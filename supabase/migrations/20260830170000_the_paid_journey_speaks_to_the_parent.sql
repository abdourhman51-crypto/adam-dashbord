begin;

-- ============================================================
-- الخيار أ: الرحلة المدفوعة تتحدّث عن الوالد
--
-- الاستمارة (journey_problem_catalog) تبقى تسأل عن موقف الطفل —
-- هذا سياق حقيقي ومفيد، لا يتغيّر. لكن كل ما يُبنى على السياق
-- من هنا فصاعداً — الهدف المختار، الوعد بما ينتظر بعد ٢٩ يوماً،
-- نصّ العرض، بصائر آدم، تقرير الختام — كان يتحدّث عن تحوّل
-- الطفل. أصبح يتحدّث عن تحوّل الوالد نفسه: كيف يتصرّف حين يفقد
-- صبره، لا هل هدأ الطفل.
--
-- انعكاس سلوك الطفل يبقى حاضراً في كل مكان — كنتيجة تُذكر بعد
-- تحوّل الوالد، لا كهدف الجملة الأولى.
--
-- ما لم يتغيّر هنا، وسبب ذلك: شريط التقدّم الرسمي على شاشة
-- «رحلتي» (objective_current/objective_target) ما زال يُحسب من
-- v_stage_progress، ومقياساه الوحيدان (calm_nights_in_window /
-- steps_done_in_window) مصدرهما daily_logs — بيانات يكتبها
-- البوت في إيقاعه الليلي. منحنى الوالد (parent_moments) لا
-- يُكتب إلا من التطبيق المصغّر (زر النجدة، سؤال المساء). ربط
-- الشريط الرسمي بمنحنى الوالد يعني أن والداً يتحدّث مع البوت
-- فقط، ولا يفتح التطبيق المصغّر أبداً، سيرى شريطه ثابتاً عند
-- صفر — لأن البوت نفسه لا يسأل سؤال «تماسكتِ أم انفجرتِ» بعد.
-- هذا يحتاج سؤالاً جديداً في محادثة البوت، وهو قرار محادثة
-- منفصل، لا نصّ فقط. فتُرك شريط التقدّم الرسمي كما هو، والدوال
-- السردية أدناه (بصائر آدم، تقرير الختام، تقدّمكم في القائمة)
-- هي التي تقود بمنحنى الوالد الحقيقي حين يوجد، وتتراجع بصدق حين
-- لا يوجد بدل أن تختلق رقماً.
-- ============================================================


-- ------------------------------------------------------------
-- 1. الخيارات التي يختار منها الوالد هدفه — كانت عن تغيّر في
--    الطفل، صارت عن تغيّر في استجابة الوالد لنفس الموقف.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.journey_outcome_options(p_problem_key text)
 RETURNS jsonb
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select case p_problem_key
    when 'anger'    then '["أهدأ خلال دقيقة بدل الانفجار","أخفض صوتي بدل رفعه","أثبت على قراري بهدوء بلا صراخ"]'::jsonb
    when 'out'      then '["أطلب مرة واحدة بلا تكرار عصبي","لا أفقد صبري مع كل دقيقة تأخير","أخرج من البيت بهدوء مهما تأخّرنا"]'::jsonb
    when 'screen'   then '["أوقف الجهاز بهدوء بلا نوبة غضب مني أنا أيضاً","لا أدخل في معركة صوت على كل تذكير","أثبت على الوقت المتفق عليه بلا تفاوض متكرر"]'::jsonb
    when 'stubborn' then '["لا أكرر الطلب عشر مرات بصوت أعلى كل مرة","أرفض بهدوء بدل الدخول في جدال","أثبت على الحدّ بلا أن أرفع صوتي"]'::jsonb
    when 'study'    then '["لا أفقد صبري وهو يماطل","أساعده بهدوء بدل التوتر من أول دقيقة","أوقف الجلسة بهدوء بدل الصراخ حين يتشتت"]'::jsonb
    when 'sleep'    then '["أهدأ عند كل استيقاظ ليلي بدل التوتر","أثبت على وقت النوم بلا نفاد صبر","لا أنفجر في آخر الليل بعد يوم طويل"]'::jsonb
    when 'meal'     then '["لا أدخل في معركة على كل لقمة","أهدأ حين يرفض الطعام بدل الضغط عليه","أثبت على القرار بلا مطاردة ولا صراخ"]'::jsonb
    when 'sibling'  then '["لا أقارن بينهما حين أتعب","أهدأ قبل أن أتدخّل بين الإخوة","أوزّع وقتي بينهما بهدوء بدل الشعور بالذنب"]'::jsonb
    else '[]'::jsonb
  end;
