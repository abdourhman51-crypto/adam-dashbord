\set ON_ERROR_STOP on
begin;

-- ============================================================
-- SILENCE IS AN ANSWER.
--
-- decay_checkin_consent was inert from 30 July to 7 August: it
-- counted ignored nights from checkin_state.last_sent_date, and
-- the function that wrote that column had been replaced by the
-- rhythm. Recovery still worked. So the live product could come
-- back from silence it was structurally unable to notice — it
-- would have gone on asking nightly, forever, of someone who
-- stopped answering weeks ago.
--
-- It had no test. That is why nobody knew. These are the cases
-- that would have failed on 30 July.
-- ============================================================

create table pg_temp.r (n int generated always as identity, name text, result text, detail text);
create or replace function pg_temp.chk(p_name text, p_cond boolean, p_detail text default null)
returns void language sql as $$
  insert into pg_temp.r (name, result, detail)
  values (p_name, case when p_cond then 'PASS' else 'FAIL' end, p_detail);
$$;

create or replace function pg_temp.parent(p_pid text)
returns uuid language plpgsql as $$
declare v uuid;
begin
  insert into public.followers (platform_user_id, country) values (p_pid, 'DZ') returning id into v;
  insert into public.checkin_state (parent_id, cadence, local_hour) values (v, 'nightly', 20);
  return v;
end $$;

-- One evening: the rhythm asked, and either she answered or she did not.
create or replace function pg_temp.evening(p_parent uuid, p_days_ago int, p_answered boolean)
returns void language sql as $$
  insert into public.daily_logs
    (follower_id, log_date, source, seed_text, seed_grounded_on, seed_sent_at,
     harvest_sent_at, harvest_answered_at, night_result)
  values
    (p_parent, current_date - p_days_ago, 'rhythm', 'خطوة صغيرة',
     '["child_name"]'::jsonb, now() - make_interval(days => p_days_ago),
     now() - make_interval(days => p_days_ago),
     case when p_answered then now() - make_interval(days => p_days_ago) end,
     case when p_answered then 'calm' end);
$$;


\echo '=== AN UNANSWERED EVENING IS COUNTED, AN ANSWERED ONE IS NOT ==='
do $$
declare p uuid; q uuid;
begin
  p := pg_temp.parent('cd-silent');
  q := pg_temp.parent('cd-answers');
  perform pg_temp.evening(p, 3, false);
  perform pg_temp.evening(p, 2, false);
  perform pg_temp.evening(q, 3, true);
  perform pg_temp.evening(q, 2, true);

  perform public.decay_checkin_consent();

  perform pg_temp.chk('two unanswered evenings count as two',
    (select consecutive_ignored from public.checkin_state where parent_id = p) = 2,
    (select consecutive_ignored::text from public.checkin_state where parent_id = p));
  perform pg_temp.chk('a parent who answers is never counted against',
    (select consecutive_ignored from public.checkin_state where parent_id = q) = 0);
end $$;


\echo '=== OUR OWN SILENCE IS NOT HERS ==='
do $$
declare p uuid;
begin
  p := pg_temp.parent('cd-never-asked');
  -- A day the rhythm planned but never sent: seed written, harvest never asked.
  insert into public.daily_logs (follower_id, log_date, source, seed_text,
                                 seed_grounded_on, seed_sent_at)
  values (p, current_date - 2, 'rhythm', 'خطوة', '["child_name"]'::jsonb, now() - interval '2 days');

  perform public.decay_checkin_consent();

  perform pg_temp.chk('a night we never asked about is not held against her',
    (select consecutive_ignored from public.checkin_state where parent_id = p) = 0,
    'if the sender never ran, that is our silence');
end $$;

do $$
declare p uuid;
begin
  p := pg_temp.parent('cd-today');
  perform pg_temp.evening(p, 0, false);
  perform public.decay_checkin_consent();
  perform pg_temp.chk('tonight is not counted — the evening is not over',
    (select consecutive_ignored from public.checkin_state where parent_id = p) = 0);
end $$;


