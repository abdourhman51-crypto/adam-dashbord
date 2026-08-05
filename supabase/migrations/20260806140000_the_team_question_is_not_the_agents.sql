-- ============================================================
-- A question for فريق آدم is not a question for آدم.
--
-- A parent asked «اريد ان اعرف بخصوص المرافقة الكاملة» and the
-- model answered, at length, and invented this:
--
--     «وسيتواصلون معكم لتوضيح كل شيء قريباً»
--
-- Nobody is going to contact them. Nothing schedules that, and
-- no human was told. The reply also carried no link, so a parent
-- who wanted to buy was left with a promise that will not arrive
-- and no way to act. That is the worst possible outcome on the
-- one turn where a parent has raised their own hand.
--
-- The prompt already forbids quoting a price. It cannot forbid
-- inventing a follow-up, because the failure is not vocabulary —
-- it is that the model is answering a question it has no facts
-- for. The fix is to stop asking it.
--
-- `is_team_question()` recognises the shape, and the reply
-- becomes a fixed moment with the فريق آدم button on it. The
-- model never sees the turn, so it cannot embellish it.
--
-- ------------------------------------------------------------
-- Precision over reach, deliberately
--
-- Every token here is one that practically cannot appear in a
-- parent describing their evening. The dangerous near-misses
-- were left OUT on purpose, and the test file holds them as
-- cases:
--
--   «بكم»    — «أهلاً بكم». Not a price question. Excluded;
--              «بكام» (Egyptian) is kept.
--   «شحال»   — «شحال من مرة قلت له». A count, not a price.
--              Excluded; «بشحال» is kept.
--   «الدفع»  — «الدفع بين الإخوة» is pushing, not paying.
--              Excluded; «طريقة الدفع» and «كيف أدفع» are kept.
--   «رحلة»   — a real journey to the grandmother's house.
--              Excluded; «المرافقة الكاملة» is exact.
--
-- A missed phrasing costs one ordinary reply, and the prompt's
-- own rule still tells ADAM to hand the question over. A false
-- positive costs a parent being brushed off with a sales card
-- while they are telling us their child hit someone. The two
-- errors are not symmetrical, so neither is the list.
--
-- ------------------------------------------------------------
-- And the prompt gets SHORTER
--
-- The worked example teaching the model how to answer «كم يكلّف
-- هذا؟» is deleted from `docs/prompts/adam-conversation-agent.md`
-- in the same change: the turn no longer reaches the model, and
-- every line of a system prompt is a line that can be misapplied
-- somewhere else. The prohibition stays as a backstop for the
-- phrasings this function does not catch.
-- ============================================================

begin;

-- ------------------------------------------------------------
-- is_team_question — does this belong to the humans?
-- ------------------------------------------------------------
create or replace function public.is_team_question(p_text text)
returns boolean
language sql
immutable
set search_path to 'pg_catalog','public'
as $function$
  select exists (
    select 1
    from unnest(array[
      -- the product, by name
      'المرافقة الكاملة','المرافقة المدفوعة','الرحلة المدفوعة','النسخة المدفوعة',
      'فريق آدم',
      -- joining and paying for it
      'اشتراك','الاشتراك','أشترك','اشترك','نشترك','تشترك',
      'الانضمام','كيف أنضم','كيف انضم',
      -- what it costs
      'السعر','سعرها','سعره','الثمن','ثمنها','ثمنه',
      'التكلفة','كم يكلف','كم يكلّف','كم تكلفة',
      'بشحال','بقداش','بكام',
      -- how to pay: only phrasings that cannot mean pushing
      'طريقة الدفع','طرق الدفع','وسائل الدفع','وسيلة الدفع',
      'كيف أدفع','كيف ادفع','كيفاش ندفع','كيفاش نخلص','وين ندفع','أين أدفع',
      'فيزا','بريدي موب','تحويل بنكي','باي بال',
      'فاتورة','الفاتورة'
    ]) as w
    where coalesce(p_text, '') like '%' || w || '%'
  );
$function$;

comment on function public.is_team_question(text) is
  'Whether a parent''s message is about the paid journey, joining it, or paying for it — the things ADAM has no facts for and must not answer. Tuned for precision, not reach: a missed phrasing costs one ordinary reply, a false positive hands a sales card to a parent describing a hard night.';


-- ------------------------------------------------------------
-- The answer. Composed, so it can carry the child's name — the
-- handover must not read as a door closing.
-- ------------------------------------------------------------
insert into public.conversation_moments
  (key, category, tier, body_ar, buttons, max_lines, requires_commerce, note)
values
  ('menu_ask_team', 'reference', 'composed', null,
   '[]'::jsonb, 4, false,
   'The answer to any question about the paid journey, joining it, or paying for it. Fixed on purpose: the model has no facts here and, asked anyway, invented a follow-up call nobody had scheduled. Composed rather than stored so it can name the child — the handover must read as "they will answer you better", not as a door closing. Buttons are built in get_conversation_moment because the فريق آدم link is a url button.')
