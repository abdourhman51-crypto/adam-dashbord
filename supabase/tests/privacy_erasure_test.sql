\set ON_ERROR_STOP on
begin;

-- ============================================================
-- «تطلبون محوه فيُمحى كلّه».
--
-- This suite exists because the promise was broken for several
-- hours on 2026-08-07 and no test noticed. execute_erasure was
-- covered directly; the TAP that reaches it was not. A cleanup
-- dropped session_tracker, execute_erasure still deleted from it,
-- and every erasure raised — a parent tapping «نعم، امحوا كل شيء»
-- got nothing erased.
--
-- So these cases walk the path a parent can actually reach:
-- get_moment_after_tap('menu_privacy_erased', …). A function
-- tested only where nobody calls it is tested in the wrong place.
-- ============================================================

create table pg_temp.r (n int generated always as identity, name text, result text, detail text);
create or replace function pg_temp.chk(p_name text, p_cond boolean, p_detail text default null)
returns void language sql as $$
  insert into pg_temp.r (name, result, detail)
  values (p_name, case when p_cond then 'PASS' else 'FAIL' end, p_detail);
$$;

-- A family ADAM knows well: a child, a situation, logged nights, a pattern,
-- a payment, and a conversation. Everything erasure has to reach.
create or replace function pg_temp.whole_family(p_pid text)
returns uuid language plpgsql as $$
declare p uuid; c uuid; s uuid; v_day uuid;
begin
  insert into public.followers (platform_user_id, country, first_name)
  values (p_pid, 'DZ', 'أمّ') returning id into p;
  insert into public.children (follower_id, name, is_primary)
  values (p, 'يوسف', true) returning id into c;
  insert into public.situations (child_id, parent_id, key, label_ar, status, window_start, window_end)
  select c, p, 'sleep', sc.label_ar, 'confirmed', sc.window_start, sc.window_end
    from public.situation_catalog sc where sc.key = 'sleep' returning id into s;

  v_day := (public.record_seed_sent(p, current_date, 'خطوة صغيرة',
              jsonb_build_array('child_name','situation'), s, c)->>'day_id')::uuid;
  perform public.record_harvest_sent(v_day);
  perform public.record_harvest_answer(p, 'succeeded');

  insert into public.child_patterns (follower_id, child_id, pattern_label, status)
  values (p, c, 'يهدأ حين نبدأ مبكراً', 'active');
  insert into public.memory_events (follower_id, child_id, event_type, title)
  values (p, c, 'win', 'أول ليلة هادئة');
  insert into public.payments (follower_id, amount, currency, status)
  values (p, 2300, 'DZD', 'confirmed');
  insert into public.n8n_chat_histories (session_id, message) values
    (p_pid,          jsonb_build_object('type','human','content','ليلة صعبة')),
    (p_pid || '_s2', jsonb_build_object('type','ai','content','أنا معكم')),
    ('=' || p_pid,   jsonb_build_object('type','human','content','شكراً'));
  return p;
end $$;


\echo '=== THE TAP ERASES. NOT THE FUNCTION UNDER IT — THE TAP. ==='
do $$
declare p uuid; res jsonb;
begin
  p := pg_temp.whole_family('er-1');

  perform pg_temp.chk('precondition: ADAM knows this family',
    (select count(*) from public.children where follower_id = p) = 1
    and (select count(*) from public.daily_logs where follower_id = p) = 1);

  res := public.get_moment_after_tap('menu_privacy_erased', p, 'DZ');

  -- This is the assertion that was missing. It is not about the return value;
  -- it is about the rows.
  perform pg_temp.chk('the tap reports that it erased', res->>'action_done' = 'erased', res->>'action_done');
  perform pg_temp.chk('the parent is gone',
    (select count(*) from public.followers where id = p) = 0);
  perform pg_temp.chk('the child is gone',
    (select count(*) from public.children where follower_id = p) = 0);
  perform pg_temp.chk('the nights are gone',
    (select count(*) from public.daily_logs where follower_id = p) = 0);
  perform pg_temp.chk('the situation is gone',
    (select count(*) from public.situations where parent_id = p) = 0);
  perform pg_temp.chk('the patterns are gone',
    (select count(*) from public.child_patterns where follower_id = p) = 0);
  perform pg_temp.chk('the memory events are gone',
    (select count(*) from public.memory_events where follower_id = p) = 0);
