\set ON_ERROR_STOP on
begin;

-- ============================================================
-- get_rhythm_due routes the morning give to the journey step.
--
-- A parent with no journey gets a 'seed'; the same parent inside a live
-- journey gets 'journey_step' in the same slot. The evening 'harvest' is
-- untouched. The timing depends on the local Algiers hour, so the seed/
-- journey assertions run only when a morning give can be due right now;
-- the routing rule itself is asserted whenever the window allows, and the
-- no-regression facts (free parent still seeds) are checked alongside.
-- Everything rolls back.
-- ============================================================

create table pg_temp.r (n int generated always as identity, name text, result text, detail text);
create or replace function pg_temp.chk(p_name text, p_cond boolean, p_detail text default null)
returns void language sql as $$
  insert into pg_temp.r (name, result, detail)
  values (p_name, case when p_cond then 'PASS' else 'FAIL' end, p_detail);
$$;

-- A parent set up to be due for a MORNING give right now: DZ (Algiers),
-- nightly cadence, a named child, a confirmed situation whose window opens
-- after the current local hour (so local_hour < win_start → seed due), and
-- a prior outcome so both can_ground_seed and can_send have their evidence.
create or replace function pg_temp.morning_parent(p_name text)
returns uuid language plpgsql as $$
declare v uuid; c uuid; v_hour int; v_win int;
begin
  select extract(hour from (now() at time zone 'Africa/Algiers'))::int into v_hour;
  -- Window opens one hour from now, capped inside the awake day.
  v_win := least(greatest(v_hour + 1, 8), 22);

  insert into public.followers (platform_user_id, country)
  values (gen_random_uuid()::text, 'DZ') returning id into v;
  insert into public.children (follower_id, name, is_primary)
  values (v, p_name, true) returning id into c;
  insert into public.situations (child_id, parent_id, key, label_ar, status,
                                 evidence_count, window_start, window_end)
  values (c, v, 'sleep', 'وقت النوم', 'confirmed', 4, v_win, least(v_win + 2, 23));
  insert into public.checkin_state (parent_id, cadence, cadence_changed_at)
  values (v, 'nightly', now());
  -- One prior outcome (grounds the seed and the journey step alike).
  insert into public.daily_logs (follower_id, log_date, night_result, step_given, step_status)
  values (v, current_date - 3, 'calm', 'روتين هادئ', 'done');
  return v;
end $$;

create or replace function pg_temp.action_of(p uuid)
returns text language sql as $$
  select action from public.get_rhythm_due(500) where parent_id = p limit 1;
$$;


\echo '=== ROUTING: same slot, journey turns seed into journey_step ==='
do $$
declare
  p_free uuid; p_journey uuid;
  v_hour int; v_morning boolean;
  a_free text; a_journey text;
begin
  select extract(hour from (now() at time zone 'Africa/Algiers'))::int into v_hour;
  -- A morning give can be due only inside the awake window with room for a
  -- window that opens later. Below 7 or at/after 22 it cannot; then the
  -- routing is not observable and we assert the invariant that holds anyway.
  v_morning := (v_hour >= 7 and v_hour < 22);

  p_free    := pg_temp.morning_parent('حرّ');
  p_journey := pg_temp.morning_parent('رحلة');
  perform public.start_stage(p_journey, 'sleep', 'خمس ليالٍ هادئة من سبع', 5, 7, 29);

  a_free    := pg_temp.action_of(p_free);
  a_journey := pg_temp.action_of(p_journey);

  if v_morning then
    perform pg_temp.chk('free parent gets a seed',        a_free = 'seed', coalesce(a_free,'<null>'));
    perform pg_temp.chk('journey parent gets journey_step', a_journey = 'journey_step', coalesce(a_journey,'<null>'));
  else
    -- Outside the morning window nothing morning-shaped is due for either.
    perform pg_temp.chk('off-hours: free parent not seeded now',
      a_free is distinct from 'seed', coalesce(a_free,'<null>'));
    perform pg_temp.chk('off-hours: journey parent not journey_stepped now',
      a_journey is distinct from 'journey_step', coalesce(a_journey,'<null>'));
  end if;

  -- Invariant regardless of the hour: a journey parent is NEVER returned as
  -- a plain 'seed'. The morning give is theirs as a journey step or not at all.
  perform pg_temp.chk('journey parent is never a plain seed',
    a_journey is distinct from 'seed', coalesce(a_journey,'<null>'));
end $$;


\echo '=== THE GATE: a journey with no outcome is silent, not a fallback seed ==='
do $$
declare p uuid; c uuid; v_hour int; v_win int; a text;
begin
  select extract(hour from (now() at time zone 'Africa/Algiers'))::int into v_hour;
  v_win := least(greatest(v_hour + 1, 8), 22);

  insert into public.followers (platform_user_id, country)
  values (gen_random_uuid()::text, 'DZ') returning id into p;
  insert into public.children (follower_id, name, is_primary)
  values (p, 'صامت', true) returning id into c;
  insert into public.situations (child_id, parent_id, key, label_ar, status,
                                 evidence_count, window_start, window_end)
  values (c, p, 'sleep', 'وقت النوم', 'confirmed', 4, v_win, least(v_win + 2, 23));
  insert into public.checkin_state (parent_id, cadence, cadence_changed_at)
  values (p, 'nightly', now());
  -- A live journey but ZERO outcomes → can_send('journey_step') is false.
  perform public.start_stage(p, 'sleep', 'خمس ليالٍ هادئة من سبع', 5, 7, 29);

  a := pg_temp.action_of(p);
  -- Silent this morning: no seed, no journey_step. Never a fallback seed.
  perform pg_temp.chk('no-outcome journey: not returned as a seed',
    a is distinct from 'seed', coalesce(a,'<null>'));
  perform pg_temp.chk('no-outcome journey: not sent a journey_step either',
    a is distinct from 'journey_step', coalesce(a,'<null>'));
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
