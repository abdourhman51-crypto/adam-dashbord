-- Minimal fixture reproducing only the columns get_telegram_surface() reads.
-- Column names and types copied from the real migrations, not invented.

-- Roles are cluster-wide, not per-database, so this must be idempotent:
-- a second test database in the same cluster would otherwise fail here
-- and leave every later statement unrun.
do $$
declare r text;
begin
  foreach r in array array['service_role','authenticated','anon'] loop
    if not exists (select 1 from pg_roles where rolname = r) then
      execute format('create role %I', r);
    end if;
  end loop;
end $$;

create table public.followers (
  id uuid primary key default gen_random_uuid(),
  platform_user_id text,
  country text,
  first_seen timestamptz default now(),
  -- The legacy subscription columns. activate_subscription() still writes them
  -- because the dashboard still calls it, so the fixture carries them — a
  -- function this suite exercises must not be tested against a schema it does
  -- not run on. This block is EXPECTED TO SHRINK: when the legacy paid model
  -- is deleted (docs/what-is-missing.md §3) these go with it, and the test
  -- that fails will be pointing at the right thing.
  funnel_stage text default 'free_conversation',
  payment_status text default 'none',
  offer_status text default 'none',
  subscription_started_at timestamptz,
  subscription_expires_at timestamptz,
  payment_pending_at timestamptz,
  renewal_d5_sent_at timestamptz,
  renewal_d0_sent_at timestamptz,
  -- record_seed_sent() stamps this on the first proactive message.
  proactive_footer_at timestamptz,
  -- The free tier's own columns, read and written by the functions restored in
  -- 20260729000100: the light memory (heart_commit / get_heart_batch), the
  -- message cap (check_daily_message_cap), and the return signal that makes a
  -- parent golden (get_free_session_state).
  first_name text,
  parent_gender text,
  light_memory text,
  light_memory_updated_at timestamptz,
  daily_msg_count integer not null default 0,
  daily_msg_date date,
  waitlist boolean default false,
  return_count integer not null default 0,
  last_return_at timestamptz,
  last_gap_hours numeric,
  is_golden boolean default false,
  last_active timestamptz,
  -- The legacy checkin consent columns. Present so the chain can run the
  -- migration that DROPS them (20260807180000); they leave with it.
  checkin_opt_in boolean,
  checkin_opted_at timestamptz,
  last_checkin_sent_date date
);

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  follower_id uuid references public.followers(id) on delete cascade,
  amount numeric, currency text, plan_type text, status text,
  claimed_at timestamptz, confirmed_at timestamptz, confirmed_by text,
  notes text, created_at timestamptz default now()
);

-- Columns copied from production. age_note is read by compose_menu_body();
-- it was added here the moment that function started reading it, rather than
-- after production returned 42703 — which is the mistake this fixture exists
-- to stop repeating.
create table public.children (
  id uuid primary key default gen_random_uuid(),
  follower_id uuid references public.followers(id) on delete cascade,
  name text,
  gender text, birth_year integer, age_note text, temperament text,
  -- NOT NULL DEFAULT false, exactly as production. It was nullable here, and
  -- that is not a harmless looseness: every "primary child, else any child"
  -- reader orders by `is_primary desc`, and DESC puts NULLs FIRST — so a child
  -- with a null flag outranked the actual primary child in the fixture and in
  -- no other database. The bug belonged to the fixture; the readers are right.
  is_primary boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz default now(),
  -- _ensure_child() and writer_commit() both upsert on this. Without it the
  -- "same child mentioned twice" case silently creates a sibling.
  unique (follower_id, name)
);

create table public.country_timezone (
  code text primary key, iana_tz text not null, name_ar text
);

-- Columns copied from production. There is NO is_supported column: an
-- earlier fixture invented one, the tests passed, and every production call
-- to get_telegram_surface returned 42703 (execution 5456). A fixture that
-- invents a column tests the fixture, not the schema.
create table public.supported_countries (
  code text primary key,
  name_ar text, currency text,
  price_subscription numeric, price_comeback numeric, price_continuation numeric,
  price_display_full text, price_display_short text, price_continuation_display text,
  is_active boolean default false,
  created_at timestamptz default now()
);

