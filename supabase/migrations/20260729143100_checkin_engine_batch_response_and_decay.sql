-- ============================================================================
-- Nightly Check-in Engine · batch, response, consent decay
-- ============================================================================
-- Called hourly. A parent is selected only in the hour that is her local
-- evening, computed from her IANA zone so DST is handled by Postgres.
--
-- log_date is the parent's LOCAL date, never UTC. At 21:00 in Algiers the UTC
-- date can already have rolled over; filing a Tuesday evening under Wednesday
-- would silently corrupt the stage clock.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_checkin_batch()
RETURNS TABLE (parent_id uuid, platform_user_id text, first_name text,
               parent_gender text, child_id uuid, child_name text,
               local_date date, cadence text, todays_step text, step_log_id uuid)
LANGUAGE sql STABLE SECURITY INVOKER
SET search_path = pg_catalog, public
AS $$
  WITH due AS (
    SELECT f.id, f.platform_user_id, f.first_name, f.parent_gender,
           cs.cadence, cs.last_sent_date,
           (now() AT TIME ZONE ct.iana_tz)::date AS local_date,
           extract(hour FROM (now() AT TIME ZONE ct.iana_tz))::int AS local_hour_now,
           cs.local_hour
    FROM public.checkin_state cs
    JOIN public.followers f         ON f.id = cs.parent_id
    JOIN public.country_timezone ct ON ct.code = upper(btrim(f.country))
    WHERE cs.cadence <> 'stopped'
      AND (cs.paused_until IS NULL OR cs.paused_until < (now() AT TIME ZONE ct.iana_tz)::date)
      -- Crisis suppresses the proactive rhythm entirely (principle P1).
      AND NOT EXISTS (SELECT 1 FROM public.crisis_flags cf
                       WHERE cf.parent_id = cs.parent_id
                         AND cf.detected_at > now() - interval '7 days')
  ), eligible AS (
    SELECT * FROM due
    WHERE local_hour_now = local_hour
      AND (last_sent_date IS NULL OR last_sent_date < local_date)
      AND (cadence = 'nightly'
           OR (cadence = 'weekly' AND (last_sent_date IS NULL OR last_sent_date <= local_date - 7)))
  )
  SELECT e.id, e.platform_user_id, e.first_name, e.parent_gender,
         kid.id, kid.name, e.local_date, e.cadence, lg.step_given, lg.id
  FROM eligible e
  LEFT JOIN LATERAL (
    SELECT c.id, c.name FROM public.children c WHERE c.follower_id = e.id
    ORDER BY c.is_primary DESC, c.created_at ASC LIMIT 1) kid ON true
  LEFT JOIN LATERAL (
    SELECT d.id, d.step_given FROM public.daily_logs d
    WHERE d.follower_id = e.id AND d.log_date = e.local_date AND d.step_given IS NOT NULL
    ORDER BY d.id DESC LIMIT 1) lg ON true;
$$;

COMMENT ON FUNCTION public.get_checkin_batch() IS
  'Parents whose local evening is now. Excludes the 7-day crisis window, '
  'anyone already sent today, and anyone whose country has no timezone.';

CREATE OR REPLACE FUNCTION public.record_checkin_sent(p_parent_id uuid, p_local_date date)
RETURNS void LANGUAGE sql VOLATILE SECURITY INVOKER
SET search_path = pg_catalog, public
AS $$
  UPDATE public.checkin_state SET last_sent_date = p_local_date, last_sent_at = now()
   WHERE parent_id = p_parent_id;
$$;

