\set ON_ERROR_STOP on
begin;

-- ============================================================
-- ONE FAMILY, FROM STRANGER TO FINISHED JOURNEY.
--
-- Nobody is being messaged in production, on purpose: ADAM is
-- stopped until the build is finished. But every engine in this
-- product is a TIME AND EVIDENCE machine — three attempts, two
-- calm nights, fifteen outcomes — so with no traffic none of
-- them will ever accumulate the data that makes them run, and
-- none of these paths can be watched working.
--
-- This file is the answer to that. It walks one synthetic family
-- through the whole lifecycle in seconds, and every row it
-- creates is written by the SAME production function the live
-- product would call:
--
--     commit_child_name  →  commit_situation  →  record_seed_sent
--     →  record_harvest_answer  →  start_stage  →  close_stage
--
-- Nothing here inserts a `daily_logs` row by hand. That matters:
-- a harness that invents its own rows tests the harness. The one
-- place history has to be aged (record_harvest_answer only ever
-- writes today) is done by moving the DATE of a row the real
-- function produced, never by fabricating its contents — and
-- there is an assertion below that pins the aged shape to the
-- live one.
--
-- What it watches, in order:
--   · knowledge_depth 0 → 1 → 2 → 3 → 4, each for its own reason
--   · can_send flipping for seed, harvest and mirror
--   · offer_ready becoming true on the exact night it is earned
--   · strain withdrawing the offer, and returning it
--   · a journey started, missed, extended, and reached
-- ============================================================

create table pg_temp.r (n int generated always as identity, name text, result text, detail text);
create or replace function pg_temp.chk(p_name text, p_cond boolean, p_detail text default null)
returns void language sql as $$
  insert into pg_temp.r (name, result, detail)
  values (p_name, case when p_cond then 'PASS' else 'FAIL' end, p_detail);
$$;

create or replace function pg_temp.lvl(p uuid) returns int language sql as $$
  select (public.knowledge_depth(p)->>'level')::int;
$$;
create or replace function pg_temp.sends(p uuid, k text) returns boolean language sql as $$
  select (public.can_send(k, p)->>'can_send')::boolean;
$$;

-- One lived day, produced entirely by the product's own writers, then aged.
--
-- record_seed_sent() takes the local date, so the morning half can be written
-- for any day. record_harvest_answer() computes «today» itself and refuses a
-- day with no seed — so the evening half is always recorded for today and the
-- finished row is then dated backwards. The row's CONTENT is never touched.
create or replace function pg_temp.lived_day(
  p_parent uuid, p_child uuid, p_situation uuid, p_outcome text, p_age int)
returns void language plpgsql as $$
declare v_today date; v_day uuid;
begin
  select coalesce((now() at time zone ct.iana_tz)::date, current_date) into v_today
  from public.followers f
  left join public.country_timezone ct on ct.code = upper(btrim(f.country))
  where f.id = p_parent;

  -- The real order is seed sent → harvest sent → harvest answered. The first
  -- draft of this helper skipped the middle step, and can_send('harvest') then
  -- said an evening question was still owed on a day already answered — which
  -- is exactly the kind of thing this file exists to catch.
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


\echo '=== A STRANGER ==='
do $$
declare p uuid;
begin
  insert into public.country_timezone (code, iana_tz) values ('DZ','Africa/Algiers')
  on conflict (code) do nothing;
  insert into public.followers (platform_user_id, country)
  values ('sim-'||gen_random_uuid()::text, 'DZ') returning id into p;
  insert into pg_temp.r (name, result, detail) values ('__parent__','PASS', p::text);

  perform pg_temp.chk('ADAM knows nothing, and the level says so',
    pg_temp.lvl(p) = 0, public.knowledge_depth(p)::text);
  perform pg_temp.chk('so he may not aim a step at anyone',
    not pg_temp.sends(p, 'seed'), public.can_send('seed', p)::text);
  perform pg_temp.chk('nor show a mirror of a house he has not seen',
    not pg_temp.sends(p, 'mirror'));
  perform pg_temp.chk('and there is nothing to sell yet',
    not (public.offer_ready(p)->>'ready')::boolean,
    public.offer_ready(p)->>'missing');
  perform pg_temp.chk('but he may always answer the moment in front of him',
    pg_temp.sends(p, 'rescue'));
end $$;


