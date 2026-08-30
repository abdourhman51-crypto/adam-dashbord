\set ON_ERROR_STOP on
begin;

-- ============================================================
-- ما بعد الوصول.
--
-- The design (docs/after-arrival.md) names four prohibitions,
-- because they are what a future session will be tempted to add.
-- Three of them are testable on the text itself, and they are
-- tested here — a rule written only in a document is a rule.
-- A rule with an assertion is a constraint.
-- ============================================================

create table pg_temp.r (n int generated always as identity, name text, result text, detail text);
create or replace function pg_temp.chk(p_name text, p_cond boolean, p_detail text default null)
returns void language sql as $$
  insert into pg_temp.r (name, result, detail)
  values (p_name, case when p_cond then 'PASS' else 'FAIL' end, p_detail);
$$;

-- A family walked to arrival through the production writers, then the stage
-- closed the way close_stage closes it.
create or replace function pg_temp.arrived(p_pid text, p_hard_after int default 0)
returns uuid language plpgsql as $$
declare p uuid; c uuid; s uuid; st uuid; v_day uuid; a jsonb;
begin
  insert into public.followers (platform_user_id, country) values (p_pid,'DZ') returning id into p;
  insert into public.children (follower_id, name, is_primary) values (p,'يوسف',true) returning id into c;
  insert into public.situations (child_id, parent_id, key, label_ar, status, window_start, window_end)
  select c, p, 'sleep', sc.label_ar, 'confirmed', sc.window_start, sc.window_end
    from public.situation_catalog sc where sc.key='sleep' returning id into s;
  insert into public.checkin_state (parent_id, cadence, local_hour) values (p,'nightly',20);

  a := public.activate_subscription(p, null, null, 'test', 'sleep',
         'خمس ليالٍ هادئة من سبع عند النوم مع يوسف', 5, 7, 29);

  -- Eight nights of the journey, one of them hard.
  for i in 0..7 loop
    v_day := (public.record_seed_sent(p, current_date, 'تنبيه قبل النوم بعشر دقائق',
                jsonb_build_array('child_name','situation'), s, c)->>'day_id')::uuid;
    perform public.record_harvest_sent(v_day);
    perform public.record_harvest_answer(p, case when i = 3 then 'tried_failed' else 'succeeded' end);
    update public.daily_logs set log_date = current_date - (40 - i)
     where follower_id = p and log_date = current_date;
  end loop;

  -- Arrival, ten days ago.
  select id into st from public.stages where parent_id = p and status in ('active','extended');
  update public.stages set status = 'completed', completed_at = now() - interval '10 days'
   where id = st;

  -- Nights since. Hard ones are a relapse; calm ones are the calm holding.
  -- Written the way a rhythm night is actually written: chk_harvest_needs_seed
  -- refuses a night that carries an answer to a question never asked, so a
  -- shorter insert here would be a row production would reject.
  for i in 1..p_hard_after loop
    insert into public.daily_logs
      (follower_id, child_id, log_date, source, seed_text, seed_grounded_on,
       seed_sent_at, harvest_sent_at, harvest_answered_at, night_result)
    values (p, c, current_date - i, 'rhythm', 'تنبيه قبل النوم بعشر دقائق',
            jsonb_build_array('child_name','situation'),
            now() - make_interval(days => i), now() - make_interval(days => i),
            now() - make_interval(days => i), 'hard');
  end loop;
  return p;
end $$;


\echo '=== THE RHYTHM STEPS DOWN BY ITSELF ==='
do $$
declare p uuid;
begin
  p := pg_temp.arrived('ar-quiet');
  perform pg_temp.chk('reaching the goal quietens the nightly question to weekly',
    (select cadence from public.checkin_state where parent_id = p) = 'weekly',
    'nobody should have to ask ADAM to stop asking about a solved problem');
end $$;

do $$
declare p uuid; st uuid;
begin
  -- A parent who already chose to stop is not moved by an arrival.
  p := pg_temp.arrived('ar-stopped');
  update public.checkin_state set cadence = 'stopped' where parent_id = p;
  insert into public.stages (parent_id, problem_key, objective_text, objective_target,
                             objective_window, status, started_at)
  values (p, 'meal', 'ثلاث وجبات هادئة من خمس', 3, 5, 'active', now() - interval '9 days')
  returning id into st;
  update public.stages set status = 'completed', completed_at = now() where id = st;

  perform pg_temp.chk('but a cadence she stopped herself is never revived by it',
    (select cadence from public.checkin_state where parent_id = p) = 'stopped',
    'a step down, never a step up');
end $$;


