\set ON_ERROR_STOP on
begin;

-- ============================================================
-- THE JOURNEY, WALKED.
--
-- Until this migration the entire journey engine was a schema, a
-- gate and a view — and nothing had ever written a row, so none
-- of it had ever run. These cases walk two families through a
-- whole journey day by day: one that misses and is extended and
-- misses again, one that reaches it.
--
-- The 29-day walk is also the first piece of the simulation
-- harness. With nobody being messaged, walking a synthetic family
-- through time is the only way any of this can be seen working.
-- ============================================================

create table pg_temp.r (n int generated always as identity, name text, result text, detail text);
create or replace function pg_temp.chk(p_name text, p_cond boolean, p_detail text default null)
returns void language sql as $$
  insert into pg_temp.r (name, result, detail)
  values (p_name, case when p_cond then 'PASS' else 'FAIL' end, p_detail);
$$;

-- A family ADAM already knows: a named child and a confirmed situation.
-- Without both, suggest_objective refuses — and that refusal is itself a case.
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
select c, ch.follower_id, 'sleep', sc.label_ar, 'confirmed', 4, sc.window_start, sc.window_end
  from public.children ch, public.situation_catalog sc
 where ch.id = c and sc.key = 'sleep';
  end if;
  return v;
end $$;

-- Time, walked. Each night is a distinct log_date because daily_logs is
-- unique on (follower_id, log_date) — the same constraint that makes the
-- clock count days rather than messages.
create or replace function pg_temp.walk(p_parent uuid, p_nights int, p_result text)
returns void language plpgsql as $$
declare v_from date;
begin
  select coalesce(max(log_date) + 1, current_date) into v_from
  from public.daily_logs where follower_id = p_parent;

  insert into public.daily_logs (follower_id, log_date, night_result, step_given)
  select p_parent, v_from + g, p_result, 'خطوة'
  from generate_series(0, p_nights - 1) g;
end $$;

create or replace function pg_temp.live_stage(p uuid) returns uuid language sql as $$
  select id from public.stages
  where parent_id = p and status in ('active','extended','paused') limit 1;
$$;


\echo '=== THE GOAL IS GROUNDED, OR THERE IS NO GOAL ==='
do $$
declare p uuid; s jsonb;
begin
  -- No child at all.
  insert into public.followers (platform_user_id, country)
  values (gen_random_uuid()::text, 'DZ') returning id into p;
  s := public.suggest_objective(p);
  perform pg_temp.chk('with no child known, no objective is invented',
    not (s->>'ready')::boolean and s->>'reason' = 'no_child', s::text);

  -- A child, but nothing confirmed about them yet.
  p := pg_temp.family('يوسف', false);
  s := public.suggest_objective(p);
  perform pg_temp.chk('a name alone is not enough to name a goal',
    not (s->>'ready')::boolean and s->>'reason' = 'no_confirmed_situation', s::text);

  -- A confirmed situation. Now there is something to agree on.
  p := pg_temp.family('يوسف');
  s := public.suggest_objective(p);
  perform pg_temp.chk('a confirmed situation produces a goal to agree',
    (s->>'ready')::boolean, s::text);
  perform pg_temp.chk('and it is written as a result they can see, not a metric',
    (s->>'objective_text') like '%خمس ليالٍ هادئة من سبع%'
    and (s->>'objective_text') like '%يوسف%', s->>'objective_text');
  perform pg_temp.chk('grounded in the situation ADAM actually confirmed',
    s->>'problem_key' = 'sleep', s::text);
  perform pg_temp.chk('and the clock it suggests is the one the offer promises',
    (s->>'planned_logged_days')::int = 29
    and (s->>'objective_target')::int = 5
    and (s->>'objective_window')::int = 7, s::text);
end $$;


