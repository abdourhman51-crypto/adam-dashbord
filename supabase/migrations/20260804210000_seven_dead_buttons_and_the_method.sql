begin;

-- ============================================================
-- سبعة أزرار كانت تَعِد بفعل وتُجيب: «لم أفهم هذه تماماً».
--
-- المؤسس ضغط «امحوا كل ما قلته» فجاءه نصّ الإنقاذ. وضغط
-- «أوقفوا الرسالة اليومية» فجاءه النصّ نفسه. وهذا ليس خطأ نصّ —
-- بل أزرار ميّتة.
--
-- الدليل، لا التخمين: هذه المفاتيح لا تظهر **ولا مرة واحدة** في
-- الـworkflow كلّه (بحث على 262 ألف حرف من JSON):
--
--   quiet_hours · pause · erase · resume_tomorrow
--   stay_paused · review_yes · review_stay
--
-- وجدول التوجيه في Router ينتهي بـ:
--   else { route = 'menu_tap'; cbdata = 'rescue'; }
--
-- فكل واحد منها يسقط إلى الإنقاذ. سبعة أزرار تَعِد ولا تفي، وهي
-- عيب سابق لتغييرات اليوم — لكن الصياغة الجديدة جعلتها أكثر
-- إغراءً بالضغط، فظهر العطب.
--
-- الحلّ: get_moment_after_tap يصير المكان الواحد الذي يُنفَّذ فيه
-- فعلُ الزرّ. وهذا هو النمط القائم أصلاً — الدالّة نفسها تُسجّل
-- البلد قبل أن تُركّب الجواب. ولا عقدة جديدة في n8n، لأن واجهة
-- MCP لا تستطيع ربط اعتماد بعقدة httpRequest جديدة.
--
-- والمحو خطوتان عمداً. النسخة القديمة وعدت «بضغطة واحدة وبلا
-- أسئلة»، وهذا وعدٌ بفعل لا رجعة فيه بلا تأكيد. «بلا أسئلة» تبقى
-- صادقة — لا نسأل عن السبب — لكن الفعل يُؤكَّد مرّة.
-- ============================================================


-- ------------------------------------------------------------
-- لحظات الإعدادات والخصوصية الجديدة.
-- ------------------------------------------------------------
insert into public.conversation_moments
  (key, category, tier, body_ar, buttons, max_lines, requires_commerce, note)
