-- ============================================================
-- The Paid Snapshot, v1 scope, exactly as approved.
-- Design: docs/adam-snapshot-value-test.md ("The revised architecture this
-- forces") and docs/adam-paid-snapshot-contract.md (superseded in scope by
-- the value test — only the historical-starting-point piece ships).
--
-- What this is: ONE sentence, written ONCE per stage, at the moment observe
-- phase ends (logged_days reaches 3), describing how the first three logged
-- nights actually went. Never regenerated. Not an LLM call — a deterministic
-- template keyed on a real, computed ratio, so nothing here can invent a
-- fact: capture_stage_baseline() only ever renders one of four fixed
-- sentences, chosen by counting real daily_logs.night_result rows.
--
-- What this explicitly is NOT, per the approved scope:
--   no periodic W2 write, no regenerating snapshot, no restated PATTERNS,
--   no restated RECENT_DAYS, no tactical-experiment clause, no new context
--   tier — the rendered text is one more line inside the JOURNEY block that
--   already exists (20260811170000), not a new bracket-section.
--
-- The one new mechanism: stage_state() suppresses the baseline outright
-- unless the most recent 3 logged nights are STRICTLY calmer than the
-- baseline's own 3 — "RECENT_DAYS / current conversation > historical
-- snapshot" as an actual, checked inequality, not a stated intention.
-- ============================================================

begin;

alter table public.stages
  add column if not exists baseline_text          text,
  add column if not exists baseline_calm_count     smallint,
  add column if not exists baseline_captured_at    timestamptz;

comment on column public.stages.baseline_text is
  'The one sentence this stage will ever carry about how it started. Written once by capture_stage_baseline(), at the end of observe phase, from the first 3 logged nights. Never rewritten after that — a past-tense fact, not a claim about now.';
comment on column public.stages.baseline_calm_count is
  '0-3: how many of the first 3 logged nights were calm. The number stage_state() compares the most recent 3 nights against before it will surface baseline_text at all.';

-- ------------------------------------------------------------
-- capture_stage_baseline — the only writer, called once, idempotent.
--
-- No LLM. The four possible sentences are fixed; the only thing computed is
-- which one, from a plain count of real daily_logs rows. A stage that has
-- not yet reached 3 logged nights, or already has a baseline, is a no-op —
-- safe to call defensively on every harvest answer without cost or risk of
-- overwriting an existing baseline.
-- ------------------------------------------------------------
create or replace function public.capture_stage_baseline(p_parent_id uuid)
returns void
language plpgsql
security definer
set search_path to 'pg_catalog', 'public'
as $fn$
declare
  v_stage_id    uuid;
  v_started_at  timestamptz;
  v_calm        int;
  v_n           int;
  v_text        text;
begin
  select id, started_at into v_stage_id, v_started_at
  from public.stages
  where parent_id = p_parent_id
    and status in ('active', 'extended')
    and baseline_text is null
    and started_at is not null
  limit 1;

  if v_stage_id is null then
    return;
  end if;

  -- Same "logged day" definition v_stage_progress already uses: distinct
  -- log_date, on or after started_at, with a real night_result. First 3 by
  -- date, not the most recent 3 — this is the beginning, on purpose.
  select count(*) filter (where night_result = 'calm'), count(*)
    into v_calm, v_n
  from (
    select night_result
    from public.daily_logs
    where follower_id = p_parent_id
      and log_date >= v_started_at::date
      and night_result is not null
    order by log_date asc
    limit 3
  ) first3;

  if v_n < 3 then
    return; -- observe phase is not actually over yet
  end if;

  v_text := case v_calm
    when 0 then 'في الأسبوع الأول: كانت الليالي المسجّلة كلها صعبة.'
    when 1 then 'في الأسبوع الأول: كانت أغلب الليالي المسجّلة صعبة.'
    when 2 then 'في الأسبوع الأول: كانت أغلب الليالي المسجّلة هادئة.'
    else        'في الأسبوع الأول: كانت الليالي المسجّلة هادئة نسبياً بالفعل.'
  end;

  update public.stages
     set baseline_text       = v_text,
         baseline_calm_count = v_calm,
         baseline_captured_at = now()
   where id = v_stage_id
     and baseline_text is null; -- belt-and-suspenders: still idempotent
                                 -- under a concurrent second call
end;
$fn$;