\echo '=== A JOURNEY STARTS ONCE, AND ONLY WITH A GOAL ==='
do $$
declare p uuid; j jsonb;
begin
  p := pg_temp.family('سلمى');

  j := public.start_stage(p, 'sleep', null);
  perform pg_temp.chk('a journey cannot start without an agreed objective',
    not (j->>'started')::boolean and j->>'reason' = 'objective_required', j::text);

  j := public.start_stage(p, 'sleep', 'خمس ليالٍ هادئة من سبع', 9, 7);
  perform pg_temp.chk('a target that cannot fit its window is refused',
    not (j->>'started')::boolean and j->>'reason' = 'target_exceeds_window', j::text);

  j := public.start_stage(p, 'sleep', 'خمس ليالٍ هادئة من سبع', 5, 7, 90);
  perform pg_temp.chk('and a clock outside 7..60 logged days is refused',
    not (j->>'started')::boolean and j->>'reason' = 'clock_out_of_range', j::text);

  j := public.start_stage(p, 'sleep', 'خمس ليالٍ هادئة من سبع مع سلمى');
  perform pg_temp.chk('with a goal agreed, the journey begins',
    (j->>'started')::boolean and (j->>'in_stage')::boolean, j::text);
  perform pg_temp.chk('and the child is attached without being named twice',
    (select child_id from public.stages where id = (j->>'stage_id')::uuid) is not null);

  j := public.start_stage(p, 'anger', 'نوبات غضب أقلّ');
  perform pg_temp.chk('a second live journey is refused — attention is the scarce thing',
    not (j->>'started')::boolean and j->>'reason' = 'stage_already_live', j::text);

  j := public.start_stage(gen_random_uuid(), 'sleep', 'هدف');
  perform pg_temp.chk('and a parent who does not exist starts nothing',
    not (j->>'started')::boolean and j->>'reason' = 'no_such_parent', j::text);
end $$;


\echo '=== THE PHASES ARE DERIVED, AND HOLD IS THE POINT ==='
do $$
declare p uuid; s jsonb;
begin
  p := pg_temp.family('مالك');
  perform public.start_stage(p, 'sleep', 'خمس ليالٍ هادئة من سبع مع مالك');

  s := public.stage_state(p);
  perform pg_temp.chk('day zero: we are watching, not changing',
    s->>'phase' = 'observe', s::text);

  perform pg_temp.walk(p, 5, 'hard');
  s := public.stage_state(p);
  perform pg_temp.chk('after a few nights logged, we are building',
    s->>'phase' = 'build' and (s->>'logged_days')::int = 5, s::text);

  -- allowed = 29, so hold begins at 29 - greatest(3, 9) = 20 logged days.
  perform pg_temp.walk(p, 15, 'hard');
  s := public.stage_state(p);
  perform pg_temp.chk('and near the end ADAM withdraws on purpose',
    s->>'phase' = 'hold' and (s->>'logged_days')::int = 20, s::text);
  perform pg_temp.chk('the hold phase says why, in words a parent can read',
    (s->>'phase_ar') like '%أتراجع عمداً%', s->>'phase_ar');

  perform pg_temp.chk('a parent not in a journey is simply not in one',
    not (public.stage_state(pg_temp.family('نور'))->>'in_stage')::boolean);
end $$;


\echo '=== MISSED, EXTENDED WITHOUT ASKING, THEN FAILED ==='
do $$
declare p uuid; sid uuid; c jsonb; s jsonb;
begin
  p := pg_temp.family('آدم');
  perform public.start_stage(p, 'sleep', 'خمس ليالٍ هادئة من سبع');
  sid := pg_temp.live_stage(p);

  perform pg_temp.walk(p, 10, 'hard');
  c := public.close_stage(sid);
  perform pg_temp.chk('a journey with time left is not closed',
    not (c->>'closed')::boolean and c->>'outcome' = 'running', c::text);

  -- 29 logged days, none of them calm.
  perform pg_temp.walk(p, 19, 'hard');
  s := public.stage_state(p);
  perform pg_temp.chk('the clock runs out on logged days, not calendar days',
    (s->>'clock_exhausted')::boolean and (s->>'logged_days')::int = 29, s::text);

  c := public.close_stage(sid);
  perform pg_temp.chk('missing it grants the extension — half the length, in the same call',
    c->>'outcome' = 'extended' and (c->>'extension_days')::int = 14, c::text);
  perform pg_temp.chk('and nobody had to ask for it',
    (select extension_granted_at is not null and status = 'extended'
     from public.stages where id = sid));

  s := public.stage_state(p);
  perform pg_temp.chk('the journey is live again, with more days on the clock',
    (s->>'in_stage')::boolean and (s->>'allowed_days')::int = 43
    and (s->>'extended')::boolean, s::text);

  -- Miss it again.
  perform pg_temp.walk(p, 14, 'hard');
  c := public.close_stage(sid);
  perform pg_temp.chk('a second miss ends it honestly rather than extending forever',
    (c->>'closed')::boolean and c->>'outcome' = 'failed', c::text);
  perform pg_temp.chk('and the parent is free to start another one',
    not (public.stage_state(p)->>'in_stage')::boolean);

  c := public.close_stage(sid);
  perform pg_temp.chk('closing a closed journey changes nothing',
    not (c->>'closed')::boolean and c->>'reason' = 'not_live', c::text);
