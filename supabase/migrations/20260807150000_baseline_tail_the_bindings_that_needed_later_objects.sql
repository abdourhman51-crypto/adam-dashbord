-- Baseline tail: the bindings that could not be made at week 0
--
-- 20260729000000_baseline_the_tables_that_predate_the_repo.sql brings the
-- fourteen pre-repo tables back into git. Four things it could not carry, because
-- they point at objects that later migrations create:
--
--   * daily_logs → stages       (created 20260729130100, the journey engine)
--   * daily_logs → situations   (created 20260730173226)
--   * seven triggers            (set_updated_at, guard_safe_for_record and
--                                guard_chat_history_message — the first restored
--                                20260807140000, the other two in the week 0 and
--                                child-record migrations)
--   * idx_chat_hist_norm_session, which indexes normalise_session_key(session_id)
--
-- Putting them in the baseline behind an "if the table exists" guard would have
-- been worse than leaving them out: on a rebuild the guard is false, the binding
-- is silently never made, and the result looks like production without being it.
-- Dated last instead, so a rebuild reaches this file with everything in place.
--
-- No-op against production, which already has all four.

begin;

-- ── The two foreign keys that reach forward ───────────────────────────────────
--
-- Both ON DELETE SET NULL, not CASCADE: closing a journey, or retiring a
-- situation, must never delete the nights a parent lived through. The evidence
-- outlives the thing that organised it.

do $tail$
begin
  if not exists (select 1 from pg_constraint
                  where conname = 'daily_logs_journey_id_fkey'
                    and conrelid = 'public.daily_logs'::regclass) then
    alter table public.daily_logs
      add constraint daily_logs_journey_id_fkey
      foreign key (journey_id) references public.stages(id) on delete set null;
  end if;

  if not exists (select 1 from pg_constraint
                  where conname = 'daily_logs_situation_id_fkey'
                    and conrelid = 'public.daily_logs'::regclass) then
    alter table public.daily_logs
      add constraint daily_logs_situation_id_fkey
      foreign key (situation_id) references public.situations(id) on delete set null;
  end if;
end $tail$;

-- ── The index over the normalised session key ─────────────────────────────────
--
-- Session ids drifted three ways ('123', '123_s4', '=123'). Readers go through
-- normalise_session_key(), so the index has to be over the call, not the column,
-- or every one of them is a sequential scan.

create index if not exists idx_chat_hist_norm_session
  on public.n8n_chat_histories (public.normalise_session_key(session_id::text));

-- ── The triggers ──────────────────────────────────────────────────────────────
--
-- CREATE TRIGGER has no IF NOT EXISTS. DROP-then-CREATE is safe here because a
-- trigger carries no state — unlike the constraints above, re-creating one
-- changes nothing about the rows already in the table.

drop trigger if exists trg_children_updated on public.children;
create trigger trg_children_updated
  before update on public.children
  for each row execute function public.set_updated_at();

drop trigger if exists trg_patterns_updated on public.child_patterns;
create trigger trg_patterns_updated
  before update on public.child_patterns
  for each row execute function public.set_updated_at();

drop trigger if exists trg_dailylogs_updated on public.daily_logs;
create trigger trg_dailylogs_updated
  before update on public.daily_logs
  for each row execute function public.set_updated_at();

drop trigger if exists trg_weeklyplans_updated on public.weekly_plans;
create trigger trg_weeklyplans_updated
  before update on public.weekly_plans
  for each row execute function public.set_updated_at();

drop trigger if exists trg_snapshots_updated on public.memory_snapshots;
create trigger trg_snapshots_updated
  before update on public.memory_snapshots
  for each row execute function public.set_updated_at();

-- Granting safe_for_record requires an audit row written in the same
-- transaction; revoking is always allowed; editing approved text withdraws the
-- approval. The column default is only the first line — this is the law.
drop trigger if exists trg_guard_safe_for_record on public.child_patterns;
create trigger trg_guard_safe_for_record
  before insert or update on public.child_patterns
  for each row execute function public.guard_safe_for_record();

-- One 169,230-character message was stored once. The ceiling is 12,000, applied
-- at the door, and the truncation says so in the text rather than hiding.
drop trigger if exists trg_guard_chat_history_message on public.n8n_chat_histories;
create trigger trg_guard_chat_history_message
  before insert or update on public.n8n_chat_histories
  for each row execute function public.guard_chat_history_message();

commit;
