\set ON_ERROR_STOP on
begin;

create table pg_temp.r (n int generated always as identity, name text, result text, detail text);
create or replace function pg_temp.chk(p_name text, p_cond boolean, p_detail text default null)
returns void language sql as $$
  insert into pg_temp.r (name, result, detail)
  values (p_name, case when p_cond then 'PASS' else 'FAIL' end, p_detail);
$$;

-- A parent who has been asked the intention question, `p_ago` ago,
-- and has not answered it yet.
create or replace function pg_temp.asked(p_ago interval) returns uuid
language plpgsql as $$
declare v uuid;
begin
  insert into public.followers (platform_user_id, country)
  values (gen_random_uuid()::text, 'DZ') returning id into v;
  update public.followers set intention_asked_at = now() - p_ago where id = v;
  return v;
end $$;

create or replace function pg_temp.kept(p uuid) returns text language sql as $$
  select intention_text from public.followers where id = p;
$$;


\echo '=== AN ANSWER IS KEPT, AND ANSWERED ==='
do $$
declare p uuid; j jsonb;
begin
  p := pg_temp.asked(interval '2 hours');
  j := public.capture_intention(p, 'أب هادئ، لا يصرخ في أولاده');

  perform pg_temp.chk('an answer given the same night is captured',
    (j->>'captured')::boolean, j::text);
  perform pg_temp.chk('and it is stored exactly as they wrote it',
    pg_temp.kept(p) = 'أب هادئ، لا يصرخ في أولاده', pg_temp.kept(p));
  perform pg_temp.chk('the capture hands back words to say, not a receipt',
    coalesce(j->>'body','') <> '' and (j->>'found')::boolean, j->>'body');
  perform pg_temp.chk('and those words are the intention_kept moment',
    j->>'key' = 'intention_kept', j->>'key');
  perform pg_temp.chk('the reply carries an escape, because fixed copy answered a typed message',
    j->'buttons' @> '[{"cb":"other"}]'::jsonb, (j->'buttons')::text);
end $$;


\echo '=== IT IS ASKED ONCE, AND KEPT ONCE ==='
do $$
declare p uuid; j jsonb;
begin
  p := pg_temp.asked(interval '1 hour');
  perform public.capture_intention(p, 'أمّ حاضرة، مش غايبة في التلفون');

  j := public.capture_intention(p, 'لا، غيّرت رأيي — أمّ صبورة');
  perform pg_temp.chk('a second answer is refused',
    not (j->>'captured')::boolean and j->>'reason' = 'not_awaiting', j::text);
  perform pg_temp.chk('and it never overwrites the first',
    pg_temp.kept(p) = 'أمّ حاضرة، مش غايبة في التلفون', pg_temp.kept(p));
end $$;


\echo '=== A MESSAGE THAT IS NOT AN ANSWER IS NOT AN ANSWER ==='
do $$
declare p uuid; j jsonb; kept text;
begin
  -- Each guard gets its own parent: a captured answer would close the door
  -- for every case after it, and the test would pass for the wrong reason.

  j := public.capture_intention(pg_temp.asked(interval '4 days'),
                                'أب هادئ لا يصرخ');
  perform pg_temp.chk('an answer four days late is not an answer',
    j->>'reason' = 'window_closed', j::text);

  j := public.capture_intention(pg_temp.asked(interval '1 hour'), 'ok');
  perform pg_temp.chk('«ok» is an acknowledgement, not an intention',
    j->>'reason' = 'too_short', j::text);

  j := public.capture_intention(pg_temp.asked(interval '1 hour'), '/faq');
  perform pg_temp.chk('a command is never an intention',
    j->>'reason' = 'command', j::text);

  j := public.capture_intention(pg_temp.asked(interval '1 hour'), 'كيف يعني؟');
  perform pg_temp.chk('a parent who ends with ؟ is asking, not answering',
    j->>'reason' = 'a_question', j::text);

  j := public.capture_intention(pg_temp.asked(interval '1 hour'), 'what do you mean?');
  perform pg_temp.chk('and the latin question mark counts too',
    j->>'reason' = 'a_question', j::text);

  j := public.capture_intention(pg_temp.asked(interval '1 hour'),
        repeat('كلام طويل جداً عمّا حدث الليلة في البيت ', 12));
  perform pg_temp.chk('a long message is a parent telling us what happened',
    j->>'reason' = 'too_long', j::text);

  j := public.capture_intention(pg_temp.asked(interval '1 hour'),
        'ابني ما ينامش' || chr(10) || 'ويصيح كل ليلة' || chr(10) ||
        'وأنا تعبت' || chr(10) || 'ماذا أفعل');
  perform pg_temp.chk('four lines is a story, not a sentence',
    j->>'reason' = 'not_a_sentence', j::text);

  j := public.capture_intention(gen_random_uuid(), 'أب هادئ');
  perform pg_temp.chk('a parent who was never asked is never captured',
    j->>'reason' = 'not_awaiting', j::text);
