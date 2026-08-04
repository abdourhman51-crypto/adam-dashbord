begin;

-- ============================================================
-- Three countries, and a third answer that did not exist.
--
-- The offer is live in exactly three places — الجزائر، مصر،
-- المغرب — and nowhere else. That is a founder constraint, not
-- an engineering one, and it is enforced in ONE place:
-- supported_countries.is_active AND a price. Adding a fourth
-- country is a row, not a deploy.
--
-- WHAT WAS MEASURED, AND WHY THIS IS NOT A REFACTOR
--
--   supported     133   DZ 62 · EG 62 · MA 9
--   unsupported   109   SY IQ JO AE LY SA TN PS LB FR
--   unknown        59   'ZZ' 33 · empty 26
--
-- Twenty percent of every parent ADAM has ever met was being
-- told «الرحلات المدفوعة لم تصل بلدكم بعد» — a sentence about
-- a country we do not know. It is not a soft inaccuracy. It is
-- ADAM stating a fact he does not have (P11), and it silently
-- excluded 59 families from the daily rhythm too, because
-- get_rhythm_due joins country_timezone and an unknown code
-- joins to nothing.
--
-- «غير مدعوم» و«لا نعرف» حالتان مختلفتان، وكانتا واحدة.
--
-- WHY 'ZZ' IS NOT A COUNTRY
--
-- 'ZZ' is the placeholder an earlier import wrote when Telegram
-- gave no locale. It is well-formed, it passes every NOT NULL
-- check, and it means nothing. Treating it as a country is how
-- 33 families ended up with a confident answer about a place
-- that does not exist. Membership in country_timezone is the
-- test, because that table is the one that has to put them on a
-- clock — if we cannot tell them what hour it is where they
-- are, we do not know where they are.
-- ============================================================


-- ------------------------------------------------------------
-- country_state — one function, three answers, no fourth.
--
-- Returns state ∈ {supported, unsupported, unknown} plus the
-- price and the Arabic name, so no caller ever reads
-- supported_countries directly and no caller ever holds a price.
-- ------------------------------------------------------------
create or replace function public.country_state(p_parent_id uuid)
returns jsonb
language sql
stable
security definer
set search_path to 'pg_catalog','public'
as $function$
  with f as (
    select nullif(btrim(upper(coalesce(country,''))), '') as code
    from public.followers where id = p_parent_id
  ),
  k as (
    select f.code,
           -- Known = a real place we can put on a clock. 'ZZ' is a
           -- placeholder somebody wrote, not a country.
           (f.code is not null and f.code <> 'ZZ'
            and exists (select 1 from public.country_timezone ct where ct.code = f.code)) as known
    from f
  )
  select jsonb_build_object(
    'code',      k.code,
    'known',     k.known,
    'supported', k.known and exists (
                   select 1 from public.supported_countries sc
                   where sc.code = k.code and coalesce(sc.is_active,false)
                     and sc.price_display_full is not null),
    'state',     case when not k.known then 'unknown'
                      when exists (select 1 from public.supported_countries sc
                                    where sc.code = k.code and coalesce(sc.is_active,false)
                                      and sc.price_display_full is not null) then 'supported'
                      else 'unsupported' end,
    'price',     (select sc.price_display_full from public.supported_countries sc
                   where sc.code = k.code and coalesce(sc.is_active,false)),
    'name_ar',   (select sc.name_ar from public.supported_countries sc where sc.code = k.code))
  from k;
$function$;

comment on function public.country_state(uuid) is
  'Where a parent is, in the only three states that change what ADAM may say: supported, unsupported, unknown. An active row with a price is the single definition of "supported" — a fourth country is a row, not a deploy. ZZ and empty are unknown, never unsupported: telling 59 families their country is not served when we do not know their country is a statement we cannot stand behind (P11).';