-- KNOWN DRIFT, recorded rather than hidden. In production `parent_id`,
-- `label_ar`, `window_start` and `window_end` are all NOT NULL, and the raw
-- inserts throughout this suite would be refused there — production's only
-- writer is commit_situation(), which fills all four from situation_catalog.
-- Nothing reads the three that tests omit except get_rhythm_due (windows),
-- and rhythm_gate_test does supply those, so no product behaviour is being
-- mistested today. Tightening this means moving ~25 raw inserts onto
-- commit_situation(); it is on the list in docs/what-is-missing.md §7 rather
-- than done quietly at the end of an unrelated change.
create table public.situations (
  id uuid primary key default gen_random_uuid(),
  child_id uuid references public.children(id) on delete cascade,
  parent_id uuid references public.followers(id) on delete cascade,
  key text,
  label_ar text,
  status text check (status in ('candidate','confirmed','rejected')),
  window_start smallint, window_end smallint,
  evidence_count integer default 1,
  first_observed timestamptz default now(),
  last_observed timestamptz default now(),
  updated_at timestamptz default now(),
  -- commit_situation() upserts on this key: three independent observations
  -- promote a candidate to confirmed, and without the constraint the promotion
  -- silently becomes a duplicate row instead.
  unique (child_id, key)
);

-- record_seed_sent() writes an A1/A2 row the first time a seed is grounded on
-- the child's name or on a prior outcome.
create table public.aha_moments (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid references public.followers(id) on delete cascade,
  child_id uuid,
  kind text, moment_class text,
  first_occurrence boolean, day_id uuid,
  journey_id uuid,
  occurred_at timestamptz default now()
);

-- The full production shape, copied from
-- 20260729130100_journey_engine_core_schema.sql — constraints included, because
-- the constraints ARE the product here: one live stage per parent, a target
-- that fits its window, and a clock between 7 and 60 logged days. A fixture
-- that keeps the columns but drops the checks tests a journey engine that
-- cannot exist.
create table public.stages (
  id                   uuid primary key default gen_random_uuid(),
  parent_id            uuid not null references public.followers(id) on delete cascade,
  child_id             uuid references public.children(id) on delete set null,
  problem_key          text not null,
  objective_text       text not null,
  objective_metric     text not null default 'calm_nights_in_window'
                         check (objective_metric in ('calm_nights_in_window','steps_done_in_window')),
  objective_target     integer not null check (objective_target > 0),
  objective_window     integer not null check (objective_window > 0),
  planned_logged_days  integer not null default 29 check (planned_logged_days between 7 and 60),
  extension_days       integer not null default 0 check (extension_days >= 0),
  extension_granted_at timestamptz,
  status               text not null default 'proposed' check (status in (
                         'proposed','active','extended','completed','failed','paused','refunded')),
  price_amount         numeric,
  price_currency       text,
  proposed_at          timestamptz not null default now(),
  started_at           timestamptz,
  paused_at            timestamptz,
  completed_at         timestamptz,
  refunded_at          timestamptz,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),
  constraint chk_target_fits_window check (objective_target <= objective_window),
  constraint chk_started_when_live  check (status not in ('active','extended') or started_at is not null)
);
create unique index uq_one_live_stage_per_parent
  on public.stages (parent_id) where status in ('active','extended','paused');

-- v_stage_progress and can_propose_stage read these two. Stubs, because this
-- fixture covers the journey engine, not safeguarding or the proposal log.
create table public.crisis_flags (
  id          uuid primary key default gen_random_uuid(),
  parent_id   uuid not null references public.followers(id) on delete cascade,
  category    text not null,
  detected_at timestamptz not null default now(),
  handled_at  timestamptz
);

-- The erasure audit trail. It carries NO foreign key to followers by design:
-- the record of an erasure must survive the erasure it records. Copied from
-- 20260729130100 because write_child_name() refuses to write a name for a
-- parent with an open erasure request.
create table public.erasure_requests (
  id               uuid primary key default gen_random_uuid(),
  parent_id        uuid not null,
  platform_user_id text not null,
  requested_at     timestamptz not null default now(),
  completed_at     timestamptz,
  status           text not null default 'requested'
                     check (status in ('requested','completed','failed')),
  refund_due       boolean not null default false,
  notes            text
);

create table public.stage_proposals (
  id          uuid primary key default gen_random_uuid(),
  parent_id   uuid not null references public.followers(id) on delete cascade,
  child_id    uuid,
  problem_key text not null,
  proposed_at timestamptz not null default now(),
  outcome     text not null default 'pending',
  stage_id    uuid references public.stages(id) on delete set null
);

