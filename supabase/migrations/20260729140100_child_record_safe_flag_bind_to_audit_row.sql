-- ============================================================================
-- CORRECTION · bind safe_for_record to the audit row, not to a token
-- ============================================================================
-- DEFECT FOUND BY TEST H4
--   The first guard accepted a transaction-scoped GUC as proof of approval.
--   Anyone able to execute SQL could set it and flip the flag:
--     PERFORM set_config('adam.pattern_approval', <id>, true);
--     UPDATE child_patterns SET safe_for_record = true WHERE id = <id>;
--   H4 did exactly that: flag set, audit rows = 0. A guessable token is a
--   convention, not an invariant. An invariant was required.
--
-- SECOND DEFECT, found while correcting the first
--   The corrected guard initially required an approval row for ANY change,
--   including revocation -- and blocked its own cleanup statement. That is
--   backwards. Granting visibility is the dangerous direction; withdrawing it
--   is fail-safe. Requiring ceremony to hide a disclosure would make the safe
--   action harder than the unsafe one.
--
-- FINAL DESIGN
--   GRANT (false -> true) requires an approval row for THIS pattern, THIS
--   decision, THIS label text, in the SAME transaction.
--   REVOKE (true -> false) is always permitted and always logged.
-- ============================================================================

ALTER TABLE public.pattern_record_approvals
  ADD COLUMN IF NOT EXISTS txid xid8 NOT NULL DEFAULT pg_current_xact_id();

COMMENT ON COLUMN public.pattern_record_approvals.txid IS
  'Transaction that wrote this approval. The guard requires a matching row '
  'from the current transaction, making the audit trail structurally '
  'inseparable from a grant of visibility.';

ALTER TABLE public.pattern_record_approvals DROP CONSTRAINT IF EXISTS chk_approver_is_human;
ALTER TABLE public.pattern_record_approvals ADD CONSTRAINT chk_approver_is_human CHECK (
  approved_by IN ('system:staleness','system:revocation')
  OR lower(btrim(approved_by)) !~ '^(system|agent|llm|bot|n8n|service|automation|admin|root)'
);

CREATE OR REPLACE FUNCTION public.guard_safe_for_record()
RETURNS trigger LANGUAGE plpgsql SET search_path = pg_catalog, public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.safe_for_record THEN NEW.safe_for_record := false; END IF;
    RETURN NEW;
  END IF;

  IF OLD.safe_for_record
     AND (NEW.pattern_label IS DISTINCT FROM OLD.pattern_label
       OR NEW.description   IS DISTINCT FROM OLD.description) THEN
    NEW.safe_for_record := false;
    INSERT INTO public.pattern_record_approvals
      (pattern_id, child_id, parent_id, pattern_label_at_approval,
       decision, approved_by, reason)
    VALUES (OLD.id, OLD.child_id, OLD.follower_id, OLD.pattern_label, false,
            'system:staleness',
            'Auto-revoked: pattern text changed after approval, so the '
            'reviewed content no longer matches what would be shown.');
    RETURN NEW;
  END IF;

  IF OLD.safe_for_record AND NOT NEW.safe_for_record THEN
    INSERT INTO public.pattern_record_approvals
      (pattern_id, child_id, parent_id, pattern_label_at_approval,
       decision, approved_by, reason)
    VALUES (OLD.id, OLD.child_id, OLD.follower_id, OLD.pattern_label, false,
            'system:revocation',
            'Visibility withdrawn. Revocation is always permitted because '
            'hiding a possible disclosure must never require ceremony.');
    RETURN NEW;
  END IF;

  IF NOT OLD.safe_for_record AND NEW.safe_for_record THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.pattern_record_approvals a
       WHERE a.pattern_id                = OLD.id
         AND a.decision                  = true
         AND a.pattern_label_at_approval = OLD.pattern_label
         AND a.txid                      = pg_current_xact_id()
    ) THEN
      RAISE EXCEPTION
        'safe_for_record requires an approval recorded in this transaction '
        'naming who approved it and why (pattern %). Direct, automated and '
        'bulk updates are refused.', OLD.id
        USING ERRCODE = 'insufficient_privilege';
    END IF;
  END IF;

  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_guard_safe_for_record ON public.child_patterns;
CREATE TRIGGER trg_guard_safe_for_record
  BEFORE INSERT OR UPDATE ON public.child_patterns
  FOR EACH ROW EXECUTE FUNCTION public.guard_safe_for_record();

CREATE OR REPLACE FUNCTION public.set_pattern_record_visibility(
  p_pattern_id uuid, p_visible boolean, p_approved_by text, p_reason text)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE r public.child_patterns%ROWTYPE;
BEGIN
  SELECT * INTO r FROM public.child_patterns WHERE id = p_pattern_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'unknown pattern %', p_pattern_id; END IF;
  IF p_visible THEN
    INSERT INTO public.pattern_record_approvals
      (pattern_id, child_id, parent_id, pattern_label_at_approval,
       decision, approved_by, reason)
    VALUES (r.id, r.child_id, r.follower_id, r.pattern_label, true,
            btrim(COALESCE(p_approved_by,'')), btrim(COALESCE(p_reason,'')));
  END IF;
  UPDATE public.child_patterns SET safe_for_record = p_visible WHERE id = r.id;
  RETURN jsonb_build_object('pattern_id', r.id, 'visible', p_visible,
                            'label', r.pattern_label, 'approved_by', btrim(p_approved_by));
END $$;

COMMENT ON FUNCTION public.set_pattern_record_visibility(uuid, boolean, text, text) IS
  'Ergonomic path for an operator decision. Not a security boundary on its '
  'own: the boundary is the trigger plus the revoked column privilege. '
  'Replaced a GUC-token design that test H4 defeated.';

REVOKE EXECUTE ON FUNCTION public.set_pattern_record_visibility(uuid, boolean, text, text)
  FROM anon, authenticated, service_role, public;
