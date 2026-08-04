begin;

-- ============================================================
-- The Mirror carries the intention forward — as a flag, never a quote.
-- (docs/adam-system.md §10 item 4 · 20260803180000_ask_the_intention.sql)
--
-- should_ask_intention() and record_intention() ask the question and
-- store the answer. Nothing has ever read intention_text — it is
-- write-only. The Mirror is where "who you meant to be" belongs: it
-- is the one surface built to show a parent evidence of their own
-- change (mirror_engine_core.sql), and the intention is exactly that
-- kind of evidence, held over time.
--
-- WHY A FLAG, NOT THE TEXT
--
-- intention_text is free text an exhausted parent typed once, never
-- moderated, never passed through copy_violations or any vocabulary
-- gate — because record_intention() only ever WROTE it, it never had
-- to be safe to SEND. Every other proactive message in this product
-- goes through gate_agent_reply or gate_composed_reply before a
-- parent sees it (35099f1, 20260731210000). Passing intention_text
-- into a payload that an LLM then echoes into a sent message would
-- quietly skip that entire discipline for exactly the kind of text
-- most likely to be personal, mis-typed, or unsafe to repeat back
-- verbatim.
--
-- So generate_first_mirror emits has_intention: boolean, nothing
-- more. The sentence the Mirror actually says is FIXED, pre-approved
-- copy — the same discipline as intention_ask itself — and it shows
-- approach without quoting her: "وتقتربون، خطوة بخطوة، ممّن أردتم أن
-- تكونوا له." No claim about WHAT she said, only that the direction
-- exists. This is documented here as the intended line because W4
-- (First Mirror Sender, pj19WNHEqU4xDDjy) is currently archived — the
-- payload is ready; the render step is not live to wire.
--
-- WHY THE FIRST MIRROR, AND WHY IT NEEDS NO REPETITION GUARD
--
-- generate_first_mirror is the only implemented kind (weekly,
-- stage_report, parent are declared in the CHECK constraint and
-- never built). uq_one_first_mirror_per_child already guarantees it
-- fires at most once per child — so a fixed intention line here can
-- never repeat to the same family, without adding any new guard.
-- ============================================================

CREATE OR REPLACE FUNCTION public.generate_first_mirror(p_child_id uuid)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY INVOKER
SET search_path = pg_catalog, public
AS $$
DECLARE d record; v_id uuid; v_payload jsonb; v_bar text; v_has_intention boolean;
BEGIN
  SELECT * INTO d FROM public.v_mirror_first_due WHERE child_id = p_child_id;
  IF NOT FOUND THEN RETURN jsonb_build_object('generated', false, 'reason', 'not_due'); END IF;

  SELECT string_agg(CASE WHEN night_result='calm' THEN '▓' ELSE '░' END, ' ' ORDER BY log_date)
    INTO v_bar
  FROM (SELECT dl.night_result, dl.log_date FROM public.daily_logs dl
         WHERE dl.follower_id=d.parent_id AND dl.night_result IS NOT NULL
         ORDER BY dl.log_date DESC LIMIT 10) t;

  SELECT (f.intention_text IS NOT NULL) INTO v_has_intention
  FROM public.followers f WHERE f.id = d.parent_id;

  v_payload := jsonb_build_object(
    'child_name', d.child_name, 'nights', d.nights, 'calm', d.calm, 'hard', d.hard,
    'bar', COALESCE(v_bar,''), 'top_trigger', d.top_trigger, 'best_step', d.best_step,
    'her_change', jsonb_build_object('calm_nights', d.calm, 'note','secondary_line_only'),
    -- Flag only. Never the text itself -- see header. The render step adds
    -- the fixed line "وتقتربون، خطوة بخطوة، ممّن أردتم أن تكونوا له." when true.
    'has_intention', COALESCE(v_has_intention, false));

  INSERT INTO public.mirrors (parent_id, child_id, kind, payload)
  VALUES (d.parent_id, d.child_id, 'first', v_payload) RETURNING id INTO v_id;

  RETURN jsonb_build_object('generated', true, 'mirror_id', v_id, 'payload', v_payload);
END $$;

commit;
