-- ============================================================
-- One promise, one next step.
--
-- The previous offer stacked five reassurances — logged days, an
-- extension, a refund, one-journey-at-a-time, and a vow of
-- silence on an improving trend. Each was true. Together they
-- read as a legal notice, and a parent skims a legal notice.
--
-- Founder's call, taken here: ONE guarantee.
--
--     نتّفق قبل أن نبدأ على هدف واضح ترونه بأعينكم.
--     وإن لم نصل إليه في المدّة، أُكمل معكم نصف المدّة
--     كاملةً مجاناً حتى نصل.
--
-- And the refund leaves the design with it. That costs nothing
-- to remove, because it was never built: no function has ever
-- written `stages.refunded_at`. It existed as a sentence in a
-- column comment. A promise that lives only in a comment is a
-- promise nobody can keep, so the comment is the thing that
-- goes. `'refunded'` survives as a status value an operator may
-- still set by hand — `can_propose_stage`, `get_telegram_surface`
-- and the erasure view all read it, and removing it would break
-- three working functions to no benefit.
--
-- `erasure_requests.refund_due` is untouched. That is a
-- different promise — money back pro-rata when a parent erases
-- everything mid-journey — and it is a right, not a sales
-- guarantee.
--
-- ------------------------------------------------------------
-- What the offer is now built on
--
-- The value equation, taken seriously: maximise the outcome and
-- the belief it will happen, minimise the wait and the effort.
--
--   Outcome     — a problem THEY name stops repeating. Four
--                 named ones, so it is concrete before they
--                 have to imagine it.
--   Belief      — the goal is agreed and observable BEFORE any
--                 money moves; the guarantee; and «لا أعدكم
--                 بطفلٍ مثالي», because a smaller promise made
--                 honestly is believed more than a large one.
--   Wait        — ٢٩ يوماً. Named, finite, and something changes
--                 the first day.
--   Effort      — a minute or two a day, and the day they
--                 cannot face does not count against them.
--
-- That last line is the honest edge of the ٢٩. The clock counts
-- days the parent logged (`v_stage_progress.logged_days`), never
-- calendar days, so a hard week cannot eat the journey. Said as
-- a caveat it would shrink the offer; said as relief it grows
-- it. It is the same fact either way.
--
-- ------------------------------------------------------------
-- And the personalisation is the sale
--
-- Seven capabilities, each with its own emoji, each one real:
-- the child row, the situations table, yesterday's result
-- feeding today's step, the counted repeats in
-- get_harvest_prompt, the one evening question, parent_strain,
-- and erasure. The line above them is the whole argument:
-- «لا يعطيكم نصيحة عامّة، بل خطوة مصنوعة لطفلكم وحده».
--
-- ------------------------------------------------------------
-- The buttons finally tell the truth
--
-- ADAM cannot discuss the journey. He is forbidden to say a
-- price, and he does not know the terms — فريق آدم does. The old
-- second button said «عندي سؤال قبل أن أقرّر» and routed to
-- ADAM, who by design cannot answer it. That is a dead end
-- dressed as help, sitting on the conversion screen.
--
--   📞 أتحدّث مع فريق آدم عن يوسف   → the humans, by name
--   🌿 ليس الآن — نكمل مجاناً        → pressure released, and
--                                     the free relationship
--                                     restated as undamaged
--
-- The same boundary is now stated in `menu_how`, where a parent
-- reading about the method learns where the method stops.
-- ============================================================

begin;

-- ------------------------------------------------------------
-- ٢٩ is now the engine's own number, not a number in an advert.
-- `planned_logged_days` had no default, so any stage created
-- without one would have failed a NOT NULL — which is fine while
-- nothing creates stages (0 rows today), and a trap the first
-- time فريق آدم starts one by hand.
-- ------------------------------------------------------------
alter table public.stages
  alter column planned_logged_days set default 29;

comment on column public.stages.planned_logged_days is
  'The journey clock, in days the parent actually logged — never calendar days, so travel, illness or a heavy week cannot eat the journey. Defaults to 29, which is the number the offer promises; the offer and the column must move together.';

comment on column public.stages.extension_days is
  'The single automatic extension granted when the objective is not met: half the stage length, unrequested. This is the whole of what is owed. The note that stood here promised money back after a second failure — no code ever implemented that, and a promise living only in a comment cannot be kept, so it is no longer made. `refunded` remains a status an operator may set by hand.';


