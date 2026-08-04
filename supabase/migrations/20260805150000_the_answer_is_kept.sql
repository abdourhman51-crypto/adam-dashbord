-- ============================================================
-- The answer is kept.
--
-- §10 item 4, the half that was never finished.
--
-- `intention_ask` asks a parent the one question the whole
-- promise hangs on — «أيّ أب أو أمّ تمنّيتم أن تكونوا له؟» —
-- and then throws their answer away. `record_intention()` has
-- existed, tested, since `give_before_asking`, called from
-- nowhere. The parent types the most personal sentence they
-- will ever type into this product, and ADAM replies to it as
-- if it were small talk about bedtime.
--
-- That is not a missing feature. It is the product asking a
-- question it does not listen to.
--
-- Two things ship here:
--
--   1. `capture_intention()` — the whole decision in one place:
--      is this parent actually awaiting, is this message
--      actually an answer, and if so keep it and hand back the
--      words to say. Every guard is here, not in a Code node,
--      so the rule is testable without n8n.
--
--   2. `get_agent_bundle()` learns to carry it. No new node.
--      The reply path already makes exactly one authenticated
--      call per message — `M2 - Get Memory Snapshot` — and the
--      README says plainly why the count cannot go up: n8n's
--      MCP API cannot attach a `supabaseApi` credential to a
--      new httpRequest node, and the workaround is how the
--      service_role key came to sit in plaintext 116 times.
--      So the call that is already being made does one more
--      thing, and the branching happens in credential-free
--      IF nodes.
--
-- What this deliberately does NOT do: guess. If the message
-- does not look like an answer to that question — a command, a
-- question back, an essay, a message three days late — nothing
-- is captured and the parent gets their ordinary reply. The
-- intention is written once and never overwritten, so a wrong
-- capture is permanent. Declining is cheap; guessing is not.
-- ============================================================

begin;

-- ------------------------------------------------------------
-- The ask now says how to answer.
--
-- It had no buttons by design — an intention cannot be picked
-- from a list — but it also never told the parent that typing
-- was the move. A message with no buttons and no instruction
-- reads as an announcement, not a question, and an announcement
-- gets no reply.
-- ------------------------------------------------------------
update public.conversation_moments
set max_lines = 3,
    body_ar = 'سؤال واحد، ولن أعيده.' || chr(10) ||
              'قبل أن يأتي — أيّ أب أو أمّ تمنّيتم أن تكونوا له؟' || chr(10) ||
              'اكتبوها بكلماتكم الآن، سطر واحد يكفي.',
    note = 'Asked once, ever, and only after something has already worked. The anchor of the promise: without it "closer to who you meant to be" has no referent. ADAM never measures the distance to it — only shows approach. The third line exists because a buttonless message with no instruction reads as an announcement, and an announcement gets no reply — and the answer is now captured (capture_intention).'
where key = 'intention_ask';

-- ------------------------------------------------------------
-- And the answer now gets an answer.
--
-- Not a receipt. A parent who has just written who they hoped
-- to be does not need «تم الحفظ» — they need to know what that
-- sentence is now FOR. So the moment says exactly three things:
-- it is enough, it will not be asked again, and here is how it
-- will show up from now on.
--
-- No promise that they will become it. §10: ADAM shows approach,
-- never distance.
-- ------------------------------------------------------------
insert into public.conversation_moments
  (key, category, tier, body_ar, buttons, max_lines, requires_commerce, note)
values
  ('intention_kept', 'rhythm', 'fixed',
   '🌱 هذه الجملة تكفي، ولن أسألكم عنها ثانية.' || chr(10) || chr(10) ||
   'لن أطلب منكم أن تصيروها هذه الليلة.' || chr(10) ||
   'لكن في كلّ مرّة يهدأ شيء، سأريكم أنّكم اقتربتم منها خطوة.',
   '[{"label":"💬 عندي موقف الآن","cb":"other"}]'::jsonb,
   3, false,
   'The reply to a captured intention. Says what the sentence is for, not that it was stored. The escape button matters more here than elsewhere: this is the one moment ADAM answers a typed message with fixed copy, so the parent must be one tap from the ordinary conversation if the capture read them wrong.')
on conflict (key) do update
  set body_ar = excluded.body_ar, buttons = excluded.buttons,
      max_lines = excluded.max_lines, note = excluded.note;


