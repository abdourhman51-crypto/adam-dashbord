-- Run order: fixture_minimal.sql, then fixture_mirror.sql, then
-- mirror_engine_core.sql and this repo's later mirror migrations,
-- then this file. fixture_mirror.sql provides v_child_record and
-- crisis_flags -- see that file for why they are stubbed rather than
-- loaded from the real journey_engine / child_record migrations.
\set ON_ERROR_STOP on
begin;
create table pg_temp.r (n int generated always as identity, name text, result text, detail text);
create or replace function pg_temp.chk(p_name text, p_cond boolean, p_detail text default null)
returns void language sql as $$
  insert into pg_temp.r (name, result, detail)
  values (p_name, case when p_cond then 'PASS' else 'FAIL' end, p_detail);
$$;

\echo '=== THE FIRST MIRROR: DUE, ONCE, AND WHAT IT CARRIES ==='
do $$
declare p uuid; c uuid; g jsonb;
begin
  insert into public.followers (platform_user_id, country) values ('mir-1','DZ') returning id into p;
  insert into public.children (follower_id, name, is_primary) values (p,'يوسف',true) returning id into c;

  -- Two nights logged: not due yet.
  insert into public.daily_logs (follower_id, log_date, night_result) values
    (p, current_date - 2, 'calm'), (p, current_date - 1, 'hard');
  g := public.generate_first_mirror(c);
  perform pg_temp.chk('not due before three logged nights',
    not (g->>'generated')::boolean and g->>'reason' = 'not_due', g::text);

  -- Third night: due.
  insert into public.daily_logs (follower_id, log_date, night_result) values (p, current_date, 'calm');
  g := public.generate_first_mirror(c);
  perform pg_temp.chk('generates once three nights carry a result', (g->>'generated')::boolean, g::text);
  perform pg_temp.chk('payload carries the child''s name', g->'payload'->>'child_name' = 'يوسف');
  perform pg_temp.chk('payload counts nights, calm and hard correctly',
    (g->'payload'->>'nights')::int = 3
    and (g->'payload'->>'calm')::int = 2
    and (g->'payload'->>'hard')::int = 1,
    (g->'payload')::text);
  perform pg_temp.chk('no intention yet: has_intention is false, not absent',
    (g->'payload'->>'has_intention') = 'false', g->'payload'->>'has_intention');

  -- Once, ever, per child (uq_one_first_mirror_per_child + v_mirror_first_due exclusion).
  g := public.generate_first_mirror(c);
  perform pg_temp.chk('never generated twice for the same child',
    not (g->>'generated')::boolean and g->>'reason' = 'not_due', g::text);
end $$;

\echo '=== A RECENT CRISIS SUPPRESSES THE FIRST MIRROR ==='
do $$
declare p uuid; c uuid; g jsonb;
begin
  insert into public.followers (platform_user_id, country) values ('mir-2','EG') returning id into p;
  insert into public.children (follower_id, name, is_primary) values (p,'ريان',true) returning id into c;
  insert into public.daily_logs (follower_id, log_date, night_result) values
    (p, current_date - 2, 'calm'), (p, current_date - 1, 'calm'), (p, current_date, 'calm');
  insert into public.crisis_flags (parent_id, detected_at) values (p, now() - interval '2 days');

  g := public.generate_first_mirror(c);
  perform pg_temp.chk('a crisis inside the last 7 days withholds the wow moment',
    not (g->>'generated')::boolean and g->>'reason' = 'not_due', g::text);
end $$;

\echo '=== THE INTENTION: A FLAG, NEVER THE WORDS ==='
do $$
declare p uuid; c uuid; g jsonb; secret text := 'أب لا يصرخ ولا يفقد صبره أبداً حتى في أصعب الليالي';
begin
  insert into public.followers (platform_user_id, country, intention_text, intention_asked_at)
  values ('mir-3','MA', secret, now() - interval '1 day') returning id into p;
  insert into public.children (follower_id, name, is_primary) values (p,'مالك',true) returning id into c;
  insert into public.daily_logs (follower_id, log_date, night_result) values
    (p, current_date - 2, 'calm'), (p, current_date - 1, 'calm'), (p, current_date, 'hard');

  g := public.generate_first_mirror(c);
  perform pg_temp.chk('once an intention exists, the flag is true', (g->'payload'->>'has_intention')::boolean, g::text);
  perform pg_temp.chk('and the parent''s own words never appear anywhere in the payload',
    position(secret in (g->'payload')::text) = 0, 'leak check');
  perform pg_temp.chk('the payload contains no free-text field at all for it -- only the boolean',
    not (g->'payload' ? 'intention_text') and not (g->'payload' ? 'intention'), (g->'payload')::text);
end $$;

\echo '=== RESULTS ==='
\pset format unaligned
select lpad(n::text,2) || '  ' || rpad(result,6) || rpad(name, 62)
    || coalesce('  -> ' || left(replace(detail, chr(10), ' / '), 50), '')
from pg_temp.r order by n;
select E'\n' || count(*) filter (where result='PASS') || ' / ' || count(*) || ' passed'
from pg_temp.r;
rollback;