-- ------------------------------------------------------------
-- record_country — the one identity fact that IS overwritable.
--
-- The child's name is written once and never overwritten,
-- because a second name is almost always a mistake. A country
-- is the opposite: families move, and the code we hold came
-- from a Telegram locale guess, not from them. When a parent
-- tells us where they are, they outrank the guess — every time.
--
-- A code we cannot put on a clock is refused rather than
-- stored. Storing it would replace one unknown with a
-- confident-looking unknown.
-- ------------------------------------------------------------
create or replace function public.record_country(p_parent_id uuid, p_code text)
returns jsonb
language plpgsql
security definer
set search_path to 'pg_catalog','public'
as $function$
declare v_code text;
begin
  v_code := nullif(btrim(upper(coalesce(p_code,''))), '');
  if v_code is null or v_code = 'ZZ'
     or not exists (select 1 from public.country_timezone ct where ct.code = v_code) then
    return jsonb_build_object('ok', false, 'reason', 'unknown_code');
  end if;

  update public.followers set country = v_code where id = p_parent_id;
  if not found then
    return jsonb_build_object('ok', false, 'reason', 'no_such_parent');
  end if;

  return public.country_state(p_parent_id) || jsonb_build_object('ok', true);
end;
$function$;

comment on function public.record_country(uuid, text) is
  'A parent naming their own country. Overwritable, unlike the child''s name: the stored code was a locale guess and families move. Refuses any code that is not in country_timezone — an unknown we cannot act on must stay an unknown.';