CREATE OR REPLACE FUNCTION public.record_checkin_response(
  p_parent_id uuid, p_night_result text DEFAULT NULL,
  p_step_status text DEFAULT NULL, p_hard_moment text DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY INVOKER
SET search_path = pg_catalog, public
AS $$
DECLARE v_tz text; v_date date; v_child uuid; v_log uuid;
BEGIN
  SELECT ct.iana_tz INTO v_tz FROM public.followers f
    JOIN public.country_timezone ct ON ct.code = upper(btrim(f.country))
   WHERE f.id = p_parent_id;

  -- If her local day cannot be resolved, fall back to UTC rather than drop the
  -- log. Losing a night she took the trouble to report is the worse failure.
  v_date := (now() AT TIME ZONE COALESCE(v_tz, 'UTC'))::date;

  SELECT c.id INTO v_child FROM public.children c WHERE c.follower_id = p_parent_id
   ORDER BY c.is_primary DESC, c.created_at ASC LIMIT 1;

  INSERT INTO public.daily_logs (follower_id, child_id, log_date, night_result, step_status, hard_moment)
  VALUES (p_parent_id, v_child, v_date, p_night_result, p_step_status, p_hard_moment)
  ON CONFLICT (follower_id, log_date) DO UPDATE
    SET night_result = COALESCE(EXCLUDED.night_result, daily_logs.night_result),
        step_status  = COALESCE(EXCLUDED.step_status,  daily_logs.step_status),
        hard_moment  = COALESCE(EXCLUDED.hard_moment,  daily_logs.hard_moment),
        child_id     = COALESCE(daily_logs.child_id,   EXCLUDED.child_id),
        updated_at   = now()
  RETURNING id INTO v_log;

  UPDATE public.checkin_state
     SET consecutive_ignored = 0, last_responded_at = now(),
         cadence = CASE WHEN cadence = 'stopped' THEN 'nightly' ELSE cadence END
   WHERE parent_id = p_parent_id;

  RETURN jsonb_build_object('log_id', v_log, 'log_date', v_date, 'child_id', v_child);
END $$;

COMMENT ON FUNCTION public.record_checkin_response(uuid, text, text, text) IS
  'Writes the nightly log against her LOCAL date and resolves child_id to the '
  'primary child, else the only child. Idempotent via (follower_id, log_date), '
  'so a double tap updates rather than duplicating.';

CREATE OR REPLACE FUNCTION public.decay_checkin_consent()
RETURNS TABLE (parent_id uuid, action text, new_cadence text)
LANGUAGE plpgsql VOLATILE SECURITY INVOKER
SET search_path = pg_catalog, public
AS $$
BEGIN
  UPDATE public.checkin_state cs SET consecutive_ignored = cs.consecutive_ignored + 1
   WHERE cs.last_sent_date IS NOT NULL AND cs.last_sent_date < current_date
     AND NOT EXISTS (SELECT 1 FROM public.daily_logs d
                      WHERE d.follower_id = cs.parent_id AND d.log_date = cs.last_sent_date)
     AND (cs.last_responded_at IS NULL OR cs.last_responded_at::date < cs.last_sent_date);

  RETURN QUERY
  WITH stepped AS (
    UPDATE public.checkin_state cs SET
      cadence = CASE
        WHEN cs.cadence='nightly' AND cs.consecutive_ignored >= 5 THEN 'weekly'
        WHEN cs.cadence='weekly'  AND cs.consecutive_ignored >= 9 THEN 'stopped'
        ELSE cs.cadence END,
      consecutive_ignored = CASE
        WHEN cs.cadence='nightly' AND cs.consecutive_ignored >= 5 THEN 0
        ELSE cs.consecutive_ignored END,
      cadence_changed_at = CASE
        WHEN (cs.cadence='nightly' AND cs.consecutive_ignored >= 5)
          OR (cs.cadence='weekly'  AND cs.consecutive_ignored >= 9) THEN now()
        ELSE cs.cadence_changed_at END
    WHERE (cs.cadence='nightly' AND cs.consecutive_ignored >= 5)
       OR (cs.cadence='weekly'  AND cs.consecutive_ignored >= 9)
    RETURNING cs.parent_id, cs.cadence)
  SELECT s.parent_id,
         CASE s.cadence WHEN 'weekly' THEN 'quietened_to_weekly'
                        WHEN 'stopped' THEN 'stopped_proactive' END,
         s.cadence FROM stepped s;
END $$;

COMMENT ON FUNCTION public.decay_checkin_consent() IS
  'Review A12. Each step returns a row so the caller sends the single '
  'explanatory message and nothing further.';

REVOKE EXECUTE ON FUNCTION public.get_checkin_batch()                            FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.record_checkin_sent(uuid, date)                FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.record_checkin_response(uuid, text, text, text) FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.decay_checkin_consent()                        FROM anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_checkin_batch()                             TO service_role;
GRANT EXECUTE ON FUNCTION public.record_checkin_sent(uuid, date)                 TO service_role;
GRANT EXECUTE ON FUNCTION public.record_checkin_response(uuid, text, text, text)  TO service_role;
GRANT EXECUTE ON FUNCTION public.decay_checkin_consent()                         TO service_role;
