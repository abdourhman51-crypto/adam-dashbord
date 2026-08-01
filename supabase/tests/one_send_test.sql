\set ON_ERROR_STOP on
begin;

create table pg_temp.r (n int generated always as identity, name text, result text, detail text);
create or replace function pg_temp.chk(p_name text, p_cond boolean, p_detail text default null)
returns void language sql as $$
  insert into pg_temp.r (name, result, detail)
  values (p_name, case when p_cond then 'PASS' else 'FAIL' end, p_detail);
$$;

\echo '=== NO KEY MAY RESOLVE TO SILENCE (spec E9) ==='
do $$
declare p uuid; k text; m jsonb; bad text[] := '{}';
begin
  insert into public.followers (platform_user_id, country) values ('os-1','DZ') returning id into p;

  -- Every key in the table, for a parent who has told us nothing at all.
  -- This is the harshest case: if a body composes here, it composes anywhere.
  for k in select key from public.conversation_moments order by key loop
    m := public.get_conversation_moment(k, p);
    if coalesce((m->>'found')::boolean, false)
       and coalesce((m->>'allowed')::boolean, true)
       and coalesce(btrim(m->>'body'), '') = '' then
      bad := bad || k;
    end if;
  end loop;

  perform pg_temp.chk('no moment returns found+allowed with an empty body',
    cardinality(bad) = 0, array_to_string(bad, ', '));
end $$;

\echo '=== THE THREE NEW MOMENTS ==='
do $$
declare m jsonb;
begin
  m := public.get_conversation_moment('welcome_back', null);
  perform pg_temp.chk('welcome_back exists and is two lines',
    (m->>'found')::boolean and public.content_line_count(m->>'body') = 2, m->>'body');
  perform pg_temp.chk('welcome_back does not recap the absence',
    (m->>'body') not like '%اشتقنا%' and (m->>'body') not like '%غبت%');

  m := public.get_conversation_moment('media_unsupported', null);
  perform pg_temp.chk('media_unsupported exists', (m->>'found')::boolean, m->>'body');

  m := public.get_conversation_moment('first_contact', null);
  perform pg_temp.chk('first_contact tells her exactly one thing to do',
    (m->>'body') like '%احكِ لي ما حدث اليوم%', m->>'body');
  perform pg_temp.chk('first_contact no longer points at a surface',
    (m->>'body') not like '%☰%', 'L1: one action, and it is typing');

  m := public.get_conversation_moment('menu_open_question', null);
  perform pg_temp.chk('«شيء آخر» is one open line, not a list',
    public.content_line_count(m->>'body') = 1, m->>'body');
end $$;

\echo '=== /child AND /progress MUST NOT SAY THE SAME THING ==='
do $$
declare p uuid; c uuid; a text; b text; s jsonb;
begin
  insert into public.followers (platform_user_id, country) values ('os-2','DZ') returning id into p;

  -- empty state first
  a := public.compose_menu_body('menu_child', p);
  b := public.compose_menu_body('menu_progress', p);
  perform pg_temp.chk('/child on an unknown child asks, and does not fake knowledge',
    a like '%لم نتعرّف على طفلك بعد%', a);
  perform pg_temp.chk('/child and /progress differ when nothing is known', a is distinct from b);

  -- now a real family
  insert into public.children (follower_id, name, is_primary) values (p, 'يوسف', true) returning id into c;
  update public.children set age_note = 'أربع سنوات' where id = c;
  insert into public.situations (child_id, key, status, evidence_count)
    values (c, 'sleep', 'confirmed', 4);
  insert into public.child_patterns (child_id, pattern_label, status, evidence_count, safe_for_record)
    values (c, 'يهدأ حين نبدأ مبكراً.', 'confirmed', 3, true);
  insert into public.daily_logs (follower_id, log_date, night_result) values
    (p, current_date,     'calm'),
    (p, current_date - 1, 'calm'),
    (p, current_date - 2, 'hard'),
    (p, current_date - 3, 'calm'),
    (p, current_date - 9, 'calm');

  a := public.compose_menu_body('menu_child', p);
  b := public.compose_menu_body('menu_progress', p);

  perform pg_temp.chk('/child names the child and the age', a like '%يوسف%' and a like '%أربع سنوات%', a);
  perform pg_temp.chk('/child names the hard moment', a like '%الأصعب عادةً%', a);
  perform pg_temp.chk('/child reads back only a safe_for_record pattern',
    a like '%يهدأ حين نبدأ مبكراً%', a);
  perform pg_temp.chk('/child stays within three lines', public.content_line_count(a) <= 3, a);

  perform pg_temp.chk('/progress compares two weeks, it does not count',
    b like '%هذا الأسبوع%' and b like '%الأسبوع الماضي%', b);
  perform pg_temp.chk('/progress states the direction', b like '%الاتجاه يتحسّن%', b);
  perform pg_temp.chk('/child and /progress are different sentences', a <> b);

  -- and neither may repeat the pinned message
  s := public.get_telegram_surface(p);
  perform pg_temp.chk('/progress is not the pinned progress line',
    b <> (s->>'progress_line'), s->>'progress_line');
