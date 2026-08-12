-- ============================================================
-- ADAM receives the journey. Fixes the paid blindness named in
-- docs/adam-under-the-microscope.md Finding 1: get_agent_context carried
-- DAYS_LEFT (an access clock) and nothing about the journey itself, so
-- the conversational agent was byte-identical for a free stranger and a
-- parent 20 days into a paid journey.
--
-- Adds ONE block, facts only — no directives here. get_agent_context is
-- the facts layer; get_agent_bundle (next migration) is where facts
-- become behavioural instruction, exactly the separation the rest of
-- this function already keeps (SUMMARY/CHILDREN/PATTERNS are facts;
-- the "[ما يُسمح لك أن تدّعي معرفته]" permission line, built in
-- get_agent_bundle, is the directive).
--
-- Reuses stage_state() verbatim — no journey logic is duplicated here,
-- only rendered. A parent with no live stage gets no JOURNEY block at
-- all (in_stage=false), so free is completely unaffected: this is
-- additive, not a rewrite of the free path.
-- ============================================================

begin;

create or replace function public.get_agent_context(p_follower_id uuid)
returns text
language plpgsql
stable
set search_path to 'pg_catalog', 'public'
as $fn$
declare
  v_out text := '';
  v_snap text;
  v_children text;
  v_patterns text;
  v_events text;
  v_logs text;
  v_days_left int;
  v_stage jsonb;
begin
  -- PLAN_DAY is gone with plan_sessions. DAYS_LEFT stays: it is the access clock
  -- the parent actually paid for, and it comes straight off followers.
  select greatest(0, extract(day from f.subscription_expires_at - now())::int)
    into v_days_left
  from followers f
  where f.id = p_follower_id;

  v_out := 'DAYS_LEFT: ' || coalesce(v_days_left::text, '?');

  -- الملخص المضغوط
  select snapshot_text into v_snap
  from memory_snapshots where follower_id = p_follower_id and char_count > 0;
  if v_snap is not null then
    v_out := v_out || E'\n\n== SUMMARY ==\n' || v_snap;
  end if;

  -- الأطفال
  select string_agg(
    '- ' || name
    || coalesce(' ('||gender||')','')
    || coalesce(', '||age_note,'')
    || coalesce(', طبع: '||temperament,''), E'\n')
  into v_children from children where follower_id = p_follower_id;
  if v_children is not null then
    v_out := v_out || E'\n\n== CHILDREN ==\n' || v_children;
  end if;

  -- الأنماط النشطة (غير المحلولة)
  select string_agg(
    '- ['||status||' x'||evidence_count||'] '||pattern_label
    || coalesce(': '||description,''), E'\n')
  into v_patterns from child_patterns
  where follower_id = p_follower_id and status <> 'resolved';
  if v_patterns is not null then
    v_out := v_out || E'\n\n== PATTERNS ==\n' || v_patterns;
  end if;

  -- آخر 5 أحداث مهمة (وزن شعوري >= 3)
  select string_agg(line, E'\n') into v_events from (
    select '- ['||event_type||', '||to_char(occurred_at,'MM/DD')||'] '||title
           || coalesce(': '||summary,'') as line
    from memory_events
    where follower_id = p_follower_id and emotional_weight >= 3
    order by occurred_at desc limit 5
  ) t;
  if v_events is not null then
    v_out := v_out || E'\n\n== KEY_MOMENTS ==\n' || v_events;
  end if;

  -- آخر 3 أيام
  select string_agg(line, E'\n') into v_logs from (
    select '- ['||log_date||'] '||coalesce(summary,'')
           || coalesce(' | خطوة: '||step_given,'')
           || case step_completed when true then ' (نُفذت)' when false then ' (لم تُنفذ)' else '' end as line
    from daily_logs
    where follower_id = p_follower_id
    order by log_date desc limit 3
  ) t;
  if v_logs is not null then
    v_out := v_out || E'\n\n== RECENT_DAYS ==\n' || v_logs;
  end if;

  -- ⭐ JOURNEY — facts only, for a parent with a live paid stage.
  -- Reuses stage_state() (tested, live) rather than re-deriving phase or
  -- progress. Absent entirely for a free parent (in_stage=false).
  v_stage := public.stage_state(p_follower_id);
  if coalesce((v_stage->>'in_stage')::boolean, false) then
    v_out := v_out || E'\n\n== JOURNEY ==\n'
      || '- objective: ' || (v_stage->>'objective_text') || E'\n'
      || '- phase: ' || (v_stage->>'phase') || E'\n'
      || '- logged_days: ' || (v_stage->>'logged_days')
      || ' / allowed_days: ' || (v_stage->>'allowed_days') || E'\n'
      || '- progress: ' || (v_stage->>'objective_current')
      || ' / ' || (v_stage->>'objective_target')
      || ' (window ' || (v_stage->>'window_filled') || ')';
  end if;

  return v_out;
end $fn$;

comment on function public.get_agent_context(uuid) is
  'Facts only — the raw block the conversational agent may draw on, before knowledge-level or journey-phase permission is applied (that translation happens in get_agent_bundle). Adds a JOURNEY block (objective, phase, progress) for a parent with a live stage, reusing stage_state() verbatim; absent for a free parent, so the free path is unaffected. DAYS_LEFT stays (the access clock); get_agent_bundle still strips it before the model sees anything, unchanged.';

commit;
