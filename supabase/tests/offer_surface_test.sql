\set ON_ERROR_STOP on
begin;

create table pg_temp.r (n int generated always as identity, name text, result text, detail text);
create or replace function pg_temp.chk(p_name text, p_cond boolean, p_detail text default null)
returns void language sql as $$
  insert into pg_temp.r (name, result, detail)
  values (p_name, case when p_cond then 'PASS' else 'FAIL' end, p_detail);
$$;

create or replace function pg_temp.parent(p_country text, p_child text default null)
returns uuid language plpgsql as $$
declare v uuid;
begin
  insert into public.followers (platform_user_id, country)
  values (gen_random_uuid()::text, p_country) returning id into v;
  if p_child is not null then
    insert into public.children (follower_id, name, is_primary) values (v, p_child, true);
  end if;
  return v;
end $$;

create or replace function pg_temp.offer(p uuid) returns jsonb language sql as $$
  select public.get_conversation_moment('menu_journey', p);
$$;


\echo '=== BOLD THAT NEVER RENDERS CANNOT BE STORED ==='
do $$
declare bad text[]; ok boolean;
begin
  -- Nothing sends with a parse_mode, so `**` reaches the parent literally.
  select coalesce(array_agg(key order by key), '{}') into bad
  from public.conversation_moments where body_ar like '%**%';
  perform pg_temp.chk('no stored moment carries markdown that never renders',
    cardinality(bad) = 0, array_to_string(bad, ', '));

  -- And the database refuses the next one.
  begin
    insert into public.conversation_moments (key, category, tier, body_ar, note)
    values ('zz_markup_probe', 'menu', 'fixed', '**عنوان**', 'probe');
    ok := true;
  exception when check_violation then ok := false;
  end;
  perform pg_temp.chk('and a new one is refused by the database', not ok);
end $$;


\echo '=== THE OFFER SELLS THE RESULT, NOT THE MECHANISM ==='
do $$
declare p uuid; j jsonb; b text;
begin
  -- Every price an active market can be asked for, or
  -- chk_active_market_has_pricing refuses the row. The amounts are 1 on purpose:
  -- what is asserted is the DISPLAY string, never a number.
  insert into public.supported_countries
    (code, name_ar, currency, price_subscription, price_comeback, price_continuation,
     price_display_full, price_display_short, price_continuation_display, is_active)
  values ('DZ', 'الجزائر', 'DZD', 1, 1, 1,
          'ثمن الرحلة', 'ثمن الرحلة', 'ثمن المواصلة', true)
  on conflict (code) do update set is_active = true, price_display_full = 'ثمن الرحلة';

  -- Two statements, never one. country_state() is STABLE, so a parent
  -- inserted by a volatile call nested in the SAME statement is invisible to
  -- it — the trap already written up in tests/README.md.
  p := pg_temp.parent('DZ', 'يوسف');
  j := pg_temp.offer(p);
  b := j->>'body';

  perform pg_temp.chk('the offer names the enemy — the repeat, not tonight',
    b like '%الموقف نفسه يتكرّر%', left(b, 60));
  perform pg_temp.chk('and says plainly what the free side already gives',
    b like '%المجاني يبقى مجانياً%' and b like '%لن ينقص منه شيء%');

  -- The value equation, one assertion per term. Drop any one of these and
  -- the offer stops being an offer and goes back to being a description.
  perform pg_temp.chk('OUTCOME · named, and chosen by them',
    b like '%مشكلة واحدة تختارونها أنتم%'
    and b like '%نوم بلا معركة%' and b like '%نوبات غضب أقلّ%', b);
  perform pg_temp.chk('BELIEF · the goal is agreed and visible before any money moves',
    b like '%نتّفق عليها قبل أن نبدأ%' and b like '%ترونه بأعينكم%');
  perform pg_temp.chk('BELIEF · and the promise is deliberately small, so it is credible',
    b like '%لا أعدكم بطفلٍ مثالي%');
  perform pg_temp.chk('WAIT · a finite, named number of days',
    b like '%خلال ٢٩ يوماً%' and b like '%لمدّة ٢٩ يوماً%');
  perform pg_temp.chk('EFFORT · a minute or two, and the day they cannot face is free',
    b like '%دقيقة أو دقيقتان%' and b like '%لا يُحسب عليكم%');

  -- Personalisation is the sale. The child's name is not decoration here:
  -- it is the claim.
  perform pg_temp.chk('the differentiator is stated as a rule, not a feature',
    b like '%لا يعطيكم نصيحة عامّة%' and b like '%مصنوعة ليوسف وحده%', b);
  perform pg_temp.chk('and the capability list is about this child by name',
    b like '%يعرف يوسف%' and b like '%يبني خطوة اليوم على نتيجة أمس%'
    and b like '%هذه ثالث مرّة هذا الأسبوع%');

  -- ONE guarantee. The count is the assertion: five reassurances read as a
  -- legal notice, and a parent skims a legal notice.
  perform pg_temp.chk('the extension is promised (stages.extension_days)',
    b like '%أُكمل معكم نصف المدّة كاملةً مجاناً%');
  perform pg_temp.chk('and it is the ONLY guarantee — no refund, no stacked reassurances',
    b not like '%يرجع مالكم%'
    and b not like '%رحلة واحدة في المرّة%'
    and b not like '%لا حين يمرّ التقويم%', b);

  -- ADAM is forbidden to say a price and does not know the terms. Saying so
  -- before they ask is the difference between a boundary and a dead end.
  perform pg_temp.chk('the offer says out loud that ADAM does not handle this part',
    b like '%لا أتولّى هذا الجزء%' and b like '%فريق آدم%');
  perform pg_temp.chk('the price is present, with the duration beside it',
    b like '%ثمن الرحلة، لمدّة ٢٩ يوماً%', b);
  perform pg_temp.chk('and no asterisk survived into the offer',
    b not like '%*%', b);
