-- ============================================================================
-- Week-0 correctness · Engagement Truth Layer
-- ============================================================================
-- PROBLEM
--   followers.message_count froze at 0 for every signup after ~2026-07-25 while
--   those parents were demonstrably conversing (verified: platform_user_id
--   6300769527 has 15 human messages; stored counter reads 0).
--
-- ROOT CAUSES (both confirmed 2026-07-29)
--   1. trg_update_message_count fires on public.messages, which holds 0 rows.
--      Conversation history lives in n8n_chat_histories; the trigger was never
--      repointed when that move happened.
--   2. increment_follower_message(uuid) is invoked from an n8n workflow node.
--      That call was dropped during the 2026-07-24..26 onboarding rewrite.
--
--   Separately, 40 of 47 apparently "orphaned" chat sessions were not lost
--   users at all -- they were session_id format drift on 2026-07-10..11:
--   a leading "=" (an unevaluated n8n expression that leaked into the key)
--   and a trailing _s<N> session-number suffix. Only 7 sessions carrying
--   7 human messages in total are genuinely unattributable.
--
-- APPROVED DESIGN
--   architecture-review.md A3 and product-blueprint-v1.md 8.2:
--   "Engagement counters must be derived, never incremented by a workflow."
--
-- SAFETY
--   Additive and non-destructive. No row is written or deleted.
--   Deliberately does NOT drop increment_follower_message() or
--   trg_update_message_count -- a live workflow may still call them, and
--   removing them here would break production mid-flight.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.normalise_session_key(p_key text)
RETURNS text
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
AS $$
  SELECT regexp_replace(
           regexp_replace(COALESCE(p_key, ''), '^=+', ''),
           '_s[0-9]+$', ''
         )
$$;

COMMENT ON FUNCTION public.normalise_session_key(text) IS
  'Canonical parent key from an n8n chat session_id. Strips a leading "=" '
  '(unevaluated n8n expression leaked into the key) and a trailing _s<N> '
  'session-number suffix. Recovered 40 of 47 apparently-orphaned sessions '
  'from 2026-07-10..11, which were format drift rather than lost users.';

CREATE INDEX IF NOT EXISTS idx_chat_hist_norm_session
  ON public.n8n_chat_histories (public.normalise_session_key(session_id));

CREATE OR REPLACE VIEW public.v_parent_engagement
WITH (security_invoker = true) AS
SELECT
  f.id                                                    AS parent_id,
  f.platform_user_id,
  COUNT(h.id) FILTER (WHERE h.message->>'type' = 'human') AS human_messages,
  COUNT(h.id) FILTER (WHERE h.message->>'type' = 'ai')    AS ai_messages,
  COUNT(DISTINCT h.session_id)                            AS session_count,
  MIN(h.created_at)                                       AS first_message_at,
  MAX(h.created_at)                                       AS last_message_at
FROM public.followers f
LEFT JOIN public.n8n_chat_histories h
       ON public.normalise_session_key(h.session_id) = f.platform_user_id
GROUP BY f.id, f.platform_user_id;

CREATE OR REPLACE VIEW public.v_orphaned_sessions
WITH (security_invoker = true) AS
SELECT
  h.session_id,
  public.normalise_session_key(h.session_id)              AS normalised_key,
  COUNT(*) FILTER (WHERE h.message->>'type' = 'human')    AS human_messages,
  MIN(h.created_at)                                       AS first_message_at,
  MAX(h.created_at)                                       AS last_message_at
FROM public.n8n_chat_histories h
WHERE NOT EXISTS (
        SELECT 1 FROM public.followers f
        WHERE f.platform_user_id = public.normalise_session_key(h.session_id))
GROUP BY h.session_id;

COMMENT ON VIEW public.v_orphaned_sessions IS
  'Chat sessions that cannot be attributed to any parent, after key '
  'normalisation. Baseline at 2026-07-29 is 7 sessions / 7 human messages, '
  'all legacy. Growth here means a live conversation is being lost.';

COMMENT ON COLUMN public.followers.message_count IS
  'DEPRECATED 2026-07-29. Frozen since ~2026-07-25 and not reliable. '
  'Read v_parent_engagement.human_messages instead.';

GRANT EXECUTE ON FUNCTION public.normalise_session_key(text) TO service_role;
GRANT SELECT  ON public.v_parent_engagement TO service_role;
GRANT SELECT  ON public.v_orphaned_sessions TO service_role;
