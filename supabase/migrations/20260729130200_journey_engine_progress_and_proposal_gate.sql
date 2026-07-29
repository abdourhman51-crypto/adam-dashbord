-- ============================================================================
-- Journey Engine · derived progress and the proposal gate
-- ============================================================================
-- Progress is derived, never stored (review A2/A3). The clock counts days on
-- which the parent logged, so crisis pauses, travel, illness and Ramadan are
-- handled without any pause feature.
-- ============================================================================

CREATE OR REPLACE VIEW public.v_stage_progress
WITH (security_invoker = true) AS
WITH logged AS (
  SELECT s.id AS stage_id, COUNT(DISTINCT d.log_date) AS logged_days
  FROM public.stages s
  LEFT JOIN public.daily_logs d
         ON d.follower_id = s.parent_id
        AND s.started_at IS NOT NULL
        AND d.log_date >= s.started_at::date
        AND d.night_result IS NOT NULL
  GROUP BY s.id
),
recent AS (
  SELECT s.id AS stage_id,
         COUNT(*) FILTER (WHERE w.night_result = 'calm') AS calm_in_window,
         COUNT(*) FILTER (WHERE w.step_status  = 'done') AS steps_in_window,
         COUNT(*)                                        AS window_size
  FROM public.stages s
  CROSS JOIN LATERAL (
    SELECT d.night_result, d.step_status FROM public.daily_logs d
    WHERE d.follower_id = s.parent_id AND s.started_at IS NOT NULL
      AND d.log_date >= s.started_at::date AND d.night_result IS NOT NULL
    ORDER BY d.log_date DESC LIMIT s.objective_window
  ) w
  GROUP BY s.id
)
SELECT
  s.id AS stage_id, s.parent_id, s.child_id, s.problem_key, s.status,
  s.objective_text, s.objective_metric, s.objective_target, s.objective_window,
  s.planned_logged_days, s.extension_days,
  (s.planned_logged_days + s.extension_days) AS allowed_days,
  COALESCE(l.logged_days, 0)                 AS logged_days,
  GREATEST(0, (s.planned_logged_days + s.extension_days) - COALESCE(l.logged_days, 0)) AS days_remaining,
  CASE
    WHEN COALESCE(l.logged_days, 0) < 3 THEN 'observe'
    WHEN COALESCE(l.logged_days, 0) >= (s.planned_logged_days + s.extension_days)
         - GREATEST(3, (s.planned_logged_days + s.extension_days) / 3) THEN 'hold'
    ELSE 'build'
  END AS phase,
  CASE s.objective_metric
    WHEN 'calm_nights_in_window' THEN COALESCE(r.calm_in_window, 0)
    WHEN 'steps_done_in_window'  THEN COALESCE(r.steps_in_window, 0)
  END AS objective_current,
  COALESCE(r.window_size, 0) AS window_filled,
  -- Met only when the window is genuinely full: a 5-of-7 target cannot be
  -- declared met on 3 nights of data.
  (COALESCE(r.window_size, 0) >= s.objective_window
   AND CASE s.objective_metric
         WHEN 'calm_nights_in_window' THEN COALESCE(r.calm_in_window, 0)
         WHEN 'steps_done_in_window'  THEN COALESCE(r.steps_in_window, 0)
       END >= s.objective_target) AS objective_met,
  (COALESCE(l.logged_days, 0) >= (s.planned_logged_days + s.extension_days)) AS clock_exhausted,
  s.started_at, s.completed_at
FROM public.stages s
LEFT JOIN logged l ON l.stage_id = s.id
LEFT JOIN recent r ON r.stage_id = s.id;

COMMENT ON VIEW public.v_stage_progress IS
  'Derived stage state. logged_days is the clock and counts days the parent '
  'logged, never calendar days. phase is computed, never assigned. '
  'objective_met requires a full measurement window: a 5-of-7 target cannot '
  'be declared met on three nights of data.';