end $$;


\echo '=== OR REACHED — AND A FULL WINDOW IS REQUIRED TO SAY SO ==='
do $$
declare p uuid; sid uuid; c jsonb; s jsonb;
begin
  p := pg_temp.family('ليان');
  perform public.start_stage(p, 'sleep', 'خمس ليالٍ هادئة من سبع مع ليان');
  sid := pg_temp.live_stage(p);

  -- Three calm nights is not five of seven, however good they feel.
  perform pg_temp.walk(p, 3, 'calm');
  s := public.stage_state(p);
  perform pg_temp.chk('three calm nights cannot be called five out of seven',
    not (s->>'objective_met')::boolean and (s->>'window_filled')::int = 3, s::text);
  c := public.close_stage(sid);
  perform pg_temp.chk('so the journey is not closed early on a good week',
    c->>'outcome' = 'running', c::text);

  -- A hard stretch, then a genuinely calm week.
  perform pg_temp.walk(p, 6, 'hard');
  perform pg_temp.walk(p, 7, 'calm');
  s := public.stage_state(p);
  perform pg_temp.chk('a full window of calm nights meets the objective',
    (s->>'objective_met')::boolean
    and (s->>'objective_current')::int >= (s->>'objective_target')::int, s::text);

  c := public.close_stage(sid);
  perform pg_temp.chk('and reaching it ends the journey, before the clock does',
    (c->>'closed')::boolean and c->>'outcome' = 'completed', c::text);
  perform pg_temp.chk('completed, not expired — the difference the guarantee rests on',
    (select status = 'completed' and completed_at is not null
     from public.stages where id = sid));
end $$;


\echo '=== A PAYMENT NOW BUYS A JOURNEY, NOT A CLOCK ==='
do $$
declare p uuid; a jsonb;
begin
  insert into public.supported_countries (code, name_ar, currency, price_subscription, is_active)
  values ('DZ','الجزائر','DZD', 2300, true)
  on conflict (code) do update set price_subscription = 2300, is_active = true;

  p := pg_temp.family('ريان');
  a := public.activate_subscription(p, 30, null, null, null,
                                    'sleep', 'خمس ليالٍ هادئة من سبع مع ريان');
  perform pg_temp.chk('paying starts the agreed journey',
    (a->'journey'->>'started')::boolean, a::text);
  perform pg_temp.chk('and the money is still recorded exactly as before',
    (a->>'payment_id') is not null and a->>'funnel_stage' = 'paid_active', a::text);
  perform pg_temp.chk('the parent is measurably inside something now',
    (public.stage_state(p)->>'in_stage')::boolean);

  -- The half-state this whole migration exists to remove: paid, no journey.
  p := pg_temp.family('تيم');
  a := public.activate_subscription(p, 30);
  perform pg_temp.chk('paying with no agreed goal records the money',
    (a->>'payment_id') is not null, a::text);
  perform pg_temp.chk('but says so out loud instead of leaving a paid parent adrift',
    not (a->'journey'->>'started')::boolean
    and a->'journey'->>'reason' = 'objective_required', a::text);
end $$;


\echo '=== RESULTS ==='
\pset format unaligned
select lpad(n::text,2) || '  ' || rpad(result,6) || rpad(name, 66)
    || coalesce('  -> ' || left(replace(detail, chr(10), ' / '), 50), '')
from pg_temp.r order by n;
select E'\n' || count(*) filter (where result='PASS') || ' / ' || count(*) || ' passed'
from pg_temp.r;

rollback;
