-- Week-0 hardening · pin search_path on the remaining legacy functions
-- Supabase advisor 0011 (function_search_path_mutable). A mutable search_path
-- lets a caller place a schema earlier in their path and shadow a built-in the
-- function relies on. For SECURITY DEFINER functions that is a
-- privilege-escalation vector; for the rest a correctness one.
-- -- Six of these — get_followup_candidates, get_live_offer_signal,
-- get_offer_candidates, get_renewal_actions, increment_waitlist_daily and
-- update_follower_message_count — were DROPPED an hour later by
-- 20260729160000_cleanup_drop_legacy_selling_and_dead_objects.sql and do not
-- exist in production today. A rebuild from this repository therefore never
-- creates them, and an unguarded ALTER on a missing function aborts the file,
-- leaving the functions that DO survive with a mutable search_path — the exact
-- privilege-escalation vector this migration closes. Each is pinned only if it
-- is there. The list is left whole rather than trimmed to the survivors: it is
-- the record of what was running on 29 July.
DO $pin$
DECLARE f text;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public._ensure_child(uuid, text)',
    'public.get_agent_context(uuid)',
    'public.get_extraction_batch(integer)',
    'public.get_followup_candidates()',
    'public.get_live_offer_signal(integer, integer)',
    'public.get_offer_candidates()',
    'public.get_renewal_actions()',
    'public.increment_follower_message(uuid)',
    'public.increment_waitlist_daily(uuid)',
    'public.set_updated_at()',
    'public.update_follower_message_count()',
    'public.write_child_name(text, text)',
    'public.writer_commit(uuid, integer, jsonb)'
  ] LOOP
    IF to_regprocedure(f) IS NOT NULL THEN
      EXECUTE 'ALTER FUNCTION ' || f || ' SET search_path = pg_catalog, public';
    END IF;
  END LOOP;
END $pin$;
