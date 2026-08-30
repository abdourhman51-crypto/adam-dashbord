begin;

-- ============================================================
-- القائمة الجانبية كانت مصدر تناقض بذاته
--
-- بند ١ — أزرار ميتة فعلياً: «عائلة آدم» و«المجاني مقابل
-- المرافقة الكاملة» في درج القائمة (TopBar.tsx) كانا يعيدان 404.
-- السبب: get_conversation_moment() تبحث عن صفّ في
-- conversation_moments أولاً، وترجع found:false فوراً إن لم تجده
-- — قبل أن تصل إطلاقاً إلى compose_menu_body(). menu_family كان
-- له فرع كامل جاهز في compose_menu_body لا يُستدعى أبداً لغياب
-- الصفّ، ومنو_pricing_diff لم يكن له فرع من الأساس.
--
-- بند ٢ — النصوص الباقية (ما هو آدم، كيف يشتغل، ما الذي يميّزه)
-- ظلّت بكاملها موجّهة نحو الطفل («مرافق يومي لكم أنتم، مع طفلكم
-- أنتم بالذات»، «يعرف طفلكم بالاسم») رغم أن الرحلة المدفوعة نفسها
-- تحوّلت. القائمة الجانبية هي أول مكان يقرأ فيه والدٌ فضولي «ما
-- هذا التطبيق» — وكانت تصف منتجاً مختلفاً عمّا يستخدمه فعلاً.
-- ============================================================


-- ------------------------------------------------------------
-- ١. صفّان جذعيان (composed، بلا body_ar مخزَّن) حتى يجد
--    get_conversation_moment صفّاً فيتابع إلى compose_menu_body.
-- ------------------------------------------------------------
insert into public.conversation_moments (key, category, tier, body_ar, buttons, buttons_forbidden, max_lines, note)
values
  ('menu_family', 'reference', 'composed', null,
   '[{"cb":"other","label":"💬 عندي سؤال"}]'::jsonb, false, 10,
   'Sidebar entry — was unreachable: compose_menu_body had a working branch but no row existed for get_conversation_moment to find first.'),
  ('menu_pricing_diff', 'reference', 'composed', null,
   '[{"cb":"menu_journey","label":"🎯 وما هي المرافقة الكاملة؟"},{"cb":"other","label":"💬 عندي سؤال"}]'::jsonb, false, 20,
   'Sidebar entry — was a dead button: no row and no compose_menu_body branch existed at all.')
on conflict (key) do nothing;


-- ------------------------------------------------------------
-- ٢. النصوص الحالية، معاد صياغتها + فرع جديد للمقارنة.
-- ------------------------------------------------------------
update public.conversation_moments set body_ar =
'🌿 ما هو آدم؟' || chr(10) || chr(10) ||
'مرافق يومي لكم أنتم — يساعدكم تتصرّفوا بشكل مختلف في أصعب لحظاتكم مع طفلكم.' || chr(10) ||
'تحكون له ما أتعبكم اليوم، فيعطيكم شيئاً واحداً صغيراً تجرّبونه — مبنياً على بيتكم بالذات، لا نصيحة عامّة.' || chr(10) ||
'وكل يوم يعرف بيتكم أكثر، فيصير ما يقوله أقرب.' || chr(10) || chr(10) ||
'🎯 النتيجة' || chr(10) ||
'تتماسكون أكثر مما تنفجرون، لأنكم تعرفون ما الذي يستفزّكم قبل أن يستفزّكم.' || chr(10) ||
'ويهدأ البيت معكم.'
where key = 'menu_faq';

update public.conversation_moments set body_ar =
'⚙️ كيف يشتغل — أربع خطوات' || chr(10) || chr(10) ||
'1️⃣ تحكون ما حدث اليوم مع طفلكم. سطر واحد يكفي.' || chr(10) ||
'2️⃣ يعطيكم شيئاً صغيراً تجرّبونه في اليوم نفسه — مربوطاً بموقفكم أنتم.' || chr(10) ||
'3️⃣ مساءً يسألكم: هل تغيّر شيء؟ وجوابكم ضغطة زر.' || chr(10) ||
'4️⃣ بعد ثلاث مرات يريكم ما لم تروه: الموقف الذي يستفزّكم أكثر من غيره، ومتى يصعب عليكم التماسك فيه.' || chr(10) || chr(10) ||
'⏱️ وكم يأخذ منكم؟' || chr(10) ||
'دقيقة في اليوم. ولا يُطلب منكم شيء في اليوم الذي لا تحتملونه.' || chr(10) || chr(10) ||
'📌 وحدودي واضحة: كلّ ما يخصّ المرافقة الكاملة — التفاصيل والدفع — يتولّاه فريق آدم، لا أنا.'
where key = 'menu_how';