end $$;


\echo '=== THE CALL TO ACTION IS A BUTTON, AND IT NAMES THE CHILD ==='
do $$
declare p uuid; j jsonb; bs jsonb;
begin
  p := pg_temp.parent('DZ', 'يوسف');
  j := pg_temp.offer(p);
  bs := j->'buttons';

  perform pg_temp.chk('the offer carries a link button, not a bare address',
    bs->0 ? 'url' and (bs->0->>'url') like 'https://t.me/%', bs::text);
  -- The old label was «نبدأ الرحلة» and the second button was «عندي سؤال قبل
  -- أن أقرّر» routed to ADAM — who is forbidden to answer it. The button must
  -- say who they are about to talk to.
  perform pg_temp.chk('and it says they are going to the humans, by name',
    (bs->0->>'label') like '%فريق آدم%' and (bs->0->>'label') like '%يوسف%',
    bs->0->>'label');
  perform pg_temp.chk('the body no longer dumps the link as text',
    (j->>'body') not like '%t.me%', left(j->>'body', 40));
  perform pg_temp.chk('declining is a real destination, not a shrug',
    bs @> '[{"cb":"menu_not_now"}]'::jsonb, bs::text);
  perform pg_temp.chk('no button on the offer sends a journey question to ADAM',
    not (bs @> '[{"cb":"other"}]'::jsonb), bs::text);
  perform pg_temp.chk('every button on the offer carries its own mark',
    not exists (select 1 from jsonb_array_elements(bs) x
                where (x->>'label') !~ '^[^[:ascii:]]'
                   or (x->>'label') ~ '^[ء-ي]'), bs::text);

  -- A parent whose child we have not been told about must not be sold to
  -- with a placeholder where a name should be.
  p := pg_temp.parent('DZ');
  j := pg_temp.offer(p);
  perform pg_temp.chk('with no name known, the label is general, never «طفلكم» in a button',
    (j->'buttons'->0->>'label') = '📞 أتحدّث مع فريق آدم', j->'buttons'->0->>'label');
end $$;


