\set ON_ERROR_STOP on
begin;

-- ============================================================
-- لحظة الاتفاق — the conversion moment.
--
-- The one hinge between free and paid. These cases assert the
-- founder's ordered flow, and the mechanisms that keep it honest:
--   · the journey door opens onto the AGREEMENT, not a price, but
--     only when the evidence is there and strain is not;
--   · «نعم» writes a reversible receipt (free, no clock, no money)
--     and then — and only then — the offer surface appears;
--   · a parent already agreed, or already in a journey, or drowning,
--     is never shown the agreement.
--
-- Everything runs in a transaction and rolls back.
-- ============================================================

create table pg_temp.r (n int generated always as identity, name text, result text, detail text);
create or replace function pg_temp.chk(p_name text, p_cond boolean, p_detail text default null)
returns void language sql as $$
  insert into pg_temp.r (name, result, detail)
  values (p_name, case when p_cond then 'PASS' else 'FAIL' end, p_detail);
$$;

-- A family ADAM knows: a named child and a confirmed situation — the two
-- things suggest_objective needs before it will name a real goal.
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


\echo '=== 1. THE DOOR ONLY OPENS ONTO THE AGREEMENT WHEN EARNED ==='
do $$
declare p_ready uuid; p_bare uuid; m jsonb;
begin
  p_bare  := pg_temp.family('نور', false);   -- named, no confirmed situation
  p_ready := pg_temp.family('يوسف', true);    -- named + confirmed

  -- Not ready: suggest_objective refuses, so should_agree_first is false and
  -- the journey door shows the ordinary offer, never a guessed goal.
  perform pg_temp.chk('bare parent: suggest_objective not ready',
    coalesce((public.suggest_objective(p_bare)->>'ready')::boolean, false) = false);
  perform pg_temp.chk('bare parent: should_agree_first false',
    public.should_agree_first(p_bare) = false);
  m := public.get_moment_after_tap('menu_journey', p_bare);
  perform pg_temp.chk('bare parent: journey door is the offer, not the agreement',
    m->>'key' = 'menu_journey', m->>'key');

  -- Ready: the door opens onto the agreement.
  perform pg_temp.chk('ready parent: suggest_objective ready',
    (public.suggest_objective(p_ready)->>'ready')::boolean = true);
  perform pg_temp.chk('ready parent: should_agree_first true',
    public.should_agree_first(p_ready) = true);
end $$;


\echo '=== 2. THE AGREEMENT SURFACE — mirror, goal, ownership, no price ==='
do $$
declare p uuid; m jsonb; body text; btns jsonb;
begin
  p := pg_temp.family('يوسف', true);
  m := public.get_moment_after_tap('menu_journey', p);
  body := m->>'body';
  btns := m->'buttons';

  perform pg_temp.chk('door → the agreement moment', m->>'key' = 'menu_agree_goal', m->>'key');

  -- The goal the parent is asked to own is the grounded one.
  perform pg_temp.chk('body carries the falsifiable goal',
    position((public.suggest_objective(p)->>'objective_text') in coalesce(body,'')) > 0, body);

  -- The ownership question and the child's name are both present.
  perform pg_temp.chk('body asks the ownership question',
    position('هل هذا هو ما تريدون أن يتغيّر' in coalesce(body,'')) > 0);
  perform pg_temp.chk('body names the child', position('يوسف' in coalesce(body,'')) > 0);

  -- No price, no currency, no price digits anywhere in the visible copy.
  perform pg_temp.chk('no price digits in the agreement body',
    cardinality(public.copy_violations(coalesce(body,''))) = 0,
    array_to_string(public.copy_violations(coalesce(body,'')), ', '));

  -- The «yes» button and the constitutional escape hatch (F9) are both there.
  perform pg_temp.chk('yes button carries menu_goal_agreed',
    btns @> '[{"cb":"menu_goal_agreed"}]'::jsonb, btns::text);
  perform pg_temp.chk('escape hatch present (cb=other)',
    btns @> '[{"cb":"other"}]'::jsonb, btns::text);
end $$;


