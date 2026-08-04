-- ============================================================================
-- Week-0 data validity · chat history integrity guards
-- ============================================================================
-- TWO DEFECTS (blueprint 8.2):
--   "Every generated message must have a hard length ceiling."
--     One stored AI message is 169,230 chars. Measured AI p99 = 1,260,
--     p99.9 = 1,832; exactly one row exceeds 12,000. A 12,000 ceiling is
--     ~6.5x p99.9 -- pathology only, never a legitimate reply. Unbounded
--     generations cost tokens on every later turn, since history is replayed.
--
--   "Agent context must never be persisted into stored user messages."
--     25 human rows begin with "=[اليوم N من 30 ... === ذاكرة الرحلة ===",
--     the composed prompt stored as though the parent typed it.
--
-- WHY ONE IS ENFORCED AND THE OTHER ONLY OBSERVED
--   The ceiling is unambiguous and safe to apply mechanically. Stripping the
--   scaffolding is not: it means regex surgery on Arabic free text, where a
--   wrong boundary silently corrupts what a parent actually wrote. The
--   correct fix is in the workflow that composes the message. Until then this
--   makes the contamination visible and countable.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.guard_chat_history_message()
RETURNS trigger LANGUAGE plpgsql
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_content text; v_len int; v_limit constant int := 12000;
BEGIN
  v_content := NEW.message->>'content';
  IF v_content IS NULL THEN RETURN NEW; END IF;
  v_len := length(v_content);
  IF v_len > v_limit THEN
    NEW.message := jsonb_set(NEW.message, '{content}',
      to_jsonb(left(v_content, v_limit)
        || E'\n\n[…truncated by guard_chat_history_message: ' || v_len || ' chars]'));
  END IF;
  RETURN NEW;
END $$;

COMMENT ON FUNCTION public.guard_chat_history_message() IS
  'Caps stored chat content at 12,000 chars. Measured AI p99.9 is 1,832, so '
  'this fires only on pathological generations -- one historical row reached '
  '169,230 chars, replayed into context on every later turn.';

DROP TRIGGER IF EXISTS trg_guard_chat_history_message ON public.n8n_chat_histories;
CREATE TRIGGER trg_guard_chat_history_message
  BEFORE INSERT OR UPDATE ON public.n8n_chat_histories
  FOR EACH ROW EXECUTE FUNCTION public.guard_chat_history_message();

CREATE OR REPLACE VIEW public.v_chat_history_contamination
WITH (security_invoker = true) AS
SELECT h.id, h.session_id, h.message->>'type' AS role,
       length(h.message->>'content') AS content_length,
       CASE
         WHEN (h.message->>'content') LIKE '=[اليوم%'               THEN 'scaffolding_prefix'
         WHEN (h.message->>'content') LIKE '%=== ذاكرة الرحلة ===%' THEN 'memory_block_inlined'
         WHEN length(h.message->>'content') > 12000                 THEN 'over_length'
       END AS defect,
       left(h.message->>'content', 100) AS head, h.created_at
FROM public.n8n_chat_histories h
WHERE (h.message->>'content') LIKE '=[اليوم%'
   OR (h.message->>'content') LIKE '%=== ذاكرة الرحلة ===%'
   OR length(h.message->>'content') > 12000;

COMMENT ON VIEW public.v_chat_history_contamination IS
  'Chat rows where agent scaffolding was persisted as user text, or content '
  'exceeded the ceiling. Baseline 2026-07-29: 25 scaffolded human rows, 1 '
  'over-length AI row. Growth in scaffolding_prefix means the workflow still '
  'writes the composed prompt into memory as though the parent typed it.';

GRANT SELECT ON public.v_chat_history_contamination TO service_role;
