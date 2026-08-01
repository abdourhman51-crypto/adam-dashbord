begin;

-- ============================================================
-- Give before asking. And count the parent, not the child.
-- (docs/adam-promise.md §5, §8 · docs/adam-system.md §3, §10)
--
-- Tonight, for the first time in the product's life, an evening
-- question will reach real families. Today it reads:
--
--     كيف كانت تجربة اليوم مع مالك؟
--
-- A blank question. Peak-End says this is the single most
-- remembered message ADAM sends, and it is a demand — and an
-- unanswered demand from an app produces guilt, which ends
-- subscriptions before they begin.
--
-- The rule inverts: the evening message GIVES something back
-- before it asks for anything. Everything it gives is measured,
-- never inferred, so it is true on the worst night too.
-- ============================================================


-- ------------------------------------------------------------
-- get_harvest_prompt — the evening message, composed in SQL.
--
-- Tier 1 by design (arch §2.2). This fires nightly for every
-- active family; it must be reliable, cheap and identical in
-- structure every time. What varies is the family, not the model.
--
-- Three gifts, in descending order of how much they prove:
--
--   1. A repeat that has been counted. "مالك هدأ ثلاث مرات هذا
--      الشهر عند النوم" is the scoreboard of the war against the
--      enemy — the parent learns something about their own child
--      that they did not know they knew.
--   2. A step that once worked, handed back.
--   3. Today's own step, so the question is never blank.
--
-- (3) always exists, because a harvest cannot fire without a
-- seed the same day. There is no fourth case and no silence.
-- ------------------------------------------------------------
create or replace function public.get_harvest_prompt(
  p_parent_id uuid,
  p_day_id    uuid default null)
returns text
language plpgsql
stable
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  v_nl        text := chr(10);
  v_name      text;
  v_today     date;
  v_country   text;
  v_sit_id    uuid;
  v_sit_label text;
  v_step      text;
  v_prev_step text;
  v_calm_here integer;
  v_gift      text;
begin
  select upper(btrim(f.country)) into v_country
  from public.followers f where f.id = p_parent_id;
  if not found then
    return null;
  end if;

  select coalesce((now() at time zone ct.iana_tz)::date, current_date) into v_today
  from public.country_timezone ct where ct.code = v_country;
  v_today := coalesce(v_today, current_date);

  select nullif(btrim(c.name), '') into v_name
  from public.children c where c.follower_id = p_parent_id
  order by c.is_primary desc nulls last, c.created_at limit 1;

  -- today's row: the step we asked them to try, and which situation it was for
  select coalesce(nullif(btrim(d.step_given), ''), nullif(btrim(d.seed_text), '')),
         d.situation_id
    into v_step, v_sit_id
  from public.daily_logs d
  where (p_day_id is not null and d.id = p_day_id)
     or (p_day_id is null and d.follower_id = p_parent_id and d.log_date = v_today)
  limit 1;

  v_sit_label := public.situation_label_ar(
    (select s.key from public.situations s where s.id = v_sit_id));

  -- How many times has this exact situation gone calm this month?
  -- Only counted where a situation was recorded, so the sentence can
  -- never say "three times" about three different kinds of evening.
  if v_sit_id is not null then
    select count(*) into v_calm_here
    from public.daily_logs d
    where d.follower_id = p_parent_id
      and d.situation_id = v_sit_id
      and d.night_result = 'calm'
      and d.log_date > v_today - 30
      and d.log_date < v_today;
  end if;
  v_calm_here := coalesce(v_calm_here, 0);

  -- the most recent step that actually worked
  select nullif(btrim(d.step_given), '') into v_prev_step
  from public.daily_logs d
  where d.follower_id = p_parent_id
    and d.night_result = 'calm'
    and d.log_date < v_today
    and nullif(btrim(d.step_given), '') is not null
  order by d.log_date desc limit 1;

  if v_name is not null and v_sit_label is not null and v_calm_here >= 2 then
    -- THE moment. Nothing else in the product proves as much in one line.
    -- situation_label_ar returns «النوم», not «عند النوم» — the preposition
    -- belongs to the sentence, not to the label.
    v_gift := v_name || ' هدأ ' || public.ar_occasions(v_calm_here)
           || ' هذا الشهر عند ' || v_sit_label || '.';
  elsif v_prev_step is not null then
    v_gift := 'آخر مرة نفعت معكم: ' || v_prev_step;
    if right(v_gift, 1) not in ('.', '؟', '!') then v_gift := v_gift || '.'; end if;
  elsif v_step is not null then
    v_gift := 'اليوم جرّبنا' || coalesce(' مع ' || v_name, '') || ': ' || v_step;
    if right(v_gift, 1) not in ('.', '؟', '!') then v_gift := v_gift || '.'; end if;
  else
    -- Cannot happen while a harvest requires a seed, but silence is never
    -- the answer: fall back to naming the day rather than asking blankly.
    v_gift := 'مرّ يوم آخر' || coalesce(' مع ' || v_name, '') || '.';
  end if;

  return v_gift || v_nl || v_nl || 'كيف مرّت؟';