-- ------------------------------------------------------------
-- get_conversation_moment — /journey answers all three states.
--
-- It had two branches for three states, so the third fell into
-- the "not yet in your country" answer by default. Defaults are
-- where honesty leaks out of a product.
--
-- The unknown branch does not apologise and does not explain the
-- machine (P24). It asks the one question whose answer changes
-- what we are allowed to say — and the same answer unblocks the
-- daily rhythm, which cannot write at an honest hour without a
-- local clock.
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
        'المرافقة اليومية التي بيننا الآن تبقى كما هي — مجاناً، دائماً.' || v_nl || v_nl ||
        'وحين يظهر هدف واضح لطفلكم — ليالٍ أهدأ، أو صباح بلا معركة —' || v_nl ||
        'يمكن أن نبني له رحلة: نمشي إليه يوماً بيوم حتى نصل،' || v_nl ||
        'أو حتى نعرف أنه لا يصلح، وأقولها لكم بصراحة.' || v_nl || v_nl ||
        'الرحلة الواحدة: ' || (v_cs->>'price') || '.' || v_nl || v_nl ||
        'التفاصيل وطرق الدفع — فريق آدم يسعده مساعدتكم:' || v_nl ||
        'https://t.me/Abdouleg';
      v_buttons := '[]'::jsonb;

    elsif (v_cs->>'state') = 'unknown' then
      -- We do not know where they are. Saying "not yet in your country"
      -- here would be a sentence we cannot stand behind. Ask instead —
      -- and the answer also unblocks the daily rhythm, which needs a
      -- local clock before it can write at an honest hour.
      v_body :=
        'المرافقة الكاملة تختلف من بلد لآخر — السعر وطريقة الدفع محليّان.' || v_nl || v_nl ||
        'من أي بلد أنتم؟';
      v_buttons := jsonb_build_array(
        jsonb_build_object('label','الجزائر',  'cb','set_country_DZ'),
        jsonb_build_object('label','مصر',     'cb','set_country_EG'),
        jsonb_build_object('label','المغرب',   'cb','set_country_MA'),
        jsonb_build_object('label','بلد آخر', 'cb','set_country_OTHER'));

    else
      v_body :=
        'آدم يرافقكم بالكامل، كما يرافق الجميع.' || v_nl ||
        'كل ما بيننا الآن يبقى كما هو، دون نقص.' || v_nl || v_nl ||
        'والرحلات المدفوعة لم تصل بلدكم بعد، لسبب واحد:' || v_nl ||
        'لا تتوفّر بعد طريقة دفع محلية نثق بها ونستطيع دعمها كما ينبغي.' || v_nl ||
        'وحين تتوفّر، تصلكم رسالة.';
      v_buttons := '[{"label":"أخبروني حين يصل","cb":"waitlist_join"},{"label":"شيء آخر","cb":"other"}]'::jsonb;
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
-- compose_menu_body — the answer after a parent names a country.
--
-- The country question is only ever asked because a parent asked
-- about the journey. So the confirmation must ANSWER that
-- question in the same breath. A bare «سجّلنا بلدكم» would make
-- them ask twice — the interface charging them for helping us.
--
-- All three states are handled here too, including the one that
-- should be impossible: record_country refuses unknown codes, so
-- 'unknown' after a recording means the write did not land. It
-- says so plainly and does not pretend.
-- ------------------------------------------------------------
create or replace function public.compose_menu_body(
  p_key       text,
  p_parent_id uuid)
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
  v_cs jsonb;
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
          || 'الرحلة الواحدة عندكم: ' || (v_cs->>'price') || '.' || v_nl
          || 'وكل ما بيننا الآن يبقى مجانياً، دائماً.' || v_nl || v_nl
          || 'التفاصيل وطرق الدفع — فريق آدم:' || v_nl || 'https://t.me/Abdouleg';
    elsif (v_cs->>'state') = 'unknown' then
      return 'لم أتعرّف على البلد.' || v_nl
          || 'لا بأس — كل ما بيننا يبقى كما هو.';
    else
      return 'سجّلنا بلدكم.' || v_nl || v_nl
          || 'والرحلات المدفوعة لم تصل إليه بعد، لسبب واحد:' || v_nl
          || 'لا تتوفّر بعد طريقة دفع محلية نثق بها.' || v_nl
          || 'وحين تتوفّر، تصلكم رسالة.';
    end if;
  end if;

  select coalesce((now() at time zone ct.iana_tz)::date, current_date) into v_today
  from public.country_timezone ct where ct.code = v_country;
  v_today := coalesce(v_today, current_date);

  select c.id, nullif(btrim(c.name), ''), nullif(btrim(c.age_note), '')
    into v_child, v_name, v_age
  from public.children c where c.follower_id = p_parent_id
  order by c.is_primary desc nulls last, c.created_at limit 1;

  if p_key = 'menu_child' then
    if v_name is null then
      return 'لم نتعرّف على طفلكم بعد.' || v_nl
          || 'اكتبوا اسمه، وما أكثر ما يتعب معه هذه الأيام.';
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

    v_lines := array[v_name || coalesce(' · ' || v_age, '')];
    if v_sit is not null then
      v_lines := v_lines || ('الأصعب عادةً: ' || v_sit || '.')::text;
    end if;
    if v_pat is not null then
      v_lines := v_lines || v_pat::text;
    elsif v_sit is null then
      v_lines := v_lines || 'لم نتبيّن بعد ما يتكرّر معه. احكوا لي عن يومكم.'::text;
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
      return 'لم نجرّب شيئاً معاً بعد.' || v_nl
          || 'نبدأ من اليوم — احكوا لي ما حدث.';
    elsif v_ever < 3 then
      return 'جرّبتم ' || public.ar_occasions(v_ever) || ' حتى الآن.' || v_nl
          || 'نحتاج ثلاثاً حتى نرى ما يتكرّر.';
    end if;

    v_lines := array['هذا الأسبوع: جرّبتم ' || public.ar_occasions(v_tried) || '.'];

    if v_calm > 0 then
      v_lines := v_lines || (case
        when v_calm = 1 then 'واحدة منها مرّت بهدوء.'
        when v_calm = 2 then 'اثنتان منها مرّتا بهدوء.'
        else public.ar_digits(v_calm::text) || ' منها مرّت بهدوء.' end)::text;
    else
      v_lines := v_lines || 'ولم تمرّ أيّ منها بهدوء بعد.'::text;
    end if;

    v_lines := v_lines || (case
      when v_tried > v_prev then 'وهذا أكثر من الأسبوع الماضي.'
      when v_tried < v_prev then 'أسبوع أثقل. المحاولة نفسها تُحسب.'
      else                       'ثابتون. نكمل.' end)::text;

    return array_to_string(v_lines, v_nl);
  end if;

  return null;
end;
$function$;


-- ------------------------------------------------------------
-- The two moments the country question needs.
--
-- country_other is deliberately the SAME text as the unsupported
-- journey answer. A parent who taps «بلد آخر» is not asked which
-- one: the country decides payment and only payment, and payment
-- is unavailable either way. Asking would be collecting a fact we
-- cannot act on — which is the definition of a form, and ADAM is
-- not a form.
-- ------------------------------------------------------------
insert into public.conversation_moments
  (key, category, tier, body_ar, buttons, max_lines, requires_commerce, note)
