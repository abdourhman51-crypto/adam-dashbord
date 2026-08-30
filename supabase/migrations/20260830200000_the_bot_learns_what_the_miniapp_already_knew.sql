-- The bot side of the paid journey had the exact same bug the miniapp's
-- بصيص أمل had before the previous round's fix: a parent already paying and
-- in an active stage (stage_state.in_stage = true) who asked the bot about
-- "المرافقة الكاملة" (via menu_journey, or a pattern-reveal's jf_start
-- button) was shown the first-time marketing pitch and a brand-new intake
-- form — not their actual progress. followers.agreed_objective is cleared
-- by activate_subscription() the moment a stage goes live (see
-- agree_objective_from_form / start_stage / activate_subscription), so
-- get_conversation_moment's `if v_agreed is not null` branch could never
-- distinguish "already paying" from "never started" — it only ever saw
-- agreed_objective = null for both. Fixed with the same two-layer pattern
-- used for the miniapp: an entry-point gate (menu_journey) and a
-- destination gate (jf_start itself, since compose_pattern_reveal's
-- seq=4 button calls jf_start directly, bypassing menu_journey).
--
-- Also closes a second, smaller gap: chk_body_clean only validates the
-- conversation_moments.body_ar column, never buttons jsonb NOR any text a
-- plpgsql function composes at runtime and returns without ever writing it
-- back to that column. A manual sweep (grep across every live function's
-- prosrc for the banned word خطة and its inflections) found four more
-- surviving instances beyond the ones fixed on 2026-08-30: two in
-- compose_journey_form_screen (the bot's own copy of the intake wizard —
-- the miniapp's copy was fixed, this one was missed), two in
-- compose_pattern_reveal (a surface not touched by the earlier sweep at
-- all). All four fixed here, plus three parallel instances found in the
-- miniapp itself (journey/start's AdamIntro, its no-teamUrl fallback line,
-- and journey/page's free-tier CTA — fixed in the same commit, not in SQL).
--
-- And a handful of remaining child-framed spots under "أنتم من يصل للنتيجة،
-- والطفل هو السياق": menu_journey_presence still promised a goal "for your
-- child" rather than one the parent wants to reach; harvest_ask (the daily
-- evening question, sent to every active parent) asked generically "how did
-- the day go with your child" instead of tying back to the step actually
-- tried, so menu_settings's description of that same question is updated to
-- match; compose_menu_body's menu_child said the daily step becomes precise
-- "for him" (the child) rather than for the parent's own household; and one
-- stray Gulf-dialect "وش" (unlikely to be understood in the DZ/EG/MA
-- markets this product actually serves) is replaced with standard "ما".

CREATE OR REPLACE FUNCTION public.get_conversation_moment(p_key text, p_parent_id uuid DEFAULT NULL::uuid, p_skip_commerce_gate boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  m         public.conversation_moments%rowtype;
  v_cs      jsonb;
  v_body    text;
  v_buttons jsonb;
  v_nl      text := chr(10);
  v_name    text;
  v_who     text;
  v_agreed  jsonb;
  v_stage   jsonb;
begin
  select * into m from public.conversation_moments where key = p_key;
  if not found then
    return jsonb_build_object('found', false, 'key', p_key);
  end if;

  if m.requires_commerce and p_parent_id is not null and not p_skip_commerce_gate
     and not coalesce(public.commerce_allowed(p_parent_id), true) then
    return jsonb_build_object('found', true, 'key', p_key, 'allowed', false,
                              'reason', 'commerce_blocked');
  end if;

  v_body    := m.body_ar;
  v_buttons := m.buttons;

  select nullif(btrim(c.name), '') into v_name
  from public.children c where c.follower_id = p_parent_id
  order by c.is_primary desc nulls last, c.created_at limit 1;
  v_who := coalesce(v_name, 'طفلكم');

  if p_key = 'country_recorded' then
    v_body := public.compose_menu_body(p_key, p_parent_id);
    v_cs := public.country_state(p_parent_id);
    if (v_cs->>'state') = 'supported' then
      v_buttons := '[
        {"label":"🎯 أشوف المرافقة الكاملة","cb":"menu_journey"},
        {"label":"🌿 ليس الآن، نكمل مجاناً","cb":"not_now"}
      ]'::jsonb;
    else
      v_buttons := '[]'::jsonb;
    end if;

  elsif p_key = 'menu_journey' then
    -- ⭐ والدٌ في رحلة نشطة بالفعل: لا يُعرض عليه استمارة جديدة ولا العرض
    -- التسويقي — agreed_objective يُصفَّر بمجرد تفعيل الرحلة (activate_subscription)،
    -- فبقاء الفرع القديم دون هذا الفحص كان يُظهر للوالد المشترك نفس عرض
    -- البيع الذي يراه من لم يبدأ بعد. نفس الإصلاح الذي طُبّق على «بصيص أمل»
    -- في التطبيق المصغّر، هنا في محادثة البوت.
    v_stage := public.stage_state(p_parent_id);
    if coalesce((v_stage->>'in_stage')::boolean, false) then
      v_body := '📈 عندكم اتفاق نشط بالفعل.' || v_nl || v_nl ||
                'هدفكم: ' || coalesce(v_stage->>'objective_text', '') || '.' || v_nl || v_nl ||
                'نمشي فيه معاً يوماً بيوم — لا حاجة لاستمارة جديدة.';
      v_buttons := '[
        {"label":"📈 أشوف تقدّمي","cb":"menu_progress"},
        {"label":"💬 عندي سؤال آخر","cb":"other"}
      ]'::jsonb;

    else

    v_cs := public.country_state(p_parent_id);

    if (v_cs->>'state') = 'supported' then
      select agreed_objective into v_agreed
      from public.followers where id = p_parent_id;

      if v_agreed is not null then
        v_body :=
          '🎉 هذا اتّفاقكم.' || v_nl ||
          'هدفكم: ' || (v_agreed->>'objective_text') || ' — خلال ' || coalesce(v_agreed->>'planned_logged_days','29') || ' يوماً.' || v_nl || v_nl ||
          'تخيّلوا تلك اللحظة: تهدأون بدل أن تنفجروا — هذا بالضبط ما نبنيه معاً، يوماً بعد يوم، لا دفعة واحدة. وينعكس هذا على ' || v_who || ' أيضاً، كنتيجة لا كهدف.' || v_nl || v_nl ||
          '✨ وكيف نصل؟' || v_nl ||
          'كل يوم: خطوة صغيرة تناسب موقفكم أنتم بالذات، لا نصيحة عامة.' || v_nl ||
          'وكل مساء: سؤال واحد، جوابه ضغطة زر — فلا نبدأ من الصفر أبداً، بل نبني كل يوم على الذي قبله.' || v_nl ||
          'وما تحكونه يبقى بينكم وبيني وحدنا، تطلبون محوه فيُمحى كلّه.' || v_nl || v_nl ||
          '⏱️ وكم يأخذ من وقتكم؟' || v_nl ||
          'دقيقة أو دقيقتان في اليوم، لا أكثر. واليوم الذي لا تحتملونه لا يُحسب عليكم.' || v_nl || v_nl ||
          '🛡️ الضمان' || v_nl ||
          'هذا الهدف بالذات هو مقياس نجاحنا — بأعينكم لا بكلامي.' || v_nl ||
          'وإن لم نصل إليه في المدّة، أُكمل معكم نصف المدّة كاملةً مجاناً حتى نصل.' || v_nl || v_nl ||
          '💎 الاستثمار: ' || (v_cs->>'price') || '، لمدّة ' || coalesce(v_agreed->>'planned_logged_days','29') || ' يوماً — لهذا الهدف بالذات، لا اشتراك عام.' || v_nl || v_nl ||
          '📌 التفاصيل وطريقة الدفع مع فريق آدم — أنا لا أتولّى هذا الجزء، ولا أستطيع الإجابة عنه.';

        v_buttons := jsonb_build_array(
          jsonb_build_object(
            'label', case when v_name is null then '📞 نُفعّل الاتفاق مع فريق آدم'
                          else '📞 نُفعّل اتفاق ' || v_name || ' مع الفريق' end,
            'url',   'https://t.me/Abdouleg'),
          jsonb_build_object('label', '📝 أُعيد الاستمارة من جديد', 'cb', 'jf_start'),
          jsonb_build_object('label', '🔄 أُغيّر الهدف', 'cb', 'menu_change_goal'),
          jsonb_build_object('label', '🌿 ليس الآن — نكمل مجاناً', 'cb', 'menu_not_now'));
      else
        v_body :=
          '🎯 المرافقة الكاملة' || v_nl || v_nl ||
          'لا أعدكم بأنكم لن تغضبوا مجدداً خلال 29 يوماً.' || v_nl ||
          'لكن أعدكم أن نعمل معاً حتى تتغيّر بالضبط اللحظة التي تفقدون فيها صبركم أكثر من غيرها — لا نصيحة عامة، بل شيء مبنيّ على بيتكم أنتم:' || v_nl ||
          '😌 تهدأون أسرع، بدل أن ينفجر الموقف' || v_nl ||
          '🗣️ تتكلّمون بدل ما تصرخون' || v_nl ||
          '⏸️ تتوقّفون قبل الكلمة التي تندمون عليها بعدها' || v_nl ||
          '💪 يزول إحساس العجز، ويحلّ مكانه إحساس أنكم تعرفون كيف تتصرّفون' || v_nl ||
          '🤝 وينعكس هذا على ' || v_who || ' أيضاً — نتيجة، لا هدف بحدّ ذاته' || v_nl || v_nl ||
          '⏱️ دقيقة أو دقيقتان في اليوم، لا أكثر — واليوم الذي لا تحتملونه لا يُحسب عليكم.' || v_nl || v_nl ||
          '🛡️ ونتّفق قبل أن نبدأ على هدف واحد واضح ترونه بأعينكم. وإن لم نصل إليه، أُكمل معكم مجاناً حتى نصل.' || v_nl || v_nl ||
          '🎁 ومعها تُفتح ✨ بصائر آدم — تتابعون فيها كل أسبوع بالأرقام: هل تحسّن الوضع فعلاً؟' || v_nl || v_nl ||
          '👇 نبني اتفاقكم أنتم الآن — نصف دقيقة، بلا أي التزام:';

        v_buttons := jsonb_build_array(
          jsonb_build_object('label', '🎯 نبني اتفاقنا الآن', 'cb', 'jf_start'),
          jsonb_build_object(
            'label', case when v_name is null then '📞 عندي سؤال أولاً'
                          else '📞 عندي سؤال عن ' || v_name || ' أولاً' end,
            'url',   'https://t.me/Abdouleg'),
          jsonb_build_object('label', '🌿 ليس الآن — نكمل مجاناً', 'cb', 'menu_not_now'));
      end if;

    elsif (v_cs->>'state') = 'unknown' then
      v_body :=
        '🎯 المرافقة الكاملة' || v_nl || v_nl ||
        'تختلف من بلد لآخر — السعر وطريقة الدفع محليّان.' || v_nl || v_nl ||
        'من أي بلد أنتم؟';
      v_buttons := jsonb_build_array(
        jsonb_build_object('label','🇩🇿 الجزائر',  'cb','set_country_DZ'),
        jsonb_build_object('label','🇪🇬 مصر',      'cb','set_country_EG'),
        jsonb_build_object('label','🇲🇦 المغرب',   'cb','set_country_MA'),
        jsonb_build_object('label','🌍 بلد آخر',   'cb','set_country_OTHER'),
        jsonb_build_object('label','💬 عندي موقف آخر', 'cb','other'));

    else
      v_body :=
        '🌿 آدم يرافقكم بالكامل، كما يرافق الجميع.' || v_nl ||
        'كل ما بيننا الآن يبقى كما هو، دون نقص.' || v_nl || v_nl ||
        'والمرافقة الكاملة لم تصل بلدكم بعد، لسبب واحد:' || v_nl ||
        'لا تتوفّر بعد طريقة دفع محلية نثق بها ونستطيع دعمها كما ينبغي.' || v_nl ||
        'وحين تتوفّر، تصلكم رسالة.';
      v_buttons := '[{"label":"🔔 أخبروني حين تصل","cb":"waitlist_join"},{"label":"💬 عندي موقف آخر","cb":"other"}]'::jsonb;
    end if;

    end if;

  elsif p_key = 'menu_ask_team' then
    v_body := public.compose_menu_body(p_key, p_parent_id);
    v_cs := public.country_state(p_parent_id);
    if p_parent_id is not null and (v_cs->>'state') = 'supported' then
      v_buttons := jsonb_build_array(
        jsonb_build_object('label', '🎯 أشوف المرافقة الكاملة', 'cb', 'menu_journey'),
        jsonb_build_object('label', '📞 أتحدّث مع فريق آدم', 'url', 'https://t.me/Abdouleg'));
    elsif p_parent_id is not null and (v_cs->>'state') = 'unsupported' then
      v_buttons := jsonb_build_array(
        jsonb_build_object('label','🔔 أخبروني حين تصل','cb','waitlist_join'),
        jsonb_build_object('label','💬 نكمل مع ' || v_who, 'cb','other'));
    else
      v_buttons := jsonb_build_array(
        jsonb_build_object('label','📞 أتحدّث مع فريق آدم','url','https://t.me/Abdouleg'),
        jsonb_build_object('label','💬 نكمل مع ' || v_who, 'cb','other'));
    end if;

  elsif p_key = 'menu_change_goal' then
    v_body := '🔄 نبدأ من جديد.' || v_nl ||
              'احكوا لي ما المشكلة اللي تثقل عليكم أكثر هالأيام مع ' || v_who || '، ونبني منها هدفاً جديداً.';
    v_buttons := '[]'::jsonb;

  elsif v_body is null then
    v_body := public.compose_menu_body(p_key, p_parent_id);
  end if;

  if v_body is null or btrim(v_body) = '' then
    return jsonb_build_object('found', false, 'key', p_key,
                              'reason', 'composed_to_nothing');
  end if;

  return jsonb_build_object(
    'found', true, 'key', m.key, 'allowed', true, 'category', m.category,
    'tier', m.tier, 'body', v_body, 'buttons', v_buttons,
    'buttons_forbidden', m.buttons_forbidden, 'max_lines', m.max_lines);
