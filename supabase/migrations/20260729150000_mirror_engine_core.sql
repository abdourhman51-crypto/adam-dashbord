-- ============================================================================
-- Mirror Engine
-- ============================================================================
-- The Mirror is the conversion engine and has fired ZERO times in production:
-- the legacy First Insight workflow is inactive, and separately no parent has
-- ever reached 3 logged nights, so it would have produced nothing even if it
-- had run. The Check-in Engine now produces the logs; this consumes them.
--
-- FOUR KINDS and their tier:
--   first         FREE   at 3 logged nights. The proof that earns the ask.
--   weekly        PAID   direction over time, inside a stage.
--   stage_report  PAID   the objective answered, then her own change.
--   parent        FREE   after 2+ completed stages. The identity payoff.
--
-- The two carrying the emotional weight are free, deliberately. The Mirror
-- earns the ask; it never makes it (blueprint 11.4). No payload may contain a
-- price or offer -- enforced by CHECK, not left to whoever writes the prompt.
--
-- Child outcome first, because that is what she came for. Her own change is a
-- secondary line, planted here and harvested at the stage report.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.mirrors (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_id    uuid NOT NULL REFERENCES public.followers(id) ON DELETE CASCADE,
  child_id     uuid REFERENCES public.children(id) ON DELETE SET NULL,
  stage_id     uuid REFERENCES public.stages(id) ON DELETE SET NULL,
  kind         text NOT NULL CHECK (kind IN ('first','weekly','stage_report','parent')),
  payload      jsonb NOT NULL,
  window_start date, window_end date,
  generated_at timestamptz NOT NULL DEFAULT now(),
  delivered_at timestamptz
);
CREATE INDEX IF NOT EXISTS idx_mirrors_parent ON public.mirrors (parent_id, generated_at DESC);
CREATE UNIQUE INDEX IF NOT EXISTS uq_one_first_mirror_per_child
  ON public.mirrors (child_id) WHERE kind = 'first' AND child_id IS NOT NULL;

CREATE OR REPLACE VIEW public.v_mirror_first_due
WITH (security_invoker = true) AS
SELECT r.parent_id, r.child_id,
       (r.record->'identity'->>'name')             AS child_name,
       (r.record->'rhythm'->>'nights_logged')::int AS nights,
       (r.record->'rhythm'->>'calm')::int          AS calm,
       (r.record->'rhythm'->>'hard')::int          AS hard,
       r.record->'what_triggers'->0                AS top_trigger,
       r.record->'what_calms'->0                   AS best_step
FROM public.v_child_record r
JOIN public.v_parent_engagement e ON e.parent_id = r.parent_id
WHERE e.nights_with_result >= 3
  AND NOT EXISTS (SELECT 1 FROM public.mirrors m WHERE m.kind='first' AND m.child_id=r.child_id)
  AND NOT EXISTS (SELECT 1 FROM public.crisis_flags cf
                   WHERE cf.parent_id=r.parent_id AND cf.detected_at > now() - interval '7 days');

COMMENT ON VIEW public.v_mirror_first_due IS
  'Parents with three nights carrying a result and no first Mirror yet for '
  'that child. Data-gated, never day-gated: the wow moment arrives when there '
  'is something true to show, not on a schedule.';

CREATE OR REPLACE FUNCTION public.generate_first_mirror(p_child_id uuid)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY INVOKER
SET search_path = pg_catalog, public
AS $$
DECLARE d record; v_id uuid; v_payload jsonb; v_bar text;
BEGIN
  SELECT * INTO d FROM public.v_mirror_first_due WHERE child_id = p_child_id;
  IF NOT FOUND THEN RETURN jsonb_build_object('generated', false, 'reason', 'not_due'); END IF;

  SELECT string_agg(CASE WHEN night_result='calm' THEN '▓' ELSE '░' END, ' ' ORDER BY log_date)
    INTO v_bar
  FROM (SELECT dl.night_result, dl.log_date FROM public.daily_logs dl
         WHERE dl.follower_id=d.parent_id AND dl.night_result IS NOT NULL
         ORDER BY dl.log_date DESC LIMIT 10) t;

  v_payload := jsonb_build_object(
    'child_name', d.child_name, 'nights', d.nights, 'calm', d.calm, 'hard', d.hard,
    'bar', COALESCE(v_bar,''), 'top_trigger', d.top_trigger, 'best_step', d.best_step,
    'her_change', jsonb_build_object('calm_nights', d.calm, 'note','secondary_line_only'));

  INSERT INTO public.mirrors (parent_id, child_id, kind, payload)
  VALUES (d.parent_id, d.child_id, 'first', v_payload) RETURNING id INTO v_id;

  RETURN jsonb_build_object('generated', true, 'mirror_id', v_id, 'payload', v_payload);
END $$;

CREATE OR REPLACE FUNCTION public.record_mirror_delivered(p_mirror_id uuid)
RETURNS void LANGUAGE sql VOLATILE SECURITY INVOKER
SET search_path = pg_catalog, public
AS $$ UPDATE public.mirrors SET delivered_at=now() WHERE id=p_mirror_id AND delivered_at IS NULL; $$;

ALTER TABLE public.mirrors ENABLE ROW LEVEL SECURITY;
CREATE POLICY service_all ON public.mirrors FOR ALL TO service_role USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE ON public.mirrors TO service_role;
GRANT SELECT ON public.v_mirror_first_due TO service_role;
REVOKE EXECUTE ON FUNCTION public.generate_first_mirror(uuid)   FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.record_mirror_delivered(uuid) FROM anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.generate_first_mirror(uuid)   TO service_role;
GRANT  EXECUTE ON FUNCTION public.record_mirror_delivered(uuid) TO service_role;