-- ------------------------------------------------------------
-- The method now names where the method stops.
-- ------------------------------------------------------------
update public.conversation_moments
set body_ar =
    '⚙️ كيف يشتغل — أربع خطوات' || chr(10) || chr(10) ||
    '1️⃣ تحكون ما حدث اليوم مع طفلكم. سطر واحد يكفي.' || chr(10) ||
    '2️⃣ يعطيكم شيئاً صغيراً تجرّبونه في اليوم نفسه — مربوطاً بموقفكم أنتم.' || chr(10) ||
    '3️⃣ مساءً يسألكم: هل تغيّر شيء؟ وجوابكم ضغطة زر.' || chr(10) ||
    '4️⃣ بعد ثلاث مرات يريكم ما لم تروه: الموقف الذي يتكرّر في بيتكم، وما الذي يهدّئ طفلكم فيه.' || chr(10) || chr(10) ||
    '⏱️ وكم يأخذ منكم؟' || chr(10) ||
    'دقيقة في اليوم. ولا يُطلب منكم شيء في اليوم الذي لا تحتملونه.' || chr(10) || chr(10) ||
    '📌 وحدودي واضحة: كلّ ما يخصّ المرافقة الكاملة — التفاصيل والدفع — يتولّاه فريق آدم، لا أنا.'
where key = 'menu_how';

-- Each capability gets its own mark. Nine identical ✅ read as a
-- list of terms; nine different marks read as nine things.
update public.conversation_moments
set body_ar =
    '✨ ما الذي يميّز آدم' || chr(10) || chr(10) ||
    'جرّبتم قبله فيديوهات ومقالات ونصائح من كل جهة، ولم ينفع أكثرها.' || chr(10) ||
    'والسبب ليس أنها رديئة — بل أنها عن «الأطفال»، لا عن طفلكم.' || chr(10) || chr(10) ||
    '👦 يعرف طفلكم بالاسم — عمره، وأصعب ساعة في يومه، وما الذي يهدّئه' || chr(10) ||
    '🧠 يتذكّر كلّ ما جرّبتموه، فلا تشرحون من البداية في كل مرّة' || chr(10) ||
    '🔁 يبني خطوة اليوم على نتيجة أمس، فلا تبدؤون من الصفر أبداً' || chr(10) ||
    '📊 يعدّ ما يتكرّر: «هذه ثالث مرّة هذا الأسبوع». لا أحد كان يعدّ قبله' || chr(10) ||
    '🪶 خطوة واحدة صغيرة، لا محاضرة — صغيرة بما يكفي لتُجرَّب في أسوأ يوم' || chr(10) ||
    '🌙 سؤال واحد في المساء، فيتعلّم من جوابكم ويقترب أكثر' || chr(10) ||
    '🤍 يرى تعبكم أنتم، فحين تكونون منهكين يخفّف ولا يطلب' || chr(10) ||
    '🤐 ولا يرسل نصيحة عامّة أبداً — إن لم يكن ما سيقوله مبنيّاً على بيتكم، يصمت' || chr(10) ||
    '🔒 وما تقولونه يبقى لكم وحدكم — تطلبون محوه، فيُمحى كلّه' || chr(10) || chr(10) ||
    'والفرق في جملة واحدة:' || chr(10) ||
    'النصيحة العامّة تصلح لكل الأطفال، ولهذا لا تصلح لطفلكم بالذات.'
where key = 'menu_why';


-- ------------------------------------------------------------
-- «ليس الآن» is a real destination, not a shrug.
--
-- A parent who declines must land somewhere that costs them
-- nothing — otherwise the only safe move is to not open the
-- offer at all. `menu_` prefix, so the Router dispatches it with
-- no code change.
-- ------------------------------------------------------------
insert into public.conversation_moments
  (key, category, tier, body_ar, buttons, max_lines, requires_commerce, note)
values
  ('menu_not_now', 'menu', 'fixed',
   '🌿 لا ضغط أبداً.' || chr(10) ||
   'آدم المجاني معكم كما هو، بلا نقص — والباب مفتوح متى شئتم.' || chr(10) ||
   'احكوا لي ما يشغلكم الآن.',
   '[{"label":"💬 عندي موقف الآن","cb":"other"}]'::jsonb,
   3, false,
   'Where «ليس الآن» lands. Declining must be cheap and must not damage the free relationship, or the safest move for a parent becomes never opening the offer. Says the refusal was heard, restates that nothing was lost, and returns to the ordinary conversation in one line.')
on conflict (key) do update
  set body_ar = excluded.body_ar, buttons = excluded.buttons,
      max_lines = excluded.max_lines, note = excluded.note;


