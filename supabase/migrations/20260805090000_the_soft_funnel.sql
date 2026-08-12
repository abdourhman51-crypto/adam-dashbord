begin;

-- ============================================================
-- قمع ناعم: من «ما هو آدم؟» إلى رابط الدفع، خطوة تكسب التي بعدها.
--
-- الحالة قبل هذا: /faq جدارٌ واحد من أربعة وثلاثين سطراً. وثيقة،
-- لا رحلة. الوالد يقرأ كل شيء دفعةً واحدة أو لا يقرأ شيئاً — وفي
-- الحالتين لا يصل إلى العرض إلا بالصدفة.
--
-- الآن أربع محطّات، كلٌّ منها قصيرة، وتنتهي بزرّ يفتح التالية:
--
--   ١. 🌿 ما هو آدم؟          الخطّاف + النتيجة في ثلاثة أسطر
--   ٢. ⚙️ كيف يشتغل؟           الطريقة والوقت المطلوب
--   ٣. ✨ ما الذي يميّزه؟       التخصيص — قلب البيع
--   ٤. 🎯 المرافقة والسعر      العرض ورابط فريق آدم
--
-- ولماذا التخصيص هو القلب: الوالد العربي جرّب قبلنا فيديوهات
-- ومقالات ونصائح من كل جهة، ولم ينفع أكثرها. والسبب ليس أنها
-- رديئة — بل أنها عن «الأطفال» لا عن طفله. هذه هي الجملة التي
-- تبيع، وهي أيضاً الشيء الوحيد الذي لا يستطيع فيديو ولا مساعد
-- عامّ أن يدّعيه: أن يعرف الاسم، ويتذكّر ما جُرِّب، ويعدّ ما يتكرّر.
--
-- وكل ميزة أدناه صحيحة وقابلة للتحقّق مما هو مبنيّ فعلاً:
--   الاسم والعمر وأصعب لحظة  →  children · situations
--   يتذكّر ما جُرِّب            →  daily_logs.step_given/step_status
--   يعدّ ما يتكرّر            →  «هذه ثالث مرة» من get_harvest_prompt
--   يسأل عن النتيجة          →  الحصاد المسائي
-- لا مبالغة، ولا وعد بما لا نملك.
--
-- ملاحظة توجيه: كل مفتاح جديد يبدأ بـ menu_ ليُوجَّه من قاعدة
-- Router العامّة بلا تعديل كود — نفس الدرس الذي كلّفنا سبعة أزرار
-- ميّتة أمس.
-- ============================================================


-- ------------------------------------------------------------
-- ١. الخطّاف. أقصر رسالة في القمع، وأهمّها: تقول ما هو، ولمن،
--    وما النتيجة — ثم تترك الوالد يختار عمقه.
-- ------------------------------------------------------------
update public.conversation_moments set
  category = 'reference', max_lines = 10,
  body_ar =
    '🌿 **ما هو آدم؟**' || chr(10) || chr(10) ||
    'مرافق يومي لكم أنتم، مع طفلكم أنتم بالذات.' || chr(10) ||
    'تحكون له ما تعبتم منه اليوم، فيعطيكم شيئاً واحداً صغيراً تجرّبونه — مبنياً على طفلكم، لا نصيحة عامّة.' || chr(10) ||
    'وكل يوم يعرفه أكثر، فيصير ما يقوله أقرب.' || chr(10) || chr(10) ||
    '🎯 **النتيجة:** المعارك تقلّ، لأنكم تعرفون ما الذي يشعلها قبل أن تشتعل.' || chr(10) ||
    'ويهدأ البيت، وتهدؤون أنتم معه.',
  buttons = '[{"label":"⚙️ كيف يشتغل بالضبط؟","cb":"menu_how"},
              {"label":"✨ وما الذي يميّزه؟","cb":"menu_why"},
              {"label":"💬 أبدأ الآن","cb":"other"}]'::jsonb
