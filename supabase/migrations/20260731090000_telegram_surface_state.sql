begin;

-- ============================================================
-- The Telegram surface, decided in one place
-- (architecture §4, UX layer)
--
-- A parent's Telegram surface is four things at once: the pinned
-- message, the five-item menu with its one changing entry, the
-- three-key reply keyboard, and the progress line. Every one of
-- them is a statement about what ADAM currently knows.
--
-- They are computed here, together, because they must agree. A
-- pinned message saying "نعمل على: النوم" above a menu item saying
-- "ما الذي يمكن أن نعمل عليه؟" is not a cosmetic mismatch — it is
-- the product contradicting itself about whether it knows this
-- family. The same argument that put commerce_allowed() in one
-- function applies here: five engines rendering the surface is
-- five chances to disagree about it.
--
-- NOTHING HERE IS STORED. The pinned text is derived on every
-- read. A stored pinned message is a second truth, and it goes
-- stale in exactly the situation where being wrong hurts most —
-- a parent returning after weeks to a banner about last month.
--
-- NO PRICE APPEARS IN THE RETURN VALUE, in any state, in any
-- country, at any strain level. The removal test (§2.1): delete
-- every price from this output and the surface still works,
-- because the changing item names a goal and the Menu is the
-- door. If a price were needed here, the design would be wrong.
-- ============================================================


-- ------------------------------------------------------------
-- Arabic numerals and the nights plural.
--
-- Arabic counts in four shapes, not two, and the pinned message
-- shows a count on most days. "٢ ليالٍ" is the kind of error a
-- parent reads as carelessness about her own week.
-- ------------------------------------------------------------
create or replace function public.ar_digits(p_text text)
returns text
language sql
immutable
set search_path to 'pg_catalog','public'
as $function$
  select translate(coalesce(p_text, ''), '0123456789', '٠١٢٣٤٥٦٧٨٩');
$function$;

comment on function public.ar_digits(text) is
  'Western digits to Arabic-Indic. The parent reads Arabic; the numbers in her pinned message should be Arabic too.';


create or replace function public.ar_nights(p_n integer)
returns text
language sql
immutable
set search_path to 'pg_catalog','public'
as $function$
  select case
    when p_n is null or p_n <= 0 then 'لا ليالٍ بعد'
    when p_n = 1                 then 'ليلة واحدة'
    when p_n = 2                 then 'ليلتان'
    when p_n <= 10               then public.ar_digits(p_n::text) || ' ليالٍ'
    else                              public.ar_digits(p_n::text) || ' ليلة'
  end;
$function$;

comment on function public.ar_nights(integer) is
  'The four Arabic count shapes for nights: none, singular, dual, paucal (3-10), plural (11+). Used wherever a night count is shown.';


-- ------------------------------------------------------------
-- The situation label.
--
-- Deliberately here and not a column on situation_catalog: the
-- catalog is a closed taxonomy consumed by the scheduler, and its
-- keys carry time windows, not copy. Copy belongs to the layer
-- that renders. One location either way — this is the rendering
-- layer, so it is this one.
-- ------------------------------------------------------------
create or replace function public.situation_label_ar(p_key text)
returns text
language sql
immutable
set search_path to 'pg_catalog','public'
as $function$
  select case p_key
    when 'sleep'  then 'النوم'
    when 'study'  then 'الدراسة'
    when 'meal'   then 'الطعام'
    when 'screen' then 'الشاشة'
    when 'out'    then 'الخروج'
    else null            -- 'other' has no honest noun; callers fall back
  end;
$function$;

comment on function public.situation_label_ar(text) is
  'Arabic noun for a situation key. Returns NULL for ''other'' on purpose: there is no honest short noun for it, and inventing one puts a word in the parent''s mouth about her own child.';


