-- ============================================================================
-- Cleanup: label every remaining object as CURRENT or DEPRECATED
-- ============================================================================
--
-- After the drops and the archive move, what is left in public is a mix: the
-- new product's tables, and legacy tables that survive only because something
-- still touches them. Nothing in the schema said which was which, so the next
-- person to open it would have to re-derive the whole dependency audit.
--
-- These comments are that audit, written down. DEPRECATED means: do not build
-- on this, it is retained for a named reason and will go once that reason does.
-- ============================================================================

begin;

-- ---------------------------------------------------------------------------
-- CURRENT — the new product
-- ---------------------------------------------------------------------------

comment on table public.followers is
  'CURRENT. The parent. Carries a large tail of legacy funnel columns '
  '(funnel_stage, offer_*, ready_for_offer, waitlist, renewal_d0/d5_sent_at, '
  'daily_msg_*, trial_started_at, cohort, is_golden, pain/urgency/intent_score) '
  'that belong to the retired offer funnel. They are not dropped because live '
  'workflows and the dashboard still select * from this table. Do not read them '
  'as product state.';

comment on table public.children is
  'CURRENT. Child identity. Only writer is write_child_name (ADAM - Heart Writer). '
  'Sole sanctioned source of the child name — never light_memory, which is an '
  'unverified LLM inference.';

comment on table public.daily_logs is
  'CURRENT. The measurement spine. The stage clock, the Mirror and the child '
  'record are all derived from it. Written by the nightly check-in response path.';

comment on table public.child_patterns is
  'CURRENT. Detected patterns. safe_for_record is an operator-only invariant: '
  'granting it requires a matching approval row in pattern_record_approvals '
  'written in the same transaction. No LLM, workflow or bulk UPDATE can set it.';

comment on table public.pattern_record_approvals is
  'CURRENT. Append-only audit for safe_for_record decisions. UPDATE and DELETE '
  'are rejected by trigger. Records who approved, when, and why.';

comment on table public.checkin_state is
  'CURRENT. Nightly check-in cadence, consent decay and local hour. Separate '
  'from followers because that table already carries 60+ columns.';

comment on table public.country_timezone is
  'CURRENT. IANA zones for 30 countries. Replaces the legacy hardcoded map '
  '{DZ:1, EG:2, MA:1}, which had Egypt at +2 and so sent every Egyptian parent '
  'the 21:00 check-in at 20:00 since DST returned in 2023.';

comment on table public.mirrors is
  'CURRENT. Weekly Mirror. A CHECK constraint forbids price or offer text in '
  'the payload, so the Mirror is structurally non-commercial.';

comment on table public.stages is        'CURRENT. Journey chapters. Progress is derived, never a stored counter.';
comment on table public.stage_proposals is 'CURRENT. Proposal cadence caps, enforced by can_propose_stage().';
comment on table public.crisis_flags is  'CURRENT. Crisis queue. Escalation destination is still unowned (review D1).';
comment on table public.erasure_requests is 'CURRENT. Right to erasure, two-step.';
comment on table public.child_record_requests is 'CURRENT. Child record access log.';
comment on table public.payments is      'CURRENT. Payment history. De-identified rather than deleted on erasure.';
comment on table public.supported_countries is 'CURRENT. Backs get_pricing(), the only sanctioned price source.';
comment on table public.n8n_chat_histories is
  'CURRENT. Conversation store, written by the langchain Postgres memory node. '
  'A guard trigger caps message length at 12,000 chars; one stored message had '
  'reached 169,230 against a p99.9 of 1,832.';

-- ---------------------------------------------------------------------------
-- DEPRECATED — retained for a named reason
-- ---------------------------------------------------------------------------

comment on table public.weekly_plans is
  'DEPRECATED (empty). Retained for two live references: write_child_name() '
  'backfills child_id here, and the dashboard reads it. Drop only after both '
  'are removed.';

comment on table public.plan_sessions is
  'DEPRECATED. Old monthly-plan model. Retained because get_agent_context() and '
  'writer_commit() read it and the dashboard displays it. Superseded by stages.';

comment on table public.session_tracker is
  'DEPRECATED. Free/paid session gating for the retired model. Last written '
  '2026-07-26. Retained because execute_erasure() must still purge these rows '
  'for a parent exercising erasure.';

comment on table public.survey_responses is
  'DEPRECATED (empty). The founder survey never collected a response. Retained '
  'because the live Machine 1+2 router still writes to it and execute_erasure() '
  'purges it.';

comment on table public.follower_insights is
  'DEPRECATED. Four rows, none newer than 2026-07-01. No function reads it; the '
  'dashboard does. Superseded by child_patterns.';

comment on table public.memory_snapshots is
  'DEPRECATED. Read by get_agent_context() and get_extraction_batch(). Superseded '
  'by the derived child record.';

comment on table public.memory_events is
  'CURRENT but RESTRICTED. Fed to get_agent_context() for conversational memory. '
  'Deliberately excluded from v_child_record: it holds parent disclosures, and '
  'the record contains only what ADAM authored or measured. A live title read '
  'exactly "حادثة الاعتداء المؤلمة" — not distinguishable from a safe label by '
  'pattern matching, which is why the rule is provenance, not content filtering.';

comment on function public.writer_commit(uuid, integer, jsonb) is
  'DEPRECATED. Belonged to the archived Machine 3 Writer. Retained rather than '
  'dropped because an unattributed write touched memory_events, memory_snapshots '
  'and child_patterns at 2026-07-28 10:01 that no n8n execution accounts for. '
  'Not provably dead.';

comment on function public.get_extraction_batch(integer) is
  'DEPRECATED. Machine 3 Writer input. Retained for the same unattributed-write '
  'reason as writer_commit().';

comment on function public._ensure_child(uuid, text) is
  'DEPRECATED. Helper called only by writer_commit(). Drop together with it.';

comment on function public.get_free_session_state(text, numeric) is
  'DEPRECATED. Free-session gating for the retired model. No live caller found.';

comment on function public.return_to_free(uuid) is
  'DEPRECATED as product logic, LIVE as an operator tool. Called from '
  'app/actions/activate.ts. Resets the legacy funnel columns; it does not touch '
  'payments or conversations.';

-- The five-argument activate_subscription predates this repository and is not
-- created by any migration in it, so a rebuild never has it to comment on.
-- Guarded rather than retargeted at the ten-argument version, because the two
-- are NOT the same function: 20260807090000 added an overload that starts a
-- journey, and left this one — the one the dashboard actually calls — starting
-- nothing. Both exist in production today. See docs/what-is-missing.md §3.
do $label$
begin
  if to_regprocedure('public.activate_subscription(uuid, integer, numeric, text, text)') is not null then
    execute $c$comment on function public.activate_subscription(uuid, integer, numeric, text, text) is
      'DEPRECATED. Manual payment activation from the dashboard, from before the '
      'journey engine existed: it moves the funnel columns and starts no stage. '
      'The ten-argument overload is the one that starts a journey.'$c$;
  end if;
end $label$;

commit;
