begin;

-- ============================================================
-- THE EVENING QUESTION HAS BEEN IMPOSSIBLE SINCE 17 AUGUST
--
-- WHAT THE DATA SAYS
--
--   16 Aug   22 seeds sent, 20 harvested   ← working
--   17 Aug   22 seeds sent,  0 harvested   ← stopped
--   18 Aug → today: seeds every day, 0 harvested, 13 days running
--
-- In the product's entire life: 117 seeds, 27 harvests, and 14
-- nights with a result. Every number ADAM sells — the calm-night
-- count, the ranked list of what worked, the patterns, the
-- weekly comparison, the whole reading — is computed from
-- daily_logs.night_result, and night_result is written by
-- exactly one thing: the parent answering the evening question.
-- With the question never asked, the product measures nothing.
--
-- WHY
--
-- An off-by-one between two lines of get_rhythm_due:
--
--   awake:   local_hour >= 7 and local_hour < 23
--   harvest: local_hour > win_end,  win_end = coalesce(s.window_end, 22)
--
-- A family with no confirmed situation gets the default win_end
-- of 22, so harvest needs hour 23 — which `awake` excludes. The
-- condition can never be true. It stayed hidden while situations
-- were being confirmed (a real window of 18, 19 or 20 leaves
-- hours free), and became total the moment seeds started going
-- to families without one: every seed since 17 August carries a
-- null situation_id.
--
-- THE FIX
--
-- Cap the harvest's window end at 21, so hour 22 is always
-- available and the question is asked once, at 22:00 local —
-- after the hard moment, inside the waking window, before the
-- 23:00 quiet hours. Nothing else in the function changes; the
-- seed still schedules off win_start.
--
-- KNOWN FRAGILITY, STATED RATHER THAN HIDDEN: this leaves one
-- hourly chance per family per day. If the hourly schedule
-- misses 22:00 in a family's timezone, that night is lost. The
-- durable fix is to let an unanswered seed be harvested the
-- following evening instead of only on its own day; that is a
-- larger change and is deliberately not made here, because this
-- one restores the loop tonight.
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_rhythm_due(p_limit integer DEFAULT 200, p_only_platform_user_id text DEFAULT NULL::text)
 RETURNS TABLE(parent_id uuid, platform_user_id text, action text, local_date date, local_hour smallint, child_id uuid, child_name text, situation_id uuid, situation_key text, day_id uuid, seed_text text, grounding jsonb, is_first_proactive boolean, footer_ar text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
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
    -- ⭐ target hour: parent's preference, or 9am default, always kept at
    -- least 3 hours before the situation window so there's real lead time
    -- to actually try the step before it's needed.
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
order by r.local_hour desc
limit p_limit;
$function$;

commit;
