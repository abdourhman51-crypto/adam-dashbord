-- ============================================================================
-- Week-0 SECURITY · revoke anonymous read access to parent and child data
-- ============================================================================
-- FINDING (2026-07-29, verified by executing as the anon role)
--   17 permissive RLS policies with USING (true) granted the `anon` role --
--   and in three cases the broader `public` role -- SELECT on effectively the
--   entire dataset:
--
--     n8n_chat_histories   4174 rows   intimate parent conversations
--     followers             290 rows   every parent, country, payment status
--     children                3 rows   named, identifiable children
--     payments, daily_logs, memory_events, memory_snapshots,
--     plan_sessions, child_patterns, session_tracker, weekly_plans,
--     follower_insights, collective_intelligence
--
--   The Supabase anon key is public by design: it ships inside client
--   bundles. API logs for 2026-07-29 show a mobile browser (Chrome/Android)
--   reading /rest/v1/n8n_chat_histories directly, which confirms the key is
--   present in a client and not merely server-side.
--
--   The conversations contain disclosures of third-party child abuse,
--   parental violence, bereavement and suicidal ideation, alongside named
--   children. Anyone holding the anon key could read all of it.
--
-- DECISION
--   Row-level parent and child data is service_role only. An internal
--   operator dashboard must read it server-side with the service key, which
--   is already provisioned (SUPABASE_SERVICE_ROLE_KEY, documented in
--   .env.local as "server only, never reaches the browser").
--
--   supported_countries is deliberately left readable: country codes and
--   public list prices carry no personal data.
--
-- REVERSIBILITY
--   Every statement is a DROP POLICY / REVOKE. To restore one table during an
--   incident:
--     CREATE POLICY anon_read_<t> ON public.<t> FOR SELECT TO anon USING (true);
--     GRANT SELECT ON public.<t> TO anon;
--   Restoring is not recommended; migrate the reader to the service key.
--
-- EXPECTED BREAKAGE
--   Any dashboard read performed with the anon key returns zero rows or a
--   permission error until that reader is switched to the service key.
-- ============================================================================

DROP POLICY IF EXISTS "anon read n8n_chat_histories"      ON public.n8n_chat_histories;
DROP POLICY IF EXISTS anon_select_followers               ON public.followers;
DROP POLICY IF EXISTS dashboard_read                      ON public.followers;
DROP POLICY IF EXISTS anon_select_payments                ON public.payments;
DROP POLICY IF EXISTS dashboard_read                      ON public.payments;
DROP POLICY IF EXISTS anon_read_children                  ON public.children;
DROP POLICY IF EXISTS anon_read_child_patterns            ON public.child_patterns;
DROP POLICY IF EXISTS anon_read_daily_logs                ON public.daily_logs;
DROP POLICY IF EXISTS anon_read_memory_events             ON public.memory_events;
DROP POLICY IF EXISTS anon_read_memory_snapshots          ON public.memory_snapshots;
DROP POLICY IF EXISTS anon_select_plan_sessions           ON public.plan_sessions;
DROP POLICY IF EXISTS anon_read_session_tracker           ON public.session_tracker;
DROP POLICY IF EXISTS anon_read_weekly_plans              ON public.weekly_plans;
DROP POLICY IF EXISTS anon_read_follower_insights         ON public.follower_insights;

REVOKE SELECT ON public.n8n_chat_histories      FROM anon, authenticated;
REVOKE SELECT ON public.followers               FROM anon, authenticated;
REVOKE SELECT ON public.payments                FROM anon, authenticated;
REVOKE SELECT ON public.children                FROM anon, authenticated;
REVOKE SELECT ON public.child_patterns          FROM anon, authenticated;
REVOKE SELECT ON public.daily_logs              FROM anon, authenticated;
REVOKE SELECT ON public.memory_events           FROM anon, authenticated;
REVOKE SELECT ON public.memory_snapshots        FROM anon, authenticated;
REVOKE SELECT ON public.plan_sessions           FROM anon, authenticated;
REVOKE SELECT ON public.session_tracker         FROM anon, authenticated;
REVOKE SELECT ON public.weekly_plans            FROM anon, authenticated;
REVOKE SELECT ON public.follower_insights       FROM anon, authenticated;
REVOKE SELECT ON public.survey_responses        FROM anon, authenticated;

-- `messages` and `collective_intelligence` were revoked here too when this ran.
-- Both tables have since been dropped, so a rebuild from this repository never
-- creates them and the unguarded statements aborted the whole file — taking the
-- rest of the revocations with them and leaving anon able to read parent data,
-- which is the exact opposite of what this migration is for. Guarded rather than
-- deleted: the revocation genuinely happened, and a database restored from an
-- old backup would still need it.
DO $legacy$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['messages','collective_intelligence'] LOOP
    IF to_regclass('public.' || t) IS NOT NULL THEN
      EXECUTE format('REVOKE SELECT ON public.%I FROM anon, authenticated', t);
    END IF;
  END LOOP;
END $legacy$;

-- Dashboard views are SECURITY DEFINER and bypass RLS; leaving anon able to
-- SELECT them would reinstate the whole exposure through the back door.
REVOKE SELECT ON public.v_funnel_summary        FROM anon, authenticated;
REVOKE SELECT ON public.v_funnel_weekly         FROM anon, authenticated;
REVOKE SELECT ON public.v_offers_log            FROM anon, authenticated;
REVOKE SELECT ON public.v_conversations_list    FROM anon, authenticated;
REVOKE SELECT ON public.v_renewal_summary       FROM anon, authenticated;

-- SECURITY DEFINER functions callable without signing in. activate_subscription
-- is the most serious: it grants paid access, and any holder of the public
-- anon key could call it for any follower id.
-- get_heart_batch was written here as `get_heart_batch()`. It takes
-- `p_limit integer default 40`, so that signature matches nothing and the
-- statement raised — taking heart_commit and write_child_name, the two lines
-- after it, down with it. Both were still executable by anon in production on
-- 2026-08-07, twelve days later. Corrected to (integer) and guarded, so one bad
-- signature can never again silently cancel the revocations that follow it.
DO $revoke$
DECLARE f text;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public.activate_subscription(uuid, integer, numeric, text, text)',
    'public.return_to_free(uuid)',
    'public.check_daily_message_cap(uuid)',
    'public.get_conversation_for(text)',
    'public.get_free_session_state(text, numeric)',
    'public.get_heart_batch(integer)',
    'public.heart_commit(text, jsonb)',
    'public.write_child_name(text, text)'
  ] LOOP
    IF to_regprocedure(f) IS NOT NULL THEN
      EXECUTE 'REVOKE EXECUTE ON FUNCTION ' || f || ' FROM anon, authenticated';
    END IF;
  END LOOP;
END $revoke$;

-- n8n authenticates as service_role; these grants keep it working.
GRANT SELECT   ON ALL TABLES    IN SCHEMA public TO service_role;
GRANT EXECUTE  ON ALL FUNCTIONS IN SCHEMA public TO service_role;
