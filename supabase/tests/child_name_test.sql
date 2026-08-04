\set ON_ERROR_STOP on
begin;

create table pg_temp.r (n int generated always as identity, name text, result text, detail text);
create or replace function pg_temp.chk(p_name text, p_cond boolean, p_detail text default null)
returns void language sql as $$
  insert into pg_temp.r (name, result, detail)
  values (p_name, case when p_cond then 'PASS' else 'FAIL' end, p_detail);
$$;

\echo '=== THE SHAPE GATE ==='
do $$
declare bad text;
begin
  perform pg_temp.chk('a real name passes', public.child_name_plausible('يوسف'));
  perform pg_temp.chk('a two-word name passes', public.child_name_plausible('عبد الرحمن'));

  foreach bad in array array[
    'الطفل','طفلي','ابني','بنتي','الصغيرة','أنا','زوجي'
  ] loop
    perform pg_temp.chk('relation word rejected: ' || bad,
      not public.child_name_plausible(bad));
  end loop;

  perform pg_temp.chk('a sentence is rejected',
    not public.child_name_plausible('ابني عمره أربع سنوات ويرفض النوم'));
  perform pg_temp.chk('digits rejected', not public.child_name_plausible('يوسف 4'));
  perform pg_temp.chk('punctuation rejected', not public.child_name_plausible('يوسف؟'));
  perform pg_temp.chk('latin rejected', not public.child_name_plausible('Youssef'));
  perform pg_temp.chk('empty rejected', not public.child_name_plausible('   '));
  perform pg_temp.chk('null rejected', not public.child_name_plausible(null));
  perform pg_temp.chk('one letter rejected', not public.child_name_plausible('ي'));
end $$;

\echo '=== COMMIT RULES ==='
do $$
declare p uuid; p2 uuid; res jsonb; c uuid;
begin
  insert into public.followers (platform_user_id, country) values ('cn-1','DZ') returning id into p;

  res := public.commit_child_name(p, 'يوسف', null, 'low');
  perform pg_temp.chk('low confidence refuses',
    not (res->>'committed')::boolean and res->>'reason' = 'low_confidence', res->>'reason');

  res := public.commit_child_name(p, 'ابني', null, 'high');
  perform pg_temp.chk('implausible name refuses',
    not (res->>'committed')::boolean and res->>'reason' = 'implausible_name', res->>'reason');

  res := public.commit_child_name(p, '  يوسف  ', 'أربع سنوات', 'high');
  perform pg_temp.chk('a confident plausible name commits, trimmed',
    (res->>'committed')::boolean and res->>'name' = 'يوسف', res->>'name');

  perform pg_temp.chk('it landed in children with the age note',
    exists (select 1 from public.children c2
             where c2.follower_id = p and c2.name = 'يوسف' and c2.age_note = 'أربع سنوات'));

  res := public.commit_child_name(p, 'سارة', null, 'high');
  perform pg_temp.chk('a second name NEVER overwrites the first',
    not (res->>'committed')::boolean and res->>'reason' = 'already_named', res->>'reason');
  perform pg_temp.chk('the original name is untouched',
    exists (select 1 from public.children c3 where c3.follower_id = p and c3.name = 'يوسف'));

  res := public.commit_child_name(gen_random_uuid(), 'يوسف', null, 'high');
  perform pg_temp.chk('unknown parent refuses',
    not (res->>'committed')::boolean and res->>'reason' = 'no_such_parent', res->>'reason');

  -- A nameless shell row must be filled, not duplicated.
  insert into public.followers (platform_user_id, country) values ('cn-2','EG') returning id into p2;
  insert into public.children (follower_id, name, is_primary) values (p2, 'الطفل', true);
  res := public.commit_child_name(p2, 'سارة', null, 'high');
  perform pg_temp.chk('a placeholder row is filled, not duplicated',
    (res->>'committed')::boolean
    and (select count(*) from public.children c4 where c4.follower_id = p2) = 1,
    'children rows: ' || (select count(*) from public.children c5 where c5.follower_id = p2));
end $$;

\echo '=== THE BATCH, AND WHAT IT UNBLOCKS ==='
do $$
declare p uuid; d jsonb; n int;
begin
  insert into public.followers (platform_user_id, country) values ('cn-3','DZ') returning id into p;
  insert into public.n8n_chat_histories (session_id, message) values
    ('cn-3', '{"type":"human","content":"يوسف ما يرقدش بكري"}'::jsonb),
    ('cn-3', '{"type":"ai","content":"رد آدم"}'::jsonb),
    ('cn-3', '{"type":"human","content":"كل ليلة نفس الشي"}'::jsonb);

  select count(*) into n from public.get_child_name_batch(50) b where b.parent_id = p;
  perform pg_temp.chk('an unnamed parent with conversation is in the batch', n = 1);

  perform pg_temp.chk('the batch carries only the parent''s own turns',
    (select b.transcript from public.get_child_name_batch(50) b where b.parent_id = p)
      not like '%رد آدم%',
    'ADAM''s replies would feed his own guesses back to him');

  -- depth before and after
  d := public.knowledge_depth(p);
  perform pg_temp.chk('depth is 0 before a name', (d->>'level')::int = 0);

  perform public.commit_child_name(p, 'يوسف', null, 'high');
  d := public.knowledge_depth(p);
  perform pg_temp.chk('depth becomes 1 once the name lands', (d->>'level')::int = 1,
    'this is what 298 of 299 live parents are missing');

  select count(*) into n from public.get_child_name_batch(50) b where b.parent_id = p;
  perform pg_temp.chk('a named parent leaves the batch', n = 0);
end $$;

\echo '=== RESULTS ==='
\pset format unaligned
select lpad(n::text,2) || '  ' || rpad(result,6) || rpad(name, 52)
    || coalesce('  -> ' || left(detail, 55), '')
from pg_temp.r order by n;
select E'\n' || count(*) filter (where result='PASS') || ' / ' || count(*) || ' passed'
from pg_temp.r;

rollback;
