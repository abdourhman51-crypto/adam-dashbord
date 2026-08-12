\set ON_ERROR_STOP on
begin;

-- ============================================================
-- THE ONES THAT LIVED ONLY IN THE DATABASE.
--
-- Restored on 2026-08-07 by 20260729000100. Every one of them had
-- been running in production for weeks with no source in git and
-- therefore no test — which is the same thing as no one knowing
-- what they do.
--
-- Two of them did not survive the day. get_free_session_state (the
-- eight-hour session gap, and the "golden" parent who came back
-- twice) and return_to_free (the legacy subscription reset) were
-- deleted hours later by 20260807200000: nothing called either —
-- neither is among the eleven Supabase endpoints W1 can reach —
-- and the founder's instruction was that nothing old survives.
-- Restoring them first was still right. A thing you cannot rebuild
-- is a thing you cannot safely delete, and their cases are in git
-- history rather than nowhere.
--
-- These cases do not re-describe the bodies. They assert the
-- promises the bodies make, in the words the comments use: a
-- recorded name is never replaced by a guess, an empty extraction
-- never overwrites a real memory, a sibling's nights are never
-- reassigned, and a blocked journey is withheld silently rather
-- than announced.
-- ============================================================

create table pg_temp.r (n int generated always as identity, name text, result text, detail text);
create or replace function pg_temp.chk(p_name text, p_cond boolean, p_detail text default null)
returns void language sql as $$
  insert into pg_temp.r (name, result, detail)
  values (p_name, case when p_cond then 'PASS' else 'FAIL' end, p_detail);
$$;

create or replace function pg_temp.parent(p_pid text, p_stage text default 'free_conversation')
returns uuid language plpgsql as $$
declare v uuid;
begin
  -- chk_active_has_expiry: paid access always has an end. A paid_active row
  -- with no subscription_expires_at is one production refuses, and the fixture
  -- had no such constraint.
  insert into public.followers (platform_user_id, country, funnel_stage, first_name,
                                subscription_expires_at)
  values (p_pid, 'DZ', p_stage, 'أمّ',
          case when p_stage = 'paid_active' then now() + interval '30 days' end)
  returning id into v;
  return v;
end $$;


\echo '=== _ensure_child: NEVER INVENTS A SIBLING ==='
do $$
declare p uuid; a uuid; b uuid; c uuid; n text;
begin
  p := pg_temp.parent('ec-1');

  a := public._ensure_child(p, 'يوسف');
  b := public._ensure_child(p, 'يوسف');
  perform pg_temp.chk('the same name twice is the same child, not two',
    a = b, a::text);

  -- A different name IS a different child. The upsert must not collapse them.
  c := public._ensure_child(p, 'ليان');
  perform pg_temp.chk('a different name is a different child',
    c <> a and (select count(*) from public.children where follower_id = p) = 2);

  -- No name: the primary child, never a guess between siblings.
  update public.children set is_primary = true where id = a;
  perform pg_temp.chk('no name resolves to the primary child',
    public._ensure_child(p, null) = a);

  perform pg_temp.chk('a blank name is treated as no name, not as a name',
    public._ensure_child(p, '   ') = a);
end $$;

do $$
declare p uuid; k uuid;
begin
  p := pg_temp.parent('ec-2');
  k := public._ensure_child(p, null);
  select name into strict k from public.children where id = k;
exception when others then null;
end $$;

do $$
declare p uuid; k uuid; nm text;
begin
  p := pg_temp.parent('ec-3');
  k := public._ensure_child(p, null);
  select name into nm from public.children where id = k;
  perform pg_temp.chk('a parent with no children at all gets one placeholder',
    nm = 'الطفل' and (select count(*) from public.children where follower_id = p) = 1, nm);
end $$;


\echo '=== write_child_name: A RECORDED NAME IS NOT A GUESS ==='
do $$
declare p uuid; c uuid; nm text;
begin
  p := pg_temp.parent('wcn-1');
  insert into public.children (follower_id, name, is_primary) values (p, 'يوسف', true) returning id into c;

  perform public.write_child_name('wcn-1', 'خالد');
  select name into nm from public.children where id = c;
  perform pg_temp.chk('a name already recorded is never replaced by a new inference',
    nm = 'يوسف', nm);
  perform pg_temp.chk('and no second child is created instead',
    (select count(*) from public.children where follower_id = p) = 1);