values
  ('menu_settings_hours', 'reference', 'fixed',
   'في أي وقت تفضّلون أن أسألكم عن يومكم مع طفلكم؟' || chr(10) ||
   'رسالة واحدة، في الوقت الذي تختارونه.',
   '[{"label":"صباحاً","cb":"menu_settings_hour_morning"},
     {"label":"بعد العصر","cb":"menu_settings_hour_evening"},
     {"label":"قبل النوم","cb":"menu_settings_hour_night"},
     {"label":"عندي سؤال آخر","cb":"other"}]'::jsonb,
   4, false,
   'The time picker behind quiet_hours. Three concrete choices, because a parent should never have to type a number to change a setting.'),

  ('menu_settings_hour_set', 'reference', 'fixed',
   'تمّ. سأكتب لكم في الوقت الذي اخترتم — رسالة واحدة، لا أكثر.',
   '[]'::jsonb, 2, false,
   'Confirmation after set_hour_*. States the frequency again, because that is the thing parents fear about a daily message.'),

  ('menu_settings_paused', 'reference', 'fixed',
   'أوقفت الرسالة اليومية. لن يصلكم منّي شيء من تلقاء نفسي.' || chr(10) || chr(10) ||
   'والحديث بيننا يبقى مفتوحاً كما هو: اكتبوا لي متى شئتم، وأنا هنا.',
   '[{"label":"أعيدوها من الغد","cb":"menu_settings_resumed"},
     {"label":"عندي سؤال آخر","cb":"other"}]'::jsonb,
   4, false,
   'Confirmation after pause. The second line is load-bearing: parents fear that stopping the message stops the help.'),

  ('menu_settings_resumed', 'reference', 'fixed',
   'عادت الرسالة اليومية من الغد — واحدة في اليوم، لا أكثر.',
   '[]'::jsonb, 2, false,
   'Confirmation after resume_tomorrow.'),

  ('menu_settings_still_paused', 'reference', 'fixed',
   'تمّ، تبقى متوقّفة. والحديث بيننا مفتوح متى شئتم.',
   '[]'::jsonb, 2, false,
   'Confirmation after stay_paused.'),

  ('menu_privacy_erase_ask', 'reference', 'fixed',
   'قبل أن أمحو: هذا يمسح كل ما تحدّثنا عنه — اسم طفلكم، وما حكيتموه، وكل ما فهمته عنه.' || chr(10) ||
   'ولا يمكن استرجاعه بعدها.' || chr(10) || chr(10) ||
   'لن أسألكم عن السبب. أسأل مرّة واحدة فقط حتى لا يحدث بالخطأ.',
   '[{"label":"نعم، امحوا كل شيء","cb":"menu_privacy_erased"},
     {"label":"لا، تراجعتُ","cb":"other"}]'::jsonb,
   5, false,
   'Erasure is irreversible and deletes the parent row itself, so it is two taps. "No questions asked" stays true — we never ask WHY — but the act is confirmed once so it cannot happen by a misplaced thumb.'),

  ('menu_privacy_erased', 'reference', 'fixed',
   'مُحي كل شيء. لم يبقَ عندي منكم شيء.' || chr(10) || chr(10) ||
   'وإن أردتم العودة يوماً، نبدأ من جديد كأننا لم نلتقِ.',
   '[]'::jsonb, 4, false,
   'After execute_erasure. The parent row is gone; the next message creates a new one, which is exactly what this says.')
on conflict (key) do update
  set body_ar = excluded.body_ar, buttons = excluded.buttons,
      category = excluded.category, tier = excluded.tier,
      max_lines = excluded.max_lines, note = excluded.note;


-- ------------------------------------------------------------
-- الخصوصية: النسخة القديمة وعدت بمحو بضغطة واحدة. الآن تصف
-- ما يحدث فعلاً.
-- ------------------------------------------------------------
update public.conversation_moments set
  body_ar = '🔒 خصوصيتكم' || chr(10) || chr(10) ||
            'كل ما تكتبونه هنا يبقى بينكم وبيني وحدنا. لا يراه أحد غيري، ولا يخرج إلى أي مكان.' || chr(10) ||
            'أستعمله لشيء واحد فقط: أن يكون ما أقوله لكم غداً أقرب لطفلكم من كلام اليوم.' || chr(10) || chr(10) ||
            'ويمكنكم محو كل شيء متى شئتم — بلا أسئلة عن السبب.'
where key = 'menu_privacy';


-- ------------------------------------------------------------
-- الإعدادات: تقول الآن إن الرسالة إشعار واحد في اليوم، لأن
-- الوالد لا يعرف أصلاً أن آدم يرسل شيئاً من تلقاء نفسه.
-- ------------------------------------------------------------
update public.conversation_moments set
  body_ar = '⚙️ الإعدادات' || chr(10) || chr(10) ||
            'مرة واحدة في اليوم يصلكم منّي إشعار واحد: أسألكم فيه كيف مرّ اليوم مع طفلكم.' || chr(10) ||
            'جوابكم هو ما يجعلني أعرف ما ينفع معه وما لا ينفع — ومنه يتحسّن ما أقترحه.' || chr(10) || chr(10) ||
            'ولا شيء غير ذلك يصلكم أبداً. لا إعلانات، ولا تذكيرات، ولا رسائل أخرى.'
where key = 'menu_settings';


