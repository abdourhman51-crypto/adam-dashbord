begin;

-- ============================================================
-- كل رسالة تُقرأ وحدها. لا شيء يفترض أن الوالد يعرف آدم.
--
-- مراجعة المؤسس الثانية، على جلسة حقيقية. لم تكن ملاحظة على
-- جملة، بل على الأساس كلّه — وهي صحيحة:
--
--   /progress  →  «جرّبتم مرة واحدة حتى الآن.
--                   نحتاج ثلاثاً حتى نرى ما يتكرّر.»
--                 جرّبنا ماذا؟ وما الذي يتكرّر؟
--
--   /settings  →  «متى يصلك الكلام، ومتى نصمت — كما تحب.»
--                 أيّ كلام؟ ضغط الوالد «الإعدادات» فوصلته جملة
--                 شاعرية لا تقول ما الذي يضبطه.
--
-- العلّة واحدة في كل موضع: **النصوص مكتوبة من داخل المنتج.**
-- كاتبها يعرف ما هي «المحاولة» وما هو «المتكرّر»، فيكتب الشذرة
-- ويظنّها جملة. والوالد الذي لا يعرف شيئاً يقرأ لغزاً.
--
-- والاختبار الذي تمرّ به كل جملة من اليوم:
--   هل يقول الوالد «آه، فهمت» — أم «وش هذا؟»
--
-- القاعدة التي طُبِّقت على كل سطح
--
--   ١. كل رسالة تُقرأ وحدها، ولا تفترض ذاكرة ولا معرفة سابقة.
--   ٢. ترتيب ثابت: ما هذا؟ ← ماذا تستفيدون؟ ← ماذا تفعلون الآن؟
--   ٣. تُباع النتيجة لا الآلية: «بيت أهدأ» لا «نسجّل النتائج».
--   ٤. اسم الطفل حيثما أمكن — المحسوس يقتل الإبهام.
--   ٥. لا رقم بلا معناه: «جرّبتم ثلاثاً» وحدها لا تعني شيئاً؛
--      يُقال ما الذي يفتحه الرقم.
--
-- تغيير الفئة إلى reference لأربعة أسطح (menu_child ·
-- menu_progress · menu_settings · menu_privacy): chk_line_budget
-- يحصر فئة menu في ثلاثة أسطر، وهي أسطح مرجعية بطبيعتها — يقرؤها
-- الوالد ليفهم حالته، لا ليتلقّى لمسة. الثلاثة أسطر هي سبب
-- الشذرات أصلاً.
-- ============================================================


-- ------------------------------------------------------------
-- الإعدادات: قال «متى يصلك الكلام» ولم يقل ما هو الكلام.
-- ------------------------------------------------------------
update public.conversation_moments set
  category = 'reference', max_lines = 6,
  body_ar = '⚙️ الإعدادات' || chr(10) || chr(10) ||
            'أرسل لكم رسالة واحدة في اليوم، لا أكثر: أسألكم فيها كيف مرّ اليوم مع طفلكم،' || chr(10) ||
            'حتى نعرف معاً ما الذي ينفع معه وما لا ينفع.' || chr(10) || chr(10) ||
            'يمكنكم تغيير وقتها، أو إيقافها تماماً — وفي الحالتين يبقى الحديث بيننا مفتوحاً متى شئتم.',
  buttons = '[{"label":"غيّروا وقت الرسالة","cb":"quiet_hours"},
              {"label":"أوقفوا الرسالة اليومية","cb":"pause"},
              {"label":"عندي سؤال آخر","cb":"other"}]'::jsonb
where key = 'menu_settings';


-- ------------------------------------------------------------
-- الخصوصية: كانت صحيحة لكنها باردة ومختصرة إلى حدّ الغموض.
-- ------------------------------------------------------------
update public.conversation_moments set
  category = 'reference', max_lines = 6,
  body_ar = '🔒 خصوصيتكم' || chr(10) || chr(10) ||
            'كل ما تكتبونه هنا يبقى بينكم وبيني وحدنا. لا يراه أحد غيري، ولا يخرج إلى أي مكان.' || chr(10) ||
            'أستعمله لشيء واحد فقط: أن يكون ما أقوله لكم غداً أقرب لطفلكم من كلام اليوم.' || chr(10) || chr(10) ||
            'ويمكنكم محو كل شيء في أي لحظة، بضغطة واحدة وبلا أسئلة.',
  buttons = '[{"label":"امحوا كل ما قلته","cb":"erase"},
              {"label":"عندي سؤال آخر","cb":"other"}]'::jsonb
