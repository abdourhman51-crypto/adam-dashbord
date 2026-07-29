-- ============================================================================
-- FIX · the no-offer constraint matched structure, not content
-- ============================================================================
-- The constraint scanned payload::text, which includes JSON KEY names. The
-- child record carries a field literally called "offered" (how many times a
-- step was offered), so EVERY legitimate Mirror was rejected as though it
-- contained a sales offer. Caught by test M2.
--
-- Two lessons applied:
--   - Match string VALUES only. Keys describe structure, not what a parent reads.
--   - Anchor Latin tokens on word boundaries, so "offered" cannot match "offer"
--     even if it appears in real content.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.jsonb_text_values(p_json jsonb)
RETURNS text LANGUAGE sql IMMUTABLE PARALLEL SAFE
SET search_path = pg_catalog, public
AS $$
  SELECT COALESCE(string_agg(v #>> '{}', ' '), '')
  FROM jsonb_path_query(p_json, '$.**') AS v
  WHERE jsonb_typeof(v) = 'string'
$$;

COMMENT ON FUNCTION public.jsonb_text_values(jsonb) IS
  'All string values in a jsonb document, excluding key names. Used by the '
  'Mirror no-offer constraint, which previously matched the key "offered" and '
  'rejected every valid Mirror.';

ALTER TABLE public.mirrors DROP CONSTRAINT IF EXISTS chk_mirror_carries_no_offer;
ALTER TABLE public.mirrors ADD CONSTRAINT chk_mirror_carries_no_offer CHECK (
  public.jsonb_text_values(payload) !~* '(\mprice\M|\moffer\M|\msubscribe\M|سعر|جنيه|دينار|درهم|اشترك|اشتراك|ادفع)'
);

COMMENT ON TABLE public.mirrors IS
  'Every Mirror generated, with the payload as sent. The CHECK refuses any '
  'payload whose string VALUES mention price or subscription: the Mirror earns '
  'the ask and never makes it, enforced structurally. One first Mirror per '
  'child, ever.';
