\set ON_ERROR_STOP on
begin;

-- ============================================================
-- «بلد آخر» — the fourth country button, and what it opens.
--
-- The branch that reached nothing: the buttons offered three
-- markets and «بلد آخر», and tapping the fourth fell through to
-- the rescue. Now it explains WHY, offers the waitlist, and reads
-- the country the parent TYPES.
--
-- Two things make free text safe, and both are tested: an answer
-- is only read inside the window after ADAM asked, and an
-- unrecognised answer is refused rather than guessed. Recording
-- the wrong country is worse than recording none — it puts a
-- family in a market they cannot buy in.
-- ============================================================

create table pg_temp.r (n int generated always as identity, name text, result text, detail text);
create or replace function pg_temp.chk(p_name text, p_cond boolean, p_detail text default null)
returns void language sql as $$
  insert into pg_temp.r (name, result, detail)
  values (p_name, case when p_cond then 'PASS' else 'FAIL' end, p_detail);
$$;

create or replace function pg_temp.parent(p_pid text, p_country text default null)
returns uuid language plpgsql as $$
declare v uuid;
begin
  insert into public.followers (platform_user_id, country) values (p_pid, p_country) returning id into v;
  return v;
end $$;


\echo '=== ANY UNKNOWN COUNTRY BUTTON IS «بلد آخر», HOWEVER SPELLED ==='
do $$
declare p uuid; m jsonb;
begin
  -- The Router turns «بلد آخر» into an unrecognised code. record_country refuses
  -- it, and that refusal IS the signal — one branch, no per-country wiring.
  p := pg_temp.parent('co-btn');
  m := public.get_moment_after_tap('menu_tap', p, 'OTHER');

  perform pg_temp.chk('an unplaceable country resolves to the «بلد آخر» moment',
    m->>'action_done' = 'country_unknown'
    and m->>'body' like '%آدم ليس متاحاً في بلدكم بعد%', m->>'action_done');
  perform pg_temp.chk('and it says WHY, not just no',
    m->>'body' like '%طريقة دفع%',
    'the honesty is what keeps the free tier from reading as a consolation prize');
  perform pg_temp.chk('and it offers the waitlist and a way out',
    (select buttons @> '[{"cb":"menu_waitlist_join"}]'::jsonb
        and buttons @> '[{"cb":"other"}]'::jsonb
     from public.conversation_moments where key = 'country_other'));
end $$;


\echo '=== سجّلوني OPENS THE WINDOW THEY WILL TYPE INTO ==='
do $$
declare p uuid; m jsonb;
begin
  p := pg_temp.parent('co-ask');    -- no country yet
  m := public.get_moment_after_tap('menu_waitlist_join', p, null);

  perform pg_temp.chk('tapping سجّلوني with no country asks for one',
    m->>'action_done' = 'waitlist_needs_country', m->>'action_done');
  perform pg_temp.chk('and STAMPS the window — without it their answer is not_awaiting',
    (select country_asked_at is not null from public.followers where id = p),
    'the ask and the window that reads it must be the same act');
end $$;


\echo '=== THE WHOLE FLOW, ONE PARENT, END TO END ==='
do $$
declare p uuid; m jsonb; res jsonb;
begin
  p := pg_temp.parent('co-flow');
  perform public.get_moment_after_tap('menu_waitlist_join', p, null);   -- window open

  res := public.capture_country_text(p, 'انا من تونس');
  perform pg_temp.chk('their typed country is caught out of a whole sentence',
    (res->>'captured')::boolean and res->>'code' = 'TN',
    'انا من تونس — the country is named inside the words, not alone');
  perform pg_temp.chk('and unsupported, so the same call puts them on the list',
    (res->>'joined')::boolean and res->>'state' = 'unsupported');
  perform pg_temp.chk('the country is recorded',
    (select country from public.followers where id = p) = 'TN');
  perform pg_temp.chk('and the window is spent, so a later message is not a second answer',
    (select country_asked_at is null from public.followers where id = p));
  perform pg_temp.chk('and they appear in the demand, with an address',
    exists (select 1 from public.v_waitlist_demand where country = 'TN'));
end $$;


\echo '=== SPELLINGS A TIRED PARENT ACTUALLY TYPES ==='
do $$
declare p uuid;
  procedure_note text;