-- ------------------------------------------------------------
-- The offer.
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
        'احكوا لي ما حدث في أيّ وقت، وأعطيكم خطوة صغيرة تناسب موقفكم اليوم.' || v_nl ||
        'هذا لكم دائماً، ولن ينقص منه شيء.' || v_nl || v_nl ||
        -- The enemy: not tonight, the repeat.
        'لكن أحياناً لا تكون المشكلة في هذا اليوم —' || v_nl ||
        'بل في أنّ الموقف نفسه يتكرّر، ويستنزفكم مرّة بعد مرّة.' || v_nl ||
        'ولهذا وُجدت المرافقة الكاملة.' || v_nl || v_nl ||
        -- Outcome + the wait, both named. The disclaimer is what
        -- makes the rest believable.
        '🎯 خلال ٢٩ يوماً' || v_nl ||
        'لا أعدكم بطفلٍ مثالي.' || v_nl ||
        'لكن أعدكم أن نعمل معاً على مشكلة واحدة تختارونها أنتم، حتى نصل إلى نتيجة نتّفق عليها قبل أن نبدأ:' || v_nl ||
        '🌙 نوم بلا معركة' || v_nl ||
        '🔥 نوبات غضب أقلّ' || v_nl ||
        '🗣️ صراخ أقلّ في البيت' || v_nl ||
        '🎒 أو ما تشعرون أنّه الأثقل عليكم اليوم' || v_nl || v_nl ||
        -- Personalisation: the whole differentiator, one mark each.
        '✨ ولماذا آدم بالذات؟' || v_nl ||
        'لأنّه لا يعطيكم نصيحة عامّة، بل خطوة مصنوعة ل' || v_who || ' وحده:' || v_nl ||
        '👦 يعرف ' || v_who || ': عمره، وأصعب ساعة في يومه، وما الذي يهدّئه' || v_nl ||
        '🧠 يتذكّر كلّ ما جرّبتموه — ما نفع وما لم ينفع' || v_nl ||
        '🔁 يبني خطوة اليوم على نتيجة أمس، فلا تبدؤون من الصفر أبداً' || v_nl ||
        '📊 يعدّ ما يتكرّر ويريكم ما لم تروه: «هذه ثالث مرّة هذا الأسبوع»' || v_nl ||
        '🌙 سؤال واحد في المساء، وجوابكم ضغطة زر' || v_nl ||
        '🤍 ويرى تعبكم أنتم — فحين تكونون منهكين يخفّف ولا يطلب' || v_nl ||
        '🔒 وما تقولونه يبقى لكم وحدكم — تطلبون محوه فيُمحى كلّه' || v_nl || v_nl ||
        -- Effort, minimised, and the honest edge of the ٢٩ told
        -- as relief rather than as a condition.
        '⏱️ وكم يأخذ من وقتكم؟' || v_nl ||
        'دقيقة أو دقيقتان في اليوم، لا أكثر.' || v_nl ||
        'واليوم الذي لا تحتملونه لا يُحسب عليكم.' || v_nl || v_nl ||
        -- One guarantee.
        '🛡️ الضمان' || v_nl ||
        'نتّفق قبل أن نبدأ على هدف واضح ترونه بأعينكم.' || v_nl ||
        'وإن لم نصل إليه في المدّة، أُكمل معكم نصف المدّة كاملةً مجاناً حتى نصل.' || v_nl || v_nl ||
        '💰 المرافقة الكاملة: ' || (v_cs->>'price') || '، لمدّة ٢٩ يوماً' || v_nl || v_nl ||
        -- The boundary, stated before they tap and discover it.
        '📌 التفاصيل وطريقة الدفع مع فريق آدم — أنا لا أتولّى هذا الجزء، ولا أستطيع الإجابة عنه.';

      v_buttons := jsonb_build_array(
        jsonb_build_object(
          'label', case when v_name is null then '📞 أتحدّث مع فريق آدم'
                        else '📞 أتحدّث مع فريق آدم عن ' || v_name end,
          'url',   'https://t.me/Abdouleg'),
        jsonb_build_object('label', '🌿 ليس الآن — نكمل مجاناً', 'cb', 'menu_not_now'));

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
        'والرحلات المدفوعة لم تصل بلدكم بعد، لسبب واحد:' || v_nl ||
        'لا تتوفّر بعد طريقة دفع محلية نثق بها ونستطيع دعمها كما ينبغي.' || v_nl ||
        'وحين تتوفّر، تصلكم رسالة.';
      v_buttons := '[{"label":"🔔 أخبروني حين تصل","cb":"waitlist_join"},{"label":"💬 عندي موقف آخر","cb":"other"}]'::jsonb;
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
  'One moment, ready to send: body, buttons, and whether commerce is allowed to show it. A button may carry `url` instead of `cb` — the offer''s call to action is a link button to فريق آدم, because ADAM is forbidden to discuss terms or price and must not be the one asked. menu_journey is composed here because the price, the country and the child''s name are per-parent.';

commit;