\echo '=== «LEIS AL-AAN» COSTS THEM NOTHING ==='
do $$
declare m jsonb;
begin
  m := public.get_conversation_moment('menu_not_now', null);
  perform pg_temp.chk('declining lands on a moment that exists',
    (m->>'found')::boolean, m::text);
  perform pg_temp.chk('and it releases the pressure instead of asking again',
    (m->>'body') like '%لا ضغط%' and (m->>'body') not like '%فريق آدم%', m->>'body');
  perform pg_temp.chk('it restates that the free relationship is undamaged',
    (m->>'body') like '%بلا نقص%');
  perform pg_temp.chk('and it returns them to the ordinary conversation',
    (m->'buttons') @> '[{"cb":"other"}]'::jsonb, (m->'buttons')::text);
end $$;


\echo '=== ADAM SAYS WHERE HE STOPS ==='
do $$
declare b text;
begin
  select body_ar into b from public.conversation_moments where key = 'menu_how';
  perform pg_temp.chk('the method page names the boundary, before a parent finds it',
    b like '%يتولّاه فريق آدم، لا أنا%', b);

  select body_ar into b from public.conversation_moments where key = 'menu_why';
  perform pg_temp.chk('and every capability carries its own mark, not nine identical ticks',
    b not like '%✅%' and b like '%👦%' and b like '%🔒%', b);
end $$;


\echo '=== ٢٩ IS THE ENGINE''S NUMBER, NOT AN ADVERT''S ==='
do $$
declare v text;
begin
  select column_default into v from information_schema.columns
  where table_schema='public' and table_name='stages' and column_name='planned_logged_days';
  perform pg_temp.chk('a stage started with no explicit length is the length we promised',
    coalesce(v,'') like '29%', coalesce(v,'null'));

  -- The refund was never code — only a sentence in this comment saying one
  -- would follow. A promise that lives in a comment cannot be kept.
  perform pg_temp.chk('and the extension is documented as the whole of what is owed',
    coalesce((select d.description from pg_description d
              join pg_attribute a on a.attrelid = d.objoid and a.attnum = d.objsubid
              where d.objoid = 'public.stages'::regclass
                and a.attname = 'extension_days'), '') like '%whole of what is owed%');
end $$;


\echo '=== THE OTHER TWO COUNTRY STATES ARE UNTOUCHED ==='
do $$
declare p uuid; j jsonb;
begin
  p := pg_temp.parent('SY', 'سلمى');
  j := pg_temp.offer(p);
  perform pg_temp.chk('an unsupported country is still offered the waiting list, not a price',
    (j->'buttons') @> '[{"cb":"waitlist_join"}]'::jsonb
    and (j->>'body') not like '%ثمن الرحلة%', (j->>'body'));

  p := pg_temp.parent('ZZ');
  j := pg_temp.offer(p);
  perform pg_temp.chk('an unknown country is asked where it is, before any price',
    (j->'buttons') @> '[{"cb":"set_country_DZ"}]'::jsonb, (j->>'body'));
end $$;


\echo '=== AND EVERY COMPOSED SURFACE IS STILL CLEAN ==='
do $$
declare p uuid; bad text[] := '{}'; k text; b text;
begin
  p := pg_temp.parent('DZ', 'يوسف');
  update public.followers set country_asked_at = now() where id = p;

  foreach k in array array['country_recorded','menu_child','menu_progress'] loop
    b := public.compose_menu_body(k, p);
    if b is not null and b like '%**%' then bad := bad || k; end if;
  end loop;

  perform pg_temp.chk('no composed surface carries markdown either',
    cardinality(bad) = 0, array_to_string(bad, ', '));

  perform pg_temp.chk('the country receipt points at the offer instead of dumping a link',
    public.compose_menu_body('country_recorded', p) not like '%t.me%',
    public.compose_menu_body('country_recorded', p));
end $$;


\echo '=== RESULTS ==='
\pset format unaligned
select lpad(n::text,2) || '  ' || rpad(result,6) || rpad(name, 64)
    || coalesce('  -> ' || left(replace(detail, chr(10), ' / '), 52), '')
from pg_temp.r order by n;
select E'\n' || count(*) filter (where result='PASS') || ' / ' || count(*) || ' passed'
from pg_temp.r;

rollback;