$function$;


-- ------------------------------------------------------------
-- 2. ما ينتظر الوالد بعد ٢٩ يوماً — كان انعكاس سلوك الطفل، صار
--    انعكاس استجابة الوالد، مع سلوك الطفل باقياً كنتيجة تُذكر
--    في السطر الأخير من كل مجموعة، لا الأول.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.journey_completion_promises(p_problem_key text)
 RETURNS jsonb
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select case p_problem_key
    when 'anger' then '[
      "😌 تهدأون خلال دقائق بدل ساعة كاملة من التوتر",
      "🗣️ تتكلّمون بدل ما تنفجرون — والفرق يحسّه البيت كله",
      "🧠 تعرفون لحظة الانفجار قبل ما تصلوها، لا بعدها",
      "💪 يزول شعور العجز أمام كل نوبة، ويحل مكانه إحساس أنكم تعرفون ماذا تفعلون"
    ]'::jsonb
    when 'out' then '[
      "🚪 تخرجون بهدوء، مهما تأخّر الاستعداد",
      "⏱️ صبركم يصمد أطول من دقيقة التأخير الأولى",
      "🧠 فهم أعمق لما يستفزّكم بالذات في هذا الموقف",
      "🤝 تعاون حقيقي بدل شد وجذب كل صباح"
    ]'::jsonb
    when 'screen' then '[
      "📱 إغلاق الجهاز بهدوء، بلا نوبة غضب منكم أنتم",
      "⏳ ثبات على القرار بلا تفاوض متكرر",
      "🧠 فهم السبب الحقيقي وراء تعلّقه، لا مجرد منعه",
      "🎨 طاقة أقل تُستهلك في المعركة اليومية"
    ]'::jsonb
    when 'stubborn' then '[
      "✅ ثبات على الحدّ من أول مرة، بلا تكرار الطلب عشر مرات",
      "💬 نقاش أقل، وصوت أهدأ عند كل طلب بسيط",
      "🌿 رفض بهدوء حين يكون القرار لا",
      "🧠 فهم ما يقف وراء العناد، لا مجرد مواجهته"
    ]'::jsonb
    when 'study' then '[
      "📚 صبر يصمد رغم المماطلة",
      "🎯 جلسة واحدة هادئة بدل عشر محاولات متوترة",
      "😌 إنهاء الواجب بهدوء، لا بصراخ من الطرفين",
      "🧠 معرفة أي وقت وطريقة تناسبه هو بالذات"
    ]'::jsonb
    when 'sleep' then '[
      "🌙 هدوء يصمد كل ليلة عند وقت السرير",
      "⏰ صبر يكفي لآخر الطريق، لا ينفد في منتصفه",
      "🌛 هدوء سريع لو استيقظ ليلاً",
      "💪 يزول القلق كل مساء من معركة النوم قبل أن تبدأ"
    ]'::jsonb
    when 'meal' then '[
      "🍽️ هدوء على الطاولة كل وجبة، بلا معركة",
      "🥦 صبر يصمد أمام الرفض بلا ضغط",
      "⏱️ ثبات على القرار، بلا مطاردة بالملعقة",
      "🧠 فهم ما يقف فعلاً وراء رفضه للطعام"
    ]'::jsonb
    when 'sibling' then '[
      "🤍 هدوء عند كل خلاف بينهما، بلا انحياز متسرّع",
      "🕊️ توتر أقل فيكم أنتم عند كل مقارنة",
      "🤝 وقت يُوزَّع بهدوء، بلا شعور بالذنب",
      "🧠 فهم أعمق لمصدر الغيرة الحقيقي"
    ]'::jsonb
    else '[
      "🎯 تغيّر حقيقي وملموس في كيف تتصرّفون في أصعب لحظاتكم",
      "🧠 فهم أعمق لما يستفزّكم بالذات، لا مجرد ردة الفعل عليه",
      "📊 صورة واضحة بالأرقام: هل تتحسّن سيطرتكم فعلاً أم لا",
      "💪 زوال شعور العجز، ومكانه إحساس أنكم تعرفون كيف تتصرفون"
    ]'::jsonb
  end;
$function$;

