-- The commercial fork stops waiting in a buried menu item.
--
-- take_offer_moment() + offer_ready() already existed: a genuine,
-- evidence-gated (situation confirmed + 3 tried steps + 2 calm nights),
-- once-only ('offer_fork_at is null' guard) natural fork -- "we noticed
-- something repeating with X. do we work on it, or let it keep happening?"
-- The ONLY place that ever called it was get_harvest_context(), itself only
-- reachable when a parent replies 'ok' to the nightly harvest question --
-- and the harvest loop is barely used (117 seeds sent, 27 harvested, ever).
-- get_agent_bundle() -- read on EVERY ordinary free-conversation turn, the
-- one path every parent actually uses -- never checked it at all. The offer
-- was reachable only through a sidebar item ('menu_journey') nobody opens
-- unprompted: 8 of 328 real followers ever reached offer_presented.
--
-- This wires the same, already-correct mechanic into the main turn, so the
-- fork can fire the moment the evidence bar is actually crossed, in
-- whatever conversation the parent is already having -- not a separate
-- menu, not a campaign. Two bugs found alongside it, fixed here too:
--   - take_offer_moment's buttons pointed at cb values that don't exist
--     ('cta_full_companion', 'not_now') -- tapping either did nothing.
--     Now reuse the real, tested callbacks: 'menu_journey' (the actual
--     commercial screen) and 'menu_not_now' (the actual decline moment).
--   - get_agent_bundle now only offers the fork when the turn isn't
--     already asking for the country, and the parent isn't already in a
--     stage or already agreed -- so it never competes with a higher-
--     priority turn or re-pitches someone already past this point.