-- ------------------------------------------------------------
-- get_telegram_surface(parent_id)
--
-- STATE is a ladder, not a set. The architecture §4.5 lists eight
-- empty states in a flat table, which reads as if a parent is in
-- exactly one. Real parents are not: a parent can be paused AND
-- still gathering, in an unsupported country AND mid-journey. So
-- the eight are split here into two kinds, and this split is the
-- architectural content of this migration:
--
--   STATE (exclusive, resolved by ladder) — what ADAM knows:
--     brand_new -> no_child_name -> no_situation -> gathering
--     -> journey_active -> journey_ended_no_next -> rhythm
--
--   MODIFIERS (orthogonal, any combination) — the parent's
--   circumstances: paused, dormant, strain_level, commerce_allowed,
--   country_supported.
--
-- Unsupported country is a MODIFIER, not a state. §4.7 says the
-- free experience is "full, identical"; a state would replace the
-- others and make that false. It changes one thing: the changing
-- menu item.
--
-- CHANGING ITEM precedence — modifiers outrank state, because a
-- paused or strained parent must not be offered a goal no matter
-- how much ADAM knows about her child:
--   1. paused            -> how to resume
--   2. commerce blocked  -> lighten the load  (P1, AD-2)
--   3. country unsupported and a goal would be named -> waitlist
--   4. state
-- ------------------------------------------------------------
create or replace function public.get_telegram_surface(p_parent_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  v_platform_user_id text;
  v_country          text;
  v_local_date       date;
  v_child_id         uuid;
  v_child_name       text;
  v_sit_id           uuid;
  v_sit_key          text;
  v_sit_status       text;
  v_sit_label        text;
  v_stage_id         uuid;
  v_stage_status     text;
  v_stage_problem    text;
  v_had_stage        boolean;
  v_nights_result    integer;
  v_human_messages   integer;
  v_last_message_at  timestamptz;
  v_calm7            integer;
  v_logged7          integer;
  v_paused           boolean;
  v_dormant          boolean;
  v_strain           smallint;
  v_commerce         boolean;
  v_supported        boolean;
  v_state            text;
  v_item_label       text;
  v_item_meaning     text;
  v_progress         text;
  v_pinned           text[];
  v_goal_label       text;
begin
  select f.platform_user_id, upper(btrim(f.country))
    into v_platform_user_id, v_country
  from public.followers f
  where f.id = p_parent_id;

  if not found then
    -- Not an empty state. A caller asking about a parent who does not
    -- exist has a bug, and returning a plausible surface would hide it.
    return jsonb_build_object('exists', false, 'parent_id', p_parent_id);
  end if;

  -- Local date where the country is known. Where it is not, the server
  -- date is used for the 7-day window only; nothing proactive is
  -- scheduled off this value (get_rhythm_due refuses without a zone).
  select coalesce((now() at time zone ct.iana_tz)::date, current_date)
    into v_local_date
  from public.country_timezone ct
  where ct.code = v_country;
  v_local_date := coalesce(v_local_date, current_date);

  select coalesce(bool_or(coalesce(sc.is_active, false)
                      and coalesce(sc.is_supported, false)), false)
    into v_supported
  from public.supported_countries sc
  where sc.code = v_country;
  v_supported := coalesce(v_supported, false);

  select c.id, nullif(btrim(c.name), '')
    into v_child_id, v_child_name
  from public.children c
  where c.follower_id = p_parent_id
  order by c.is_primary desc nulls last, c.created_at
  limit 1;

  select s.id, s.key, s.status
    into v_sit_id, v_sit_key, v_sit_status
  from public.situations s
  where s.child_id = v_child_id
    and s.status in ('candidate','confirmed')
  order by (s.status = 'confirmed') desc, s.evidence_count desc, s.last_observed desc
  limit 1;

  v_sit_label := public.situation_label_ar(v_sit_key);

  select st.id, st.status, st.problem_key
    into v_stage_id, v_stage_status, v_stage_problem
  from public.stages st
  where st.parent_id = p_parent_id
    and st.status in ('active','extended')
  limit 1;

  select exists (
    select 1 from public.stages st2
    where st2.parent_id = p_parent_id
      and st2.status in ('completed','failed','refunded')
  ) into v_had_stage;

  select coalesce(e.nights_with_result, 0), coalesce(e.human_messages, 0), e.last_message_at
    into v_nights_result, v_human_messages, v_last_message_at
  from public.v_parent_engagement e
  where e.parent_id = p_parent_id;

  v_nights_result  := coalesce(v_nights_result, 0);
  v_human_messages := coalesce(v_human_messages, 0);

  select count(*) filter (where d.night_result is not null),
         count(*) filter (where d.night_result = 'calm')
    into v_logged7, v_calm7
  from public.daily_logs d
  where d.follower_id = p_parent_id
    and d.log_date > v_local_date - 7
    and d.log_date <= v_local_date;

  v_logged7 := coalesce(v_logged7, 0);
  v_calm7   := coalesce(v_calm7, 0);

  select coalesce(cs.cadence = 'stopped', false)
      or coalesce(cs.paused_until >= v_local_date, false)
    into v_paused
  from public.checkin_state cs
  where cs.parent_id = p_parent_id;
  v_paused := coalesce(v_paused, false);

  v_dormant := v_last_message_at is not null
           and v_last_message_at < now() - interval '21 days';

  select coalesce(ps.level, 1) into v_strain
  from public.parent_strain ps
  where ps.parent_id = p_parent_id;
  v_strain := coalesce(v_strain, 1);

  v_commerce := coalesce(public.commerce_allowed(p_parent_id), true);

  -- ---------- STATE ladder ----------
  v_state := case
    when v_child_id is null and v_human_messages <= 1 then 'brand_new'
    when v_child_name is null                         then 'no_child_name'
    when v_stage_id is not null                       then 'journey_active'
    when v_sit_id is null                             then 'no_situation'
    when v_nights_result < 3                          then 'gathering'
    when v_had_stage                                  then 'journey_ended_no_next'
    else                                                   'rhythm'
  end;

  -- journey_active is checked before no_situation and gathering on
  -- purpose: a parent inside a paid journey has a named goal, and
  -- showing her "we are still gathering the picture" would be false.

  -- ---------- CHANGING MENU ITEM ----------
  v_goal_label := coalesce(v_sit_label, public.situation_label_ar(v_stage_problem));

  if v_paused then
    v_item_label   := 'كيف نعود؟';
    v_item_meaning := 'resume';
  elsif not v_commerce then
    -- P1 / AD-2. Nothing commercial, and nothing that reads as a task.
    v_item_label   := 'أن نخفّف الحمل قليلاً';
    v_item_meaning := 'lighten_load';
  elsif not v_supported and v_state in ('rhythm','journey_ended_no_next') then
    v_item_label   := 'أخبروني حين يصل آدم إلى بلدي';
    v_item_meaning := 'waitlist';
  else
    case v_state
      when 'journey_active' then
        v_item_label   := case when v_goal_label is not null
                            then 'كيف تسير رحلة ' || v_goal_label || '؟'
                            else 'كيف تسير الرحلة؟' end;
        v_item_meaning := 'journey_progress';
      when 'journey_ended_no_next' then
        v_item_label   := case when v_goal_label is not null
                            then 'ما بعد ' || v_goal_label || '؟'
                            else 'ما الذي يمكن أن نعمل عليه؟' end;
        v_item_meaning := 'next_goal';
      else
        v_item_label   := 'ما الذي يمكن أن نعمل عليه؟';
        v_item_meaning := 'open_question';
    end case;
  end if;

  -- ---------- PROGRESS LINE ----------
  -- Fewer than three logged evenings: say what is true. An empty chart
  -- or a 0% bar is the product pretending, and P11 forbids it.
  v_progress := case
    when v_nights_result = 0 then 'لم نسجّل شيئاً بعد — نبدأ الليلة'
    when v_nights_result < 3 then 'نجمع الصورة — ' || public.ar_nights(v_nights_result) || ' حتى الآن'
    when v_logged7 = 0       then 'الصورة محفوظة — لم نسجّل هذا الأسبوع'
    else 'هذا الأسبوع: ' || public.ar_digits(v_calm7::text) || ' من ' ||
         public.ar_digits(v_logged7::text) || ' أهدأ'
  end;

  -- ---------- PINNED MESSAGE ----------
  -- No placeholder for a child with no name (§4.5). "طفلك" tells a
  -- parent that ADAM is filling a blank where her child should be.
  if v_child_name is null then
    v_pinned := array['📌  نبني الصورة معاً', v_progress];
  elsif v_goal_label is not null and v_state = 'journey_active' then
    v_pinned := array['📌  ' || v_child_name || ' · نعمل على: ' || v_goal_label, v_progress];
  elsif v_goal_label is not null then
    v_pinned := array['📌  ' || v_child_name || ' · ' || v_goal_label, v_progress];
  else
    v_pinned := array['📌  ' || v_child_name, v_progress];
  end if;

  -- Cast required: `text[] || 'literal'` resolves to array-concat and
  -- Postgres tries to parse the literal as an array literal.
  v_pinned := v_pinned || 'القائمة ☰ فيها كل ما يمكن أن نفعله معاً.'::text;

  return jsonb_build_object(
    'exists',           true,
    'parent_id',        p_parent_id,
    'platform_user_id', v_platform_user_id,
    'state',            v_state,
    'modifiers', jsonb_build_object(
      'paused',            v_paused,
      'dormant',           v_dormant,
      'strain_level',      v_strain,
      'commerce_allowed',  v_commerce,
      'country_supported', v_supported
    ),
    'child', case when v_child_id is null then null
                  else jsonb_build_object('id', v_child_id, 'name', v_child_name) end,
    'situation', case when v_sit_id is null then null
                      else jsonb_build_object('id', v_sit_id, 'key', v_sit_key,
                                              'label', v_sit_label, 'status', v_sit_status) end,
    'journey', case when v_stage_id is null then null
                    else jsonb_build_object('id', v_stage_id, 'status', v_stage_status,
                                            'problem_key', v_stage_problem) end,
    'keyboard', jsonb_build_array('ما حدث الآن', 'كيف نتقدّم', 'القائمة ☰'),
    'menu', jsonb_build_array(
      jsonb_build_object('key','child',    'label', coalesce(v_child_name, 'طفلي'), 'fixed', true),
      jsonb_build_object('key','progress', 'label', 'كيف نتقدّم',                    'fixed', true),
      jsonb_build_object('key','changing', 'label', v_item_label, 'fixed', false,
                         'meaning', v_item_meaning),
      jsonb_build_object('key','settings', 'label', 'إعدادات الرسائل',               'fixed', true),
      jsonb_build_object('key','privacy',  'label', 'الخصوصية وحذف البيانات',        'fixed', true)
    ),
    'progress_line', v_progress,
    'pinned', jsonb_build_object(
      'lines', to_jsonb(v_pinned),
      'text',  array_to_string(v_pinned, E'\n')
    )
  );
end;
$function$;

comment on function public.get_telegram_surface(uuid) is
  'The whole Telegram surface for one parent: state, modifiers, pinned message, five-item menu with its single changing entry, reply keyboard, progress line. Derived on every read, never stored. State is an exclusive ladder; paused/dormant/strain/country are orthogonal modifiers that outrank it when choosing the changing item. Contains no price in any state, in any country (architecture §2.1 removal test).';

revoke all on function public.get_telegram_surface(uuid) from anon, authenticated, public;
revoke all on function public.ar_digits(text)            from anon, authenticated, public;
revoke all on function public.ar_nights(integer)         from anon, authenticated, public;
revoke all on function public.situation_label_ar(text)   from anon, authenticated, public;

grant execute on function public.get_telegram_surface(uuid) to service_role;
grant execute on function public.ar_digits(text)            to service_role;
grant execute on function public.ar_nights(integer)         to service_role;
grant execute on function public.situation_label_ar(text)   to service_role;

commit;
