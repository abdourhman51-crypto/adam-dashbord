-- Delete the legacy evening system
--
-- docs/what-is-missing.md §3, first row. Two systems have been sending an
-- evening question: the checkin engine (29 July) and the rhythm (30 July). The
-- checkin engine goes.
--
-- §3 SAID `checkin_state` GOES WITH IT. §3 WAS WRONG, and this is why the
-- deletion was worth doing slowly. The table was never replaced — the rhythm
-- adopted it. Five live functions depend on it right now:
--
--   get_rhythm_due        joins it, and skips anyone whose cadence is 'stopped'
--   get_telegram_surface  reads it, to show a paused parent «كيف نعود؟»
--   record_harvest_answer updates it, resetting the ignore streak on an answer
--   get_moment_after_tap  writes it, when a parent taps pause / resume / stop
--   set_checkin_hour      writes it, when a parent chooses their evening hour
--
-- Dropping `checkin_state` would have taken the rhythm's pause, resume, stop and
-- hour-of-evening with it — the whole of a parent's control over when ADAM
-- speaks. The table stays. So does `daily_logs.checkin_sent_at`, which the live
-- `CK - Save Night Result` node still writes.
--
-- What actually goes is four functions nothing calls — verified against every
-- other function's source (no callers) and against the live workflow's reachable
-- node graph (11 Supabase endpoints, none of them these):
--
--   get_checkin_batch()          → get_rhythm_due()
--   record_checkin_sent()        → record_seed_sent() / record_harvest_sent()
--   record_checkin_response()    → record_harvest_answer()
--   ensure_checkin_state()       → set_checkin_hour() / get_moment_after_tap()
--
-- A fifth, decay_checkin_consent, looks dead and is not. It is INERT: it counts
-- an ignored night from `checkin_state.last_sent_date`, which only
-- record_checkin_sent ever wrote. Deleting it would quietly delete the principle
-- that silence is an answer. It is rebuilt on the rhythm's own evidence in
-- 20260807190000, and only that is why it is safe to leave it standing here.
--
-- And three `followers` columns, the legacy consent record. Nothing live reads
-- them: the only workflow node that mentions checkin_opt_in is
-- `OB - Save Checkin Choice`, which is unreachable from the trigger.

begin;

-- ── Archive before dropping ───────────────────────────────────────────────────
--
-- 15 parents answered the old opt-in question and 5 were sent an old check-in.
-- That is a small number and a real one: it is the record of what ADAM asked
-- them and what they said. Following the archive.*_YYYYMMDD convention already
-- in this database.

create schema if not exists archive;

create table if not exists archive.followers_checkin_20260807 as
select id as follower_id, platform_user_id, checkin_opt_in, checkin_opted_at,
       last_checkin_sent_date, now() as archived_at
from public.followers
where checkin_opt_in is not null
   or checkin_opted_at is not null
   or last_checkin_sent_date is not null;

comment on table archive.followers_checkin_20260807 is
  'The legacy opt-in consent record, archived when the checkin engine was '
  'deleted on 2026-08-07. Kept because it records what parents were asked and '
  'what they answered, which the columns themselves no longer do.';

-- ── The four functions nothing calls ──────────────────────────────────────────

drop function if exists public.get_checkin_batch();
drop function if exists public.record_checkin_sent(uuid, date);
drop function if exists public.record_checkin_response(uuid, text, text, text);
drop function if exists public.ensure_checkin_state(uuid);

-- ── The legacy consent columns ────────────────────────────────────────────────

alter table public.followers drop column if exists checkin_opt_in;
alter table public.followers drop column if exists checkin_opted_at;
alter table public.followers drop column if exists last_checkin_sent_date;

comment on table public.checkin_state is
  'The rhythm''s state, not the old checkin engine''s. Cadence, the parent''s '
  'chosen evening hour, pause and stop. Named for the system that created it '
  'and kept by the system that replaced it.';

commit;
