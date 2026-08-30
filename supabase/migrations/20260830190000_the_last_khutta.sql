begin;

-- ============================================================
-- آخر أثر لكلمة «خطة» في كلام يواجه الوالد مباشرةً.
--
-- زر تفعيل المرافقة («📞 نُفعّل خطة يوسف مع الفريق») لم يكن
-- صفّاً في conversation_moments ولا نصّ body_ar، بل تسمية زرّ
-- مبنيّة داخل الدالة نفسها — فأفلتت من كل الفحوصات التي بنيناها
-- (chk_body_clean يفحص body_ar فقط، لا buttons). القانون لا
-- يفرّق: الكلمة ممنوعة في أي نصّ يصل الوالد، زرّاً كان أو جملة.
-- ============================================================

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

commit;