on conflict (key) do update
  set category = excluded.category, tier = excluded.tier,
      body_ar = excluded.body_ar, buttons = excluded.buttons,
      max_lines = excluded.max_lines, note = excluded.note;


-- ------------------------------------------------------------
-- compose_menu_body learns the one new surface.
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
  if p_parent_id is null then
    -- menu_ask_team must still answer when we know nothing at all: it is
    -- reachable from a first message, before any child exists.
    if p_key = 'menu_ask_team' then
      return '🤝 هذا الجزء يتولّاه فريق آدم' || v_nl ||
             'كلّ ما يخصّ المرافقة الكاملة — التفاصيل والمدّة وطريقة الدفع — يشرحونه لكم بأنفسهم، وأنا لا أتولّاه.' || v_nl || v_nl ||
             'ونحن هنا كما نحن، نكمل في أيّ وقت.';
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

  if p_key = 'menu_ask_team' then
    return '🤝 هذا الجزء يتولّاه فريق آدم' || v_nl ||
           'كلّ ما يخصّ المرافقة الكاملة — التفاصيل والمدّة وطريقة الدفع — يشرحونه لكم بأنفسهم، وأنا لا أتولّاه.' || v_nl || v_nl ||
           'ونحن هنا كما نحن، نكمل مع ' || v_who || ' في أيّ وقت.';
  end if;

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


-- ------------------------------------------------------------
-- get_conversation_moment gives menu_ask_team the one button
-- that matters. A handover with no link is the reply that
-- started this.
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

  select nullif(btrim(c.name), '') into v_name
  from public.children c where c.follower_id = p_parent_id
  order by c.is_primary desc nulls last, c.created_at limit 1;
  v_who := coalesce(v_name, 'طفلكم');

  if p_key = 'menu_journey' then
    v_cs := public.country_state(p_parent_id);

    if (v_cs->>'state') = 'supported' then
      v_body :=
        '🌿 المجاني يبقى مجانياً، بلا نقص' || v_nl ||
        'احكوا لي ما حدث في أيّ وقت، وأعطيكم خطوة صغيرة تناسب موقفكم اليوم.' || v_nl ||
        'هذا لكم دائماً، ولن ينقص منه شيء.' || v_nl || v_nl ||
        'لكن أحياناً لا تكون المشكلة في هذا اليوم —' || v_nl ||
        'بل في أنّ الموقف نفسه يتكرّر، ويستنزفكم مرّة بعد مرّة.' || v_nl ||
        'ولهذا وُجدت المرافقة الكاملة.' || v_nl || v_nl ||
        '🎯 خلال ٢٩ يوماً' || v_nl ||
        'لا أعدكم بطفلٍ مثالي.' || v_nl ||
        'لكن أعدكم أن نعمل معاً على مشكلة واحدة تختارونها أنتم، حتى نصل إلى نتيجة نتّفق عليها قبل أن نبدأ:' || v_nl ||
        '🌙 نوم بلا معركة' || v_nl ||
        '🔥 نوبات غضب أقلّ' || v_nl ||
        '🗣️ صراخ أقلّ في البيت' || v_nl ||
        '🎒 أو ما تشعرون أنّه الأثقل عليكم اليوم' || v_nl || v_nl ||
        '✨ ولماذا آدم بالذات؟' || v_nl ||
        'لأنّه لا يعطيكم نصيحة عامّة، بل خطوة مصنوعة ل' || v_who || ' وحده:' || v_nl ||
        '👦 يعرف ' || v_who || ': عمره، وأصعب ساعة في يومه، وما الذي يهدّئه' || v_nl ||
        '🧠 يتذكّر كلّ ما جرّبتموه — ما نفع وما لم ينفع' || v_nl ||
        '🔁 يبني خطوة اليوم على نتيجة أمس، فلا تبدؤون من الصفر أبداً' || v_nl ||
        '📊 يعدّ ما يتكرّر ويريكم ما لم تروه: «هذه ثالث مرّة هذا الأسبوع»' || v_nl ||
        '🌙 سؤال واحد في المساء، وجوابكم ضغطة زر' || v_nl ||
        '🤍 ويرى تعبكم أنتم — فحين تكونون منهكين يخفّف ولا يطلب' || v_nl ||
        '🔒 وما تقولونه يبقى لكم وحدكم — تطلبون محوه فيُمحى كلّه' || v_nl || v_nl ||
        '⏱️ وكم يأخذ من وقتكم؟' || v_nl ||
        'دقيقة أو دقيقتان في اليوم، لا أكثر.' || v_nl ||
        'واليوم الذي لا تحتملونه لا يُحسب عليكم.' || v_nl || v_nl ||
        '🛡️ الضمان' || v_nl ||
        'نتّفق قبل أن نبدأ على هدف واضح ترونه بأعينكم.' || v_nl ||
        'وإن لم نصل إليه في المدّة، أُكمل معكم نصف المدّة كاملةً مجاناً حتى نصل.' || v_nl || v_nl ||
        '💰 المرافقة الكاملة: ' || (v_cs->>'price') || '، لمدّة ٢٩ يوماً' || v_nl || v_nl ||
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

  elsif p_key = 'menu_ask_team' then
    v_body := public.compose_menu_body(p_key, p_parent_id);
    -- The unsupported-country case must not be handed a link to buy
    -- something that is not for sale where they live.
    v_cs := public.country_state(p_parent_id);
    if p_parent_id is not null and (v_cs->>'state') = 'unsupported' then
      v_buttons := jsonb_build_array(
        jsonb_build_object('label','🔔 أخبروني حين تصل','cb','waitlist_join'),
        jsonb_build_object('label','💬 نكمل مع ' || v_who, 'cb','other'));
    else
      v_buttons := jsonb_build_array(
        jsonb_build_object('label','📞 أتحدّث مع فريق آدم','url','https://t.me/Abdouleg'),
        jsonb_build_object('label','💬 نكمل مع ' || v_who, 'cb','other'));
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
-- get_agent_bundle answers it before the model is asked.
--
-- The team check runs FIRST, ahead of the intention capture.
-- «اشتراك» is short, has no question mark and is three lines
-- shorter than the limit — capture_intention would have written
-- it into the parent's intention, permanently, as who they
-- hoped to be.
--
-- `handled` generalises what `intention_captured` started: the
-- bundle answered this turn itself, and the model must not run.
-- The old keys stay so nothing that reads them breaks.
-- ------------------------------------------------------------
create or replace function public.get_agent_bundle(
  p_follower_id uuid, p_message text)
