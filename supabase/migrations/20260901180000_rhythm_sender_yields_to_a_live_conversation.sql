-- get_rhythm_due() is the single gate every scheduled send (seed/harvest/journey
-- step) passes through -- it already suppresses on quiet hours, situation
-- windows, strain, and the once-per-day ceiling. It had no awareness of whether
-- the parent was mid-conversation right now, so a scheduled message could land
-- on top of an unresolved live exchange with Adam (docs/adam-persona-operating-model.md
-- §7.4 -- reported directly: a seed message interrupted a diagnostic thread
-- where Adam's own question had not been answered yet).
--
-- Deliberately NOT "is Adam's last message an unanswered question" -- that needs
-- judging tone/intent (a step-card send, a country-block notice, and an actual
-- open question are all type='ai' rows alike) and most conversations end with
-- Adam speaking last as their normal steady state, so that signal alone would
-- suppress nearly every scheduled send, not just live interruptions. The
-- narrower, safe signal: has this parent's chat had ANY activity -- either
-- side -- in the last 90 minutes? That is "a conversation is happening right
-- now," which is exactly the collision being prevented, without guessing at
-- what a message means. Checked against production data before writing this:
-- of 330 followers, 6 had chat activity in the last 90 minutes at the moment
-- of testing -- a narrow, live-only exclusion, not a blanket suppression.
create or replace function public.get_rhythm_due(p_limit integer default 200, p_only_platform_user_id text default null::text)
returns table(parent_id uuid, platform_user_id text, action text, local_date date, local_hour smallint, child_id uuid, child_name text, situation_id uuid, situation_key text, day_id uuid, seed_text text, grounding jsonb, is_first_proactive boolean, footer_ar text)
language sql
stable security definer
set search_path to 'pg_catalog', 'public'
as $function$
with base as (
  select
    f.id            as parent_id,
    f.platform_user_id,
    ct.iana_tz,
    (now() at time zone ct.iana_tz)::date       as local_date,
    extract(hour from (now() at time zone ct.iana_tz))::smallint as local_hour,
    (f.proactive_footer_at is null)             as owes_exit,
    cs.local_hour                               as preferred_hour
  from public.followers f
  join public.country_timezone ct
    on upper(btrim(f.country)) = ct.code
  left join public.checkin_state cs on cs.parent_id = f.id
  where
    ct.iana_tz is not null
    and (cs.paused_until is null or cs.paused_until < (now() at time zone ct.iana_tz)::date)
    and coalesce(cs.cadence, 'nightly') <> 'stopped'
    and (p_only_platform_user_id is null or f.platform_user_id = p_only_platform_user_id)
),
awake as (
  select * from base where local_hour >= 7 and local_hour < 23
),
ctx as (
  select
    a.*,
    ch.id   as child_id,
    nullif(btrim(ch.name),'') as child_name,
    s.id    as situation_id,
    s.key   as situation_key,
    coalesce(s.window_start, 20)::smallint as win_start,
    least(coalesce(s.window_end, 21), 21)::smallint as win_end,
    d.id    as day_id,
    d.seed_sent_at,
    d.harvest_sent_at,
    d.seed_text
  from awake a
  left join lateral (
    select c.id, c.name from public.children c
    where c.follower_id = a.parent_id
    order by c.is_primary desc nulls last, c.created_at limit 1
  ) ch on true
  left join lateral (
    select s2.id, s2.key, s2.window_start, s2.window_end
    from public.situations s2
    where s2.child_id = ch.id and s2.status in ('candidate','confirmed')
    order by (s2.status='confirmed') desc, s2.evidence_count desc, s2.last_observed desc
    limit 1
  ) s on true
  left join public.daily_logs d
    on d.follower_id = a.parent_id and d.log_date = a.local_date
),
decided as (
  select
    c.*,
    least(coalesce(c.preferred_hour, 9), c.win_start - 3) as seed_target_hour,
    case
      when c.seed_sent_at is not null
       and c.harvest_sent_at is null
       and c.local_hour > c.win_end
        then 'harvest'
      when c.seed_sent_at is null
       and c.local_hour >= 7
       and c.local_hour < c.win_start
       and c.local_hour >= least(coalesce(c.preferred_hour, 9), c.win_start - 3)
       and c.local_hour <= least(coalesce(c.preferred_hour, 9), c.win_start - 3) + 3
        then 'seed'
      else null
    end as base_action,
    exists (
      select 1 from public.stages st
      where st.parent_id = c.parent_id and st.status in ('active','extended')
    ) as in_journey
  from ctx c
),
routed as (
  select
    d.*,
    case
      when d.base_action = 'seed' and d.in_journey
       and coalesce((public.compose_journey_step(d.parent_id)->>'can_send')::boolean, false)
        then 'journey_step'
      else d.base_action
    end as action
  from decided d
)
select
  r.parent_id, r.platform_user_id, r.action, r.local_date, r.local_hour,
  r.child_id, r.child_name, r.situation_id, r.situation_key,
  r.day_id, r.seed_text,
  case
    when r.action = 'seed'         then public.can_ground_seed(r.parent_id)
    when r.action = 'journey_step' then public.compose_journey_step(r.parent_id)
    else null
  end as grounding,
  r.owes_exit as is_first_proactive,
  case when r.owes_exit
       then (select cm.body_ar from public.conversation_moments cm
              where cm.key = 'proactive_first_footer')
       else null end as footer_ar
from routed r
where r.action is not null
  and (
    r.action = 'harvest'
    or (r.action = 'seed'
        and (public.can_ground_seed(r.parent_id)->>'can_ground')::boolean)
    or (r.action = 'journey_step'
        and (public.compose_journey_step(r.parent_id)->>'can_send')::boolean)
  )
  and not exists (
    select 1 from public.n8n_chat_histories h
    where h.session_id = r.platform_user_id
      and h.created_at > now() - interval '90 minutes'
  )
order by r.local_hour desc
limit p_limit;
$function$;