\echo '=== RUNNING IT TWICE COUNTS NOTHING TWICE ==='
do $$
declare p uuid; a int; b int;
begin
  p := pg_temp.parent('cd-idem');
  perform pg_temp.evening(p, 3, false);
  perform pg_temp.evening(p, 2, false);
  perform pg_temp.evening(p, 1, false);

  perform public.decay_checkin_consent();
  select consecutive_ignored into a from public.checkin_state where parent_id = p;
  perform public.decay_checkin_consent();
  perform public.decay_checkin_consent();
  select consecutive_ignored into b from public.checkin_state where parent_id = p;

  perform pg_temp.chk('three unanswered evenings count as three', a = 3, a::text);
  perform pg_temp.chk('and two more runs the same day add nothing', b = 3, b::text);
end $$;

do $$
declare p uuid;
begin
  p := pg_temp.parent('cd-catchup');
  perform pg_temp.evening(p, 4, false);
  perform pg_temp.evening(p, 3, false);
  perform pg_temp.evening(p, 2, false);
  perform pg_temp.evening(p, 1, false);
  -- The job did not run for four days. Nothing is forgiven; it is counted late.
  perform public.decay_checkin_consent();
  perform pg_temp.chk('four days the job did not run are counted, not forgiven',
    (select consecutive_ignored from public.checkin_state where parent_id = p) = 4);
end $$;


\echo '=== FIVE QUIETENS IT, NINE MORE STOP IT ==='
do $$
declare p uuid; res record;
begin
  p := pg_temp.parent('cd-ladder');
  for i in 1..4 loop perform pg_temp.evening(p, i, false); end loop;
  perform public.decay_checkin_consent();
  perform pg_temp.chk('four ignored nights are not yet enough to quieten it',
    (select cadence from public.checkin_state where parent_id = p) = 'nightly');

  perform pg_temp.evening(p, 5, false);
  update public.checkin_state set last_decayed_on = null where parent_id = p;
  update public.checkin_state set consecutive_ignored = 0 where parent_id = p;
  perform public.decay_checkin_consent();

  perform pg_temp.chk('the fifth does',
    (select cadence from public.checkin_state where parent_id = p) = 'weekly');
  perform pg_temp.chk('and the streak restarts from the quieter cadence',
    (select consecutive_ignored from public.checkin_state where parent_id = p) = 0,
    'the next nine are counted from weekly, not from where she already was');

  update public.checkin_state set consecutive_ignored = 9 where parent_id = p;
  perform public.decay_checkin_consent();
  perform pg_temp.chk('nine more stop the proactive rhythm entirely',
    (select cadence from public.checkin_state where parent_id = p) = 'stopped');
end $$;

do $$
declare p uuid; acted text;
begin
  p := pg_temp.parent('cd-reports');
  update public.checkin_state set consecutive_ignored = 5 where parent_id = p;
  select action into acted from public.decay_checkin_consent() d where d.parent_id = p;
  perform pg_temp.chk('the step-down is reported to the caller, not done silently',
    acted = 'quietened_to_weekly', acted);
end $$;


\echo '=== AN UNREADABLE ANSWER IS REFUSED, NOT SILENTLY SWALLOWED ==='
do $$
declare p uuid; c uuid; s uuid; v_day uuid; res jsonb;
begin
  p := pg_temp.parent('cd-bad-outcome');
  insert into public.children (follower_id, name, is_primary) values (p, 'يوسف', true) returning id into c;
  insert into public.situations (child_id, parent_id, key, label_ar, status, window_start, window_end)
  select c, p, 'sleep', sc.label_ar, 'confirmed', sc.window_start, sc.window_end
    from public.situation_catalog sc where sc.key = 'sleep' returning id into s;

  v_day := (public.record_seed_sent(p, current_date, 'خطوة صغيرة',
              jsonb_build_array('child_name','situation'), s, c)->>'day_id')::uuid;
  perform public.record_harvest_sent(v_day);

  -- 'calm' is the vocabulary of night_result, in the same table, one column
  -- across. It used to be accepted here: the night was stamped answered, the
  -- streak was reset, and NOTHING was written down.
  res := public.record_harvest_answer(p, 'calm');

  perform pg_temp.chk('an outcome we cannot read is refused',
    (res->>'recorded')::boolean is false and res->>'reason' = 'unknown_outcome', res::text);
  perform pg_temp.chk('and the night is NOT marked answered',
    (select harvest_answered_at from public.daily_logs
      where follower_id = p and log_date = current_date) is null,
    'otherwise can_send would never ask again, and nothing was learned');
  perform pg_temp.chk('and nothing was written',
    (select night_result is null and step_status is null from public.daily_logs
      where follower_id = p and log_date = current_date));

  -- The real word works, on the very same night.
  res := public.record_harvest_answer(p, 'succeeded');
  perform pg_temp.chk('and the correct word still records it',
    (res->>'recorded')::boolean
    and (select night_result from public.daily_logs
          where follower_id = p and log_date = current_date) = 'calm', res::text);