begin
  -- Each is asked fresh, since capture spends the window.
  for procedure_note in select unnest(array['x']) loop null; end loop;
end $$;

do $$
declare p uuid;
begin
  p := pg_temp.parent('sp-1'); update public.followers set country_asked_at = now() where id = p;
  perform pg_temp.chk('«الجزاير» (dialect) resolves to DZ',
    (public.capture_country_text(p, 'الجزاير')->>'code') = 'DZ');

  p := pg_temp.parent('sp-2'); update public.followers set country_asked_at = now() where id = p;
  perform pg_temp.chk('«سلطنة عمان» beats the shorter «عمان» — longest match wins',
    (public.capture_country_text(p, 'نعيش في سلطنة عمان')->>'code') = 'OM');

  p := pg_temp.parent('sp-3'); update public.followers set country_asked_at = now() where id = p;
  perform pg_temp.chk('a bare code like «SA» is understood',
    (public.capture_country_text(p, 'SA')->>'code') = 'SA');

  p := pg_temp.parent('sp-4'); update public.followers set country_asked_at = now() where id = p;
  perform pg_temp.chk('«غزة» resolves to PS — the name people use',
    (public.capture_country_text(p, 'غزة')->>'code') = 'PS');
end $$;


\echo '=== NEVER GUESSED, NEVER OUT OF WINDOW ==='
do $$
declare p uuid; res jsonb;
begin
  p := pg_temp.parent('ng-1'); update public.followers set country_asked_at = now() where id = p;
  res := public.capture_country_text(p, 'بلاد العجائب');
  perform pg_temp.chk('an unrecognised place is refused, not guessed',
    (res->>'captured')::boolean is false and res->>'reason' = 'unrecognised',
    'recording the wrong country is worse than recording none');
  perform pg_temp.chk('and the window stays OPEN so they can try again',
    (select country_asked_at is not null from public.followers where id = p));
end $$;

do $$
declare p uuid; res jsonb;
begin
  -- A country mentioned with no ask pending must never move a family.
  p := pg_temp.parent('ng-2', 'DZ');
  res := public.capture_country_text(p, 'كنا في مصر الصيف الماضي');
  perform pg_temp.chk('a place named with no ask pending changes nothing',
    (res->>'captured')::boolean is false and res->>'reason' = 'not_awaiting',
    'otherwise a holiday story would relocate the family');
  perform pg_temp.chk('and the country they were is untouched',
    (select country from public.followers where id = p) = 'DZ');
end $$;

do $$
declare p uuid; res jsonb;
begin
  -- The window closes after 36 hours.
  p := pg_temp.parent('ng-3');
  update public.followers set country_asked_at = now() - interval '40 hours' where id = p;
  res := public.capture_country_text(p, 'تونس');
  perform pg_temp.chk('an answer two days after the ask is stale, not accepted',
    res->>'reason' = 'not_awaiting');
end $$;


\echo '=== A SUPPORTED COUNTRY, TYPED, IS NOT PUT ON A LIST ==='
do $$
declare p uuid; res jsonb;
begin
  p := pg_temp.parent('sup'); update public.followers set country_asked_at = now() where id = p;
  res := public.capture_country_text(p, 'مصر');
  perform pg_temp.chk('typing a country we sell in records it and does NOT waitlist',
    (res->>'captured')::boolean and res->>'code' = 'EG'
    and res->>'reason' = 'already_supported',
    'they can have it today — no list');
  perform pg_temp.chk('and they are not flagged as waiting',
    (select waitlist from public.followers where id = p) is not true);
end $$;


\echo '=== THE ALIAS TABLE IS CLEAN ==='
do $$
begin
  perform pg_temp.chk('every alias points at a country we can put on a clock',
    not exists (select 1 from public.country_aliases a
                 where not exists (select 1 from public.country_timezone ct where ct.code = a.code)),
    'the cleanup after the generous seed is the integrity guarantee, not an FK');
end $$;


\echo '=== RESULTS ==='
\pset format unaligned
select lpad(n::text,2) || '  ' || rpad(result,6) || rpad(name, 60)
    || coalesce('  -> ' || left(replace(detail, chr(10), ' / '), 44), '')
from pg_temp.r order by n;
select E'\n' || count(*) filter (where result='PASS') || ' / ' || count(*) || ' passed'
from pg_temp.r;

rollback;