end $$;

do $$
declare p uuid; c uuid; d uuid;
begin
  p := pg_temp.parent('wcn-2');
  insert into public.children (follower_id, name, is_primary) values (p, '', true) returning id into c;
  insert into public.daily_logs (follower_id, log_date) values (p, current_date - 1);

  perform public.write_child_name('wcn-2', 'ريان');
  perform pg_temp.chk('an empty name IS filled in',
    (select name from public.children where id = c) = 'ريان');
  perform pg_temp.chk('and the orphan nights are back-linked to the only child',
    (select child_id from public.daily_logs where follower_id = p) = c);
end $$;

do $$
declare p uuid; c uuid;
begin
  p := pg_temp.parent('wcn-3');
  insert into public.children (follower_id, name, is_primary) values (p, '', true) returning id into c;
  insert into public.children (follower_id, name) values (p, 'ليان');
  insert into public.daily_logs (follower_id, log_date) values (p, current_date - 1);

  perform public.write_child_name('wcn-3', 'ريان');
  perform pg_temp.chk('with two children the orphan nights are LEFT orphaned',
    (select child_id from public.daily_logs where follower_id = p) is null,
    'a sibling''s nights must never be reassigned on a guess');
end $$;

do $$
begin
  perform public.write_child_name('wcn-nobody', 'ريان');
  perform pg_temp.chk('an unknown telegram id writes nothing and does not raise', true);
end $$;


\echo '=== writer_commit: MODEL OUTPUT IS NEVER TRUSTED ==='
do $$
declare p uuid; c uuid;
begin
  p := pg_temp.parent('wc-1', 'paid_active');
  c := public._ensure_child(p, null);   -- creates the 'الطفل' placeholder

  perform public.writer_commit(p, 10, jsonb_build_object(
    'children', jsonb_build_array(jsonb_build_object('name','  يوسف  ','gender','ذكر'))));

  perform pg_temp.chk('the placeholder is PROMOTED, not left beside the real name',
    (select count(*) from public.children where follower_id = p) = 1
    and (select name from public.children where id = c) = 'يوسف');
  perform pg_temp.chk('and the name arrives trimmed',
    exists (select 1 from public.children where follower_id = p and name = 'يوسف'));
end $$;

do $$
declare p uuid;
begin
  p := pg_temp.parent('wc-2', 'paid_active');

  perform public.writer_commit(p, 5, jsonb_build_object(
    'children', jsonb_build_array(jsonb_build_object('name','   ')),
    'events',   jsonb_build_array(jsonb_build_object('title','  ','child_name','ليان')),
    'patterns', jsonb_build_array(jsonb_build_object('pattern_label',''))));

  perform pg_temp.chk('a blank name writes no child',
    (select count(*) from public.children where follower_id = p) = 0);
  perform pg_temp.chk('a blank title writes no memory event',
    (select count(*) from public.memory_events where follower_id = p) = 0);
  perform pg_temp.chk('a blank label writes no pattern',
    (select count(*) from public.child_patterns where follower_id = p) = 0);
end $$;

do $$
declare p uuid; et text; w int;
begin
  p := pg_temp.parent('wc-3', 'paid_active');

  perform public.writer_commit(p, 5, jsonb_build_object(
    'events', jsonb_build_array(jsonb_build_object(
      'title','ليلة هادئة','child_name','ليان',
      'event_type','SOMETHING_THE_MODEL_MADE_UP','emotional_weight','99'))));

  select event_type, emotional_weight into et, w
    from public.memory_events where follower_id = p;
  perform pg_temp.chk('an invented event_type is clamped to other, not stored',
    et = 'other', et);
  perform pg_temp.chk('an out-of-range weight is clamped into 1..5',
    w = 5, w::text);
end $$;

