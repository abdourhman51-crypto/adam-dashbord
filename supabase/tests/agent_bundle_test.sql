\set ON_ERROR_STOP on
begin;

-- ============================================================
-- ONE CALL PER NODE.
--
-- Three nodes were added through the n8n MCP API and none could
-- authenticate; Tap - Record Country had been discarding every
-- country a parent tapped for two days. The number of
-- Supabase-authenticated nodes in W1 cannot go up, so these two
-- functions let existing calls carry more instead.
-- ============================================================

create table pg_temp.r (n int generated always as identity, name text, result text, detail text);
create or replace function pg_temp.chk(p_name text, p_cond boolean, p_detail text default null)
returns void language sql as $$
  insert into pg_temp.r (name, result, detail)
  values (p_name, case when p_cond then 'PASS' else 'FAIL' end, p_detail);
$$;

create or replace function pg_temp.parent(p_country text) returns uuid
language plpgsql as $$
declare v uuid;
begin
  insert into public.followers (platform_user_id, country)
  values (gen_random_uuid()::text, p_country) returning id into v;
  return v;
end $$;

create or replace function pg_temp.spoke(p_parent uuid, p_n int) returns void
language plpgsql as $$
declare k text;
begin
  select platform_user_id into k from public.followers where id = p_parent;
  insert into public.n8n_chat_histories (session_id, message)
  select k, jsonb_build_object('type','human','content','x') from generate_series(1, p_n);
end $$;

\echo '=== THE AGENT FINALLY RECEIVES THE FAMILY ==='
do $$
declare p uuid; b jsonb;
begin
  p := pg_temp.parent('DZ');
  insert into public.children (follower_id, name, is_primary) values (p, 'مالك', true);

  b := public.get_agent_bundle(p);

  perform pg_temp.chk('the child ADAM is talking about is in the bundle',
    (b->>'family_context') like '%مالك%', left(b->>'family_context', 90));

  -- Internal bookkeeping handed to a language model is vocabulary it is
  -- forbidden to use (P24).
  perform pg_temp.chk('PLAN_DAY and DAYS_LEFT never reach the model',
    (b->>'family_context') !~ '(PLAN_DAY|DAYS_LEFT)', b->>'family_context');

  -- Without the frame the model reads its own notes as the parent's words.
  perform pg_temp.chk('the context is framed as OUR notes, not as something they said',
    (b->>'family_context') like '%لم يقلها الأهل الآن%', left(b->>'family_context',80));

  perform pg_temp.chk('and it says what ADAM may CLAIM to know, not a bare number',
    (b->>'family_context') like '%ما يُسمح لك أن تدّعي معرفته%'
    and (b->>'family_context') like '%تعرف اسم الطفل فقط%', left(b->>'family_context',120));
end $$;

\echo '=== A STRANGER IS NOT SPOKEN TO AS IF REMEMBERED ==='
do $$
declare p uuid; b jsonb;
begin
  p := pg_temp.parent('DZ');
  b := public.get_agent_bundle(p);

  perform pg_temp.chk('level 0 is stated as knowing nothing',
    (b->>'knowledge_level')::int = 0, b->>'knowledge_level');
  -- The failure mode this exists to stop: a warm machine implying memory
  -- it does not have, which is the enemy wearing the product's own face.
  -- Wording rewritten 2026-08-11 (docs/adam-under-the-microscope.md, the
  -- ADAM Contract) to name the forbidden move explicitly, in the same
  -- terms gate_grounded_reply enforces at the gate; the underlying rule
  -- (do not imply memory or repetition that does not exist) is unchanged
  -- and is now also guaranteed by the gate, not only advised by the prompt.
  perform pg_temp.chk('and the model is told explicitly not to imply memory or repetition',
    (b->>'family_context') like '%ممنوع%' and (b->>'family_context') like '%تكرار%',
    b->>'family_context');
  perform pg_temp.chk('an unknown family is named as unknown, not left blank',
    (b->>'family_context') like '%لا شيء مسجّل عن هذا البيت بعد%', b->>'family_context');

  perform pg_temp.chk('a null parent does not throw — the agent still answers',
    (public.get_agent_bundle(null)->>'ask')::boolean = false);
