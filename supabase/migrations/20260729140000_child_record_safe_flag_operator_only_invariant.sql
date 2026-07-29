-- ============================================================================
-- Child Record · safe_for_record is an operator-only invariant
-- ============================================================================
-- REQUIREMENT
--   safe_for_record must never be writable by an LLM, an n8n workflow, any
--   automated process, or a bulk SQL operation. It may change only through an
--   explicit operator action carrying who approved it, when, and why.
--
-- WHY STRUCTURAL
--   The flag admits a pattern label into a document the parent reads. Test T3
--   showed the mechanism working on "التنقل بين ثلاث عائلات", which reveals
--   family separation. A single careless UPDATE would publish a disclosure.
--
-- FOUR MECHANISMS (see the two correction migrations that follow; the first
-- attempt at mechanisms 1 and 2 was defeated by tests H4 and the privilege
-- verification, and both were rebuilt):
--   1. COLUMN PRIVILEGE  -- service_role holds UPDATE on every column but this
--   2. GUARD TRIGGER     -- granting requires an audit row in the same txn
--   3. AUDIT CONSTRAINTS -- approver and reason validated by CHECK
--   4. STALENESS REVOKE  -- label/description change withdraws approval
--
-- RESIDUAL RISK, STATED HONESTLY
--   A database superuser can drop a trigger or re-grant a column. This defends
--   against every path the application, its workflows and its models possess.
--   It does not defend against direct superuser action on the instance.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.pattern_record_approvals (
  id                        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pattern_id                uuid NOT NULL,
  child_id                  uuid,
  parent_id                 uuid,
  pattern_label_at_approval text NOT NULL,
  decision                  boolean NOT NULL,
  approved_by               text NOT NULL CHECK (btrim(approved_by) <> ''),
  reason                    text NOT NULL CHECK (length(btrim(reason)) >= 10),
  approved_at               timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_pattern_approvals_pattern
  ON public.pattern_record_approvals (pattern_id, approved_at DESC);

COMMENT ON TABLE public.pattern_record_approvals IS
  'Append-only record of every decision to show or hide a child_patterns label '
  'in the parent-facing child record. reason must be at least 10 characters so '
  'a decision cannot be justified with "ok". pattern_label_at_approval is a '
  'snapshot: approval applies to the text reviewed, not to later rewrites.';

CREATE OR REPLACE FUNCTION public.reject_audit_mutation()
RETURNS trigger LANGUAGE plpgsql SET search_path = pg_catalog, public
AS $$
BEGIN
  RAISE EXCEPTION 'pattern_record_approvals is append-only (attempted %)', TG_OP;
END $$;

DROP TRIGGER IF EXISTS trg_approvals_append_only ON public.pattern_record_approvals;
CREATE TRIGGER trg_approvals_append_only
  BEFORE UPDATE OR DELETE ON public.pattern_record_approvals
  FOR EACH ROW EXECUTE FUNCTION public.reject_audit_mutation();

ALTER TABLE public.pattern_record_approvals ENABLE ROW LEVEL SECURITY;
CREATE POLICY service_read_insert ON public.pattern_record_approvals
  FOR SELECT TO service_role USING (true);
GRANT SELECT ON public.pattern_record_approvals TO service_role;