end;
$function$;

CREATE OR REPLACE FUNCTION public.compose_journey_form_screen(p_parent_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_state    jsonb;
  v_step     text;
  v_who      text;
  v_nl       text := chr(10);
  v_problem_label text;
  v_freq_label    text;
  v_outcome_opts  jsonb;
  v_buttons  jsonb;
  v_body     text;
  v_row      record;
begin
  select coalesce(nullif(btrim(c.name),''), 'طفلكم') into v_who
  from public.children c where c.follower_id = p_parent_id
  order by c.is_primary desc nulls last, c.created_at limit 1;
  v_who := coalesce(v_who, 'طفلكم');

  select journey_form_state into v_state from public.followers where id = p_parent_id;
  v_state := coalesce(v_state, jsonb_build_object('step','problem'));
  v_step := coalesce(v_state->>'step', 'problem');

  if v_step = 'problem' then
    v_body := 'خطوة 1 من 4' || v_nl ||
              '🎯 لنتّفق على شيء يخصّ وضعكم مع ' || v_who || ' بالذات — لا نصيحة عامة.' || v_nl ||
              'ما الأمر الذي يتعبكم أكثر هذه الأيام؟';
    v_buttons := '[]'::jsonb;
    for v_row in select key, emoji, label_ar from public.journey_problem_catalog order by sort_order loop
      v_buttons := v_buttons || jsonb_build_array(jsonb_build_object(
        'label', v_row.emoji || ' ' || v_row.label_ar, 'cb', 'jf_problem_' || v_row.key));
    end loop;
    v_buttons := v_buttons || jsonb_build_array(jsonb_build_object('label','💬 أمر آخر','cb','jf_other_problem'));

  elsif v_step = 'frequency' then
    v_problem_label := coalesce(
      (select jpc.label_ar from public.journey_problem_catalog jpc
        where jpc.key = v_state->>'problem_key'),
      v_state->>'problem_text', 'هذا الأمر');
    v_body := 'خطوة 2 من 4' || v_nl ||
              'وكم مرة يتكرر «' || v_problem_label || '» معكم؟';
    v_buttons := '[
      {"label":"📅 كل يوم تقريباً","cb":"jf_freq_daily"},
      {"label":"🗓️ عدة مرات في الأسبوع","cb":"jf_freq_weekly"},
      {"label":"〰️ بين فترة وأخرى، لكنه يوجع حين يحدث","cb":"jf_freq_occasional"}
    ]'::jsonb;

  elsif v_step = 'outcome' then
    if v_state->>'problem_key' is not null then
      v_outcome_opts := public.journey_outcome_options(v_state->>'problem_key');
      v_body := 'خطوة 3 من 4' || v_nl ||
                'ولو تغيّر شيء واحد في كيف تتعاملون معه خلال 29 يوماً، ماذا تحبّون أن يتغيّر؟';
      v_buttons := '[]'::jsonb;
      for v_row in select value as opt, ordinality as i from jsonb_array_elements_text(v_outcome_opts) with ordinality loop
        v_buttons := v_buttons || jsonb_build_array(jsonb_build_object('label', v_row.opt, 'cb', 'jf_outcome_' || v_row.i));
      end loop;
      v_buttons := v_buttons || jsonb_build_array(jsonb_build_object('label','💬 أمر آخر','cb','jf_other_outcome'));
    else
      return jsonb_build_object(
        'body', 'خطوة 3 من 4' || v_nl || 'بكلماتكم: كيف تحبّون أن تتصرّفوا بشكل مختلف؟',
        'buttons', '[]'::jsonb, 'await_field', 'outcome_text');
    end if;

  elsif v_step = 'confirm' then
    v_problem_label := coalesce(
      (select jpc.emoji || ' ' || jpc.label_ar from public.journey_problem_catalog jpc
        where jpc.key = v_state->>'problem_key'),
      v_state->>'problem_text');
    v_freq_label := case v_state->>'frequency_key'
      when 'daily'      then 'كل يوم تقريباً'
      when 'weekly'     then 'عدة مرات في الأسبوع'
      when 'occasional' then 'بين فترة وأخرى'
      else 'بشكل متكرر' end;

    v_body :=
      'خطوة 4 من 4 — آخر خطوة' || v_nl || v_nl ||
      '📋 اتّفاقكم جاهز:' || v_nl ||
      '• الأمر الذي يتعبكم مع ' || v_who || ': ' || coalesce(v_problem_label, 'ما ذكرتموه') || '، ' || v_freq_label || v_nl ||
      '• الهدف خلال 29 يوماً: ' || coalesce(v_state->>'outcome_text', 'ما اخترتموه') || v_nl || v_nl ||
      '🎁 ومعها تُفتح ✨ بصائر آدم — صفحة تتابعون فيها بالأرقام كل أسبوع: هل تحسّن الوضع فعلاً؟' || v_nl || v_nl ||
      '🛡️ وباتفاق واضح: إن لم نصل لهذا الهدف بالذات خلال المدة، أُكمل معكم نصف المدة إضافية مجاناً حتى نصل.' || v_nl || v_nl ||
      'هل هذا صحيح؟';
    v_buttons := '[
      {"label":"✅ نعم، هذا بالضبط","cb":"jf_confirm_yes"},
      {"label":"🔄 نبدأ من جديد","cb":"jf_confirm_restart"}
    ]'::jsonb;
  else
    v_body := null; v_buttons := '[]'::jsonb;
  end if;

  return jsonb_build_object('body', v_body, 'buttons', v_buttons);
