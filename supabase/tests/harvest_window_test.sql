\set ON_ERROR_STOP on
begin;

create table pg_temp.r (n int generated always as identity, name text, result text, detail text);
create or replace function pg_temp.chk(p_name text, p_cond boolean, p_detail text default null)
returns void language sql as $$
  insert into pg_temp.r (name, result, detail)
  values (p_name, case when p_cond then 'PASS' else 'FAIL' end, p_detail);
$$;

-- ===============================================================
-- THE EVENING QUESTION MUST BE REACHABLE.
--
-- Between 17 and 30 August 2026 it was not: 117 seeds had gone
-- out, 27 had ever been harvested, and the last one was on the
-- 16th. get_rhythm_due only offers 'harvest' when the local hour
-- is past the family's window end, and it only looks at families
-- whose local hour is under 23. A family with no confirmed
-- situation defaulted to a window ending at 22, so the harvest
-- needed hour 23 and the gate excluded hour 23. No hour existed.
--
-- Nothing in the suite noticed, because every other test drives
-- the harvest directly through record_harvest_answer() and never
-- asks whether the scheduler would have offered it.
--
-- The test cannot move the clock, so it moves the family: it
-- picks a real timezone in which it is 22:00 right now, which
-- exists at every moment of the day.
-- ===============================================================
do $$
declare
  v_tz text; v_p uuid; v_c uuid; v_day uuid; v_hour int;
  v_action text; v_rows int;
begin
  select name into v_tz from pg_timezone_names
  where extract(hour from (now() at time zone name)) = 22
    and name like '%/%'
  order by name limit 1;

  perform pg_temp.chk('a timezone where it is 22:00 right now exists',
    v_tz is not null, v_tz);
  if v_tz is null then return; end if;

  insert into public.country_timezone (code, iana_tz, name_ar)
  values ('ZZ', v_tz, 'بلد الاختبار')
  on conflict (code) do update set iana_tz = excluded.iana_tz;

  insert into public.followers (platform_user_id, country, proactive_footer_at)
  values ('harvest-window-probe', 'ZZ', now()) returning id into v_p;
  insert into public.children (follower_id, name, is_primary)
  values (v_p, 'يوسف', true) returning id into v_c;
  insert into public.checkin_state (parent_id, cadence, local_hour)
  values (v_p, 'nightly', 20);

  -- A family with NO confirmed situation — the exact shape every
  -- seed since 17 August went to.
  perform pg_temp.chk('the family deliberately has no situation',
    not exists (select 1 from public.situations s where s.child_id = v_c));

  -- One earlier night that went calm, so can_ground_seed passes on
  -- prior_outcome rather than on a situation.
  insert into public.daily_logs
    (follower_id, child_id, log_date, step_given, seed_text, seed_sent_at,
     seed_grounded_on, source, night_result, step_status)
  values (v_p, v_c, (now() at time zone v_tz)::date - 3,
          'نبّهوه قبل النوم بعشر دقائق', 'نبّهوه قبل النوم بعشر دقائق', now(),
          jsonb_build_array('child_name'), 'rhythm', 'calm', 'done');

  -- Today's seed is out and unanswered: exactly the state that must
  -- produce an evening question.
  insert into public.daily_logs
    (follower_id, child_id, log_date, step_given, seed_text, seed_sent_at,
     seed_grounded_on, source)
  values (v_p, v_c, (now() at time zone v_tz)::date,
          'نبّهوه قبل النوم بعشر دقائق', 'نبّهوه قبل النوم بعشر دقائق', now(),
          jsonb_build_array('child_name','prior_outcome'), 'rhythm')
  returning id into v_day;

  select count(*), max(action) into v_rows, v_action
  from public.get_rhythm_due(200, 'harvest-window-probe');

  perform pg_temp.chk('the scheduler sees this family at all',
    v_rows > 0, 'rows: ' || v_rows);
  perform pg_temp.chk('and what it owes them is the evening question',
    v_action = 'harvest',
    coalesce(v_action, '(nothing — the bug: no hour satisfies both '
      || 'local_hour < 23 and local_hour > win_end)'));

  -- The same must hold for a family whose real window ends at 22,
  -- the latest the catalog allows. Before the cap, these two were
  -- the only ones the bug could not reach even with a situation.
  update public.followers set platform_user_id = 'harvest-window-probe-2' where id = v_p;
  insert into public.situations (child_id, parent_id, key, label_ar, status,
                                 window_start, window_end, evidence_count)
  select v_c, v_p, sc.key, sc.label_ar, 'confirmed', sc.window_start, sc.window_end, 3
  from public.situation_catalog sc where sc.window_end = 22 limit 1;

  select max(action) into v_action
  from public.get_rhythm_due(200, 'harvest-window-probe-2');
  perform pg_temp.chk('a window ending at 22 is still asked, not skipped',
    v_action = 'harvest', coalesce(v_action, '(nothing)'));
end $$;

select n, result, name, coalesce(detail,'') as detail from pg_temp.r order by n;
select count(*) filter (where result = 'PASS') || ' / ' || count(*) || ' passed' from pg_temp.r;

rollback;