update public.conversation_moments set body_ar =
'✨ ما الذي يميّز آدم' || chr(10) || chr(10) ||
'جرّبتم قبله فيديوهات ومقالات ونصائح من كل جهة، ولم ينفع أكثرها.' || chr(10) ||
'والسبب ليس أنها رديئة — بل أنها عن «الآباء» و«الأطفال» عموماً، لا عن بيتكم بالذات.' || chr(10) || chr(10) ||
'🧭 يعرف بيتكم بالتفصيل — اسم طفلكم، أصعب ساعة في يومه، وما الذي يستفزّكم فيها' || chr(10) ||
'🧠 يتذكّر كلّ ما جرّبتموه، فلا تشرحون من البداية في كل مرّة' || chr(10) ||
'🔁 يبني خطوة اليوم على نتيجة أمس، فلا تبدؤون من الصفر أبداً' || chr(10) ||
'📊 يعدّ كم مرة تماسكتم وكم مرة انفجرتم — لا أحد كان يعدّ هذا قبله' || chr(10) ||
'🪶 خطوة واحدة صغيرة، لا محاضرة — صغيرة بما يكفي لتُجرَّب في أسوأ يوم' || chr(10) ||
'🌙 سؤال واحد في المساء، فيتعلّم من جوابكم ويقترب أكثر' || chr(10) ||
'🤍 يرى تعبكم أنتم، فحين تكونون منهكين يخفّف ولا يطلب' || chr(10) ||
'🤐 ولا يرسل نصيحة عامّة أبداً — إن لم يكن ما سيقوله مبنيّاً على بيتكم، يصمت' || chr(10) ||
'🔒 وما تقولونه يبقى لكم وحدكم — تطلبون محوه، فيُمحى كلّه' || chr(10) || chr(10) ||
'والفرق في جملة واحدة:' || chr(10) ||
'النصيحة العامّة تصلح لكل بيت، ولهذا لا تصلح لبيتكم بالذات.'
where key = 'menu_why';

update public.conversation_moments set body_ar =
'🔒 خصوصيتكم' || chr(10) || chr(10) ||
'كل ما تكتبونه هنا يبقى بينكم وبيني وحدنا. لا يراه أحد غيري، ولا يخرج إلى أي مكان.' || chr(10) ||
'أستعمله لشيء واحد فقط: أن يكون ما أقوله لكم غداً أقرب لبيتكم من كلام اليوم.' || chr(10) || chr(10) ||
'ويمكنكم محو كل شيء متى شئتم — بلا أسئلة عن السبب.'
where key = 'menu_privacy';
-- ⭐ لمسة واحدة فقط هنا: «أقرب لطفلكم» → «أقرب لبيتكم». الباقي دقيق كما هو.


-- ------------------------------------------------------------
-- ٣. الفرع الذي كان مفقوداً كلياً: menu_pricing_diff. مبني بنفس
--    قانون الكلام — لا سعر بالأرقام، لا كلمة «خطة» أو «اشتراك».
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

  if p_key = 'menu_pricing_diff' then
    return '⚖️ المجاني مقابل المرافقة الكاملة' || v_nl || v_nl ||
           '🌿 المجاني — ويبقى مجانياً دائماً' || v_nl ||
           'خطوة يومية مبنية على حكيكم لي، وسؤال مساء واحد، وزر النجدة وقت الانفجار.' || v_nl || v_nl ||
           '🎯 المرافقة الكاملة — لهدف واحد محدَّد' || v_nl ||
           'تتّفقون معي على شيء واحد بالذات تريدون تغييره في كيف تتصرّفون، لمدّة 29 يوماً.' || v_nl ||
           'وتُفتح لكم ✨ بصائر آدم: تتابعون فيها كل أسبوع بالأرقام — هل تتحسّن سيطرتكم فعلاً؟' || v_nl ||
           'وإن لم نصل للهدف في المدّة، أُكمل معكم مجاناً حتى نصل.' || v_nl || v_nl ||
           'الفرق ليس في الاهتمام — بل في أن المرافقة الكاملة مبنية حول هدف واحد نتّفق عليه معاً، لا محادثة مفتوحة بلا وجهة.';
  end if;

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

commit;
