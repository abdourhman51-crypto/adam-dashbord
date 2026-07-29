-- Week-0 hardening · pin search_path on the remaining legacy functions
-- Supabase advisor 0011 (function_search_path_mutable). A mutable search_path
-- lets a caller place a schema earlier in their path and shadow a built-in the
-- function relies on. For SECURITY DEFINER functions that is a
-- privilege-escalation vector; for the rest a correctness one.
-- ALTER FUNCTION ... SET search_path changes only the setting, never the body.

ALTER FUNCTION public._ensure_child(uuid, text)               SET search_path = pg_catalog, public;
ALTER FUNCTION public.get_agent_context(uuid)                 SET search_path = pg_catalog, public;
ALTER FUNCTION public.get_extraction_batch(integer)           SET search_path = pg_catalog, public;
ALTER FUNCTION public.get_followup_candidates()               SET search_path = pg_catalog, public;
ALTER FUNCTION public.get_live_offer_signal(integer, integer) SET search_path = pg_catalog, public;
ALTER FUNCTION public.get_offer_candidates()                  SET search_path = pg_catalog, public;
ALTER FUNCTION public.get_renewal_actions()                   SET search_path = pg_catalog, public;
ALTER FUNCTION public.increment_follower_message(uuid)        SET search_path = pg_catalog, public;
ALTER FUNCTION public.increment_waitlist_daily(uuid)          SET search_path = pg_catalog, public;
ALTER FUNCTION public.set_updated_at()                        SET search_path = pg_catalog, public;
ALTER FUNCTION public.update_follower_message_count()         SET search_path = pg_catalog, public;
ALTER FUNCTION public.write_child_name(text, text)            SET search_path = pg_catalog, public;
ALTER FUNCTION public.writer_commit(uuid, integer, jsonb)     SET search_path = pg_catalog, public;