where key = 'menu_faq';


-- ------------------------------------------------------------
-- ٢. الطريقة. الاعتراض الصامت هنا هو الوقت، فيُجاب قبل أن يُسأل.
-- ------------------------------------------------------------
insert into public.conversation_moments
  (key, category, tier, body_ar, buttons, max_lines, requires_commerce, note)
values
  ('menu_how', 'reference', 'fixed',
   '⚙️ **كيف يشتغل — أربع خطوات**' || chr(10) || chr(10) ||
   '1️⃣ تحكون ما حدث اليوم مع طفلكم. سطر واحد يكفي.' || chr(10) ||
   '2️⃣ يعطيكم شيئاً صغيراً تجرّبونه في اليوم نفسه — مربوطاً بموقفكم أنتم.' || chr(10) ||
   '3️⃣ مساءً يسألكم: هل تغيّر شيء؟ وجوابكم ضغطة زر.' || chr(10) ||
   '4️⃣ بعد ثلاث مرات يريكم ما لم تروه: الموقف الذي يتكرّر في بيتكم، وما الذي يهدّئ طفلكم فيه.' || chr(10) || chr(10) ||
   '⏱️ **وكم يأخذ منكم؟** دقيقة في اليوم.' || chr(10) ||
   'ولا يُطلب منكم شيء في اليوم الذي لا تحتملونه.',
   '[{"label":"✨ وما الذي يميّزه؟","cb":"menu_why"},
     {"label":"💬 أبدأ الآن","cb":"other"}]'::jsonb,
   12, false,
   'Funnel step 2. The silent objection at this point is time, so it is answered before it is asked.'),

-- ------------------------------------------------------------
-- ٣. التمييز. قلب البيع كلّه، ومبناه على ما جرّبه الوالد وفشل.
-- ------------------------------------------------------------
  ('menu_why', 'reference', 'fixed',
   '✨ **ما الذي يميّز آدم**' || chr(10) || chr(10) ||
   'جرّبتم قبل هذا فيديوهات ومقالات ونصائح من كل جهة، ولم ينفع أكثرها.' || chr(10) ||
   'والسبب ليس أنها رديئة — بل أنها عن «الأطفال»، لا عن طفلكم.' || chr(10) || chr(10) ||
   '✅ **يعرف طفلكم بالاسم** — عمره، وأصعب لحظة عنده، وما الذي يهدّئه.' || chr(10) ||
   '✅ **يتذكّر كل ما جرّبتموه** — ما نفع وما لم ينفع، فلا تعيدون الشرح من البداية.' || chr(10) ||
   '✅ **يعدّ ما يتكرّر** — «هذه ثالث مرة هذا الأسبوع». لا أحد كان يعدّ قبله.' || chr(10) ||
   '✅ **خطوة واحدة، لا محاضرة** — صغيرة بما يكفي لتُجرَّب في أسوأ يوم.' || chr(10) ||
   '✅ **يسأل عن النتيجة** — فيتعلّم من جوابكم ويقترب أكثر.' || chr(10) ||
   '✅ **يكتب بلغتكم** — بلا مصطلحات ولا كلام أكاديمي.' || chr(10) || chr(10) ||
   'والفرق في جملة واحدة:' || chr(10) ||
   'النصيحة العامّة تصلح لكل الأطفال، ولهذا لا تصلح لطفلكم بالذات.',
   '[{"label":"🎯 وما هي المرافقة الكاملة؟","cb":"menu_journey"},
     {"label":"💬 أبدأ الآن","cb":"other"}]'::jsonb,
   16, false,
   'Funnel step 3, and the whole sale. Built on what the parent already tried and failed with. Every claim maps to something actually built: name/age/situation from children+situations, what was tried from daily_logs, the counting from get_harvest_prompt, the evening question from the harvest. No claim we cannot keep.')
on conflict (key) do update
  set body_ar = excluded.body_ar, buttons = excluded.buttons,
      category = excluded.category, tier = excluded.tier,
      max_lines = excluded.max_lines, note = excluded.note;