\echo '=== 3. «نعم» WRITES A REVERSIBLE RECEIPT, THEN SHOWS THE OFFER ==='
do $$
declare p uuid; m jsonb; v_obj jsonb; v_at timestamptz; np int;
begin
  p := pg_temp.family('سارة', true);

  -- Before: no receipt, no proposal, no journey.
  select agreed_objective into v_obj from public.followers where id = p;
  perform pg_temp.chk('before: no agreed goal', v_obj is null);

  m := public.get_moment_after_tap('menu_goal_agreed', p);

  -- After: the tap reports the agreement and opens the offer surface.
  perform pg_temp.chk('tap reports goal_agreed', m->>'action_done' = 'goal_agreed', m->>'action_done');
  perform pg_temp.chk('tap then shows the offer (menu_journey)',
    m->>'key' = 'menu_journey', m->>'key');

  -- The receipt: the agreed goal on the parent, and its shape.
  select agreed_objective, agreed_at into v_obj, v_at from public.followers where id = p;
  perform pg_temp.chk('receipt: agreed_objective written', v_obj is not null);
  perform pg_temp.chk('receipt: agreed_at stamped', v_at is not null);
  perform pg_temp.chk('receipt: carries the problem_key',
    v_obj->>'problem_key' = 'sleep', v_obj->>'problem_key');
  perform pg_temp.chk('receipt: carries a target inside its window',
    (v_obj->>'objective_target')::int <= (v_obj->>'objective_window')::int);

  -- A pending proposal exists for start_stage's accounting.
  select count(*) into np from public.stage_proposals
  where parent_id = p and problem_key = 'sleep' and outcome = 'pending';
  perform pg_temp.chk('receipt: one pending proposal', np = 1, np::text);

  -- No money moved, no clock started.
  perform pg_temp.chk('agreement takes no money',
    not exists (select 1 from public.payments where follower_id = p));
  perform pg_temp.chk('agreement starts no journey',
    not exists (select 1 from public.stages where parent_id = p));
end $$;


\echo '=== 4. ONCE AGREED, THE DOOR SHOWS THE OFFER — AND «نعم» IS IDEMPOTENT ==='
do $$
declare p uuid; np int;
begin
  p := pg_temp.family('لين', true);

  perform public.agree_objective(p);
  perform pg_temp.chk('after agreeing: should_agree_first false',
    public.should_agree_first(p) = false);
  perform pg_temp.chk('after agreeing: door is the offer',
    public.get_moment_after_tap('menu_journey', p)->>'key' = 'menu_journey');

  -- A second «نعم» refreshes the same receipt, never a duplicate proposal.
  perform public.agree_objective(p);
  select count(*) into np from public.stage_proposals
  where parent_id = p and problem_key = 'sleep' and outcome = 'pending';
  perform pg_temp.chk('idempotent: still one pending proposal', np = 1, np::text);
end $$;


\echo '=== 5. STRAIN WITHDRAWS THE WHOLE MOMENT, SILENTLY ==='
do $$
declare p uuid; a jsonb; m jsonb;
begin
  p := pg_temp.family('آدم', true);
  perform public.set_strain_level(p, 2::smallint, 'simulated');

  perform pg_temp.chk('at strain: should_agree_first false',
    public.should_agree_first(p) = false);

  a := public.agree_objective(p);
  perform pg_temp.chk('at strain: agree_objective refuses',
    (a->>'agreed')::boolean = false and a->>'reason' = 'commerce_blocked', a::text);

  -- The door does not show the agreement; menu_journey handles strain itself.
  m := public.get_moment_after_tap('menu_journey', p);
  perform pg_temp.chk('at strain: door is not the agreement',
    coalesce(m->>'key','') <> 'menu_agree_goal', m->>'key');
end $$;


\echo '=== 6. ALREADY IN A JOURNEY — NOTHING TO AGREE ==='
do $$
declare p uuid; a jsonb;
begin
  p := pg_temp.family('حياة', true);
  perform public.start_stage(p, 'sleep', 'خمس ليالٍ هادئة من سبع', 5, 7, 29);

  perform pg_temp.chk('in journey: should_agree_first false',
    public.should_agree_first(p) = false);
  a := public.agree_objective(p);
  perform pg_temp.chk('in journey: agree_objective refuses',
    (a->>'agreed')::boolean = false and a->>'reason' = 'already_in_journey', a::text);
end $$;


\echo '=== 7. compose_agreement_moment NEVER FAKES A GOAL ==='
do $$
declare p uuid; m jsonb;
begin
  p := pg_temp.family('رفيق', false);   -- not ready
  m := public.compose_agreement_moment(p);
  perform pg_temp.chk('not ready: falls back to the offer, invents nothing',
    m->>'key' = 'menu_journey', m->>'key');
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
