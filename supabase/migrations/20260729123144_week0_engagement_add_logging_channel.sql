-- ============================================================================
-- Week-0 correctness · add the logging channel to the engagement truth layer
-- ============================================================================
-- WHY
--   Parents engage through two distinct channels and they are not
--   interchangeable:
--     conversation -> n8n_chat_histories  (she writes)
--     logging      -> daily_logs          (she taps)
--
--   Validating the first migration exposed the risk: 22 parents carry a
--   non-zero legacy counter with zero conversation, and the two signals
--   disagree on 64 rows in both directions. The approved Mirror gate is
--   "3 logged nights" (architecture A3: the nightly log is the measurement
--   spine), which lives in daily_logs -- NOT in message volume. Exposing only
--   the conversation channel here would invite the Mirror Engine to be wired
--   to the wrong signal.
--
--   Both channels therefore live in one view, named explicitly, so the gate
--   cannot be mis-wired by accident.
-- ============================================================================

CREATE OR REPLACE VIEW public.v_parent_engagement
WITH (security_invoker = true) AS
WITH chat AS (
  SELECT
    public.normalise_session_key(h.session_id)               AS key,
    COUNT(*) FILTER (WHERE h.message->>'type' = 'human')     AS human_messages,
    COUNT(*) FILTER (WHERE h.message->>'type' = 'ai')        AS ai_messages,
    COUNT(DISTINCT h.session_id)                             AS session_count,
    MIN(h.created_at)                                        AS first_message_at,
    MAX(h.created_at)                                        AS last_message_at
  FROM public.n8n_chat_histories h
  GROUP BY 1
),
logs AS (
  SELECT
    d.follower_id,
    COUNT(DISTINCT d.log_date)                                       AS nights_logged,
    COUNT(DISTINCT d.log_date) FILTER (WHERE d.night_result IS NOT NULL)
                                                                     AS nights_with_result,
    COUNT(*) FILTER (WHERE d.night_result = 'calm')                  AS calm_nights,
    COUNT(*) FILTER (WHERE d.night_result = 'hard')                  AS hard_nights,
    COUNT(*) FILTER (WHERE d.step_status = 'done')                   AS steps_done,
    MAX(d.log_date)                                                  AS last_log_date
  FROM public.daily_logs d
  GROUP BY 1
)
SELECT
  f.id                                        AS parent_id,
  f.platform_user_id,
  -- conversation channel (she writes)
  COALESCE(c.human_messages, 0)               AS human_messages,
  COALESCE(c.ai_messages, 0)                  AS ai_messages,
  COALESCE(c.session_count, 0)                AS session_count,
  c.first_message_at,
  c.last_message_at,
  -- logging channel (she taps) -- this is what gates the Mirror
  COALESCE(l.nights_logged, 0)                AS nights_logged,
  COALESCE(l.nights_with_result, 0)           AS nights_with_result,
  COALESCE(l.calm_nights, 0)                  AS calm_nights,
  COALESCE(l.hard_nights, 0)                  AS hard_nights,
  COALESCE(l.steps_done, 0)                   AS steps_done,
  l.last_log_date,
  -- approved Mirror gate: 3 logged nights carrying a result
  (COALESCE(l.nights_with_result, 0) >= 3)    AS mirror_eligible
FROM public.followers f
LEFT JOIN chat c ON c.key = f.platform_user_id
LEFT JOIN logs l ON l.follower_id = f.id;

COMMENT ON VIEW public.v_parent_engagement IS
  'Derived engagement per parent. Source of truth for every engagement gate. '
  'Two channels, deliberately separate: conversation (human_messages, from '
  'n8n_chat_histories via normalise_session_key) and logging (nights_logged, '
  'from daily_logs). The approved Mirror gate is nights_with_result >= 3, '
  'exposed as mirror_eligible -- it is NOT a message count. '
  'Does not count inbound messages that never reached the agent (e.g. legacy '
  'waitlist-blocked sends); those were never conversation. '
  'Never write a counter to followers -- read this.';

GRANT SELECT ON public.v_parent_engagement TO service_role;
