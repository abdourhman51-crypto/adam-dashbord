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
  insert into public.supported_countries
    (code, name_ar, currency, price_subscription, price_comeback, is_active, price_display_full)
  values ('DZ', 'الجزائر', 'DZD', 1, 1, true, 'ثمن الرحلة')
  on conflict (code) do update set is_active = true, price_display_full = 'ثمن الرحلة';

  -- Two statements, never one. country_state() is STABLE, so a parent
  -- inserted by a volatile call nested in the SAME statement is invisible to
  -- it — the trap already written up in tests/README.md.
  p := pg_temp.parent('DZ', 'يوسف');
  j := pg_temp.offer(p);
  b := j->>'body';

  perform pg_temp.chk('the offer names the enemy — the night that comes back',
    b like '%ترجع الأسبوع القادم%', left(b, 60));
  perform pg_temp.chk('and says plainly what the free side already gives',
    b like '%المجاني يبقى مجانياً%' and b like '%يبقى لكم دائماً%');
  perform pg_temp.chk('the target is a number they can see, not a feeling',
    b like '%خمس ليالٍ هادئة من سبع%');

  -- The three promises the schema already enforces. If a line here is
  -- deleted from the copy, this fails — the offer must not quietly shrink
  -- back to the modest version that undersold the product.
  perform pg_temp.chk('the clock counts days they were present, not calendar days',
    b like '%لا حين يمرّ التقويم%');
  perform pg_temp.chk('the unrequested extension is promised (stages.extension_days)',
    b like '%أُكمل معكم نصفها كاملاً%' and b like '%بلا أن تطلبوا%');
  perform pg_temp.chk('and the refund after it (stages.refunded_at)',
    b like '%يرجع مالكم%');

  -- The two refusals can_propose_stage() enforces. These buy more trust
  -- than any claim, and they are free to make because they are already true.
  perform pg_temp.chk('one journey at a time is said out loud (uq_one_live_stage_per_parent)',
    b like '%رحلة واحدة في المرّة%');
  perform pg_temp.chk('and the refusal to raise it on an improving trend',
    b like '%تتحسّن عندكم%' and b like '%أصمت%');

  perform pg_temp.chk('the fourth step is the differentiator: they stop needing it',
    b like '%لا أريدكم أن تحتاجوني%');
  perform pg_temp.chk('the price is present',
    b like '%ثمن الرحلة%');
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
  perform pg_temp.chk('and the label is a decision about this child',
    (bs->0->>'label') like '%يوسف%', bs->0->>'label');
  perform pg_temp.chk('the body no longer dumps the link as text',
    (j->>'body') not like '%t.me%', left(j->>'body', 40));
  perform pg_temp.chk('and there is a way out that is not "no"',
    bs @> '[{"cb":"other"}]'::jsonb, bs::text);

  -- A parent whose child we have not been told about must not be sold to
  -- with a placeholder where a name should be.
  p := pg_temp.parent('DZ');
  j := pg_temp.offer(p);
  perform pg_temp.chk('with no name known, the label is general, never «طفلكم» in a button',
    (j->'buttons'->0->>'label') = '💚 نبدأ الرحلة', j->'buttons'->0->>'label');
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
