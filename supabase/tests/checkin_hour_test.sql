\set ON_ERROR_STOP on
begin;

-- ============================================================
-- set_checkin_hour, called for real.
--
-- The only prior test of this function checked to_regprocedure(...) is
-- not null and never invoked it — which is exactly how a CHECK-constraint
-- violation on every real call (repo wrote cadence='daily';
-- checkin_state_cadence_check allows only nightly/weekly/stopped)
-- survived every offline suite. These cases call it.
-- ============================================================

create table pg_temp.r (n int generated always as identity, name text, result text, detail text);
create or replace function pg_temp.chk(p_name text, p_cond boolean, p_detail text default null)
returns void language sql as $$
  insert into pg_temp.r (name, result, detail)
  values (p_name, case when p_cond then 'PASS' else 'FAIL' end, p_detail);
$$;

create or replace function pg_temp.parent()
returns uuid language sql as $$
  insert into public.followers (platform_user_id, country)
  values (gen_random_uuid()::text, 'DZ') returning id;
$$;


\echo '=== set_checkin_hour actually writes a row the constraint allows ==='
do $$
declare p uuid; ok boolean; v_hour smallint; v_cadence text;
begin
  p := pg_temp.parent();
  ok := public.set_checkin_hour(p, 20::smallint);
  perform pg_temp.chk('returns true on a valid hour', ok = true);

  select local_hour, cadence into v_hour, v_cadence
  from public.checkin_state where parent_id = p;
  perform pg_temp.chk('local_hour stored', v_hour = 20, v_hour::text);
  perform pg_temp.chk('cadence is a value the constraint allows',
    v_cadence in ('nightly','weekly','stopped'), coalesce(v_cadence,'<null>'));
end $$;


\echo '=== an existing row is updated, not duplicated, and keeps its cadence ==='
do $$
declare p uuid; n int; v_cadence_before text; v_cadence_after text; v_hour smallint;
begin
  p := pg_temp.parent();
  perform public.set_checkin_hour(p, 8::smallint);

  -- Simulate a parent who had switched to weekly.
  update public.checkin_state set cadence = 'weekly' where parent_id = p;
  select cadence into v_cadence_before from public.checkin_state where parent_id = p;

  perform public.set_checkin_hour(p, 21::smallint);

  select count(*) into n from public.checkin_state where parent_id = p;
  perform pg_temp.chk('still exactly one row per parent', n = 1, n::text);

  select local_hour, cadence into v_hour, v_cadence_after
  from public.checkin_state where parent_id = p;
  perform pg_temp.chk('hour updated to the new choice', v_hour = 21, v_hour::text);
  perform pg_temp.chk('re-picking the hour does not reset an explicit weekly cadence',
    v_cadence_after = v_cadence_before, v_cadence_after);
end $$;


\echo '=== an out-of-range hour is refused, nothing written ==='
do $$
declare p uuid; ok boolean; n int;
begin
  p := pg_temp.parent();
  ok := public.set_checkin_hour(p, 24::smallint);
  perform pg_temp.chk('hour 24 refused', ok = false);
  ok := public.set_checkin_hour(p, (-1)::smallint);
  perform pg_temp.chk('negative hour refused', ok = false);
  ok := public.set_checkin_hour(p, null);
  perform pg_temp.chk('null hour refused', ok = false);

  select count(*) into n from public.checkin_state where parent_id = p;
  perform pg_temp.chk('no row written for a refused hour', n = 0, n::text);
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
