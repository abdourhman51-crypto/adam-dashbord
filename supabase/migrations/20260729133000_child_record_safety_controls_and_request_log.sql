-- ============================================================================
-- Child Record · safety controls and request log
-- ============================================================================
-- THE GOVERNING RULE, established by inspecting the live data:
--   The record contains what ADAM AUTHORED and what was MEASURED.
--   It never contains what the parent DISCLOSED.
--
-- An allowlist by provenance, not a content filter, because filtering Arabic
-- free text cannot be done safely. Real rows presently in the database:
--   memory_events.title   = 'حادثة الاعتداء المؤلمة'        (child assault)
--   child_patterns.label  = 'التنقل بين ثلاث عائلات'         (family separation)
-- Both sit squarely inside A10's "may never contain", and neither is
-- distinguishable from a safe label by pattern matching.
-- ============================================================================

ALTER TABLE public.child_patterns
  ADD COLUMN IF NOT EXISTS safe_for_record boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.child_patterns.safe_for_record IS
  'Default-deny gate for A10. A pattern is LLM-extracted from the parent''s own '
  'words and may encode a disclosure (live example: "التنقل بين ثلاث عائلات" '
  'reveals family separation). It appears in the child record only when '
  'something has explicitly affirmed it is behavioural and non-sensitive. '
  'Never default this to true in a migration, and never let an LLM set it.';

CREATE TABLE IF NOT EXISTS public.child_record_requests (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_id         uuid NOT NULL REFERENCES public.followers(id) ON DELETE CASCADE,
  child_id          uuid REFERENCES public.children(id) ON DELETE SET NULL,
  requested_at      timestamptz NOT NULL DEFAULT now(),
  initiated_by      text NOT NULL DEFAULT 'parent' CHECK (initiated_by IN ('parent','operator')),
  delivered         boolean NOT NULL DEFAULT false,
  suppressed_reason text
);
CREATE INDEX IF NOT EXISTS idx_record_requests_parent
  ON public.child_record_requests (parent_id, requested_at DESC);

COMMENT ON TABLE public.child_record_requests IS
  'Audit of every child-record request. initiated_by has no "agent" value by '
  'design: ADAM may never send the record on his own initiative, so there is '
  'no enum member that would let him. Also enforces one record per week.';

ALTER TABLE public.child_record_requests ENABLE ROW LEVEL SECURITY;
CREATE POLICY service_all ON public.child_record_requests
  FOR ALL TO service_role USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE ON public.child_record_requests TO service_role;
