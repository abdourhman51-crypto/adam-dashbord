-- ============================================================
-- The knowledge level becomes a move-set, not just a prose suggestion —
-- and the paid journey gets its behavioural directive.
-- Design: docs/adam-under-the-microscope.md, The ADAM Contract.
--
-- Two changes to get_agent_bundle, both additive:
--
--   1. The permission line is rewritten from soft prose ("يمكنك أن...")
--      to an explicit allow/forbid pair per level, phrased to match
--      exactly what gate_grounded_reply (next migration) actually
--      enforces — so the prompt's bias and the gate's guarantee agree.
--      knowledge_depth()'s own now_possible array is the single source
--      for what unlocks at each level; this does not re-derive it.
--
--   2. A JOURNEY directive is appended when stage_state (already called
--      in get_agent_context) reports a live stage: phase-specific
--      behaviour — observe/build proceed as today's step logic already
--      implies, hold explicitly forbids proposing a new step, matching
--      compose_journey_step's own discipline (never contradicting it,
--      just applied to the reactive surface too).
--
-- Enforcement is NOT this migration. The prompt reduces violations;
-- gate_grounded_reply (next migration), which re-derives knowledge_level
-- independently at gate time rather than trusting what the model was
-- told, is what a violation cannot get past.
-- ============================================================

begin;

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
  v_team  jsonb;
  v_stage jsonb;
  v_journey_directive text := '';