-- ------------------------------------------------------------
-- المساعدة المختصرة تدخل القمع من أوّله بدل أن تكون نسخة ثالثة.
-- ------------------------------------------------------------
update public.conversation_moments set
  buttons = '[{"label":"⚙️ كيف يشتغل بالضبط؟","cb":"menu_how"},
              {"label":"✨ وما الذي يميّزه؟","cb":"menu_why"},
              {"label":"💬 أبدأ الآن","cb":"other"}]'::jsonb
where key = 'menu_help';


-- ------------------------------------------------------------
-- أول رسالة يراها الوالد لم يكن فيها أي مدخل. الآن فيها بابان.
-- ------------------------------------------------------------
update public.conversation_moments set
  buttons = '[{"label":"🌿 ما هو آدم؟","cb":"menu_faq"},
              {"label":"💬 عندي موقف الآن","cb":"other"}]'::jsonb
where key = 'first_contact';


-- ------------------------------------------------------------
-- ٤. العرض. آخر محطّة، وفيها وحدها يُنطق السعر ويظهر الرابط.
-- ------------------------------------------------------------
create or replace function public.get_conversation_moment(
  p_key       text,
  p_parent_id uuid default null)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  m         public.conversation_moments%rowtype;
  v_cs      jsonb;
  v_body    text;
  v_buttons jsonb;
  v_nl      text := chr(10);
begin
  select * into m from public.conversation_moments where key = p_key;
  if not found then
    return jsonb_build_object('found', false, 'key', p_key);
  end if;

  if m.requires_commerce and p_parent_id is not null
     and not coalesce(public.commerce_allowed(p_parent_id), true) then
    return jsonb_build_object('found', true, 'key', p_key, 'allowed', false,
                              'reason', 'commerce_blocked');
  end if;

  v_body    := m.body_ar;
  v_buttons := m.buttons;

  if p_key = 'menu_journey' then
    v_cs := public.country_state(p_parent_id);

    if (v_cs->>'state') = 'supported' then
      -- The price is read from supported_countries, per country, at read
      -- time. It is stored in exactly one place and spoken in exactly one.
      v_body :=
        '🌿 **المجاني يبقى مجانياً**' || v_nl ||
        'الحديث، والفهم، وشيء صغير كل يوم. لا ينقص منه شيء أبداً.' || v_nl || v_nl ||
        '🎯 **وما هي المرافقة إذن؟**' || v_nl ||
        'المجاني يجعل الموقف أخفّ عليكم حين يقع.' || v_nl ||
        'والمرافقة تعمل على ألّا يقع أصلاً.' || v_nl || v_nl ||
        'تختارون هدفاً واحداً — نوم بلا معركة، أو صباح أهدأ، أو عناد أقلّ —' || v_nl ||
        'ونمشي إليه يوماً بيوم حتى نصل.' || v_nl || v_nl ||
        '✅ هدف واحد تسمّونه أنتم، لا نختاره لكم' || v_nl ||
        '✅ خطوة كل يوم مبنية على طفلكم وما نفع معه' || v_nl ||
        '✅ نعرف معاً متى وصلنا — بما نراه، لا بالإحساس' || v_nl ||
        '✅ وإن لم يصلح، أقولها لكم بصراحة. هذا وعدي في الحالتين.' || v_nl || v_nl ||
        '💰 **الرحلة الواحدة عندكم:** ' || (v_cs->>'price') || v_nl ||
        '👈 فريق آدم يشرح التفاصيل وطرق الدفع:' || v_nl ||
        'https://t.me/Abdouleg';
      v_buttons := '[]'::jsonb;

    elsif (v_cs->>'state') = 'unknown' then
      -- We do not know where they are. Saying "not yet in your country"
      -- here would be a sentence we cannot stand behind. Ask instead --
      -- and the answer also unblocks the daily rhythm, which needs a
      -- local clock before it can write at an honest hour.
      v_body :=
        '🎯 **المرافقة الكاملة**' || v_nl || v_nl ||
        'تختلف من بلد لآخر — السعر وطريقة الدفع محليّان.' || v_nl || v_nl ||
        'من أي بلد أنتم؟';
      v_buttons := jsonb_build_array(
        jsonb_build_object('label','الجزائر',  'cb','set_country_DZ'),
        jsonb_build_object('label','مصر',     'cb','set_country_EG'),
        jsonb_build_object('label','المغرب',   'cb','set_country_MA'),
        jsonb_build_object('label','بلد آخر', 'cb','set_country_OTHER'),
        jsonb_build_object('label','عندي موقف آخر', 'cb','other'));

    else
      v_body :=
        '🌿 **آدم يرافقكم بالكامل، كما يرافق الجميع.**' || v_nl ||
        'كل ما بيننا الآن يبقى كما هو، دون نقص.' || v_nl || v_nl ||
        'والرحلات المدفوعة لم تصل بلدكم بعد، لسبب واحد:' || v_nl ||
        'لا تتوفّر بعد طريقة دفع محلية نثق بها ونستطيع دعمها كما ينبغي.' || v_nl ||
        'وحين تتوفّر، تصلكم رسالة.';
      v_buttons := '[{"label":"أخبروني حين تصل","cb":"waitlist_join"},{"label":"عندي موقف آخر","cb":"other"}]'::jsonb;
    end if;

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
-- تأكيد البلد: آخر خطوة قبل الرابط، فتحمل العرض لا مجرّد إيصال.
-- ------------------------------------------------------------
create or replace function public.compose_menu_body(p_key text, p_parent_id uuid)
returns text
language plpgsql
stable
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  v_nl text := chr(10); v_country text; v_today date;
  v_child uuid; v_name text; v_age text; v_sit text; v_pat text;
  v_e jsonb; v_tried integer; v_prev integer; v_calm integer; v_ever integer;
  v_cs jsonb; v_who text;
  v_lines text[] := '{}';