end $$;

\echo '=== A WORSE WEEK IS STATED, NOT SOFTENED AWAY ==='
do $$
declare p uuid; b text;
begin
  insert into public.followers (platform_user_id, country) values ('os-3','DZ') returning id into p;
  insert into public.daily_logs (follower_id, log_date, night_result) values
    (p, current_date,      'hard'),
    (p, current_date - 1,  'hard'),
    (p, current_date - 2,  'hard'),
    (p, current_date - 8,  'calm'),
    (p, current_date - 9,  'calm');
  b := public.compose_menu_body('menu_progress', p);
  perform pg_temp.chk('a harder week is said plainly and then carried',
    b like '%أصعب%' and b like '%نكمل%', b);
end $$;

\echo '=== LEGACY BUTTONS STILL ON PHONES MUST ANSWER ==='
do $$
declare p uuid; k text; m jsonb;
begin
  insert into public.followers (platform_user_id, country) values ('os-4','DZ') returning id into p;
  insert into public.daily_logs (follower_id, log_date, night_result) values (p, current_date, 'calm');

  foreach k in array array['menu_next_goal','menu_journey_progress','menu_lighten_load'] loop
    m := public.get_conversation_moment(k, p);
    perform pg_temp.chk('stale button answers: ' || k,
      (m->>'found')::boolean and btrim(coalesce(m->>'body','')) <> '', m->>'body');
  end loop;
end $$;

\echo '=== THE PINNED MESSAGE STATES, IT DOES NOT INSTRUCT (L3) ==='
do $$
declare p uuid; s jsonb;
begin
  insert into public.followers (platform_user_id, country) values ('os-5','DZ') returning id into p;
  s := public.get_telegram_surface(p);

  perform pg_temp.chk('the pin is two lines',
    jsonb_array_length(s->'pinned'->'lines') = 2, s->'pinned'->>'text');
  perform pg_temp.chk('the pin carries no instruction',
    (s->'pinned'->>'text') not like '%اضغط%', s->'pinned'->>'text');
  perform pg_temp.chk('the in-chat menu is gone',
    jsonb_array_length(s->'menu') = 0);
  perform pg_temp.chk('the reply keyboard stays gone',
    jsonb_array_length(s->'keyboard') = 0);
end $$;

\echo '=== SUPPRESSION IS STILL SILENT (L4) ==='
do $$
declare p uuid; s jsonb; m jsonb;
begin
  insert into public.followers (platform_user_id, country) values ('os-6','DZ') returning id into p;
  insert into public.parent_strain (parent_id, level) values (p, 2);

  s := public.get_telegram_surface(p);
  perform pg_temp.chk('strain L2 blocks commerce', not (s->'modifiers'->>'commerce_allowed')::boolean);
  perform pg_temp.chk('and says so nowhere in the pin',
    (s->'pinned'->>'text') not like '%الحمل%' and (s->'pinned'->>'text') not like '%الحِمل%',
    s->'pinned'->>'text');

  m := public.get_conversation_moment('menu_journey', p);
  perform pg_temp.chk('the journey is withheld without a reason being given',
    (m->>'found')::boolean and not (m->>'allowed')::boolean
    and coalesce(m->>'body','') = '', m->>'reason');
end $$;

\echo '=== RESULTS ==='
\pset format unaligned
select lpad(n::text,2) || '  ' || rpad(result,6) || rpad(name, 58)
    || coalesce('  -> ' || left(replace(detail, chr(10), ' / '), 60), '')
from pg_temp.r order by n;
select E'\n' || count(*) filter (where result='PASS') || ' / ' || count(*) || ' passed'
from pg_temp.r;

rollback;