returns jsonb
language plpgsql
volatile
security definer
set search_path to 'pg_catalog','public'
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

  -- PLAN_DAY / DAYS_LEFT are ours, not theirs.
  --
  -- The trim character set is not decoration. Single-argument btrim() removes
  -- SPACES ONLY, so stripping those two lines left a bare newline behind, the
  -- context tested as non-empty, and a parent ADAM knows nothing about got an
  -- empty block instead of the sentence saying so — a machine that looks like
  -- it is withholding rather than one that is honest about knowing nothing.
  v_ctx := btrim((
    select coalesce(string_agg(l, chr(10)), '')
    from regexp_split_to_table(v_ctx, chr(10)) l
    where l !~ '^\s*(PLAN_DAY|DAYS_LEFT)\s*:'), E' \t\r\n');

  v_kd    := public.knowledge_depth(p_follower_id);
  v_level := coalesce((v_kd->>'level')::int, 0);

  v_perm := case v_level
    when 0 then 'لا تعرف عن هذا البيت شيئاً بعد. أجب عن اللحظة التي أمامك فقط، ولا تُلمّح إلى أنك تتذكّر شيئاً.'
    when 1 then 'تعرف اسم الطفل فقط. استعمله بطبيعية، ولا تدّعِ معرفة بما يتكرّر معه.'
    when 2 then 'تعرف الاسم وما يُتعب عادةً. يمكنك أن تقترح شيئاً صغيراً موجّهاً لذلك الموقف بالذات.'
    when 3 then 'تعرف ما يتكرّر فعلاً. يمكنك أن تذكر ما لاحظتَه مرّة واحدة، بلا مبالغة.'
    else        'تعرف هذا البيت جيّداً. يمكنك أن تسمّي هدفاً واضحاً إن كان الوقت مناسباً.'
  end;

  v_known := case when v_ctx = '' then 'لا شيء مسجّل عن هذا البيت بعد.' else v_ctx end;

  v_ask := public.take_country_ask(p_follower_id);

  return jsonb_build_object(
    'context',         v_ctx,
    'knowledge_level', v_level,
    -- One block, framed as OUR notes. Without the frame the model reads its
    -- own context as something the parent just said and answers a question
    -- nobody asked.
    'family_context',
      '[ما نعرفه عن هذا البيت — ملاحظاتنا نحن، لم يقلها الأهل الآن]' || chr(10)
      || v_known || chr(10) || chr(10)
      || '[ما يُسمح لك أن تدّعي معرفته]' || chr(10) || v_perm,
    'ask',         coalesce((v_ask->>'ask')::boolean, false),
    'ask_body',    v_ask->>'body',
    'ask_buttons', coalesce(v_ask->'buttons', '[]'::jsonb),
    'handled', false,
    'intention_captured', false);
end;
$function$;

comment on function public.get_agent_bundle(uuid, text) is
  'The one authenticated call the reply path makes per message. Before building any context it decides whether the bundle should answer the turn itself — a question for فريق آدم, or the answer to the once-ever intention question — and if so returns `handled` with the exact body and buttons to send, so the model never sees a turn it has no facts for.';

revoke all on function public.is_team_question(text) from anon, authenticated, public;
grant execute on function public.is_team_question(text) to service_role;

commit;
