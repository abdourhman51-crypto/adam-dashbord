-- The parent-facing product was converted to the new positioning in three
-- passes (the offer, the sidebar, the progress screens, the Mini App). The
-- agent layer was not. That gap was the largest one left, because it sits in
-- the one place a parent actually experiences Adam: the conversation.
--
-- What the audit found, in descending order of damage:
--
-- 1. get_agent_context — the entire awareness Adam has — carried ZERO parent
--    signal. Not one line about how the parent themselves behaved in a hard
--    moment, even though parent_moments has held/erupted rows AND a free-text
--    `note` the parent wrote in their own words, already copy-law clean by
--    constraint. get_parent_curve() has existed since 20260830090000 and is
--    read by three parent-facing surfaces. The agent read none of it. Adam was
--    accompanying a parent while unable to see a single thing that parent had
--    said about themselves.
--
-- 2. The permission ladder (`[ما يُسمح لك أن تدّعي معرفته]`) had five rungs,
--    all describing what Adam may claim about the CHILD. After the parent
--    became the subject of the promise, nothing governed what he may claim
--    about the parent — so "you are improving" was neither permitted nor
--    forbidden, which in practice means invented.
--
-- 3. The JOURNEY block printed `- objective: <text>` with no owner. The text is
--    now a sentence about the parent ("أهدأ خلال دقيقة بدل الانفجار") but
--    arrives beside the child's name and situation, and every other line around
--    it is about the child — so the cheaper reading was that it is a demand on
--    the child. Same for RECENT_DAYS: "نُفذت، نفعت" reads as a verdict on the
--    child unless something says the step was the parent's act.
--
-- 4. The build-phase directive allowed only ONE shape of step ("كيف يتصرّف أو
--    يتنفّس أو يتكلّم" — inward). That fixed half the old problem and created
--    another: defusing a predictable trigger ("warn him five minutes before the
--    transition") is an act the PARENT performs, but it was banned for being
--    directed at the child. The result was a parent told to breathe, every day,
--    in front of a fight that did not have to happen.
--
-- 5. agree_objective_from_form chose calm_nights_in_window for the 'sleep'
--    problem and steps_done_in_window for the other seven. So a parent whose
--    problem was sleep agreed a goal about their own response and then had
--    their progress bar count the CHILD's calm nights — they could hold
--    themselves every single night and finish the 29 days with an empty bar.
--    This is the last contradiction sitting in the middle of the paid model.
--
-- The fixes, in the same order:
--
-- get_agent_context  — new `== PARENT ==` block (the parent's own words from
--   their three most recent recorded moments); JOURNEY objective and
--   RECENT_DAYS relabelled with the owner; and two token trims that pay for
--   the new block: the memory snapshot is capped at 1000 chars (it was
--   unbounded and entered the context first, able to crowd out everything
--   below it) and KEY_MOMENTS drops 5 → 3.
--
-- get_agent_bundle   — new top-level `[منحنى الوالد]` block, built only when
--   get_parent_curve reports ready (a partial week produces a fake
--   "improvement"); the permission ladder gains its parent axis, driven by
--   curve readiness rather than by `level`, because the two have different
--   sources — a parent whose child we know well may have recorded nothing
--   about themselves; and the journey directive states step ownership.
--
-- compose_journey_step — build phase now carries BOTH step shapes and the rule
--   for choosing between them; the curve reaches the paid proactive message,
--   under a narrower rule than the conversation gets (an improvement is said,
--   a worse week is never volunteered in a message Adam starts).
--
-- agree_objective_from_form — always steps_done_in_window. calm_nights_in_window
--   stays a legal value for stages already running, because their goal was
--   agreed under the old wording and silently re-pointing a live progress bar
--   changes a deal its owner already accepted.
--
-- v_stage_progress   — steps_in_window counts a day where the step was done OR
--   a held moment was recorded. A parent who hit the panic button and held
--   themselves through an eruption did exactly what the product promises, and
--   was scoring zero for it. daily_logs is unique on (follower_id, log_date)
--   and the check is an EXISTS, so no day counts twice.
--
-- The four agent prompts were rewritten in the same commit under
-- docs/prompts/, which now also carries the shared law every agent copies and
-- a check-law.sh that fails on drift. The workflows remain switched off on
-- purpose; nothing here reaches a real parent before the launch decision.

CREATE OR REPLACE FUNCTION public.get_agent_context(p_follower_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_out text := '';
  v_snap text;
  v_children text;
  v_patterns text;
  v_situations text;
  v_events text;
  v_logs text;
  v_stage jsonb;
  v_light_raw text;
  v_light jsonb;
  v_now_lines text := '';
  v_rhythm text;
  v_parent text;
begin
  v_out := '';

  -- ⭐ السرد المحفوظ غير محدود الطول في الجدول، وهو أول ما يدخل السياق —
  -- فنصّ واحد طويل قادر على إزاحة كل ما تحته أهميةً. ألف حرف تكفي لسرد بيت.
  select left(snapshot_text, 1000) into v_snap
  from memory_snapshots where follower_id = p_follower_id and char_count > 0;
  if v_snap is not null then
    v_out := v_out || '== SUMMARY ==' || E'\n' || v_snap;
  end if;

  select string_agg(
    '- ' || name
    || coalesce(' ('||gender||')','')
    || coalesce(', '||age_note,'')
    || coalesce(', طبع: '||temperament,''), E'\n')
  into v_children from children where follower_id = p_follower_id;
  if v_children is not null then
    v_out := v_out || E'\n\n== CHILDREN ==\n' || v_children;
  end if;

  begin
    select light_memory into v_light_raw from followers where id = p_follower_id;
    if v_light_raw is not null and btrim(v_light_raw) <> '' then
      v_light := v_light_raw::jsonb;
    end if;
  exception when others then
    v_light := null;
  end;

  if v_light is not null then
    v_now_lines := '';
    -- ⭐ life_context surfaced first: external circumstance (travel,
    -- illness, an occasion) reads differently from emotional_state
    -- (psychological coping) and the agent should be able to tell them
    -- apart -- "متعبة لأنها مسافرة" needs a different tone than "متعبة
    -- ويائسة".
    if coalesce(v_light->>'life_context','') <> '' then
      v_now_lines := v_now_lines || '- ظرف حالي: ' || (v_light->>'life_context') || E'\n';
    end if;
    if coalesce(v_light->>'core_pain','') <> '' then
      v_now_lines := v_now_lines || '- الألم: ' || (v_light->>'core_pain') || E'\n';
    end if;
    if coalesce(v_light->>'emotional_state','') <> '' then
      v_now_lines := v_now_lines || '- الحالة: ' || (v_light->>'emotional_state') || E'\n';
    end if;
    if coalesce(v_light->>'continuity','') <> '' then
      v_now_lines := v_now_lines || '- نكمل: ' || (v_light->>'continuity') || E'\n';
    end if;
    if coalesce(v_light->>'last_win','') <> '' then
      v_now_lines := v_now_lines || '- آخر نجاح: ' || (v_light->>'last_win');
    end if;
    v_now_lines := btrim(v_now_lines, E'\n');
    if v_now_lines <> '' then
      v_out := v_out || E'\n\n== NOW ==\n' || v_now_lines;
    end if;
  end if;

  -- ⭐ كلام الوالد عن نفسه في أصعب لحظاته.
  -- `parent_moments.note` يكتبه الوالد بيده في زرّ النجدة أو سؤال المساء، ويمرّ
  -- على chk_moment_note_clean قبل أن يُحفظ — أي أنه نصّ نظيف بلغة الوالد نفسه
  -- عن اللحظة التي كاد ينفجر فيها. وهو أثمن ما في قاعدة البيانات كلّها لهذا
  -- المنتج، لأنه الشيء الوحيد المكتوب عن الوالد لا عن الطفل — ولم يكن يصل إلى
  -- آدم إطلاقاً قبل هذا الترحيل، فكان يرافق والداً وهو لا يقرأ حرفاً ممّا قاله
  -- عن نفسه.
  -- ثلاثة فقط: أحدثها هو ما يزال حيّاً في ذهن الوالد، وما قبلها يصير تاريخاً.
  select string_agg(line, E'\n') into v_parent from (
    select '- [' || to_char(pm.occurred_on, 'MM/DD') || ' · '
        || case pm.kind when 'held' then 'تماسك' else 'انفجر' end || '] '
        || pm.note as line
    from parent_moments pm
    where pm.parent_id = p_follower_id
      and nullif(btrim(coalesce(pm.note, '')), '') is not null
    order by pm.occurred_on desc, pm.created_at desc
    limit 3
  ) t;
  if v_parent is not null then
    v_out := v_out || E'\n\n== PARENT ==\n' || v_parent;
  end if;

  select string_agg(
    '- ['||status||' x'||evidence_count||'] '||pattern_label
    || coalesce(': '||description,''), E'\n')
  into v_patterns from child_patterns
  where follower_id = p_follower_id and status <> 'resolved';
  if v_patterns is not null then
    v_out := v_out || E'\n\n== PATTERNS ==\n' || v_patterns;
  end if;

  select string_agg(
    '- ' || s.label_ar || ': يظهر بين ' ||
    lpad(s.window_start::text,2,'0') || ':00-' || lpad(s.window_end::text,2,'0') || ':00',
    E'\n')
  into v_situations
  from situations s
  where s.parent_id = p_follower_id and s.status = 'confirmed';
  if v_situations is not null then
    v_out := v_out || E'\n\n== SITUATIONS ==\n' || v_situations;
  end if;

  select string_agg(line, E'\n') into v_events from (
    select '- ['||event_type||', '||to_char(occurred_at,'MM/DD')||'] '||title
           || coalesce(': '||summary,'') as line
    from memory_events
    where follower_id = p_follower_id and emotional_weight >= 3
    order by occurred_at desc limit 3
  ) t;
  if v_events is not null then
    v_out := v_out || E'\n\n== KEY_MOMENTS ==\n' || v_events;
  end if;

  select string_agg(line, E'\n') into v_logs from (
    select
      '- ['||log_date||'] ' ||
      case when source = 'rhythm' then
        coalesce(seed_text, '(بلا نص مسجّل)')
        || case step_status
             when 'done'         then ' — نُفذت، نفعت'
             when 'tried_failed' then ' — جُرّبت، لم تنفع'
             when 'not_tried'    then ' — لم تُجرَّب'
             else ' — بانتظار الرد'
           end
      else
        coalesce(summary,'')
        || coalesce(' | خطوة: '||step_given,'')
        || case step_completed when true then ' (نُفذت)' when false then ' (لم تُنفذ)' else '' end
      end as line
    from daily_logs
    where follower_id = p_follower_id
    order by log_date desc limit 3
  ) t;
  if v_logs is not null then
    -- ⭐ سطر واحد يسبق الأيام: من الذي كان يفعل. بلا هذا السطر يقرأ النموذج
    -- «نُفذت، نفعت» على أنها حكم على الطفل، فيبني ردّه على أن الطفل تحسّن أو
    -- تراجع — بينما هي سِجلّ ما فعله الوالد.
    v_out := v_out || E'\n\n== RECENT_DAYS ==\n'
          || '(الخطوة فعلٌ قام به الوالد، لا سلوكٌ طُلب من الطفل)' || E'\n'
          || v_logs;
  end if;

  select case
    when cs.cadence = 'stopped' then 'الرسالة اليومية: متوقفة الآن بطلب الأهل.'
    when cs.local_hour is not null then 'الرسالة اليومية: مفعّلة، حوالي الساعة ' || cs.local_hour || ':00 بتوقيتهم.'
    else null
  end
  into v_rhythm
  from checkin_state cs
  where cs.parent_id = p_follower_id;
  if v_rhythm is not null then
    v_out := v_out || E'\n\n== RHYTHM ==\n- ' || v_rhythm;
  end if;

  v_stage := public.stage_state(p_follower_id);
  if coalesce((v_stage->>'in_stage')::boolean, false) then
    -- ⭐ الهدف صار بعد تحويل الوعد جملةً عن الوالد («أهدأ خلال دقيقة بدل
    -- الانفجار»)، لكنه يصل مقترناً باسم الطفل والموقف. الوسم `objective`
    -- المجرّد كان يترك للنموذج أن يقرأه كمطلبٍ من الطفل — وهو أسهل القراءتين
    -- لأن كل ما حوله في السياق عن الطفل. الوسم الآن يقول لمن هو.
    v_out := v_out || E'\n\n== JOURNEY ==\n'
      || '- هدف الوالد عن نفسه: ' || (v_stage->>'objective_text') || E'\n';
    if v_stage->>'problem_context_text' is not null then
      v_out := v_out || '- الموقف الذي بدأ منه (سياق، لا هدف): '
             || (v_stage->>'problem_context_text')
             || coalesce(' ('||(v_stage->>'frequency_label')||')', '') || E'\n';
    end if;
    v_out := v_out
      || '- phase: ' || (v_stage->>'phase') || ' — ' || (v_stage->>'phase_ar') || E'\n'
      || '- logged_days: ' || (v_stage->>'logged_days')
      || ' / allowed_days: ' || (v_stage->>'allowed_days') || E'\n'
      || '- progress: ' || (v_stage->>'objective_current')
      || ' / ' || (v_stage->>'objective_target')
      || ' (window ' || (v_stage->>'window_filled') || ')';
    if v_stage->>'baseline_text' is not null then
      v_out := v_out || E'\n' || '- baseline: ' || (v_stage->>'baseline_text');
    end if;
    if coalesce((v_stage->>'extended')::boolean, false) then
      v_out := v_out || E'\n' || '- extended: نعم — مددنا المدة بلا مقابل لأننا لسه نشتغل على الهدف، ولم نصل بعد.';
    end if;
  end if;

  return btrim(v_out, E'\n');
end $function$;

CREATE OR REPLACE FUNCTION public.get_agent_bundle(p_follower_id uuid, p_message text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
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
  v_curve       jsonb;
  v_curve_block text := '';
  v_held  int; v_erupt int; v_held_p int; v_erupt_p int; v_delta int;
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

  -- ⭐ السلّم أعلاه يصف ما يُسمح بادّعاء معرفته عن **الطفل** وحده — خمس درجات،
  -- كلّها عن الطفل. وبعد أن صار الوالد هو موضوع الوعد ومقياسه، صار في السلّم
  -- نصفٌ ناقص: لا شيء يحكم ما يجوز لآدم أن يدّعيه عن الوالد نفسه. والمحور
  -- مستقلّ عن `level` لأن مصدره مختلف: `level` يُحسب من إشارات الطفل
  -- (اسم، موقف، ليالٍ)، ومنحنى الوالد يُحسب من `parent_moments` وحدها.
  -- فوالد عرفنا طفله جيداً (level 4) قد لا يكون سجّل لحظة واحدة عن نفسه.
  v_curve := public.get_parent_curve(p_follower_id);
  if coalesce((v_curve->>'ready')::boolean, false) then
    v_perm := v_perm || ' وتعرف كم مرّة تماسك الوالد وكم مرّة انفجر — هذه أرقامه هو، ويجوز أن تقولها بالرقم مرّة واحدة.';
  else
    v_perm := v_perm || ' ولا تعرف بعدُ كيف يتصرّف الوالد نفسه في اللحظة الصعبة — ممنوع أن تدّعي أنه يتحسّن أو يتراجع، ولا أن تعطيه رقماً عن نفسه.';
  end if;

  -- ⭐ كتلة مستقلّة في الأعلى، لا سطر داخل السياق: هذه هي الأرقام التي بُني
  -- عليها الوعد المدفوع، ويجب أن يراها النموذج وهو يبني الجواب لا وهو ينهيه.
  -- ولا تُبنى إلا حين `ready` — أي حين مضى أسبوع كامل على أول لحظة مسجّلة —
  -- لأن مقارنة أسبوع بأسبوع غير مكتمل تُخرج «تحسّناً» ليس حقيقياً.
  -- والسطر الأخير حارسٌ مقصود: البرومبت يحمل القاعدة نفسها، لكن النود قد لا
  -- يكون حُدِّث بعد، ورقمٌ يصل بلا قاعدة قد يُهنّئ والداً على أسبوع أسوأ.
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

  -- ⭐2 The journey directive. stage_state() is the single source for
  -- phase; this only renders behaviour for it, exactly as
  -- compose_journey_step renders behaviour for the SAME phase value on
  -- the proactive side. Absent for a free parent (in_stage=false).
  -- ⭐3 Both observe/hold branches now carry one explicit carve-out: a
  -- live-now situation needing real first aid is answered with a single
  -- containment line (never framed as a new step), then control returns
  -- to the phase's normal behaviour. This does not weaken the phase --
  -- it distinguishes "new intervention design" (still fully blocked)
  -- from "the child is in distress this instant" (never blocked).
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

    -- ⭐ الهدف في JOURNEY جملة عن الوالد، لكنها تصل مقترنة باسم الطفل وبموقفه،
    -- فتُقرأ بسهولة كمطلبٍ منه. السطر التالي يُغلق هذا الباب في التوجيه نفسه،
    -- لا في البرومبت وحده — دفاعاً في العمق، لأن النود قد لا يكون حُدِّث بعد.
    v_journey_directive := v_journey_directive ||
      ' والهدف المذكور في JOURNEY هدفُ الوالد عن نفسه، لا مطلبٌ من الطفل — ' ||
      'وأي خطوة تعطيها يفعلها الوالد، لا الطفل.';
  end if;

  return jsonb_build_object(
    'context',         v_ctx,
    'knowledge_level', v_level,
    'allowed_moves',   coalesce(v_kd->'now_possible', '[]'::jsonb),
    'in_journey',      coalesce((v_stage->>'in_stage')::boolean, false),
    'phase',           v_stage->>'phase',
    -- One block, framed as OUR notes. Without the frame the model reads its
    -- own context as something the parent just said and answers a question
    -- nobody asked.
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
    'handled', false,
    'intention_captured', false);
end;
$function$;

CREATE OR REPLACE FUNCTION public.compose_journey_step(p_parent_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_stage   jsonb;
  v_gate    jsonb;
  v_phase   text;
  v_child   text;
  v_sit     text;
  v_last_result text;
  v_last_step   text;
  v_last_status text;
  v_working text;
  v_recent  jsonb;
  v_directive text;
  v_rough   boolean;
  v_curve   jsonb;
  v_delta   int;
begin
  v_stage := public.stage_state(p_parent_id);
  if not coalesce((v_stage->>'in_stage')::boolean, false) then
    return jsonb_build_object('in_journey', false);
  end if;

  v_gate  := public.can_send('journey_step', p_parent_id);
  v_phase := v_stage->>'phase';

  select nullif(btrim(c.name), '') into v_child
  from public.children c where c.follower_id = p_parent_id
  order by c.is_primary desc nulls last, c.created_at limit 1;

  v_sit := public.hard_moment_label(v_stage->>'problem_key');

  select d.night_result, d.step_given, d.step_status
    into v_last_result, v_last_step, v_last_status
  from public.daily_logs d
  where d.follower_id = p_parent_id and d.night_result is not null
  order by d.log_date desc limit 1;

  select nullif(btrim(d.step_given), '') into v_working
  from public.daily_logs d
  where d.follower_id = p_parent_id
    and nullif(btrim(d.step_given), '') is not null
    and (d.step_status = 'done' or d.night_result = 'calm')
  order by d.log_date desc limit 1;

  select coalesce(jsonb_agg(s order by rn), '[]'::jsonb) into v_recent
  from (
    select nullif(btrim(d.step_given), '') as s,
           row_number() over (order by d.log_date desc) as rn
    from public.daily_logs d
    where d.follower_id = p_parent_id
      and nullif(btrim(d.step_given), '') is not null
    order by d.log_date desc limit 5
  ) t
  where s is not null;

  -- ⭐ same rough-patch signal as can_ground_seed/get_harvest_prompt.
  select count(*) filter (where d.night_result = 'hard') >= 2
     and count(*) filter (where d.night_result = 'calm') = 0
    into v_rough
  from public.daily_logs d
  where d.follower_id = p_parent_id
    and d.log_date > current_date - 3 and d.log_date < current_date;
  v_rough := coalesce(v_rough, false);

  if v_rough then
    v_directive :=
      'آخر أيام كانت ثقيلة (لا ليلة هادئة، وليلتان صعبتان على الأقل). لا تقترح خطوة جديدة الليلة مهما كانت المرحلة. '
      || 'اكتفِ بحضور هادئ: اعترف أن الفترة صعبة، بلا انتظار تحسّن فوري، واسألهم كيف مرّت الليلة بلا أي اقتراح.';
  else
    v_directive := case v_phase
      when 'observe' then
        'لا تقترح خطوة جديدة الليلة. اطلب منهم أن يلاحظوا '
        || coalesce(v_sit, 'الموقف الصعب')
        || ' دون أن يغيّروا شيئاً — متى يبدأ بالضبط، وما الذي يسبقه. '
        || 'نحن نتعرّف على ما يحدث فعلاً قبل أن نغيّره.'
      when 'hold' then
        'تراجَع عمداً. لا تقترح خطوة. ذكّرهم بهدوء أنهم صاروا يعرفون ما ينفع مع '
        || coalesce(v_child, 'طفلهم')
        || '، واسأل فقط كيف مرّت الليلة. الهدوء يجب أن يُرى وهو يصمد بلا تذكير منك.'
      else
        -- ⭐ كان هذا التوجيه يسمح بشكل واحد فقط للخطوة: «كيف يتصرّف أو يتنفّس
        -- أو يتكلّم» — أي الشكل الداخلي وحده. وهذا أصلحَ نصف المشكلة وخلق
        -- نصفاً آخر: صار ممنوعاً على آدم أن ينزع فتيل موقف متوقّع («نبّهوه قبل
        -- الانتقال بخمس دقائق») لأن ذلك فعلٌ تجاه الطفل، مع أنّ الذي يفعله هو
        -- الوالد. والنتيجة والدٌ يُطلب منه أن يتنفّس كل يوم أمام معركةٍ كان
        -- يمكن ألّا تقع أصلاً.
        -- الشكلان كلاهما يفعلهما الوالد؛ والممنوع هو الشكل الثالث وحده:
        -- مطلبٌ يُنفّذه الطفل. وقاعدة الاختيار تُذكر صراحة حتى لا تُترك للذوق.
        'اقترح خطوة واحدة صغيرة'
        || coalesce(' مبنية على ما نفع سابقاً: «' || v_working || '»', '')
        || '، قابلة للتجربة في أسوأ ليلة. '
        || 'والخطوة يفعلها الوالد دائماً، ولها شكلان: '
        || 'خطوة تجاه ' || coalesce(v_child, 'الطفل') || ' تنزع فتيل الموقف قبل أن يشتعل (تنبيه مبكر، اختياران بدل أمر) — تُعطى حين يكون المفجّر متوقّعاً؛ '
        || 'أو خطوة في الوالد نفسه تغيّر ما يفعله حين يشتعل الموقف رغم ذلك (نفَس قبل الكلام، جملة واحدة بدل خمس) — تُعطى حين تكون اللحظة قد وقعت أو لا يمكن نزع المفجّر. '
        || 'وممنوع الشكل الثالث: أي خطوة يكون تنفيذها مطلوباً من ' || coalesce(v_child, 'الطفل') || ' لا من الوالد. '
        || 'مرتبطة بـ ' || coalesce(v_child, 'طفلهم') || ' و' || coalesce(v_sit, 'الموقف') || '. '
        || 'لا تكرّر خطوة سبق أن أعطيتها.'
    end;
  end if;

  -- ⭐ منحنى الوالد يصل الآن إلى الرسالة الاستباقية المدفوعة أيضاً، لا إلى
  -- المحادثة وحدها. وقاعدته هنا أضيق: التحسّن يُذكر، والتراجع لا يُذكر إطلاقاً
  -- في رسالة يبدؤها آدم — لأن الوالد لم يسأل، والصباح ليس وقت مواجهته بأسوأ
  -- أسبوعه.
  v_curve := public.get_parent_curve(p_parent_id);
  if coalesce((v_curve->>'ready')::boolean, false) and not v_rough then
    v_delta := coalesce((v_curve->>'eruptDelta')::int, 0);
    if v_delta < 0 then
      v_directive := v_directive
        || ' وقد قلّت انفجاراتهم عن الأسبوع الماضي بـ ' || abs(v_delta)::text || '.'
        || ' اذكر هذا مرّة واحدة بالرقم، بلا احتفال زائد، ثم أكمل.';
    else
      v_directive := v_directive
        || ' ولا تذكر أرقام تماسكهم أو انفجارهم في هذه الرسالة — لم يسألوا، والأسبوع ليس أفضل من سابقه.';
    end if;
  end if;

  return jsonb_build_object(
    'in_journey',        true,
    'can_send',          coalesce((v_gate->>'can_send')::boolean, false),
    'reason',            v_gate->>'reason',
    'phase',             v_phase,
    'phase_ar',          v_stage->>'phase_ar',
    'phase_directive',   v_directive,
    'is_rough_patch',    v_rough,
    'objective_text',    v_stage->>'objective_text',
    'objective_current', (v_stage->>'objective_current'),
    'objective_target',  (v_stage->>'objective_target'),
    'days_remaining',    (v_stage->>'days_remaining'),
    'logged_days',       (v_stage->>'logged_days'),
    'child_name',        v_child,
    'situation',         v_sit,
    'last_night', jsonb_build_object(
      'result', v_last_result, 'step', v_last_step, 'status', v_last_status),
    'last_working_step', v_working,
    'recent_steps',      v_recent);
end;
$function$;

CREATE OR REPLACE FUNCTION public.agree_objective_from_form(p_parent_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_state jsonb;
  v_problem_key text;
  v_problem_context text;
  v_frequency_label text;
  v_objective_text text;
  v_metric text;
begin
  select journey_form_state into v_state from public.followers where id = p_parent_id;
  if v_state is null or v_state->>'outcome_text' is null then
    return jsonb_build_object('agreed', false, 'reason', 'form_incomplete');
  end if;

  v_problem_key := coalesce(v_state->>'problem_key', 'other');
  v_objective_text := v_state->>'outcome_text';
  -- ⭐ كان: مشكلة النوم تُقاس بـ calm_nights_in_window، وكل ما عداها بـ
  -- steps_done_in_window. وهذا آخر تناقض بقي في قلب النموذج الربحي:
  -- نصّ الهدف صار جملةً عن الوالد لكل المشكلات الثمانٍ («أهدأ عند كل استيقاظ
  -- ليلي بدل التوتر»)، بينما كان شريط التقدّم لوالد اختار «النوم» يعدّ ليالي
  -- هدوء **الطفل**. أي أنّ الوالد يتّفق على هدف عن نفسه، ثم يُقاس بسلوك ابنه —
  -- ويصل إلى نهاية المدّة وقد تماسك كل ليلة بينما شريطه فارغ لأن الطفل لم يهدأ.
  -- الهدف الآن عن الوالد دائماً، فالمقياس فعلٌ للوالد دائماً.
  -- calm_nights_in_window يبقى قيمة صالحة في القيد من أجل الرحلات القائمة
  -- (اتُّفق عليها بالصياغة القديمة، وتحويلها في منتصف الطريق يغيّر اتفاقاً
  -- وافق عليه صاحبه) — لكنه لا يُختار لأي اتفاق جديد.
  v_metric := 'steps_done_in_window';

  -- ⭐ Problem context: the catalog label if a button was tapped, or the
  -- parent's own literal words if they used "أمر آخر". Either way, this is
  -- what Adam should be able to say back during the journey ("زي ما حكيتوا
  -- لي عن...").
  v_problem_context := coalesce(
    (select jpc.label_ar from public.journey_problem_catalog jpc where jpc.key = v_problem_key),
    v_state->>'problem_text');

  v_frequency_label := case v_state->>'frequency_key'
    when 'daily'      then 'كل يوم تقريباً'
    when 'weekly'     then 'عدة مرات في الأسبوع'
    when 'occasional' then 'بين فترة وأخرى'
    else null end;

  update public.followers
  set agreed_objective = jsonb_build_object(
        'problem_key',          v_problem_key,
        'problem_context_text', v_problem_context,
        'frequency_label',      v_frequency_label,
        'objective_text',       v_objective_text,
        'objective_metric',     v_metric,
        'objective_target',     5,
        'objective_window',     7,
        'planned_logged_days',  29),
      agreed_at = now(),
      journey_form_state = null
  where id = p_parent_id;

  return jsonb_build_object('agreed', true, 'problem_key', v_problem_key,
    'problem_context_text', v_problem_context, 'frequency_label', v_frequency_label,
    'objective_text', v_objective_text);
end;
$function$;

CREATE OR REPLACE VIEW public.v_stage_progress AS
 WITH logged AS (
         SELECT s_1.id AS stage_id,
            count(DISTINCT d.log_date) AS logged_days
           FROM stages s_1
             LEFT JOIN daily_logs d ON d.follower_id = s_1.parent_id AND s_1.started_at IS NOT NULL AND d.log_date >= s_1.started_at::date AND d.night_result IS NOT NULL
          GROUP BY s_1.id
        ), recent AS (
         SELECT s_1.id AS stage_id,
            count(*) FILTER (WHERE w.night_result = 'calm'::text) AS calm_in_window,
            -- ⭐ «الوالد فعل شيئاً في هذا اليوم» — لا «نفّذ الخطوة» وحدها.
            -- كان هذا العدّاد يقرأ step_status='done' فقط، أي أنه لا يرى إلا
            -- الأيام التي أُعطيت فيها خطوة وأُجيب عنها. ووالدٌ ضغط زرّ النجدة
            -- وأمسك نفسه في لحظة انفجار — وهو بالضبط ما يَعِد به المنتج — كان
            -- يومه يُحسب صفراً. الآن يُحسب اليوم إن نُفّذت الخطوة **أو** سُجّلت
            -- فيه لحظة تماسك.
            -- ولا ازدواج: daily_logs فريد على (follower_id, log_date)،
            -- وEXISTS يجعل اليوم صفاً واحداً مهما تعدّدت لحظاته.
            count(*) FILTER (WHERE w.step_status = 'done'::text OR w.parent_held) AS steps_in_window,
            count(*) AS window_size
           FROM stages s_1
             CROSS JOIN LATERAL ( SELECT d.night_result,
                    d.step_status,
                    EXISTS (
                      SELECT 1 FROM parent_moments pm
                      WHERE pm.parent_id = s_1.parent_id
                        AND pm.kind = 'held'
                        AND pm.occurred_on = d.log_date) AS parent_held
                   FROM daily_logs d
                  WHERE d.follower_id = s_1.parent_id AND s_1.started_at IS NOT NULL AND d.log_date >= s_1.started_at::date AND d.night_result IS NOT NULL
                  ORDER BY d.log_date DESC
                 LIMIT s_1.objective_window) w
          GROUP BY s_1.id
        )
 SELECT s.id AS stage_id,
    s.parent_id,
    s.child_id,
    s.problem_key,
    s.status,
    s.objective_text,
    s.objective_metric,
    s.objective_target,
    s.objective_window,
    s.planned_logged_days,
    s.extension_days,
    s.planned_logged_days + s.extension_days AS allowed_days,
    COALESCE(l.logged_days, 0::bigint) AS logged_days,
    GREATEST(0::bigint, s.planned_logged_days + s.extension_days - COALESCE(l.logged_days, 0::bigint)) AS days_remaining,
        CASE
            WHEN COALESCE(l.logged_days, 0::bigint) < 3 THEN 'observe'::text
            WHEN COALESCE(l.logged_days, 0::bigint) >= (s.planned_logged_days + s.extension_days - GREATEST(3, (s.planned_logged_days + s.extension_days) / 3)) THEN 'hold'::text
            ELSE 'build'::text
        END AS phase,
        CASE s.objective_metric
            WHEN 'calm_nights_in_window'::text THEN COALESCE(r.calm_in_window, 0::bigint)
            WHEN 'steps_done_in_window'::text THEN COALESCE(r.steps_in_window, 0::bigint)
            ELSE NULL::bigint
        END AS objective_current,
    COALESCE(r.window_size, 0::bigint) AS window_filled,
    COALESCE(r.window_size, 0::bigint) >= s.objective_window AND
        CASE s.objective_metric
            WHEN 'calm_nights_in_window'::text THEN COALESCE(r.calm_in_window, 0::bigint)
            WHEN 'steps_done_in_window'::text THEN COALESCE(r.steps_in_window, 0::bigint)
            ELSE NULL::bigint
        END >= s.objective_target AS objective_met,
    COALESCE(l.logged_days, 0::bigint) >= (s.planned_logged_days + s.extension_days) AS clock_exhausted,
    s.started_at,
    s.completed_at
   FROM stages s
     LEFT JOIN logged l ON l.stage_id = s.id
     LEFT JOIN recent r ON r.stage_id = s.id;

-- The same contradiction, one layer up: two fallbacks still defaulted to the
-- child metric whenever nobody passed one explicitly. start_stage's parameter
-- default, and activate_subscription's final coalesce — which fires when the
-- team activates a subscription from the dashboard for a parent who has no
-- agreed_objective row yet. Both now default to the parent-owned metric, so
-- there is no path left that silently measures the child against a goal the
-- parent set about themselves.
CREATE OR REPLACE FUNCTION public.start_stage(p_parent_id uuid, p_problem_key text, p_objective_text text, p_objective_target integer DEFAULT 5, p_objective_window integer DEFAULT 7, p_planned_logged_days integer DEFAULT 29, p_objective_metric text DEFAULT 'steps_done_in_window'::text, p_child_id uuid DEFAULT NULL::uuid, p_problem_context_text text DEFAULT NULL::text, p_frequency_label text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_child uuid; v_id uuid; v_live uuid;
begin
  if p_parent_id is null
     or nullif(btrim(coalesce(p_problem_key, '')), '') is null
     or nullif(btrim(coalesce(p_objective_text, '')), '') is null then
    return jsonb_build_object('started', false, 'reason', 'objective_required');
  end if;

  if not exists (select 1 from public.followers where id = p_parent_id) then
    return jsonb_build_object('started', false, 'reason', 'no_such_parent');
  end if;

  select id into v_live from public.stages
  where parent_id = p_parent_id and status in ('active','extended','paused')
  limit 1;
  if v_live is not null then
    return jsonb_build_object('started', false, 'reason', 'stage_already_live',
                              'stage_id', v_live);
  end if;

  if p_objective_target > p_objective_window then
    return jsonb_build_object('started', false, 'reason', 'target_exceeds_window');
  end if;
  if p_planned_logged_days < 7 or p_planned_logged_days > 60 then
    return jsonb_build_object('started', false, 'reason', 'clock_out_of_range');
  end if;

  v_child := p_child_id;
  if v_child is null then
    select c.id into v_child from public.children c
    where c.follower_id = p_parent_id
    order by c.is_primary desc nulls last, c.created_at limit 1;
  end if;

  insert into public.stages (
    parent_id, child_id, problem_key, objective_text,
    objective_metric, objective_target, objective_window,
    planned_logged_days, status, started_at,
    problem_context_text, frequency_label)
  values (
    p_parent_id, v_child, btrim(p_problem_key), btrim(p_objective_text),
    p_objective_metric, p_objective_target, p_objective_window,
    p_planned_logged_days, 'active', now(),
    p_problem_context_text, p_frequency_label)
  returning id into v_id;

  update public.stage_proposals
  set outcome = 'accepted', stage_id = v_id
  where parent_id = p_parent_id and problem_key = btrim(p_problem_key)
    and outcome = 'pending';

  return jsonb_build_object('started', true, 'stage_id', v_id)
      || public.stage_state(p_parent_id);
end;
$function$;

CREATE OR REPLACE FUNCTION public.activate_subscription(p_follower_id uuid, p_amount numeric DEFAULT NULL::numeric, p_currency text DEFAULT NULL::text, p_notes text DEFAULT NULL::text, p_problem_key text DEFAULT NULL::text, p_objective_text text DEFAULT NULL::text, p_objective_target integer DEFAULT 5, p_objective_window integer DEFAULT 7, p_planned_logged_days integer DEFAULT 29, p_objective_metric text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  f public.followers%rowtype;
  v_country text; v_amount numeric; v_currency text;
  v_start timestamptz := now();
  v_pay_id uuid; v_journey jsonb;
  v_problem_context text; v_frequency_label text;
begin
  select * into f from public.followers where id = p_follower_id;
  if not found then
    raise exception 'follower_not_found' using errcode = 'P0002';
  end if;

  if nullif(btrim(coalesce(p_objective_text, '')), '') is null
     and nullif(btrim(coalesce(p_problem_key, '')), '') is null
     and f.agreed_objective is not null then
    p_problem_key         := f.agreed_objective->>'problem_key';
    p_objective_text      := f.agreed_objective->>'objective_text';
    p_objective_target    := coalesce((f.agreed_objective->>'objective_target')::int,    p_objective_target);
    p_objective_window    := coalesce((f.agreed_objective->>'objective_window')::int,    p_objective_window);
    p_planned_logged_days := coalesce((f.agreed_objective->>'planned_logged_days')::int, p_planned_logged_days);
    -- ⭐ FIX: was hardcoded to calm_nights_in_window regardless of what the
    -- form actually determined (sleep vs everything else).
    p_objective_metric    := coalesce(p_objective_metric, f.agreed_objective->>'objective_metric');
    v_problem_context := f.agreed_objective->>'problem_context_text';
    v_frequency_label := f.agreed_objective->>'frequency_label';
  end if;
  p_objective_metric := coalesce(p_objective_metric, 'steps_done_in_window');

  v_country := nullif(btrim(coalesce(f.country, '')), '');

  select sc.price_subscription, sc.currency into v_amount, v_currency
  from public.supported_countries sc where sc.code = coalesce(v_country, 'DZ') limit 1;
  if v_amount is null then
    select sc.price_subscription, sc.currency into v_amount, v_currency
    from public.supported_countries sc where sc.code = 'DZ' limit 1;
  end if;
  v_amount   := coalesce(p_amount, v_amount, 2300);
  v_currency := coalesce(p_currency, v_currency, 'DZD');

  update public.followers
  set funnel_stage = 'paid_active', payment_status = 'paid',
      subscription_started_at = v_start, subscription_expires_at = null,
      offer_status = 'converted', payment_pending_at = null,
      renewal_d5_sent_at = null, renewal_d0_sent_at = null
  where id = p_follower_id;

  insert into public.payments (follower_id, amount, currency, plan_type, status,
                               claimed_at, confirmed_at, confirmed_by, notes, created_at)
  values (p_follower_id, v_amount, v_currency, 'basic', 'confirmed',
          coalesce(f.payment_pending_at, v_start), now(), 'dashboard', p_notes, now())
  returning id into v_pay_id;

  v_journey := public.start_stage(
    p_follower_id, p_problem_key, p_objective_text,
    p_objective_target, p_objective_window, p_planned_logged_days,
    p_objective_metric, null, v_problem_context, v_frequency_label);

  if coalesce((v_journey->>'started')::boolean, false) then
    update public.followers set agreed_objective = null, agreed_at = null
    where id = p_follower_id;
  end if;

  return jsonb_build_object(
    'follower_id', p_follower_id,
    'payment_id',  v_pay_id,
    'funnel_stage','paid_active',
    'subscription_started_at', v_start,
    'amount', v_amount, 'currency', v_currency,
    'journey', v_journey);
end;
$function$;
