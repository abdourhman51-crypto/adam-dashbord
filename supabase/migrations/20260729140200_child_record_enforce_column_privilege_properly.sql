-- ============================================================================
-- CORRECTION · make the column privilege actually take effect
-- ============================================================================
-- DEFECT
--   The earlier statement
--     REVOKE UPDATE (safe_for_record) ON child_patterns FROM service_role;
--   had no effect. Verified afterwards:
--     has_column_privilege('service_role','child_patterns','safe_for_record','UPDATE')
--       -> true
--
--   In PostgreSQL a column-level REVOKE cannot subtract from a TABLE-level
--   grant. service_role held UPDATE on the whole table from an earlier
--   migration, and a table-level grant implies every column, so the revoke was
--   silently a no-op.
--
--   The exposure was covered by the guard trigger throughout (H2, H3 and H4 all
--   blocked), so nothing leaked. But a defence that is claimed and does not
--   hold is worse than one never claimed, because it invites reliance.
-- ============================================================================

REVOKE UPDATE ON public.child_patterns FROM service_role, anon, authenticated;

GRANT UPDATE (
  follower_id, child_id, pattern_label, description,
  status, evidence_count, first_observed, last_observed, updated_at
) ON public.child_patterns TO service_role;

COMMENT ON TABLE public.child_patterns IS
  'Behavioural patterns extracted from conversation. service_role holds UPDATE '
  'on every column EXCEPT safe_for_record, which is granted to no application '
  'role at all. A column-level REVOKE alone does not achieve this -- the '
  'table-level grant must be revoked first, then re-granted per column.';
