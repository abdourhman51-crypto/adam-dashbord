\set ON_ERROR_STOP on
begin;

-- ============================================================
-- THREE COUNTRIES, AND THE THIRD ANSWER.
--
-- The offer is live in الجزائر، مصر، المغرب and nowhere else.
-- Everything here defends two things at once:
--
--   1. that the list is exactly three, enforced in one place;
--   2. that "we do not sell here" and "we do not know where you
--      are" never again produce the same sentence.
--
-- The second one is what shipped broken for the product's whole
-- life: 59 of 301 parents — one in five — were told the offer
-- had not reached their country, about a country nobody knew.
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

\echo '=== THREE STATES, AND NEVER A FOURTH ==='
do $$
declare dz uuid; sa uuid; sy uuid; zz uuid; mt uuid; nl uuid; xx uuid; gone uuid;
begin
  dz   := pg_temp.parent('DZ');    -- sells
  sa   := pg_temp.parent('SA');    -- known, row exists, is_active false
  sy   := pg_temp.parent('SY');    -- known, no row at all
  zz   := pg_temp.parent('ZZ');    -- the placeholder
  mt   := pg_temp.parent('');      -- empty string
  nl   := pg_temp.parent(null);    -- never set
  xx   := pg_temp.parent('XX');    -- well-formed, not a place we know
  gone := gen_random_uuid();       -- no such parent

  perform pg_temp.chk('a supported country is supported',
    public.country_state(dz)->>'state' = 'supported', public.country_state(dz)::text);
  perform pg_temp.chk('an inactive row is unsupported, not unknown',
    public.country_state(sa)->>'state' = 'unsupported', public.country_state(sa)::text);
  perform pg_temp.chk('no row at all is also unsupported — we know where they are',
    public.country_state(sy)->>'state' = 'unsupported', public.country_state(sy)::text);

  -- The whole point of the migration.
  perform pg_temp.chk('ZZ is unknown, never unsupported',
    public.country_state(zz)->>'state' = 'unknown', public.country_state(zz)::text);
  perform pg_temp.chk('an empty country is unknown',
    public.country_state(mt)->>'state' = 'unknown', public.country_state(mt)::text);
  perform pg_temp.chk('a null country is unknown',
    public.country_state(nl)->>'state' = 'unknown', public.country_state(nl)::text);
  perform pg_temp.chk('a code we cannot put on a clock is unknown',
    public.country_state(xx)->>'state' = 'unknown', public.country_state(xx)::text);

  perform pg_temp.chk('the state is always one of exactly three',
    (select bool_and((public.country_state(f.id)->>'state') in ('supported','unsupported','unknown'))
     from public.followers f));

  -- security definer + a parent that does not exist must not error.
  perform pg_temp.chk('a parent who does not exist is unknown, not an exception',
    coalesce(public.country_state(gone)->>'state','unknown') = 'unknown',
    public.country_state(gone)::text);

  -- A price only ever accompanies a supported state.
  perform pg_temp.chk('no price is ever returned for a state that cannot buy',
    (select bool_and(case when (public.country_state(f.id)->>'state') <> 'supported'
                          then (public.country_state(f.id)->>'price') is null
                          else true end)
     from public.followers f));
end $$;

\echo '=== THE LIST IS THREE, AND IT LIVES IN ONE PLACE ==='
do $$
declare sellable text[]; qa uuid;
begin
  select array_agg(code order by code) into sellable
  from public.supported_countries
  where coalesce(is_active,false) and price_display_full is not null;

  perform pg_temp.chk('exactly الجزائر، مصر، المغرب are sellable',
    sellable = array['DZ','EG','MA'], array_to_string(sellable, ','));

  -- Adding a fourth must be a row, not a deploy. Prove it by adding one.
  insert into public.country_timezone (code, iana_tz) values ('QA','Asia/Qatar');
  insert into public.supported_countries (code, name_ar, is_active, price_display_full)
  values ('QA','قطر', true, '90 ريالاً قطرياً');
  -- The write and the read MUST be separate statements. country_state is
  -- STABLE, so inside one statement it reads that statement's snapshot —
  -- taken before the volatile insert nested in the same expression ran.
  -- Written as one line this fails, and it fails looking exactly like a
  -- product bug.
  qa := pg_temp.parent('QA');
  perform pg_temp.chk('a fourth country needs no code change — a row is enough',
    public.country_state(qa)->>'state' = 'supported', public.country_state(qa)::text);
  delete from public.followers where id = qa;
  delete from public.supported_countries where code = 'QA';
  delete from public.country_timezone where code = 'QA';
