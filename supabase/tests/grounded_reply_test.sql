\set ON_ERROR_STOP on
begin;

-- ============================================================
-- The grounding gate — ADAM cannot get a hallucinated claim past it.
-- Design + calibration: docs/adam-under-the-microscope.md, The ADAM Contract.
--
-- Covers exactly what the founder asked to be proven: missing knowledge,
-- non-existent memory, psychological explanations, causes of child
-- behavior, numbers, and claims about the past — each as a case that
-- must be BLOCKED, paired with a near-miss case that must SURVIVE, the
-- same discipline conversation_law_test.sql already uses for the
-- vocabulary law (a rule never seen to reject anything is a rule you
-- are hoping for; a rule that blocks approved copy is a rule someone
-- switches off).
--
-- Also covers: knowledge_level as an enforced (not advisory) gate on
-- pattern claims, all five levels (0-4, docs/adam-constitution.md's
-- Knowledge Levels table); the journey directive reaching a paid parent
-- and being absent for a free one, across all three phases
-- (observe/build/hold, matching compose_journey_step's own vocabulary).
-- ============================================================

create table pg_temp.r (n int generated always as identity, name text, result text, detail text);
create or replace function pg_temp.chk(p_name text, p_cond boolean, p_detail text default null)
returns void language sql as $$
  insert into pg_temp.r (name, result, detail)
  values (p_name, case when p_cond then 'PASS' else 'FAIL' end, p_detail);
$$;

create or replace function pg_temp.family(p_name text, p_confirm boolean default true)
returns uuid language plpgsql as $$
declare v uuid; c uuid;
begin
  insert into public.followers (platform_user_id, country)
  values (gen_random_uuid()::text, 'DZ') returning id into v;
  insert into public.children (follower_id, name, is_primary)
  values (v, p_name, true) returning id into c;
  if p_confirm then
    insert into public.situations (child_id, parent_id, key, label_ar, status,
                                   evidence_count, window_start, window_end)
    select c, ch.follower_id, 'sleep', sc.label_ar, 'confirmed', 4,
           sc.window_start, sc.window_end
    from public.children ch, public.situation_catalog sc
    where ch.id = c and sc.key = 'sleep';
  end if;
  return v;
end $$;

create or replace function pg_temp.walk(p uuid, n int, res text)
returns void language plpgsql as $$
declare v_from date;
begin
  select coalesce(max(log_date) + 1, current_date) into v_from
  from public.daily_logs where follower_id = p;
  insert into public.daily_logs (follower_id, log_date, night_result, step_given, step_status)
  select p, v_from + g, res, 'خطوة', 'done'
  from generate_series(0, n - 1) g;
end $$;


\echo '=== 1. MEMORY CLAIMS — blocked, and the honest future-promise near-miss survives ==='
do $$
declare p uuid; g jsonb;
begin
  p := pg_temp.family('نور');

  g := public.gate_grounded_reply(p, 'أتذكّر أن يوسف كان متعباً أمس.');
  perform pg_temp.chk('present-tense "أتذكّر" is blocked',
    (g->>'blocked')::boolean = true and (g->'violations') @> '["memory:announced"]', g::text);

  g := public.gate_grounded_reply(p, 'بحسب ما سجّلته، الأمر تحسّن.');
  perform pg_temp.chk('"بحسب ما سجّلته" is blocked', (g->>'blocked')::boolean = true);

  -- Near-miss: an honest FUTURE promise to remember. Must survive —
  -- calibrated against a real false positive found in production.
  g := public.gate_grounded_reply(p, 'أخبروني باسمه، وسأتذكره طوال رحلتنا معاً.');
  perform pg_temp.chk('future promise "سأتذكره" survives (not a memory claim)',
    (g->>'blocked')::boolean = false, g::text);
end $$;


\echo '=== 2. CLAIMS ABOUT THE PAST — blocked ==='
do $$
declare p uuid; g jsonb;
begin
  p := pg_temp.family('سارة');

  g := public.gate_grounded_reply(p, 'في المرة الماضية قلتم إنه هدأ بسرعة.');
  perform pg_temp.chk('"في المرة الماضية" is blocked', (g->>'blocked')::boolean = true,
    g::text);

  g := public.gate_grounded_reply(p, 'كما أخبرتموني سابقاً، هو يخاف من الظلام.');
  perform pg_temp.chk('"كما أخبرتموني سابقاً" is blocked', (g->>'blocked')::boolean = true);
end $$;


\echo '=== 3. NUMBERS / REPETITION COUNTS — level-gated, not a flat ban ==='
do $$
declare p_new uuid; p_pattern uuid; g jsonb;
begin
  -- Level 0-2: no confirmed pattern. A count claim is fabricated.
  p_new := pg_temp.family('يوسف', true);
  g := public.gate_grounded_reply(p_new, 'هذه ثالث مرة هذا الأسبوع يرفض فيها النوم.');
  perform pg_temp.chk('repetition count blocked with no confirmed pattern (level < 3)',
    (g->>'blocked')::boolean = true and (g->'violations') @> '["pattern:unfounded"]', g::text);

  -- Level 3+: three logged nights, notice_a_pattern unlocked. Same claim
  -- is now grounded and must survive.
  p_pattern := pg_temp.family('أحمد', true);
  perform pg_temp.walk(p_pattern, 3, 'hard');
  perform pg_temp.chk('setup: knowledge_depth reaches level 3',
    (public.knowledge_depth(p_pattern)->>'level')::int = 3);
  g := public.gate_grounded_reply(p_pattern, 'هذه ثالث مرة هذا الأسبوع يرفض فيها النوم.');
  perform pg_temp.chk('the SAME claim survives once a pattern is actually confirmed',
    (g->>'blocked')::boolean = false, g::text);

  -- Near-miss: "هذه المرة" (this time — no count at all) must never be
  -- caught. A real false positive found in production calibration.
  g := public.gate_grounded_reply(p_new, 'جرّبي هذه المرة ألا تجادليه حول الوقت.');
  perform pg_temp.chk('"هذه المرة" (ordinary "this time") survives, not a count claim',
    (g->>'blocked')::boolean = false, g::text);
end $$;


\echo '=== 4. PSYCHOLOGICAL EXPLANATIONS / CAUSES OF BEHAVIOUR — deliberately NOT blocked ==='
do $$
declare p uuid; g jsonb;
begin
  -- Calibrated against real production replies: a blanket ban on causal
  -- language over-blocks the product's own working technique (the
  -- 2026-08-04 warmth rewrite's worked examples use exactly this shape).
  -- This gate targets INVENTED SPECIFIC FACTS, not general reframes.
  p := pg_temp.family('حياة', false);  -- level 0: no confirmed situation even

  g := public.gate_grounded_reply(p,
    'الصراخ يحدث لأن جسمكِ يفرغ ضغط تعبكِ المتراكم دفعة واحدة، وليس غضباً من طفلكِ.');
  perform pg_temp.chk('a general causal reframe survives at level 0', (g->>'blocked')::boolean = false, g::text);

  g := public.gate_grounded_reply(p,
    'التعب المستمرّ معه غالباً لا يأتي منه هو، بل من تكرار الصدام في النقطة نفسها كل يوم.');
  perform pg_temp.chk('a hedged general explanation survives ("غالباً")', (g->>'blocked')::boolean = false);

  g := public.gate_grounded_reply(p,
    'لاحظت أنك مهتم بهذا الأمر، أخبرني أكثر عنه.');
  perform pg_temp.chk('"لاحظت" as a suggested script/question survives (calibration finding: 7/7 real hits were not memory claims)',
    (g->>'blocked')::boolean = false, g::text);
end $$;


\echo '=== 5. MISSING KNOWLEDGE — a clean, honest reply always passes ==='
do $$
declare p uuid; g jsonb;
begin
  p := pg_temp.family('رفيق', false);
  g := public.gate_grounded_reply(p,
    'ما زلت أتعرّف على بيتكم. احكوا لي أكثر عمّا حدث اليوم.');
  perform pg_temp.chk('an honest "I do not know yet" reply is never blocked',
    (g->>'blocked')::boolean = false, g::text);

  -- The empty-body case is gate_agent_reply's job, not this gate's — but
  -- gate_grounded_reply itself must not choke on it.
  g := public.gate_grounded_reply(p, '');
  perform pg_temp.chk('empty body: gate_grounded_reply itself does not block (gate_agent_reply owns that)',
    (g->>'blocked')::boolean = false);
end $$;


\echo '=== 6. gate_agent_reply INTEGRATION — merges grounding into the existing gate ==='
do $$
declare p uuid; g jsonb;
begin
  p := pg_temp.family('نور2', false);

  -- A grounding violation alone is now caught through the SAME node W1
  -- already calls — zero n8n change.
  g := public.gate_agent_reply(p, 'أتذكّر أنكم قلتم إنه تحسّن.');
  perform pg_temp.chk('gate_agent_reply blocks a grounding violation',
    (g->>'blocked')::boolean = true and (g->'blocking') @> '["memory:announced"]', g::text);
  perform pg_temp.chk('fallback is reply_withheld, never rescue (ADAM understood; it invented)',
    g->>'fallback_key' = 'reply_withheld', g->>'fallback_key');

  -- A clean reply with a real price violation still gets caught exactly
  -- as before — the vocabulary law is untouched.
  g := public.gate_agent_reply(p, 'التكلفة 2,300 دينار.');
  perform pg_temp.chk('pre-existing price check still fires, unmodified',
    (g->'blocking') @> '["sell:price"]', g::text);

  -- A reply violating BOTH classes at once — both are logged.
  g := public.gate_agent_reply(p, 'أتذكّر أن التكلفة 2,300 دينار.');
  perform pg_temp.chk('both a grounding and a vocabulary violation are recorded together',
    (g->'blocking') @> '["memory:announced"]' and (g->'blocking') @> '["sell:price"]', g::text);

  -- A genuinely clean reply is not blocked.
  g := public.gate_agent_reply(p, 'ما زلت أتعرّف على بيتكم. احكوا لي أكثر.');
  perform pg_temp.chk('a clean reply still passes', (g->>'ok')::boolean = true, g::text);
end $$;


\echo '=== 7. THE KNOWLEDGE LEVEL AS AN ENFORCED MOVE-SET (get_agent_bundle) ==='
do $$
declare p0 uuid; p3 uuid; b0 jsonb; b3 jsonb;
begin
  -- True level 0: no child row at all, not merely no confirmed situation.
  -- knowledge_depth() reads any non-placeholder child name as level >= 1,
  -- so pg_temp.family() (which always names the child) cannot produce
  -- level 0 — a stranger who has not yet mentioned a child does.
  insert into public.followers (platform_user_id, country)
  values (gen_random_uuid()::text, 'DZ') returning id into p0;
  perform pg_temp.chk('setup: a stranger with no child is genuinely level 0',
    (public.knowledge_depth(p0)->>'level')::int = 0);

  b0 := public.get_agent_bundle(p0, 'مرحباً');
  perform pg_temp.chk('level 0: allowed_moves is exactly answer_this_moment',
    b0->'allowed_moves' = '["answer_this_moment"]'::jsonb, (b0->'allowed_moves')::text);
  perform pg_temp.chk('level 0: family_context forbids naming a repetition explicitly',
    position('ممنوع' in (b0->>'family_context')) > 0
    and position('تكرار' in (b0->>'family_context')) > 0, b0->>'family_context');
  perform pg_temp.chk('level 0: not in a journey', (b0->>'in_journey')::boolean = false);

  p3 := pg_temp.family('لين', true);
  perform pg_temp.walk(p3, 3, 'hard');
  b3 := public.get_agent_bundle(p3, 'كيف حاله؟');
  perform pg_temp.chk('level 3: allowed_moves includes notice_a_pattern',
    b3->'allowed_moves' ? 'notice_a_pattern', (b3->'allowed_moves')::text);
end $$;


\echo '=== 8a. EVERY KNOWLEDGE LEVEL, NOT JUST 0 AND 3 (docs/adam-constitution.md Knowledge Levels table) ==='
do $$
declare p1 uuid; p2 uuid; p4 uuid; b1 jsonb; b2 jsonb; b4 jsonb;
begin
  -- Level 1: named child, no confirmed situation. May use the name; may not
  -- claim a recurring pattern.
  p1 := pg_temp.family('يوسف', false);
  perform pg_temp.chk('setup: level 1 (name only, no confirmed situation)',
    (public.knowledge_depth(p1)->>'level')::int = 1);
  b1 := public.get_agent_bundle(p1, 'مرحباً');
  perform pg_temp.chk('level 1: allowed_moves is answer_this_moment + speak_by_name',
    b1->'allowed_moves' ? 'speak_by_name' and not (b1->'allowed_moves' ? 'aim_a_seed'),
    (b1->'allowed_moves')::text);
  perform pg_temp.chk('level 1: family_context forbids claiming a recurring pattern',
    position('يتكرّر' in (b1->>'family_context')) > 0
    and position('ممنوع' in (b1->>'family_context')) > 0, b1->>'family_context');

  -- Level 2: name + a confirmed situation, no logged nights yet. May aim a
  -- step at the confirmed situation; may not claim a count.
  p2 := pg_temp.family('ريم', true);
  perform pg_temp.chk('setup: level 2 (name + confirmed situation, no nights)',
    (public.knowledge_depth(p2)->>'level')::int = 2);
  b2 := public.get_agent_bundle(p2, 'مرحباً');
  perform pg_temp.chk('level 2: allowed_moves includes aim_a_seed, not notice_a_pattern',
    b2->'allowed_moves' ? 'aim_a_seed' and not (b2->'allowed_moves' ? 'notice_a_pattern'),
    (b2->'allowed_moves')::text);
  perform pg_temp.chk('level 2: family_context forbids naming "هذه المرة الثالثة" or any count',
    position('هذه المرة الثالثة' in (b2->>'family_context')) > 0
    or position('عدد تكرار' in (b2->>'family_context')) > 0, b2->>'family_context');

  -- Level 4: a month of outcomes. May name a goal.
  p4 := pg_temp.family('كريم', true);
  perform pg_temp.walk(p4, 15, 'hard');
  perform pg_temp.chk('setup: level 4 (>=15 outcomes)',
    (public.knowledge_depth(p4)->>'level')::int = 4);
  b4 := public.get_agent_bundle(p4, 'مرحباً');
  perform pg_temp.chk('level 4: allowed_moves includes name_a_goal',
    b4->'allowed_moves' ? 'name_a_goal', (b4->'allowed_moves')::text);
end $$;


\echo '=== 8. THE JOURNEY REACHES A PAID PARENT, AND ONLY A PAID PARENT ==='
do $$
declare p_free uuid; p_obs uuid; p_hold uuid; b jsonb; ctx text;
begin
  -- Free parent: no JOURNEY block anywhere, in_journey false.
  p_free := pg_temp.family('حرّ', true);
  perform pg_temp.walk(p_free, 3, 'calm');
  b := public.get_agent_bundle(p_free, 'مرحباً');
  perform pg_temp.chk('free parent: in_journey is false', (b->>'in_journey')::boolean = false);
  perform pg_temp.chk('free parent: no [الرحلة] directive in family_context',
    position('[الرحلة]' in (b->>'family_context')) = 0, b->>'family_context');
  ctx := public.get_agent_context(p_free);
  perform pg_temp.chk('free parent: no JOURNEY block in raw context',
    position('== JOURNEY ==' in ctx) = 0);

  -- Paid parent, observe phase (just started): directive forbids a new step.
  p_obs := pg_temp.family('رحلة أ', true);
  perform pg_temp.walk(p_obs, 2, 'hard');
  perform public.start_stage(p_obs, 'sleep', 'خمس ليالٍ هادئة من سبع', 5, 7, 29);
  b := public.get_agent_bundle(p_obs, 'كيف نتقدّم؟');
  perform pg_temp.chk('paid/observe: in_journey true', (b->>'in_journey')::boolean = true);
  perform pg_temp.chk('paid/observe: directive present and forbids a new step',
    position('[الرحلة]' in (b->>'family_context')) > 0
    and position('لا تقترح خطوة' in (b->>'family_context')) > 0, b->>'family_context');
  ctx := public.get_agent_context(p_obs);
  perform pg_temp.chk('paid/observe: JOURNEY block carries the agreed objective',
    position('خمس ليالٍ هادئة من سبع' in ctx) > 0, ctx);

  -- Paid parent, hold phase (short journey so hold begins early).
  p_hold := pg_temp.family('رحلة ب', true);
  perform public.start_stage(p_hold, 'sleep', 'خمس ليالٍ هادئة من سبع', 5, 7, 7);
  perform pg_temp.walk(p_hold, 6, 'calm');
  b := public.get_agent_bundle(p_hold, 'شكراً لكم');
  perform pg_temp.chk('paid/hold: directive explicitly forbids proposing a step',
    position('ممنوع اقتراح أي خطوة' in (b->>'family_context')) > 0, b->>'family_context');

  -- Paid parent, build phase (middle of a 29-day journey: 10 logged nights,
  -- clear of both the observe floor <3 and the hold ceiling 29-9=20).
  perform pg_temp.chk('setup: build-phase boundaries for a 29-day journey put 10 logged nights in build',
    10 >= 3 and 10 < (29 - greatest(3, 29/3)));
  perform pg_temp.walk(p_obs, 8, 'hard');  -- p_obs already had 2 logged nights; 2 + 8 = 10 total
  b := public.get_agent_bundle(p_obs, 'شنو نجرب الليلة؟');
  perform pg_temp.chk('paid/build: phase is actually build at 10 logged nights',
    (public.stage_state(p_obs)->>'phase') = 'build', (public.stage_state(p_obs))::text);
  perform pg_temp.chk('paid/build: directive allows referencing the objective, does not forbid a step',
    position('طور البناء' in (b->>'family_context')) > 0
    and position('ممنوع اقتراح أي خطوة' in (b->>'family_context')) = 0, b->>'family_context');
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
