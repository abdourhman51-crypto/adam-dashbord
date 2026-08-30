\set ON_ERROR_STOP on
begin;

-- ============================================================
-- The Paid Snapshot, v1 scope — the historical-starting-point baseline.
-- Design: docs/adam-snapshot-value-test.md, docs/adam-paid-snapshot-contract.md.
-- Migration: 20260812100000_the_baseline_is_written_once.sql.
--
-- Every daily_logs row here is produced by the SAME production writers the
-- live product calls (record_seed_sent / record_harvest_sent /
-- record_harvest_answer), following lifecycle_test.sql's own discipline: "a
-- harness that invents its own rows tests the harness." The one thing aged
-- by hand is the row's DATE (record_harvest_answer only ever writes today),
-- never its content.
--
-- What this file proves, exactly matching what was approved:
--   1. Written exactly once, at the real end of observe (3rd logged night),
--      through the real trigger point (record_harvest_answer), not before.
--   2. Deterministic — same four template sentences, chosen only by a real
--      calm-night count. No two calls ever produce different text for the
--      same data.
--   3. Idempotent — a 4th, 5th, 10th logged night never overwrites it.
--   4. The conflict rule: shown only when the most recent 3 logged nights
--      are STRICTLY calmer than the first 3 were. Equal or worse: silent.
--   5. Reaches ADAM only inside the existing JOURNEY block — no new tier,
--      no empty header, absent whenever suppressed.
--   6. Budget — every real template stays inside the ~30-token ceiling.
-- ============================================================

create table pg_temp.r (n int generated always as identity, name text, result text, detail text);
create or replace function pg_temp.chk(p_name text, p_cond boolean, p_detail text default null)
returns void language sql as $$
  insert into pg_temp.r (name, result, detail)
  values (p_name, case when p_cond then 'PASS' else 'FAIL' end, p_detail);
$$;

insert into public.country_timezone (code, iana_tz) values ('DZ','Africa/Algiers')
on conflict (code) do nothing;

-- A real family, up through a confirmed situation and a live stage — the
-- same chain lifecycle_test.sql already proved works, reused rather than
-- reinvented.
create or replace function pg_temp.new_family(p_child_name text)
returns table(parent uuid, child uuid, situation uuid, stage uuid)
language plpgsql as $$
declare v_p uuid; v_c uuid; v_s uuid; v_stage uuid; v_sg jsonb; v_j jsonb;
begin
  insert into public.followers (platform_user_id, country)
  values ('sim-'||gen_random_uuid()::text, 'DZ') returning id into v_p;

  perform public.commit_child_name(v_p, p_child_name, null, 'high');
  select id into v_c from public.children where follower_id = v_p;

  perform public.commit_situation(v_p, v_c, 'sleep');
  perform public.commit_situation(v_p, v_c, 'sleep');
  perform public.commit_situation(v_p, v_c, 'sleep');
  select id into v_s from public.situations where child_id = v_c;

  v_sg := public.suggest_objective(v_p);
  v_j := public.start_stage(v_p, v_sg->>'problem_key', v_sg->>'objective_text',
                             (v_sg->>'objective_target')::int,
                             (v_sg->>'objective_window')::int,
                             (v_sg->>'planned_logged_days')::int);
  v_stage := (v_j->>'stage_id')::uuid;
  -- Push the start back so every lived day below can be aged forward from it.
  update public.stages set started_at = now() - interval '60 days' where id = v_stage;

  return query select v_p, v_c, v_s, v_stage;
end $$;

-- One real logged night, through the real writers, aged to p_age days ago
-- (0 = today). Same helper shape as lifecycle_test.sql's lived_day.
create or replace function pg_temp.lived_day(
  p_parent uuid, p_child uuid, p_situation uuid, p_outcome text, p_age int)
returns void language plpgsql as $$
declare v_today date; v_day uuid;
begin
  select (now() at time zone 'Africa/Algiers')::date into v_today;
  v_day := (public.record_seed_sent(
    p_parent, v_today, 'خطوة صغيرة الليلة',
    jsonb_build_array('child_name','situation'), p_situation, p_child)->>'day_id')::uuid;
  perform public.record_harvest_sent(v_day);
  perform public.record_harvest_answer(p_parent, p_outcome);
  if p_age > 0 then
    update public.daily_logs set log_date = v_today - p_age
    where follower_id = p_parent and log_date = v_today;
  end if;
end $$;