-- Columns copied from production (information_schema), not from memory.
create table public.daily_logs (
  id uuid primary key default gen_random_uuid(),
  follower_id uuid references public.followers(id) on delete cascade,
  log_date date not null,
  summary text, guardian_mood text,
  step_given text, step_completed boolean, step_status text,
  created_at timestamptz default now(), updated_at timestamptz default now(),
  checkin_sent_at timestamptz,
  child_id uuid,
  night_result text, hard_moment text,
  source text, journey_id uuid, situation_id uuid,
  seed_text text, seed_grounded_on jsonb,
  seed_scheduled_for timestamptz, seed_sent_at timestamptz,
  harvest_sent_at timestamptz, harvest_answered_at timestamptz,
  unique (follower_id, log_date)
);

create table public.child_patterns (
  id uuid primary key default gen_random_uuid(),
  follower_id uuid,
  child_id uuid references public.children(id) on delete cascade,
  pattern_label text,
  description text,
  status text,
  evidence_count integer default 1,
  first_observed timestamptz default now(),
  last_observed timestamptz default now(),
  updated_at timestamptz default now(),
  safe_for_record boolean not null default false,
  -- writer_commit() upserts patterns on this key; a second sighting is meant to
  -- raise evidence_count, not to create a second pattern with the same label.
  unique (follower_id, pattern_label)
);