\echo '=== THE ARRIVAL MESSAGE SELLS NOTHING AND CLAIMS NOTHING ==='
do $$
declare p uuid; m jsonb; b text;
begin
  p := pg_temp.arrived('ar-msg');
  m := public.arrival_message(p, 'arrived');
  b := m->>'body';

  perform pg_temp.chk('it names the goal they agreed, not a generic congratulation',
    b like '%خمس ليالٍ هادئة من سبع%', left(b, 40));

  -- Prohibition 4: ADAM never claims the result.
  perform pg_temp.chk('ADAM gives the credit away, by name',
    b like '%لم أفعل هذا أنا%' and b like '%أنتم من جرّب%',
    'it asked a question and wrote the answer; they did the rest');

  -- Prohibition 1: no offer, and prohibition 3: no expiry framing.
  perform pg_temp.chk('nothing in it leads to money',
    b not like '%اشترك%' and b not like '%مرافقة%' and b not like '%فريق آدم%'
    and (select jsonb_array_length(buttons) from public.conversation_moments
          where key = 'journey_arrived') = 0,
    'the one message in the product that sells nothing');
  perform pg_temp.chk('and nothing in it is framed as expiring',
    b not like '%ينتهي%' and b not like '%تبقّى%',
    'what ended is a goal reached, not a rental');
  perform pg_temp.chk('and it asks for nothing tonight',
    b like '%لا خطوة ولا سؤال%');
end $$;


\echo '=== THE CHOICE COMES LATER, AND THE FREE DOOR IS NAMED FIRST ==='
do $$
declare p uuid; b text;
begin
  p := pg_temp.arrived('ar-now');
  b := public.arrival_message(p, 'what_now')->>'body';

  perform pg_temp.chk('the free door appears before the paid one',
    position('يبقى مجانياً' in b) > 0
    and position('يبقى مجانياً' in b) < position('نتّفق على هدف' in b),
    'that order is the only reason the second door is believable');
  perform pg_temp.chk('and leaving is a door too, not an absence',
    b like '%أو نكتفي بهذا%' and b like '%لا أختفي%');
  perform pg_temp.chk('the next goal is offered, never assumed',
    (select jsonb_array_length(buttons) from public.conversation_moments
      where key = 'journey_what_now') = 3);
end $$;


\echo '=== THE WATCH: THREE HARD NIGHTS, AND ADAM COMES BACK ==='
do $$
declare p uuid; q uuid;
begin
  p := pg_temp.arrived('ar-calm', 0);
  q := pg_temp.arrived('ar-relapse', 3);

  perform pg_temp.chk('a calm month after arrival is not a relapse',
    (select relapse from public.v_arrival_watch where parent_id = p) is not true);
  perform pg_temp.chk('three hard nights in a week is',
    (select relapse from public.v_arrival_watch where parent_id = q),
    'one is a night, two is a week, three is a pattern returning');
  perform pg_temp.chk('and the journey''s OWN hard nights never count as one',
    (select since_arrival from public.v_arrival_watch where parent_id = p) = 0,
    'only nights after the goal was met are counted');
end $$;

do $$
declare p uuid; b text;
begin
  p := pg_temp.arrived('ar-return', 3);
  b := public.arrival_message(p, 'relapse')->>'body';

  perform pg_temp.chk('the return does not start from zero',
    b like '%لا نبدأ من الصفر%');
  perform pg_temp.chk('and says exactly what worked last time, with the count',
    -- The successes are pinned; the denominator is not. It counts every night
    -- the step was given, which now includes the relapse nights themselves — so
    -- pinning it would make this assertion a restatement of the fixture rather
    -- than a check on the message.
    b like '%تنبيه قبل النوم بعشر دقائق%' and b like '%نجح ٧ من%', left(b, 200));
  perform pg_temp.chk('and it asks for nothing but a week',
    b not like '%اشترك%' and b like '%نعيده أسبوعاً%',
    'charging for the return is charging for the failure of what they paid for');
end $$;


\echo '=== IT COMPOSES, IT NEVER SENDS AND NEVER RENEWS ==='
do $$
declare p uuid; n int;
begin
  p := pg_temp.arrived('ar-ro');
  select count(*) into n from public.stages;
  perform public.arrival_message(p, 'arrived');
  perform public.arrival_message(p, 'what_now');
  perform public.arrival_message(p, 'relapse');

  -- Prohibition 2: no stage renews itself.
  perform pg_temp.chk('composing all three starts no new journey',
    (select count(*) from public.stages) = n,
    'a journey nobody agreed is not a journey');
  perform pg_temp.chk('a parent who never arrived gets no arrival message',
    (public.arrival_message(gen_random_uuid(), 'arrived')->>'reason') = 'no_arrival');
  perform pg_temp.chk('and an unknown kind is refused rather than guessed',
    (public.arrival_message(p, 'celebrate')->>'reason') = 'unknown_kind');
end $$;


\echo '=== RESULTS ==='
\pset format unaligned
select lpad(n::text,2) || '  ' || rpad(result,6) || rpad(name, 60)
    || coalesce('  -> ' || left(replace(detail, chr(10), ' / '), 44), '')
from pg_temp.r order by n;
select E'\n' || count(*) filter (where result='PASS') || ' / ' || count(*) || ' passed'
from pg_temp.r;

rollback;