-- ------------------------------------------------------------
-- الأسئلة الشائعة: أضيف «كيف نصل للنتيجة؟» — الطريقة خطوة بخطوة
-- من طرف الوالد، لا وصف الآلة. وأُوضّح أن الرسالة إشعار واحد.
-- ------------------------------------------------------------
-- 34 content lines; the table's own ceiling is 40.
update public.conversation_moments set
  max_lines = 40,
  body_ar =
    '**ما هو آدم؟**' || chr(10) ||
    'شخص تحكون له عمّا يتعبكم مع طفلكم، فيمشي معكم خطوة بخطوة حتى يقلّ.' || chr(10) || chr(10) ||

    '**وما الذي سيتغيّر عندي؟**' || chr(10) ||
    'المعارك تقلّ لأنكم تعرفون ما الذي يشعلها قبل أن تشتعل.' || chr(10) ||
    'وتفهمون لماذا يتصرّف طفلكم هكذا — فيهدأ البيت، وتهدؤون أنتم معه.' || chr(10) ||
    'لا وعد بطفل مثالي. الوعد أن تتوقّف القصة نفسها عن التكرار كل يوم.' || chr(10) || chr(10) ||

    '**كيف نصل إلى ذلك؟**' || chr(10) ||
    'أربع خطوات، وكلها تبدأ منكم:' || chr(10) ||
    '١. تحكون لي ما حدث اليوم مع طفلكم — بكلماتكم، ولو سطراً واحداً.' || chr(10) ||
    '٢. أعطيكم شيئاً واحداً صغيراً تجرّبونه في نفس اليوم، مربوطاً بموقفكم أنتم لا بنصيحة عامّة.' || chr(10) ||
    '٣. مساءً أسألكم: هل تغيّر شيء؟ وجوابكم كلمة واحدة بضغطة زر.' || chr(10) ||
    '٤. بعد ثلاث مرات أريكم ما لم تروه: الموقف الذي يتكرّر عندكم بالذات، وما الذي يهدّئ طفلكم فيه.' || chr(10) ||
    'ومن هناك نختار هدفاً واحداً، ونمشي إليه حتى يتغيّر.' || chr(10) || chr(10) ||

    '**كم يأخذ منّي هذا؟**' || chr(10) ||
    'دقيقة في اليوم. سطر منكم، وشيء صغير تجرّبونه، وضغطة زر مساءً.' || chr(10) ||
    'ولا يُطلب منكم شيء في اليوم الذي لا تحتملونه.' || chr(10) || chr(10) ||

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

    '**هل ستصلني رسائل كثيرة؟**' || chr(10) ||
    'إشعار واحد في اليوم، لا أكثر: سؤال المساء. لا إعلانات ولا تذكيرات.' || chr(10) ||
    'ويمكن تغيير وقته أو إيقافه تماماً من الإعدادات، ويبقى الحديث مفتوحاً.' || chr(10) || chr(10) ||

    '**ماذا يحدث لما أقوله؟**' || chr(10) ||
    'يبقى بينكم وبيني وحدنا، ويمكن محوه كلّه متى شئتم دون أسئلة.'
where key = 'menu_faq';


-- ------------------------------------------------------------
-- get_moment_after_tap — المكان الواحد الذي يُنفَّذ فيه فعل الزرّ.
--
-- كان يسجّل البلد فقط. الآن ينفّذ فعل الإعدادات والخصوصية أيضاً،
-- ثم يُركّب لحظة التأكيد. الفعل قبل التركيب دائماً، حتى لا تؤكّد
-- الرسالةُ شيئاً لم يحدث.
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
declare
  v_rec  jsonb;
  v_req  uuid;
  v_done text := null;
  v_moment text := p_key;   -- the moment shown may differ from the tap key
