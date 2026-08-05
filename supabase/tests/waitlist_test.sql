\set ON_ERROR_STOP on
begin;

-- ============================================================
-- قائمة الانتظار — the pipe, tested dry.
--
-- Nothing is switched on and nothing collects yet. What these
-- cases prove is that when production starts, the pipe fills with
-- the RIGHT thing: demand that knows which country it came from.
--
-- The mistake this suite exists to prevent is the tempting one —
-- inferring `waitlist` from geography. That column routes
-- M2 - Classify Track, so inferring it would silently move every
-- parent in an unsupported country onto a different track without
-- any of them asking.
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


\echo '=== NO ADDRESS, NO SIGNUP ==='
do $$
declare p uuid; res jsonb;
begin
  p := pg_temp.parent('wl-nowhere');           -- country never recorded
  res := public.join_waitlist(p);

  perform pg_temp.chk('a signup with no country is refused',
    (res->>'joined')::boolean is false and res->>'reason' = 'needs_country', res::text);
  perform pg_temp.chk('and nothing is written',
    (select waitlist from public.followers where id = p) is not true
    and (select waitlist_at from public.followers where id = p) is null,
    'demand with no address is the one number this must not produce');

  -- The caller asks, using the country buttons the purchase flow already has.
  perform public.record_country(p, 'TN');
  res := public.join_waitlist(p);
  perform pg_temp.chk('and once they say where, the signup goes through',
    (res->>'joined')::boolean and res->>'state' = 'unsupported', res::text);
end $$;


\echo '=== WE DO NOT ASK PEOPLE TO WAIT FOR WHAT THEY CAN HAVE ==='
do $$
declare p uuid; res jsonb;
begin
  p := pg_temp.parent('wl-supported', 'DZ');
  res := public.join_waitlist(p);

  perform pg_temp.chk('a parent where we already sell is not put on a list',
    (res->>'joined')::boolean is false and res->>'reason' = 'already_supported', res::text);
  perform pg_temp.chk('and is not flagged as waiting',
    (select waitlist from public.followers where id = p) is not true);
end $$;


\echo '=== THE FLAG MEANS "SOMEONE ASKED", NEVER "SOMEONE IS FOREIGN" ==='
do $$
declare p uuid;
begin
  -- Recording an unsupported country must NOT enrol anyone. This is the whole
  -- argument of the migration: `waitlist` routes M2 - Classify Track.
  p := pg_temp.parent('wl-passive');
  perform public.record_country(p, 'TN');

  perform pg_temp.chk('recording an unsupported country enrols NOBODY',
    (select waitlist from public.followers where id = p) is not true,
    'inferring it would move them to another track without asking');
  perform pg_temp.chk('and they do not appear in the demand',
    not exists (select 1 from public.v_waitlist_demand where country = 'TN'
                 and waiting > (select count(*) from public.followers
                                 where waitlist and country = 'TN')));
end $$;


\echo '=== TAPPING TWICE IS NOT TWO PEOPLE ==='
do $$
declare p uuid; t1 timestamptz;
begin
  p := pg_temp.parent('wl-twice', 'TN');
  perform public.join_waitlist(p);
  select waitlist_at into t1 from public.followers where id = p;

  perform public.join_waitlist(p);
  perform pg_temp.chk('a second tap keeps the FIRST timestamp',
    (select waitlist_at from public.followers where id = p) = t1,
    'when they asked is the fact worth having');
  perform pg_temp.chk('and counts once',
    (select waiting from public.v_waitlist_demand where country = 'TN') =
    (select count(*) from public.followers where waitlist and country = 'TN'));
end $$;


\echo '=== THE DEMAND READS AS A DECISION ==='
do $$
declare p uuid;
begin
  -- Three in one unsupported country, one in another.
  for i in 1..3 loop
    p := pg_temp.parent('wl-sy-' || i, 'SY');
    perform public.join_waitlist(p);
  end loop;
  p := pg_temp.parent('wl-tn-x', 'TN');
  perform public.join_waitlist(p);

  perform pg_temp.chk('the busiest unsupported country sorts first',
    (select country from public.v_waitlist_demand limit 1) = 'SY',
    (select country || '=' || waiting from public.v_waitlist_demand limit 1));
  perform pg_temp.chk('and it carries since-when, not just how-many',
    (select first_asked is not null and asked_last_30d = 3
       from public.v_waitlist_demand where country = 'SY'));
  perform pg_temp.chk('a supported country never appears as demand',
    not exists (select 1 from public.v_waitlist_demand where country = 'DZ'));
end $$;


\echo '=== WHEN A COUNTRY ARRIVES, THE LIST BECOMES A DEBT ==='
do $$
declare owed int;
begin
  -- SY is switched on. The people who asked are now owed the message.
  insert into public.supported_countries
    (code, name_ar, currency, price_subscription, price_comeback, price_continuation,
     price_display_full, price_display_short, price_continuation_display, is_active)
  values ('SY','سوريا','SYP', 1, 1, 1, 'ثمن الرحلة', 'ثمن الرحلة', 'ثمن المواصلة', true)
  on conflict (code) do update set is_active = true, price_display_full = 'ثمن الرحلة';

  select count(*) into owed from public.v_waitlist_owed_the_news where country = 'SY';
  perform pg_temp.chk('the three who asked move to the owed list',
    owed = 3, owed::text);
  perform pg_temp.chk('and they leave the demand — they are no longer a decision',
    not exists (select 1 from public.v_waitlist_demand where country = 'SY'),
    'one list is a decision, the other is a debt');
end $$;


\echo '=== WHAT THE PARENT IS TOLD ==='
do $$
declare m jsonb;
begin
  m := public.get_conversation_moment('menu_waitlist_joined', null);
  perform pg_temp.chk('no date is promised, because none is known',
    m->>'body' like '%لن أعدكم بموعد لا أعرفه%');
  perform pg_temp.chk('and the free product is named as complete, not as a trial',
    m->>'body' like '%ويبقى مجانياً%' and m->>'body' like '%وليس نسخة مصغّرة%',
    'honesty is the conversion tool here, not scarcity');
  perform pg_temp.chk('and there is a way out of the message',
    m->'buttons' @> '[{"cb":"other"}]'::jsonb);

  m := public.get_conversation_moment('menu_waitlist_ask_country', null);
  perform pg_temp.chk('asking where they are says why we are asking',
    m->>'body' like '%لسببين%');
end $$;


\echo '=== RESULTS ==='
\pset format unaligned
select lpad(n::text,2) || '  ' || rpad(result,6) || rpad(name, 60)
    || coalesce('  -> ' || left(replace(detail, chr(10), ' / '), 44), '')
from pg_temp.r order by n;
select E'\n' || count(*) filter (where result='PASS') || ' / ' || count(*) || ' passed'
from pg_temp.r;

rollback;
