-- ============================================================================
-- Cleanup: relocate the 2026-07-08 archive tables into a private schema
-- ============================================================================
--
-- Nine tables suffixed _archive_20260708 hold a snapshot taken during the July
-- restructure. They contain REAL production history — 3,428 conversation rows,
-- 132 follower records, 102 plan sessions — so they are never dropped.
--
-- They do not belong in public. Two reasons:
--
--   1. PostgREST exposes the public schema. Week-0 revoked anonymous read of
--      parent data table by table; a snapshot sitting alongside live tables is
--      one forgotten GRANT away from re-exposing the same conversations that
--      exposure closed. A schema PostgREST does not serve cannot leak through
--      the API at all.
--
--   2. They are indistinguishable at a glance from live tables, which is how a
--      future query joins the wrong one.
--
-- Moving rather than copying keeps exactly one copy of the data.
-- ============================================================================

begin;

create schema if not exists archive;

comment on schema archive is
  'Frozen historical snapshots. Not served by PostgREST, not read by any '
  'workflow or dashboard page. Read-only reference for auditing what the '
  'product looked like before the 2026-07 restructure.';

alter table if exists public.child_patterns_archive_20260708    set schema archive;
alter table if exists public.children_archive_20260708          set schema archive;
alter table if exists public.daily_logs_archive_20260708        set schema archive;
alter table if exists public.followers_archive_20260708         set schema archive;
alter table if exists public.memory_events_archive_20260708     set schema archive;
alter table if exists public.memory_snapshots_archive_20260708  set schema archive;
alter table if exists public.n8n_chat_histories_archive_20260708 set schema archive;
alter table if exists public.plan_sessions_archive_20260708     set schema archive;
alter table if exists public.session_tracker_archive_20260708   set schema archive;

-- The API roles must not reach this schema at all.
revoke all on schema archive from anon, authenticated, public;
revoke all on all tables in schema archive from anon, authenticated, public;

grant usage on schema archive to service_role;
grant select on all tables in schema archive to service_role;

-- Anything added here later inherits the same posture.
alter default privileges in schema archive
  revoke all on tables from anon, authenticated, public;

commit;
