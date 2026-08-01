begin;

-- ============================================================
-- Revive the rhythm gate. Silence was a fault, not a choice.
-- (docs/adam-system.md §0, §10, §11)
--
-- WHAT WAS MEASURED
--
-- 301 parents. 175 have spoken, 142 three times or more. And:
-- 0 seeds sent, 0 evening questions sent, 4 outcomes ever
-- recorded, 0 parents with three, 0 patterns, 0 journeys.
--
-- Everything that makes ADAM ADAM — the return, the
-- accumulation, "this is the third time", the paid journey —
-- has never executed once in the product's life. A product that
-- repeats without accumulating is the enemy's own definition.
--
-- THE CUT, AND IT IS ONE WORD
--
--     join public.checkin_state cs on cs.parent_id = f.id
--
-- An INNER join. checkin_state holds 12 rows against 301
-- followers, because it was an explicit opt-in table filled by
-- an onboarding flow that was later disabled — the flow went,
-- the requirement stayed. W3 has been running hourly,
-- succeeding, and finding nobody.
--
-- Absence of a row means "expressed no preference". It was being
-- read as "never write to me". Twenty families are fully ready —
-- named child, confirmed situation — and ADAM has been waiting
-- for them instead of writing to them.
--
-- THE CONSENT QUESTION, ANSWERED RATHER THAN AVOIDED
--
-- This makes silence mean yes. That is a real change and the
-- founder made it deliberately. Three things make it defensible:
--
--   1. The cohort is self-limiting. A seed only goes out when
--      can_ground_seed() is true — a named child AND a situation
--      or a prior outcome. Twenty families today, not 301.
--   2. One message a day, maximum, inside waking hours, with the
--      whole strain and pause machinery still in front of it.
--   3. The FIRST proactive message a parent ever receives now
--      carries its own exit. is_first_proactive is returned so
--      W3 can append it — an invitation rather than an intrusion.
--
-- Not doing this is not the safe option. It is choosing to keep
-- a broken product that looks polite.
-- ============================================================

drop function if exists public.get_rhythm_due(integer);

create function public.get_rhythm_due(p_limit integer default 200)
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
  -- LEFT, not inner. A parent who never expressed a preference has
  -- not refused; they were never asked. Refusal is a row saying so.
  left join public.checkin_state cs on cs.parent_id = f.id
  where
    -- unknown local evening -> send nothing (arch §5.4 rule 5)
    ct.iana_tz is not null
    -- strain L2/L3 suspend the rhythm entirely (AD-2)
    and coalesce(ps.level, 1) = 1
    -- explicit pause is honoured indefinitely
    and (cs.paused_until is null or cs.paused_until < (now() at time zone ct.iana_tz)::date)
    -- 'stopped' is the one value that means no. Absent means default.
    and coalesce(cs.cadence, 'nightly') <> 'stopped'
),
awake as (
  -- quiet hours are absolute: nothing proactive 23:00-07:00 local
  select * from base where local_hour >= 7 and local_hour < 23
),
ctx as (
  select
    a.*,
    ch.id   as child_id,
    nullif(btrim(ch.name),'') as child_name,
    s.id    as situation_id,
    s.key   as situation_key,
    -- default window when no situation is known yet (arch §5.4)
    coalesce(s.window_start, 20)::smallint as win_start,
    coalesce(s.window_end,   22)::smallint as win_end,
    d.id    as day_id,
    d.seed_sent_at,
    d.harvest_sent_at,
    d.seed_text,
    -- Has ADAM ever started a conversation with this parent?
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
      -- HARVEST first: the window has closed and a Seed went out today.
      -- No Seed, no Harvest -- the pair is atomic (arch §5.3).
      when c.seed_sent_at is not null
       and c.harvest_sent_at is null
       and c.local_hour > c.win_end
        then 'harvest'
      -- SEED: must arrive with time to act, i.e. strictly before the
      -- window opens. A bedtime Seed at 21:30 is useless (arch §5.4 rule 1).
      when c.seed_sent_at is null
       and c.local_hour < c.win_start
       and c.local_hour >= 7
        then 'seed'
      else null
    end as action
  from ctx c
)
select
  d.parent_id,
  d.platform_user_id,
  d.action,
  d.local_date,
  d.local_hour,
  d.child_id,
  d.child_name,
  d.situation_id,
  d.situation_key,
  d.day_id,
  d.seed_text,
  case when d.action = 'seed'
       then public.can_ground_seed(d.parent_id)
       else null end as grounding,
  -- Only a seed can be a first contact from ADAM's side; a harvest
  -- always follows a seed sent the same day.
  (d.action = 'seed' and d.is_first_proactive) as is_first_proactive,
  -- The sender must not hold copy. Every sentence that has lived in an
  -- n8n expression instead of conversation_moments today has drifted from
  -- the table within hours. The gate carries the text; W3 only appends it.
  case when d.action = 'seed' and d.is_first_proactive
       then (select cm.body_ar from public.conversation_moments cm
              where cm.key = 'proactive_first_footer')
       else null end as footer_ar
from decided d
where d.action is not null
  -- A Seed only goes out if it can be grounded. can_ground=false
  -- means silence, never a generic tip (P11). This is also what
  -- keeps the revived gate narrow: a named child AND a situation
  -- or a prior outcome, which today is twenty families.
  and (d.action <> 'seed'
       or (public.can_ground_seed(d.parent_id)->>'can_ground')::boolean)
order by d.local_hour desc
limit p_limit;
$function$;

revoke all on function public.get_rhythm_due(integer) from anon, authenticated, public;
grant execute on function public.get_rhythm_due(integer) to service_role;

comment on function public.get_rhythm_due(integer) is
  'Who is due a proactive message right now, and which one. A missing checkin_state row means no preference expressed, not refusal — the inner join that read it as refusal is why zero messages were sent in the product''s first month. is_first_proactive tells the sender to carry the exit in ADAM''s very first uninvited message.';


-- ------------------------------------------------------------
-- The exit, carried by the first uninvited message.
--
-- ADAM does not explain himself unasked (P24) — but consent
-- cannot be obtained silently, and this is said exactly once,
-- ever, on the first message he starts rather than answers.
-- ------------------------------------------------------------
insert into public.conversation_moments
  (key, category, tier, body_ar, buttons, max_lines, requires_commerce, note)
values
  ('proactive_first_footer', 'rhythm', 'fixed',
   'أكتب لكم مرة في اليوم، لا أكثر. ولإيقاف ذلك: /settings',
   '[]'::jsonb, 1, false,
   'Appended once, to the first message ADAM ever starts rather than answers. The single exception to "ADAM never explains himself unasked": consent cannot be obtained silently.')
on conflict (key) do update
  set body_ar = excluded.body_ar, note = excluded.note;

commit;
