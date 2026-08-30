begin;

-- ============================================================
-- A NOTE, NOT A CHANGE.
--
-- Phase 1 built a tantrum reading engine: tantrum_kind_catalog,
-- tantrum_driver_catalog, tantrum_phase_catalog,
-- tantrum_age_expectation, the `incidents` table, and
-- can_read_incident / get_tantrum_frame / commit_incident.
--
-- As of 2026-08-30 nothing calls any of it.
--
-- Its only consumer was the mini app's /api/panic route, and the
-- panic button was rewritten to address the PARENT's own loss of
-- control rather than the child's tantrum — because reading
-- 5,712 real messages showed that is what parents actually
-- disclose, and because a parent at the edge cannot wait for a
-- round trip. Its scripts are now inline in
-- components/PanicButton.tsx and its data lands in
-- parent_moments. The route has been deleted rather than left
-- unreachable.
--
-- NOTHING IS DROPPED HERE, deliberately. The engine is correct,
-- tested (supabase/tests/tantrum_reading_test.sql, 32/32), and
-- costs nothing while idle. Dropping a working engine is a
-- product decision, not a cleanup, and it belongs to the team:
--
--   * Wire it up — the calm place for a reading is the طفلي
--     screen, not the crisis moment: what kind of tantrum this
--     child has, what drives it, what backfires at each phase,
--     and what is normal for the age. That is the one screen
--     where a parent has the attention to read it.
--   * Or drop it — one migration, and the four catalogs and the
--     incidents table go.
--
-- Until one of those is chosen, this comment is what stops the
-- next person from assuming it is load-bearing.
-- ============================================================

comment on table public.incidents is
  'A single tantrum, as read: kind, driver, phase. WRITTEN BY NOBODY as of 2026-08-30 — the panic button that fed it moved into the mini app and now addresses the parent instead. See 20260830160000 before assuming this table is live.';

commit;
