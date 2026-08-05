-- Baseline: the fourteen tables that predate this repository
--
-- This migration history begins at 20260729123012_week0_*, on a database that
-- already existed and already held 310 families. Everything older than week 0
-- has no CREATE TABLE anywhere in git, so a blank database could never be
-- brought to production's shape from this repository — the offline suite ran on
-- fixture_minimal.sql, which is deliberately partial and says so.
--
-- Read out of production on 2026-08-07 (pg_attribute / pg_constraint /
-- pg_indexes / pg_policies), not from memory. Every statement is IF NOT EXISTS
-- or guarded, so this is a no-op against the database that already has them —
-- which is the only database it will ever meet until someone rebuilds.
--
-- Dated before week 0 on purpose. A rebuild applies files in timestamp order,
-- and week 0 alters these tables.
--
-- TWO THINGS ARE DELIBERATELY NOT HERE, because they need objects that later
-- migrations create, and a baseline that silently skipped them would produce a
-- database that merely looks like production:
--
--   * daily_logs' foreign keys to `stages` and `situations`
--   * the seven triggers (set_updated_at, guard_safe_for_record,
--     guard_chat_history_message) and the normalised-session-key index
--
-- They live in 20260807150000_baseline_tail_the_bindings_that_needed_later_objects.sql,
-- dated after everything they depend on.
--
-- Faithfully reproduced, NOT tidied — this file is a photograph, not a design:
--   * followers carries ~14 columns that docs/what-is-missing.md §3 marks dead
--     (offer_score, judge_reason, cohort, is_golden, reactivation_*, ...). They
--     are here because they are there. §3 deletes them, and now §3 has a diff.
--   * children, daily_logs and child_patterns each carry BOTH a unique
--     constraint and a redundant unique index over the same columns
--     (children_follower_id_name_key and uq_children_follower_name, and so on).
--     Two objects enforcing one rule is production's real shape.

begin;

-- ── followers: everything else hangs off this ─────────────────────────────────

create table if not exists public.followers (
  id uuid default gen_random_uuid() not null,
  platform text default 'telegram'::text,
  platform_user_id text not null,
  username text,
  first_name text,
  first_seen timestamptz default now(),
  last_active timestamptz default now(),
  message_count integer default 0,
  funnel_stage text default 'free_conversation'::text,
  country text,
  payment_status text default 'none'::text,
  payment_pending_at timestamptz,
  pain_score integer default 0,
  urgency_score integer default 0,
  intent_score integer default 0,
  subscription_started_at timestamptz,
  subscription_expires_at timestamptz,
  offer_status text default 'none'::text not null,
  offer_sent_at timestamptz,
  offer_count integer default 0 not null,
  offer_declined_count integer default 0 not null,
  followup_sent_at timestamptz,
  daily_msg_count integer default 0 not null,
  daily_msg_date date,
  renewal_d5_sent_at timestamptz,
  renewal_d0_sent_at timestamptz,
  ready_for_offer boolean default false,
  offer_score integer default 0 not null,
  last_judged_at timestamptz,
  judge_reason text,
  offer_child_name text,
  offer_pain_safe text,
  offer_hook text,
  waitlist boolean default false not null,
  cap_reached_at timestamptz,
  cta_clicked_at timestamptz,
  offer_source text,
  light_memory text,
  light_memory_updated_at timestamptz,
  last_return_at timestamptz,
  last_gap_hours numeric,
  cohort text default 'new'::text not null,
  return_count integer default 0 not null,
  is_golden boolean default false not null,
  signup_source text default 'organic'::text not null,
  offer_text text,
  survey_mode boolean default false not null,
  survey_sent_at timestamptz,
  onboarding_step smallint default 0 not null,
  onboarding_done boolean default false not null,
  child_age_band text,
  main_pain text,
  guardian_state text,
  pain_time text,
  parent_gender text,
  checkin_opt_in boolean,
  checkin_opted_at timestamptz,
  last_checkin_sent_date date,
  reactivation_sent_at timestamptz,
  reactivation_clicked_at timestamptz,
  trial_started_at timestamptz,
  clarity_seen_at timestamptz,
  insight_sent_at timestamptz,
  pinned_message_id bigint,
  intention_text text,
  intention_asked_at timestamptz,
  proactive_footer_at timestamptz,
  country_asked_at timestamptz,
  offer_fork_at timestamptz
);