values
  ('country_recorded', 'reference', 'composed', null, '[]'::jsonb, 6, false,
   'Confirms the country a parent just chose, then answers the journey question for real. Composed because the answer differs per country and the price is never stored outside supported_countries.'),
  ('country_other', 'reference', 'fixed',
   'آدم يرافقكم بالكامل، كما يرافق الجميع.' || chr(10) ||
   'كل ما بيننا الآن يبقى كما هو، دون نقص.' || chr(10) || chr(10) ||
   'والرحلات المدفوعة لم تصل بلدكم بعد، لسبب واحد:' || chr(10) ||
   'لا تتوفّر بعد طريقة دفع محلية نثق بها ونستطيع دعمها كما ينبغي.' || chr(10) ||
   'وحين تتوفّر، تصلكم رسالة.',
   '[{"label":"أخبروني حين يصل","cb":"waitlist_join"},{"label":"شيء آخر","cb":"other"}]'::jsonb,
   6, false,
   'Chosen «بلد آخر» at the journey question. We do not press for which: the country decides payment only, and payment is unavailable either way. Pressing would be collecting data we cannot act on.')
on conflict (key) do update
  set category = excluded.category, tier = excluded.tier,
      body_ar = excluded.body_ar, buttons = excluded.buttons,
      max_lines = excluded.max_lines, note = excluded.note;