comment on function public.capture_stage_baseline(uuid) is
  'Writes stages.baseline_text exactly once, when the first 3 logged nights exist. Deterministic template keyed on a real calm-night count — no LLM, nothing to invent. No-op if already captured or observe is not yet over; safe to call on every harvest answer.';

revoke all on function public.capture_stage_baseline(uuid) from anon, authenticated, public;
grant execute on function public.capture_stage_baseline(uuid) to service_role;


-- ------------------------------------------------------------
-- record_harvest_answer — one additive call, body otherwise untouched
-- (transcribed verbatim from 20260807210000, the current repo source of
-- truth; a production deploy would re-verify the live body first, same
-- safety pattern as every other function change this session).
-- ------------------------------------------------------------
create or replace function public.record_harvest_answer(
  p_parent_id uuid, p_outcome text, p_hard_moment text default null)
returns jsonb
language plpgsql
set search_path to 'pg_catalog', 'public'
as $fn$
declare
  v_day  public.daily_logs%rowtype;
  v_tz   text;
  v_date date;
begin
  if p_outcome is null or p_outcome not in ('succeeded', 'tried_failed', 'no_chance') then
    return jsonb_build_object(
      'recorded', false,
      'reason', 'unknown_outcome',
      'given', p_outcome,
      'expected', jsonb_build_array('succeeded', 'tried_failed', 'no_chance'));
  end if;

  select ct.iana_tz into v_tz
  from public.followers f
  join public.country_timezone ct on upper(btrim(f.country)) = ct.code
  where f.id = p_parent_id;

  v_date := (now() at time zone coalesce(v_tz, 'UTC'))::date;

  update public.daily_logs
     set step_status = case p_outcome
                         when 'succeeded'    then 'done'
                         when 'tried_failed' then 'tried_failed'
                         when 'no_chance'    then 'not_tried' end,
         night_result = case p_outcome
                         when 'succeeded'    then 'calm'
                         when 'tried_failed' then 'hard'
                         else night_result end,
         hard_moment  = coalesce(p_hard_moment, hard_moment),
         harvest_answered_at = now(),
         updated_at = now()
   where follower_id = p_parent_id
     and log_date = v_date
     and seed_sent_at is not null
  returning * into v_day;

  if v_day.id is null then
    return jsonb_build_object('recorded', false, 'reason', 'no_seed_today');
  end if;

  update public.checkin_state
     set consecutive_ignored = 0, last_responded_at = now(), updated_at = now()
   where parent_id = p_parent_id;

  -- ⭐ The only addition. A no-op unless this answer is the 3rd logged night
  -- of a live stage's observe phase with no baseline yet.
  perform public.capture_stage_baseline(p_parent_id);

  return jsonb_build_object('recorded', true, 'day_id', v_day.id, 'local_date', v_date);
end;
$fn$;

comment on function public.record_harvest_answer(uuid, text, text) is
  'Records how the night went, for today''s seed only. The outcome must be one of succeeded / tried_failed / no_chance; anything else is refused outright. Also the one trigger point for capture_stage_baseline() — a no-op except on the exact night observe phase ends.';

revoke all on function public.record_harvest_answer(uuid, text, text) from anon, authenticated, public;
grant execute on function public.record_harvest_answer(uuid, text, text) to service_role;