-- ── The family ────────────────────────────────────────────────────────────────

create table if not exists public.children (
  id uuid default gen_random_uuid() not null,
  follower_id uuid not null,
  name text,
  gender text,
  birth_year integer,
  age_note text,
  -- NOT NULL DEFAULT false, and that matters: every "primary child, else any
  -- child" reader orders by `is_primary desc`, and DESC puts NULLs FIRST. A
  -- nullable flag would let a child with no flag outrank the primary one.
  is_primary boolean default false not null,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null,
  temperament text
);

create table if not exists public.child_patterns (
  id uuid default gen_random_uuid() not null,
  follower_id uuid not null,
  child_id uuid,
  pattern_label text not null,
  description text,
  status text default 'active'::text not null,
  evidence_count integer default 1 not null,
  first_observed timestamptz default now() not null,
  last_observed timestamptz default now() not null,
  updated_at timestamptz default now() not null,
  -- A pattern is never born visible. guard_safe_for_record() (added in the tail
  -- file) is what actually enforces that; the default is only the first line.
  safe_for_record boolean default false not null
);

create table if not exists public.daily_logs (
  id uuid default gen_random_uuid() not null,
  follower_id uuid not null,
  log_date date default current_date not null,
  summary text,
  guardian_mood text,
  step_given text,
  step_completed boolean,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null,
  step_status text,
  checkin_sent_at timestamptz,
  child_id uuid,
  night_result text,
  hard_moment text,
  source text default 'legacy'::text not null,
  journey_id uuid,
  situation_id uuid,
  seed_text text,
  seed_grounded_on jsonb,
  seed_scheduled_for timestamptz,
  seed_sent_at timestamptz,
  harvest_sent_at timestamptz,
  harvest_answered_at timestamptz
);

create table if not exists public.weekly_plans (
  id uuid default gen_random_uuid() not null,
  follower_id uuid not null,
  week_number integer not null,
  starts_on date,
  focus text,
  steps jsonb default '[]'::jsonb not null,
  status text default 'planned'::text not null,
  outcome_notes text,
  created_at timestamptz default now() not null,
  updated_at timestamptz default now() not null,
  child_id uuid
);

-- ── Memory ────────────────────────────────────────────────────────────────────

create table if not exists public.memory_events (
  id uuid default gen_random_uuid() not null,
  follower_id uuid not null,
  child_id uuid,
  event_type text not null,
  title text not null,
  summary text,
  emotional_weight integer default 3 not null,
  occurred_at timestamptz default now() not null,
  source text default 'agent_extraction'::text not null,
  created_at timestamptz default now() not null
);

create table if not exists public.memory_snapshots (
  follower_id uuid not null,
  snapshot_text text default ''::text not null,
  -- GENERATED, not defaulted. A default cannot read another column, and a
  -- dump that writes `default length(snapshot_text)` is simply invalid SQL —
  -- which is how this line got read twice before being written once.
  char_count integer generated always as (length(snapshot_text)) stored,
  built_from jsonb default '{}'::jsonb not null,
  updated_at timestamptz default now() not null
);

create table if not exists public.plan_sessions (
  id uuid default gen_random_uuid() not null,
  follower_id uuid,
  plan_started_at timestamptz default now(),
  current_day integer default 1,
  current_week integer default 1,
  child_name text,
  child_age text,
  main_challenge text,
  wins text,
  next_step text,
  updated_at timestamptz default now(),
  compressed_memory text,
  session_count integer default 0,
  has_breakthrough boolean default false,
  child_gender text,
  guardian_name text,
  guardian_state text,
  guardian_approach text,
  relation_to_child text,
  onboarding_complete boolean default false not null,
  progress_score integer default 0 not null
);

create table if not exists public.follower_insights (
  id uuid default gen_random_uuid() not null,
  follower_id uuid,
  recorded_at timestamptz default now(),
  emotional_state text,
  struggle text,
  fear text,
  goal text,
  language_used text
);

-- ── Conversation and sessions ─────────────────────────────────────────────────

-- serial, not identity: production's default is nextval on a sequence named
-- n8n_chat_histories_id_seq, which is exactly what serial creates. n8n owns the
-- shape of this table, including session_id being varchar(255) and not text.
create table if not exists public.n8n_chat_histories (
  id serial not null,
  session_id character varying(255) not null,
  message jsonb not null,
  created_at timestamptz default now()
);

