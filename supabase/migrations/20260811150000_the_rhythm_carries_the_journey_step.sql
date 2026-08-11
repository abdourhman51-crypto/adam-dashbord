-- ============================================================
-- get_rhythm_due carries the journey step.
-- Design: docs/the-conversion-seam.md step 5 · knowledge-engine.md §5
--
-- The morning "give" slot is a free SEED for a parent with no journey.
-- For a parent inside a live journey it must be the JOURNEY STEP instead
-- — the same slot, the same timing, journey-aware content. The evening
-- half is untouched: the journey's night question is still the ordinary
-- Harvest, which already handles a journey parent.
--
-- ------------------------------------------------------------
-- What changes, precisely
--
-- Built on the live version (20260801150000 revive_the_rhythm_gate): the
-- 14-column return, the LEFT join on checkin_state, is_first_proactive
-- and footer_ar are all preserved exactly. The timing, window, strain,
-- quiet hours, pause, cadence and once-per-day ceiling are byte-for-byte
-- the same. Only the decision layer gains one rule and the final select
-- gains branches, all marked ⭐:
--
--   ⭐ when the morning action would be 'seed' AND the parent has a live
--      stage, it becomes 'journey_step';
--   ⭐ 'journey_step' is gated by compose_journey_step(...).can_send and
--      grounded by compose_journey_step(...), exactly as 'seed' is gated
--      by can_ground_seed. No outcome yet → no row: the journey is silent
--      this morning, it does NOT fall back to a generic seed (§5).
--
-- A parent with no journey is completely unaffected. And because a
-- journey_step is never action='seed', is_first_proactive and footer_ar
-- come back false/null for it automatically — correct, since a parent in
-- a paid journey is long past their first uninvited message.
--
-- ------------------------------------------------------------
-- The evening still fires, because delivery stamps the same slot
--
-- The Harvest is keyed on seed_sent_at. When W3 sends a journey_step it
-- must stamp seed_sent_at just as the seed branch does, so the evening
-- question still fires. That is the delivery layer's contract (the W3
-- journey_step branch, still to be built); get_rhythm_due reads the stamp
-- and needs no change for it.
-- ============================================================

begin;

create or replace function public.get_rhythm_due(p_limit integer default 200)
returns table(
  parent_id uuid, platform_user_id text, action text,
  local_date date, local_hour smallint,
  child_id uuid, child_name text,
  situation_id uuid, situation_key text,
  day_id uuid, seed_text text, grounding jsonb,
  is_first_proactive boolean, footer_ar text)
language sql
stable
security definer
set search_path to 'pg_catalog','public'
as $function$
with base as (
  select
    f.id            as parent_id,
    f.platform_user_id,
    ct.iana_tz,
    (now() at time zone ct.iana_tz)             as local_ts,
    (now() at time zone ct.iana_tz)::date       as local_date,
    extract(hour from (now() at time zone ct.iana_tz))::smallint as local_hour,
    coalesce(ps.level, 1)                       as strain_level
  from public.followers f
  join public.country_timezone ct
    on upper(btrim(f.country)) = ct.code
  left join public.parent_strain ps on ps.parent_id = f.id
  left join public.checkin_state cs on cs.parent_id = f.id
  where
    ct.iana_tz is not null
    and coalesce(ps.level, 1) = 1
    and (cs.paused_until is null or cs.paused_until < (now() at time zone ct.iana_tz)::date)
    and coalesce(cs.cadence, 'nightly') <> 'stopped'
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
    coalesce(s.window_end,   22)::smallint as win_end,
    d.id    as day_id,
    d.seed_sent_at,
    d.harvest_sent_at,
    d.seed_text,
    not exists (
      select 1 from public.daily_logs d2
      where d2.follower_id = a.parent_id and d2.seed_sent_at is not null
    ) as is_first_proactive
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
    case
      when c.seed_sent_at is not null
       and c.harvest_sent_at is null
       and c.local_hour > c.win_end
        then 'harvest'
      when c.seed_sent_at is null
       and c.local_hour < c.win_start
       and c.local_hour >= 7
        then 'seed'
      else null
    end as base_action,
    -- ⭐ A live journey turns the morning give into the journey step.
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
      when d.base_action = 'seed' and d.in_journey then 'journey_step'
      else d.base_action
    end as action
  from decided d
)
select
  r.parent_id,
  r.platform_user_id,
  r.action,
  r.local_date,
  r.local_hour,
  r.child_id,
  r.child_name,
  r.situation_id,
  r.situation_key,
  r.day_id,
  r.seed_text,
  -- ⭐ grounding per action: seed from can_ground_seed, journey step from
  -- compose_journey_step. The harvest carries none (composed at send).
  case
    when r.action = 'seed'         then public.can_ground_seed(r.parent_id)
    when r.action = 'journey_step' then public.compose_journey_step(r.parent_id)
    else null
  end as grounding,
  -- Only a seed can be a first contact; a journey_step never is (the parent
  -- has been messaged throughout the free tier).
  (r.action = 'seed' and r.is_first_proactive) as is_first_proactive,
  case when r.action = 'seed' and r.is_first_proactive
       then (select cm.body_ar from public.conversation_moments cm
              where cm.key = 'proactive_first_footer')
       else null end as footer_ar
from routed r
where r.action is not null
  and (
    r.action = 'harvest'
    or (r.action = 'seed'
        and (public.can_ground_seed(r.parent_id)->>'can_ground')::boolean)
    -- ⭐ journey_step sends only when it has an outcome to build on; else
    -- the journey is silent this morning (it does not become a seed).
    or (r.action = 'journey_step'
        and (public.compose_journey_step(r.parent_id)->>'can_send')::boolean)
  )
order by r.local_hour desc
limit p_limit;
$function$;

comment on function public.get_rhythm_due(integer) is
  'Who is due a proactive message right now, and which one: harvest, seed, or — for a parent inside a live journey — journey_step in the morning give slot, grounded by compose_journey_step and gated by its can_send (no outcome yet → silent, not a fallback seed). A missing checkin_state row means no preference, not refusal. is_first_proactive/footer_ar are carried for a seed only; a journey_step is never a first contact.';

revoke all on function public.get_rhythm_due(integer) from anon, authenticated, public;
grant execute on function public.get_rhythm_due(integer) to service_role;

commit;
