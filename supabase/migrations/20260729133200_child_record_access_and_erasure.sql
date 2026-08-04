-- ============================================================================
-- Child Record · access, rate limit, and right to erasure
-- ============================================================================
-- NOTE: get_child_record returns was_delivered (not "delivered"). The first
-- implementation used "delivered", which collides with the column of the same
-- name on child_record_requests and failed at runtime with 42702 (ambiguous
-- reference). Caught by test T5.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_child_record(
  p_child_id uuid, p_initiated_by text DEFAULT 'parent')
RETURNS TABLE (was_delivered boolean, reason text, record jsonb)
LANGUAGE plpgsql VOLATILE SECURITY INVOKER
SET search_path = pg_catalog, public
AS $$
DECLARE v_parent uuid; v_recent int; v_record jsonb;
BEGIN
  SELECT c.follower_id INTO v_parent FROM public.children c WHERE c.id = p_child_id;
  IF v_parent IS NULL THEN
    RETURN QUERY SELECT false, 'unknown_child', NULL::jsonb; RETURN;
  END IF;

  -- ADAM has no way to initiate this. There is deliberately no 'agent' value.
  IF p_initiated_by NOT IN ('parent','operator') THEN
    RETURN QUERY SELECT false, 'record_is_never_unprompted', NULL::jsonb; RETURN;
  END IF;

  SELECT count(*) INTO v_recent FROM public.child_record_requests crr
   WHERE crr.parent_id = v_parent AND crr.delivered
     AND crr.requested_at > now() - interval '7 days';

  IF v_recent > 0 AND p_initiated_by = 'parent' THEN
    INSERT INTO public.child_record_requests
      (parent_id, child_id, initiated_by, delivered, suppressed_reason)
    VALUES (v_parent, p_child_id, p_initiated_by, false, 'rate_limited_7d');
    RETURN QUERY SELECT false, 'rate_limited_7d', NULL::jsonb; RETURN;
  END IF;

  SELECT vcr.record INTO v_record FROM public.v_child_record vcr WHERE vcr.child_id = p_child_id;
  INSERT INTO public.child_record_requests (parent_id, child_id, initiated_by, delivered)
  VALUES (v_parent, p_child_id, p_initiated_by, true);
  RETURN QUERY SELECT true, 'ok', v_record;
END $$;

COMMENT ON FUNCTION public.get_child_record(uuid, text) IS
  'Retrieval for the child record. Enforces one record per parent per week and '
  'audits every request. initiated_by admits only parent or operator -- there '
  'is deliberately no value ADAM could pass.';

-- Right to erasure. architecture-review A11: four design documents specified
-- no way for a parent to delete her data, for a product holding intimate
-- disclosures about identifiable children. Two steps by design, so an
-- accidental single call cannot destroy a parent's history.

CREATE OR REPLACE FUNCTION public.request_erasure(p_parent_id uuid)
RETURNS uuid LANGUAGE plpgsql VOLATILE SECURITY INVOKER
SET search_path = pg_catalog, public
AS $$
DECLARE v_pid text; v_refund boolean; v_id uuid;
BEGIN
  SELECT platform_user_id INTO v_pid FROM public.followers WHERE id = p_parent_id;
  IF v_pid IS NULL THEN RAISE EXCEPTION 'unknown parent %', p_parent_id; END IF;
  SELECT EXISTS (SELECT 1 FROM public.stages WHERE parent_id = p_parent_id
                  AND status IN ('active','extended','paused') AND price_amount IS NOT NULL)
    INTO v_refund;
  INSERT INTO public.erasure_requests (parent_id, platform_user_id, refund_due)
  VALUES (p_parent_id, v_pid, v_refund) RETURNING id INTO v_id;
  RETURN v_id;
END $$;

CREATE OR REPLACE FUNCTION public.execute_erasure(p_request_id uuid)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY INVOKER
SET search_path = pg_catalog, public
AS $$
DECLARE v_parent uuid; v_pid text; v_status text;
        v_chat int; v_sess int; v_surv int; v_pay int;
BEGIN
  SELECT parent_id, platform_user_id, status INTO v_parent, v_pid, v_status
    FROM public.erasure_requests WHERE id = p_request_id;
  IF v_parent IS NULL THEN RAISE EXCEPTION 'unknown erasure request %', p_request_id; END IF;
  IF v_status <> 'requested' THEN RAISE EXCEPTION 'erasure % already %', p_request_id, v_status; END IF;

  -- Conversations are keyed by session_id, not a foreign key, so they must be
  -- removed explicitly and via the normalised key or drifted rows survive.
  DELETE FROM public.n8n_chat_histories
   WHERE public.normalise_session_key(session_id) = v_pid;
  GET DIAGNOSTICS v_chat = ROW_COUNT;
  DELETE FROM public.session_tracker WHERE platform_user_id = v_pid;
  GET DIAGNOSTICS v_sess = ROW_COUNT;
  DELETE FROM public.survey_responses WHERE platform_user_id = v_pid;
  GET DIAGNOSTICS v_surv = ROW_COUNT;

  -- Payments retained but de-identified: the financial record must survive,
  -- the link to a person must not.
  UPDATE public.payments SET follower_id = NULL, notes = '[erased]' WHERE follower_id = v_parent;
  GET DIAGNOSTICS v_pay = ROW_COUNT;

  DELETE FROM public.followers WHERE id = v_parent;

  UPDATE public.erasure_requests SET status='completed', completed_at=now(),
         notes = format('chat=%s sessions=%s surveys=%s payments_anonymised=%s',
                        v_chat, v_sess, v_surv, v_pay)
   WHERE id = p_request_id;

  RETURN jsonb_build_object('erased', true, 'chat_rows', v_chat, 'sessions', v_sess,
                            'surveys', v_surv, 'payments_anonymised', v_pay);
END $$;

COMMENT ON FUNCTION public.execute_erasure(uuid) IS
  'Executes a recorded erasure request. Removes conversations via the '
  'normalised session key (drifted keys would otherwise survive), session and '
  'survey rows, then the parent -- cascading children, logs, stages, patterns '
  'and flags. Payments are de-identified rather than deleted. The '
  'erasure_requests row has no FK so the audit trail outlives the erasure.';

REVOKE EXECUTE ON FUNCTION public.get_child_record(uuid, text) FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.request_erasure(uuid)        FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.execute_erasure(uuid)        FROM anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_child_record(uuid, text)  TO service_role;
GRANT EXECUTE ON FUNCTION public.request_erasure(uuid)         TO service_role;
GRANT EXECUTE ON FUNCTION public.execute_erasure(uuid)         TO service_role;