end $$;


\echo '=== EVERY SHAPE OF THE CONVERSATION KEY, NOT JUST THE TIDY ONE ==='
do $$
begin
  -- '123', '123_s2' and '=123' are all the same person. A delete on the literal
  -- key alone would leave two thirds of what she said sitting in the table.
  perform pg_temp.chk('all three historical session-key shapes are erased',
    (select count(*) from public.n8n_chat_histories
      where public.normalise_session_key(session_id) = 'er-1') = 0,
    'the drifted keys are the ones that outlive a careless delete');
end $$;


\echo '=== WHAT SURVIVES, AND WHY ==='
do $$
begin
  perform pg_temp.chk('the payment row SURVIVES — the financial record must',
    (select count(*) from public.payments where notes = '[erased]') = 1);
  perform pg_temp.chk('but it no longer points at a person',
    (select count(*) from public.payments where follower_id is not null and notes = '[erased]') = 0,
    'the record outlives the link, which is the whole distinction');

  -- The audit trail carries no foreign key to followers on purpose: the record
  -- of an erasure must survive the erasure it records.
  perform pg_temp.chk('the erasure itself is recorded, and says what it removed',
    (select status from public.erasure_requests where platform_user_id = 'er-1') = 'completed'
    and (select notes from public.erasure_requests where platform_user_id = 'er-1') like 'chat=3%',
    (select notes from public.erasure_requests where platform_user_id = 'er-1'));
end $$;


\echo '=== IT IS ASKED ONCE, AND ONLY THE SECOND TAP ACTS ==='
do $$
declare p uuid; res jsonb;
begin
  p := pg_temp.whole_family('er-2');

  -- The first tap only asks. Erasing on it would make an accident permanent.
  res := public.get_moment_after_tap('menu_privacy_erase_ask', p, 'DZ');
  perform pg_temp.chk('the confirm step erases NOTHING',
    (select count(*) from public.followers where id = p) = 1
    and coalesce(res->>'action_done','') <> 'erased',
    'asked once, so it cannot happen by mistake');
  perform pg_temp.chk('and it names what will be lost before it is lost',
    res->>'body' like '%ولا يمكن استرجاعه%', left(coalesce(res->>'body',''), 60));

  res := public.get_moment_after_tap('menu_privacy_erased', p, 'DZ');
  perform pg_temp.chk('the second tap is the one that acts',
    (select count(*) from public.followers where id = p) = 0);
end $$;

do $$
declare p uuid; res jsonb;
begin
  p := pg_temp.whole_family('er-3');
  perform public.get_moment_after_tap('menu_privacy_erased', p, 'DZ');

  -- The parent row is gone, so composing the closing message with her id would
  -- resolve every parent-scoped lookup to nothing. It is composed without one.
  res := public.get_conversation_moment('menu_privacy_erased', null);
  perform pg_temp.chk('the closing words survive having no one left to look up',
    coalesce(res->>'body','') like '%مُحي كل شيء%', left(coalesce(res->>'body',''), 50));
end $$;


\echo '=== RESULTS ==='
\pset format unaligned
select lpad(n::text,2) || '  ' || rpad(result,6) || rpad(name, 60)
    || coalesce('  -> ' || left(replace(detail, chr(10), ' / '), 46), '')
from pg_temp.r order by n;
select E'\n' || count(*) filter (where result='PASS') || ' / ' || count(*) || ' passed'
from pg_temp.r;

rollback;