end;
$function$;

comment on function public.get_harvest_prompt(uuid, uuid) is
  'The evening message. Gives something measured back before it asks anything — a counted repeat, a step that once worked, or today''s own step. Peak-End: this is the most remembered message ADAM sends, and it was a blank question.';


-- ------------------------------------------------------------
-- parent_effort — the scoreboard, counted on the parent.
--
-- Every number ADAM has shown so far has been about the child:
-- calm nights, hard nights. Those depend on a four-year-old
-- co-operating, and on a bad week they say "you failed".
--
-- What is actually within the parent's power is whether they
-- tried. That is fully observable, independent of the child, and
-- it is the first crack in the enemy: the story repeated, and
-- they answered it differently.
--
-- An attempt counts whether it worked or not. A night they were
-- too exhausted to try is not held against them — it is simply
-- not counted.
-- ------------------------------------------------------------
create or replace function public.parent_effort(p_parent_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  v_country text; v_today date;
  v_tried_7 integer; v_calm_7 integer; v_tried_prev integer;
  v_tried_all integer;
begin
  select upper(btrim(f.country)) into v_country
  from public.followers f where f.id = p_parent_id;
  if not found then
    return jsonb_build_object('tried_this_week', 0, 'tried_ever', 0);
  end if;

  select coalesce((now() at time zone ct.iana_tz)::date, current_date) into v_today
  from public.country_timezone ct where ct.code = v_country;
  v_today := coalesce(v_today, current_date);

  -- "tried" = they came back and told us how it went, either way.
  -- 'skip' is an honest answer, not an attempt, and costs them nothing.
  select count(*) filter (where d.night_result in ('calm','hard')),
         count(*) filter (where d.night_result = 'calm')
    into v_tried_7, v_calm_7
  from public.daily_logs d
  where d.follower_id = p_parent_id
    and d.log_date > v_today - 7 and d.log_date <= v_today;

  select count(*) filter (where d.night_result in ('calm','hard')) into v_tried_prev
  from public.daily_logs d
  where d.follower_id = p_parent_id
    and d.log_date > v_today - 14 and d.log_date <= v_today - 7;

  select count(*) filter (where d.night_result in ('calm','hard')) into v_tried_all
  from public.daily_logs d where d.follower_id = p_parent_id;

  return jsonb_build_object(
    'tried_this_week', coalesce(v_tried_7, 0),
    'tried_last_week', coalesce(v_tried_prev, 0),
    'tried_ever',      coalesce(v_tried_all, 0),
    'calm_this_week',  coalesce(v_calm_7, 0));
end;
$function$;

comment on function public.parent_effort(uuid) is
  'What the parent did, not what the child did. An attempt counts whether it worked; a night too exhausted to try is not counted against them. This is the number that is inside their power and the first thing that changes.';


-- ------------------------------------------------------------
-- /progress now leads with them.
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
  v_lines text[] := '{}';
begin
  if p_parent_id is null then return null; end if;

  select upper(btrim(f.country)) into v_country
  from public.followers f where f.id = p_parent_id;
  if not found then return null; end if;

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

    -- Them first. The child's outcome is evidence for their effort,
    -- not the other way round.
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
-- The intention — the anchor the promise has been missing.
--
-- "You come closer to who you meant to be for your child" needs
-- ADAM to know who that is. It is not a goal (stages holds
-- those); it is an identity, asked once, never repeated, and
-- NEVER used to measure distance.
--
-- Timing matters more than wording: asking at first contact is
-- abstract to an exhausted stranger. It is asked only after
-- something has already worked once — when the question lands as
-- meaning rather than as a survey.
-- ------------------------------------------------------------
alter table public.followers
  add column if not exists intention_text text,
  add column if not exists intention_asked_at timestamptz;

comment on column public.followers.intention_text is
  'Who this parent said they wanted to be for their child. The anchor of the brand promise. Never used to measure distance — only to show approach.';

create or replace function public.should_ask_intention(p_parent_id uuid)
returns boolean
language sql
stable
security definer
set search_path to 'pg_catalog','public'
as $function$
  select exists (
    select 1 from public.followers f
    where f.id = p_parent_id
      and f.intention_text is null
      and f.intention_asked_at is null
      -- only after something has actually worked once
      and exists (select 1 from public.daily_logs d
                   where d.follower_id = f.id and d.night_result = 'calm')
  );
$function$;

create or replace function public.record_intention(
  p_parent_id uuid, p_text text)
returns boolean
language plpgsql
volatile
security definer
set search_path to 'pg_catalog','public'
as $function$
declare v_clean text;
begin
  v_clean := nullif(btrim(coalesce(p_text, '')), '');
  if v_clean is null or length(v_clean) < 3 then
    return false;
  end if;
  -- Never overwritten. A parent says this once; a second answer to a
  -- different question must not silently replace who they said they were.
  update public.followers
  set intention_text = v_clean, intention_asked_at = coalesce(intention_asked_at, now())
  where id = p_parent_id and intention_text is null;
  return found;
end;
$function$;

insert into public.conversation_moments
  (key, category, tier, body_ar, buttons, max_lines, requires_commerce, note)
values
  ('intention_ask', 'rhythm', 'fixed',
   'سؤال واحد، ولن أعيده.' || chr(10) ||
   'قبل أن يأتي — أيّ أب أو أمّ تمنّيتم أن تكونوا له؟',
   '[]'::jsonb, 2, false,
   'Asked once, ever, and only after something has already worked. The anchor of the promise: without it "closer to who you meant to be" has no referent. ADAM never measures the distance to it — only shows approach.')
on conflict (key) do update
  set body_ar = excluded.body_ar, note = excluded.note;


-- ------------------------------------------------------------
-- offer_ready — the only moment the journey may be raised.
--
-- Not while they are in pain (P1). Not while they are new. Only
-- once they have SEEN evidence that something changed, because
-- that is when "what if we did this on purpose?" becomes their
-- own thought rather than our offer.
-- ------------------------------------------------------------
create or replace function public.offer_ready(p_parent_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  v_calm integer; v_tried integer; v_sit text; v_name text;
  v_missing text[] := '{}';
begin
  select nullif(btrim(c.name),'') into v_name
  from public.children c where c.follower_id = p_parent_id
  order by c.is_primary desc nulls last, c.created_at limit 1;

  select (public.parent_effort(p_parent_id)->>'tried_ever')::int into v_tried;

  select count(*) into v_calm from public.daily_logs d
  where d.follower_id = p_parent_id and d.night_result = 'calm';

  select public.situation_label_ar(s.key) into v_sit
  from public.situations s join public.children c2 on c2.id = s.child_id
  where c2.follower_id = p_parent_id and s.status = 'confirmed'
  order by s.evidence_count desc limit 1;

  -- The ::text casts are load-bearing. Without them `text[] || 'literal'`
  -- resolves to array-concat and Postgres tries to parse the literal as an
  -- array. Same trap, third time this week.
  if v_name is null           then v_missing := v_missing || 'child_name'::text; end if;
  if v_sit is null            then v_missing := v_missing || 'confirmed_situation'::text; end if;
  if coalesce(v_tried,0) < 3  then v_missing := v_missing || 'three_attempts'::text; end if;
  if coalesce(v_calm,0)  < 2  then v_missing := v_missing || 'two_outcomes'::text; end if;
  if not coalesce(public.commerce_allowed(p_parent_id), true)
                              then v_missing := v_missing || 'commerce_blocked'::text; end if;

  return jsonb_build_object(
    'ready',   cardinality(v_missing) = 0,
    'missing', to_jsonb(v_missing),
    'child',   v_name,
    'situation', v_sit,
    -- The fork, not the offer. No price, no product name, no urgency.
    'fork_ar', case when cardinality(v_missing) = 0 and v_name is not null
                    then 'لاحظنا شيئاً يتكرّر مع ' || v_name || '.' || chr(10) || chr(10)
                      || 'هل نتركه يتكرّر... أم نشتغل عليه حتى يتغيّر؟'
                    else null end);
end;
$function$;

comment on function public.offer_ready(uuid) is
  'Whether this parent has seen enough of their own evidence for the journey question to be theirs rather than ours. Returns the fork, never an offer: no price, no product name, no urgency.';


revoke all on function public.get_harvest_prompt(uuid, uuid)  from anon, authenticated, public;
revoke all on function public.parent_effort(uuid)             from anon, authenticated, public;
revoke all on function public.should_ask_intention(uuid)      from anon, authenticated, public;
revoke all on function public.record_intention(uuid, text)    from anon, authenticated, public;
revoke all on function public.offer_ready(uuid)               from anon, authenticated, public;

grant execute on function public.get_harvest_prompt(uuid, uuid) to service_role;
grant execute on function public.parent_effort(uuid)            to service_role;
grant execute on function public.should_ask_intention(uuid)     to service_role;
grant execute on function public.record_intention(uuid, text)   to service_role;
grant execute on function public.offer_ready(uuid)              to service_role;

commit;
