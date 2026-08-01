begin;

-- ============================================================
-- The enemy is a repeating story, not a time of day.
-- (docs/adam-promise.md §8)
--
-- The enemy was first named "the night that repeats itself".
-- That was an error of SCOPE, not of principle, and the cost is
-- commercial before it is linguistic: an enemy tied to bedtime
-- gives the brand an expiry date. A parent who solves sleep
-- LEAVES. A parent whose enemy is "the story that repeats" is
-- followed into meals, then school, then jealousy, then temper,
-- then adolescence.
--
-- The leak was already in production. Every progress sentence
-- ADAM speaks is night-shaped:
--
--   "سجّلنا ليلة واحدة"     "٣ ليالٍ هادئة من ٤"
--
-- A parent whose repeating story is the school-run battle reads
-- "three calm nights" and learns, in one sentence, that ADAM is
-- not for them. This migration removes that sentence.
--
-- WHAT IS NOT CHANGED, DELIBERATELY
--
-- daily_logs.night_result keeps its name. Renaming it breaks W3
-- and W4 for no gain a parent can see — the column is internal
-- naming debt, not product surface. Only what is SPOKEN changes.
-- ============================================================


-- ------------------------------------------------------------
-- ar_occasions replaces ar_nights.
--
-- Same Arabic plural ladder, domain-free noun. "مرة" works for a
-- bedtime, a breakfast, a homework hour and a slammed door — the
-- whole point of widening the enemy.
--
-- ar_nights is dropped rather than left: a night-shaped helper
-- sitting in the schema is an invitation to write a night-shaped
-- sentence next time.
-- ------------------------------------------------------------
create or replace function public.ar_occasions(p_n integer)
returns text
language sql
immutable
set search_path to 'pg_catalog','public'
as $function$
  select case
    when p_n is null or p_n <= 0 then 'لا شيء بعد'
    when p_n = 1                 then 'مرة واحدة'
    -- Accusative. Every call site is adverbial — «جرّبتم مرّتين»،
    -- «هدأ مرّتين» — so the nominative «مرّتان» would be wrong in all of them.
    when p_n = 2                 then 'مرّتين'
    when p_n <= 10               then public.ar_digits(p_n::text) || ' مرات'
    else                              public.ar_digits(p_n::text) || ' مرة'
  end;
$function$;

comment on function public.ar_occasions(integer) is
  'Arabic plural ladder for a countable occasion. Replaces ar_nights: the enemy is a repeating story, not a time of day, and a night-shaped helper produces night-shaped copy.';

drop function if exists public.ar_nights(integer);


-- ------------------------------------------------------------
-- progress_line — the same three states, spoken domain-free.
--
-- "نحتاج ثلاثة حتى نعرف ما يتكرّر" is kept word for word. It is
-- the one sentence in the product that names the enemy out loud
-- without naming it: what repeats is exactly what we are here to
-- break, and three is when it becomes visible.
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
      then 'لم نسجّل شيئاً بعد — نبدأ من اليوم.'
    when p_nights_with_result = 1
      then 'سجّلنا مرة واحدة. نحتاج ثلاثاً حتى نعرف ما يتكرّر.'
    when p_nights_with_result = 2
      then 'سجّلنا مرّتين. نحتاج ثلاثاً حتى نعرف ما يتكرّر.'
    when coalesce(p_logged_this_week,0) = 0
      then 'لم نسجّل شيئاً هذا الأسبوع.'
    else 'هذا الأسبوع: ' || public.ar_digits(p_calm_this_week::text)
         || ' من ' || public.ar_digits(p_logged_this_week::text) || ' مرّت بهدوء.'
  end;
$function$;

comment on function public.progress_line(integer, integer, integer) is
  'What we recorded, and what comes next — free of any time of day. The parameter names still say nights because their callers do; the sentence does not, and only the sentence is read by a parent.';