create table if not exists public.session_tracker (
  platform_user_id text not null,
  session_anchor_id bigint default 0 not null,
  session_started_at timestamptz default now() not null,
  last_seen_at timestamptz default now() not null,
  session_msg_turns integer default 0 not null,
  session_number integer default 1 not null
);

create table if not exists public.survey_responses (
  id bigserial not null,
  platform_user_id text not null,
  first_name text,
  response text,
  created_at timestamptz default now()
);

-- ── Money ─────────────────────────────────────────────────────────────────────

create table if not exists public.payments (
  id uuid default gen_random_uuid() not null,
  follower_id uuid,
  amount numeric default 2300,
  currency text default 'DZD'::text,
  plan_type text default 'basic'::text,
  status text default 'pending'::text,
  claimed_at timestamptz default now(),
  confirmed_at timestamptz,
  confirmed_by text default 'manual'::text,
  notes text,
  created_at timestamptz default now()
);

create table if not exists public.supported_countries (
  code text not null,
  name_ar text,
  currency text not null,
  price_subscription numeric not null,
  price_comeback numeric not null,
  is_active boolean default true not null,
  created_at timestamptz default now() not null,
  price_continuation numeric,
  price_display_full text,
  price_display_short text,
  price_continuation_display text
);

-- ── Constraints ───────────────────────────────────────────────────────────────
--
-- ADD CONSTRAINT has no IF NOT EXISTS, so each one is guarded by name. Naming
-- them exactly as production names them is the point: a rebuild whose
-- constraints are called something else cannot be diffed against the original.

do $baseline$
declare
  c record;
