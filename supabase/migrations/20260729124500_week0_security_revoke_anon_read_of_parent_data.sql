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
DROP POLICY IF EXISTS dashboard_read                      ON public.messages;
DROP POLICY IF EXISTS anon_read_children                  ON public.children;
DROP POLICY IF EXISTS anon_read_child_patterns            ON public.child_patterns;
DROP POLICY IF EXISTS anon_read_daily_logs                ON public.daily_logs;
DROP POLICY IF EXISTS anon_read_memory_events             ON public.memory_events;
DROP POLICY IF EXISTS anon_read_memory_snapshots          ON public.memory_snapshots;
DROP POLICY IF EXISTS anon_select_plan_sessions           ON public.plan_sessions;
DROP POLICY IF EXISTS anon_read_session_tracker           ON public.session_tracker;
DROP POLICY IF EXISTS anon_read_weekly_plans              ON public.weekly_plans;
DROP POLICY IF EXISTS anon_read_follower_insights         ON public.follower_insights;
DROP POLICY IF EXISTS anon_read_collective_intelligence   ON public.collective_intelligence;

REVOKE SELECT ON public.n8n_chat_histories      FROM anon, authenticated;
REVOKE SELECT ON public.followers               FROM anon, authenticated;
REVOKE SELECT ON public.payments                FROM anon, authenticated;
REVOKE SELECT ON public.messages                FROM anon, authenticated;
REVOKE SELECT ON public.children                FROM anon, authenticated;
REVOKE SELECT ON public.child_patterns          FROM anon, authenticated;
REVOKE SELECT ON public.daily_logs              FROM anon, authenticated;
REVOKE SELECT ON public.memory_events           FROM anon, authenticated;
REVOKE SELECT ON public.memory_snapshots        FROM anon, authenticated;
REVOKE SELECT ON public.plan_sessions           FROM anon, authenticated;
REVOKE SELECT ON public.session_tracker         FROM anon, authenticated;
REVOKE SELECT ON public.weekly_plans            FROM anon, authenticated;
REVOKE SELECT ON public.follower_insights       FROM anon, authenticated;
REVOKE SELECT ON public.collective_intelligence FROM anon, authenticated;
REVOKE SELECT ON public.survey_responses        FROM anon, authenticated;

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
REVOKE EXECUTE ON FUNCTION public.activate_subscription(uuid, integer, numeric, text, text) FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.return_to_free(uuid)                  FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.check_daily_message_cap(uuid)         FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.get_conversation_for(text)            FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.get_free_session_state(text, numeric) FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.get_heart_batch()                     FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.heart_commit(text, jsonb)             FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.write_child_name(text, text)          FROM anon, authenticated;

-- n8n authenticates as service_role; these grants keep it working.
GRANT SELECT   ON ALL TABLES    IN SCHEMA public TO service_role;
GRANT EXECUTE  ON ALL FUNCTIONS IN SCHEMA public TO service_role;