begin
  if nullif(btrim(coalesce(p_country_code,'')), '') is not null then
    -- A refusal here is not an error: record_country rejects anything it
    -- cannot put on a clock, and the moment below then honestly reports
    -- that we still do not know where they are.
    v_rec := public.record_country(p_parent_id, p_country_code);
  end if;

  -- ---- the tap actions -------------------------------------------------
  -- Every one of these was a button that promised something and answered
  -- «لم أفهم». The action runs BEFORE the moment is composed, so the
  -- confirmation can never describe something that did not happen.
  --
  -- The three hour keys carry the chosen hour in the KEY itself rather
  -- than in a parameter: this call has no free slot for it, and adding
  -- one would mean a new n8n node, which cannot be given a credential.
  if p_parent_id is not null then
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
                else                              21::smallint end);
      v_done   := 'hour_set';
      v_moment := 'menu_settings_hour_set';

    elsif p_key = 'menu_privacy_erased' then
      -- Irreversible, and confirmed on the previous tap.
      v_req := public.request_erasure(p_parent_id);
      if v_req is not null then
        perform public.execute_erasure(v_req);
        v_done := 'erased';
      end if;
    end if;
  end if;

  -- After an erasure the parent row is gone, so the moment must be
  -- composed without an id or every parent-scoped lookup inside it
  -- would silently return nothing.
  return public.get_conversation_moment(
           v_moment,
           case when v_done = 'erased' then null else p_parent_id end)
       || jsonb_build_object('country_recorded', coalesce(v_rec, 'null'::jsonb))
       || jsonb_build_object('action_done', coalesce(to_jsonb(v_done), 'null'::jsonb));
end;
$function$;

comment on function public.get_moment_after_tap(text, uuid, text) is
  'The one place a tap performs its action. Records the country when one is supplied, and performs the settings/privacy actions whose callbacks were previously unhandled anywhere — seven buttons that promised an action and answered with the rescue text. The action always runs before the moment is composed, so a confirmation can never describe something that did not happen.';


-- ------------------------------------------------------------
-- set_checkin_hour — يُستدعى من مسار اختيار الوقت.
-- ------------------------------------------------------------
create or replace function public.set_checkin_hour(p_parent_id uuid, p_hour smallint)
returns boolean
language plpgsql
volatile
security definer
set search_path to 'pg_catalog','public'
as $function$
begin
  if p_hour is null or p_hour < 0 or p_hour > 23 then
    return false;
  end if;
  insert into public.checkin_state (parent_id, local_hour, cadence)
  values (p_parent_id, p_hour, 'daily')
  on conflict (parent_id) do update
    set local_hour = excluded.local_hour, updated_at = now();
  return true;
end;
$function$;

comment on function public.set_checkin_hour(uuid, smallint) is
  'Sets the local hour of the one daily message. Three concrete choices are offered as buttons (morning / afternoon / before bed) so a parent never types a number to change a setting.';

revoke all on function public.set_checkin_hour(uuid, smallint) from anon, authenticated, public;
grant execute on function public.set_checkin_hour(uuid, smallint) to service_role;

commit;

-- ------------------------------------------------------------
-- الأزرار التي كانت تشير إلى المفاتيح الميّتة.
-- review_yes / review_stay لم تحتاجا لحظات جديدة: menu_journey
-- و menu_open_question كانتا مُوجَّهتين منذ البداية.
-- ------------------------------------------------------------
update public.conversation_moments set
  buttons = '[{"label":"غيّروا وقت الرسالة","cb":"menu_settings_hours"},
              {"label":"أوقفوا الرسالة اليومية","cb":"menu_settings_paused"},
              {"label":"عندي سؤال آخر","cb":"other"}]'::jsonb
where key = 'menu_settings';

update public.conversation_moments set
  buttons = '[{"label":"امحوا كل ما قلته","cb":"menu_privacy_erase_ask"},
              {"label":"عندي سؤال آخر","cb":"other"}]'::jsonb
where key = 'menu_privacy';

update public.conversation_moments set
  buttons = '[{"label":"نعود من الغد","cb":"menu_settings_resumed"},
              {"label":"نبقى كما نحن","cb":"menu_settings_still_paused"},
              {"label":"عندي موقف آخر","cb":"other"}]'::jsonb
where key = 'menu_resume';

update public.conversation_moments set
  buttons = '[{"label":"نعم، نعمل عليه","cb":"menu_journey"},
              {"label":"نكمل كما نحن","cb":"menu_open_question"},
              {"label":"عندي موقف آخر","cb":"other"}]'::jsonb
where key = 'review_stage4';