-- ------------------------------------------------------------
-- 3. نصّ العرض نفسه. فرعان: قبل الاستمارة (قائمة تسويقية عامة)
--    وبعدها (يُرجّع الهدف الذي اختاره الوالد). كلاهما كان يَعِد
--    بتحوّل الطفل؛ صار يَعِد بتحوّل الوالد، مع بقاء الطفل نتيجة
--    تُذكر لا هدفاً يُفتتح به السطر الأول.
--
--    ما لم يتغيّر عمداً: سطر السعر والتنويه بأن آدم لا يتولّى
--    الدفع، وكل الأزرار. هذان خارج نطاق قرار اليوم.
-- ------------------------------------------------------------
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
            'label', case when v_name is null then '📞 نُفعّل الخطة مع فريق آدم'
                          else '📞 نُفعّل خطة ' || v_name || ' مع الفريق' end,
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
          '👇 نبني خطتكم أنتم الآن — نصف دقيقة، بلا أي التزام:';

        v_buttons := jsonb_build_array(
          jsonb_build_object('label', '🎯 نبني خطتنا الآن', 'cb', 'jf_start'),
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
              'احكوا لي وش المشكلة اللي تثقل عليكم أكثر هالأيام مع ' || v_who || '، ونبني منها هدفاً جديداً.';
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

-- ------------------------------------------------------------
-- 4. بصائر آدم. الرقم الرئيسي عند اكتمال الحالة صار منحنى
--    الوالد (get_parent_curve) حين يوجد — كم مرة أوشك وتماسك،
--    وانفجر، والدلتا الأسبوعية. ليالي الطفل الهادئة تبقى، لكن
--    كجملة تالية «وينعكس هذا على [الطفل] أيضاً»، لا الجملة
--    الأولى. حين لا توجد بيانات منحنى بعد (لم يُستخدم التطبيق
--    المصغّر) لا نختلق رقماً — نروي من الحضور، ونرشد الوالد إلى
--    أين يجد الصورة الأدق.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.adam_reading(p_parent_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_nl        text := chr(10);
  v_paid      boolean;
  v_child     text;
  v_sit       text;
  v_nights    int;
  v_calm      int;
  v_hard      int;
  v_calm_prev int;
  v_trigger   text;
  v_calms     text;
  v_stage     jsonb;
  v_state     text;
  v_body      text;
  v_nights_word text;
  v_who       text;
  v_lines     text[] := '{}';
  v_curve       jsonb;
  v_curve_ready boolean;
  v_held_week   int;
  v_erupt_week  int;
  v_erupt_delta int;
  v_held_total  int;
begin
  if p_parent_id is null then
    return jsonb_build_object('state', 'unknown', 'body', null);
  end if;

  select f.funnel_stage = 'paid_active' into v_paid
  from public.followers f where f.id = p_parent_id;
  if not found then
    return jsonb_build_object('state', 'unknown', 'body', null);
  end if;

  select nullif(btrim(c.name), '') into v_child
  from public.children c
  where c.follower_id = p_parent_id and c.name not in ('الطفل', 'الطفلة')
  order by c.is_primary desc, c.created_at limit 1;

  v_who := coalesce(v_child, 'طفلكم');

  select s.label_ar into v_sit
  from public.situations s
  where s.parent_id = p_parent_id and s.status = 'confirmed'
  order by s.evidence_count desc, s.last_observed desc limit 1;

  select count(*) filter (where d.night_result is not null),
         count(*) filter (where d.night_result = 'calm'),
         count(*) filter (where d.night_result = 'hard')
    into v_nights, v_calm, v_hard
  from public.daily_logs d where d.follower_id = p_parent_id;

  select count(*) filter (where d.night_result = 'calm') into v_calm_prev
  from public.daily_logs d
  where d.follower_id = p_parent_id
    and d.log_date >  current_date - 14
    and d.log_date <= current_date - 7;

  select public.hard_moment_label(d.hard_moment) into v_trigger
  from public.daily_logs d
  where d.follower_id = p_parent_id and d.hard_moment is not null
  group by d.hard_moment order by count(*) desc limit 1;

  select string_agg(line, v_nl) into v_calms from (
    select '• ' || coalesce(d.step_given, d.seed_text) || ' — نجحت '
           || (count(*) filter (where d.step_status = 'done'))::text
           || ' من ' || count(*)::text as line
    from public.daily_logs d
    where d.follower_id = p_parent_id
      and coalesce(d.step_given, d.seed_text) is not null
    group by coalesce(d.step_given, d.seed_text)
    having count(*) filter (where d.step_status = 'done') > 0
    order by count(*) filter (where d.step_status = 'done') desc, count(*) desc
    limit 3
  ) t;

  v_stage := public.stage_state(p_parent_id);

  -- ⭐ منحنى الوالد (parent_moments) — المصدر الوحيد لتماسكتم/انفجرتم.
  -- لا يوجد إلا لمن استخدم زر النجدة أو سؤال المساء في التطبيق
  -- المصغّر؛ لهذا نتحقّق من ready قبل الاعتماد عليه، ولا نختلق رقماً
  -- لمن لم يستخدمه بعد.
  v_curve       := public.get_parent_curve(p_parent_id);
  v_curve_ready := coalesce((v_curve->>'ready')::boolean, false);
  v_held_week   := coalesce((v_curve->>'heldWeek')::int, 0);
  v_erupt_week  := coalesce((v_curve->>'eruptWeek')::int, 0);
  v_erupt_delta := coalesce((v_curve->>'eruptDelta')::int, 0);
  v_held_total  := coalesce((v_curve->>'heldTotal')::int, 0);

  v_nights_word := case when v_nights between 3 and 10 then 'ليالٍ' else 'ليلة' end;

  v_state := case
    when not v_paid and v_nights = 0 then 'locked'
    when not v_paid and v_nights > 0 then 'locked_preview'
    when v_nights = 0    then 'opened'
    when v_nights < 7    then 'gathering'
    else                      'full' end;

  if v_state = 'locked' then
    v_lines := array_append(v_lines, '✨ بصائر آدم');
    v_lines := array_append(v_lines, '');
    if v_sit is not null and v_child is not null then
      v_lines := array_append(v_lines, ('أعرف أنّ ' || v_sit || ' يستهلك صبركم مع ' || v_child || '.'));
    elsif v_child is not null then
      v_lines := array_append(v_lines, ('أعرف ' || v_child || '، ولا أعرف بعد متى يصعب عليكم التماسك معه.'));
    else
      v_lines := array_append(v_lines, 'لا أعرف بيتكم بعد بما يكفي لأقرأه.');
    end if;
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, 'والبصائر الكاملة تعطيكم شيئاً أهم من المعلومات:');
    v_lines := array_append(v_lines, 'تعرفون بالضبط: هل تتحسّن سيطرتكم فعلاً، أم تدورون في نفس الدائرة — بالأرقام لا بالإحساس.');
    v_lines := array_append(v_lines, 'كل أسبوع تشوفون بأعينكم كم مرة أوشكتم وتماسكتم.');
    v_lines := array_append(v_lines, 'وتعرفون أي خطوة نفعت مع بيتكم بالذات، فلا تكرّرون تجربة فشلت من قبل.');
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, 'ابدأوا بالحكي عن يومكم معه، وتُفتح لكم أول لمحة من هنا.');

  elsif v_state = 'locked_preview' then
    v_lines := array_append(v_lines, ('✨ بصائر ' || v_who || ' — لمحة'));
    v_lines := array_append(v_lines, '');
    if v_curve_ready then
      v_lines := array_append(v_lines, ('هذا الأسبوع: أوشكتم وتماسكتم ' || public.ar_occasions(v_held_week) || '.'));
      v_lines := array_append(v_lines, '');
    end if;
    v_lines := array_append(v_lines, ('حتى الآن: ' || v_nights::text || ' ' || v_nights_word || ' حكيتم لي عنها، '
                           || v_calm::text || ' منها مرّت بهدوء عند ' || v_who || '.'));
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, (public.render_progress_bar(v_calm::numeric / greatest(v_nights,1)::numeric) || ' هدوء'));
    v_lines := array_append(v_lines, '');
    if v_trigger is not null then
      v_lines := array_append(v_lines, '🔒 ولاحظت نمطاً يتكرّر عندكم بالذات — يظهر كاملاً، بالاسم والتفصيل، مع المرافقة الكاملة.');
    else
      v_lines := array_append(v_lines, '🔒 وبعد أسبوع كامل من الحكي، أقدر أقول لكم متى تتماسكون ومتى يصعب عليكم — هذا يُفتح مع المرافقة الكاملة.');
    end if;

  elsif v_state = 'opened' then
    v_lines := array_append(v_lines, ('✨ بصائر ' || v_who || ' — فُتحت الآن'));
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, 'هذا ما أعرفه عنكم حتى اللحظة:');
    if v_child is not null then
      v_lines := array_append(v_lines, ('• طفلكم ' || v_child || '.'));
    end if;
    if v_sit is not null then
      v_lines := array_append(v_lines, ('• و' || v_sit || ' يستهلك صبركم أكثر من غيره.'));
    end if;
    if (v_stage->>'in_stage')::boolean then
      v_lines := array_append(v_lines, ('• واتّفقنا على: ' || (v_stage->>'objective_text') || '.'));
    end if;
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, 'من الليلة أبدأ أسألكم كل مساء سؤالاً واحداً قصيراً.');
    v_lines := array_append(v_lines, 'كل إجابة تضيف سطراً إلى هذه الصفحة.');
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, 'بعد ثلاث ليالٍ أريكم ما يتكرّر.');
    v_lines := array_append(v_lines, 'وبعد أسبوع أريكم كم مرة تماسكتم فعلاً، وكيف تغيّر ذلك.');
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, 'لا شيء مطلوب منكم الآن سوى أن تحكوا لي كيف مرّت الليلة.');

  elsif v_state = 'gathering' then
    v_lines := array_append(v_lines, ('✨ بصائر ' || v_who));
    v_lines := array_append(v_lines, '');
    if v_curve_ready then
      v_lines := array_append(v_lines, ('هذا الأسبوع: أوشكتم وتماسكتم ' || public.ar_occasions(v_held_week) || '.'));
      v_lines := array_append(v_lines, '');
    end if;
    v_lines := array_append(v_lines, ('حتى الآن: ' || v_nights::text || ' ' || v_nights_word || ' حكيتم لي عنها، '
                           || v_calm::text || ' منها مرّت بهدوء عند ' || v_who || '.'));
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, (public.render_progress_bar(v_calm::numeric / greatest(v_nights,1)::numeric) || ' هدوء'));
    v_lines := array_append(v_lines, '');
    if v_trigger is not null then
      v_lines := array_append(v_lines, ('وأصعب اللحظات تتكرّر ' || v_trigger || '.'));
      v_lines := array_append(v_lines, '');
    end if;
    if v_calms is not null then
      v_lines := array_append(v_lines, 'وما نجح معكم حتى الآن:');
      v_lines := array_append(v_lines, v_calms);
      v_lines := array_append(v_lines, '');
    end if;
    -- ⭐ Gap framing: concrete countdown instead of a vague "الصورة تتشكل".
    -- Honest here (unlike the free tier) because this IS governed by
    -- night count -- 'full' triggers at 7 logged nights.
    v_lines := array_append(v_lines, ('باقي ' || (7 - v_nights)::text || ' ' ||
      (case when 7 - v_nights = 1 then 'ليلة' else 'ليالٍ' end) ||
      ' حتى تكتمل الصورة الأسبوعية — وأقول لكم بالأرقام إن كانت سيطرتكم تتحسّن أم لا.'));

  else
    v_lines := array_append(v_lines, ('✨ بصائر ' || v_who));
    v_lines := array_append(v_lines, '');
    if v_curve_ready then
      -- ⭐ الرقم الرئيسي الآن: منحنى الوالد، لا ليالي الطفل الهادئة.
      v_lines := array_append(v_lines, ('هذا الأسبوع: أوشكتم وتماسكتم ' || public.ar_occasions(v_held_week) || '، وانفجرتم ' || public.ar_occasions(v_erupt_week) || '.'));
      v_lines := array_append(v_lines, '');
      if v_erupt_delta < 0 then
        v_lines := array_append(v_lines, ('وهذا أقل انفجاراً من الأسبوع الماضي بـ ' || abs(v_erupt_delta)::text || ' ' || (case when abs(v_erupt_delta)=1 then 'مرة' else 'مرات' end) || '.'));
      elsif v_erupt_delta > 0 then
        v_lines := array_append(v_lines, 'وهذا الأسبوع أثقل من الذي قبله — يحدث، ولا يُلغي ما قبله.');
      else
        v_lines := array_append(v_lines, 'وهو ثابت مع الأسبوع الماضي — والثبات نفسه ليس قليلاً.');
      end if;
      v_lines := array_append(v_lines, '');
      v_lines := array_append(v_lines, ('ومنذ أن بدأتم: ' || public.ar_occasions(v_held_total) || ' أوشكتم فيها ولم تنفجروا.'));
      v_lines := array_append(v_lines, '');
      v_lines := array_append(v_lines, ('وينعكس هذا على ' || v_who || ' أيضاً — ' || v_calm::text || ' من ' || v_nights::text || ' ' || v_nights_word || ' مرّت بهدوء.'));
    else
      -- لا بيانات منحنى بعد — لم يُستخدم زر النجدة ولا سؤال المساء في
      -- التطبيق المصغّر. لا نختلق رقماً؛ نروي من الحضور بدل الرقم.
      v_lines := array_append(v_lines, ('من ' || v_nights::text || ' ' || v_nights_word || ' حكيتم لي عنها، '
                             || v_calm::text || ' مرّت بهدوء عند ' || v_who || ' و'
                             || v_hard::text || ' كانت صعبة.'));
      v_lines := array_append(v_lines, '');
      v_lines := array_append(v_lines, (public.render_progress_bar(v_calm::numeric / greatest(v_nights,1)::numeric) || ' هدوء'));
      if v_calm > v_calm_prev then
        v_lines := array_append(v_lines, 'وهذا الأسبوع أهدأ من الذي قبله.');
      elsif v_calm < v_calm_prev then
        v_lines := array_append(v_lines, 'وهذا الأسبوع أصعب من الذي قبله — يحدث، والمهم أنكم واصلتم.');
      else
        v_lines := array_append(v_lines, 'وهو ثابت مع الأسبوع الماضي.');
      end if;
    end if;
    if v_trigger is not null then
      v_lines := array_append(v_lines, '');
      v_lines := array_append(v_lines, ('ما يتكرّر: أصعب اللحظات تأتي ' || v_trigger || '.'));
    end if;
    if v_calms is not null then
      v_lines := array_append(v_lines, '');
      v_lines := array_append(v_lines, 'وما ينفع معكم فعلاً — من تجربتكم أنتم، لا من نصيحة عامّة:');
      v_lines := array_append(v_lines, v_calms);
    end if;
    if not v_curve_ready then
      v_lines := array_append(v_lines, '');
      v_lines := array_append(v_lines, 'وإن أردتم صورة أدق لتماسككم لحظة بلحظة، زر النجدة وسؤال المساء في التطبيق المصغّر يبنيان هذا معكم.');
    end if;
    if (v_stage->>'in_stage')::boolean then
      v_lines := array_append(v_lines, '');
      v_lines := array_append(v_lines, ('الهدف: ' || (v_stage->>'objective_text') || '.'));
      v_lines := array_append(v_lines, (v_stage->>'phase_ar'));
    end if;
  end if;

  v_body := array_to_string(v_lines, v_nl);

  return jsonb_build_object(
    'state', v_state,
    'body', v_body,
    'child_name', v_child,
    'nights', v_nights,
    'calm', v_calm,
    'in_stage', coalesce((v_stage->>'in_stage')::boolean, false));