do $$
declare p uuid; n int;
begin
  p := pg_temp.parent('wc-4', 'paid_active');

  perform public.writer_commit(p, 5, jsonb_build_object(
    'patterns', jsonb_build_array(jsonb_build_object('pattern_label','يرفض النوم وحده','child_name','ليان'))));
  perform public.writer_commit(p, 6, jsonb_build_object(
    'patterns', jsonb_build_array(jsonb_build_object('pattern_label','يرفض النوم وحده','child_name','ليان'))));

  select evidence_count into n from public.child_patterns where follower_id = p;
  perform pg_temp.chk('seeing a pattern twice raises the evidence, it does not duplicate the row',
    n = 2 and (select count(*) from public.child_patterns where follower_id = p) = 1, n::text);
end $$;

do $$
declare p uuid; hid int;
begin
  p := pg_temp.parent('wc-5', 'paid_active');

  perform public.writer_commit(p, 90, jsonb_build_object('snapshot_text','ما نعرفه عن البيت'));
  -- A later run that read FEWER messages must not drag the watermark backwards,
  -- or every message between 40 and 90 is extracted a second time.
  perform public.writer_commit(p, 40, jsonb_build_object('snapshot_text','تحديث'));

  select (built_from->>'last_history_id')::int into hid
    from public.memory_snapshots where follower_id = p;
  perform pg_temp.chk('the read watermark only ever moves forward',
    hid = 90, hid::text);

  perform public.writer_commit(p, 95, jsonb_build_object('snapshot_text','   '));
  perform pg_temp.chk('a blank snapshot never erases the one we had',
    (select snapshot_text from public.memory_snapshots where follower_id = p) = 'تحديث');
end $$;


\echo '=== get_extraction_batch: ONLY PAID, ONLY WHAT IS NEW ==='
do $$
declare p uuid; q uuid;
begin
  p := pg_temp.parent('gx-paid', 'paid_active');
  q := pg_temp.parent('gx-free');
  insert into public.n8n_chat_histories (session_id, message) values
    ('gx-paid', jsonb_build_object('type','human','content','ليلة صعبة')),
    ('gx-free', jsonb_build_object('type','human','content','ليلة صعبة'));

  perform pg_temp.chk('a paid parent with new messages is queued',
    exists (select 1 from public.get_extraction_batch() b where b.follower_id = p));
  perform pg_temp.chk('a free parent is not — W2 is the paid engine',
    not exists (select 1 from public.get_extraction_batch() b where b.follower_id = q));

  perform public.writer_commit(p, (select max(id)::int from public.n8n_chat_histories where session_id='gx-paid'),
                               jsonb_build_object('snapshot_text','ما نعرفه'));
  perform pg_temp.chk('and once summarised, they leave the queue',
    not exists (select 1 from public.get_extraction_batch() b where b.follower_id = p));
end $$;


\echo '=== get_conversation_for: THREE SESSION KEYS, ONE CONVERSATION ==='
do $$
declare n int;
begin
  insert into public.n8n_chat_histories (session_id, message) values
    ('7788',      jsonb_build_object('type','human','content','أ')),
    ('7788_s3',   jsonb_build_object('type','human','content','ب')),
    ('=7788',     jsonb_build_object('type','human','content','ج')),
    ('77889',     jsonb_build_object('type','human','content','ليس هو'));

  select count(*) into n from public.get_conversation_for('7788');
  perform pg_temp.chk('all three historical key shapes read as one conversation',
    n = 3, n::text);
  perform pg_temp.chk('and a different id that merely starts the same is not swept in',
    not exists (select 1 from public.get_conversation_for('7788') c
                where c.message->>'content' = 'ليس هو'));
end $$;


