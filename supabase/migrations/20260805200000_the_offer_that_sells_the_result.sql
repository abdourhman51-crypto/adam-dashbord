-- ============================================================
-- The offer sells the result, not the mechanism.
--
-- Three things were wrong at the same time, and the third is
-- the one that costs money.
--
-- 1. `**` everywhere. Nothing in this product sends with a
--    parse_mode, so every `**عنوان**` reached the parent as
--    literal asterisks. Bold that isn't bold is just noise, and
--    it was on the offer surface — the one screen where a
--    parent decides whether to pay.
--
-- 2. The offer described the machinery: what ADAM does, in what
--    order. A parent at 10pm is not buying a method. They are
--    buying the end of a night that keeps coming back.
--
-- 3. We undersold the thing. The journey engine already
--    implements three promises that almost nothing else in this
--    market makes, and the offer mentioned none of them:
--
--      · The clock counts LOGGED days, not calendar days
--        (`v_stage_progress.logged_days`). Travel, illness, a
--        heavy week — none of them can steal a day. For an Arab
--        parent who has bought a course and watched the access
--        window burn while life happened, this is the single
--        most disarming sentence we own.
--      · One automatic extension, half the length again, granted
--        without being asked (`stages.extension_days`, and the
--        column comment says "unrequested").
--      · No second extension — an automatic refund instead
--        (`stages.refunded_at`).
--
--    And two refusals that buy more trust than any claim:
--      · `can_propose_stage` returns `trend_improving` — ADAM
--        will not raise the offer to a parent whose nights are
--        already getting better.
--      · `uq_one_live_stage_per_parent` — one journey at a time,
--        because the scarce resource is the parent's attention.
--
--    Every line added here maps to one of those. Nothing is
--    promised that the schema does not already enforce.
--
-- 4. The call to action was a bare URL in the message body. Now
--    it is a button. `get_conversation_moment` may emit a button
--    carrying `url` instead of `cb`, and `Tap - Send Fixed`
--    renders it as a Telegram url button. The label carries the
--    child's name when we know it, because «نبدأ رحلة يوسف» is a
--    decision about a specific child and «اضغط هنا» is not.
-- ============================================================

begin;

-- ------------------------------------------------------------
-- Steps 1–3 of the funnel: same shape, no asterisks, and the
-- capability list stops being modest.
-- ------------------------------------------------------------
update public.conversation_moments
set body_ar =
    '🌿 ما هو آدم؟' || chr(10) || chr(10) ||
    'مرافق يومي لكم أنتم، مع طفلكم أنتم بالذات.' || chr(10) ||
    'تحكون له ما تعبتم منه اليوم، فيعطيكم شيئاً واحداً صغيراً تجرّبونه — مبنياً على طفلكم، لا نصيحة عامّة.' || chr(10) ||
    'وكل يوم يعرفه أكثر، فيصير ما يقوله أقرب.' || chr(10) || chr(10) ||
    '🎯 النتيجة' || chr(10) ||
    'المعارك تقلّ، لأنكم تعرفون ما الذي يشعلها قبل أن تشتعل.' || chr(10) ||
    'ويهدأ البيت، وتهدؤون أنتم معه.'
where key = 'menu_faq';

update public.conversation_moments
set body_ar =
    '⚙️ كيف يشتغل — أربع خطوات' || chr(10) || chr(10) ||
    '1️⃣ تحكون ما حدث اليوم مع طفلكم. سطر واحد يكفي.' || chr(10) ||
    '2️⃣ يعطيكم شيئاً صغيراً تجرّبونه في اليوم نفسه — مربوطاً بموقفكم أنتم.' || chr(10) ||
    '3️⃣ مساءً يسألكم: هل تغيّر شيء؟ وجوابكم ضغطة زر.' || chr(10) ||
    '4️⃣ بعد ثلاث مرات يريكم ما لم تروه: الموقف الذي يتكرّر في بيتكم، وما الذي يهدّئ طفلكم فيه.' || chr(10) || chr(10) ||
    '⏱️ وكم يأخذ منكم؟' || chr(10) ||
    'دقيقة في اليوم. ولا يُطلب منكم شيء في اليوم الذي لا تحتملونه.'
