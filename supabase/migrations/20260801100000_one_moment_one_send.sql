begin;

-- ============================================================
-- One moment function, one send path.
-- (spec: docs/telegram-logic.md — L1, L3, §5.1, §6, §7 R3/R6/R7)
--
-- WHAT WAS WRONG
--
-- Six menu keys were stored as tier='composed' with a null body,
-- and the composition lived in a JavaScript expression inside one
-- n8n node. That node built the SAME two lines for every key it
-- received. So /child and /progress replied identically, and both
-- replied with the text already visible in the pinned message.
--
-- Three surfaces saying one thing is what the founder was seeing
-- when they said the logic contradicts itself. It is not a bug in
-- any one of them; it is copy living outside the copy table.
--
-- WHAT CHANGES
--
-- compose_menu_body() puts every derived body back in SQL beside
-- the fixed ones. get_conversation_moment() now returns a real
-- body for every key, which means the workflow no longer needs to
-- branch on "is this fixed or derived" — there is one send path,
-- and a key that composes to nothing is visible here rather than
-- arriving as silence on a phone.
-- ============================================================


-- ------------------------------------------------------------
-- The two moments that did not exist, and were reached anyway.
--
-- welcome_back: /start currently re-greets a parent three weeks in
--   as a stranger, because the start path has no branch on state.
--   Two lines, and deliberately no summary of what was missed —
--   the pinned message carries that, and repeating it makes coming
--   back feel audited.
--
-- media_unsupported: a photo reached the agent with an empty
--   prompt and died. Honest beats silent (P11).
-- ------------------------------------------------------------
insert into public.conversation_moments
  (key, category, tier, body_ar, buttons, max_lines, note)
values
  ('welcome_back', 'greeting', 'fixed',
   'أنا هنا.' || chr(10) || 'احكِ لي ما حدث.',
   '[]'::jsonb, 2,
   'Repeat /start in any state but brand_new. No recap of the absence: a companion does not bill you for being away.'),

  ('media_unsupported', 'greeting', 'fixed',
   'لا أستطيع رؤية الصور بعد.' || chr(10) || 'لكن صِفي لي ما فيها بكلماتك، وسأفهم.',
   '[]'::jsonb, 2,
   'Photo, sticker, document or video with no caption. Says what is true and hands the turn back.')
on conflict (key) do update
  set body_ar = excluded.body_ar,
      max_lines = excluded.max_lines,
      note      = excluded.note;


-- first_contact: line 3 was a promise about surfaces. It is now the
-- one action she is invited to take (L1). She already knows how to
-- type; that is the whole reason it is the only instruction.
update public.conversation_moments
set body_ar = 'السلام عليكم 🌿' || chr(10)
           || 'أنا آدم — أرافق الأهل مع أطفالهم، يوماً بيوم.' || chr(10)
           || 'احكِ لي ما حدث اليوم مع طفلك، بكلماتك.'
where key = 'first_contact';


-- «شيء آخر» now hosts what the removed menu item used to. An open
-- door, not a list — one line, because a list here would rebuild
-- the navigation this release deletes.
update public.conversation_moments
set tier = 'fixed', max_lines = 1, body_ar = 'احكِ لي ما يشغلك الآن.',
    note = 'The escape hatch required by chk_escape_hatch, and after the in-chat menu was removed, the only thing behind «شيء آخر».'
where key = 'menu_open_question';


-- ------------------------------------------------------------
-- Two functions that existed in production but in no migration.
--
-- They were applied directly in an earlier session and never
-- written to the repo, so a clean checkout could not build the
-- surface. The local fixture caught it on the first run of this
-- change — which is the entire reason the fixture exists. Copied
-- verbatim from production (pg_proc), not from memory.
-- ------------------------------------------------------------
create or replace function public.progress_line(
  p_nights_with_result integer,
  p_logged_this_week   integer,
  p_calm_this_week     integer)
returns text
language sql
immutable
as $function$
  select case
    when coalesce(p_nights_with_result,0) = 0
      then 'لم نسجّل أي ليلة بعد — نبدأ من الليلة.'
    when p_nights_with_result = 1
      then 'سجّلنا ليلة واحدة. نحتاج ثلاثاً حتى نعرف ما يتكرّر.'
    when p_nights_with_result = 2
      then 'سجّلنا ليلتين. نحتاج ثلاثاً حتى نعرف ما يتكرّر.'
    when coalesce(p_logged_this_week,0) = 0
      then 'لم نسجّل أي ليلة هذا الأسبوع.'
    else 'هذا الأسبوع: ' || public.ar_digits(p_calm_this_week::text)
         || ' ليالٍ هادئة من ' || public.ar_digits(p_logged_this_week::text) || ' سجّلناها.'
  end;
$function$;

comment on function public.progress_line(integer, integer, integer) is
  'What we recorded, and what comes next. Replaces "نجمع الصورة" — a parent cannot act on a picture being gathered, but can act on "we need three nights to see what repeats".';