end;
$function$;

CREATE OR REPLACE FUNCTION public.compose_pattern_reveal(p_pattern_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_nl text := chr(10);
  v_child text; v_label text; v_follower uuid; v_body text;
  v_seq int; v_prev1 text; v_prev2 text;
  v_buttons jsonb;
begin
  select coalesce(nullif(btrim(c.name),''), 'طفلكم'), cp.pattern_label, cp.follower_id
    into v_child, v_label, v_follower
  from public.child_patterns cp
  join public.children c on c.id = cp.child_id
  where cp.id = p_pattern_id;

  if v_label is null then
    return jsonb_build_object('body', null, 'buttons', '[]'::jsonb);
  end if;

  select count(*) into v_seq
  from public.child_patterns cp2
  where cp2.follower_id = v_follower and cp2.revealed_at is not null;
  v_seq := v_seq + 1;

  select pattern_label into v_prev1
  from public.child_patterns
  where follower_id = v_follower and revealed_at is not null
  order by revealed_at desc limit 1;

  select pattern_label into v_prev2
  from public.child_patterns
  where follower_id = v_follower and revealed_at is not null
  order by revealed_at desc offset 1 limit 1;

  if v_seq = 1 then
    v_body :=
      '🔍 لاحظت شي بـ' || v_child || ':' || v_nl || v_nl ||
      v_label || '.' || v_nl ||
      'هذا مو انطباع — لاحظته يتكرر فعلاً بكلامكم معي.' || v_nl || v_nl ||
      'وهذا نمط واحد بس من كذا لاحظتهم. باقي الصورة الكاملة، وكيف نكسر هالنمط بالذات، يظهر مع المرافقة الكاملة.';
    v_buttons := jsonb_build_array(
      jsonb_build_object('label','🎯 أشوف المرافقة الكاملة','cb','menu_journey'),
      jsonb_build_object('label','💬 عندي سؤال أولاً','cb','other'));

  elsif v_seq = 2 then
    v_body :=
      '🔍 وفيه شي ثاني لاحظته بـ' || v_child || ':' || v_nl || v_nl ||
      v_label || '.' || v_nl || v_nl ||
      'مو صدفة — نفس القدر اللي لاحظت فيه «' || coalesce(v_prev1,'الأول') || '»، هذا كمان يتكرر.' || v_nl || v_nl ||
      'كل ملاحظة جديدة تقرّبنا من فهم الصورة كاملة.';
    v_buttons := jsonb_build_array(
      jsonb_build_object('label','🎯 أشوف المرافقة الكاملة','cb','menu_journey'),
      jsonb_build_object('label','💬 عندي سؤال أولاً','cb','other'));

  elsif v_seq = 3 then
    v_body :=
      '🔍 وصلت الصورة تترابط عند ' || v_child || '.' || v_nl || v_nl ||
      '«' || coalesce(v_prev2,'') || '» ← «' || coalesce(v_prev1,'') || '» ← «' || v_label || '»' || v_nl || v_nl ||
      'هذي مو ٣ أشياء منفصلة — سلسلة وحدة. وهذا كله من كلامكم أنتم فقط، خلال أيام قليلة.' || v_nl || v_nl ||
      'تخيّلوا لو اتّفقنا على نتيجة واحدة تكسر هالسلسلة بالذات، لا كل جزء لحاله.';
    v_buttons := jsonb_build_array(
      jsonb_build_object('label','🎯 نتّفق على نتيجة لهالسلسلة','cb','menu_journey'),
      jsonb_build_object('label','💬 عندي سؤال أولاً','cb','other'));

  else
    v_body :=
      '🔍 هذا رابع شي نكتشفه سوا عن ' || v_child || ':' || v_nl || v_nl ||
      v_label || '.' || v_nl || v_nl ||
      'كل هذا بنيناه من حكيكم اليومي وحده، بلا أي استمارة ولا سؤال مباشر.' || v_nl || v_nl ||
      'تخيّلوا لو اتّفقنا على نتيجة واحدة تجمع كل هالأنماط مع بعض — هذا بالضبط اللي تسويه المرافقة الكاملة.';
    v_buttons := jsonb_build_array(
      jsonb_build_object('label','🚀 نبني الاتفاق الآن','cb','jf_start'),
      jsonb_build_object('label','💬 عندي سؤال أولاً','cb','other'));
  end if;

  return jsonb_build_object('body', v_body, 'buttons', v_buttons, 'seq', v_seq);
end;
$function$;

CREATE OR REPLACE FUNCTION public.get_moment_after_tap(p_key text, p_parent_id uuid, p_country_code text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_rec  jsonb;
  v_req  uuid;
  v_done text := null;
  v_moment text := p_key;
  v_reading jsonb;
  v_join jsonb;
  v_cap jsonb;
  v_intent_result jsonb;
  v_screen jsonb;
  v_field  text;
  v_result jsonb;
  v_cs jsonb;
  v_reading_buttons jsonb;
  v_offer jsonb;
  v_review jsonb;
  v_commit jsonb;
  v_nl text := chr(10);
  v_stage jsonb;
begin
  if p_key <> 'menu_capture_country' then
    update public.followers
       set country_asked_at = null
     where id = p_parent_id and country_asked_at is not null;
  end if;

  -- ⭐ NEW: step commitment card taps ("سأطبق ذلك" / "عندي استفسار آخر").
  if p_key = 'sc_commit' then
    v_commit := public.commit_chat_step(p_parent_id);
    if not coalesce((v_commit->>'committed')::boolean, false) then
      return jsonb_build_object('found', true, 'key', 'sc_commit', 'allowed', true,
        'category', 'reference', 'tier', 'fixed',
        'body', 'ما لقيت خطوة اليوم بعد — احكوا لي الموقف الأول.',
        'buttons', '[]'::jsonb, 'buttons_forbidden', false, 'max_lines', 2,
        'action_done', 'step_commit_missing');
    end if;
    return jsonb_build_object('found', true, 'key', 'sc_commit', 'allowed', true,
      'category', 'reference', 'tier', 'fixed',
      'body', case when coalesce((v_commit->>'is_paid')::boolean, false) and v_commit->>'objective_text' is not null
        then '✅ تمام — سجّلتها. هذي خطوة حقيقية تقرّبكم من هدفكم: «' || (v_commit->>'objective_text') || '».'
        else '✅ تمام — سجّلتها. كل خطوة صغيرة توخذ بجدية تصنع فرق حقيقي.' end,
      'buttons', '[]'::jsonb, 'buttons_forbidden', false, 'max_lines', 3,
      'action_done', 'step_committed');
  end if;

  if p_key = 'sc_more' then
    return jsonb_build_object('found', true, 'key', 'sc_more', 'allowed', true,
      'category', 'reference', 'tier', 'fixed',
      'body', 'تمام، احكوا لي شنو يشغل بالكم أكثر — كل ما تحكون أكثر، صارت الخطوة أدق.',
      'buttons', '[]'::jsonb, 'buttons_forbidden', false, 'max_lines', 2,
      'action_done', 'step_more_context_requested');
  end if;

  -- ⭐ NEW: pattern review taps (from the internal review message, not a
  -- family-facing menu). No parent_id needed -- the pattern id is self-
  -- contained in the callback data.
  if p_key like 'pat\_yes\_%' escape '\' then
    v_review := public.handle_pattern_review_tap(substring(p_key from 9)::uuid, true);
    return jsonb_build_object('found', true, 'key', 'pattern_review', 'allowed', true,
      'category', 'reference', 'tier', 'fixed',
      'body', v_review->>'body', 'buttons', '[]'::jsonb,
      'buttons_forbidden', false, 'max_lines', 4, 'action_done', 'pattern_approved');
  end if;
  if p_key like 'pat\_no\_%' escape '\' then
    v_review := public.handle_pattern_review_tap(substring(p_key from 8)::uuid, false);
    return jsonb_build_object('found', true, 'key', 'pattern_review', 'allowed', true,
      'category', 'reference', 'tier', 'fixed',
      'body', v_review->>'body', 'buttons', '[]'::jsonb,
      'buttons_forbidden', false, 'max_lines', 4, 'action_done', 'pattern_rejected');
  end if;

  if p_key in ('sdi_yes', 'sdi_no') then
    select platform_user_id into v_moment from public.followers where id = p_parent_id;
    v_intent_result := public.record_seed_intent(
      v_moment, case when p_key = 'sdi_yes' then 'will_try' else 'not_tonight' end);
    return jsonb_build_object(
      'found', true, 'key', p_key, 'allowed', true, 'category', 'rhythm',
      'tier', 'fixed',
      'body', case when p_key = 'sdi_yes' then '🌿 نتابع الليلة.' else 'تمام، نكون هنا لما يناسبكم.' end,
      'buttons', '[]'::jsonb, 'buttons_forbidden', false, 'max_lines', 2,
      'action_done', case when coalesce((v_intent_result->>'recorded')::boolean, false)
                           then 'intent_recorded' else 'intent_not_recorded' end);
  end if;

  if p_key = 'jf_start' then
    -- ⭐ دفاع في العمق: نفس فحص «الرحلة النشطة» من get_conversation_moment،
    -- هنا أيضاً — لأنّ compose_pattern_reveal (seq=4) يطلق jf_start مباشرة
    -- بلا مرور بـ menu_journey. والدٌ يدفع فعلاً لا يفتح استمارة جديدة أبداً.
    v_stage := public.stage_state(p_parent_id);
    if coalesce((v_stage->>'in_stage')::boolean, false) then
      return jsonb_build_object('found', true, 'key', 'jf_already_in_stage', 'allowed', true,
        'category', 'journey_form', 'tier', 'fixed',
        'body', '📈 عندكم اتفاق نشط بالفعل — هدفكم: ' || coalesce(v_stage->>'objective_text','') || '.' || v_nl || v_nl
             || 'ما في داعي لاستمارة جديدة.',
        'buttons', '[{"label":"📈 أشوف تقدّمي","cb":"menu_progress"},{"label":"💬 عندي سؤال","cb":"other"}]'::jsonb,
        'buttons_forbidden', false, 'max_lines', 6, 'action_done', 'jf_start_blocked_in_stage');
    end if;
    perform public.start_journey_form(p_parent_id);
    v_screen := public.compose_journey_form_screen(p_parent_id);
    return jsonb_build_object('found', true, 'key', 'jf_screen', 'allowed', true,
      'category', 'journey_form', 'tier', 'fixed',
      'body', v_screen->>'body', 'buttons', coalesce(v_screen->'buttons','[]'::jsonb),
      'buttons_forbidden', false, 'max_lines', 20, 'action_done', 'form_started');
  end if;

  if p_key = 'menu_change_goal' then
    update public.followers set agreed_objective = null, agreed_at = null where id = p_parent_id;
    perform public.start_journey_form(p_parent_id);
    v_screen := public.compose_journey_form_screen(p_parent_id);
    return jsonb_build_object('found', true, 'key', 'jf_screen', 'allowed', true,
      'category', 'journey_form', 'tier', 'fixed',
      'body', v_screen->>'body', 'buttons', coalesce(v_screen->'buttons','[]'::jsonb),
      'buttons_forbidden', false, 'max_lines', 20, 'action_done', 'form_restarted');
  end if;

  if p_key like 'jf_%' and p_key <> 'jf_capture_text' then
    if p_key = 'jf_other_problem' then
      perform public.await_journey_form_text(p_parent_id, 'problem_text');
      return jsonb_build_object('found', true, 'key', p_key, 'allowed', true,
        'category', 'journey_form', 'tier', 'fixed',
        'body', 'احكوا لي بكلماتكم: ما الذي يتعبكم معه؟', 'buttons', '[]'::jsonb,
        'buttons_forbidden', false, 'max_lines', 4, 'action_done', 'awaiting_problem_text');

    elsif p_key = 'jf_other_outcome' then
      perform public.await_journey_form_text(p_parent_id, 'outcome_text');
      return jsonb_build_object('found', true, 'key', p_key, 'allowed', true,
        'category', 'journey_form', 'tier', 'fixed',
        'body', 'بكلماتكم: ماذا تحبّون أن يتغيّر؟', 'buttons', '[]'::jsonb,
        'buttons_forbidden', false, 'max_lines', 4, 'action_done', 'awaiting_outcome_text');

    elsif p_key like 'jf_problem\_%' escape '\' then
      perform public.capture_journey_form_answer(p_parent_id, 'problem_key', substring(p_key from 12));

    elsif p_key like 'jf_freq\_%' escape '\' then
      perform public.capture_journey_form_answer(p_parent_id, 'frequency_key', substring(p_key from 9));

    elsif p_key like 'jf_outcome\_%' escape '\' then
      declare
        v_idx int;
        v_prob text;
        v_opts jsonb;
        v_text text;
      begin
        v_idx := substring(p_key from 12)::int;
        select journey_form_state->>'problem_key' into v_prob from public.followers where id = p_parent_id;
        v_opts := public.journey_outcome_options(v_prob);
        v_text := v_opts->>(v_idx - 1);
        perform public.capture_journey_form_answer(p_parent_id, 'outcome_text', coalesce(v_text, 'ما اخترتموه'));
      end;

    elsif p_key = 'jf_confirm_restart' then
      perform public.start_journey_form(p_parent_id);

    elsif p_key = 'jf_confirm_yes' then
      v_result := public.agree_objective_from_form(p_parent_id);
      if coalesce((v_result->>'agreed')::boolean, false) then
        if public.commerce_allowed_after_voluntary_form(p_parent_id) then
          v_offer := public.get_conversation_moment('menu_journey', p_parent_id, true);
          return v_offer || jsonb_build_object('action_done', 'goal_agreed_from_form');
        end if;
        return jsonb_build_object('found', true, 'key', 'jf_goal_saved_no_offer',
          'allowed', true, 'category', 'journey_form', 'tier', 'fixed',
          'body', 'سجّلت هدفكم: ' || coalesce(v_result->>'objective_text','') || '.' || chr(10) || chr(10)
               || 'خلّونا نكمل نتكلم شوي، ونرجع لهذا الموضوع لما يناسب الوقت أكثر.' || chr(10)
               || 'هو محفوظ عندي، ما يضيع.',
          'buttons', '[]'::jsonb, 'buttons_forbidden', false, 'max_lines', 4,
          'action_done', 'goal_agreed_offer_deferred');
      end if;
      perform public.start_journey_form(p_parent_id);
    end if;

    v_screen := public.compose_journey_form_screen(p_parent_id);
    if v_screen ? 'await_field' then
      perform public.await_journey_form_text(p_parent_id, v_screen->>'await_field');
    end if;
    return jsonb_build_object('found', true, 'key', 'jf_screen', 'allowed', true,
      'category', 'journey_form', 'tier', 'fixed',
      'body', v_screen->>'body', 'buttons', coalesce(v_screen->'buttons','[]'::jsonb),
      'buttons_forbidden', false, 'max_lines', 20, 'action_done', 'form_advanced');
  end if;

  if p_key = 'jf_capture_text' then
    select journey_form_state->>'awaiting_free_text_for' into v_field
    from public.followers where id = p_parent_id;
    if v_field is null then
      v_field := 'problem_text';
    end if;
    perform public.capture_journey_form_answer(p_parent_id, v_field, p_country_code);
    v_screen := public.compose_journey_form_screen(p_parent_id);
    if v_screen ? 'await_field' then
      perform public.await_journey_form_text(p_parent_id, v_screen->>'await_field');
    end if;
    return jsonb_build_object('found', true, 'key', 'jf_screen', 'allowed', true,
      'category', 'journey_form', 'tier', 'fixed',
      'body', v_screen->>'body', 'buttons', coalesce(v_screen->'buttons','[]'::jsonb),
      'buttons_forbidden', false, 'max_lines', 20, 'action_done', 'form_text_captured');
  end if;

  if p_key = 'menu_capture_country' then
    v_cap := public.capture_country_text(p_parent_id, p_country_code);
    if (v_cap->>'captured')::boolean then
      if (v_cap->>'joined')::boolean then
        v_moment := 'menu_waitlist_joined'; v_done := 'waitlisted';
      else
        v_moment := 'country_recorded'; v_done := 'country_recorded';
      end if;
    else
      v_moment := 'country_not_recognised'; v_done := 'country_unrecognised';
    end if;
    return coalesce(public.get_conversation_moment(v_moment, p_parent_id), '{}'::jsonb)
        || jsonb_build_object('action_done', v_done)
        || jsonb_build_object('captured', coalesce((v_cap->>'captured')::boolean, false));
  end if;

  if nullif(btrim(coalesce(p_country_code,'')), '') is not null then
    v_rec := public.record_country(p_parent_id, p_country_code);
    if coalesce((v_rec->>'ok')::boolean, false) is not true then
      v_done   := 'country_unknown';
      v_moment := 'country_other';
    end if;
  end if;

  if p_parent_id is not null and v_moment = p_key then
    if p_key = 'menu_settings_paused' then
      insert into public.checkin_state (parent_id, cadence, cadence_changed_at)
      values (p_parent_id, 'stopped', now())
      on conflict (parent_id) do update
        set cadence = 'stopped', cadence_changed_at = now(), updated_at = now();
      v_done := 'paused';
    elsif p_key = 'menu_settings_resumed' then
      insert into public.checkin_state (parent_id, cadence, paused_until, cadence_changed_at)
      values (p_parent_id, 'nightly', null, now())
      on conflict (parent_id) do update
        set cadence = 'nightly', paused_until = null,
            cadence_changed_at = now(), updated_at = now();
      v_done := 'resumed';
    elsif p_key in ('menu_settings_hour_morning','menu_settings_hour_evening','menu_settings_hour_night') then
      perform public.set_checkin_hour(p_parent_id, case p_key
                when 'menu_settings_hour_morning' then 8::smallint
                when 'menu_settings_hour_evening' then 17::smallint
                else                                   21::smallint end);
      v_done   := 'hour_set';
      v_moment := 'menu_settings_hour_set';
    elsif p_key = 'menu_privacy_erased' then
      v_req := public.request_erasure(p_parent_id);
      if v_req is not null then
        perform public.execute_erasure(v_req);
        v_done := 'erased';
      end if;
    elsif p_key = 'menu_waitlist_join' then
      v_join := public.join_waitlist(p_parent_id);
      if (v_join->>'joined')::boolean then
        v_done   := 'waitlisted';
        v_moment := 'menu_waitlist_joined';
      elsif v_join->>'reason' = 'needs_country' then
        update public.followers set country_asked_at = now() where id = p_parent_id;
        v_done   := 'waitlist_needs_country';
        v_moment := 'menu_waitlist_ask_country';
      else
        v_done   := 'waitlist_not_needed';
        v_moment := 'menu_journey';
      end if;
    end if;
  end if;

  if p_key = 'menu_reading' then
    v_reading := public.adam_reading(p_parent_id);
    v_reading_buttons := case when v_reading->>'state' in ('locked','locked_preview')
      then jsonb_build_array(jsonb_build_object('label','🎯 أشوف المرافقة الكاملة','cb','menu_journey'))
      else '[]'::jsonb end;
    return coalesce(public.get_conversation_moment('menu_reading', p_parent_id), '{}'::jsonb)
        || jsonb_build_object('body', v_reading->>'body')
        || jsonb_build_object('buttons', v_reading_buttons)
        || jsonb_build_object('reading_state', v_reading->>'state')
        || jsonb_build_object('country_recorded', coalesce(v_rec, 'null'::jsonb))
        || jsonb_build_object('action_done', 'null'::jsonb);
  end if;

  return public.get_conversation_moment(
           v_moment,
           case when v_done = 'erased' then null else p_parent_id end)
       || jsonb_build_object('country_recorded', coalesce(v_rec, 'null'::jsonb))
       || jsonb_build_object('action_done', coalesce(to_jsonb(v_done), 'null'::jsonb));
end;
$function$;

CREATE OR REPLACE FUNCTION public.compose_menu_body(p_key text, p_parent_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_nl text := chr(10); v_country text; v_today date;
  v_child uuid; v_name text; v_age text; v_sit text; v_pat text;
  v_e jsonb; v_tried integer; v_prev integer; v_calm integer; v_ever integer;
  v_cs jsonb; v_who text;
  v_lines text[] := '{}';
  v_light_raw text; v_light jsonb;
  v_sits text[]; v_pats text[];
  v_facts_count int := 0;
  v_families int;
  v_curve       jsonb;
  v_curve_ready boolean;
  v_held_week   int;
  v_erupt_week  int;
  v_erupt_delta int;
begin
  -- ⭐ Two distinct feelings, in order: (1) trust/social proof — real
  -- families confide in Adam, so it's safe to; (2) belonging — a direct,
  -- unambiguous statement of membership, its own standalone line so it
  -- lands clearly rather than blending into the proof paragraph.
  if p_key = 'menu_family' then
    select count(distinct f.id) into v_families
    from public.followers f
    join public.children c on c.follower_id = f.id
    where f.platform_user_id not in ('7377091520','8074049810');

    return '🌳 عائلة آدم' || v_nl || v_nl
        || v_families::text || ' أماً وأباً يحكون لآدم كل يوم أشياء ما يقولونها لحد غيره — بنفس الصراحة اللي حكيتوها أنتم بأول رسالة.' || v_nl || v_nl
        || 'يثقون فيه لأنه يستحق الثقة: يسمع بلا حكم، ويتذكّر، ولا ينسى بيتاً واحداً منهم.' || v_nl || v_nl
        || '🌳 وأنتم، من هالثانية، جزء من عائلة آدم.';
  end if;

  if p_parent_id is null then
    if p_key = 'menu_ask_team' then
      return '🌿 احكوا لي ما حدث في أيّ وقت، وأعطيكم خطوة صغيرة تناسب موقفكم — بلا مقابل.' || v_nl || v_nl ||
             'وللفرق بين هذا وبين المرافقة الكاملة، اكتبوا /adam.';
    end if;
    if p_key = 'menu_child' then
      return '👦 ما أعرفه عن طفلكم' || v_nl || v_nl
          || 'ما زلت لا أعرف عنه شيئاً — وهذا بيدكم تماماً.' || v_nl || v_nl
          || 'كل ما حكيتم أكثر، فهمته أعمق؛ ولما أفهمه أكثر، تصير الخطوة التي أقترحها عليكم أدقّ لبيتكم بالذات، لا لأي بيت آخر.' || v_nl || v_nl
          || 'ابدأوا الآن: اكتبوا اسمه وما أكثر ما يتعبكم معه هذه الأيام.';
    end if;
    return null;
  end if;

  select upper(btrim(f.country)) into v_country
  from public.followers f where f.id = p_parent_id;
  if not found then return null; end if;

  if p_key = 'country_recorded' then
    v_cs := public.country_state(p_parent_id);
    if (v_cs->>'state') = 'supported' then
      return '✅ سجّلنا: ' || coalesce(v_cs->>'name_ar', 'بلدكم') || '.' || v_nl || v_nl
          || '🌿 كل ما بيننا الآن مجاني، ويبقى مجانياً — هذا لن يتغيّر أبداً.';
    elsif (v_cs->>'state') = 'unknown' then
      return 'لم أتعرّف على البلد.' || v_nl
          || 'لا بأس — كل ما بيننا يبقى كما هو، دون نقص.';
    else
      return '✅ سجّلنا بلدكم.' || v_nl || v_nl
          || 'وكل ما بيننا يبقى كما هو تماماً، مجاناً.' || v_nl || v_nl
          || 'أمّا المرافقة الكاملة فلم تصل إليه بعد، لسبب واحد:' || v_nl
          || 'لا تتوفّر بعد طريقة دفع محلية نثق بها. وحين تتوفّر، تصلكم رسالة.';
    end if;
  end if;

  select coalesce((now() at time zone ct.iana_tz)::date, current_date) into v_today
  from public.country_timezone ct where ct.code = v_country;
  v_today := coalesce(v_today, current_date);

  select c.id, nullif(btrim(c.name), ''), nullif(btrim(c.age_note), '')
    into v_child, v_name, v_age
  from public.children c where c.follower_id = p_parent_id
  order by c.is_primary desc nulls last, c.created_at limit 1;

  v_who := coalesce(v_name, 'طفلكم');

  if p_key = 'menu_ask_team' then
    return '🌿 احكوا لي ما حدث في أيّ وقت، وأعطيكم خطوة صغيرة تناسب موقفكم مع ' || v_who || ' — بلا مقابل.' || v_nl || v_nl ||
           'وللفرق بين هذا وبين المرافقة الكاملة، اكتبوا /adam.';
  end if;

  if p_key = 'menu_child' then
    if v_name is null then
      return '👦 ما أعرفه عن طفلكم' || v_nl || v_nl
          || 'ما زلت لا أعرف عنه شيئاً — وهذا بيدكم تماماً.' || v_nl || v_nl
          || 'كل ما حكيتم أكثر، فهمته أعمق؛ ولما أفهمه أكثر، تصير الخطوة التي أقترحها عليكم أدقّ لبيتكم بالذات، لا لأي بيت آخر.' || v_nl || v_nl
          || 'ابدأوا الآن: اكتبوا اسمه وما أكثر ما يتعبكم معه هذه الأيام.';
    end if;

    select array_agg(distinct public.situation_label_ar(s.key))
      into v_sits
    from public.situations s
    where s.child_id = v_child and s.status in ('candidate','confirmed')
      and s.key is not null and s.key <> 'other';

    select array_agg(cp.pattern_label order by cp.evidence_count desc)
      into v_pats
    from public.child_patterns cp
    where cp.child_id = v_child and cp.safe_for_record;

    begin
      select light_memory into v_light_raw from public.followers where id = p_parent_id;
      if v_light_raw is not null and btrim(v_light_raw) <> '' then
        v_light := v_light_raw::jsonb;
      end if;
    exception when others then
      v_light := null;
    end;

    v_lines := array['👦 ما أعرفه عن ' || v_name || coalesce(' · ' || v_age, '')];
    v_lines := v_lines || ''::text;

    if v_light is not null and coalesce(v_light->>'child_insight','') <> '' then
      v_lines := v_lines || (v_light->>'child_insight')::text;
      v_facts_count := v_facts_count + 1;

      if v_sits is not null and array_length(v_sits,1) > 0 then
        v_lines := v_lines || ''::text;
        v_lines := v_lines || ('🔍 وأصعب اللحظات: ' || array_to_string(v_sits, '، '))::text;
      end if;

      v_lines := v_lines || ''::text;
      v_lines := v_lines || 'وهذا كله من كلامكم أنتم — وكلما حكيتم أكثر، صارت الخطوة أدق لبيتكم بالذات.'::text;

      return array_to_string(v_lines, v_nl);
    end if;

    if v_sits is not null and array_length(v_sits,1) > 0 then
      v_lines := v_lines || ('🔍 أصعب اللحظات مع ' || v_name || ': ' || array_to_string(v_sits, '، '))::text;
      v_facts_count := v_facts_count + 1;
    end if;

    if v_pats is not null and array_length(v_pats,1) > 0 then
      v_lines := v_lines || ('🧩 لاحظنا نمطاً متكرراً: ' || v_pats[1] ||
        case when array_length(v_pats,1) > 1 then '، و' || v_pats[2] else '' end)::text;
      v_facts_count := v_facts_count + 1;
    end if;

    if v_light is not null then
      if coalesce(v_light->>'core_pain','') <> '' then
        v_lines := v_lines || ('💭 ما يتعبكم أكثر: ' || (v_light->>'core_pain'))::text;
        v_facts_count := v_facts_count + 1;
      end if;
      if coalesce(v_light->>'emotional_state','') <> '' then
        v_lines := v_lines || ('🤍 حالتكم هذه الأيام: ' || (v_light->>'emotional_state'))::text;
        v_facts_count := v_facts_count + 1;
      end if;
      if coalesce(v_light->>'last_win','') <> '' then
        v_lines := v_lines || ('✨ آخر ما نجح: ' || (v_light->>'last_win'))::text;
        v_facts_count := v_facts_count + 1;
      end if;
    end if;

    if v_facts_count = 0 then
      v_lines := v_lines || 'لم يتّضح بعد ما الذي يتكرّر معه.'::text;
      v_lines := v_lines || ''::text;
      v_lines := v_lines || ('احكوا لي عن يومكم مع ' || v_name || '، وكلما حكيتم عرفته أكثر.')::text;
    else
      v_lines := v_lines || ''::text;
      v_lines := v_lines || ('وهذا كله من كلامكم أنتم — وكلما حكيتم أكثر، صارت الخطوة أدق لبيتكم بالذات.')::text;
    end if;

    return array_to_string(v_lines, v_nl);
  end if;

  if p_key in ('menu_progress','menu_next_goal',
               'menu_journey_progress','menu_lighten_load') then

    v_e     := public.parent_effort(p_parent_id);
    v_tried := (v_e->>'tried_this_week')::int;
    v_prev  := (v_e->>'tried_last_week')::int;
    v_calm  := (v_e->>'calm_this_week')::int;
    v_ever  := (v_e->>'tried_ever')::int;

    -- ⭐ منحنى الوالد (parent_moments): الرقم الرئيسي حين يوجد. لا
    -- يوجد إلا لمن استخدم زر النجدة أو سؤال المساء في التطبيق
    -- المصغّر؛ لهذا نتحقّق من ready قبل الاعتماد عليه.
    v_curve       := public.get_parent_curve(p_parent_id);
    v_curve_ready := coalesce((v_curve->>'ready')::boolean, false);
    v_held_week   := coalesce((v_curve->>'heldWeek')::int, 0);
    v_erupt_week  := coalesce((v_curve->>'eruptWeek')::int, 0);
    v_erupt_delta := coalesce((v_curve->>'eruptDelta')::int, 0);

    if v_ever = 0 and not v_curve_ready then
      return '📈 تقدّمكم' || v_nl || v_nl
          || 'لم نجرّب شيئاً معاً بعد.' || v_nl || v_nl
          || 'كيف تمشي الأمور: تحكون لي ما تعبتم منه اليوم، فأعطيكم شيئاً واحداً صغيراً تجرّبونه،' || v_nl
          || 'ثم أسألكم مساءً: هل تغيّر شيء عندكم أنتم؟' || v_nl || v_nl
          || 'وبعد ثلاث محاولات يصير عندي ما يكفي لأريكم الموقف الذي يستهلك صبركم أكثر من غيره،' || v_nl
          || 'ومتى يصعب عليكم التماسك فيه.' || v_nl || v_nl
          || 'نبدأ الآن: احكوا لي ما حدث معه اليوم.';
    elsif v_ever < 3 and not v_curve_ready then
      return '📈 تقدّمكم' || v_nl || v_nl
          || 'جرّبتم معه ' || public.occasions_latin(v_ever) || ' حتى الآن.' || v_nl || v_nl
          || 'بعد ثلاث محاولات يصير عندي ما يكفي لأريكم الموقف الذي يستهلك صبركم أكثر من غيره،' || v_nl
          || 'ومتى يصعب عليكم التماسك فيه — وهناك يبدأ الفرق الحقيقي.' || v_nl || v_nl
          || 'احكوا لي عن يومكم معه، ونكمل.';
    end if;

    v_lines := array['📈 تقدّمكم'];
    v_lines := v_lines || ''::text;

    if v_curve_ready then
      v_lines := v_lines || ('هذا الأسبوع: أوشكتم وتماسكتم ' || public.ar_occasions(v_held_week) || '، وانفجرتم ' || public.ar_occasions(v_erupt_week) || '.')::text;
      v_lines := v_lines || ''::text;
      if v_erupt_delta < 0 then
        v_lines := v_lines || ('وهذا أقل انفجاراً من الأسبوع الماضي بـ ' || abs(v_erupt_delta)::text || ' ' || (case when abs(v_erupt_delta)=1 then 'مرة' else 'مرات' end) || '.')::text;
      elsif v_erupt_delta > 0 then
        v_lines := v_lines || 'وهذا الأسبوع أثقل من الذي قبله — يحدث، ولا يُلغي ما قبله.'::text;
      else
        v_lines := v_lines || 'ثابتون على نفس الإيقاع — والثبات نفسه ليس قليلاً.'::text;
      end if;
      if v_tried > 0 then
        v_lines := v_lines || ''::text;
        v_lines := v_lines || ('وجرّبتم معه ' || public.occasions_latin(v_tried) || '، ' || v_calm::text || ' منها مرّت بهدوء عند ' || v_who || '.')::text;
      end if;
      v_lines := v_lines || ''::text;
      v_lines := v_lines || 'ما يهمّ هنا ليس أن تهدأوا كل يوم — بل أن تتماسكوا أكثر مما تنفجرون، لأن هذا هو ما يتراكم.'::text;
      return array_to_string(v_lines, v_nl);
    end if;

    v_lines := v_lines || ('هذا الأسبوع: جرّبتم ' || public.occasions_latin(v_tried) || ' مع ' || v_who || '.')::text;

    if v_tried > 0 then
      v_lines := v_lines || ''::text;
      v_lines := v_lines || ('هذا الأسبوع  ' || public.render_progress_bar(v_calm::numeric / v_tried::numeric))::text;
      if v_prev > 0 then
        v_lines := v_lines || ('الأسبوع الماضي ' || public.render_progress_bar((select coalesce((v_e->>'calm_last_week')::numeric,0)) / v_prev::numeric))::text;
      end if;
      v_lines := v_lines || ''::text;
    end if;

    if v_calm > 0 then
      v_lines := v_lines || (case
        when v_calm = 1 then 'واحدة منها مرّت بهدوء.'
        when v_calm = 2 then 'اثنتان منها مرّتا بهدوء.'
        else v_calm::text || ' منها مرّت بهدوء.' end)::text;
    else
      v_lines := v_lines || 'ولم تمرّ أيّ منها بهدوء بعد — وهذا يحدث، ولا يعني أننا نتراجع.'::text;
    end if;

    v_lines := v_lines || (case
      when v_tried > v_prev then 'وهذا أكثر من الأسبوع الماضي.'
      when v_tried < v_prev then 'أسبوع أثقل من الذي قبله. والمحاولة نفسها تُحسب لكم.'
      else                       'ثابتون على نفس الإيقاع.' end)::text;

    v_lines := v_lines || ''::text;
    v_lines := v_lines || 'ما يهمّ هنا ليس أن يهدأ كل يوم — بل أن تحاولوا، لأن التكرار هو ما يكسر القصة.'::text;

    return array_to_string(v_lines, v_nl);
  end if;

  return null;
end;
$function$;


-- menu_journey_presence: a goal "for your child" -> a goal the parent wants
-- to reach with him. harvest_ask + menu_settings: tie the daily question to
-- the step actually tried, and keep both in sync with each other.
update public.conversation_moments
set body_ar = 'المجاني يبقى مجانياً — الحديث، والفهم، وشيء صغير كل يوم. لا ينقص منه شيء.' || chr(10)
           || 'وحين يظهر هدف واضح تريدون الوصول إليه معه، نبني رحلة نمشي فيها يوماً بيوم حتى نصل.' || chr(10)
           || 'وفريق آدم يشرح التفاصيل متى شئتم: https://t.me/Abdouleg'
where key = 'menu_journey_presence';

update public.conversation_moments
set body_ar = 'الخطوة اللي جرّبتوها اليوم — كيف مرّت؟'
where key = 'harvest_ask';

update public.conversation_moments
set body_ar = '⚙️ الإعدادات' || chr(10) || chr(10)
           || 'مرة واحدة في اليوم يصلكم منّي إشعار واحد: أسألكم فيه كيف مرّت الخطوة اللي جرّبتوها اليوم.' || chr(10)
           || 'جوابكم هو ما يجعلني أعرف ما ينفع معكم وما لا ينفع — ومنه يتحسّن ما أقترحه.' || chr(10) || chr(10)
           || 'ولا شيء غير ذلك يصلكم أبداً. لا إعلانات، ولا تذكيرات، ولا رسائل أخرى.'
where key = 'menu_settings';
