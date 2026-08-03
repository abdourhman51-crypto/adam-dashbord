begin;

-- ============================================================
-- Three new n8n nodes, none of which could ever have worked.
--
-- FA - Country Ask?, M2 - Knowledge Depth and Tap - Record
-- Country were all added through the n8n MCP API. All three
-- saved cleanly, published cleanly, and failed at runtime with
-- «Credentials not found» the moment a real parent triggered
-- them. Tap - Record Country had been failing silently for two
-- days: every country button a parent tapped recorded nothing.
--
-- THE ACTUAL RULE, AFTER GETTING IT WRONG TWICE
--
-- First I claimed the missing credentials field in the JSON was
-- the blocker. It is not: Pin - Load, Pin - Surface and
-- Pin - Remember all report no credentials and all succeed on
-- live traffic.
--
-- Then I claimed typeVersion 4.2 was the cause and rebuilt the
-- node at 4.4. It failed again, two days later, at 4.4.
--
-- The truth is simpler and has no workaround:
--
--   Pre-existing nodes hold their credential SERVER-SIDE. The
--   API omits it from every response, which is why they look
--   bare. A node created through the MCP API genuinely has none,
--   and cannot be given one: both setNodeCredential and addNode
--   reject 'supabaseApi' on 'n8n-nodes-base.httpRequest'.
--
-- So the number of Supabase-authenticated nodes in this workflow
-- cannot go up. Not "should not" — cannot.
--
-- WHICH IS A BETTER CONSTRAINT THAN IT SOUNDS
--
-- The workaround that presented itself was to copy what
-- M2 - Get Memory Snapshot does: hardcode the apikey and
-- Authorization headers. That is the 116-times-in-plaintext
-- service_role key the founder still has to rotate, and adding
-- a 117th occurrence to work around a tooling limit is how that
-- number got to 116.
--
-- Instead: no new nodes. Two existing, already-authenticated
-- calls each carry more back. Three round trips become none, the
-- workflow gets smaller rather than larger, and nothing new
-- holds a secret.
-- ============================================================


-- ------------------------------------------------------------
-- get_agent_bundle — everything the conversational turn needs.
--
-- Replaces the get_agent_context call in M2 - Get Memory
-- Snapshot. Carries three things instead of one:
--
--   context     what we know about this family, PLAN_DAY and
--               DAYS_LEFT stripped — internal bookkeeping handed
--               to a language model is vocabulary it is
--               forbidden to use (P24)
--   knowledge   the level, and what ADAM may therefore CLAIM to
--               know. Stated as permission, not as a number: a
--               model told "level 2" invents a meaning for 2.
--   country_ask the claimed question, or nothing
--
-- Volatile, because take_country_ask claims. The claim now
-- happens before the reply is composed rather than after, which
-- widens the window in which a failed send spends the question
-- for nothing. That was already the accepted trade: asking a
-- family twice where they live, from something that claims to
-- remember them, is worse than asking once and losing it.
-- ------------------------------------------------------------
create or replace function public.get_agent_bundle(p_follower_id uuid)
returns jsonb
language plpgsql
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
begin
  if p_follower_id is null then
    return jsonb_build_object('context', '', 'knowledge_level', 0,
                              'family_context', '', 'ask', false);
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
    'ask_buttons', coalesce(v_ask->'buttons', '[]'::jsonb));
end;
$function$;

comment on function public.get_agent_bundle(uuid) is
  'Everything one conversational turn needs, in the single call an already-authenticated node was making anyway. Exists because n8n''s MCP API cannot attach a supabaseApi credential to a new httpRequest node, and the alternative — hardcoding the service_role key a fourth way — is how it came to appear 116 times in plaintext.';


-- ------------------------------------------------------------
-- get_moment_after_tap — records the country, then answers.
--
-- Replaces the get_conversation_moment call in Tap - Get Moment,
-- and retires Tap - Record Country, which never once ran.
--
-- Order matters and is the whole point: the country is written
-- BEFORE the moment is composed, so «سجّلنا: الجزائر» and the
-- price beneath it are read from a row that already exists. The
-- two-node version could not guarantee that, and would have
-- confirmed a country while quoting the wrong one.
-- ------------------------------------------------------------
create or replace function public.get_moment_after_tap(
  p_key          text,
  p_parent_id    uuid,
  p_country_code text default null)
returns jsonb
language plpgsql
security definer
set search_path to 'pg_catalog','public'
as $function$
declare v_rec jsonb;
begin
  if nullif(btrim(coalesce(p_country_code,'')), '') is not null then
    -- A refusal here is not an error: record_country rejects anything it
    -- cannot put on a clock, and the moment below then honestly reports
    -- that we still do not know where they are.
    v_rec := public.record_country(p_parent_id, p_country_code);
  end if;

  return public.get_conversation_moment(p_key, p_parent_id)
       || jsonb_build_object('country_recorded', coalesce(v_rec, 'null'::jsonb));
end;
$function$;

comment on function public.get_moment_after_tap(text, uuid, text) is
  'The tap handler: writes the country if one was tapped, then composes the answer — in that order, so the confirmation and the price are read from a row that already exists. Replaces a separate recording node that could never authenticate and had been silently discarding every country a parent chose.';


revoke all on function public.get_agent_bundle(uuid) from anon, authenticated, public;
revoke all on function public.get_moment_after_tap(text, uuid, text) from anon, authenticated, public;
grant execute on function public.get_agent_bundle(uuid) to service_role;
grant execute on function public.get_moment_after_tap(text, uuid, text) to service_role;

commit;