create or replace function public.take_offer_moment(p_parent_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'pg_catalog', 'public'
as $function$
declare
  v_offer jsonb;
begin
  v_offer := public.offer_ready(p_parent_id);

  if not coalesce((v_offer->>'ready')::boolean, false) then
    return jsonb_build_object('present', false);
  end if;

  update public.followers
     set offer_fork_at = now()
   where id = p_parent_id and offer_fork_at is null;

  if not found then
    return jsonb_build_object('present', false);
  end if;

  return jsonb_build_object(
    'present', true,
    'fork_ar', v_offer->>'fork_ar',
    'buttons', jsonb_build_array(
      jsonb_build_object('label', 'نشتغل عليه',  'cb', 'menu_journey'),
      jsonb_build_object('label', 'نتركه يتكرّر', 'cb', 'menu_not_now')));
end;
$function$;

create or replace function public.get_agent_bundle(p_follower_id uuid, p_message text)
returns jsonb
language plpgsql
security definer
set search_path to 'pg_catalog', 'public'
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
  v_offer jsonb;
  v_journey_directive text := '';
  v_curve       jsonb;
  v_curve_block text := '';
  v_held  int; v_erupt int; v_held_p int; v_erupt_p int; v_delta int;
begin
  if p_follower_id is null then
    return jsonb_build_object('context', '', 'knowledge_level', 0,
                              'family_context', '', 'ask', false,
                              'handled', false, 'intention_captured', false);
  end if;

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

  v_ctx := btrim((
    select coalesce(string_agg(l, chr(10)), '')
    from regexp_split_to_table(v_ctx, chr(10)) l
    where l !~ '^\s*(PLAN_DAY|DAYS_LEFT)\s*:'), E' \t\r\n');

  v_kd    := public.knowledge_depth(p_follower_id);
  v_level := coalesce((v_kd->>'level')::int, 0);

  v_perm := case v_level
    when 0 then 'لا تعرف عن هذا البيت شيئاً بعد. أجب عن اللحظة التي أمامك فقط. ممنوع: أي اسم، أي تكرار، أي إشارة إلى ذاكرة أو سجلّ — لا شيء من هذا موجود بعد.'
    when 1 then 'تعرف اسم الطفل فقط. استعمله بطبيعية. ممنوع: الادّعاء بمعرفة ما يتكرّر معه أو نمط له — لم تريا ذلك بعد.'
    when 2 then 'تعرف الاسم وما يُتعب عادةً. يمكنك أن تقترح شيئاً صغيراً موجّهاً لذلك الموقف. ممنوع: قول «هذه المرة الثالثة» أو أي عدد تكرار — لم يُثبت نمط بعد.'
    when 3 then 'تعرف ما يتكرّر فعلاً — يمكنك أن تذكر ذلك مرّة، بلا مبالغة ولا رقم مختلق.'
    else        'تعرف هذا البيت جيّداً. يمكنك أن تسمّي هدفاً واضحاً إن كان الوقت مناسباً.'
  end;

  v_curve := public.get_parent_curve(p_follower_id);
  if coalesce((v_curve->>'ready')::boolean, false) then
    v_perm := v_perm || ' وتعرف كم مرّة تماسك الوالد وكم مرّة انفجر — هذه أرقامه هو، ويجوز أن تقولها بالرقم مرّة واحدة.';
  else
    v_perm := v_perm || ' ولا تعرف بعدُ كيف يتصرّف الوالد نفسه في اللحظة الصعبة — ممنوع أن تدّعي أنه يتحسّن أو يتراجع، ولا أن تعطيه رقماً عن نفسه.';
  end if;

  if coalesce((v_curve->>'ready')::boolean, false) then
    v_held    := coalesce((v_curve->>'heldWeek')::int, 0);
    v_erupt   := coalesce((v_curve->>'eruptWeek')::int, 0);
    v_held_p  := coalesce((v_curve->>'heldPrev')::int, 0);
    v_erupt_p := coalesce((v_curve->>'eruptPrev')::int, 0);
    v_delta   := v_erupt - v_erupt_p;

    v_curve_block :=
         'هذا الأسبوع: تماسكوا ' || v_held::text || '، وانفجروا ' || v_erupt::text || '.'
      || ' والأسبوع الذي قبله: ' || v_held_p::text || ' و' || v_erupt_p::text || '.' || chr(10)
      || case
           when v_delta < 0 then 'الاتجاه: انفجارات أقلّ بـ ' || abs(v_delta)::text || '.'
           when v_delta > 0 then 'الاتجاه: أسبوع أثقل من الذي قبله.'
           else                  'الاتجاه: ثابت.'
         end || chr(10)
      || 'اذكره مرّة واحدة بالرقم إن تحسّن. وإن ساء فلا تذكره إلا إن سألوا. ولا تجعله مطلباً — لو كانوا يقدرون لفعلوا، والخطوة هي ما يجعلهم يقدرون.';
  end if;

  v_known := case when v_ctx = '' then 'لا شيء مسجّل عن هذا البيت بعد.' else v_ctx end;

  v_ask := public.take_country_ask(p_follower_id);

  v_stage := public.stage_state(p_follower_id);
  if coalesce((v_stage->>'in_stage')::boolean, false) then
    v_journey_directive := case v_stage->>'phase'
      when 'observe' then
        'العائلة في رحلة مدفوعة، طور المراقبة. لا تقترح خطوة تغييرية جديدة كجزء من المنهجية، حتى لو طُلبت منك صراحة — ' ||
        'الهدف الآن أن تُلاحَظ اللحظة الصعبة، لا أن تُغيَّر. إن سُئلت عن الهدف فاذكره كما هو في JOURNEY. ' ||
        'استثناء واحد فقط: لو الموقف حيّ الآن (الطفل في ضيق فعلي هذه اللحظة) والوالد يطلب فعلاً فورياً، أعطِ سطر احتواء آمن ' ||
        'ومحايد واحد بلا وصفه كخطوة أو تغيير منهج، ثم عد للمراقبة بلا سؤال إضافي.'
      when 'hold' then
        'العائلة في رحلة مدفوعة، طور الإمساك. ممنوع اقتراح أي خطوة جديدة في هذا الطور، حتى لو طُلبت منك صراحة — ' ||
        'العائلة تعرف الآن ما ينفع، ودورك أن تسأل عن الليلة بلا اقتراح، ليُرى الهدوء أنه ملكهم. ' ||
        'استثناء واحد فقط: لو الموقف حيّ الآن والوالد يطلب إسعافاً فورياً حقيقياً، أعطِ سطر احتواء آمن واحد بلا وصفه كخطوة، ثم عد لدورك المعتاد في هذا الطور.'
      else
        'العائلة في رحلة مدفوعة، طور البناء. يمكنك أن تشير إلى الهدف المتّفق عليه إن سُئلت، ' ||
        'وأن تبني على ما نفع سابقاً إن ورد في JOURNEY أو RECENT_DAYS.'
    end;

    v_journey_directive := v_journey_directive ||
      ' والهدف المذكور في JOURNEY هدفُ الوالد عن نفسه، لا مطلبٌ من الطفل — ' ||
      'وأي خطوة تعطيها يفعلها الوالد، لا الطفل.';
  end if;

  -- ⭐ The natural commercial fork, wired into the one path every parent
  -- actually uses. Only when this turn isn't already asking for the
  -- country, and the parent isn't already in a stage or already agreed —
  -- take_offer_moment() itself still owns the real evidence gate
  -- (offer_ready) and the once-only guard (offer_fork_at is null).
  v_offer := jsonb_build_object('present', false);
  if not coalesce((v_ask->>'ask')::boolean, false)
     and not coalesce((v_stage->>'in_stage')::boolean, false)
     and not exists (
       select 1 from public.followers
       where id = p_follower_id and agreed_objective is not null
     )
  then
    v_offer := public.take_offer_moment(p_follower_id);
  end if;

  return jsonb_build_object(
    'context',         v_ctx,
    'knowledge_level', v_level,
    'allowed_moves',   coalesce(v_kd->'now_possible', '[]'::jsonb),
    'in_journey',      coalesce((v_stage->>'in_stage')::boolean, false),
    'phase',           v_stage->>'phase',
    'family_context',
      '[ما نعرفه عن هذا البيت — ملاحظاتنا نحن، لم يقلها الأهل الآن]' || chr(10)
      || v_known || chr(10) || chr(10)
      || '[ما يُسمح لك أن تدّعي معرفته]' || chr(10) || v_perm
      || case when v_curve_block <> '' then
           chr(10) || chr(10) || '[منحنى الوالد]' || chr(10) || v_curve_block
         else '' end
      || case when v_journey_directive <> '' then
           chr(10) || chr(10) || '[الرحلة]' || chr(10) || v_journey_directive
         else '' end,
    'ask',         coalesce((v_ask->>'ask')::boolean, false),
    'ask_body',    v_ask->>'body',
    'ask_buttons', coalesce(v_ask->'buttons', '[]'::jsonb),
    'offer_present', coalesce((v_offer->>'present')::boolean, false),
    'offer_fork_ar', case when coalesce((v_offer->>'present')::boolean, false)
                          then v_offer->>'fork_ar' else null end,
    'offer_buttons', case when coalesce((v_offer->>'present')::boolean, false)
                          then v_offer->'buttons' else '[]'::jsonb end,
    'handled', false,
    'intention_captured', false);
end;
$function$;