begin
  if p_follower_id is null then
    return jsonb_build_object('context', '', 'knowledge_level', 0,
                              'family_context', '', 'ask', false,
                              'handled', false, 'intention_captured', false);
  end if;

  -- Theirs, not ours. Checked before the intention capture, which would
  -- otherwise write «اشتراك» into the parent's intention forever.
  if p_message is not null and public.is_team_question(p_message) then
    v_team := public.get_conversation_moment('menu_ask_team', p_follower_id);
    if coalesce((v_team->>'found')::boolean, false) then
      return jsonb_build_object(
        'handled',            true,
        'handled_reason',     'team_question',
        'handled_body',       v_team->>'body',
        'handled_buttons',    coalesce(v_team->'buttons', '[]'::jsonb),
        'intention_captured', false,
        'context', '', 'knowledge_level', 0, 'family_context', '',
        'ask', false, 'ask_body', null, 'ask_buttons', '[]'::jsonb);
    end if;
  end if;

  -- Is this message the answer to the one question we promised not to repeat?
  if p_message is not null then
    v_cap := public.capture_intention(p_follower_id, p_message);
    if coalesce((v_cap->>'captured')::boolean, false) then
      return jsonb_build_object(
        'handled',            true,
        'handled_reason',     'intention_kept',
        'handled_body',       v_cap->>'body',
        'handled_buttons',    coalesce(v_cap->'buttons', '[]'::jsonb),
        'intention_captured', true,
        'intention_body',     v_cap->>'body',
        'intention_buttons',  coalesce(v_cap->'buttons', '[]'::jsonb),
        'context', '', 'knowledge_level', 0, 'family_context', '',
        'ask', false, 'ask_body', null, 'ask_buttons', '[]'::jsonb);
    end if;
  end if;

  v_ctx := coalesce(public.get_agent_context(p_follower_id), '');

  -- PLAN_DAY / DAYS_LEFT are ours, not theirs. The JOURNEY block (new,
  -- lines prefixed "- ") is deliberately NOT stripped here — it is
  -- progress the family earned, not a billing clock, and the whole
  -- point of this migration is that the agent may see it.
  v_ctx := btrim((
    select coalesce(string_agg(l, chr(10)), '')
    from regexp_split_to_table(v_ctx, chr(10)) l
    where l !~ '^\s*(PLAN_DAY|DAYS_LEFT)\s*:'), E' \t\r\n');

  v_kd    := public.knowledge_depth(p_follower_id);
  v_level := coalesce((v_kd->>'level')::int, 0);

  -- ⭐1 Rewritten to name the forbidden move explicitly, in the same terms
  -- gate_grounded_reply checks — a false "yes you may" here would just be
  -- overruled at the gate, so the two must describe the same line.
  v_perm := case v_level
    when 0 then 'لا تعرف عن هذا البيت شيئاً بعد. أجب عن اللحظة التي أمامك فقط. ممنوع: أي اسم، أي تكرار، أي إشارة إلى ذاكرة أو سجلّ — لا شيء من هذا موجود بعد.'
    when 1 then 'تعرف اسم الطفل فقط. استعمله بطبيعية. ممنوع: الادّعاء بمعرفة ما يتكرّر معه أو نمط له — لم تريا ذلك بعد.'
    when 2 then 'تعرف الاسم وما يُتعب عادةً. يمكنك أن تقترح شيئاً صغيراً موجّهاً لذلك الموقف. ممنوع: قول «هذه المرة الثالثة» أو أي عدد تكرار — لم يُثبت نمط بعد.'
    when 3 then 'تعرف ما يتكرّر فعلاً — يمكنك أن تذكر ذلك مرّة، بلا مبالغة ولا رقم مختلق.'
    else        'تعرف هذا البيت جيّداً. يمكنك أن تسمّي هدفاً واضحاً إن كان الوقت مناسباً.'
  end;

  v_known := case when v_ctx = '' then 'لا شيء مسجّل عن هذا البيت بعد.' else v_ctx end;

  v_ask := public.take_country_ask(p_follower_id);

  -- ⭐2 The journey directive. stage_state() is the single source for
  -- phase; this only renders behaviour for it, exactly as
  -- compose_journey_step renders behaviour for the SAME phase value on
  -- the proactive side. Absent for a free parent (in_stage=false).
  v_stage := public.stage_state(p_follower_id);
  if coalesce((v_stage->>'in_stage')::boolean, false) then
    v_journey_directive := case v_stage->>'phase'
      when 'observe' then
        'العائلة في رحلة مدفوعة، طور المراقبة. لا تقترح خطوة جديدة — الهدف الآن أن تُلاحَظ ' ||
        'اللحظة الصعبة، لا أن تُغيَّر. إن سُئلت عن الهدف فاذكره كما هو في JOURNEY.'
      when 'hold' then
        'العائلة في رحلة مدفوعة، طور الإمساك. ممنوع اقتراح أي خطوة جديدة في هذا الطور — ' ||
        'العائلة تعرف الآن ما ينفع، ودورك أن تسأل عن الليلة بلا اقتراح، ليُرى الهدوء أنه ملكهم.'
      else
        'العائلة في رحلة مدفوعة، طور البناء. يمكنك أن تشير إلى الهدف المتّفق عليه إن سُئلت، ' ||
        'وأن تبني على ما نفع سابقاً إن ورد في JOURNEY أو RECENT_DAYS.'
    end;
  end if;

  return jsonb_build_object(
    'context',         v_ctx,
    'knowledge_level', v_level,
    'allowed_moves',   coalesce(v_kd->'now_possible', '[]'::jsonb),
    'in_journey',      coalesce((v_stage->>'in_stage')::boolean, false),
    -- One block, framed as OUR notes. Without the frame the model reads its
    -- own context as something the parent just said and answers a question
    -- nobody asked.
    'family_context',
      '[ما نعرفه عن هذا البيت — ملاحظاتنا نحن، لم يقلها الأهل الآن]' || chr(10)
      || v_known || chr(10) || chr(10)
      || '[ما يُسمح لك أن تدّعي معرفته]' || chr(10) || v_perm
      || case when v_journey_directive <> '' then
           chr(10) || chr(10) || '[الرحلة]' || chr(10) || v_journey_directive
         else '' end,
    'ask',         coalesce((v_ask->>'ask')::boolean, false),
    'ask_body',    v_ask->>'body',
    'ask_buttons', coalesce(v_ask->'buttons', '[]'::jsonb),
    'handled', false,
    'intention_captured', false);
end;
$function$;

comment on function public.get_agent_bundle(uuid, text) is
  'The context and permission block for the conversational agent, and — for a parent in a live paid stage — the journey directive matching compose_journey_step''s own phase discipline (silent in hold). The permission line names the same violations gate_grounded_reply enforces, so prompt bias and gate guarantee agree; the level-gate here is advisory, the gate is authoritative. Team questions and kept intentions still short-circuit before any of this runs.';

commit;