-- The four tables W2's writer touches, and the one the free session clock keeps.
-- Columns copied from production's information_schema. Only the columns the
-- restored functions in 20260807140000 actually read or write carry the
-- production defaults; the rest are here because the writers name them.
create table public.memory_snapshots (
  follower_id uuid primary key references public.followers(id) on delete cascade,
  snapshot_text text not null default '',
  char_count integer,
  built_from jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table public.memory_events (
  id uuid primary key default gen_random_uuid(),
  follower_id uuid not null references public.followers(id) on delete cascade,
  child_id uuid,
  event_type text not null,
  title text not null,
  summary text,
  emotional_weight integer not null default 3,
  occurred_at timestamptz not null default now(),
  source text not null default 'agent_extraction',
  created_at timestamptz not null default now()
);

-- Production's full shape. It was four columns until get_agent_context came
-- home in 20260729000100 and replaced the stub below with the real body, which
-- reads current_day. Four columns was enough to test the stub and nothing else.
create table public.plan_sessions (
  id uuid primary key default gen_random_uuid(),
  follower_id uuid references public.followers(id) on delete cascade,
  plan_started_at timestamptz default now(),
  current_day integer default 1,
  current_week integer default 1,
  child_name text, child_age text, main_challenge text, wins text, next_step text,
  updated_at timestamptz default now(),
  compressed_memory text,
  session_count integer default 0,
  has_breakthrough boolean default false,
  child_gender text, guardian_name text, guardian_state text,
  guardian_approach text, relation_to_child text,
  onboarding_complete boolean not null default false,
  progress_score integer not null default 0,
  unique (follower_id)
);

-- write_child_name() back-links this table's orphan rows to the only child.
create table public.weekly_plans (
  id uuid primary key default gen_random_uuid(),
  follower_id uuid not null references public.followers(id) on delete cascade,
  week_number integer not null,
  child_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.session_tracker (
  platform_user_id text primary key,
  session_anchor_id bigint not null default 0,
  session_started_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  session_msg_turns integer not null default 0,
  session_number integer not null default 1
);

create table public.checkin_state (
  parent_id uuid primary key references public.followers(id) on delete cascade,
  cadence text not null default 'nightly',
  local_hour smallint,
  consecutive_ignored integer not null default 0,
  last_sent_date date,
  last_sent_at timestamptz,
  last_responded_at timestamptz,
  cadence_changed_at timestamptz,
  paused_until date,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table public.parent_strain (
  parent_id uuid primary key references public.followers(id) on delete cascade,
  level smallint not null default 1,
  reason text,
  entered_at timestamptz default now(),
  return_eligible_at timestamptz,
  updated_at timestamptz default now()
);

create table public.n8n_chat_histories (
  id bigserial primary key,
  session_id text,
  message jsonb,
  created_at timestamptz default now()
);

create function public.normalise_session_key(p text) returns text
language sql immutable as $$ select p $$;

-- v_parent_engagement: only the four columns the surface function reads.
create view public.v_parent_engagement as
with chat as (
  select public.normalise_session_key(h.session_id) as key,
         count(*) filter (where h.message->>'type' = 'human') as human_messages,
         max(h.created_at) as last_message_at
  from public.n8n_chat_histories h group by 1
),
logs as (
  select d.follower_id,
         count(distinct d.log_date) filter (where d.night_result is not null) as nights_with_result
  from public.daily_logs d group by 1
)
select f.id as parent_id, f.platform_user_id,
       coalesce(c.human_messages, 0) as human_messages,
       c.last_message_at,
       coalesce(l.nights_with_result, 0) as nights_with_result
from public.followers f
left join chat c on c.key = f.platform_user_id
left join logs l on l.follower_id = f.id;

-- get_agent_context() was stubbed here, because its source lived only in the
-- database. It came home in 20260729000100_baseline_the_functions_that_predate
-- _the_repo.sql, which the chain loads first, so the real body is what these
-- tests now run against — including the PLAN_DAY / DAYS_LEFT preamble whose
-- stripping is the behaviour under test. The stub is deleted rather than kept
-- and shadowed: a fixture that defines what a migration also defines is a
-- second source, and second sources drift.

-- commerce_allowed(): real signature, simplified body (blocks at L2/L3).
-- hard_moment_label(): copied verbatim from the child-record migration.
create function public.hard_moment_label(p_key text) returns text
language sql immutable as $$
  select case lower(coalesce(p_key,''))
    when 'meal' then 'عند الأكل' when 'sleep' then 'عند النوم'
    when 'out' then 'عند الخروج' when 'screen' then 'في وقت الشاشة'
    when 'study' then 'عند الدراسة' when 'other' then 'في موقف آخر'
    else null end
$$;

-- can_ground_seed(): the real one lives in a migration this fixture does
-- not load. Same contract — a child name AND one of situation / prior
-- outcome / pattern — reimplemented so can_send('seed') is exercised.
create function public.can_ground_seed(p_parent_id uuid) returns jsonb
language sql stable as $$
  with ctx as (
    select (select nullif(btrim(c.name),'') from public.children c
             where c.follower_id = p_parent_id
             order by c.is_primary desc nulls last, c.created_at limit 1) as nm,
           exists (select 1 from public.situations s join public.children c on c.id = s.child_id
                    where c.follower_id = p_parent_id and s.status in ('candidate','confirmed')) as sit,
           exists (select 1 from public.daily_logs d
                    where d.follower_id = p_parent_id and d.step_status = 'done') as outc
  )
  select jsonb_build_object(
    'can_ground', nm is not null and (sit or outc),
    'child_name', nm,
    'basis', (select coalesce(jsonb_agg(b),'[]'::jsonb) from (
                select 'situation' as b where sit
                union all select 'prior_outcome' where outc) z),
    'missing', (select coalesce(jsonb_agg(b),'[]'::jsonb) from (
                select 'child_name' as b where nm is null
                union all select 'grounding' where not (sit or outc)) z))
  from ctx;
$$;

create function public.commerce_allowed(p_parent_id uuid) returns boolean
language sql stable as $$
  select coalesce((select ps.level from public.parent_strain ps
                    where ps.parent_id = p_parent_id), 1) < 2;
$$;

-- SA and SY are here on purpose: a country we can put on a clock but do NOT
-- sell in. Without one of those, "unsupported" and "unknown" collapse into
-- the same fixture state and the test that matters cannot be written.
insert into public.country_timezone (code, iana_tz) values
  ('DZ','Africa/Algiers'), ('EG','Africa/Cairo'), ('MA','Africa/Casablanca'),
  ('SA','Asia/Riyadh'), ('SY','Asia/Damascus'),
  -- Tunisia: genuinely unsupported, and on Africa/Tunis — permanently UTC+1,
  -- exactly like Africa/Algiers. The unsupported-vs-supported comparison in
  -- telegram_surface_test used SA, whose local date rolls over four hours
  -- before DZ's, so the two parents' seven-day windows landed on different
  -- dates and the test failed for roughly two hours every night.
  ('TN','Africa/Tunis');
-- name_ar is read by country_recorded. It was absent, and the confirmation
-- fell back to «بلدكم» in a test that still passed.
insert into public.supported_countries (code, name_ar, is_active, price_display_full) values
  ('DZ','الجزائر',true,'2,300 دينار جزائري'), ('EG','مصر',true,'490 جنيهاً مصرياً'),
  ('MA','المغرب',true,'110 دراهم مغربية'), ('SA','السعودية',false,null);
