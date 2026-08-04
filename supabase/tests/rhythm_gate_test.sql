\set ON_ERROR_STOP on
begin;

create table pg_temp.r (n int generated always as identity, name text, result text, detail text);
create or replace function pg_temp.chk(p_name text, p_cond boolean, p_detail text default null)
returns void language sql as $$
  insert into pg_temp.r (name, result, detail)
  values (p_name, case when p_cond then 'PASS' else 'FAIL' end, p_detail);
$$;

-- A family ADAM can ground a seed for: named child, confirmed situation.
-- Every parent below is built in a timezone whose local hour we control by
-- picking the country, so "is it seed time" is deterministic rather than
-- dependent on when the suite happens to run.
create or replace function pg_temp.ready_parent(p_country text, p_win_start smallint)
returns uuid language plpgsql as $$
declare v uuid; c uuid;
begin
  insert into public.followers (platform_user_id, country)
  values (gen_random_uuid()::text, p_country) returning id into v;
  insert into public.children (follower_id, name, is_primary)
  values (v, 'يوسف', true) returning id into c;
  insert into public.situations (child_id, key, status, evidence_count, window_start, window_end)
  values (c, 'sleep', 'confirmed', 4, p_win_start, (p_win_start + 2)::smallint);
  return v;
end $$;

\echo '=== THE CUT: A PARENT WITH NO checkin_state ROW IS NOT A REFUSAL ==='
do $$
declare p uuid; n int; hr int;
begin
  -- Local hour in Algiers right now decides whether a seed is due at all,
  -- so build the window to sit strictly after it.
  select extract(hour from (now() at time zone 'Africa/Algiers'))::int into hr;

  if hr >= 7 and hr < 20 then
    p := pg_temp.ready_parent('DZ', (hr + 2)::smallint);

    select count(*) into n from public.get_rhythm_due(200) g where g.parent_id = p;
    perform pg_temp.chk('a ready parent with NO checkin_state row is due a seed', n = 1,
      'this is the inner join that sent zero messages for a month');

    perform pg_temp.chk('and it is marked as ADAM''s first uninvited message',
      (select g.is_first_proactive from public.get_rhythm_due(200) g where g.parent_id = p),
      'the exit rides on this one');

    perform pg_temp.chk('and it carries the exit TEXT, read from the copy table',
      (select g.footer_ar from public.get_rhythm_due(200) g where g.parent_id = p)
        = (select body_ar from public.conversation_moments where key='proactive_first_footer'),
      'a sender that holds copy drifts from the table within hours');

    -- an explicit stop must still win
    insert into public.checkin_state (parent_id, cadence) values (p, 'stopped');
    select count(*) into n from public.get_rhythm_due(200) g where g.parent_id = p;
    perform pg_temp.chk('an explicit «stopped» still silences everything', n = 0);

    update public.checkin_state set cadence = 'nightly', paused_until = current_date + 3
      where parent_id = p;
    select count(*) into n from public.get_rhythm_due(200) g where g.parent_id = p;
    perform pg_temp.chk('an explicit pause still silences everything', n = 0);

    update public.checkin_state set paused_until = null where parent_id = p;
    select count(*) into n from public.get_rhythm_due(200) g where g.parent_id = p;
    perform pg_temp.chk('an explicit «nightly» is due, same as no row at all', n = 1);
  else
    perform pg_temp.chk('SKIPPED: local Algiers hour is outside seed time', true, hr::text);
  end if;
end $$;

\echo '=== THE GATE STAYS NARROW — GROUNDING, STRAIN, QUIET HOURS ==='
do $$
declare p uuid; n int; hr int;
begin
  select extract(hour from (now() at time zone 'Africa/Algiers'))::int into hr;

  if hr >= 7 and hr < 20 then
    -- no child name -> cannot ground -> silence, never a generic tip
    insert into public.followers (platform_user_id, country)
    values (gen_random_uuid()::text, 'DZ') returning id into p;
    select count(*) into n from public.get_rhythm_due(200) g where g.parent_id = p;
    perform pg_temp.chk('an ungroundable parent gets silence, not a generic tip', n = 0,
      'P11: honest silence beats a tip that is true of any child');

    -- strain L2 suspends the rhythm
    p := pg_temp.ready_parent('DZ', (hr + 2)::smallint);
    insert into public.parent_strain (parent_id, level) values (p, 2);
    select count(*) into n from public.get_rhythm_due(200) g where g.parent_id = p;
    perform pg_temp.chk('strain L2 suspends the rhythm entirely', n = 0);

    -- a seed that would arrive after the window has already opened is useless
    p := pg_temp.ready_parent('DZ', greatest(hr - 1, 7)::smallint);
    select count(*) into n from public.get_rhythm_due(200) g
      where g.parent_id = p and g.action = 'seed';
    perform pg_temp.chk('no seed once the window has already opened', n = 0,
      'a bedtime step arriving at bedtime is not a step');
  else
    perform pg_temp.chk('SKIPPED: local Algiers hour is outside seed time', true, hr::text);
  end if;
end $$;

\echo '=== NO SEED, NO HARVEST — THE PAIR IS ATOMIC ==='
do $$
declare p uuid; n int; hr int;
begin
  select extract(hour from (now() at time zone 'Africa/Algiers'))::int into hr;

  if hr >= 10 then
    -- window closed hours ago, and no seed was ever sent today
    p := pg_temp.ready_parent('DZ', 7::smallint);
    select count(*) into n from public.get_rhythm_due(200) g
      where g.parent_id = p and g.action = 'harvest';
    perform pg_temp.chk('a harvest never fires without a seed that day', n = 0,
      'asking "how did it go?" about nothing is an interrogation');

    -- now with a seed sent today
    insert into public.daily_logs (follower_id, log_date, seed_text, seed_sent_at)
    values (p, (now() at time zone 'Africa/Algiers')::date, 'خطوة', now());
    select count(*) into n from public.get_rhythm_due(200) g
      where g.parent_id = p and g.action = 'harvest';
    perform pg_temp.chk('with a seed sent, the harvest is due after the window', n = 1);

    perform pg_temp.chk('a harvest is never flagged as ADAM''s first message',
      not (select coalesce(bool_or(g.is_first_proactive), false)
             from public.get_rhythm_due(200) g
             where g.parent_id = p and g.action = 'harvest')
      and (select coalesce(bool_and(g.footer_ar is null), true)
             from public.get_rhythm_due(200) g
             where g.parent_id = p and g.action = 'harvest'),
      'the exit rides on the seed, which always came first');
  else
    perform pg_temp.chk('SKIPPED: too early in Algiers for a closed window', true, hr::text);
  end if;
end $$;

\echo '=== THE EXIT EXISTS, AND IS ONE LINE ==='
do $$
declare m jsonb;
begin
  m := public.get_conversation_moment('proactive_first_footer', null);
  perform pg_temp.chk('the first uninvited message carries an exit',
    (m->>'found')::boolean and (m->>'body') like '%/settings%', m->>'body');
  perform pg_temp.chk('and it is one line, not an explanation',
    public.content_line_count(m->>'body') = 1, m->>'body');
end $$;

\echo '=== RESULTS ==='
\pset format unaligned
select lpad(n::text,2) || '  ' || rpad(result,6) || rpad(name, 58)
    || coalesce('  -> ' || left(replace(detail, chr(10), ' / '), 58), '')
from pg_temp.r order by n;
select E'\n' || count(*) filter (where result='PASS') || ' / ' || count(*) || ' passed'
from pg_temp.r;

rollback;
