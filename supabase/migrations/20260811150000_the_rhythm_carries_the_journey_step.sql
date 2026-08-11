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
-- Built on the LIVE production version, not the repo's stale one
--
-- A drift predating this work: production's get_rhythm_due had already
-- moved to the "exit is owed until shown" model — owes_exit derived from
-- followers.proactive_footer_at, the footer carried by whichever
-- proactive message comes next (seed OR harvest). The repo's
-- 20260801190000 added the column but never updated get_rhythm_due, so
-- the repo still built the older is_first_proactive (not-exists) version.
-- Rebuilding on the repo's copy and deploying would have REVERTED the
-- live fix. This migration is therefore transcribed from the live
-- function and adds only the journey routing — which also realigns the
-- repo with production.
--
-- ------------------------------------------------------------
-- What this adds, precisely (all marked ⭐)
--
--   ⭐ when the morning action would be 'seed' AND the parent has a live
--      stage, it becomes 'journey_step';
--   ⭐ 'journey_step' is grounded by compose_journey_step and gated by
--      its can_send, exactly as 'seed' is by can_ground_seed. No outcome
--      yet → no row: the journey is silent this morning, it does NOT fall
--      back to a generic seed (§5).
--
-- owes_exit / is_first_proactive / footer_ar are preserved verbatim: a
-- journey_step is just another proactive message, so it carries the exit
-- footer on the rare row where the debt still stands, exactly as a seed
-- or harvest would. A parent with no journey is entirely unaffected.
--
-- Delivery contract for W3 (still to build): sending a journey_step must
-- stamp seed_sent_at like the seed branch, so the evening harvest fires.
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
    (now() at time zone ct.iana_tz)::date       as local_date,
    extract(hour from (now() at time zone ct.iana_tz))::smallint as local_hour,
    -- The exit is owed until it has actually been shown. A fact about
    -- the parent, not about any one message: a send that fails to carry
    -- it leaves the debt standing.
    (f.proactive_footer_at is null)             as owes_exit
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
  r.parent_id, r.platform_user_id, r.action, r.local_date, r.local_hour,
  r.child_id, r.child_name, r.situation_id, r.situation_key,
  r.day_id, r.seed_text,
  -- ⭐ grounding per action: seed from can_ground_seed, journey step from
  -- compose_journey_step. The harvest carries none (composed at send).
  case
    when r.action = 'seed'         then public.can_ground_seed(r.parent_id)
    when r.action = 'journey_step' then public.compose_journey_step(r.parent_id)
    else null
  end as grounding,
  r.owes_exit as is_first_proactive,
  -- Carried by whichever proactive message comes next — seed, harvest, or
  -- journey step. The debt is a fact about the parent, not the message.
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
    -- ⭐ journey_step sends only when it has an outcome to build on; else
    -- the journey is silent this morning (it does not become a seed).
    or (r.action = 'journey_step'
        and (public.compose_journey_step(r.parent_id)->>'can_send')::boolean)
  )
order by r.local_hour desc
limit p_limit;
$function$;

comment on function public.get_rhythm_due(integer) is
  'Who is due a proactive message right now, and which one: harvest, seed, or — for a parent inside a live journey — journey_step in the morning give slot, grounded by compose_journey_step and gated by its can_send (no outcome yet → silent, not a fallback seed). owes_exit (from followers.proactive_footer_at) carries the first-contact footer on whichever proactive message comes next. A missing checkin_state row means no preference, not refusal.';

revoke all on function public.get_rhythm_due(integer) from anon, authenticated, public;
grant execute on function public.get_rhythm_due(integer) to service_role;

commit;
