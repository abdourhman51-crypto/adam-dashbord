-- ============================================================================
-- Child Record · the derived record
-- ============================================================================
-- Never stored. Computed at request time so redaction always applies and a
-- stale copy can never leak (architecture-review A10).
--
-- LOG ATTRIBUTION
--   daily_logs.child_id is NULL on all 21 live rows, so a naive per-child join
--   returns an empty record for every child. The rule:
--     log.child_id = this child                     -> attribute
--     log.child_id IS NULL and parent has ONE child -> attribute (unambiguous)
--     log.child_id IS NULL and parent has SEVERAL   -> exclude, and count it
--   The excluded count is surfaced as unattributed_logs rather than hidden:
--   silently dropping a parent's data is worse than showing a gap.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.hard_moment_label(p_key text)
RETURNS text LANGUAGE sql IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, public
AS $$
  SELECT CASE lower(COALESCE(p_key,''))
    WHEN 'meal' THEN 'عند الأكل' WHEN 'sleep' THEN 'عند النوم'
    WHEN 'out' THEN 'عند الخروج' WHEN 'screen' THEN 'في وقت الشاشة'
    WHEN 'study' THEN 'عند الدراسة' WHEN 'other' THEN 'في موقف آخر'
    ELSE NULL END
$$;

CREATE OR REPLACE VIEW public.v_child_record
WITH (security_invoker = true) AS
WITH ctx AS (
  SELECT c.id AS child_id, c.follower_id AS parent_id,
         NULLIF(btrim(c.name), '') AS raw_name, c.gender, c.age_note, c.is_primary,
         (SELECT count(*) FROM public.children c2 WHERE c2.follower_id = c.follower_id) AS sibling_count
  FROM public.children c
),
logs AS (
  SELECT x.child_id, d.log_date, d.night_result, d.hard_moment, d.step_given, d.step_status
  FROM ctx x JOIN public.daily_logs d ON d.follower_id = x.parent_id
  WHERE d.child_id = x.child_id OR (d.child_id IS NULL AND x.sibling_count = 1)
),
unattributed AS (
  SELECT x.child_id, count(d.id) AS n FROM ctx x
  LEFT JOIN public.daily_logs d ON d.follower_id = x.parent_id
        AND d.child_id IS NULL AND x.sibling_count > 1
  GROUP BY x.child_id
),
steps AS (
  SELECT child_id, step_given,
         count(*) FILTER (WHERE step_status = 'done') AS worked, count(*) AS offered
  FROM logs WHERE step_given IS NOT NULL GROUP BY 1,2
),
moments AS (
  SELECT child_id, hard_moment, count(*) AS n FROM logs WHERE hard_moment IS NOT NULL GROUP BY 1,2
),
rhythm AS (
  SELECT child_id, count(DISTINCT log_date) AS nights_logged,
         count(*) FILTER (WHERE night_result='calm')   AS calm,
         count(*) FILTER (WHERE night_result='hard')   AS hard,
         count(*) FILTER (WHERE night_result='normal') AS normal,
         min(log_date) AS first_log, max(log_date) AS last_log
  FROM logs GROUP BY 1
),
done_stages AS (
  SELECT s.child_id, s.problem_key, s.objective_text, s.status, s.completed_at,
         p.logged_days, p.objective_met
  FROM public.stages s LEFT JOIN public.v_stage_progress p ON p.stage_id = s.id
  WHERE s.status IN ('completed','failed','refunded')
),
safe_patterns AS (
  SELECT child_id, pattern_label, status, evidence_count
  FROM public.child_patterns WHERE safe_for_record AND child_id IS NOT NULL
)
SELECT x.child_id, x.parent_id,
  jsonb_build_object(
    'identity', jsonb_build_object(
      'name', CASE WHEN x.raw_name IN ('الطفل','الطفلة') THEN NULL ELSE x.raw_name END,
      'name_is_placeholder', (x.raw_name IS NULL OR x.raw_name IN ('الطفل','الطفلة')),
      'gender', x.gender, 'age_note', x.age_note, 'is_primary', x.is_primary),
    'what_calms', COALESCE((SELECT jsonb_agg(jsonb_build_object(
        'step', s.step_given, 'worked', s.worked, 'offered', s.offered)
        ORDER BY s.worked DESC, s.offered DESC)
      FROM steps s WHERE s.child_id = x.child_id AND s.worked > 0), '[]'::jsonb),
    'what_triggers', COALESCE((SELECT jsonb_agg(jsonb_build_object(
        'key', m.hard_moment, 'label', public.hard_moment_label(m.hard_moment), 'times', m.n)
        ORDER BY m.n DESC) FROM moments m WHERE m.child_id = x.child_id), '[]'::jsonb),
    'rhythm', COALESCE((SELECT to_jsonb(r) - 'child_id' FROM rhythm r WHERE r.child_id = x.child_id),
      jsonb_build_object('nights_logged',0,'calm',0,'hard',0,'normal',0)),
    'stages', COALESCE((SELECT jsonb_agg(jsonb_build_object(
        'problem', d.problem_key, 'objective', d.objective_text, 'status', d.status,
        'objective_met', d.objective_met, 'logged_days', d.logged_days,
        'completed_at', d.completed_at) ORDER BY d.completed_at DESC NULLS LAST)
      FROM done_stages d WHERE d.child_id = x.child_id), '[]'::jsonb),
    'patterns', COALESCE((SELECT jsonb_agg(jsonb_build_object(
        'label', sp.pattern_label, 'status', sp.status, 'evidence', sp.evidence_count))
      FROM safe_patterns sp WHERE sp.child_id = x.child_id), '[]'::jsonb),
    'meta', jsonb_build_object(
      'unattributed_logs', COALESCE((SELECT u.n FROM unattributed u WHERE u.child_id = x.child_id), 0),
      'sibling_count', x.sibling_count, 'generated_at', now())
  ) AS record
FROM ctx x;

COMMENT ON VIEW public.v_child_record IS
  'The child record, derived at request time and never stored, so redaction '
  'always applies and no stale copy can leak. Sources restricted by PROVENANCE: '
  'what ADAM authored (steps, stage objectives) and what was measured (nightly '
  'enums, counts). LLM-extracted free text is excluded structurally -- '
  'memory_events never feeds this view, and child_patterns requires '
  'safe_for_record.';

GRANT SELECT ON public.v_child_record TO service_role;
GRANT EXECUTE ON FUNCTION public.hard_moment_label(text) TO service_role;