where key = 'menu_how';

-- The differentiator list. Every item is a capability that
-- exists: the child row, the situations table, the counted
-- repeats in get_harvest_prompt, the one-step rule, the harvest
-- question, parent_strain, the §2.6 send gate, and erasure.
update public.conversation_moments
set max_lines = 16,
    body_ar =
    '✨ ما الذي يميّز آدم' || chr(10) || chr(10) ||
    'جرّبتم قبله فيديوهات ومقالات ونصائح من كل جهة، ولم ينفع أكثرها.' || chr(10) ||
    'والسبب ليس أنها رديئة — بل أنها عن «الأطفال»، لا عن طفلكم.' || chr(10) || chr(10) ||
    '✅ يعرف طفلكم بالاسم — عمره، وأصعب ساعة في يومه، وما الذي يهدّئه' || chr(10) ||
    '✅ يتذكّر كل ما جرّبتموه، فلا تشرحون من البداية في كل مرّة' || chr(10) ||
    '✅ يعدّ ما يتكرّر: «هذه ثالث مرّة هذا الأسبوع». لا أحد كان يعدّ قبله' || chr(10) ||
    '✅ خطوة واحدة صغيرة، لا محاضرة — صغيرة بما يكفي لتُجرَّب في أسوأ يوم' || chr(10) ||
    '✅ يسأل عن النتيجة، فيتعلّم من جوابكم ويقترب أكثر' || chr(10) ||
    '✅ يرى تعبكم أنتم، فحين تكونون منهكين يخفّف ولا يطلب' || chr(10) ||
    '✅ ولا يرسل نصيحة عامّة أبداً — إن لم يكن ما سيقوله مبنيّاً على بيتكم، يصمت' || chr(10) ||
    '✅ وما تقولونه يبقى لكم وحدكم — تطلبون محوه، فيُمحى كلّه' || chr(10) || chr(10) ||
    'والفرق في جملة واحدة:' || chr(10) ||
    'النصيحة العامّة تصلح لكل الأطفال، ولهذا لا تصلح لطفلكم بالذات.'
where key = 'menu_why';


-- Bold that never renders cannot come back. Deliberately a
-- constraint on STORED copy only, not a new copy_violations()
-- rule: copy_violations() also gates what the model writes at
-- send time, and an LLM reaching for markdown would start
-- costing real sends. The bug was in copy we wrote and stored,
-- so the guard sits exactly there.
alter table public.conversation_moments
  drop constraint if exists chk_body_no_dead_markup;
alter table public.conversation_moments
  add constraint chk_body_no_dead_markup
  check (body_ar is null or body_ar not like '%**%');