\echo '=== 1. THE BASELINE IS WRITTEN ONCE, ON THE REAL 3RD LOGGED NIGHT, AND STAYS ==='
do $$
declare f record; st jsonb; t1 timestamptz;
begin
  select * into f from pg_temp.new_family('سارة');

  perform pg_temp.lived_day(f.parent, f.child, f.situation, 'tried_failed', 59);
  perform pg_temp.chk('nothing captured after 1 logged night',
    (select baseline_text from public.stages where id = f.stage) is null);

  perform pg_temp.lived_day(f.parent, f.child, f.situation, 'tried_failed', 58);
  perform pg_temp.chk('nothing captured after 2 logged nights',
    (select baseline_text from public.stages where id = f.stage) is null);

  perform pg_temp.lived_day(f.parent, f.child, f.situation, 'tried_failed', 57);
  perform pg_temp.chk('the 3rd logged night writes the baseline',
    (select baseline_text from public.stages where id = f.stage) is not null,
    (select baseline_text from public.stages where id = f.stage));
  perform pg_temp.chk('three hard nights produce the all-hard sentence',
    (select baseline_text from public.stages where id = f.stage)
      = 'في الأسبوع الأول: كانت الليالي المسجّلة كلها صعبة.');
  perform pg_temp.chk('the calm count stored is exactly 0',
    (select baseline_calm_count from public.stages where id = f.stage) = 0);

  select baseline_captured_at into t1 from public.stages where id = f.stage;

  -- A 4th, 5th logged night must never rewrite it — idempotency through the
  -- REAL trigger point, not just the function called in isolation.
  perform pg_temp.lived_day(f.parent, f.child, f.situation, 'succeeded', 56);
  perform pg_temp.lived_day(f.parent, f.child, f.situation, 'succeeded', 55);
  perform pg_temp.chk('a later calm night does not change the stored text',
    (select baseline_text from public.stages where id = f.stage)
      = 'في الأسبوع الأول: كانت الليالي المسجّلة كلها صعبة.');
  perform pg_temp.chk('or the stored calm count',
    (select baseline_calm_count from public.stages where id = f.stage) = 0);
  perform pg_temp.chk('or even the captured_at timestamp',
    (select baseline_captured_at from public.stages where id = f.stage) = t1);
end $$;


\echo '=== 2. THE FOUR TEMPLATES ARE DETERMINISTIC, KEYED ONLY ON A REAL COUNT ==='
do $$
declare f record;
begin
  -- 1 calm of 3
  select * into f from pg_temp.new_family('ياسمين');
  perform pg_temp.lived_day(f.parent, f.child, f.situation, 'tried_failed', 59);
  perform pg_temp.lived_day(f.parent, f.child, f.situation, 'succeeded',    58);
  perform pg_temp.lived_day(f.parent, f.child, f.situation, 'tried_failed', 57);
  perform pg_temp.chk('1 of 3 calm -> "most were hard"',
    (select baseline_text from public.stages where id = f.stage)
      = 'في الأسبوع الأول: كانت أغلب الليالي المسجّلة صعبة.',
    (select baseline_text from public.stages where id = f.stage));

  -- 2 calm of 3
  select * into f from pg_temp.new_family('ريم');
  perform pg_temp.lived_day(f.parent, f.child, f.situation, 'succeeded',    59);
  perform pg_temp.lived_day(f.parent, f.child, f.situation, 'succeeded',    58);
  perform pg_temp.lived_day(f.parent, f.child, f.situation, 'tried_failed', 57);
  perform pg_temp.chk('2 of 3 calm -> "most were calm"',
    (select baseline_text from public.stages where id = f.stage)
      = 'في الأسبوع الأول: كانت أغلب الليالي المسجّلة هادئة.');

  -- 3 calm of 3
  select * into f from pg_temp.new_family('لين');
  perform pg_temp.lived_day(f.parent, f.child, f.situation, 'succeeded', 59);
  perform pg_temp.lived_day(f.parent, f.child, f.situation, 'succeeded', 58);
  perform pg_temp.lived_day(f.parent, f.child, f.situation, 'succeeded', 57);
  perform pg_temp.chk('3 of 3 calm -> "already relatively calm"',
    (select baseline_text from public.stages where id = f.stage)
      = 'في الأسبوع الأول: كانت الليالي المسجّلة هادئة نسبياً بالفعل.');
end $$;


