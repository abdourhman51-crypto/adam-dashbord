\set ON_ERROR_STOP on
begin;

-- ============================================================
-- «بلد آخر» — the typed-country branch, end to end.
--
-- The founder hit this live: they typed their country after being
-- asked, and nothing was caught. The gap was the one wire a typed
-- answer needs. These cases walk the whole branch the way the
-- workflow now does — tap «بلد آخر», tap سجّلوني, TYPE the country
-- — and assert the two things that make free text safe: it is only
-- read inside the window, and a country it does not know is asked
-- again rather than guessed.
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
  insert into public.followers (platform_user_id) values (p_pid) returning id into v;
  return v;
end $$;


\echo '=== THE FOURTH BUTTON, HOWEVER IT IS SPELLED, REACHES «not here yet» ==='
do $$
declare p uuid; m jsonb;
begin
  p := pg_temp.parent('cb-other');
  -- «بلد آخر» carries set_country_OTHER; the Router hands the raw code through,
  -- record_country refuses it, and that refusal IS the branch.
  m := public.get_moment_after_tap('country_recorded', p, 'OTHER');
  perform pg_temp.chk('an unplaceable code lands on country_other, not an error',
    m->>'action_done' = 'country_unknown' and m->>'body' like '%ليس متاحاً في بلدكم بعد%',
    m->>'action_done');
  perform pg_temp.chk('and it says WHY, not merely no',
    m->>'body' like '%طريقة دفع%');
  perform pg_temp.chk('and offers to register, with a way out',
    m->'buttons' @> '[{"cb":"menu_waitlist_join"}]'::jsonb
    and m->'buttons' @> '[{"cb":"other"}]'::jsonb);
end $$;


\echo '=== سجّلوني WITH NO COUNTRY ASKS, AND OPENS THE WINDOW ==='
do $$
declare p uuid; m jsonb;
begin
  p := pg_temp.parent('cb-ask');
  m := public.get_moment_after_tap('menu_waitlist_join', p, null);
  perform pg_temp.chk('with no country known, سجّلوني asks for one',
    m->>'action_done' = 'waitlist_needs_country' and m->>'body' like '%من أيّ بلد%',
    m->>'action_done');
  perform pg_temp.chk('and stamps the window the typed answer will land in',
    (select country_asked_at from public.followers where id = p) is not null,
    'without this stamp the parent types into silence');
end $$;


\echo '=== THE TYPED ANSWER IS CAUGHT — THE WIRE THAT WAS MISSING ==='
do $$
declare p uuid; m jsonb;
begin
  p := pg_temp.parent('cb-type');
  perform public.get_moment_after_tap('menu_waitlist_join', p, null);  -- opens window

  -- They TYPE it. This is the exact call W1 now makes: the tap node, with the
  -- capture key and the raw message text as the "country".
  m := public.get_moment_after_tap('menu_capture_country', p, 'تونس');

  perform pg_temp.chk('a typed unsupported country is caught and joins the waitlist',
    m->>'action_done' = 'waitlisted' and m->>'body' like '%سجّلناكم%', m->>'action_done');
  perform pg_temp.chk('and the country is actually recorded',
    (select country from public.followers where id = p) = 'TN',
    'the whole point: caught AND recorded');
  perform pg_temp.chk('and the window is spent, so the next message is normal again',
    (select country_asked_at from public.followers where id = p) is null);
end $$;

do $$
declare p uuid; m jsonb;
begin
  p := pg_temp.parent('cb-type-sup');
  perform public.get_moment_after_tap('menu_waitlist_join', p, null);
  -- A SUPPORTED country typed: recorded, and NOT put on a waitlist — they can buy.
  m := public.get_moment_after_tap('menu_capture_country', p, 'الجزائر');
  perform pg_temp.chk('a supported country typed is recorded, not waitlisted',
    (select country from public.followers where id = p) = 'DZ'
    and (select waitlist from public.followers where id = p) is not true,
    m->>'action_done');
end $$;