begin
  for c in
    select * from (values
      ('followers','followers_pkey','primary key (id)'),
      ('followers','followers_platform_user_id_key','unique (platform_user_id)'),
      ('followers','followers_funnel_stage_check',
       $q$check (funnel_stage = any (array['free_conversation','offer_presented','payment_pending_manual','paid_active','waitlist_non_algerian','expired']))$q$),
      ('followers','chk_payment_status_valid',
       $q$check (payment_status = any (array['none','paid']))$q$),
      ('followers','chk_offer_source_valid',
       $q$check (offer_source is null or offer_source = any (array['cap_button','judge_seller']))$q$),
      -- Paid access always has an end. A subscription with no expiry is a
      -- subscription nobody can ever close.
      ('followers','chk_active_has_expiry',
       $q$check (funnel_stage <> 'paid_active' or subscription_expires_at is not null)$q$),
      -- Nobody is sold what they already have.
      ('followers','chk_no_offer_for_active',
       $q$check (not (funnel_stage = 'paid_active' and ready_for_offer = true))$q$),

      ('children','children_pkey','primary key (id)'),
      ('children','children_follower_id_name_key','unique (follower_id, name)'),
      ('children','children_follower_id_fkey',
       'foreign key (follower_id) references public.followers(id) on delete cascade'),

      ('child_patterns','child_patterns_pkey','primary key (id)'),
      ('child_patterns','child_patterns_follower_id_pattern_label_key','unique (follower_id, pattern_label)'),
      ('child_patterns','child_patterns_follower_id_fkey',
       'foreign key (follower_id) references public.followers(id) on delete cascade'),
      ('child_patterns','child_patterns_child_id_fkey',
       'foreign key (child_id) references public.children(id) on delete set null'),
      ('child_patterns','child_patterns_status_check',
       $q$check (status = any (array['active','improving','resolved','dormant']))$q$),

      ('daily_logs','daily_logs_pkey','primary key (id)'),
      ('daily_logs','daily_logs_follower_id_log_date_key','unique (follower_id, log_date)'),
      ('daily_logs','daily_logs_follower_id_fkey',
       'foreign key (follower_id) references public.followers(id) on delete cascade'),
      ('daily_logs','daily_logs_child_id_fkey',
       'foreign key (child_id) references public.children(id) on delete set null'),
      ('daily_logs','daily_logs_night_result_check',
       $q$check (night_result = any (array['calm','hard','normal']))$q$),
      ('daily_logs','daily_logs_step_status_check',
       $q$check (step_status = any (array['done','tried_failed','not_tried']))$q$),
      ('daily_logs','chk_daily_logs_source',
       $q$check (source = any (array['legacy','rhythm']))$q$),
      -- A rhythm night cannot carry an answer to a question that was never
      -- asked, and a seed cannot be sent without something real to stand on.
      -- These two are the rhythm's honesty, enforced in the schema.
      ('daily_logs','chk_harvest_needs_seed',
       $q$check (source <> 'rhythm' or (night_result is null and step_status is null and harvest_answered_at is null) or seed_sent_at is not null)$q$),
      ('daily_logs','chk_seed_grounded',
       $q$check (source <> 'rhythm' or seed_sent_at is null or (seed_grounded_on is not null and jsonb_typeof(seed_grounded_on) = 'array' and jsonb_array_length(seed_grounded_on) > 0))$q$),

      ('weekly_plans','weekly_plans_pkey','primary key (id)'),
      ('weekly_plans','weekly_plans_follower_id_week_number_key','unique (follower_id, week_number)'),
      ('weekly_plans','weekly_plans_follower_id_fkey',
       'foreign key (follower_id) references public.followers(id) on delete cascade'),
      ('weekly_plans','weekly_plans_child_id_fkey',
       'foreign key (child_id) references public.children(id) on delete set null'),
      ('weekly_plans','weekly_plans_status_check',
       $q$check (status = any (array['planned','active','done','skipped']))$q$),
      ('weekly_plans','weekly_plans_week_number_check','check (week_number >= 1)'),

      ('memory_events','memory_events_pkey','primary key (id)'),
      ('memory_events','memory_events_follower_id_fkey',
       'foreign key (follower_id) references public.followers(id) on delete cascade'),
      ('memory_events','memory_events_child_id_fkey',
       'foreign key (child_id) references public.children(id) on delete set null'),
      ('memory_events','memory_events_event_type_check',
       $q$check (event_type = any (array['win','breakthrough','setback','disclosure','milestone','pattern_change','other']))$q$),
      ('memory_events','memory_events_emotional_weight_check',
       'check (emotional_weight >= 1 and emotional_weight <= 5)'),
      ('memory_events','memory_events_source_check',
       $q$check (source = any (array['agent_extraction','manual','system']))$q$),

      ('memory_snapshots','memory_snapshots_pkey','primary key (follower_id)'),
      ('memory_snapshots','memory_snapshots_follower_id_fkey',
       'foreign key (follower_id) references public.followers(id) on delete cascade'),

      ('plan_sessions','plan_sessions_pkey','primary key (id)'),
      ('plan_sessions','plan_sessions_follower_id_unique','unique (follower_id)'),
      ('plan_sessions','plan_sessions_follower_id_fkey',
       'foreign key (follower_id) references public.followers(id) on delete cascade'),
      ('plan_sessions','plan_sessions_progress_score_check',
       'check (progress_score >= 0 and progress_score <= 100)'),

      ('follower_insights','follower_insights_pkey','primary key (id)'),
      ('follower_insights','follower_insights_follower_id_fkey',
       'foreign key (follower_id) references public.followers(id) on delete cascade'),

      ('n8n_chat_histories','n8n_chat_histories_pkey','primary key (id)'),
      ('session_tracker','session_tracker_pkey','primary key (platform_user_id)'),
      ('survey_responses','survey_responses_pkey','primary key (id)'),

      -- payments' FK has NO on delete clause, deliberately: the financial
      -- record must not vanish with the person. execute_erasure() nulls the
      -- link and writes '[erased]' instead.
      ('payments','payments_pkey','primary key (id)'),
      ('payments','payments_follower_id_fkey',
       'foreign key (follower_id) references public.followers(id)'),

      ('supported_countries','supported_countries_pkey','primary key (code)'),
      -- A market cannot be switched on without every price it will be asked
      -- for. This is why get_pricing() can promise exactly one row.
      ('supported_countries','chk_active_market_has_pricing',
       $q$check (not is_active or (price_subscription is not null and price_continuation is not null and price_display_full is not null and price_continuation_display is not null))$q$)
    ) as v(tbl, name, def)
  loop
    if not exists (select 1 from pg_constraint where conname = c.name
                     and conrelid = ('public.' || c.tbl)::regclass) then
      execute format('alter table public.%I add constraint %I %s', c.tbl, c.name, c.def);
    end if;
  end loop;
end $baseline$;

-- ── Indexes ───────────────────────────────────────────────────────────────────
--
-- The uq_* unique indexes duplicate the unique CONSTRAINTS above, on the same
-- columns. Reproduced because they exist; §3 is where redundancy gets removed,
-- not here.