-- ------------------------------------------------------------
-- get_telegram_surface — the same three states, on the pinned surface.
--
-- The surface computed its own boolean. Two functions answering the
-- same question in two different ways is how the answers diverge, and
-- this pair had already diverged in the only way that matters: one of
-- them could say "unknown" and the other could not.
--
-- Nothing consumed the flag yet, so this fixes no live symptom. That
-- is the reason to do it now rather than later — a trap with no
-- consumer is cheap to remove and expensive to find.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_telegram_surface(p_parent_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_platform_user_id text; v_country text; v_local_date date;
  v_child_id uuid; v_child_name text;
  v_sit_id uuid; v_sit_key text; v_sit_status text; v_sit_label text;
  v_stage_id uuid; v_stage_status text; v_stage_problem text; v_had_stage boolean;
  v_nights_result integer; v_human_messages integer; v_last_message_at timestamptz;
  v_calm7 integer; v_logged7 integer;
  v_paused boolean; v_dormant boolean; v_strain smallint;
  v_commerce boolean; v_country_state text;
  v_state text;
  v_progress text; v_pinned text[]; v_goal_label text;
begin
  select f.platform_user_id, upper(btrim(f.country))
    into v_platform_user_id, v_country
  from public.followers f where f.id = p_parent_id;

  if not found then
    return jsonb_build_object('exists', false, 'parent_id', p_parent_id);
  end if;

  select coalesce((now() at time zone ct.iana_tz)::date, current_date) into v_local_date
  from public.country_timezone ct where ct.code = v_country;
  v_local_date := coalesce(v_local_date, current_date);

  -- Three states, from the one function that knows them. This used to be a
  -- boolean computed here, which meant a parent whose country we did not
  -- know reported country_supported=false -- indistinguishable from a
  -- parent in a country we have decided not to sell in.
  v_country_state := public.country_state(p_parent_id)->>'state';

  select c.id, nullif(btrim(c.name), '') into v_child_id, v_child_name
  from public.children c where c.follower_id = p_parent_id
  order by c.is_primary desc nulls last, c.created_at limit 1;

  select s.id, s.key, s.status into v_sit_id, v_sit_key, v_sit_status
  from public.situations s
  where s.child_id = v_child_id and s.status in ('candidate','confirmed')
  order by (s.status = 'confirmed') desc, s.evidence_count desc, s.last_observed desc
  limit 1;

  v_sit_label := public.situation_label_ar(v_sit_key);

  select st.id, st.status, st.problem_key into v_stage_id, v_stage_status, v_stage_problem
  from public.stages st
  where st.parent_id = p_parent_id and st.status in ('active','extended') limit 1;

  select exists (select 1 from public.stages st2
                  where st2.parent_id = p_parent_id
                    and st2.status in ('completed','failed','refunded')) into v_had_stage;

  select coalesce(e.nights_with_result,0), coalesce(e.human_messages,0), e.last_message_at
    into v_nights_result, v_human_messages, v_last_message_at
  from public.v_parent_engagement e where e.parent_id = p_parent_id;
  v_nights_result := coalesce(v_nights_result,0);
  v_human_messages := coalesce(v_human_messages,0);

  select count(*) filter (where d.night_result is not null),
         count(*) filter (where d.night_result = 'calm')
    into v_logged7, v_calm7
  from public.daily_logs d
  where d.follower_id = p_parent_id
    and d.log_date > v_local_date - 7 and d.log_date <= v_local_date;
  v_logged7 := coalesce(v_logged7,0); v_calm7 := coalesce(v_calm7,0);

  select coalesce(cs.cadence = 'stopped', false)
      or coalesce(cs.paused_until >= v_local_date, false)
    into v_paused
  from public.checkin_state cs where cs.parent_id = p_parent_id;
  v_paused := coalesce(v_paused, false);

  v_dormant := v_last_message_at is not null
           and v_last_message_at < now() - interval '21 days';

  select coalesce(ps.level,1) into v_strain
  from public.parent_strain ps where ps.parent_id = p_parent_id;
  v_strain := coalesce(v_strain, 1);

  v_commerce := coalesce(public.commerce_allowed(p_parent_id), true);

  v_state := case
    when v_child_id is null and v_human_messages <= 1 then 'brand_new'
    when v_child_name is null                         then 'no_child_name'
    when v_stage_id is not null                       then 'journey_active'
    when v_sit_id is null                             then 'no_situation'
    when v_nights_result < 3                          then 'gathering'
    when v_had_stage                                  then 'journey_ended_no_next'
    else                                                   'rhythm'
  end;

  v_goal_label := coalesce(v_sit_label, public.situation_label_ar(v_stage_problem));
  v_progress := public.progress_line(v_nights_result, v_logged7, v_calm7);

  -- Two lines. State, never instruction (L3).
  if v_child_name is null then
    v_pinned := array['📌  ما سجّلناه معاً', v_progress];
  elsif v_goal_label is not null and v_state = 'journey_active' then
    v_pinned := array['📌  ' || v_child_name || ' · نعمل على: ' || v_goal_label, v_progress];
  elsif v_goal_label is not null then
    v_pinned := array['📌  ' || v_child_name || ' · ' || v_goal_label, v_progress];
  else
    v_pinned := array['📌  ' || v_child_name, v_progress];
  end if;

  return jsonb_build_object(
    'exists', true, 'parent_id', p_parent_id, 'platform_user_id', v_platform_user_id,
    'state', v_state,
    'modifiers', jsonb_build_object(
      'paused', v_paused, 'dormant', v_dormant, 'strain_level', v_strain,
      'commerce_allowed', v_commerce,
      'country_state', v_country_state,
      -- Kept for one release so no consumer breaks silently, and it is now
      -- true ONLY for a country we sell in -- never for one we cannot name.
      'country_supported', (v_country_state = 'supported')),
    'child', case when v_child_id is null then null
                  else jsonb_build_object('id', v_child_id, 'name', v_child_name) end,
    'situation', case when v_sit_id is null then null
                      else jsonb_build_object('id', v_sit_id, 'key', v_sit_key,
                                              'label', v_sit_label, 'status', v_sit_status) end,
    'journey', case when v_stage_id is null then null
                    else jsonb_build_object('id', v_stage_id, 'status', v_stage_status,
                                            'problem_key', v_stage_problem) end,
    'keyboard', public.surface_keyboard(v_state),
    'menu', '[]'::jsonb,
    'progress_line', v_progress,
    'pinned', jsonb_build_object('lines', to_jsonb(v_pinned),
                                 'text',  array_to_string(v_pinned, chr(10))));
end;
$function$;


comment on function public.get_telegram_surface(uuid) is
  'Everything the pinned surface needs, in one read. country_state carries the three real states; country_supported is derived from it and kept only so no consumer breaks silently.';

revoke all on function public.country_state(uuid) from anon, authenticated, public;
revoke all on function public.record_country(uuid, text) from anon, authenticated, public;
grant execute on function public.country_state(uuid) to service_role;
grant execute on function public.record_country(uuid, text) to service_role;

commit;