create or replace function public.surface_keyboard(p_state text)
returns jsonb
language sql
immutable
as $function$ select '[]'::jsonb; $function$;

comment on function public.surface_keyboard(text) is
  'Empty by design. Telegram already gives two affordances every user knows: the input field and the ☰ command menu. A persistent button bar was a third list of the same actions. Kept as a function so restoring one is a one-line change.';


-- ------------------------------------------------------------
-- compose_menu_body — the derived bodies, in SQL.
--
-- Returns null for a key it does not compose, which is how
-- get_conversation_moment tells "nothing to say" from "nothing
-- built it yet".
--
-- menu_child answers *who* — it must not repeat the progress line,
-- which is already pinned. menu_progress answers *are we moving* —
-- a comparison, not a count, for the same reason. Two surfaces that
-- say the same sentence teach a parent that one of them is noise.
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
  v_nl      text := chr(10);
  v_country text;
  v_today   date;
  v_child   uuid;
  v_name    text;
  v_age     text;
  v_sit     text;
  v_pat     text;
  v_total   integer;
  v_l7      integer;
  v_c7      integer;
  v_c14     integer;
  v_lines   text[] := '{}';
begin
  if p_parent_id is null then
    return null;
  end if;

  select upper(btrim(f.country)) into v_country
  from public.followers f where f.id = p_parent_id;
  if not found then
    return null;
  end if;

  select coalesce((now() at time zone ct.iana_tz)::date, current_date) into v_today
  from public.country_timezone ct where ct.code = v_country;
  v_today := coalesce(v_today, current_date);

  select c.id, nullif(btrim(c.name), ''), nullif(btrim(c.age_note), '')
    into v_child, v_name, v_age
  from public.children c
  where c.follower_id = p_parent_id
  order by c.is_primary desc nulls last, c.created_at
  limit 1;

  -- ---- /child -------------------------------------------------
  if p_key = 'menu_child' then
    if v_name is null then
      -- The honest empty state. Asking here is fair: she opened it.
      return 'لم نتعرّف على طفلك بعد.' || v_nl
          || 'قولي لي اسمه، وما الذي يصعب معه عادةً.';
    end if;

    select public.situation_label_ar(s.key) into v_sit
    from public.situations s
    where s.child_id = v_child and s.status in ('candidate','confirmed')
    order by (s.status = 'confirmed') desc, s.evidence_count desc
    limit 1;

    -- safe_for_record is the §2.8 provenance gate: only what was
    -- measured may be read back to her as a fact about her child.
    select cp.pattern_label into v_pat
    from public.child_patterns cp
    where cp.child_id = v_child and cp.safe_for_record
    order by cp.evidence_count desc
    limit 1;

    v_lines := array[v_name || coalesce(' · ' || v_age, '')];

    if v_sit is not null then
      v_lines := v_lines || ('الأصعب عادةً: ' || v_sit || '.')::text;
    end if;

    if v_pat is not null then
      v_lines := v_lines || v_pat::text;
    elsif v_sit is null then
      v_lines := v_lines || 'لم نتبيّن بعد ما يتكرّر معه. احكِ لي عن يومكم.'::text;
    end if;

    return array_to_string(v_lines, v_nl);
  end if;

  -- ---- /progress, and the three legacy menu callbacks ---------
  -- menu_next_goal, menu_journey_progress and menu_lighten_load
  -- lost their host when the in-chat menu was removed, but buttons
  -- already sent to phones still fire them. They answer here rather
  -- than resolving to a missing key, which would arrive as silence.
  if p_key in ('menu_progress','menu_next_goal',
               'menu_journey_progress','menu_lighten_load') then

    select count(*) filter (where d.night_result is not null) into v_total
    from public.daily_logs d where d.follower_id = p_parent_id;

    select count(*) filter (where d.night_result is not null),
           count(*) filter (where d.night_result = 'calm')
      into v_l7, v_c7
    from public.daily_logs d
    where d.follower_id = p_parent_id
      and d.log_date > v_today - 7 and d.log_date <= v_today;

    select count(*) filter (where d.night_result = 'calm') into v_c14
    from public.daily_logs d
    where d.follower_id = p_parent_id
      and d.log_date > v_today - 14 and d.log_date <= v_today - 7;

    v_total := coalesce(v_total, 0); v_l7 := coalesce(v_l7, 0);
    v_c7    := coalesce(v_c7, 0);    v_c14 := coalesce(v_c14, 0);

    if v_total = 0 then
      return 'لم نسجّل أي ليلة بعد.' || v_nl
          || 'نبدأ من الليلة — أخبريني كيف كانت.';
    elsif v_total < 3 then
      return 'سجّلنا ' || case when v_total = 1 then 'ليلة واحدة' else 'ليلتين' end
          || '.' || v_nl || 'نحتاج ثلاثاً حتى نرى ما يتكرّر.';
    end if;

    v_lines := array[
      'هذا الأسبوع: ' || public.ar_digits(v_c7::text)
        || ' هادئة من ' || public.ar_digits(v_l7::text) || '.',
      'الأسبوع الماضي: ' || public.ar_digits(v_c14::text) || '.'];

    -- The third line is the only one that carries meaning; the two
    -- above it are the evidence for it. Never congratulatory, never
    -- disappointed — a worse week is stated and then carried.
    v_lines := v_lines || (case
      when v_c7 > v_c14 then 'الاتجاه يتحسّن.'
      when v_c7 < v_c14 then 'هذا الأسبوع أصعب. لا بأس — نكمل.'
      else                   'ثابت. نكمل.' end)::text;

    return array_to_string(v_lines, v_nl);
  end if;

  return null;
