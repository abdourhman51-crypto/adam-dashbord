\set ON_ERROR_STOP on
begin;

-- ============================================================
-- compose_journey_step — the daily plan, walked through its phases.
--
-- No fixed plans: the step is grown from the child's evidence, and the
-- phase (observe → build → hold) is what makes two nights cohere into a
-- journey. These cases assert the posture changes with the phase, that
-- `build` leans on what actually worked, and that a parent with no live
-- journey gets nothing.
--
-- Every row is written by the production writers where it matters, and
-- the whole thing rolls back.
-- ============================================================

create table pg_temp.r (n int generated always as identity, name text, result text, detail text);
create or replace function pg_temp.chk(p_name text, p_cond boolean, p_detail text default null)
returns void language sql as $$
  insert into pg_temp.r (name, result, detail)
  values (p_name, case when p_cond then 'PASS' else 'FAIL' end, p_detail);
$$;

-- A family with a named child and a confirmed situation.
create or replace function pg_temp.family(p_name text)
returns uuid language plpgsql as $$
declare v uuid; c uuid;
begin
  insert into public.followers (platform_user_id, country)
  values (gen_random_uuid()::text, 'DZ') returning id into v;
  insert into public.children (follower_id, name, is_primary)
  values (v, p_name, true) returning id into c;
  insert into public.situations (child_id, parent_id, key, label_ar, status,
                                 evidence_count, window_start, window_end)
  select c, ch.follower_id, 'sleep', sc.label_ar, 'confirmed', 4,
         sc.window_start, sc.window_end
  from public.children ch, public.situation_catalog sc
  where ch.id = c and sc.key = 'sleep';
  return v;
end $$;

-- Nights on the journey clock: each a distinct log_date, with an
-- optional step text so `build` has something that worked to lean on.
create or replace function pg_temp.walk(p uuid, n int, res text, step text default null)
returns void language plpgsql as $$
declare v_from date;
begin
  select coalesce(max(log_date) + 1, current_date) into v_from
  from public.daily_logs where follower_id = p;
  insert into public.daily_logs (follower_id, log_date, night_result, step_given, step_status)
  select p, v_from + g, res, step,
         case when res = 'calm' then 'done' else 'tried_failed' end
  from generate_series(0, n - 1) g;
end $$;


\echo '=== 1. NO LIVE JOURNEY → NOTHING TO COMPOSE ==='
do $$
declare p uuid; j jsonb;
begin
  p := pg_temp.family('نور');
  j := public.compose_journey_step(p);
  perform pg_temp.chk('no journey: in_journey false',
    (j->>'in_journey')::boolean = false, j::text);
end $$;


\echo '=== 2. OBSERVE — change nothing, watch the situation ==='
do $$
declare p uuid; j jsonb;
begin
  p := pg_temp.family('يوسف');
  -- Some free-tier outcomes so can_send has something, then start the journey.
  perform pg_temp.walk(p, 2, 'hard', 'خطوة قديمة');
  perform public.start_stage(p, 'sleep', 'خمس ليالٍ هادئة من سبع', 5, 7, 29);

  j := public.compose_journey_step(p);
  perform pg_temp.chk('observe: in_journey true', (j->>'in_journey')::boolean = true);
  perform pg_temp.chk('observe: phase is observe', j->>'phase' = 'observe', j->>'phase');
  perform pg_temp.chk('observe: directive says change nothing',
    position('دون أن يغيّروا' in (j->>'phase_directive')) > 0, j->>'phase_directive');
  perform pg_temp.chk('observe: directive names the situation',
    position((public.hard_moment_label('sleep')) in (j->>'phase_directive')) > 0);
  perform pg_temp.chk('observe: carries the agreed objective',
    j->>'objective_text' = 'خمس ليالٍ هادئة من سبع', j->>'objective_text');
end $$;


\echo '=== 3. BUILD — one step, leaning on what worked ==='
do $$
declare p uuid; j jsonb;
begin
  p := pg_temp.family('سارة');
  perform public.start_stage(p, 'sleep', 'خمس ليالٍ هادئة من سبع', 5, 7, 29);
  -- Push past observe (>=3 logged days), with one clearly-working step.
  perform pg_temp.walk(p, 3, 'hard', 'خطوة أ');
  perform pg_temp.walk(p, 1, 'calm', 'خفض الأضواء قبل النوم');
  perform pg_temp.walk(p, 2, 'hard', 'خطوة ب');

  j := public.compose_journey_step(p);
  perform pg_temp.chk('build: phase is build', j->>'phase' = 'build', j->>'phase');
  perform pg_temp.chk('build: leans on the step that worked',
    j->>'last_working_step' = 'خفض الأضواء قبل النوم', j->>'last_working_step');
  perform pg_temp.chk('build: directive proposes one step built on what worked',
    position('مبنية على ما نفع' in (j->>'phase_directive')) > 0
    and position('خفض الأضواء' in (j->>'phase_directive')) > 0, j->>'phase_directive');
  perform pg_temp.chk('build: directive forbids repeating a step',
    position('لا تكرّر' in (j->>'phase_directive')) > 0);
  perform pg_temp.chk('build: recent steps are carried',
    jsonb_array_length(j->'recent_steps') > 0, (j->'recent_steps')::text);
  perform pg_temp.chk('build: last night is reported',
    j->'last_night'->>'result' is not null, (j->'last_night')::text);
end $$;


\echo '=== 4. HOLD — ADAM fades, no step, only the question ==='
do $$
declare p uuid; j jsonb;
begin
  p := pg_temp.family('لين');
  -- A short journey so hold begins early: 7 logged days, hold is the last third.
  perform public.start_stage(p, 'sleep', 'خمس ليالٍ هادئة من سبع', 5, 7, 7);
  perform pg_temp.walk(p, 6, 'calm', 'روتين ثابت');

  j := public.compose_journey_step(p);
  perform pg_temp.chk('hold: phase is hold', j->>'phase' = 'hold', j->>'phase');
  perform pg_temp.chk('hold: directive fades ADAM out (no step)',
    position('لا تقترح خطوة' in (j->>'phase_directive')) > 0, j->>'phase_directive');
  perform pg_temp.chk('hold: directive names the child',
    position('لين' in (j->>'phase_directive')) > 0);
end $$;


\echo '=== 5. THE GATE — an objective with no outcome yet cannot send ==='
do $$
declare p uuid; c uuid; j jsonb;
begin
  -- A journey with a live stage but ZERO recorded outcomes: can_send refuses.
  insert into public.followers (platform_user_id, country)
  values (gen_random_uuid()::text, 'DZ') returning id into p;
  insert into public.children (follower_id, name, is_primary)
  values (p, 'رفيق', true) returning id into c;
  insert into public.situations (child_id, parent_id, key, label_ar, status,
                                 evidence_count, window_start, window_end)
  select c, p, 'sleep', sc.label_ar, 'confirmed', 4, sc.window_start, sc.window_end
  from public.situation_catalog sc where sc.key = 'sleep';
  perform public.start_stage(p, 'sleep', 'خمس ليالٍ هادئة من سبع', 5, 7, 29);

  j := public.compose_journey_step(p);
  perform pg_temp.chk('gate: in a journey but can_send false with no outcome',
    (j->>'in_journey')::boolean = true and (j->>'can_send')::boolean = false
    and j->>'reason' = 'no_outcome_yet', j::text);
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