-- ------------------------------------------------------------
-- stage_state — adds baseline_text to the output, gated by the one rule
-- that matters: only shown if the most recent 3 logged nights are
-- STRICTLY calmer than the baseline's own 3. Not blended, not softened —
-- an inequality, checked fresh every call. v_stage_progress (the view) is
-- untouched; the baseline columns are read directly off stages.
-- ------------------------------------------------------------
create or replace function public.stage_state(p_parent_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'pg_catalog', 'public'
as $function$
declare
  v            record;
  v_baseline_text  text;
  v_baseline_calm  int;
  v_recent_calm    int;
  v_show_baseline  boolean := false;
begin
  select * into v from public.v_stage_progress
  where parent_id = p_parent_id and status in ('active','extended')
  limit 1;

  if not found then
    return jsonb_build_object('in_stage', false);
  end if;

  select s.baseline_text, s.baseline_calm_count
    into v_baseline_text, v_baseline_calm
  from public.stages s where s.id = v.stage_id;

  if v_baseline_text is not null then
    select count(*) filter (where night_result = 'calm')
      into v_recent_calm
    from (
      select night_result
      from public.daily_logs
      where follower_id = p_parent_id and night_result is not null
      order by log_date desc
      limit 3
    ) recent3;

    -- The one rule: live data must be STRICTLY better than the baseline
    -- before the baseline is allowed to speak. Equal or worse: silence,
    -- not a softened version of the claim.
    v_show_baseline := v_recent_calm > v_baseline_calm;
  end if;

  return jsonb_build_object(
    'in_stage',          true,
    'stage_id',          v.stage_id,
    'problem_key',       v.problem_key,
    'objective_text',    v.objective_text,
    'objective_target',  v.objective_target,
    'objective_window',  v.objective_window,
    'objective_current', v.objective_current,
    'window_filled',     v.window_filled,
    'objective_met',     v.objective_met,
    'logged_days',       v.logged_days,
    'allowed_days',      v.allowed_days,
    'days_remaining',    v.days_remaining,
    'clock_exhausted',   v.clock_exhausted,
    'extended',          v.status = 'extended',
    'phase',             v.phase,
    'phase_ar', case v.phase
      when 'observe' then 'نراقب — لم نغيّر شيئاً بعد، نتعرّف على ما يحدث فعلاً'
      when 'build'   then 'نبني — خطوة كل يوم على ما نفع أمس'
      else                'نُمسك — أتراجع عمداً، لنرى الهدوء وهو يصمد بلا تذكير'
    end,
    'baseline_text', case when v_show_baseline then v_baseline_text else null end);
end;
$function$;

comment on function public.stage_state(uuid) is
  'The live journey and everything derived from it: the agreed objective, progress, the clock, the phase, and — only when the most recent 3 logged nights are strictly calmer than the first 3 were — the one-sentence baseline captured at the end of observe. Returns in_stage=false for a parent who is not in one, which is most parents. baseline_text is null whenever showing it would contradict or merely restate the current data, not just when it is absent.';


-- ------------------------------------------------------------
-- get_agent_context — one more conditional line inside the JOURNEY block
-- that already exists (20260811170000). No new bracket-section, no new
-- tier, exactly as scoped.
-- ------------------------------------------------------------
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
  select greatest(0, extract(day from f.subscription_expires_at - now())::int)
    into v_days_left
  from followers f
  where f.id = p_follower_id;

  v_out := 'DAYS_LEFT: ' || coalesce(v_days_left::text, '?');

  select snapshot_text into v_snap
  from memory_snapshots where follower_id = p_follower_id and char_count > 0;
  if v_snap is not null then
    v_out := v_out || E'\n\n== SUMMARY ==\n' || v_snap;
  end if;

  select string_agg(
    '- ' || name
    || coalesce(' ('||gender||')','')
    || coalesce(', '||age_note,'')
    || coalesce(', طبع: '||temperament,''), E'\n')
  into v_children from children where follower_id = p_follower_id;
  if v_children is not null then
    v_out := v_out || E'\n\n== CHILDREN ==\n' || v_children;
  end if;

  select string_agg(
    '- ['||status||' x'||evidence_count||'] '||pattern_label
    || coalesce(': '||description,''), E'\n')
  into v_patterns from child_patterns
  where follower_id = p_follower_id and status <> 'resolved';
  if v_patterns is not null then
    v_out := v_out || E'\n\n== PATTERNS ==\n' || v_patterns;
  end if;

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
    -- ⭐ The one new line. Absent whenever stage_state() withheld it —
    -- never, ever, an empty "- baseline:" header (absent-not-empty,
    -- adam-context-contract.md's own rule, applied to itself).
    if v_stage->>'baseline_text' is not null then
      v_out := v_out || E'\n' || '- baseline: ' || (v_stage->>'baseline_text');
    end if;
  end if;

  return v_out;
end $fn$;

comment on function public.get_agent_context(uuid) is
  'Facts only — the raw block the conversational agent may draw on. Adds a JOURNEY block for a parent with a live stage (reusing stage_state() verbatim), now including one conditional baseline line — the v1 Paid Snapshot, docs/adam-snapshot-value-test.md — present only when stage_state() judged the live data strictly better than the stage''s own start. Absent for a free parent, absent whenever showing it would contradict the current data, absent whenever observe phase has not ended yet.';

commit;