\echo '=== heart_commit: AN EMPTY MEMORY NEVER OVERWRITES A REAL ONE ==='
do $$
declare p uuid; before timestamptz; ok boolean;
begin
  p := pg_temp.parent('hc-1');

  ok := public.heart_commit('hc-1', jsonb_build_object('child_name','يوسف','core_pain','النوم'));
  perform pg_temp.chk('a memory with content is written', ok
    and (select light_memory from public.followers where id = p) is not null);

  select light_memory_updated_at into before from public.followers where id = p;

  ok := public.heart_commit('hc-1', jsonb_build_object(
    'child_name','','core_pain','','emotional_state','','last_win','','continuity',''));
  perform pg_temp.chk('all five fields blank writes nothing and reports it', not ok);
  perform pg_temp.chk('and does NOT stamp the clock, so she is retried next cycle',
    (select light_memory_updated_at from public.followers where id = p) = before);
  perform pg_temp.chk('and the real memory survives',
    (select light_memory from public.followers where id = p) like '%يوسف%');

  perform pg_temp.chk('a non-object payload is refused rather than stored',
    not public.heart_commit('hc-1', '"just a string"'::jsonb));
  perform pg_temp.chk('an unknown telegram id reports false, not success',
    not public.heart_commit('hc-nobody', jsonb_build_object('child_name','يوسف')));
end $$;


\echo '=== get_heart_batch: STALE ONLY, AND FREE ONLY ==='
do $$
declare p uuid; q uuid;
begin
  p := pg_temp.parent('hb-free');
  q := pg_temp.parent('hb-paid', 'paid_active');
  insert into public.n8n_chat_histories (session_id, message) values
    ('hb-free', jsonb_build_object('type','human','content','ليلة صعبة')),
    ('hb-paid', jsonb_build_object('type','human','content','ليلة صعبة'));

  perform pg_temp.chk('a free parent with no memory yet is queued',
    exists (select 1 from public.get_heart_batch() b where b.platform_user_id = 'hb-free'));
  perform pg_temp.chk('a paid parent is not — they have the full snapshot instead',
    not exists (select 1 from public.get_heart_batch() b where b.platform_user_id = 'hb-paid'));

  perform public.heart_commit('hb-free', jsonb_build_object('child_name','يوسف'));
  perform pg_temp.chk('once summarised with nothing newer said, they leave the queue',
    not exists (select 1 from public.get_heart_batch() b where b.platform_user_id = 'hb-free'));

  -- created_at is stamped explicitly. now() is transaction time, so a row
  -- inserted here would tie with light_memory_updated_at, and the freshness
  -- test is a strict `>`. In production the two writes are seconds and two
  -- transactions apart; inside one test transaction they are not.
  insert into public.n8n_chat_histories (session_id, message, created_at) values
    ('hb-free', jsonb_build_object('type','human','content','حدث شيء جديد'),
     now() + interval '1 minute');
  perform pg_temp.chk('and a new message puts them back',
    exists (select 1 from public.get_heart_batch() b where b.platform_user_id = 'hb-free'));
end $$;

do $$
declare p uuid; conv text;
begin
  p := pg_temp.parent('hb-fmt');
  insert into public.n8n_chat_histories (session_id, message) values
    ('hb-fmt', jsonb_build_object('type','human','content','ليلة صعبة')),
    ('hb-fmt', jsonb_build_object('type','ai','content','{"reply":"أنا معكم"}'));

  select b.conversation into conv from public.get_heart_batch() b where b.platform_user_id = 'hb-fmt';
  perform pg_temp.chk('a JSON reply is unwrapped to what the parent actually read',
    conv like '%آدم: أنا معكم%' and conv not like '%"reply"%', conv);
end $$;


\echo '=== check_daily_message_cap ==='
do $$
declare p uuid; q uuid; s record;
begin
  p := pg_temp.parent('cap-1');
  q := pg_temp.parent('cap-2');
  update public.followers set waitlist = true where id = q;

  select * into s from public.check_daily_message_cap(p);
  perform pg_temp.chk('asking IS the counting — one call, count 1',
    s.daily_count = 1 and s.cap = 68 and not s.is_over_cap);

  select * into s from public.check_daily_message_cap(p);
  perform pg_temp.chk('and the second call counts 2',
    s.daily_count = 2);

  select * into s from public.check_daily_message_cap(q);
  perform pg_temp.chk('a waitlisted parent has the tighter cap',
    s.cap = 15 and s.is_waitlisted);

  update public.followers set daily_msg_count = 68, daily_msg_date = current_date where id = p;
  select * into s from public.check_daily_message_cap(p);
  perform pg_temp.chk('the cap trips at 69, not at 68',
    s.daily_count = 69 and s.is_over_cap);

  update public.followers set daily_msg_count = 40, daily_msg_date = current_date - 1 where id = p;
  select * into s from public.check_daily_message_cap(p);
  perform pg_temp.chk('yesterday''s count does not follow her into today',
    s.daily_count = 1);

  select * into s from public.check_daily_message_cap(gen_random_uuid());
  perform pg_temp.chk('an unknown parent returns a row rather than nothing',
    s.daily_count = 0 and not s.is_over_cap);