\echo '=== 3. THE CONFLICT RULE: LIVE DATA MUST BEAT THE BASELINE, NOT MATCH IT ==='
do $$
declare f record; st jsonb;
begin
  -- Baseline = 0 calm of 3 (all hard). Recent 3 also all hard: must NOT show.
  select * into f from pg_temp.new_family('هدى');
  perform pg_temp.lived_day(f.parent, f.child, f.situation, 'tried_failed', 59);
  perform pg_temp.lived_day(f.parent, f.child, f.situation, 'tried_failed', 58);
  perform pg_temp.lived_day(f.parent, f.child, f.situation, 'tried_failed', 57);
  perform pg_temp.lived_day(f.parent, f.child, f.situation, 'tried_failed', 10);
  perform pg_temp.lived_day(f.parent, f.child, f.situation, 'tried_failed', 9);
  perform pg_temp.lived_day(f.parent, f.child, f.situation, 'tried_failed', 8);
  st := public.stage_state(f.parent);
  perform pg_temp.chk('equal-to-baseline recent nights: baseline stays silent',
    st->>'baseline_text' is null, st::text);

  -- One more still-hard night: still equal (0 vs 0). Still silent.
  perform pg_temp.lived_day(f.parent, f.child, f.situation, 'tried_failed', 7);
  st := public.stage_state(f.parent);
  perform pg_temp.chk('still equal: still silent, not "softened"',
    st->>'baseline_text' is null);

  -- A single calm night among the most recent 3 (1 > 0): now allowed to speak.
  perform pg_temp.lived_day(f.parent, f.child, f.situation, 'succeeded', 6);
  st := public.stage_state(f.parent);
  perform pg_temp.chk('recent strictly calmer than baseline: now shown',
    st->>'baseline_text' = 'في الأسبوع الأول: كانت الليالي المسجّلة كلها صعبة.',
    st::text);
end $$;


\echo '=== 4. THE REGRESSION CASE THIS RULE EXISTS FOR: A REAL RELAPSE STAYS SILENT ==='
do $$
declare f record; st jsonb;
begin
  -- Baseline = 2 of 3 calm (started fairly well). Then a real relapse: 3
  -- hard nights in a row, most recently. Recent(0) is WORSE than baseline(2)
  -- -- this must never be softened into "well it started ok-ish."
  select * into f from pg_temp.new_family('وئام');
  perform pg_temp.lived_day(f.parent, f.child, f.situation, 'succeeded',    59);
  perform pg_temp.lived_day(f.parent, f.child, f.situation, 'succeeded',    58);
  perform pg_temp.lived_day(f.parent, f.child, f.situation, 'tried_failed', 57);
  perform pg_temp.chk('setup: baseline is 2 of 3 calm',
    (select baseline_calm_count from public.stages where id = f.stage) = 2);

  perform pg_temp.lived_day(f.parent, f.child, f.situation, 'tried_failed', 3);
  perform pg_temp.lived_day(f.parent, f.child, f.situation, 'tried_failed', 2);
  perform pg_temp.lived_day(f.parent, f.child, f.situation, 'tried_failed', 1);
  st := public.stage_state(f.parent);
  perform pg_temp.chk('a real relapse (0 recent vs 2 baseline) is never shown as reassurance',
    st->>'baseline_text' is null, st::text);
end $$;