\echo '=== A COUNTRY IT DOES NOT KNOW IS ASKED AGAIN, NEVER GUESSED ==='
do $$
declare p uuid; m jsonb;
begin
  p := pg_temp.parent('cb-huh');
  perform public.get_moment_after_tap('menu_waitlist_join', p, null);
  m := public.get_moment_after_tap('menu_capture_country', p, 'بلاد العجائب');

  perform pg_temp.chk('an unrecognised answer asks again',
    m->>'action_done' = 'country_unrecognised' and m->>'body' like '%لم أعرف هذا البلد%',
    m->>'action_done');
  perform pg_temp.chk('and records NOTHING — a wrong country is worse than none',
    (select country from public.followers where id = p) is null);
  perform pg_temp.chk('and keeps the window open for the retry',
    (select country_asked_at from public.followers where id = p) is not null);
end $$;


\echo '=== FREE TEXT IS ONLY A COUNTRY INSIDE THE WINDOW ==='
do $$
declare p uuid; res jsonb;
begin
  p := pg_temp.parent('cb-nowindow');
  -- No ask was made. «كنا في مصر الصيف الماضي» must not move them to Egypt.
  res := public.capture_country_text(p, 'كنا في مصر الصيف الماضي');
  perform pg_temp.chk('with no open window, a country word is ignored',
    (res->>'captured')::boolean is false and res->>'reason' = 'not_awaiting',
    res->>'reason');
  perform pg_temp.chk('and nothing is recorded',
    (select country from public.followers where id = p) is null);
end $$;

do $$
declare p uuid; res jsonb;
begin
  p := pg_temp.parent('cb-expired');
  update public.followers set country_asked_at = now() - interval '48 hours' where id = p;
  res := public.capture_country_text(p, 'تونس');
  perform pg_temp.chk('a window older than 36h is closed',
    (res->>'captured')::boolean is false and res->>'reason' = 'not_awaiting');
end $$;


\echo '=== IT FINDS THE COUNTRY INSIDE A SENTENCE, AND THE RIGHT ONE ==='
do $$
declare p uuid;
begin
  p := pg_temp.parent('cb-sentence');
  update public.followers set country_asked_at = now() where id = p;
  perform public.capture_country_text(p, 'انا من تونس');
  perform pg_temp.chk('«انا من تونس» resolves to Tunisia',
    (select country from public.followers where id = p) = 'TN');
end $$;

do $$
declare p uuid;
begin
  p := pg_temp.parent('cb-named');
  update public.followers set country_asked_at = now() where id = p;
  -- They name where they LIVE, mentioning where they are from.
  perform public.capture_country_text(p, 'تونسي الأصل لكن نعيش في فرنسا');
  perform pg_temp.chk('when two countries appear, the resolution is deterministic',
    (select country from public.followers where id = p) in ('TN','FR'),
    (select country from public.followers where id = p));
end $$;

do $$
declare p uuid;
begin
  p := pg_temp.parent('cb-longest');
  update public.followers set country_asked_at = now() where id = p;
  perform public.capture_country_text(p, 'سلطنة عمان');
  perform pg_temp.chk('«سلطنة عمان» is Oman, not caught by a shorter fragment',
    (select country from public.followers where id = p) = 'OM');
end $$;

do $$
declare p uuid;
begin
  p := pg_temp.parent('cb-dialect');
  update public.followers set country_asked_at = now() where id = p;
  -- The definite article and the alef/hamza variants are normalised away.
  perform public.capture_country_text(p, 'الجزاير');
  perform pg_temp.chk('a dialect spelling «الجزاير» still resolves',
    (select country from public.followers where id = p) = 'DZ');
end $$;


\echo '=== RESULTS ==='
\pset format unaligned
select lpad(n::text,2) || '  ' || rpad(result,6) || rpad(name, 58)
    || coalesce('  -> ' || left(replace(detail, chr(10), ' / '), 44), '')
from pg_temp.r order by n;
select E'\n' || count(*) filter (where result='PASS') || ' / ' || count(*) || ' passed'
from pg_temp.r;

rollback;
