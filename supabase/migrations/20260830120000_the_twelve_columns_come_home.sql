begin;

-- ============================================================
-- THE TWELVE COLUMNS COME HOME
--
-- The same drift as the functions, one layer down. Twelve
-- columns existed only in production, added by hand while
-- shipping and never written to a migration. A database rebuilt
-- from this repository was missing all twelve, so the functions
-- that read them could not even be created — which is exactly
-- how the drift stayed invisible: nobody could get far enough
-- into a rebuild to notice.
--
-- Taken from production on 2026-08-30. Every one is nullable
-- with no default, so this file is safe to run against a
-- database that already has them (IF NOT EXISTS) and changes
-- nothing for existing rows.
-- ============================================================

-- The win-back message is sent at most once per parent. Without
-- this column the send has no memory and would repeat forever.
alter table public.checkin_state
  add column if not exists winback_sent_at timestamptz;

-- A pattern is spoken to a parent once. This is the mark that
-- says it already was.
alter table public.child_patterns
  add column if not exists revealed_at timestamptz;

alter table public.children
  add column if not exists situation_checked_at timestamptz;

-- The parent's answer to «هل ستجرّبونها الليلة؟», and the moment
-- they committed to the day's step. Intent and follow-through are
-- deliberately two different columns: promising is not doing, and
-- the difference between them is a real measurement.
alter table public.daily_logs
  add column if not exists seed_intent text,
  add column if not exists seed_intent_at timestamptz,
  add column if not exists step_committed_at timestamptz;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.daily_logs'::regclass
      and conname = 'daily_logs_seed_intent_check')
  then
    alter table public.daily_logs
      add constraint daily_logs_seed_intent_check
      check (seed_intent is null or seed_intent = any (array['will_try','not_tonight']));
  end if;
end $$;

alter table public.followers
  add column if not exists activation_welcome_sent_at timestamptz,
  add column if not exists journey_form_state jsonb,
  add column if not exists last_pattern_reflection_at timestamptz,
  add column if not exists strain_checked_at timestamptz;

-- What the parent said was wrong, in their own words, and how
-- often. Kept on the stage so ADAM can say it back later («زي ما
-- حكيتوا لي عن...») instead of speaking in the abstract.
alter table public.stages
  add column if not exists problem_context_text text,
  add column if not exists frequency_label text;

commit;