-- ------------------------------------------------------------
-- capture_intention — one place decides.
--
-- Returns the moment payload on success, in the same shape
-- get_conversation_moment() returns, so the sender that already
-- knows how to render a moment needs no new code.
--
-- The guards, and why each one is here:
--
--   not_awaiting  — never asked, or already answered. The write
--                   itself refuses to overwrite, but declining
--                   early means we never reply with the ack to
--                   a parent whose answer was already kept.
--   window_closed — the ask rides the evening harvest. An answer
--                   comes that night or the next morning. Three
--                   days later, «ابني تعبان» is not an intention,
--                   it is a Tuesday.
--   too_short     — «ok», «نعم». An acknowledgement, not an answer.
--   too_long      — an intention is a sentence. 240 characters of
--                   text is a parent telling us what happened,
--                   and that belongs to the conversation.
--   command       — /start, /faq. Never an answer.
--   a_question    — a parent who ends with ؟ is asking, not
--                   answering. This one catches «كيف يعني؟» —
--                   the most likely reply to a question a parent
--                   did not expect.
--   not_a_sentence— four lines or more is a story.
--
-- Everything that is declined falls through to the ordinary
-- reply. Nothing is lost, nothing is answered wrongly.
-- ------------------------------------------------------------
create or replace function public.capture_intention(
  p_parent_id uuid, p_text text)
returns jsonb
language plpgsql
volatile
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  v_asked timestamptz;
  v_have  text;
  v_clean text;
begin
  if p_parent_id is null then
    return jsonb_build_object('captured', false, 'reason', 'no_parent');
  end if;

  select f.intention_asked_at, f.intention_text into v_asked, v_have
  from public.followers f where f.id = p_parent_id;

  if not found or v_asked is null or v_have is not null then
    return jsonb_build_object('captured', false, 'reason', 'not_awaiting');
  end if;

  if now() - v_asked > interval '36 hours' then
    return jsonb_build_object('captured', false, 'reason', 'window_closed');
  end if;

  v_clean := nullif(btrim(coalesce(p_text, ''), E' \t\r\n'), '');

  if v_clean is null or length(v_clean) < 3 then
    return jsonb_build_object('captured', false, 'reason', 'too_short');
  end if;
  if length(v_clean) > 240 then
    return jsonb_build_object('captured', false, 'reason', 'too_long');
  end if;
  if left(v_clean, 1) = '/' then
    return jsonb_build_object('captured', false, 'reason', 'command');
  end if;
  if right(v_clean, 1) in ('؟', '?') then
    return jsonb_build_object('captured', false, 'reason', 'a_question');
  end if;
  if public.content_line_count(v_clean) > 3 then
    return jsonb_build_object('captured', false, 'reason', 'not_a_sentence');
  end if;

  -- record_intention() is the only writer, and it refuses to
  -- overwrite. If it returns false here, two messages raced and
  -- the other one won — say nothing, let the ordinary reply run.
  if not public.record_intention(p_parent_id, v_clean) then
    return jsonb_build_object('captured', false, 'reason', 'race_lost');
  end if;

  return jsonb_build_object('captured', true)
      || public.get_conversation_moment('intention_kept', p_parent_id);
end;
$function$;

comment on function public.capture_intention(uuid, text) is
  'Whether this message is the parent''s answer to the once-ever intention question, and if so keeps it and returns the words to reply with. Declines on anything that does not look like an answer — the intention is written once and never overwritten, so a wrong capture is permanent.';


-- ------------------------------------------------------------
-- get_agent_bundle now carries the capture.
--
-- Two arities, no default: a default would make the one-argument
-- call ambiguous and break the live node between apply and
-- publish. The old signature stays as a thin forward so nothing
-- that calls it can notice.
--
-- On a capture the bundle short-circuits: no context is built,
-- no country ask is stamped. A parent who just answered the
-- intention question is not also asked where they live, and a
-- spent country stamp on a message that never reaches the model
-- would cost an ask for nothing.
-- ------------------------------------------------------------
create or replace function public.get_agent_bundle(
  p_follower_id uuid, p_message text)
returns jsonb
language plpgsql
volatile
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  v_ctx   text;
  v_kd    jsonb;
  v_ask   jsonb;
  v_level integer;
  v_perm  text;
  v_known text;
  v_cap   jsonb;