end $$;


\echo '=== ONE REPLY WIPES THE STREAK — BUT DOES NOT OVERRIDE HER STOP ==='
do $$
declare p uuid; c uuid; s uuid; v_day uuid;
begin
  p := pg_temp.parent('cd-returns');
  insert into public.children (follower_id, name, is_primary) values (p, 'ليان', true) returning id into c;
  insert into public.situations (child_id, parent_id, key, label_ar, status, window_start, window_end)
  values (c, p, 'sleep', 'وقت النوم', 'confirmed', 19, 22) returning id into s;

  update public.checkin_state set cadence = 'stopped', consecutive_ignored = 12 where parent_id = p;

  -- She answers tonight, through the rhythm's own writers.
  v_day := (public.record_seed_sent(p, current_date, 'خطوة صغيرة الليلة',
              jsonb_build_array('child_name','situation'), s, c)->>'day_id')::uuid;
  perform public.record_harvest_sent(v_day);
  perform public.record_harvest_answer(p, 'succeeded');

  perform pg_temp.chk('the streak is wiped entirely',
    (select consecutive_ignored from public.checkin_state where parent_id = p) = 0,
    'coming back is not held against her');

  -- The legacy record_checkin_response revived a stopped cadence on any answer.
  -- record_harvest_answer deliberately does not, and this asserts the silence.
  --
  -- 'stopped' is reached two ways: she tapped stop, or decay stopped her. The
  -- table does not distinguish them, so auto-reviving would silently override an
  -- explicit choice — the one thing ensure_checkin_state's own comment said never
  -- to do ("never resurrect a cadence she wound down"). She is not stranded:
  -- get_telegram_surface reports cadence='stopped' as paused, so her keyboard
  -- offers «كيف نعود؟», and get_moment_after_tap('menu_settings_resumed') sets it
  -- back to nightly. Coming back stays her decision, made once, out loud.
  perform pg_temp.chk('but a stopped rhythm is NOT restarted behind her back',
    (select cadence from public.checkin_state where parent_id = p) = 'stopped',
    'the resume button exists; answering once is not consent to be asked nightly');
end $$;


\echo '=== THE LEGACY ENGINE IS GONE ==='
do $$
begin
  perform pg_temp.chk('get_checkin_batch is deleted',
    to_regprocedure('public.get_checkin_batch()') is null);
  perform pg_temp.chk('record_checkin_sent is deleted',
    to_regprocedure('public.record_checkin_sent(uuid, date)') is null);
  perform pg_temp.chk('record_checkin_response is deleted',
    to_regprocedure('public.record_checkin_response(uuid, text, text, text)') is null);
  perform pg_temp.chk('ensure_checkin_state is deleted',
    to_regprocedure('public.ensure_checkin_state(uuid)') is null);

  -- The table is NOT legacy. §3 said it was; five live functions say otherwise.
  perform pg_temp.chk('but checkin_state SURVIVES — the rhythm''s pause lives there',
    to_regclass('public.checkin_state') is not null,
    'dropping it would have taken pause, resume, stop and the evening hour');
  perform pg_temp.chk('and set_checkin_hour survives with it',
    to_regprocedure('public.set_checkin_hour(uuid, smallint)') is not null);

  perform pg_temp.chk('the legacy consent columns are gone from followers',
    not exists (select 1 from information_schema.columns
                 where table_schema = 'public' and table_name = 'followers'
                   and column_name in ('checkin_opt_in','checkin_opted_at','last_checkin_sent_date')));
  perform pg_temp.chk('but daily_logs.checkin_sent_at stays — a live node writes it',
    exists (select 1 from information_schema.columns
             where table_schema = 'public' and table_name = 'daily_logs'
               and column_name = 'checkin_sent_at'));
end $$;


\echo '=== RESULTS ==='
\pset format unaligned
select lpad(n::text,2) || '  ' || rpad(result,6) || rpad(name, 62)
    || coalesce('  -> ' || left(replace(detail, chr(10), ' / '), 48), '')
from pg_temp.r order by n;
select E'\n' || count(*) filter (where result='PASS') || ' / ' || count(*) || ' passed'
from pg_temp.r;

rollback;