end $$;

\echo '=== /journey ANSWERS ALL THREE, AND SAYS ONLY WHAT IS TRUE ==='
do $$
declare dz uuid; sa uuid; zz uuid; j jsonb; cbs text[];
begin
  dz := pg_temp.parent('DZ'); sa := pg_temp.parent('SA'); zz := pg_temp.parent('ZZ');

  -- supported
  j := public.get_conversation_moment('menu_journey', dz);
  perform pg_temp.chk('a supported parent is told the price of their own country',
    (j->>'body') like '%2,300 دينار جزائري%', j->>'body');
  perform pg_temp.chk('and the free relationship is named as permanent, first',
    position('مجاناً، دائماً' in (j->>'body'))
      < position('الرحلة الواحدة' in (j->>'body')), j->>'body');
  perform pg_temp.chk('the price answer carries no buttons — فريق آدم is the only next step',
    coalesce(j->'buttons', '[]'::jsonb) = '[]'::jsonb, (j->'buttons')::text);
  perform pg_temp.chk('and it hands them a human, not a checkout',
    (j->>'body') like '%https://t.me/Abdouleg%', j->>'body');

  -- unsupported
  j := public.get_conversation_moment('menu_journey', sa);
  perform pg_temp.chk('an unsupported parent is told the real reason, not a vague soon',
    (j->>'body') like '%طريقة دفع محلية%', j->>'body');
  perform pg_temp.chk('and is never shown a number',
    (j->>'body') !~ '[0-9٠-٩]', j->>'body');
  perform pg_temp.chk('and keeps the identical free experience, said out loud',
    (j->>'body') like '%دون نقص%', j->>'body');
  select array_agg(x->>'cb') into cbs from jsonb_array_elements(j->'buttons') x;
  perform pg_temp.chk('the only offer made is to be told when it arrives',
    cbs @> array['waitlist_join'] and cbs @> array['other'], array_to_string(cbs,','));

  -- unknown: the branch that did not exist
  j := public.get_conversation_moment('menu_journey', zz);
  perform pg_temp.chk('an unknown parent is ASKED, not told',
    (j->>'body') like '%من أي بلد أنتم؟', j->>'body');
  perform pg_temp.chk('and is never told the offer has not reached a country we do not know',
    (j->>'body') not like '%لم تصل بلدكم بعد%', j->>'body');
  perform pg_temp.chk('and is never shown a price for a country we cannot name',
    (j->>'body') !~ '(دينار|جنيه|درهم|ريال)', j->>'body');
  select array_agg(x->>'cb') into cbs from jsonb_array_elements(j->'buttons') x;
  perform pg_temp.chk('the three countries are offered as taps, plus an honest fourth',
    cbs = array['set_country_DZ','set_country_EG','set_country_MA','set_country_OTHER'],
    array_to_string(cbs,','));
  perform pg_temp.chk('the question is one line the parent can answer without typing',
    (select count(*) from jsonb_array_elements(j->'buttons')) = 4);

  -- P1: crisis outranks every commercial answer, in all three states.
  insert into public.parent_strain (parent_id, level) values (dz, 2), (sa, 2), (zz, 2);
  perform pg_temp.chk('strain suppresses the journey answer whatever the country',
    coalesce((public.get_conversation_moment('menu_journey', dz)->>'allowed')::boolean, true) = false
    and coalesce((public.get_conversation_moment('menu_journey', sa)->>'allowed')::boolean, true) = false
    and coalesce((public.get_conversation_moment('menu_journey', zz)->>'allowed')::boolean, true) = false,
    public.get_conversation_moment('menu_journey', zz)::text);
end $$;