\echo '=== A NAME, THEN A SITUATION ==='
do $$
declare p uuid; c uuid; s jsonb;
begin
  select detail::uuid into p from pg_temp.r where name = '__parent__';

  perform public.commit_child_name(p, 'يوسف', null, 'high');
  select id into c from public.children where follower_id = p;
  perform pg_temp.chk('a name alone lifts him to level one',
    pg_temp.lvl(p) = 1 and public.knowledge_depth(p)->>'child_name' = 'يوسف');

  -- Three independent observations is what confirms a situation. Not one.
  s := public.commit_situation(p, c, 'sleep');
  perform pg_temp.chk('one observation is a candidate, not a confirmation',
    s->>'status' = 'candidate', s::text);
  perform pg_temp.chk('and a candidate is already enough to aim at',
    pg_temp.lvl(p) = 2, public.knowledge_depth(p)::text);

  perform public.commit_situation(p, c, 'sleep');
  s := public.commit_situation(p, c, 'sleep');
  perform pg_temp.chk('the third observation confirms it',
    s->>'status' = 'confirmed' and (s->>'evidence_count')::int = 3, s::text);

  perform pg_temp.chk('an invented situation is refused, whatever the model says',
    not (public.commit_situation(p, c, 'homework')->>'committed')::boolean);

  perform pg_temp.chk('now a step can be grounded and sent',
    pg_temp.sends(p, 'seed'), public.can_send('seed', p)::text);
end $$;


\echo '=== THREE NIGHTS, LIVED BY THE REAL WRITERS ==='
do $$
declare p uuid; c uuid; sid uuid; d record; today date;
begin
  select detail::uuid into p from pg_temp.r where name = '__parent__';
  select id into c from public.children where follower_id = p;
  select id into sid from public.situations where child_id = c;

  perform pg_temp.lived_day(p, c, sid, 'tried_failed', 45);
  perform pg_temp.lived_day(p, c, sid, 'succeeded',    44);
  perform pg_temp.chk('two nights is not yet enough for a mirror',
    not pg_temp.sends(p, 'mirror'), public.can_send('mirror', p)::text);

  perform pg_temp.lived_day(p, c, sid, 'succeeded', 43);
  perform pg_temp.chk('the third result raises him to level three',
    pg_temp.lvl(p) = 3, public.knowledge_depth(p)::text);
  perform pg_temp.chk('and the mirror becomes sendable on exactly that night',
    pg_temp.sends(p, 'mirror'), public.can_send('mirror', p)::text);

  -- The aged rows must be indistinguishable from a live one. If the harness
  -- ever starts writing its own shape, this is where it shows.
  perform pg_temp.lived_day(p, c, sid, 'succeeded', 0);
  select coalesce((now() at time zone 'Africa/Algiers')::date, current_date) into today;
  select * into d from public.daily_logs where follower_id = p and log_date = today;
  perform pg_temp.chk('a lived day carries its seed, its grounding and its answer',
    d.seed_sent_at is not null and d.seed_grounded_on is not null
    and d.harvest_answered_at is not null and d.night_result = 'calm'
    and d.step_status = 'done' and d.source = 'rhythm',
    d.night_result || '/' || d.step_status);
  perform pg_temp.chk('and the aged nights have the identical shape',
    (select bool_and(seed_sent_at is not null and harvest_answered_at is not null
                     and night_result is not null and source = 'rhythm')
     from public.daily_logs where follower_id = p));

  perform pg_temp.chk('a harvest cannot be asked twice in one day',
    not pg_temp.sends(p, 'harvest'), public.can_send('harvest', p)::text);

  -- Today is now spent, so age it too and leave the calendar free for the
  -- journey. Only the DATE moves; the row the real writers produced is intact.
  update public.daily_logs set log_date = today - 42
  where follower_id = p and log_date = today;
end $$;


\echo '=== THE OFFER IS EARNED, NOT SCHEDULED ==='
do $$
declare p uuid; c uuid; sid uuid; o jsonb; e jsonb;
begin
  select detail::uuid into p from pg_temp.r where name = '__parent__';
  select id into c from public.children where follower_id = p;
  select id into sid from public.situations where child_id = c;

  e := public.parent_effort(p);
  o := public.offer_ready(p);
  perform pg_temp.chk('four attempts and three calm nights: the offer is earned',
    (o->>'ready')::boolean, o::text);
  perform pg_temp.chk('and it names the child and the situation it grew from',
    o->>'child' = 'يوسف' and (o->>'fork_ar') like '%يوسف%', o->>'fork_ar');
  perform pg_temp.chk('the fork asks, it does not sell — no price, no product name',
    (o->>'fork_ar') !~ '[0-9]' and (o->>'fork_ar') not like '%مرافقة%',
    o->>'fork_ar');

  -- P1: a parent in strain is never sold to, however well they qualify.
  perform public.set_strain_level(p, 2::smallint, 'simulated');
  o := public.offer_ready(p);
  perform pg_temp.chk('strain withdraws the offer even when it was earned',
    not (o->>'ready')::boolean
    and (o->'missing')::text like '%commerce_blocked%', o::text);
  perform pg_temp.chk('and the free relationship is untouched by that',
    pg_temp.sends(p, 'rescue') and pg_temp.lvl(p) = 3);

  -- Coming back down is not immediate: L2 holds for three days before it may
  -- step to L1. A parent is not declared recovered the moment they write one
  -- calm sentence.
  perform pg_temp.chk('recovery is held until the window has actually elapsed',
    public.set_strain_level(p, 1::smallint, 'too soon')->>'action' = 'held');
  perform pg_temp.chk('and the offer stays withdrawn while it is held',
    not (public.offer_ready(p)->>'ready')::boolean);

  update public.parent_strain set return_eligible_at = now() - interval '1 day'
  where parent_id = p;
  -- Two statements, not one. set_strain_level is VOLATILE and offer_ready is
  -- STABLE, so calling both inside a single expression makes offer_ready read
  -- the snapshot from BEFORE the step-down and report the offer still
  -- withdrawn. Fourth time this trap has cost real debugging; see
  -- tests/README.md.
  declare v_step jsonb;
  begin
    v_step := public.set_strain_level(p, 1::smallint, 'recovered');
    perform pg_temp.chk('once it has, they step down and the offer returns',
      v_step->>'action' = 'stepped_down' and (public.offer_ready(p)->>'ready')::boolean,
      v_step::text || ' | ' || public.offer_ready(p)::text);
  end;