-- ------------------------------------------------------------
-- get_conversation_moment — the offer surface, rewritten.
--
-- Only the `menu_journey` branch changes; everything else is the
-- function as it stood, so this is a rewrite of one screen and
-- not of the moment layer.
-- ------------------------------------------------------------
create or replace function public.get_conversation_moment(
  p_key text, p_parent_id uuid default null::uuid)
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
  v_name    text;
  v_who     text;
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

    select nullif(btrim(c.name), '') into v_name
    from public.children c where c.follower_id = p_parent_id
    order by c.is_primary desc nulls last, c.created_at limit 1;
    v_who := coalesce(v_name, 'طفلكم');

    if (v_cs->>'state') = 'supported' then
      v_body :=
        -- What they already have, and that it is not a trial.
        '🌿 المجاني يبقى مجانياً، بلا نقص' || v_nl ||
        'تحكون لي ما حدث، أفهم ' || v_who || '، وأعطيكم شيئاً صغيراً تجرّبونه اليوم.' || v_nl ||
        'هذا يجعل ليلتكم أخفّ — وسيبقى لكم دائماً.' || v_nl || v_nl ||
        -- The enemy, named. Not "more features": the return of the same night.
        '🎯 لكن «أخفّ» ليست هي النتيجة' || v_nl ||
        'المشكلة ليست ليلة صعبة، بل أنّها ترجع الأسبوع القادم، وبعده، وبعده.' || v_nl ||
        'والمرافقة الكاملة موجودة لشيء واحد: أن تتوقّف القصّة عن التكرار.' || v_nl || v_nl ||
        '🧭 كيف نصل — أربع خطوات' || v_nl ||
        '1️⃣ تختارون مشكلة واحدة تُتعبكم أكثر من غيرها، بكلماتكم أنتم.' || v_nl ||
        '2️⃣ نتّفق على شكل الوصول قبل أن نبدأ: «خمس ليالٍ هادئة من سبع». رقم نراه معاً، لا شعور نتجادل فيه.' || v_nl ||
        '3️⃣ كل يوم خطوة واحدة مبنية على ' || v_who || ' وعلى ما نفع معه أمس. دقيقة منكم.' || v_nl ||
        '4️⃣ ثم أتراجع أنا عمداً، لنرى الهدوء وهو يصمد بلا أن أذكّركم به.' || v_nl || v_nl ||
        -- The 'hold' phase is the product's real differentiator: the
        -- goal is that they stop needing it.
        'والخطوة الرابعة هي الفرق كلّه:' || v_nl ||
        'لا أريدكم أن تحتاجوني بعد شهر. أريد أن يكون بيتكم قد تغيّر.' || v_nl || v_nl ||
        -- Every line here is a column in `stages`.
        '🛡️ وحتى لا تخاطروا بشيء' || v_nl ||
        '✅ الأيام تُحسب حين تكونون معي، لا حين يمرّ التقويم — سفر أو مرض أو أسبوع ثقيل لا يسرق منكم يوماً' || v_nl ||
        '✅ لم نصل في المدّة المتّفق عليها؟ أُكمل معكم نصفها كاملاً، مجاناً، وبلا أن تطلبوا' || v_nl ||
        '✅ ولم نصل بعدها؟ يرجع مالكم. بلا شرح، وبلا أن تُقنعوا أحداً' || v_nl || v_nl ||
        -- The refusals. can_propose_stage enforces both.
        '🤍 وقبل أن تقرّروا، ثلاثة أشياء أقولها بصراحة' || v_nl ||
        '✅ رحلة واحدة في المرّة — لن أعرض عليكم ثانية وأنتم في الأولى' || v_nl ||
        '✅ وإن رأيت الأمور تتحسّن عندكم، أصمت ولا أعرض شيئاً' || v_nl ||
        '✅ وإن لم يكن هذا وقتكم، قولوها — المجاني يبقى كما هو، بلا نقص وبلا زعل' || v_nl || v_nl ||
        '💰 الرحلة الواحدة عندكم: ' || (v_cs->>'price');

      -- A decision about one child, not a link.
      v_buttons := jsonb_build_array(
        jsonb_build_object(
          'label', case when v_name is null then '💚 نبدأ الرحلة'
                        else '💚 نبدأ رحلة ' || v_name end,
          'url',   'https://t.me/Abdouleg'),
        jsonb_build_object('label', '🤔 عندي سؤال قبل أن أقرّر', 'cb', 'other'));

    elsif (v_cs->>'state') = 'unknown' then
      v_body :=
        '🎯 المرافقة الكاملة' || v_nl || v_nl ||
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
        '🌿 آدم يرافقكم بالكامل، كما يرافق الجميع.' || v_nl ||
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

comment on function public.get_conversation_moment(text, uuid) is
  'One moment, ready to send: body, buttons, and whether commerce is allowed to show it. A button may carry `url` instead of `cb` — the offer''s call to action is a link button, not a bare address in the text. menu_journey is composed here because the price and the country are per-parent.';


-- ------------------------------------------------------------
-- compose_menu_body — the same two fixes on the country receipt:
-- no asterisks, and it points at the offer instead of dumping a
-- link, since /journey now carries the button.
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
          || '💰 الرحلة الواحدة عندكم: ' || (v_cs->>'price') || v_nl
          || 'واضغطوا «المرافقة الكاملة» في القائمة لتروا كيف نصل، وما ضماننا لكم.';
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