-- Enforces review A7 (cadence), A6 (never sell into an improving trend) and
-- A9 (no proposal for 30 days after a failure). Guidance is free and
-- proactive; these caps are what stop it becoming the pushing that produced
-- 8 offers and 0 clicks.
CREATE OR REPLACE FUNCTION public.can_propose_stage(p_parent_id uuid, p_problem_key text)
RETURNS TABLE (allowed boolean, reason text)
LANGUAGE plpgsql STABLE SECURITY INVOKER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_live int; v_recent_prop int; v_lifetime int; v_crisis int;
  v_failed int; v_since_report int; v_calm_recent numeric; v_calm_prior numeric;
BEGIN
  SELECT count(*) INTO v_live FROM public.stages
   WHERE parent_id = p_parent_id AND status IN ('active','extended','paused');
  IF v_live > 0 THEN RETURN QUERY SELECT false, 'stage_already_live'; RETURN; END IF;

  SELECT count(*) INTO v_crisis FROM public.crisis_flags
   WHERE parent_id = p_parent_id AND detected_at > now() - interval '7 days';
  IF v_crisis > 0 THEN RETURN QUERY SELECT false, 'crisis_window'; RETURN; END IF;

  SELECT count(*) INTO v_failed FROM public.stages
   WHERE parent_id = p_parent_id AND status IN ('failed','refunded')
     AND COALESCE(completed_at, refunded_at) > now() - interval '30 days';
  IF v_failed > 0 THEN RETURN QUERY SELECT false, 'recent_failure'; RETURN; END IF;

  SELECT count(*) INTO v_recent_prop FROM public.stage_proposals
   WHERE parent_id = p_parent_id AND proposed_at > now() - interval '30 days';
  IF v_recent_prop > 0 THEN RETURN QUERY SELECT false, 'proposed_within_30d'; RETURN; END IF;

  SELECT count(*) INTO v_lifetime FROM public.stage_proposals
   WHERE parent_id = p_parent_id AND problem_key = p_problem_key;
  IF v_lifetime >= 3 THEN RETURN QUERY SELECT false, 'lifetime_cap_for_problem'; RETURN; END IF;

  SELECT count(DISTINCT d.log_date) INTO v_since_report FROM public.daily_logs d
   WHERE d.follower_id = p_parent_id
     AND d.log_date > COALESCE((SELECT max(completed_at)::date FROM public.stages
                                 WHERE parent_id = p_parent_id AND status = 'completed'),
                               '1900-01-01'::date);
  IF EXISTS (SELECT 1 FROM public.stages WHERE parent_id = p_parent_id AND status = 'completed')
     AND v_since_report < 3 THEN
    RETURN QUERY SELECT false, 'too_soon_after_report'; RETURN;
  END IF;

  -- Never sell into an improving trend. Only blocks when there is enough data
  -- to see a trend at all: 8+ logged nights.
  SELECT avg(CASE WHEN night_result='calm' THEN 1 ELSE 0 END) FILTER (WHERE rn <= 4),
         avg(CASE WHEN night_result='calm' THEN 1 ELSE 0 END) FILTER (WHERE rn BETWEEN 5 AND 8)
    INTO v_calm_recent, v_calm_prior
  FROM (SELECT night_result, row_number() OVER (ORDER BY log_date DESC) AS rn
        FROM public.daily_logs WHERE follower_id = p_parent_id AND night_result IS NOT NULL) t
  WHERE rn <= 8;

  IF v_calm_recent IS NOT NULL AND v_calm_prior IS NOT NULL
     AND v_calm_recent > v_calm_prior THEN
    RETURN QUERY SELECT false, 'trend_improving'; RETURN;
  END IF;

  RETURN QUERY SELECT true, 'ok';
END $$;

COMMENT ON FUNCTION public.can_propose_stage(uuid, text) IS
  'Gate for proposing the next stage. Enforces one-stage-at-a-time, the 7-day '
  'crisis suppression, the 30-day post-failure block, the 30-day cadence cap, '
  'the 3-lifetime cap per problem, a 3-logged-day cooldown after a report, and '
  'the refusal to sell into an improving trend. Returns a reason so the caller '
  'can log why guidance was withheld.';

REVOKE EXECUTE ON FUNCTION public.can_propose_stage(uuid, text) FROM anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.can_propose_stage(uuid, text) TO service_role;
GRANT  SELECT ON public.v_stage_progress TO service_role;