end $$;


\echo '=== NOTHING DECLINED IS LOST ==='
do $$
declare p uuid; j jsonb;
begin
  -- The whole safety argument: a declined message writes nothing, so it can
  -- still be answered normally, and the question can still be answered later.
  p := pg_temp.asked(interval '1 hour');
  perform public.capture_intention(p, 'كيف يعني؟');
  perform pg_temp.chk('a declined message stores nothing',
    pg_temp.kept(p) is null, coalesce(pg_temp.kept(p), 'null'));

  j := public.capture_intention(p, 'أب يضحك مع أولاده');
  perform pg_temp.chk('and the real answer, sent after it, still lands',
    (j->>'captured')::boolean and pg_temp.kept(p) = 'أب يضحك مع أولاده',
    pg_temp.kept(p));
end $$;


\echo '=== THE BUNDLE CARRIES IT, AND NOTHING ELSE CHANGES ==='
do $$
declare p uuid; b jsonb;
begin
  p := pg_temp.asked(interval '1 hour');

  b := public.get_agent_bundle(p, 'أب حاضر مع أولاده');
  perform pg_temp.chk('the one call the reply path makes performs the capture',
    (b->>'intention_captured')::boolean and pg_temp.kept(p) = 'أب حاضر مع أولاده',
    b::text);
  perform pg_temp.chk('and hands the sender a body and buttons',
    coalesce(b->>'intention_body','') <> ''
    and b->'intention_buttons' @> '[{"cb":"other"}]'::jsonb, b::text);
  perform pg_temp.chk('a captured message never also spends the country ask',
    (b->>'ask')::boolean is false, b::text);
  perform pg_temp.chk('and never builds context for a model that will not run',
    b->>'context' = '', b::text);

  -- The ordinary case must be untouched: same keys, same shape.
  b := public.get_agent_bundle(p, 'ابني ما ينامش، وش ندير؟');
  perform pg_temp.chk('an ordinary message still gets the ordinary bundle',
    not (b->>'intention_captured')::boolean
    and b ? 'context' and b ? 'knowledge_level' and b ? 'family_context'
    and b ? 'ask' and b ? 'ask_buttons', b::text);

  perform pg_temp.chk('and the one-argument call still works, unchanged',
    (public.get_agent_bundle(p) ? 'family_context')
    and not (public.get_agent_bundle(p)->>'intention_captured')::boolean);

  perform pg_temp.chk('a null parent answers without touching anything',
    not (public.get_agent_bundle(null::uuid, 'أب هادئ')->>'intention_captured')::boolean);
end $$;


\echo '=== THE WORDS THEMSELVES ARE UNDER THE SAME LAW ==='
do $$
declare v_ask text; v_kept text;
begin
  select body_ar into v_ask  from public.conversation_moments where key = 'intention_ask';
  select body_ar into v_kept from public.conversation_moments where key = 'intention_kept';

  perform pg_temp.chk('the ask tells the parent that typing is the move',
    v_ask like '%اكتبوها%', v_ask);
  perform pg_temp.chk('the reply says what the sentence is for, not that it was stored',
    v_kept like '%اقتربتم%' and v_kept not like '%حفظ%', v_kept);
  perform pg_temp.chk('and it never promises they will become it tonight',
    v_kept like '%لن أطلب منكم أن تصيروها%', v_kept);
  perform pg_temp.chk('both survive the vocabulary law',
    cardinality(public.copy_violations(v_ask)) = 0
    and cardinality(public.copy_violations(v_kept)) = 0);
  perform pg_temp.chk('and both speak to a household, not to a mother',
    v_ask !~ '(صِفي|قولي|أخبريني|احكِ|اكتبي|جرّبي|أنتِ)'
    and v_kept !~ '(صِفي|قولي|أخبريني|احكِ|اكتبي|جرّبي|أنتِ)');
end $$;


\echo '=== RESULTS ==='
\pset format unaligned
select lpad(n::text,2) || '  ' || rpad(result,6) || rpad(name, 62)
    || coalesce('  -> ' || left(replace(detail, chr(10), ' / '), 54), '')
from pg_temp.r order by n;
select E'\n' || count(*) filter (where result='PASS') || ' / ' || count(*) || ' passed'
from pg_temp.r;

rollback;