end $$;

\echo '=== THE COUNTRY QUESTION RIDES ON THE SAME CALL ==='
do $$
declare p uuid; b jsonb; b2 jsonb;
begin
  p := pg_temp.parent('ZZ');
  perform pg_temp.spoke(p, 4);

  b := public.get_agent_bundle(p);
  perform pg_temp.chk('an engaged parent we cannot place is asked, in the bundle',
    (b->>'ask')::boolean and (b->>'ask_body') like '%من أي بلد أنتم؟%', b->>'ask_body');
  perform pg_temp.chk('and the buttons come with it, escape hatch included',
    jsonb_array_length(b->'ask_buttons') = 5
    and (b->'ask_buttons') @> '[{"cb":"other"}]'::jsonb, (b->'ask_buttons')::text);

  -- The claim now happens once per turn, on a hot path. It must still be once.
  b2 := public.get_agent_bundle(p);
  perform pg_temp.chk('a second turn does not ask again',
    not (b2->>'ask')::boolean and b2->>'ask_body' is null, b2::text);

  perform pg_temp.chk('a parent we can place is never asked',
    not (public.get_agent_bundle(pg_temp.parent('DZ'))->>'ask')::boolean);
end $$;

\echo '=== THE TAP RECORDS BEFORE IT ANSWERS ==='
do $$
declare p uuid; m jsonb;
begin
  p := pg_temp.parent('ZZ');

  -- Order is the whole point: if the moment were composed first, the
  -- confirmation would quote the country they had BEFORE the tap.
  m := public.get_moment_after_tap('country_recorded', p, 'DZ');
  perform pg_temp.chk('the tapped country is written before the answer is composed',
    (m->>'body') like '%الجزائر%' and (m->>'body') like '%2,300 دينار جزائري%',
    m->>'body');
  perform pg_temp.chk('and it is actually persisted',
    (select country from public.followers where id = p) = 'DZ');
  perform pg_temp.chk('the write is reported back for the log',
    (m->'country_recorded'->>'ok')::boolean, (m->'country_recorded')::text);

  -- A tap with no country must behave exactly as the old node did.
  m := public.get_moment_after_tap('menu_progress', p, null);
  perform pg_temp.chk('an ordinary tap is unaffected',
    (m->>'found')::boolean and m->'country_recorded' = 'null'::jsonb, m::text);

  -- «بلد آخر» sends no code. We must not invent one.
  m := public.get_moment_after_tap('country_other', p, '');
  perform pg_temp.chk('an empty code writes nothing and still answers',
    (m->>'found')::boolean
    and (select country from public.followers where id = p) = 'DZ', m->>'body');
end $$;

\echo '=== A COUNTRY WE CANNOT PLACE IS REFUSED, AND SAID HONESTLY ==='
do $$
declare p uuid; m jsonb;
begin
  p := pg_temp.parent('ZZ');
  m := public.get_moment_after_tap('country_recorded', p, 'XX');

  perform pg_temp.chk('an unplaceable code is refused, not stored',
    (m->'country_recorded'->>'reason') = 'unknown_code'
    and (select coalesce(country,'') from public.followers where id = p) = 'ZZ',
    (m->'country_recorded')::text);
  -- P11: having failed to record it, ADAM must not claim he did. An unplaceable
  -- code is «بلد آخر», so the answer is now the honest unavailable-here offer
  -- (20260807270000) rather than a bare "not recognised" — but the invariant is
  -- the same: it never says it saved a country.
  perform pg_temp.chk('and the answer does not pretend the country was recorded',
    (m->>'body') not like '%سجّلنا%' and (m->>'action_done') = 'country_unknown',
    m->>'body');
end $$;

\echo '=== RESULTS ==='
\pset format unaligned
select lpad(n::text,2) || '  ' || rpad(result,6) || rpad(name, 62)
    || coalesce('  -> ' || left(replace(detail, chr(10), ' / '), 54), '')
from pg_temp.r order by n;
select E'\n' || count(*) filter (where result='PASS') || ' / ' || count(*) || ' passed'
from pg_temp.r;

rollback;