create index        if not exists idx_followers_country            on public.followers (country);
create index        if not exists idx_followers_funnel_stage       on public.followers (funnel_stage);
create index        if not exists idx_followers_payment_status     on public.followers (payment_status);
create index        if not exists idx_followers_judge_candidates   on public.followers (last_active)
  where funnel_stage = 'free_conversation';

create index        if not exists idx_children_follower            on public.children (follower_id);
create unique index if not exists uq_children_follower_name        on public.children (follower_id, name);

create index        if not exists idx_patterns_follower_status     on public.child_patterns (follower_id, status);
create unique index if not exists uq_child_patterns_follower_label on public.child_patterns (follower_id, pattern_label);

create index        if not exists idx_daily_logs_child             on public.daily_logs (child_id);
create index        if not exists idx_daily_logs_follower_date     on public.daily_logs (follower_id, log_date desc);
create index        if not exists idx_dailylogs_follower_date      on public.daily_logs (follower_id, log_date desc);
create index        if not exists idx_daily_logs_journey           on public.daily_logs (journey_id);
create index        if not exists idx_daily_logs_seed_due          on public.daily_logs (seed_scheduled_for)
  where seed_sent_at is null;
create unique index if not exists uq_daily_logs_follower_date      on public.daily_logs (follower_id, log_date);

create index        if not exists idx_weekly_plans_child           on public.weekly_plans (child_id);
create index        if not exists idx_weeklyplans_follower         on public.weekly_plans (follower_id, week_number);

create index        if not exists idx_memevents_follower_time      on public.memory_events (follower_id, occurred_at desc);
create index        if not exists idx_memevents_type               on public.memory_events (event_type);
create unique index if not exists uq_memory_snapshots_follower     on public.memory_snapshots (follower_id);

create index        if not exists idx_plan_sessions_follower       on public.plan_sessions (follower_id);
create index        if not exists idx_chat_hist_session_created    on public.n8n_chat_histories (session_id, created_at);
create index        if not exists idx_survey_responses_user        on public.survey_responses (platform_user_id);
create index        if not exists idx_payments_follower_id         on public.payments (follower_id);
create index        if not exists idx_payments_status              on public.payments (status);

-- ── Row level security ────────────────────────────────────────────────────────
--
-- Every one of these tables has RLS ON with a single service_role ALL policy,
-- and supported_countries additionally lets anon read — prices are public, and
-- nothing else is. Enabling RLS without the policy would lock out the product,
-- so both halves belong in the same file.

do $baseline$
declare t text;
begin
  foreach t in array array[
    'followers','children','child_patterns','daily_logs','weekly_plans',
    'memory_events','memory_snapshots','plan_sessions','follower_insights',
    'n8n_chat_histories','session_tracker','survey_responses','payments',
    'supported_countries'
  ] loop
    execute format('alter table public.%I enable row level security', t);
  end loop;
end $baseline$;

do $baseline$
declare
  p record;
begin
  for p in
    select * from (values
      ('followers','service_role_full_access'),
      ('children','srv_all_children'),
      ('child_patterns','srv_all_child_patterns'),
      ('daily_logs','srv_all_daily_logs'),
      ('weekly_plans','srv_all_weekly_plans'),
      ('memory_events','srv_all_memory_events'),
      ('memory_snapshots','srv_all_memory_snapshots'),
      ('plan_sessions','service_role_all_plan_sessions'),
      ('follower_insights','service_role_full_access'),
      ('n8n_chat_histories','service_role_full_access'),
      ('session_tracker','srv_all_session_tracker'),
      ('survey_responses','survey_responses_service_all'),
      ('payments','service_role_all_payments'),
      ('supported_countries','srv_all_supported_countries')
    ) as v(tbl, name)
  loop
    if not exists (select 1 from pg_policies
                    where schemaname = 'public' and tablename = p.tbl and policyname = p.name) then
      execute format(
        'create policy %I on public.%I for all to service_role using (true) with check (true)',
        p.name, p.tbl);
    end if;
  end loop;

  if not exists (select 1 from pg_policies where schemaname = 'public'
                   and tablename = 'supported_countries'
                   and policyname = 'anon_read_supported_countries') then
    create policy anon_read_supported_countries
      on public.supported_countries for select to anon using (true);
  end if;
end $baseline$;

commit;