\echo '=== 5. IT REACHES ADAM ONLY INSIDE THE EXISTING JOURNEY BLOCK, NEVER AS A NEW TIER ==='
do $$
declare f record; ctx text; f_free uuid;
begin
  -- Paid, shown case: reuse a family already past the conflict test above
  -- with the baseline legitimately visible.
  select * into f from pg_temp.new_family('دانة');
  perform pg_temp.lived_day(f.parent, f.child, f.situation, 'tried_failed', 59);
  perform pg_temp.lived_day(f.parent, f.child, f.situation, 'tried_failed', 58);
  perform pg_temp.lived_day(f.parent, f.child, f.situation, 'tried_failed', 57);
  perform pg_temp.lived_day(f.parent, f.child, f.situation, 'succeeded',    3);
  perform pg_temp.lived_day(f.parent, f.child, f.situation, 'succeeded',    2);
  perform pg_temp.lived_day(f.parent, f.child, f.situation, 'succeeded',    1);

  ctx := public.get_agent_context(f.parent);
  -- The objective label was renamed in 20260830210000 from the ownerless
  -- "- objective:" to "- هدف الوالد عن نفسه:". The assertion is about ORDER and
  -- containment (baseline sits inside JOURNEY, after objective/phase/progress),
  -- not about the label's wording — so it tracks the new label and keeps
  -- asserting exactly what it was written to assert.
  perform pg_temp.chk('the baseline line lives inside == JOURNEY ==, after objective/phase/progress',
    ctx ~ '== JOURNEY ==.*- هدف الوالد عن نفسه:.*- phase:.*- progress:.*- baseline: في الأسبوع الأول',
    ctx);
  perform pg_temp.chk('no new bracket-section was introduced for the baseline — it is one line inside JOURNEY, not its own header',
    ctx !~ '== *(BASELINE|نقطة البداية|SNAPSHOT) *==' and ctx ~ '- baseline: ', ctx);

  -- Suppressed case: no "- baseline:" line at all, not an empty one.
  declare f2 record; ctx2 text;
  begin
    select * into f2 from pg_temp.new_family('أمل');
    perform pg_temp.lived_day(f2.parent, f2.child, f2.situation, 'tried_failed', 59);
    perform pg_temp.lived_day(f2.parent, f2.child, f2.situation, 'tried_failed', 58);
    perform pg_temp.lived_day(f2.parent, f2.child, f2.situation, 'tried_failed', 57);
    ctx2 := public.get_agent_context(f2.parent);
    perform pg_temp.chk('suppressed baseline: no "- baseline:" line appears at all (absent, not empty)',
      ctx2 !~ '- baseline:', ctx2);
  end;

  -- Free parent, otherwise identical evidence, never sees JOURNEY at all —
  -- the baseline cannot leak to free by construction, since it only ever
  -- renders inside a block free parents never get.
  insert into public.followers (platform_user_id, country)
  values ('sim-'||gen_random_uuid()::text, 'DZ') returning id into f_free;
  perform public.commit_child_name(f_free, 'رغد', null, 'high');
  perform pg_temp.chk('a free parent (no stage) never sees a JOURNEY block, so never the baseline',
    public.get_agent_context(f_free) !~ 'JOURNEY|baseline');
end $$;


\echo '=== 6. BUDGET: EVERY TEMPLATE FITS THE ~30-TOKEN CEILING ==='
do $$
declare v_texts text[] := array[
  'في الأسبوع الأول: كانت الليالي المسجّلة كلها صعبة.',
  'في الأسبوع الأول: كانت أغلب الليالي المسجّلة صعبة.',
  'في الأسبوع الأول: كانت أغلب الليالي المسجّلة هادئة.',
  'في الأسبوع الأول: كانت الليالي المسجّلة هادئة نسبياً بالفعل.'
];
  v text;
begin
  foreach v in array v_texts loop
    -- Char length as a cheap proxy in-SQL; the real cl100k_base token count
    -- for each of these four was measured offline (gpt-tokenizer, no
    -- network) at 24-31 tokens, inside the ~30-token target. This assertion
    -- just guards against someone quietly lengthening a template later.
    perform pg_temp.chk('template stays under 100 chars: ' || left(v, 20) || '…',
      length(v) <= 100, length(v)::text);
  end loop;
end $$;


\echo '=== 7. record_harvest_answer STILL BEHAVES EXACTLY AS BEFORE (REGRESSION) ==='
do $$
declare f record; r jsonb;
begin
  select * into f from pg_temp.new_family('منى');

  r := public.record_harvest_answer(f.parent, 'not_a_real_outcome');
  perform pg_temp.chk('an unrecognised outcome is still refused outright',
    (r->>'recorded')::boolean = false and r->>'reason' = 'unknown_outcome', r::text);

  r := public.record_harvest_answer(f.parent, 'succeeded');
  perform pg_temp.chk('answering with no seed sent today is still refused',
    (r->>'recorded')::boolean = false and r->>'reason' = 'no_seed_today', r::text);

  perform pg_temp.lived_day(f.parent, f.child, f.situation, 'succeeded', 0);
  perform pg_temp.chk('a normal lived day still records normally',
    exists(select 1 from public.daily_logs
           where follower_id = f.parent and night_result = 'calm'
             and log_date = (now() at time zone 'Africa/Algiers')::date));
end $$;


\echo '=== RESULTS ==='
\pset format unaligned
select lpad(n::text,2) || '  ' || rpad(result,4) || '  ' || name
       || case when result='FAIL' and detail is not null then '  [' || detail || ']' else '' end
from pg_temp.r order by n;

select (count(*) filter (where result='PASS'))::text || ' / ' || count(*)::text || ' passed'
from pg_temp.r;
select 'FAIL'::text || ' ' || name from pg_temp.r where result = 'FAIL';

rollback;