end $$;


\echo '=== surface_changing_item: A WITHHELD JOURNEY IS SILENT ==='
do $$
declare blocked jsonb; normal jsonb;
begin
  normal  := public.surface_changing_item('rhythm', false, true,  true, null);
  blocked := public.surface_changing_item('rhythm', false, false, true, null);
  perform pg_temp.chk('when commerce is blocked the label is IDENTICAL to the normal one',
    blocked->>'label' = normal->>'label',
    'she is never told a thing is being withheld from her');

  perform pg_temp.chk('paused names her own choice back to her',
    public.surface_changing_item('rhythm', true, true, true, null)->>'meaning' = 'resume');
  perform pg_temp.chk('and paused outranks everything, including a live journey',
    public.surface_changing_item('journey_active', true, true, true, 'النوم')->>'meaning' = 'resume');

  perform pg_temp.chk('an unsupported country is offered the waitlist, not a price',
    public.surface_changing_item('rhythm', false, true, false, null)->>'meaning' = 'waitlist');
  perform pg_temp.chk('but a blocked-commerce parent is NOT offered it either',
    public.surface_changing_item('rhythm', false, false, false, null)->>'meaning' = 'open_question');

  perform pg_temp.chk('a live journey asks after the goal by name',
    public.surface_changing_item('journey_active', false, true, true, 'النوم')->>'label' = 'كيف تسير رحلة النوم؟');
  perform pg_temp.chk('and with no goal named it still asks, without a blank',
    public.surface_changing_item('journey_active', false, true, true, null)->>'label' = 'كيف تسير الرحلة؟');
end $$;


\echo '=== set_updated_at: EIGHT TABLES HANG A TRIGGER OFF THIS ==='
-- The fixture carries no triggers, so the trigger is created here on a throwaway
-- table. Asserting the function through the mechanism that actually invokes it
-- is the only way to test a trigger function at all.
create table pg_temp.t_sua (id int primary key, note text, updated_at timestamptz);
create trigger t_sua_updated before update on pg_temp.t_sua
  for each row execute function public.set_updated_at();

do $$
declare t1 timestamptz; t2 timestamptz;
begin
  insert into pg_temp.t_sua (id, note, updated_at) values (1, 'أ', '2020-01-01');
  select updated_at into t1 from pg_temp.t_sua where id = 1;

  update pg_temp.t_sua set note = 'ب' where id = 1;
  select updated_at into t2 from pg_temp.t_sua where id = 1;

  perform pg_temp.chk('an update stamps updated_at without the writer naming it',
    t1 = '2020-01-01'::timestamptz and t2 > t1, t2::text);

  -- A writer that sets updated_at itself must still lose to the trigger, or a
  -- stale value copied from an old row would silently look fresh. It is checked
  -- against t2 rather than "later than t2": now() is transaction time, so the
  -- two stamps are equal inside one test — the point is that 2019 is discarded.
  update pg_temp.t_sua set note = 'ج', updated_at = '2019-01-01' where id = 1;
  perform pg_temp.chk('and a writer that sets it by hand does not win',
    (select updated_at from pg_temp.t_sua where id = 1) = t2);
end $$;


\echo '=== RESULTS ==='
\pset format unaligned
select lpad(n::text,2) || '  ' || rpad(result,6) || rpad(name, 68)
    || coalesce('  -> ' || left(replace(detail, chr(10), ' / '), 46), '')
from pg_temp.r order by n;
select E'\n' || count(*) filter (where result='PASS') || ' / ' || count(*) || ' passed'
from pg_temp.r;

rollback;