end $function$;

-- ------------------------------------------------------------
-- 5. تقرير نهاية الرحلة. نفس المنطق: الرقم الرئيسي هو كم مرة
--    تماسك الوالد على مدى الرحلة كلها (أول أسبوع مقابل آخر
--    أسبوع)، وليالي الطفل الهادئة تصير سطراً واحداً بعده «وينعكس
--    هذا على [الطفل] أيضاً». حين لا توجد بيانات منحنى لهذه
--    الرحلة، يبقى التقرير بالضبط كما كان — لا رقم مختلق أفضل من
--    عدم وجوده.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.close_stage_report(p_parent_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_nl text := chr(10);
  v_child text; v_objective text; v_context text; v_freq text;
  v_child_id uuid; v_started date; v_days int;
  v_nights int; v_calm int; v_hard int;
  v_calm_w1 int; v_calm_last int;
  v_calms text;
  v_sits text[]; v_pats text[];
  v_lines text[] := '{}';
  v_curve       jsonb;
  v_curve_ready boolean;
  v_held_total  int;
  v_erupt_w1    int;
  v_erupt_last  int;
begin
  select s.child_id, s.objective_text, s.problem_context_text, s.frequency_label, s.started_at::date
    into v_child_id, v_objective, v_context, v_freq, v_started
  from public.stages s
  where s.parent_id = p_parent_id and s.status in ('active','extended')
  order by s.started_at desc limit 1;

  select nullif(btrim(c.name),'') into v_child
  from public.children c where c.id = v_child_id;
  v_child := coalesce(v_child, 'طفلكم');
  v_days := greatest(1, (current_date - coalesce(v_started, current_date)));

  select count(*) filter (where d.night_result is not null),
         count(*) filter (where d.night_result = 'calm'),
         count(*) filter (where d.night_result = 'hard')
    into v_nights, v_calm, v_hard
  from public.daily_logs d where d.follower_id = p_parent_id;

  select count(*) filter (where d.night_result = 'calm') into v_calm_w1
  from public.daily_logs d
  where d.follower_id = p_parent_id and d.log_date >= coalesce(v_started, current_date)
    and d.log_date < coalesce(v_started, current_date) + 7;

  select count(*) filter (where d.night_result = 'calm') into v_calm_last
  from public.daily_logs d
  where d.follower_id = p_parent_id and d.log_date > current_date - 7 and d.log_date <= current_date;

  -- ⭐ منحنى الوالد على مدى الرحلة كلها: أوّل أسبوع مقابل آخر أسبوع،
  -- بنفس منطق get_parent_curve لكن على نافذة الرحلة لا آخر ٢٨ يوماً.
  select count(*) filter (where kind='erupted' and occurred_on >= coalesce(v_started, current_date)
                                                and occurred_on <  coalesce(v_started, current_date) + 7),
         count(*) filter (where kind='erupted' and occurred_on > current_date - 7),
         count(*) filter (where kind='held')
    into v_erupt_w1, v_erupt_last, v_held_total
  from public.parent_moments
  where parent_id = p_parent_id;
  v_curve_ready := v_held_total > 0 or v_erupt_w1 > 0 or v_erupt_last > 0;

  select array_agg(distinct public.situation_label_ar(s.key))
    into v_sits
  from public.situations s
  where s.child_id = v_child_id and s.status = 'confirmed';

  select array_agg(cp.pattern_label order by cp.evidence_count desc)
    into v_pats
  from public.child_patterns cp
  where cp.child_id = v_child_id and cp.safe_for_record;

  select string_agg(line, v_nl) into v_calms from (
    select '• ' || coalesce(d.step_given, d.seed_text) || ' — نجحت '
           || public.ar_digits((count(*) filter (where d.step_status = 'done'))::text)
           || ' من ' || public.ar_digits(count(*)::text)
      as line
    from public.daily_logs d
    where d.follower_id = p_parent_id
      and coalesce(d.step_given, d.seed_text) is not null
    group by coalesce(d.step_given, d.seed_text)
    order by count(*) filter (where d.step_status = 'done') desc, count(*) desc
    limit 5
  ) t;

  v_lines := array['📖 تقرير رحلتكم الكاملة'];
  v_lines := v_lines || ''::text;
  v_lines := v_lines || ('من ' || to_char(coalesce(v_started, current_date), 'DD/MM') || ' إلى اليوم — '
                          || public.ar_digits(v_days::text) || ' يوماً معاً.')::text;
  v_lines := v_lines || ''::text;
  v_lines := v_lines || ('الهدف الذي بنينا عليه هذه الرحلة: ' || coalesce(v_objective,'') || '.')::text;
  if v_context is not null then
    v_lines := v_lines || ('بدأنا من: ' || v_context || coalesce('، '||v_freq, '') || '.')::text;
  end if;

  v_lines := v_lines || ''::text;
  v_lines := v_lines || '📊 بالأرقام'::text;
  if v_curve_ready then
    -- ⭐ الرقم الرئيسي: كم مرة تماسكتم على مدى الرحلة، لا كم ليلة هدأ الطفل.
    v_lines := v_lines || ('• ' || public.ar_digits(v_held_total::text) || ' مرة أوشكتم فيها ولم تنفجروا.')::text;
    if v_erupt_last < v_erupt_w1 then
      v_lines := v_lines || ('• انفجاراتكم في آخر أسبوع أقل منها في أول أسبوع معنا — تحسّن حقيقي وواضح بالأرقام.')::text;
    elsif v_erupt_last = v_erupt_w1 then
      v_lines := v_lines || ('• تماسككم ثابت من أول أسبوع لآخر أسبوع — لم يتراجع رغم كل التعب.')::text;
    else
      v_lines := v_lines || ('• كانت هناك أسابيع أثقل من غيرها — وهذا طبيعي، النمو لا يمشي بخط مستقيم.')::text;
    end if;
    v_lines := v_lines || ('• وينعكس هذا على ' || v_child || ' أيضاً: ' || public.ar_digits(coalesce(v_nights,0)::text) || ' ليلة سجّلتموها معنا، '
                            || public.ar_digits(coalesce(v_calm,0)::text) || ' منها مرّت بهدوء.')::text;
  else
    -- لا بيانات منحنى — لم يُستخدم زر النجدة ولا سؤال المساء في التطبيق
    -- المصغّر خلال هذه الرحلة. لا نختلق رقماً؛ نروي من الحضور.
    v_lines := v_lines || ('• ' || public.ar_digits(coalesce(v_nights,0)::text) || ' ليلة سجّلتموها معنا، '
                            || public.ar_digits(coalesce(v_calm,0)::text) || ' منها مرّت بهدوء فعلاً.')::text;
    if v_calm_w1 is not null and v_calm_last is not null then
      if v_calm_last > v_calm_w1 then
        v_lines := v_lines || ('• الأسبوع الأخير كان أهدأ من أول أسبوع معنا — تحسّن حقيقي وواضح بالأرقام.')::text;
      elsif v_calm_last = v_calm_w1 then
        v_lines := v_lines || ('• الهدوء ثابت من أول أسبوع لآخر أسبوع — لم يتراجع رغم كل التعب.')::text;
      else
        v_lines := v_lines || ('• كانت هناك أسابيع أصعب من غيرها — وهذا طبيعي، النمو لا يمشي بخط مستقيم.')::text;
      end if;
    end if;
  end if;

  if v_calms is not null then
    v_lines := v_lines || ''::text;
    v_lines := v_lines || '✅ ما نجح معكم فعلاً'::text;
    v_lines := v_lines || v_calms;
  end if;

  if v_pats is not null and array_length(v_pats,1) > 0 then
    v_lines := v_lines || ''::text;
    v_lines := v_lines || '🧩 أنماط لاحظناها معاً'::text;
    v_lines := v_lines || ('• ' || array_to_string(v_pats[1:3], E'\n• '))::text;
  end if;

  if v_sits is not null and array_length(v_sits,1) > 0 then
    v_lines := v_lines || ''::text;
    v_lines := v_lines || ('🔍 اللحظات اللي عرفنا مصدرها بالضبط: ' || array_to_string(v_sits, '، ') || '.')::text;
  end if;

  v_lines := v_lines || ''::text;
  v_lines := v_lines || ('لم نصل بعد بشكل كامل إلى «' || coalesce(v_objective,'') || '» — وهذا ما نقوله لكم بصراحة، لا نزيّنه.')::text;

  v_lines := v_lines || ''::text;
  v_lines := v_lines || '🌿 آدم كان معكم كل يوم — يقترح خطوة مبنية على ما نجح أمس، لا نصيحة عامة، ويتابع كل ليلة بلا كلل.'::text;
  v_lines := v_lines || ('لكن كل ما تحقق فعلياً هو اجتهادكم أنتم — أنتم من طبّق، أنتم من واظب، وأنتم من لم يستسلموا رغم الأيام الصعبة.')::text;

  v_lines := v_lines || ''::text;
  v_lines := v_lines || 'المرافقة الكاملة تنتهي اليوم.'::text;
  v_lines := v_lines || 'وما بنيتموه حتى الآن لا يستحق أن يتوقف هنا.'::text;

  return array_to_string(v_lines, v_nl);
end;
$function$;

-- ------------------------------------------------------------
-- 6. قائمة البوت — «تقدّمكم». نفس المنطق مرة أخرى: منحنى الوالد
--    أولاً حين يوجد، وجهد الوالد مع الطفل (المحاولات، لا نتيجتها)
--    كسطر تالٍ لا الجملة الأولى.
-- ------------------------------------------------------------
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
          || 'كل ما حكيتم أكثر، فهمته أعمق؛ ولما أفهمه أكثر، تصير الخطوة التي أقترحها له هو، لا لأي طفل آخر.' || v_nl || v_nl
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
          || 'كل ما حكيتم أكثر، فهمته أعمق؛ ولما أفهمه أكثر، تصير الخطوة التي أقترحها له هو، لا لأي طفل آخر.' || v_nl || v_nl
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

-- ------------------------------------------------------------
-- 7. لمسات خفيفة أخيرة. سؤال خطوة ٣ في الاستمارة يسأل الآن عن
--    كيف يتعاملون معه، لا ماذا يحدث له. وتوجيه طور «البناء» في
--    compose_journey_step يطلب من الوكيل صراحة خطوة يفعلها
--    الوالد نفسه — كيف يتصرّف أو يتنفّس أو يتكلّم — لا وصفاً
--    لسلوك مطلوب من الطفل وحده.
-- ------------------------------------------------------------
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
              '🎯 لنبنِ خطة تخصّ ' || v_who || ' وحده — لا خطة عامة.' || v_nl ||
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
      '📋 خطتكم جاهزة:' || v_nl ||
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
        'اقترح خطوة واحدة صغيرة'
        || coalesce(' مبنية على ما نفع سابقاً: «' || v_working || '»', '')
        || '، قابلة للتجربة في أسوأ ليلة. الخطوة شيء يفعله الوالد نفسه — كيف يتصرّف أو يتنفّس أو يتكلّم — لا وصف لسلوك مطلوب من '
        || coalesce(v_child, 'طفلهم') || ' وحده. مرتبطة بـ ' || coalesce(v_child, 'طفلهم') || ' و' || coalesce(v_sit, 'الموقف') || '. '
        || 'لا تكرّر خطوة سبق أن أعطيتها.'
    end;
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

commit;
