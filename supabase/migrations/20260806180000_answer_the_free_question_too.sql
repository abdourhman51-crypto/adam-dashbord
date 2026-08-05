-- ============================================================
-- «هل انت مجاني» is the same question, and it was falling through.
--
-- Three messages, one turn apart:
--
--   «اريد ان اعرف بخصوص المرافقة الكاملة»  → caught
--   «بكم الاشتراك»                          → caught
--   «هل انت مجاني»                          → NOT caught
--
-- The third has no word about a price, a subscription or paying, so
-- `is_team_question` let it through and the model answered with the
-- one line the prompt allows — correct, and useless, because it
-- carries no link.
--
-- It is the same question. A parent asking whether ADAM is free is
-- asking what they get for nothing and what costs money. That it
-- reached the model at all was the gap.
--
-- ------------------------------------------------------------
-- And the answer was wrong in shape, not only in reach
--
-- The handover said «هذا يتولّاه فريق آدم» and nothing else. To
-- «هل انت مجاني» that is close to a refusal: the parent asked
-- whether they owe anything, and ADAM declined to say.
--
-- ADAM *can* answer that half. What is free is not a commercial
-- term he has no facts for — it is the relationship he is in. So
-- the moment now answers plainly first, and hands over only the
-- half that is genuinely the team's:
--
--   🌿 كل ما بيننا الآن مجاني، ويبقى مجانياً.   ← he knows this
--   🤝 وهناك مرافقة كاملة… يتولّاها فريق آدم    ← he does not
--
-- One moment now serves all three messages, and every one of them
-- ends with the link.
--
-- ------------------------------------------------------------
-- The tokens, and the ones still left out
--
-- `تدفع` is NOT added, and that is the whole discipline of this
-- list in one word: «تدفعه للنوم» is a parent pushing a child
-- towards bed. `فلوس` is not added either — «يطلب فلوس كل يوم» is
-- pocket money, an ordinary thing to be tired about.
-- ============================================================

begin;

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
      'فاتورة','الفاتورة',
      -- and «is this free?», which is the same question asked from
      -- the other side. `تدفع` and `فلوس` stay out: «تدفعه للنوم» is
      -- a parent pushing a child, and «يطلب فلوس» is pocket money.
      'مجاني','مجانا','مجاناً','بالمجان','المجاني',
      'مدفوع','مدفوعة','المدفوعة','مقابل مادي','بلا مقابل'
    ]) as w
    where coalesce(p_text, '') like '%' || w || '%'
  );
$function$;

comment on function public.is_team_question(text) is
  'Whether a parent''s message is about the paid journey, joining it, paying for it, or whether ADAM costs anything — the things ADAM either has no facts for or must answer with the team''s link attached. Tuned for precision, not reach: a missed phrasing costs one ordinary reply, a false positive hands a sales card to a parent describing a hard night.';

update public.conversation_moments
set max_lines = 6,
    note = 'The answer to any question about the paid journey, joining it, paying for it, or whether ADAM is free. Answers the free half plainly — that is the relationship he is in, not a commercial term he lacks facts for — and hands over only the half that is genuinely the team''s. Fixed on purpose: asked to explain the paid side, the model invented a follow-up call nobody had scheduled. Composed so it can name the child; buttons are built in get_conversation_moment because the فريق آدم link is a url button.'
where key = 'menu_ask_team';

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
    if p_key = 'menu_ask_team' then
      return '🌿 كل ما بيننا الآن مجاني، ويبقى مجانياً.' || v_nl ||
             'احكوا لي ما حدث في أيّ وقت، وأعطيكم خطوة صغيرة تناسب موقفكم — بلا مقابل.' || v_nl || v_nl ||
             '🤝 وهناك مرافقة كاملة لمن أرادها، يتولّاها فريق آدم وحده.' || v_nl ||
             'كلّ تفاصيلها — المدّة والسعر وطريقة الدفع — يشرحونها لكم بأنفسهم، وأنا لا أتولّاها.' || v_nl || v_nl ||
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
    return '🌿 كل ما بيننا الآن مجاني، ويبقى مجانياً.' || v_nl ||
           'احكوا لي ما حدث في أيّ وقت، وأعطيكم خطوة صغيرة تناسب موقفكم — بلا مقابل.' || v_nl || v_nl ||
           '🤝 وهناك مرافقة كاملة لمن أرادها، يتولّاها فريق آدم وحده.' || v_nl ||
           'كلّ تفاصيلها — المدّة والسعر وطريقة الدفع — يشرحونها لكم بأنفسهم، وأنا لا أتولّاها.' || v_nl || v_nl ||
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

commit;