where key = 'menu_privacy';


-- ------------------------------------------------------------
-- رفع السقف للسطحين المركّبين حتى تتّسع الجملة الكاملة.
-- ------------------------------------------------------------
update public.conversation_moments set category = 'reference', max_lines = 10
where key in ('menu_child', 'menu_progress');


-- ------------------------------------------------------------
-- الأسئلة الشائعة: كانت تشرح الآلية وتنسى النتيجة.
-- الوالد لا يشتري «مرافقاً يومياً» — يشتري بيتاً أهدأ، وطفلاً
-- يفهمه، وعناداً أقلّ. تُباع النتيجة أولاً، والآلية دليلاً عليها.
-- ------------------------------------------------------------
update public.conversation_moments set
  max_lines = 32,
  body_ar =
    '**ما هو آدم؟**' || chr(10) ||
    'شخص تحكون له كل يوم عمّا يتعبكم مع طفلكم، فيعطيكم شيئاً واحداً صغيراً تجرّبونه في نفس اليوم — ثم يسألكم مساءً: هل تغيّر شيء؟' || chr(10) ||
    'وبعد أيام قليلة يصير يعرف طفلكم: ما الذي يثيره، وما الذي يهدّئه.' || chr(10) || chr(10) ||
    '**وما الذي سيتغيّر عندي؟**' || chr(10) ||
    'المعارك تقلّ لأنكم تعرفون ما الذي يشعلها قبل أن تشتعل.' || chr(10) ||
    'وتفهمون لماذا يتصرّف طفلكم هكذا — فيهدأ البيت، وتهدؤون أنتم معه.' || chr(10) ||
    'لا وعد بطفل مثالي. الوعد أن تتوقّف القصة نفسها عن التكرار كل يوم.' || chr(10) || chr(10) ||
    '**ولماذا آدم بالذات؟**' || chr(10) ||
    'لأن ما يقوله لا يصلح لطفل غير طفلكم.' || chr(10) ||
    'الكتاب لا يعرف أن هذه ثالث مرة يتكرّر فيها الموقف عندكم هذا الأسبوع — وآدم يعرف، لأنه كان يعدّ.' || chr(10) || chr(10) ||
    '**كيف أبدأ؟**' || chr(10) ||
    'اكتبوا ما يتعبكم مع طفلكم الآن، بكلماتكم. لا إعداد ولا أسئلة قبلها.' || chr(10) || chr(10) ||
    '**هل هو مجاني؟**' || chr(10) ||
    'نعم. الحديث، والفهم، والشيء الصغير كل يوم — مجاناً، دائماً، ولا ينقص منه شيء أبداً.' || chr(10) || chr(10) ||
    '**وما الفرق بين المجاني والمرافقة؟**' || chr(10) ||
    'المجاني يجعل الموقف أخفّ عليكم حين يقع.' || chr(10) ||
    'والمرافقة تعمل على ألّا يقع أصلاً: تختارون هدفاً واحداً — نوم بلا معركة، أو صباح أهدأ، أو عناد أقلّ —' || chr(10) ||
    'ونمشي إليه يوماً بيوم حتى نصل، أو حتى نعرف معاً أنه لا يصلح، وأقولها لكم بصراحة.' || chr(10) || chr(10) ||
    '**ماذا لو لم ينفع ما جرّبناه؟**' || chr(10) ||
    'نجرّب زاوية أخرى غداً. المحاولة نفسها تغيّر شيئاً، ولا شيء عليكم فيها.' || chr(10) || chr(10) ||
    '**هل يمكن إيقاف الرسائل؟**' || chr(10) ||
    'نعم، متى شئتم من الإعدادات، ويبقى الحديث مفتوحاً كما هو.' || chr(10) || chr(10) ||
    '**ماذا يحدث لما أقوله؟**' || chr(10) ||
    'يبقى بينكم وبيني وحدنا، ويمكن محوه كلّه متى شئتم دون أسئلة.'