-- ------------------------------------------------------------
-- compose_menu_body — /child unchanged, /progress de-nighted.
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
      return 'لم نتعرّف على طفلكم بعد.' || v_nl
          || 'اكتبوا اسمه، وما أكثر ما يتعب معه هذه الأيام.';
    end if;

    select public.situation_label_ar(s.key) into v_sit
    from public.situations s
    where s.child_id = v_child and s.status in ('candidate','confirmed')
    order by (s.status = 'confirmed') desc, s.evidence_count desc
    limit 1;

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
      v_lines := v_lines || 'لم نتبيّن بعد ما يتكرّر معه. احكوا لي عن يومكم.'::text;
    end if;

    return array_to_string(v_lines, v_nl);
  end if;

  -- ---- /progress, and the three legacy menu callbacks ---------
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
      return 'لم نسجّل شيئاً بعد.' || v_nl
          || 'نبدأ من اليوم — احكوا لي ما حدث.';
    elsif v_total < 3 then
      return 'سجّلنا ' || public.ar_occasions(v_total)
          || '.' || v_nl || 'نحتاج ثلاثاً حتى نرى ما يتكرّر.';
    end if;

    v_lines := array[
      'هذا الأسبوع: ' || public.ar_digits(v_c7::text)
        || ' من ' || public.ar_digits(v_l7::text) || ' مرّت بهدوء.',
      'الأسبوع الماضي: ' || public.ar_digits(v_c14::text) || '.'];

    v_lines := v_lines || (case
      when v_c7 > v_c14 then 'الاتجاه يتحسّن.'
      when v_c7 < v_c14 then 'هذا الأسبوع أصعب. لا بأس — نكمل.'
      else                   'ثابت. نكمل.' end)::text;

    return array_to_string(v_lines, v_nl);
  end if;

  return null;
end;
$function$;


revoke all on function public.ar_occasions(integer) from anon, authenticated, public;
grant execute on function public.ar_occasions(integer) to service_role;

commit;

-- ============================================================
-- ADAM does not know he is speaking to a mother.
--
-- §0.7 has required gender-neutral address since it was written.
-- Nothing enforced it, so it held only for as long as whoever was
-- typing remembered — and on 2026-08-01 I wrote «صِفي لي»،
-- «قولي لي» and «احكِ» into four moments in one sitting.
--
-- A father reading «صِفي لي ما فيها» learns in three words that
-- this product was not built with him in mind. Half the market,
-- lost to a verb ending.
--
-- The plural imperative is the neutral form in Arabic and it is
-- also the warmer one here: it addresses the household rather
-- than an individual, which is what a companion to a FAMILY
-- should do.
--
-- A test now guards every stored and composed body, so this
-- cannot come back quietly.
-- ============================================================

begin;

update public.conversation_moments
set body_ar = 'السلام عليكم 🌿' || chr(10)
           || 'أنا آدم — أرافق الأهل مع أطفالهم، يوماً بيوم.' || chr(10)
           || 'احكوا لي ما حدث اليوم مع طفلكم، بكلماتكم.'
where key = 'first_contact';

update public.conversation_moments
set body_ar = 'أنا هنا.' || chr(10) || 'احكوا لي ما حدث.'
where key = 'welcome_back';

update public.conversation_moments
set body_ar = 'لا أستطيع رؤية الصور بعد.' || chr(10)
           || 'لكن احكوا لي ما فيها بكلماتكم، وسأفهم.'
where key = 'media_unsupported';

update public.conversation_moments
set body_ar = 'احكوا لي ما يشغلكم الآن.'
where key = 'menu_open_question';

commit;

-- The last one the guard found. The rescue is the floor under every path;
-- it fires when everything else failed. Speaking it to a mother
-- specifically means a father's worst moment with ADAM is also the moment
-- he learns the product was not built for him.
begin;
update public.conversation_moments
set body_ar = 'لم أفهم هذه تماماً.' || chr(10)
           || 'احكوا لي ما يحدث بكلماتكم، وأنا معكم.'
where key = 'rescue';
commit;