end $$;


\echo '=== THE JOURNEY THEY BOUGHT ==='
do $$
declare p uuid; c uuid; sid uuid; j jsonb; st jsonb; sg jsonb; stage uuid;
begin
  select detail::uuid into p from pg_temp.r where name = '__parent__';
  select id into c from public.children where follower_id = p;
  select id into sid from public.situations where child_id = c;

  sg := public.suggest_objective(p);
  perform pg_temp.chk('the goal to agree is built from what we already confirmed',
    (sg->>'ready')::boolean and sg->>'problem_key' = 'sleep'
    and (sg->>'objective_text') like '%يوسف%', sg::text);

  perform pg_temp.chk('and no step can be sent for a journey nobody started',
    not pg_temp.sends(p, 'journey_step'),
    public.can_send('journey_step', p)->>'reason');

  j := public.start_stage(p, sg->>'problem_key', sg->>'objective_text',
                          (sg->>'objective_target')::int,
                          (sg->>'objective_window')::int,
                          (sg->>'planned_logged_days')::int);
  stage := (j->>'stage_id')::uuid;
  -- Age the start too. The clock counts days on or after started_at, so the
  -- free-tier nights before the sale must NOT count towards a journey that had
  -- not begun — the harness has to move the start, not borrow those nights.
  update public.stages set started_at = now() - interval '41 days' where id = stage;
  perform pg_temp.chk('the journey begins on the goal they agreed',
    (j->>'started')::boolean and j->>'objective_text' = sg->>'objective_text');
  perform pg_temp.chk('and now a daily step has somewhere to belong',
    pg_temp.sends(p, 'journey_step'), public.can_send('journey_step', p)::text);

  -- Live the journey. The four nights already walked count towards the clock,
  -- so this takes it to the end of the agreed 29.
  -- The journey's own 29 days. The four free-tier nights sit before started_at
  -- and are deliberately not counted.
  for i in 0..28 loop
    perform pg_temp.lived_day(p, c, sid, 'tried_failed', 41 - i);
  end loop;

  st := public.stage_state(p);
  perform pg_temp.chk('fifteen outcomes recorded lifts him to level four',
    pg_temp.lvl(p) = 4, public.knowledge_depth(p)::text);
  perform pg_temp.chk('the clock is measured in days they showed up for',
    (st->>'logged_days')::int = (st->>'allowed_days')::int
    and (st->>'clock_exhausted')::boolean, st::text);

  perform pg_temp.chk('missing it grants the extension, unrequested',
    public.close_stage(stage)->>'outcome' = 'extended');

  -- And then a genuinely calm week.
  for i in 0..6 loop
    perform pg_temp.lived_day(p, c, sid, 'succeeded', 6 - i);
  end loop;

  st := public.stage_state(p);
  perform pg_temp.chk('a full calm window meets the goal they chose',
    (st->>'objective_met')::boolean, st::text);
  perform pg_temp.chk('and the journey completes',
    public.close_stage(stage)->>'outcome' = 'completed');
  perform pg_temp.chk('leaving them free, and known — level four, no live journey',
    pg_temp.lvl(p) = 4 and not (public.stage_state(p)->>'in_stage')::boolean);
end $$;


\echo '=== RESULTS ==='
\pset format unaligned
select lpad(n::text,2) || '  ' || rpad(result,6) || rpad(name, 64)
    || coalesce('  -> ' || left(replace(detail, chr(10), ' / '), 50), '')
from pg_temp.r where name <> '__parent__' order by n;
select E'\n' || count(*) filter (where result='PASS') || ' / ' || count(*) || ' passed'
from pg_temp.r where name <> '__parent__';

rollback;