\echo '=== A PARENT NAMING THEIR COUNTRY OUTRANKS OUR GUESS ==='
do $$
declare p uuid; res jsonb; b text;
begin
  p := pg_temp.parent('ZZ');

  res := public.record_country(p, 'DZ');
  perform pg_temp.chk('a recorded country is accepted', (res->>'ok')::boolean, res::text);
  perform pg_temp.chk('and takes effect immediately',
    public.country_state(p)->>'state' = 'supported', public.country_state(p)::text);

  -- Unlike the child's name, this one is overwritable: families move, and
  -- what we held was a locale guess, not something they told us.
  res := public.record_country(p, 'MA');
  perform pg_temp.chk('a later answer REPLACES the earlier one',
    (res->>'ok')::boolean
    and (select country from public.followers where id = p) = 'MA', res::text);

  -- Same trap as above: the write goes in its own statement, then the read.
  res := public.record_country(p, '  eg ');
  perform pg_temp.chk('a lowercase or padded code still lands',
    (res->>'ok')::boolean
    and (select country from public.followers where id = p) = 'EG',
    (select country from public.followers where id = p));

  perform pg_temp.chk('ZZ is refused rather than stored',
    (public.record_country(p, 'ZZ')->>'reason') = 'unknown_code');
  perform pg_temp.chk('a code we cannot put on a clock is refused',
    (public.record_country(p, 'XX')->>'reason') = 'unknown_code');
  perform pg_temp.chk('an empty answer is refused',
    (public.record_country(p, '   ')->>'reason') = 'unknown_code');
  perform pg_temp.chk('a refusal does not damage what we already knew',
    (select country from public.followers where id = p) = 'EG');
  perform pg_temp.chk('an unknown parent is refused, not silently created',
    (public.record_country(gen_random_uuid(), 'DZ')->>'reason') = 'no_such_parent');
end $$;

\echo '=== THE CONFIRMATION ANSWERS THE QUESTION THAT CAUSED IT ==='
do $$
declare p uuid; b text; j jsonb;
begin
  p := pg_temp.parent('ZZ');
  perform public.record_country(p, 'DZ');

  b := public.compose_menu_body('country_recorded', p);
  perform pg_temp.chk('the country is named back in Arabic, not as a code',
    b like '%الجزائر%' and b not like '%DZ%', b);
  perform pg_temp.chk('and the journey question is answered in the same breath',
    b like '%2,300 دينار جزائري%', b);
  perform pg_temp.chk('the free relationship is restated so the price cannot read as a wall',
    b like '%مجانياً، دائماً%', b);

  -- The moment must resolve through the real entry point, not just the composer.
  j := public.get_conversation_moment('country_recorded', p);
  perform pg_temp.chk('country_recorded resolves as a real moment',
    (j->>'found')::boolean and (j->>'body') like '%الجزائر%', j::text);

  perform public.record_country(p, 'SA');
  b := public.compose_menu_body('country_recorded', p);
  perform pg_temp.chk('an unsupported answer is confirmed without a price',
    b like '%سجّلنا بلدكم%' and b !~ '[0-9٠-٩]', b);
  perform pg_temp.chk('and still gives the one true reason',
    b like '%طريقة دفع محلية%', b);
end $$;

\echo '=== «بلد آخر» IS ANSWERED WITHOUT AN INTERROGATION ==='
do $$
declare p uuid; j jsonb; cbs text[];
begin
  p := pg_temp.parent('ZZ');
  j := public.get_conversation_moment('country_other', p);
  perform pg_temp.chk('country_other exists as its own moment',
    (j->>'found')::boolean, j::text);
  perform pg_temp.chk('it does not ask which country — we could not act on the answer',
    (j->>'body') not like '%أي بلد%', j->>'body');
  perform pg_temp.chk('it carries no price',
    (j->>'body') !~ '[0-9٠-٩]', j->>'body');
  select array_agg(x->>'cb') into cbs from jsonb_array_elements(j->'buttons') x;
  perform pg_temp.chk('and it still offers the waitlist',
    cbs @> array['waitlist_join'], array_to_string(cbs,','));
end $$;

\echo '=== AN UNKNOWN COUNTRY IS WHY 59 FAMILIES NEVER HEARD FROM ADAM ==='
do $$
declare p uuid; c uuid;
begin
  -- Fully ready in every way except one: we cannot tell what hour it is
  -- where they are. get_rhythm_due joins country_timezone, so an unknown
  -- code excludes them silently — the classification bug was never only
  -- about a sentence.
  p := pg_temp.parent('ZZ');
  insert into public.children (follower_id, name, is_primary) values (p, 'آدم', true) returning id into c;
  insert into public.situations (child_id, key, status, evidence_count)
  values (c, 'sleep', 'confirmed', 4);

  perform pg_temp.chk('an unknown country is never due a proactive message',
    not exists (select 1 from public.get_rhythm_due(500) g where g.parent_id = p));

  perform public.record_country(p, 'DZ');
  perform pg_temp.chk('and naming the country is what makes the clock exist',
    exists (select 1 from public.country_timezone ct
            join public.followers f on upper(btrim(f.country)) = ct.code
            where f.id = p));
end $$;

