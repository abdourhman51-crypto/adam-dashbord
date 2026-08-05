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


\echo '=== A QUESTION FOR THE TEAM IS RECOGNISED ==='
do $$
declare bad text[] := '{}'; t text;
begin
  foreach t in array array[
    'اريد ان اعرف بخصوص المرافقة الكاملة',
    'كيف أنضم للمرافقة الكاملة؟',
    'شنو هو السعر؟',
    'بشحال المرافقة؟',
    'بكام الاشتراك؟',
    'أريد أن أشترك',
    'ما هي طريقة الدفع عندكم',
    'نحب نشترك، كيفاش ندفع؟',
    'واش كاين فيزا ولا بريدي موب؟',
    'كم يكلف هذا',
    'أين أدفع؟',
    'وين ندفع بالضبط',
    'عندي سؤال لفريق آدم',
    'ثمنها شحال', -- «ثمنها» carries it, «شحال» alone would not
    'بغيت نعرف التكلفة',
    -- The same question from the other side. This one reached the model for
    -- a whole release: no word about a price, a subscription or paying.
    'هل انت مجاني',
    'واش هذا مجاني ولا مدفوع',
    'آدم مجاناً؟',
    'هل الخدمة بالمجان'
  ] loop
    if not public.is_team_question(t) then bad := bad || t; end if;
  end loop;

  perform pg_temp.chk('every way a parent asks about buying is caught',
    cardinality(bad) = 0, array_to_string(bad, ' | '));
end $$;


\echo '=== AND A PARENT DESCRIBING THEIR EVENING IS NOT ==='
do $$
declare bad text[] := '{}'; t text;
begin
  -- These are the near-misses the token list was pruned for. Each one is a
  -- real thing a parent says, and each contains a substring that a lazier
  -- list would have matched. A false positive here hands a sales card to
  -- someone telling us their child hit their brother.
  foreach t in array array[
    'أحمد دفع أخاه اليوم ولم أعرف ماذا أفعل',   -- «دفع» is pushing
    'الدفع بينهم كل يوم صار عادة',              -- «الدفع» is pushing
    'أهلاً بكم، سعيدة بوجودكم',                  -- «بكم» is not «بكام»
    'شحال من مرة قلت له لا ينفع',               -- «شحال» is a count
    'قداش من ليلة وأنا صاحية معه',              -- «قداش» is a count
    'رحلتنا إلى بيت جدّته كانت متعبة',           -- a real journey
    'يرفض الأكل، ويبكي عند النوم',
    'صار عنيداً جداً هذا الأسبوع',
    'تعبت، ما عاد فيني',
    'نامت بهدوء الليلة ولأول مرة',
    'أخته الصغيرة تنام مبكراً وهو لا',
    'تدفعه للنوم بالقوة ما ينفعش',        -- «تدفع» is pushing, and stays out
    'يطلب فلوس كل يوم للمدرسة'            -- «فلوس» is pocket money, and stays out
  ] loop
    if public.is_team_question(t) then bad := bad || t; end if;
  end loop;

  perform pg_temp.chk('no ordinary message about a child is mistaken for a sale',
    cardinality(bad) = 0, array_to_string(bad, ' | '));

  perform pg_temp.chk('and an empty or null message is never a team question',
    not public.is_team_question(null) and not public.is_team_question(''));
end $$;