begin
  if p_parent_id is null then return null; end if;

  select upper(btrim(f.country)) into v_country
  from public.followers f where f.id = p_parent_id;
  if not found then return null; end if;

  if p_key = 'country_recorded' then
    v_cs := public.country_state(p_parent_id);
    if (v_cs->>'state') = 'supported' then
      return '✅ سجّلنا: ' || coalesce(v_cs->>'name_ar', 'بلدكم') || '.' || v_nl || v_nl
          || '🌿 كل ما بيننا الآن يبقى مجانياً، دائماً.' || v_nl || v_nl
          || '🎯 وإن أردتم يوماً أن نعمل على هدف واحد حتى يتغيّر — نوم بلا معركة، أو عناد أقلّ —' || v_nl
          || 'نمشي إليه يوماً بيوم حتى نصل، أو حتى نعرف معاً أنه لا يصلح وأقولها لكم بصراحة.' || v_nl || v_nl
          || '💰 **الرحلة الواحدة عندكم:** ' || (v_cs->>'price') || v_nl
          || '👈 فريق آدم يشرح التفاصيل وطرق الدفع:' || v_nl
          || 'https://t.me/Abdouleg';
    elsif (v_cs->>'state') = 'unknown' then
      return 'لم أتعرّف على البلد.' || v_nl
          || 'لا بأس — كل ما بيننا يبقى كما هو، دون نقص.';
    else
      return '✅ سجّلنا بلدكم.' || v_nl || v_nl
          || 'وكل ما بيننا يبقى كما هو تماماً، مجاناً.' || v_nl || v_nl
          || 'أمّا الرحلات المدفوعة فلم تصل إليه بعد، لسبب واحد:' || v_nl
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

  if p_key = 'menu_child' then
    if v_name is null then
      return '👦 ما أعرفه عن طفلكم' || v_nl || v_nl
          || 'لا شيء بعد — لم تحكوا لي عنه.' || v_nl || v_nl
          || 'اكتبوا اسمه وما أكثر ما يتعبكم معه هذه الأيام،' || v_nl
          || 'ومن هناك أبدأ أعرفه: ما الذي يثيره، وما الذي يهدّئه.';
    end if;

    select public.situation_label_ar(s.key) into v_sit
    from public.situations s
    where s.child_id = v_child and s.status in ('candidate','confirmed')
      and s.key is not null and s.key <> 'other'
    order by (s.status = 'confirmed') desc, s.evidence_count desc limit 1;

    select cp.pattern_label into v_pat
    from public.child_patterns cp
    where cp.child_id = v_child and cp.safe_for_record
    order by cp.evidence_count desc limit 1;

    v_lines := array['👦 ما أعرفه عن ' || v_name || coalesce(' · ' || v_age, '')];
    v_lines := v_lines || ''::text;
    v_lines := v_lines || 'هذا ما فهمته عنه من كلامكم حتى الآن:'::text;
    if v_sit is not null then
      v_lines := v_lines || ('• أصعب لحظة معه عادةً: ' || v_sit || '.')::text;
    end if;
    if v_pat is not null then
      v_lines := v_lines || ('• ' || v_pat)::text;
    end if;
    if v_sit is null and v_pat is null then
      v_lines := v_lines || 'لم يتّضح بعد ما الذي يتكرّر معه.'::text;
      v_lines := v_lines || ''::text;
      v_lines := v_lines || ('احكوا لي عن يومكم مع ' || v_name || '، وكلما حكيتم عرفته أكثر.')::text;
    else
      v_lines := v_lines || ''::text;
      v_lines := v_lines || 'وكلما حكيتم أكثر، صار ما أقترحه أقرب له وحده.'::text;
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

    if v_ever = 0 then
      return '📊 رحلتكم مع ' || v_who || v_nl || v_nl
          || 'لم نجرّب شيئاً معاً بعد.' || v_nl || v_nl
          || 'كيف تمشي الأمور: تحكون لي ما تعبتم منه اليوم، فأعطيكم شيئاً واحداً صغيراً تجرّبونه،' || v_nl
          || 'ثم أسألكم مساءً: هل تغيّر شيء؟' || v_nl || v_nl
          || 'وبعد ثلاث محاولات يصير عندي ما يكفي لأريكم الموقف الذي يتكرّر في بيتكم بالذات،' || v_nl
          || 'وما الذي يهدّئ ' || v_who || ' فيه.' || v_nl || v_nl
          || 'نبدأ الآن: احكوا لي ما حدث معه اليوم.';
    elsif v_ever < 3 then
      return '📊 رحلتكم مع ' || v_who || v_nl || v_nl
          || 'جرّبتم معه ' || public.ar_occasions(v_ever) || ' حتى الآن.' || v_nl || v_nl
          || 'بعد ثلاث محاولات يصير عندي ما يكفي لأريكم الموقف الذي يتكرّر عندكم بالذات،' || v_nl
          || 'وما الذي يهدّئ ' || v_who || ' فيه — وهناك يبدأ الفرق الحقيقي.' || v_nl || v_nl
          || 'احكوا لي عن يومكم معه، ونكمل.';
    end if;

    v_lines := array['📊 رحلتكم مع ' || v_who];
    v_lines := v_lines || ''::text;
    v_lines := v_lines || ('هذا الأسبوع: جرّبتم ' || public.ar_occasions(v_tried) || ' مع ' || v_who || '.')::text;

    if v_calm > 0 then
      v_lines := v_lines || (case
        when v_calm = 1 then 'واحدة منها مرّت بهدوء.'
        when v_calm = 2 then 'اثنتان منها مرّتا بهدوء.'
        else public.ar_digits(v_calm::text) || ' منها مرّت بهدوء.' end)::text;
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