end;
$function$;

comment on function public.compose_menu_body(text, uuid) is
  'Derived bodies for the ☰ commands, in SQL beside the fixed copy. /child answers who, /progress answers whether we are moving — deliberately different sentences, because the pinned message already carries the count.';


-- ------------------------------------------------------------
-- get_conversation_moment — now returns a body for every key.
--
-- Unchanged for menu_journey (pricing is still built at read time
-- from supported_countries, the one sanctioned source, so §3.7
-- holds and the table still stores no price).
--
-- What is new is the last resort: a composed key that produced
-- nothing returns found=false rather than an empty body, so the
-- caller routes it to the rescue instead of sending a blank
-- message. Silence is the one output that is always wrong.
-- ------------------------------------------------------------
create or replace function public.get_conversation_moment(
  p_key       text,
  p_parent_id uuid default null::uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  m         public.conversation_moments%rowtype;
  v_country text;
  v_price   text;
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
    select upper(btrim(f.country)) into v_country
    from public.followers f where f.id = p_parent_id;

    select sc.price_display_full into v_price
    from public.supported_countries sc
    where sc.code = v_country
      and coalesce(sc.is_active, false)
      and sc.price_display_full is not null;

    if v_price is not null then
      v_body :=
        'المرافقة اليومية التي بيننا الآن تبقى كما هي — مجاناً، دائماً.' || v_nl || v_nl ||
        'وحين يظهر هدف واضح لطفلكم — ليالٍ أهدأ، أو صباح بلا معركة —' || v_nl ||
        'يمكن أن نبني له رحلة: نمشي إليه يوماً بيوم حتى نصل،' || v_nl ||
        'أو حتى نعرف أنه لا يصلح، وأقولها لكم بصراحة.' || v_nl || v_nl ||
        'الرحلة الواحدة: ' || v_price || '.' || v_nl || v_nl ||
        'التفاصيل وطرق الدفع — فريق آدم يسعده مساعدتكم:' || v_nl ||
        'https://t.me/Abdouleg';
      v_buttons := '[]'::jsonb;
    else
      -- Honest about the reason. Not "your country does not matter" but the
      -- actual constraint: no payment rail we can stand behind yet.
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
-- get_telegram_surface — two removals.
--
-- 1. The pinned message loses its third line, «اضغط ☰ بجانب
--    الكتابة…». A permanent instruction is a permanent admission
--    that the product is not obvious (L3). It is said once, at
--    first contact, in the conversation, and then never again.
--
-- 2. `menu` becomes empty. The in-chat menu is removed: Telegram's
--    native ☰ is the only navigation, and a menu whose one item
--    points at another menu was the contradiction the founder kept
--    running into. The key stays, empty, rather than disappearing —
--    a caller that still reads it sends no buttons instead of
--    erroring on a missing field.
--
-- surface_changing_item() is left in place but is no longer called.
-- ------------------------------------------------------------
create or replace function public.get_telegram_surface(p_parent_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  v_platform_user_id text; v_country text; v_local_date date;
  v_child_id uuid; v_child_name text;
  v_sit_id uuid; v_sit_key text; v_sit_status text; v_sit_label text;
  v_stage_id uuid; v_stage_status text; v_stage_problem text; v_had_stage boolean;
  v_nights_result integer; v_human_messages integer; v_last_message_at timestamptz;
  v_calm7 integer; v_logged7 integer;
  v_paused boolean; v_dormant boolean; v_strain smallint;
  v_commerce boolean; v_supported boolean;
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

  select coalesce(bool_or(coalesce(sc.is_active, false)
                      and sc.price_display_full is not null), false)
    into v_supported
  from public.supported_countries sc where sc.code = v_country;
  v_supported := coalesce(v_supported, false);

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
      'commerce_allowed', v_commerce, 'country_supported', v_supported),
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


revoke all on function public.compose_menu_body(text, uuid) from anon, authenticated, public;
grant execute on function public.compose_menu_body(text, uuid) to service_role;

commit;
