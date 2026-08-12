-- Silence is still an answer
--
-- `decay_checkin_consent` is the rule that a parent who stops replying is
-- gradually left alone: five ignored nights quieten the rhythm from nightly to
-- weekly, nine more stop it, and one reply brings it back. It is the product's
-- consent model, and it has been INERT since 30 July.
--
-- It counted an ignored night from `checkin_state.last_sent_date`. Only
-- `record_checkin_sent` ever wrote that column, and that function belonged to
-- the checkin engine, deleted in 20260807180000. The rhythm records its evening
-- question on `daily_logs` instead — `harvest_sent_at` when it asks,
-- `harvest_answered_at` when she answers — so `last_sent_date` has been null or
-- frozen for every parent since, and `consecutive_ignored` has never once been
-- incremented.
--
-- The recovery half never broke: `record_harvest_answer` still resets the streak
-- and revives a stopped cadence. So the live behaviour today is a rhythm that
-- can recover from silence it never notices — it would have gone on asking
-- nightly, forever, of someone who had stopped answering weeks ago. For a
-- product whose first principle is that it must be possible to be left alone,
-- that is the worst possible half to have working.
--
-- Rebuilt here on the rhythm's own evidence. Deliberately NOT deleted along with
-- the rest of the checkin engine: deleting an inert function is how a principle
-- disappears without anyone deciding to drop it.
--
-- Two design points worth stating, because both are about not punishing a parent
-- for our own faults:
--
--   * Only a night the rhythm actually ASKED about counts. `harvest_sent_at is
--     not null and harvest_answered_at is null` — if the sender never ran, or
--     never reached her, that is our silence, not hers.
--   * The scan is idempotent and catches up. `last_decayed_on` marks how far the
--     count has been taken, so running twice in a day counts nothing twice, and
--     a week when nobody ran the job is not forgiven — it is simply counted late.

begin;

alter table public.checkin_state
  add column if not exists last_decayed_on date;

comment on column public.checkin_state.last_decayed_on is
  'How far decay_checkin_consent has counted. Makes the scan idempotent within '
  'a day and able to catch up after a day it did not run.';

create or replace function public.decay_checkin_consent()
returns table(parent_id uuid, action text, new_cadence text)
language plpgsql
set search_path to 'pg_catalog', 'public'
as $fn$
begin
  -- An ignored night is one the rhythm ASKED about and she did not answer.
  -- Counted only for days after the last one already counted, and never for
  -- today, which is not over.
  with unanswered as (
    select cs.parent_id, count(*) as n, max(d.log_date) as newest
      from public.checkin_state cs
      join public.daily_logs d on d.follower_id = cs.parent_id
     where d.source = 'rhythm'
       and d.harvest_sent_at is not null
       and d.harvest_answered_at is null
       and d.log_date < current_date
       and d.log_date > coalesce(cs.last_decayed_on, '-infinity'::date)
     group by cs.parent_id
  )
  update public.checkin_state cs
     set consecutive_ignored = cs.consecutive_ignored + u.n,
         last_decayed_on     = u.newest,
         updated_at          = now()
    from unanswered u
   where u.parent_id = cs.parent_id;

  -- Everyone else's watermark still moves, so a parent who answers every night
  -- is not re-scanned from the beginning of time on every run.
  update public.checkin_state cs
     set last_decayed_on = current_date - 1
   where coalesce(cs.last_decayed_on, '-infinity'::date) < current_date - 1;

  return query
  with stepped as (
    update public.checkin_state cs
       set cadence = case
             when cs.cadence = 'nightly' and cs.consecutive_ignored >= 5 then 'weekly'
             when cs.cadence = 'weekly'  and cs.consecutive_ignored >= 9 then 'stopped'
             else cs.cadence end,
           -- The streak resets on the step DOWN, so the next nine are counted
           -- from the quieter cadence rather than from where she already was.
           consecutive_ignored = case
             when cs.cadence = 'nightly' and cs.consecutive_ignored >= 5 then 0
             else cs.consecutive_ignored end,
           cadence_changed_at = now(),
           updated_at         = now()
     where (cs.cadence = 'nightly' and cs.consecutive_ignored >= 5)
        or (cs.cadence = 'weekly'  and cs.consecutive_ignored >= 9)
     returning cs.parent_id, cs.cadence
  )
  select s.parent_id,
         case s.cadence when 'weekly'  then 'quietened_to_weekly'
                        when 'stopped' then 'stopped_proactive' end,
         s.cadence
  from stepped s;
end $fn$;

comment on function public.decay_checkin_consent() is
  'Silence is an answer. Counts evenings the rhythm asked about and she did '
  'not answer; five quieten it to weekly, nine more stop it. '
  'record_harvest_answer is the other half — one reply resets the streak and '
  'revives a stopped cadence. Idempotent within a day, and catches up after a '
  'day it did not run.';

commit;