begin
  if p_follower_id is null then
    return jsonb_build_object('context', '', 'knowledge_level', 0,
                              'family_context', '', 'ask', false,
                              'intention_captured', false);
  end if;

  -- Before anything else: is this message the answer to the one
  -- question we promised not to repeat?
  if p_message is not null then
    v_cap := public.capture_intention(p_follower_id, p_message);
    if coalesce((v_cap->>'captured')::boolean, false) then
      return jsonb_build_object(
        'intention_captured', true,
        'intention_body',     v_cap->>'body',
        'intention_buttons',  coalesce(v_cap->'buttons', '[]'::jsonb),
        -- Defaults so nothing downstream reads a missing key.
        'context', '', 'knowledge_level', 0, 'family_context', '',
        'ask', false, 'ask_body', null, 'ask_buttons', '[]'::jsonb);
    end if;
  end if;

  v_ctx := coalesce(public.get_agent_context(p_follower_id), '');

  -- PLAN_DAY / DAYS_LEFT are ours, not theirs.
  --
  -- The trim character set is not decoration. Single-argument btrim() removes
  -- SPACES ONLY, so stripping those two lines left a bare newline behind, the
  -- context tested as non-empty, and a parent ADAM knows nothing about got an
  -- empty block instead of the sentence saying so — a machine that looks like
  -- it is withholding rather than one that is honest about knowing nothing.
  v_ctx := btrim((
    select coalesce(string_agg(l, chr(10)), '')
    from regexp_split_to_table(v_ctx, chr(10)) l
    where l !~ '^\s*(PLAN_DAY|DAYS_LEFT)\s*:'), E' \t\r\n');

  v_kd    := public.knowledge_depth(p_follower_id);
  v_level := coalesce((v_kd->>'level')::int, 0);

  v_perm := case v_level
    when 0 then 'لا تعرف عن هذا البيت شيئاً بعد. أجب عن اللحظة التي أمامك فقط، ولا تُلمّح إلى أنك تتذكّر شيئاً.'
    when 1 then 'تعرف اسم الطفل فقط. استعمله بطبيعية، ولا تدّعِ معرفة بما يتكرّر معه.'
    when 2 then 'تعرف الاسم وما يُتعب عادةً. يمكنك أن تقترح شيئاً صغيراً موجّهاً لذلك الموقف بالذات.'
    when 3 then 'تعرف ما يتكرّر فعلاً. يمكنك أن تذكر ما لاحظتَه مرّة واحدة، بلا مبالغة.'
    else        'تعرف هذا البيت جيّداً. يمكنك أن تسمّي هدفاً واضحاً إن كان الوقت مناسباً.'
  end;

  v_known := case when v_ctx = '' then 'لا شيء مسجّل عن هذا البيت بعد.' else v_ctx end;

  v_ask := public.take_country_ask(p_follower_id);

  return jsonb_build_object(
    'context',         v_ctx,
    'knowledge_level', v_level,
    -- One block, framed as OUR notes. Without the frame the model reads its
    -- own context as something the parent just said and answers a question
    -- nobody asked.
    'family_context',
      '[ما نعرفه عن هذا البيت — ملاحظاتنا نحن، لم يقلها الأهل الآن]' || chr(10)
      || v_known || chr(10) || chr(10)
      || '[ما يُسمح لك أن تدّعي معرفته]' || chr(10) || v_perm,
    'ask',         coalesce((v_ask->>'ask')::boolean, false),
    'ask_body',    v_ask->>'body',
    'ask_buttons', coalesce(v_ask->'buttons', '[]'::jsonb),
    'intention_captured', false);
end;
$function$;

create or replace function public.get_agent_bundle(p_follower_id uuid)
returns jsonb
language sql
volatile
security definer
set search_path to 'pg_catalog','public'
as $function$
  select public.get_agent_bundle(p_follower_id, null::text);
$function$;

comment on function public.get_agent_bundle(uuid, text) is
  'The one authenticated call the reply path makes per message: the family context, what ADAM may claim to know, the country question — and, first, whether this message is the answer to the once-ever intention question, in which case it short-circuits and hands back the reply instead of the context.';


revoke all on function public.capture_intention(uuid, text)   from anon, authenticated, public;
revoke all on function public.get_agent_bundle(uuid, text)    from anon, authenticated, public;
revoke all on function public.get_agent_bundle(uuid)          from anon, authenticated, public;

grant execute on function public.capture_intention(uuid, text) to service_role;
grant execute on function public.get_agent_bundle(uuid, text)  to service_role;
grant execute on function public.get_agent_bundle(uuid)        to service_role;

commit;
