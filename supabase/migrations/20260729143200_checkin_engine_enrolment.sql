-- ============================================================================
-- Nightly Check-in Engine · enrolment
-- ============================================================================
-- DECISION: enrol on a real exchange, never in bulk.
--   234 parents have a resolvable timezone but only 12 carry check-in state.
--   Backfilling all 234 and starting the rhythm tonight is the wrong call:
--   - The approved journey earns the rhythm through an exchange. ADAM's first
--     moment ends with "أخبريني الليلة كيف كانت" -- the check-in is the second
--     half of a conversation she already had, not a broadcast.
--   - Most of those parents last spoke weeks ago. A nightly message to a
--     dormant stranger is how ADAM becomes the thing she mutes, and the trust
--     guardrail is a block rate under 2%.
--   - Blueprint v1 already caps re-engagement at one message per lifetime.
--   Reach grows because parents talk, not because a table was filled.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.ensure_checkin_state(p_parent_id uuid)
RETURNS text LANGUAGE plpgsql VOLATILE SECURITY INVOKER
SET search_path = pg_catalog, public
AS $$
DECLARE v_tz text; v_existing text;
BEGIN
  SELECT cadence INTO v_existing FROM public.checkin_state WHERE parent_id = p_parent_id;
  IF v_existing IS NOT NULL THEN RETURN v_existing; END IF;  -- never resurrect

  SELECT ct.iana_tz INTO v_tz FROM public.followers f
    JOIN public.country_timezone ct ON ct.code = upper(btrim(f.country))
   WHERE f.id = p_parent_id;
  IF v_tz IS NULL THEN RETURN 'unschedulable'; END IF;

  INSERT INTO public.checkin_state (parent_id, cadence) VALUES (p_parent_id, 'nightly')
  ON CONFLICT (parent_id) DO NOTHING;
  RETURN 'nightly';
END $$;

COMMENT ON FUNCTION public.ensure_checkin_state(uuid) IS
  'Called from the conversation path when a parent engages. Creates the '
  'rhythm only when her local evening is known, and never resurrects a cadence '
  'she wound down.';

REVOKE EXECUTE ON FUNCTION public.ensure_checkin_state(uuid) FROM anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.ensure_checkin_state(uuid) TO service_role;