\echo '=== THE PINNED SURFACE AGREES WITH THE ANSWER ==='
do $$
declare dz uuid; sa uuid; zz uuid; c uuid;
begin
  -- Two functions answering "where is this parent" in two different ways is
  -- how the answers drift. These assert they cannot.
  dz := pg_temp.parent('DZ'); sa := pg_temp.parent('SA'); zz := pg_temp.parent('ZZ');
  foreach c in array array[dz, sa, zz] loop
    insert into public.children (follower_id, name, is_primary) values (c, 'نور', true);
  end loop;

  perform pg_temp.chk('the surface carries the state, not a guess',
    public.get_telegram_surface(dz)->'modifiers'->>'country_state' = 'supported'
    and public.get_telegram_surface(sa)->'modifiers'->>'country_state' = 'unsupported'
    and public.get_telegram_surface(zz)->'modifiers'->>'country_state' = 'unknown',
    (public.get_telegram_surface(zz)->'modifiers')::text);

  perform pg_temp.chk('surface and moment can never disagree',
    (select bool_and(public.get_telegram_surface(f.id)->'modifiers'->>'country_state'
                     = public.country_state(f.id)->>'state')
     from public.followers f));

  -- The legacy boolean must now be FALSE only where we truly do not sell,
  -- and must never again be the reason an unknown parent is treated as
  -- rejected. It stays derived so it cannot drift on its own.
  perform pg_temp.chk('the legacy boolean is true for exactly the supported state',
    (select bool_and((public.get_telegram_surface(f.id)->'modifiers'->>'country_supported')::boolean
                     = (public.country_state(f.id)->>'state' = 'supported'))
     from public.followers f));

  -- §4.7 / §6.8: none of this may reach the pinned message.
  perform pg_temp.chk('an unknown country is still invisible on the surface',
    (public.get_telegram_surface(zz)->'pinned'->>'text') !~ '(بلد|قائمة الانتظار|لم يصل)',
    public.get_telegram_surface(zz)->'pinned'->>'text');
end $$;

\echo '=== AND NONE OF IT ADDRESSES A MOTHER, OR SELLS ==='
do $$
declare bad text[] := '{}'; dz uuid; sa uuid; zz uuid;
begin
  dz := pg_temp.parent('DZ'); sa := pg_temp.parent('SA'); zz := pg_temp.parent('ZZ');
  perform public.record_country(dz, 'DZ');

  if public.get_conversation_moment('menu_journey', dz)->>'body'
       ~ '(صِفي|قولي|أخبريني|احكِ|اكتبي|جرّبي|أنتِ)' then bad := bad || 'journey_dz'; end if;
  if public.get_conversation_moment('menu_journey', sa)->>'body'
       ~ '(صِفي|قولي|أخبريني|احكِ|اكتبي|جرّبي|أنتِ)' then bad := bad || 'journey_sa'; end if;
  if public.get_conversation_moment('menu_journey', zz)->>'body'
       ~ '(صِفي|قولي|أخبريني|احكِ|اكتبي|جرّبي|أنتِ)' then bad := bad || 'journey_zz'; end if;
  if public.compose_menu_body('country_recorded', dz)
       ~ '(صِفي|قولي|أخبريني|احكِ|اكتبي|جرّبي|أنتِ)' then bad := bad || 'recorded'; end if;
  if (select body_ar from public.conversation_moments where key='country_other')
       ~ '(صِفي|قولي|أخبريني|احكِ|اكتبي|جرّبي|أنتِ)' then bad := bad || 'other'; end if;
  perform pg_temp.chk('every country sentence speaks to a household, not a mother',
    cardinality(bad) = 0, array_to_string(bad, ', '));

  -- §3.7: ADAM never sells. He may state a price when asked, once, and stop.
  bad := '{}';
  if public.get_conversation_moment('menu_journey', dz)->>'body'
       ~ '(اشترك|اشتروا|سارعوا|الآن فقط|عرض خاص|خصم|مجاناً لفترة)' then bad := bad || 'journey'; end if;
  if public.compose_menu_body('country_recorded', dz)
       ~ '(اشترك|اشتروا|سارعوا|الآن فقط|عرض خاص|خصم|مجاناً لفترة)' then bad := bad || 'recorded'; end if;
  perform pg_temp.chk('the price is stated, never pushed',
    cardinality(bad) = 0, array_to_string(bad, ', '));
end $$;

\echo '=== RESULTS ==='
\pset format unaligned
select lpad(n::text,2) || '  ' || rpad(result,6) || rpad(name, 62)
    || coalesce('  -> ' || left(replace(detail, chr(10), ' / '), 54), '')
from pg_temp.r order by n;
select E'\n' || count(*) filter (where result='PASS') || ' / ' || count(*) || ' passed'
from pg_temp.r;

rollback;