where key = 'menu_faq';


-- ------------------------------------------------------------
-- «ما هو آدم؟» المختصرة — نفس المنطق، بثلاثة أسطر.
-- ------------------------------------------------------------
update public.conversation_moments set
  category = 'reference', max_lines = 6,
  body_ar = 'أنا آدم. تحكون لي كل يوم عمّا يتعبكم مع طفلكم، فأعطيكم شيئاً واحداً صغيراً تجرّبونه في نفس اليوم،' || chr(10) ||
            'ثم أسألكم مساءً: هل تغيّر شيء؟' || chr(10) || chr(10) ||
            'وكلما حكيتم أكثر، عرفت طفلكم أكثر — ما الذي يثيره وما الذي يهدّئه —' || chr(10) ||
            'فتقلّ المعارك لأنكم تعرفون ما يشعلها قبل أن تشتعل.',
  buttons = '[{"label":"كيف أبدأ؟","cb":"help_start"},
              {"label":"عندي سؤال آخر","cb":"other"}]'::jsonb
where key = 'menu_help';


-- ------------------------------------------------------------
-- compose_menu_body — الأسطح المركّبة.
-- كل فرع صار يقول: ما هذا السطح، وما الذي يفتحه ما فعلتموه،
-- وماذا تفعلون الآن. والرقم لم يعد يُقال وحده.
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

  -- ---- the answer after a parent names their country -----------
  if p_key = 'country_recorded' then
    v_cs := public.country_state(p_parent_id);
    if (v_cs->>'state') = 'supported' then
      return 'سجّلنا: ' || coalesce(v_cs->>'name_ar', 'بلدكم') || '.' || v_nl || v_nl
          || 'كل ما بيننا الآن يبقى مجانياً، دائماً.' || v_nl || v_nl
          || 'وإن أردتم يوماً أن نعمل على هدف واحد حتى يتغيّر — نوم بلا معركة، أو عناد أقلّ —' || v_nl
          || 'فالرحلة الواحدة عندكم: ' || (v_cs->>'price') || '.' || v_nl
          || 'وفريق آدم يشرح التفاصيل وطرق الدفع: https://t.me/Abdouleg';
    elsif (v_cs->>'state') = 'unknown' then
      return 'لم أتعرّف على البلد.' || v_nl
          || 'لا بأس — كل ما بيننا يبقى كما هو، دون نقص.';
    else
      return 'سجّلنا بلدكم.' || v_nl || v_nl
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

  -- Used everywhere below: the child's name when known, and a plain
  -- word when not. A surface that says «طفلكم» is still concrete;
  -- one that says nothing at all is the fragment problem.
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

    -- Nothing yet: this is the surface that must explain the whole
    -- product, because a parent who taps it this early is asking
    -- "what is this thing and what do I get".
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


-- ------------------------------------------------------------
-- progress_line — السطر المثبَّت أعلى المحادثة. مساحته ضيّقة،
-- لكن «سجّلنا مرة واحدة» وحدها لا تقول ما الذي يُنتظر ولا لماذا.
-- ------------------------------------------------------------
create or replace function public.progress_line(
  p_nights_with_result integer, p_logged_this_week integer, p_calm_this_week integer)
returns text
language sql
immutable
as $function$
  select case
    when coalesce(p_nights_with_result,0) = 0
      then 'لم نجرّب شيئاً بعد — نبدأ اليوم.'
    when p_nights_with_result = 1
      then 'جرّبتم مرة واحدة. بعد ثلاث أعرف ما الذي يتكرّر عندكم.'
    when p_nights_with_result = 2
      then 'جرّبتم مرّتين. بعد ثلاث أعرف ما الذي يتكرّر عندكم.'
    when coalesce(p_logged_this_week,0) = 0
      then 'لم نجرّب شيئاً هذا الأسبوع.'
    else 'هذا الأسبوع: ' || public.ar_digits(p_calm_this_week::text)
         || ' من ' || public.ar_digits(p_logged_this_week::text) || ' مرّت بهدوء.'
  end;
$function$;

commit;