\echo '=== THE HANDOVER CARRIES A LINK, AND NEVER A PROMISE ==='
do $$
declare p uuid; m jsonb;
begin
  insert into public.supported_countries
    (code, name_ar, currency, price_subscription, price_comeback, is_active, price_display_full)
  values ('DZ', 'الجزائر', 'DZD', 1, 1, true, 'ثمن الرحلة')
  on conflict (code) do update set is_active = true;

  p := pg_temp.parent('DZ', 'أحمد');
  m := public.get_conversation_moment('menu_ask_team', p);

  perform pg_temp.chk('the handover exists and composes',
    (m->>'found')::boolean, m::text);
  -- «هل انت مجاني» deserves an answer, not a deflection. ADAM knows what is
  -- free — that is the relationship he is in, not a commercial term.
  perform pg_temp.chk('it answers the free half itself, before handing anything over',
    (m->>'body') like '%كل ما بيننا الآن مجاني%'
    and position('مجاني' in (m->>'body')) < position('فريق آدم' in (m->>'body')),
    m->>'body');
  perform pg_temp.chk('and hands over only the half that is genuinely theirs',
    (m->>'body') like '%لا أتولّاها%' and (m->>'body') like '%فريق آدم%', m->>'body');

  -- The failure that started this: the model invented «وسيتواصلون معكم
  -- قريباً». Nothing schedules that and no human was told.
  perform pg_temp.chk('and it never promises that anyone will call them',
    (m->>'body') not like '%سيتواصلون%'
    and (m->>'body') not like '%سنتواصل%'
    and (m->>'body') not like '%قريباً%', m->>'body');
  perform pg_temp.chk('the parent is given a way to act, not a wait',
    (m->'buttons'->0->>'url') = 'https://t.me/Abdouleg', (m->'buttons')::text);
  perform pg_temp.chk('and the door back to the conversation names the child',
    (m->'buttons'->1->>'label') like '%أحمد%'
    and (m->'buttons'->1->>'cb') = 'other', (m->'buttons')::text);
  perform pg_temp.chk('no price is quoted in a handover',
    (m->>'body') not like '%ثمن الرحلة%' and (m->>'body') !~ '[0-9]', m->>'body');

  -- A parent whose country does not sell must not be handed a purchase link.
  p := pg_temp.parent('SY', 'سلمى');
  m := public.get_conversation_moment('menu_ask_team', p);
  perform pg_temp.chk('where we do not sell, the link becomes the waiting list',
    (m->'buttons') @> '[{"cb":"waitlist_join"}]'::jsonb
    and not ((m->'buttons')::text like '%t.me%'), (m->'buttons')::text);

  -- Reachable from a first message, before any child is known.
  m := public.get_conversation_moment('menu_ask_team', null);
  perform pg_temp.chk('and it still answers when we know nothing at all',
    (m->>'found')::boolean and coalesce(m->>'body','') <> '', m::text);
end $$;


\echo '=== THE MODEL NEVER SEES THE TURN ==='
do $$
declare p uuid; b jsonb;
begin
  p := pg_temp.parent('DZ', 'أحمد');

  b := public.get_agent_bundle(p, 'اريد ان اعرف بخصوص المرافقة الكاملة');
  perform pg_temp.chk('the bundle answers a team question itself',
    (b->>'handled')::boolean and b->>'handled_reason' = 'team_question', b::text);
  perform pg_temp.chk('and hands the sender a body and buttons',
    coalesce(b->>'handled_body','') <> ''
    and (b->'handled_buttons'->0->>'url') = 'https://t.me/Abdouleg', b::text);
  perform pg_temp.chk('it builds no context for a model that will not run',
    b->>'context' = '' and (b->>'ask')::boolean is false, b::text);

  -- The ordering that matters. «اشتراك» is short, has no question mark and
  -- is one line — capture_intention would have taken it and written it into
  -- this parent's intention permanently.
  update public.followers set intention_asked_at = now() where id = p;
  b := public.get_agent_bundle(p, 'اشتراك');
  perform pg_temp.chk('a team question is never mistaken for the intention answer',
    b->>'handled_reason' = 'team_question'
    and (select intention_text from public.followers where id = p) is null, b::text);

  -- And the intention capture still works, and still reports as handled.
  b := public.get_agent_bundle(p, 'أب هادئ لا يصرخ');
  perform pg_temp.chk('the intention answer is still captured, and still handled',
    (b->>'handled')::boolean and b->>'handled_reason' = 'intention_kept'
    and (b->>'intention_captured')::boolean
    and (select intention_text from public.followers where id = p) = 'أب هادئ لا يصرخ',
    b::text);

  -- Ordinary talk is untouched.
  b := public.get_agent_bundle(p, 'أحمد دفع أخاه اليوم');
  perform pg_temp.chk('and an ordinary message still reaches the model',
    not (b->>'handled')::boolean and b ? 'family_context' and b ? 'ask_buttons',
    b::text);
end $$;


\echo '=== RESULTS ==='
\pset format unaligned
select lpad(n::text,2) || '  ' || rpad(result,6) || rpad(name, 62)
    || coalesce('  -> ' || left(replace(detail, chr(10), ' / '), 54), '')
from pg_temp.r order by n;
select E'\n' || count(*) filter (where result='PASS') || ' / ' || count(*) || ' passed'
from pg_temp.r;

rollback;
