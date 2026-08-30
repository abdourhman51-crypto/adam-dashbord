begin;

-- ============================================================
-- THE EIGHTEEN, RECONCILED TO PRODUCTION
--
-- The functions restored in 20260830130000 existed ONLY in
-- production. These eighteen exist in both — and their bodies
-- had drifted apart. Each was edited directly against the live
-- database and the migration that first defined it was never
-- updated, so a database built from this repository ran
-- different logic from the one real parents are talking to.
--
-- The live version wins here, because it is the one that has
-- been answering parents. Where the difference is behavioural
-- rather than cosmetic it is named in a comment above the
-- function, so the team can disagree with any single one of them
-- without having to diff a database to find it.
--
-- Six further functions differ from production only in SQL
-- keyword case (BEGIN vs begin) or in carrying a search_path
-- setting: _ensure_child, check_daily_message_cap,
-- get_conversation_for, get_extraction_batch, set_updated_at,
-- surface_keyboard. They are deliberately NOT restated here.
-- Rewriting a function to change nothing but its capitalisation
-- costs a review and buys nothing.
-- ============================================================


-- ------------------------------------------------------------
-- BEHAVIOURAL: the crisis lockout is 24 hours, not 14 days, and
-- the extra `entered_at < now() - 14 days` clause is gone.
--
-- The repo's version kept commerce shut for a fortnight after a
-- single crisis flag. In practice that silenced the offer for
-- parents who had long since steadied, and the dead clause
-- (`ps.level = 1 and (... or ps.level = 1)`) never excluded
-- anything anyway. Production matches
-- commerce_allowed_after_voluntary_form, which uses the same
-- 24-hour window.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.commerce_allowed(p_parent_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
  select coalesce((
    select ps.level = 1
       and not exists (
         select 1 from public.crisis_flags cf
         where cf.parent_id = p_parent_id
           and cf.detected_at > now() - interval '24 hours')
    from public.parent_strain ps
    where ps.parent_id = p_parent_id
  ), true);
$function$;


CREATE OR REPLACE FUNCTION public.get_pricing(p_country text)
 RETURNS TABLE(country text, is_supported boolean, currency text, first_stage_amount numeric, first_stage_display text, first_stage_display_short text, continuation_amount numeric, continuation_display text)
 LANGUAGE sql
 STABLE
 SET search_path TO 'pg_catalog', 'public'
AS $function$
  SELECT
    COALESCE(sc.code, upper(trim(COALESCE(p_country,'')))) AS country,
    (sc.code IS NOT NULL)                                   AS is_supported,
    sc.currency,
    sc.price_subscription,
    sc.price_display_full,
    sc.price_display_short,
    sc.price_continuation,
    sc.price_continuation_display
  FROM (SELECT 1) AS anchor
  LEFT JOIN public.supported_countries sc
         ON sc.code = upper(trim(COALESCE(p_country,'')))
        AND sc.is_active
$function$;


CREATE OR REPLACE FUNCTION public.heart_commit(p_platform_user_id text, p_light_memory jsonb)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_has_content boolean := false;
    v_updated     integer := 0;
    k             text;
    v             text;
BEGIN
    IF p_platform_user_id IS NULL
       OR p_light_memory IS NULL
       OR jsonb_typeof(p_light_memory) <> 'object' THEN
        RETURN false;
    END IF;

    FOREACH k IN ARRAY ARRAY['child_name','core_pain','emotional_state','last_win','continuity','life_context']
    LOOP
        v := btrim(COALESCE(p_light_memory->>k, ''));
        IF v <> '' THEN
            v_has_content := true;
        END IF;
    END LOOP;

    IF NOT v_has_content THEN
        RETURN false;
    END IF;

    UPDATE followers
       SET light_memory            = p_light_memory::text,
           light_memory_updated_at = now()
     WHERE platform_user_id = p_platform_user_id;

    GET DIAGNOSTICS v_updated = ROW_COUNT;
    RETURN v_updated > 0;
END;
$function$;


CREATE OR REPLACE FUNCTION public.parent_effort(p_parent_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_country text; v_today date;
  v_tried_7 integer; v_calm_7 integer; v_tried_prev integer; v_calm_prev integer; v_tried_all integer;
begin
  select upper(btrim(f.country)) into v_country
  from public.followers f where f.id = p_parent_id;
  if not found then
    return jsonb_build_object('tried_this_week', 0, 'tried_ever', 0);
  end if;

  select coalesce((now() at time zone ct.iana_tz)::date, current_date) into v_today
  from public.country_timezone ct where ct.code = v_country;
  v_today := coalesce(v_today, current_date);

  select count(*) filter (where d.night_result in ('calm','hard')),
         count(*) filter (where d.night_result = 'calm')
    into v_tried_7, v_calm_7
  from public.daily_logs d
  where d.follower_id = p_parent_id
    and d.log_date > v_today - 7 and d.log_date <= v_today;

  select count(*) filter (where d.night_result in ('calm','hard')),
         count(*) filter (where d.night_result = 'calm')
    into v_tried_prev, v_calm_prev
  from public.daily_logs d
  where d.follower_id = p_parent_id
    and d.log_date > v_today - 14 and d.log_date <= v_today - 7;

  select count(*) filter (where d.night_result in ('calm','hard')) into v_tried_all
  from public.daily_logs d where d.follower_id = p_parent_id;

  return jsonb_build_object(
    'tried_this_week', coalesce(v_tried_7, 0),
    'tried_last_week', coalesce(v_tried_prev, 0),
    'tried_ever',      coalesce(v_tried_all, 0),
    'calm_this_week',  coalesce(v_calm_7, 0),
    'calm_last_week',  coalesce(v_calm_prev, 0));
end;
$function$;


-- ------------------------------------------------------------
-- BEHAVIOURAL: the agreement moment is now gated on the country
-- being one we can actually sell in. Naming a measured goal to a
-- parent whose country is unknown or unsupported builds
-- excitement for a door that does not open.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.should_agree_first(p_parent_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_ready   boolean;
  v_agreed  timestamptz;
  v_ttl     constant interval := interval '14 days';
  v_cs      jsonb;
begin
  if p_parent_id is null then
    return false;
  end if;

  -- ⭐ FIX: the goal-agreement moment ("اتّفقنا على هدف قياسه بالضبط...") only
  -- makes sense once we actually know we CAN sell here. Without this check,
  -- a parent whose country is unknown or unsupported could be shown a
  -- specific measured goal before we even know whether a purchase is
  -- possible for them -- building excitement for a door that isn't open yet.
  v_cs := public.country_state(p_parent_id);
  if coalesce(v_cs->>'state', 'unknown') <> 'supported' then
    return false;
  end if;

  if not coalesce(public.commerce_allowed(p_parent_id), true) then
    return false;
  end if;

  if exists (select 1 from public.stages
             where parent_id = p_parent_id
               and status in ('active','extended','paused')) then
    return false;
  end if;

  select agreed_at into v_agreed from public.followers where id = p_parent_id;
  if v_agreed is not null and v_agreed > now() - v_ttl then
    return false;
  end if;

  v_ready := coalesce((public.suggest_objective(p_parent_id)->>'ready')::boolean, false);
  return v_ready;
end;
$function$;


CREATE OR REPLACE FUNCTION public.can_ground_seed(p_parent_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
with child as (
  select c.id, nullif(btrim(c.name), '') as name
  from public.children c
  where c.follower_id = p_parent_id
  order by c.is_primary desc nulls last, c.created_at
  limit 1
),
sit as (
  select s.id, s.key, s.window_start, s.window_end,
         (s.key is not null and s.key <> 'other') as is_specific
  from public.situations s
  join child on child.id = s.child_id
  where s.status in ('candidate','confirmed')
  order by (s.key is not null and s.key <> 'other') desc,
           (s.status = 'confirmed') desc, s.evidence_count desc, s.last_observed desc
  limit 1
),
outcome as (
  select d.step_given, d.night_result, d.step_status, d.log_date
  from public.daily_logs d
  where d.follower_id = p_parent_id
    and (d.night_result is not null or d.step_status is not null)
  order by d.log_date desc
  limit 1
),
pat as (
  select p.pattern_label
  from public.child_patterns p
  join child on child.id = p.child_id
  where coalesce(p.status,'active') <> 'dismissed'
  order by p.evidence_count desc nulls last, p.last_observed desc
  limit 1
),
-- ⭐ same rule as get_harvest_prompt: last 3 nights, zero calm, 2+ hard.
rough as (
  select count(*) filter (where d.night_result = 'hard') >= 2
     and count(*) filter (where d.night_result = 'calm') = 0 as is_rough
  from public.daily_logs d
  where d.follower_id = p_parent_id
    and d.log_date > current_date - 3 and d.log_date < current_date
),
basis as (
  select
    (select count(*) from sit) > 0                          as has_situation,
    coalesce((select is_specific from sit), false)           as has_specific_situation,
    (select count(*) from outcome) > 0                       as has_outcome,
    (select count(*) from pat)     > 0                       as has_pattern,
    (select name from child) is not null                     as has_name
)
select jsonb_build_object(
  'can_ground',  b.has_name and (b.has_specific_situation or b.has_outcome or b.has_pattern),
  'child_id',    (select id   from child),
  'child_name',  (select name from child),
  'situation',   (select to_jsonb(sit)     from sit),
  'last_outcome',(select to_jsonb(outcome) from outcome),
  'pattern',     (select pattern_label from pat),
  'is_rough_patch', coalesce((select is_rough from rough), false),
  'basis', (
    select coalesce(jsonb_agg(x), '[]'::jsonb) from (
      select 'child_name'    as x where b.has_name                union all
      select 'situation'          where b.has_specific_situation  union all
      select 'prior_outcome'      where b.has_outcome             union all
      select 'pattern'            where b.has_pattern
    ) t
  ),
  'missing', (
    select coalesce(jsonb_agg(x), '[]'::jsonb) from (
      select 'child_name' as x where not b.has_name
      union all
      select 'any_of_situation_outcome_pattern'
        where not (b.has_specific_situation or b.has_outcome or b.has_pattern)
      union all
      select 'situation_is_only_other'
        where b.has_situation and not b.has_specific_situation
          and not (b.has_outcome or b.has_pattern)
    ) t
  )
)
from basis b;
$function$;


-- ------------------------------------------------------------
-- BEHAVIOURAL: answering the evening question now clears
-- winback_sent_at as well as consecutive_ignored, so a parent who
-- goes quiet again later is eligible for a win-back again. In the
-- repo's version the flag was set once and never cleared, which
-- meant every parent could receive exactly one win-back, ever.
-- It also runs the stage clock and returns its verdict, so the
-- n8n side needs one call instead of two.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.record_harvest_answer(p_parent_id uuid, p_outcome text, p_hard_moment text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_day  public.daily_logs%rowtype;
  v_tz   text;
  v_date date;
  v_clock jsonb;
begin
  if p_outcome is null or p_outcome not in ('succeeded', 'tried_failed', 'no_chance') then
    return jsonb_build_object(
      'recorded', false,
      'reason', 'unknown_outcome',
      'given', p_outcome,
      'expected', jsonb_build_array('succeeded', 'tried_failed', 'no_chance'));
  end if;

  select ct.iana_tz into v_tz
  from public.followers f
  join public.country_timezone ct on upper(btrim(f.country)) = ct.code
  where f.id = p_parent_id;

  v_date := (now() at time zone coalesce(v_tz, 'UTC'))::date;

  update public.daily_logs
     set step_status = case p_outcome
                         when 'succeeded'    then 'done'
                         when 'tried_failed' then 'tried_failed'
                         else 'not_tried' end,
         night_result = case p_outcome
                         when 'succeeded'    then 'calm'
                         when 'tried_failed' then 'hard'
                         else night_result end,
         hard_moment  = coalesce(p_hard_moment, hard_moment),
         harvest_answered_at = now(),
         updated_at = now()
   where follower_id = p_parent_id
     and log_date = v_date
     and seed_sent_at is not null
  returning * into v_day;

  if v_day.id is null then
    return jsonb_build_object('recorded', false, 'reason', 'no_seed_today');
  end if;

  -- ⭐ winback_sent_at reset alongside consecutive_ignored: this response
  -- closes out the silence streak the win-back (if any) was sent for.
  update public.checkin_state
     set consecutive_ignored = 0, last_responded_at = now(),
         winback_sent_at = null, updated_at = now()
   where parent_id = p_parent_id;

  perform public.capture_stage_baseline(p_parent_id);

  v_clock := public.check_stage_clock(p_parent_id);

  return jsonb_build_object('recorded', true, 'day_id', v_day.id, 'local_date', v_date,
    'stage_clock', v_clock);
end;
$function$;


-- ------------------------------------------------------------
-- BEHAVIOURAL: strain steps DOWN one level at a time and refuses
-- to step down at all inside the recovery window ('held'), and
-- reaching level 3 now raises a crisis flag on its own. A parent
-- who was drowning yesterday is not fine today because one calm
-- message arrived.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_strain_level(p_parent_id uuid, p_level smallint, p_reason text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_cur    smallint;
  v_elig   timestamptz;
  v_new    smallint;
  v_action text;
begin
  if p_level not in (1,2,3) then
    return jsonb_build_object('ok', false, 'reason', 'invalid_level');
  end if;

  select level, return_eligible_at into v_cur, v_elig
  from public.parent_strain where parent_id = p_parent_id;

  if v_cur is null then
    v_cur := 1;
    insert into public.parent_strain(parent_id, level) values (p_parent_id, 1)
      on conflict (parent_id) do nothing;
  end if;

  if p_level > v_cur then
    v_new := p_level;
    v_action := 'escalated';
  elsif p_level < v_cur then
    if v_elig is not null and now() < v_elig then
      return jsonb_build_object(
        'ok', true, 'action', 'held', 'level', v_cur,
        'return_eligible_at', v_elig,
        'note', 'recovery window not yet elapsed');
    end if;
    v_new := v_cur - 1;
    v_action := case when v_new < v_cur - 1 then 'stepped' else 'stepped_down' end;
  else
    v_new := v_cur;
    v_action := 'unchanged';
  end if;

  update public.parent_strain
     set level  = v_new,
         reason = coalesce(p_reason, reason),
         entered_at = case when v_new <> v_cur then now() else entered_at end,
         return_eligible_at = case
           when v_new = 3 then now() + interval '7 days'
           when v_new = 2 then now() + interval '24 hours'
           else null end,
         updated_at = now()
   where parent_id = p_parent_id;

  if v_new = 3 and v_cur <> 3 then
    insert into public.crisis_flags
      (id, parent_id, category, detected_at, source, confidence, created_at)
    values
      (gen_random_uuid(), p_parent_id, 'other', now(), 'system',
       'medium', now());
  end if;

  return jsonb_build_object(
    'ok', true, 'action', v_action, 'from', v_cur, 'level', v_new,
    'return_eligible_at', case when v_new = 3 then now() + interval '7 days'
                               when v_new = 2 then now() + interval '24 hours'
                               else null end);
end;
$function$;


CREATE OR REPLACE FUNCTION public.stage_state(p_parent_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v            record;
  v_baseline_text  text;
  v_baseline_calm  int;
  v_recent_calm    int;
  v_show_baseline  boolean := false;
  v_problem_context text;
  v_frequency_label text;
begin
  select * into v from public.v_stage_progress
  where parent_id = p_parent_id and status in ('active','extended')
  limit 1;

  if not found then
    return jsonb_build_object('in_stage', false);
  end if;

  select s.baseline_text, s.baseline_calm_count, s.problem_context_text, s.frequency_label
    into v_baseline_text, v_baseline_calm, v_problem_context, v_frequency_label
  from public.stages s where s.id = v.stage_id;

  if v_baseline_text is not null then
    select count(*) filter (where night_result = 'calm')
      into v_recent_calm
    from (
      select night_result
      from public.daily_logs
      where follower_id = p_parent_id and night_result is not null
      order by log_date desc
      limit 3
    ) recent3;

    v_show_baseline := v_recent_calm > v_baseline_calm;
  end if;

  return jsonb_build_object(
    'in_stage',          true,
    'stage_id',          v.stage_id,
    'problem_key',       v.problem_key,
    'problem_context_text', v_problem_context,
    'frequency_label',   v_frequency_label,
    'objective_text',    v.objective_text,
    'objective_target',  v.objective_target,
    'objective_window',  v.objective_window,
    'objective_current', v.objective_current,
    'window_filled',     v.window_filled,
    'objective_met',     v.objective_met,
    'logged_days',       v.logged_days,
    'allowed_days',      v.allowed_days,
    'days_remaining',    v.days_remaining,
    'clock_exhausted',   v.clock_exhausted,
    'extended',          v.status = 'extended',
    'phase',             v.phase,
    'phase_ar', case v.phase
      when 'observe' then 'نراقب — لم نغيّر شيئاً بعد، نتعرّف على ما يحدث فعلاً'
      when 'build'   then 'نبني — خطوة كل يوم على ما نفع أمس'
      else                'نُمسك — أتراجع عمداً، لنرى الهدوء وهو يصمد بلا تذكير'
    end,
    'baseline_text', case when v_show_baseline then v_baseline_text else null end);
end;
$function$;


-- ------------------------------------------------------------
-- BEHAVIOURAL: on arrival ADAM refuses the credit outright —
-- «لم أفعل هذا أنا» — and the relapse branch reaches for the step
-- that actually worked before rather than starting over.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.arrival_message(p_parent_id uuid, p_kind text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_nl text := chr(10);
  v_child text; v_objective text; v_days int; v_best text; v_won int; v_of int;
  v_lines text[] := '{}';
begin
  if p_kind not in ('arrived','what_now','relapse') then
    return jsonb_build_object('ok', false, 'reason', 'unknown_kind', 'given', p_kind);
  end if;

  select w.objective_text, greatest(1, (current_date - w.completed_at::date))
    into v_objective, v_days
  from public.v_arrival_watch w where w.parent_id = p_parent_id;

  if v_objective is null then
    return jsonb_build_object('ok', false, 'reason', 'no_arrival');
  end if;

  select nullif(btrim(c.name),'') into v_child
  from public.children c
  where c.follower_id = p_parent_id and c.name not in ('الطفل','الطفلة')
  order by c.is_primary desc, c.created_at limit 1;

  select coalesce(d.step_given, d.seed_text),
         count(*) filter (where d.step_status = 'done'), count(*)
    into v_best, v_won, v_of
  from public.daily_logs d
  where d.follower_id = p_parent_id
    and coalesce(d.step_given, d.seed_text) is not null
  group by coalesce(d.step_given, d.seed_text)
  having count(*) filter (where d.step_status = 'done') > 0
  order by count(*) filter (where d.step_status = 'done') desc, count(*) desc
  limit 1;

  if p_kind = 'arrived' then
    v_lines := array_append(v_lines, '🌿 وصلتم.');
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, (v_objective || '.'));
    v_lines := array_append(v_lines, 'هذا ما اتّفقنا عليه، وهذا ما صار.');
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, 'لم أفعل هذا أنا. أنا سألتكم كل مساء سؤالاً واحداً وكتبت الجواب.');
    v_lines := array_append(v_lines, 'أنتم من جرّب، في أصعب ساعة من يومكم،');
    v_lines := array_append(v_lines, 'وأعاد المحاولة بعد الليالي التي لم تنجح.');
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, 'الليلة لا خطوة ولا سؤال.');
    v_lines := array_append(v_lines, 'فقط أردتُ أن تعرفوا أنّ ما تعبتم فيه ظهر.');

  elsif p_kind = 'what_now' then
    v_lines := array_append(v_lines, '🌿 مرّت أيام على وصولكم، وما زالت هادئة.');
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, 'من هنا، الأمر لكم:');
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, '👁 نُبقي عيناً على ما وصلنا إليه — أسألكم مرّة في الأسبوع بدل كل مساء.');
    v_lines := array_append(v_lines, '   إن رجعت الليالي الصعبة، أعرف قبل أن تصير عادة. وهذا يبقى مجانياً.');
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, ('🎯 أو نعمل على شيء آخر يتعبكم مع ' || coalesce(v_child,'طفلكم') || '.'));
    v_lines := array_append(v_lines, '   نتّفق على هدف، ونمشي إليه كما فعلنا تماماً.');
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, '🌿 أو نكتفي بهذا. تعرفون أين أجدكم، وأنا لا أختفي.');

  else
    v_lines := array_append(v_lines, '🌿 لاحظتُ أنّ الليالي رجعت صعبة هذا الأسبوع.');
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, 'هذا يحدث — الهدوء لا يمشي في خط مستقيم.');
    if v_best is not null then
      v_lines := array_append(v_lines, 'والفرق أنّنا لا نبدأ من الصفر: نعرف ما نجح معكم آخر مرّة.');
      v_lines := array_append(v_lines, '');
      v_lines := array_append(v_lines,
        ('«' || v_best || '» نجح ' || public.ar_digits(v_won::text)
              || ' من ' || public.ar_digits(v_of::text) || ' ليالٍ.'));
      v_lines := array_append(v_lines, 'نعيده أسبوعاً ونرى؟');
    else
      v_lines := array_append(v_lines, 'ونحن نعرف بيتكم الآن أكثر ممّا كنّا نعرفه في البداية.');
      v_lines := array_append(v_lines, 'احكوا لي ما تغيّر، ونبدأ من حيث نحن.');
    end if;
  end if;

  return jsonb_build_object('ok', true, 'kind', p_kind,
    'body', array_to_string(v_lines, v_nl),
    'child_name', v_child, 'days_since_arrival', v_days);
end $function$;


-- ------------------------------------------------------------
-- BEHAVIOURAL: the rough-patch override. Three nights with no
-- calm and at least two hard, and ADAM stops proposing anything
-- — whatever phase the journey is in. A parent in the worst week
-- of the month does not need another thing to try.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.compose_journey_step(p_parent_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_stage   jsonb;
  v_gate    jsonb;
  v_phase   text;
  v_child   text;
  v_sit     text;
  v_last_result text;
  v_last_step   text;
  v_last_status text;
  v_working text;
  v_recent  jsonb;
  v_directive text;
  v_rough   boolean;
begin
  v_stage := public.stage_state(p_parent_id);
  if not coalesce((v_stage->>'in_stage')::boolean, false) then
    return jsonb_build_object('in_journey', false);
  end if;

  v_gate  := public.can_send('journey_step', p_parent_id);
  v_phase := v_stage->>'phase';

  select nullif(btrim(c.name), '') into v_child
  from public.children c where c.follower_id = p_parent_id
  order by c.is_primary desc nulls last, c.created_at limit 1;

  v_sit := public.hard_moment_label(v_stage->>'problem_key');

  select d.night_result, d.step_given, d.step_status
    into v_last_result, v_last_step, v_last_status
  from public.daily_logs d
  where d.follower_id = p_parent_id and d.night_result is not null
  order by d.log_date desc limit 1;

  select nullif(btrim(d.step_given), '') into v_working
  from public.daily_logs d
  where d.follower_id = p_parent_id
    and nullif(btrim(d.step_given), '') is not null
    and (d.step_status = 'done' or d.night_result = 'calm')
  order by d.log_date desc limit 1;

  select coalesce(jsonb_agg(s order by rn), '[]'::jsonb) into v_recent
  from (
    select nullif(btrim(d.step_given), '') as s,
           row_number() over (order by d.log_date desc) as rn
    from public.daily_logs d
    where d.follower_id = p_parent_id
      and nullif(btrim(d.step_given), '') is not null
    order by d.log_date desc limit 5
  ) t
  where s is not null;

  -- ⭐ same rough-patch signal as can_ground_seed/get_harvest_prompt.
  select count(*) filter (where d.night_result = 'hard') >= 2
     and count(*) filter (where d.night_result = 'calm') = 0
    into v_rough
  from public.daily_logs d
  where d.follower_id = p_parent_id
    and d.log_date > current_date - 3 and d.log_date < current_date;
  v_rough := coalesce(v_rough, false);

  if v_rough then
    v_directive :=
      'آخر أيام كانت ثقيلة (لا ليلة هادئة، وليلتان صعبتان على الأقل). لا تقترح خطوة جديدة الليلة مهما كانت المرحلة. '
      || 'اكتفِ بحضور هادئ: اعترف أن الفترة صعبة، بلا انتظار تحسّن فوري، واسألهم كيف مرّت الليلة بلا أي اقتراح.';
  else
    v_directive := case v_phase
      when 'observe' then
        'لا تقترح خطوة جديدة الليلة. اطلب منهم أن يلاحظوا '
        || coalesce(v_sit, 'الموقف الصعب')
        || ' دون أن يغيّروا شيئاً — متى يبدأ بالضبط، وما الذي يسبقه. '
        || 'نحن نتعرّف على ما يحدث فعلاً قبل أن نغيّره.'
      when 'hold' then
        'تراجَع عمداً. لا تقترح خطوة. ذكّرهم بهدوء أنهم صاروا يعرفون ما ينفع مع '
        || coalesce(v_child, 'طفلهم')
        || '، واسأل فقط كيف مرّت الليلة. الهدوء يجب أن يُرى وهو يصمد بلا تذكير منك.'
      else
        'اقترح خطوة واحدة صغيرة'
        || coalesce(' مبنية على ما نفع سابقاً: «' || v_working || '»', '')
        || '، قابلة للتجربة في أسوأ ليلة، مرتبطة بـ '
        || coalesce(v_child, 'طفلهم') || ' و' || coalesce(v_sit, 'الموقف') || '. '
        || 'لا تكرّر خطوة سبق أن أعطيتها.'
    end;
  end if;

  return jsonb_build_object(
    'in_journey',        true,
    'can_send',          coalesce((v_gate->>'can_send')::boolean, false),
    'reason',            v_gate->>'reason',
    'phase',             v_phase,
    'phase_ar',          v_stage->>'phase_ar',
    'phase_directive',   v_directive,
    'is_rough_patch',    v_rough,
    'objective_text',    v_stage->>'objective_text',
    'objective_current', (v_stage->>'objective_current'),
    'objective_target',  (v_stage->>'objective_target'),
    'days_remaining',    (v_stage->>'days_remaining'),
    'logged_days',       (v_stage->>'logged_days'),
    'child_name',        v_child,
    'situation',         v_sit,
    'last_night', jsonb_build_object(
      'result', v_last_result, 'step', v_last_step, 'status', v_last_status),
    'last_working_step', v_working,
    'recent_steps',      v_recent);
end;
$function$;


-- ------------------------------------------------------------
-- BEHAVIOURAL: the same rough-patch rule, applied to the evening
-- question itself. After three heavy nights the question drops
-- every reminder of what was supposed to work and becomes only
-- «بس احكولي كيف كانت الليلة».
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_harvest_prompt(p_parent_id uuid, p_day_id uuid DEFAULT NULL::uuid)
 RETURNS text
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_nl text := chr(10); v_name text; v_today date; v_country text;
  v_sit_id uuid; v_sit_label text; v_step text; v_prev_step text;
  v_calm_here integer; v_gift text; v_streak integer; v_streak_line text;
  v_hard_recent integer; v_calm_recent integer;
begin
  select upper(btrim(f.country)) into v_country
  from public.followers f where f.id = p_parent_id;
  if not found then return null; end if;

  select coalesce((now() at time zone ct.iana_tz)::date, current_date) into v_today
  from public.country_timezone ct where ct.code = v_country;
  v_today := coalesce(v_today, current_date);

  select nullif(btrim(c.name), '') into v_name
  from public.children c where c.follower_id = p_parent_id
  order by c.is_primary desc nulls last, c.created_at limit 1;

  -- ⭐ Rough-patch check: last 3 nights, zero calm and 2+ hard.
  select count(*) filter (where d.night_result = 'hard'),
         count(*) filter (where d.night_result = 'calm')
    into v_hard_recent, v_calm_recent
  from public.daily_logs d
  where d.follower_id = p_parent_id
    and d.log_date > v_today - 3 and d.log_date < v_today;

  if coalesce(v_hard_recent, 0) >= 2 and coalesce(v_calm_recent, 0) = 0 then
    return '🌿 آخر أيام كانت ثقيلة.' || v_nl || v_nl
        || 'بس احكولي كيف كانت الليلة، بلا انتظار شي معيّن.';
  end if;

  select coalesce(nullif(btrim(d.step_given), ''), nullif(btrim(d.seed_text), '')),
         d.situation_id
    into v_step, v_sit_id
  from public.daily_logs d
  where (p_day_id is not null and d.id = p_day_id)
     or (p_day_id is null and d.follower_id = p_parent_id and d.log_date = v_today)
  limit 1;

  v_sit_label := public.situation_label_ar(
    (select s.key from public.situations s where s.id = v_sit_id));

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

  select nullif(btrim(d.step_given), '') into v_prev_step
  from public.daily_logs d
  where d.follower_id = p_parent_id
    and d.night_result = 'calm'
    and d.log_date < v_today
    and nullif(btrim(d.step_given), '') is not null
  order by d.log_date desc limit 1;

  if v_name is not null and v_sit_label is not null and v_calm_here >= 2 then
    v_gift := v_name || ' هدأ ' || public.ar_occasions(v_calm_here)
           || ' هذا الشهر عند ' || v_sit_label || '.';
  elsif v_prev_step is not null then
    v_gift := 'آخر مرة نفعت معكم: ' || v_prev_step;
    if right(v_gift, 1) not in ('.', '؟', '!') then v_gift := v_gift || '.'; end if;
  elsif v_step is not null then
    v_gift := 'اليوم جرّبنا' || coalesce(' مع ' || v_name, '') || ': ' || v_step;
    if right(v_gift, 1) not in ('.', '؟', '!') then v_gift := v_gift || '.'; end if;
  else
    v_gift := 'مرّ يوم آخر' || coalesce(' مع ' || v_name, '') || '.';
  end if;

  with logged_nights as (
    select log_date from public.daily_logs
    where follower_id = p_parent_id and night_result is not null and log_date < v_today
  ),
  grp as (
    select log_date, log_date - (row_number() over (order by log_date))::int as island
    from logged_nights
  )
  select count(*) into v_streak from grp
  where island = (select island from grp order by log_date desc limit 1);
  v_streak := coalesce(v_streak, 0);

  v_streak_line := case when v_streak in (3,5,7,10,14,21,29)
    then v_nl || '🔥 هذي ' || (v_streak + 1)::text || ' ليالٍ متتالية تحكون فيها لي.'
    else null end;

  return v_gift || coalesce(v_streak_line, '') || v_nl || v_nl || 'كيف مرّت؟';
end;
$function$;


-- ------------------------------------------------------------
-- BEHAVIOURAL: the == NOW == block leads with life_context, and
-- the journey block carries started_from, baseline and the
-- extension. External circumstance (travel, illness, an occasion)
-- reads differently from emotional state, and an agent that
-- cannot tell them apart answers «متعبة لأنها مسافرة» in the
-- tone reserved for «متعبة ويائسة».
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_agent_context(p_follower_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_out text := '';
  v_snap text;
  v_children text;
  v_patterns text;
  v_situations text;
  v_events text;
  v_logs text;
  v_stage jsonb;
  v_light_raw text;
  v_light jsonb;
  v_now_lines text := '';
  v_rhythm text;
begin
  v_out := '';

  select snapshot_text into v_snap
  from memory_snapshots where follower_id = p_follower_id and char_count > 0;
  if v_snap is not null then
    v_out := v_out || '== SUMMARY ==' || E'\n' || v_snap;
  end if;

  select string_agg(
    '- ' || name
    || coalesce(' ('||gender||')','')
    || coalesce(', '||age_note,'')
    || coalesce(', طبع: '||temperament,''), E'\n')
  into v_children from children where follower_id = p_follower_id;
  if v_children is not null then
    v_out := v_out || E'\n\n== CHILDREN ==\n' || v_children;
  end if;

  begin
    select light_memory into v_light_raw from followers where id = p_follower_id;
    if v_light_raw is not null and btrim(v_light_raw) <> '' then
      v_light := v_light_raw::jsonb;
    end if;
  exception when others then
    v_light := null;
  end;

  if v_light is not null then
    v_now_lines := '';
    -- ⭐ life_context surfaced first: external circumstance (travel,
    -- illness, an occasion) reads differently from emotional_state
    -- (psychological coping) and the agent should be able to tell them
    -- apart -- "متعبة لأنها مسافرة" needs a different tone than "متعبة
    -- ويائسة".
    if coalesce(v_light->>'life_context','') <> '' then
      v_now_lines := v_now_lines || '- ظرف حالي: ' || (v_light->>'life_context') || E'\n';
    end if;
    if coalesce(v_light->>'core_pain','') <> '' then
      v_now_lines := v_now_lines || '- الألم: ' || (v_light->>'core_pain') || E'\n';
    end if;
    if coalesce(v_light->>'emotional_state','') <> '' then
      v_now_lines := v_now_lines || '- الحالة: ' || (v_light->>'emotional_state') || E'\n';
    end if;
    if coalesce(v_light->>'continuity','') <> '' then
      v_now_lines := v_now_lines || '- نكمل: ' || (v_light->>'continuity') || E'\n';
    end if;
    if coalesce(v_light->>'last_win','') <> '' then
      v_now_lines := v_now_lines || '- آخر نجاح: ' || (v_light->>'last_win');
    end if;
    v_now_lines := btrim(v_now_lines, E'\n');
    if v_now_lines <> '' then
      v_out := v_out || E'\n\n== NOW ==\n' || v_now_lines;
    end if;
  end if;

  select string_agg(
    '- ['||status||' x'||evidence_count||'] '||pattern_label
    || coalesce(': '||description,''), E'\n')
  into v_patterns from child_patterns
  where follower_id = p_follower_id and status <> 'resolved';
  if v_patterns is not null then
    v_out := v_out || E'\n\n== PATTERNS ==\n' || v_patterns;
  end if;

  select string_agg(
    '- ' || s.label_ar || ': يظهر بين ' ||
    lpad(s.window_start::text,2,'0') || ':00-' || lpad(s.window_end::text,2,'0') || ':00',
    E'\n')
  into v_situations
  from situations s
  where s.parent_id = p_follower_id and s.status = 'confirmed';
  if v_situations is not null then
    v_out := v_out || E'\n\n== SITUATIONS ==\n' || v_situations;
  end if;

  select string_agg(line, E'\n') into v_events from (
    select '- ['||event_type||', '||to_char(occurred_at,'MM/DD')||'] '||title
           || coalesce(': '||summary,'') as line
    from memory_events
    where follower_id = p_follower_id and emotional_weight >= 3
    order by occurred_at desc limit 5
  ) t;
  if v_events is not null then
    v_out := v_out || E'\n\n== KEY_MOMENTS ==\n' || v_events;
  end if;

  select string_agg(line, E'\n') into v_logs from (
    select
      '- ['||log_date||'] ' ||
      case when source = 'rhythm' then
        coalesce(seed_text, '(بلا نص مسجّل)')
        || case step_status
             when 'done'         then ' — نُفذت، نفعت'
             when 'tried_failed' then ' — جُرّبت، لم تنفع'
             when 'not_tried'    then ' — لم تُجرَّب'
             else ' — بانتظار الرد'
           end
      else
        coalesce(summary,'')
        || coalesce(' | خطوة: '||step_given,'')
        || case step_completed when true then ' (نُفذت)' when false then ' (لم تُنفذ)' else '' end
      end as line
    from daily_logs
    where follower_id = p_follower_id
    order by log_date desc limit 3
  ) t;
  if v_logs is not null then
    v_out := v_out || E'\n\n== RECENT_DAYS ==\n' || v_logs;
  end if;

  select case
    when cs.cadence = 'stopped' then 'الرسالة اليومية: متوقفة الآن بطلب الأهل.'
    when cs.local_hour is not null then 'الرسالة اليومية: مفعّلة، حوالي الساعة ' || cs.local_hour || ':00 بتوقيتهم.'
    else null
  end
  into v_rhythm
  from checkin_state cs
  where cs.parent_id = p_follower_id;
  if v_rhythm is not null then
    v_out := v_out || E'\n\n== RHYTHM ==\n- ' || v_rhythm;
  end if;

  v_stage := public.stage_state(p_follower_id);
  if coalesce((v_stage->>'in_stage')::boolean, false) then
    v_out := v_out || E'\n\n== JOURNEY ==\n'
      || '- objective: ' || (v_stage->>'objective_text') || E'\n';
    if v_stage->>'problem_context_text' is not null then
      v_out := v_out || '- started_from: ' || (v_stage->>'problem_context_text')
             || coalesce(' ('||(v_stage->>'frequency_label')||')', '') || E'\n';
    end if;
    v_out := v_out
      || '- phase: ' || (v_stage->>'phase') || ' — ' || (v_stage->>'phase_ar') || E'\n'
      || '- logged_days: ' || (v_stage->>'logged_days')
      || ' / allowed_days: ' || (v_stage->>'allowed_days') || E'\n'
      || '- progress: ' || (v_stage->>'objective_current')
      || ' / ' || (v_stage->>'objective_target')
      || ' (window ' || (v_stage->>'window_filled') || ')';
    if v_stage->>'baseline_text' is not null then
      v_out := v_out || E'\n' || '- baseline: ' || (v_stage->>'baseline_text');
    end if;
    if coalesce((v_stage->>'extended')::boolean, false) then
      v_out := v_out || E'\n' || '- extended: نعم — مددنا المدة بلا مقابل لأننا لسه نشتغل على الهدف، ولم نصل بعد.';
    end if;
  end if;

  return btrim(v_out, E'\n');
end $function$;


-- ------------------------------------------------------------
-- BEHAVIOURAL: the first calm night ever logged gets its own
-- line instead of the generic acknowledgement, and the streak
-- line fires on the milestone nights. Both are once-only.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_harvest_context(p_parent_id uuid, p_answer text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_today   date;
  v_child   text;
  v_sit     text;
  v_seed    text;
  v_step    text;
  v_logged  integer;
  v_calm    integer;
  v_tok     jsonb;
  v_prev_calm integer;
  v_ask_intention boolean := false;
  v_intention_body text;
  v_offer   jsonb;
  v_offer_present boolean := false;
  v_streak  integer;
  v_streak_line text;
  v_calm_ever integer;
  v_first_win_line text;
begin
  select coalesce((now() at time zone ct.iana_tz)::date, current_date) into v_today
  from public.followers f
  left join public.country_timezone ct on ct.code = upper(btrim(f.country))
  where f.id = p_parent_id;
  v_today := coalesce(v_today, current_date);

  select nullif(btrim(c.name), '') into v_child
  from public.children c where c.follower_id = p_parent_id
  order by c.is_primary desc nulls last, c.created_at limit 1;

  select public.hard_moment_label(s.key) into v_sit
  from public.situations s
  join public.children c2 on c2.id = s.child_id
  where c2.follower_id = p_parent_id and s.status in ('candidate','confirmed')
  order by (s.status = 'confirmed') desc, s.evidence_count desc limit 1;

  select d.seed_text,
         coalesce(nullif(btrim(d.step_given), ''), nullif(btrim(d.seed_text), ''))
    into v_seed, v_step
  from public.daily_logs d
  where d.follower_id = p_parent_id and d.log_date = v_today;

  select count(*) filter (where d.night_result is not null),
         count(*) filter (where d.night_result = 'calm')
    into v_logged, v_calm
  from public.daily_logs d
  where d.follower_id = p_parent_id
    and d.log_date > v_today - 7 and d.log_date <= v_today;

  select count(*) filter (where d.night_result = 'calm') into v_prev_calm
  from public.daily_logs d
  where d.follower_id = p_parent_id
    and d.log_date > v_today - 14 and d.log_date <= v_today - 7;

  with logged_nights as (
    select log_date
    from public.daily_logs
    where follower_id = p_parent_id and night_result is not null
  ),
  grp as (
    select log_date,
           log_date - (row_number() over (order by log_date))::int as island
    from logged_nights
  )
  select count(*) into v_streak
  from grp
  where island = (select island from grp order by log_date desc limit 1);
  v_streak := coalesce(v_streak, 0);

  v_streak_line := case
    when v_streak in (3,5,7,10,14,21,29)
      then '🔥 هذي ' || v_streak::text || ' ليالٍ متتالية ترجعون فيها لي.'
    else null
  end;

  -- ⭐ NEW: first-ever calm night gets a distinct celebration, not the
  -- generic "OK" reply -- the Duolingo "first lesson" moment. Only fires
  -- once per family, ever (checked by total calm-night count = 1).
  select count(*) into v_calm_ever
  from public.daily_logs where follower_id = p_parent_id and night_result = 'calm';

  v_first_win_line := case
    when p_answer = 'ok' and coalesce(v_calm_ever,0) = 1
      then '🎉 هذه أول ليلة هادئة نسجّلها معاً — بداية حقيقية.'
    else null
  end;

  v_tok := public.family_tokens(p_parent_id);

  if p_answer = 'ok' then
    v_offer := public.take_offer_moment(p_parent_id);
    if coalesce((v_offer->>'present')::boolean, false) then
      v_offer_present := true;
    elsif public.should_ask_intention(p_parent_id) then
      v_ask_intention := true;
      perform public.record_intention_ask(p_parent_id);
      select body_ar into v_intention_body
      from public.conversation_moments where key = 'intention_ask';
    end if;
  end if;

  return jsonb_build_object(
    'child_name',   v_child,
    'situation',    v_sit,
    'seed_text',    v_seed,
    'step_given',   v_step,
    'answer',       p_answer,
    'nights_logged_this_week', coalesce(v_logged, 0),
    'calm_this_week',          coalesce(v_calm, 0),
    'calm_last_week',          coalesce(v_prev_calm, 0),
    'must_mention_one_of', v_tok->'measured',
    'fallback_key', case p_answer
                      when 'ok'     then 'harvest_reply_ok'
                      when 'failed' then 'harvest_reply_failed'
                      else               'harvest_reply_skip' end,
    'ask_intention',      v_ask_intention,
    'intention_ask_body', v_intention_body,
    'offer_present',      v_offer_present,
    'offer_fork_ar',      case when v_offer_present then v_offer->>'fork_ar' else null end,
    'offer_buttons',      case when v_offer_present then v_offer->'buttons' else '[]'::jsonb end,
    'streak_days',         v_streak,
    'streak_line',         v_streak_line,
    'first_win_line',      v_first_win_line);
end;
$function$;


-- ------------------------------------------------------------
-- BEHAVIOURAL: three additions the repo never had. The team
-- question is answered before intention capture (otherwise
-- «اشتراك» is written into a parent's intention forever); the
-- JOURNEY block is passed through to the agent rather than
-- stripped with the billing clock; and each phase carries one
-- explicit carve-out — a child in distress this instant is never
-- refused first aid because the journey is in its observe phase.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_agent_bundle(p_follower_id uuid, p_message text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_ctx   text;
  v_kd    jsonb;
  v_ask   jsonb;
  v_level integer;
  v_perm  text;
  v_known text;
  v_cap   jsonb;
  v_team  jsonb;
  v_stage jsonb;
  v_journey_directive text := '';
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

  -- PLAN_DAY / DAYS_LEFT are ours, not theirs. The JOURNEY block (new,
  -- lines prefixed "- ") is deliberately NOT stripped here — it is
  -- progress the family earned, not a billing clock, and the whole
  -- point of this migration is that the agent may see it.
  v_ctx := btrim((
    select coalesce(string_agg(l, chr(10)), '')
    from regexp_split_to_table(v_ctx, chr(10)) l
    where l !~ '^\s*(PLAN_DAY|DAYS_LEFT)\s*:'), E' \t\r\n');

  v_kd    := public.knowledge_depth(p_follower_id);
  v_level := coalesce((v_kd->>'level')::int, 0);

  -- ⭐1 Rewritten to name the forbidden move explicitly, in the same terms
  -- gate_grounded_reply checks — a false "yes you may" here would just be
  -- overruled at the gate, so the two must describe the same line.
  v_perm := case v_level
    when 0 then 'لا تعرف عن هذا البيت شيئاً بعد. أجب عن اللحظة التي أمامك فقط. ممنوع: أي اسم، أي تكرار، أي إشارة إلى ذاكرة أو سجلّ — لا شيء من هذا موجود بعد.'
    when 1 then 'تعرف اسم الطفل فقط. استعمله بطبيعية. ممنوع: الادّعاء بمعرفة ما يتكرّر معه أو نمط له — لم تريا ذلك بعد.'
    when 2 then 'تعرف الاسم وما يُتعب عادةً. يمكنك أن تقترح شيئاً صغيراً موجّهاً لذلك الموقف. ممنوع: قول «هذه المرة الثالثة» أو أي عدد تكرار — لم يُثبت نمط بعد.'
    when 3 then 'تعرف ما يتكرّر فعلاً — يمكنك أن تذكر ذلك مرّة، بلا مبالغة ولا رقم مختلق.'
    else        'تعرف هذا البيت جيّداً. يمكنك أن تسمّي هدفاً واضحاً إن كان الوقت مناسباً.'
  end;

  v_known := case when v_ctx = '' then 'لا شيء مسجّل عن هذا البيت بعد.' else v_ctx end;

  v_ask := public.take_country_ask(p_follower_id);

  -- ⭐2 The journey directive. stage_state() is the single source for
  -- phase; this only renders behaviour for it, exactly as
  -- compose_journey_step renders behaviour for the SAME phase value on
  -- the proactive side. Absent for a free parent (in_stage=false).
  -- ⭐3 Both observe/hold branches now carry one explicit carve-out: a
  -- live-now situation needing real first aid is answered with a single
  -- containment line (never framed as a new step), then control returns
  -- to the phase's normal behaviour. This does not weaken the phase --
  -- it distinguishes "new intervention design" (still fully blocked)
  -- from "the child is in distress this instant" (never blocked).
  v_stage := public.stage_state(p_follower_id);
  if coalesce((v_stage->>'in_stage')::boolean, false) then
    v_journey_directive := case v_stage->>'phase'
      when 'observe' then
        'العائلة في رحلة مدفوعة، طور المراقبة. لا تقترح خطوة تغييرية جديدة كجزء من المنهجية، حتى لو طُلبت منك صراحة — ' ||
        'الهدف الآن أن تُلاحَظ اللحظة الصعبة، لا أن تُغيَّر. إن سُئلت عن الهدف فاذكره كما هو في JOURNEY. ' ||
        'استثناء واحد فقط: لو الموقف حيّ الآن (الطفل في ضيق فعلي هذه اللحظة) والوالد يطلب فعلاً فورياً، أعطِ سطر احتواء آمن ' ||
        'ومحايد واحد بلا وصفه كخطوة أو تغيير منهج، ثم عد للمراقبة بلا سؤال إضافي.'
      when 'hold' then
        'العائلة في رحلة مدفوعة، طور الإمساك. ممنوع اقتراح أي خطوة جديدة في هذا الطور، حتى لو طُلبت منك صراحة — ' ||
        'العائلة تعرف الآن ما ينفع، ودورك أن تسأل عن الليلة بلا اقتراح، ليُرى الهدوء أنه ملكهم. ' ||
        'استثناء واحد فقط: لو الموقف حيّ الآن والوالد يطلب إسعافاً فورياً حقيقياً، أعطِ سطر احتواء آمن واحد بلا وصفه كخطوة، ثم عد لدورك المعتاد في هذا الطور.'
      else
        'العائلة في رحلة مدفوعة، طور البناء. يمكنك أن تشير إلى الهدف المتّفق عليه إن سُئلت، ' ||
        'وأن تبني على ما نفع سابقاً إن ورد في JOURNEY أو RECENT_DAYS.'
    end;
  end if;

  return jsonb_build_object(
    'context',         v_ctx,
    'knowledge_level', v_level,
    'allowed_moves',   coalesce(v_kd->'now_possible', '[]'::jsonb),
    'in_journey',      coalesce((v_stage->>'in_stage')::boolean, false),
    'phase',           v_stage->>'phase',
    -- One block, framed as OUR notes. Without the frame the model reads its
    -- own context as something the parent just said and answers a question
    -- nobody asked.
    'family_context',
      '[ما نعرفه عن هذا البيت — ملاحظاتنا نحن، لم يقلها الأهل الآن]' || chr(10)
      || v_known || chr(10) || chr(10)
      || '[ما يُسمح لك أن تدّعي معرفته]' || chr(10) || v_perm
      || case when v_journey_directive <> '' then
           chr(10) || chr(10) || '[الرحلة]' || chr(10) || v_journey_directive
         else '' end,
    'ask',         coalesce((v_ask->>'ask')::boolean, false),
    'ask_body',    v_ask->>'body',
    'ask_buttons', coalesce(v_ask->'buttons', '[]'::jsonb),
    'handled', false,
    'intention_captured', false);
end;
$function$;


-- ------------------------------------------------------------
-- BEHAVIOURAL: five states instead of a single page, a real
-- progress bar, and — in the gathering state — a countdown to a
-- specific night rather than «الصورة تتشكل». The countdown is
-- honest because it is governed by the same night count that
-- flips the state to 'full'.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.adam_reading(p_parent_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_nl        text := chr(10);
  v_paid      boolean;
  v_child     text;
  v_sit       text;
  v_nights    int;
  v_calm      int;
  v_hard      int;
  v_calm_prev int;
  v_trigger   text;
  v_calms     text;
  v_stage     jsonb;
  v_state     text;
  v_body      text;
  v_nights_word text;
  v_who       text;
  v_lines     text[] := '{}';
begin
  if p_parent_id is null then
    return jsonb_build_object('state', 'unknown', 'body', null);
  end if;

  select f.funnel_stage = 'paid_active' into v_paid
  from public.followers f where f.id = p_parent_id;
  if not found then
    return jsonb_build_object('state', 'unknown', 'body', null);
  end if;

  select nullif(btrim(c.name), '') into v_child
  from public.children c
  where c.follower_id = p_parent_id and c.name not in ('الطفل', 'الطفلة')
  order by c.is_primary desc, c.created_at limit 1;

  v_who := coalesce(v_child, 'طفلكم');

  select s.label_ar into v_sit
  from public.situations s
  where s.parent_id = p_parent_id and s.status = 'confirmed'
  order by s.evidence_count desc, s.last_observed desc limit 1;

  select count(*) filter (where d.night_result is not null),
         count(*) filter (where d.night_result = 'calm'),
         count(*) filter (where d.night_result = 'hard')
    into v_nights, v_calm, v_hard
  from public.daily_logs d where d.follower_id = p_parent_id;

  select count(*) filter (where d.night_result = 'calm') into v_calm_prev
  from public.daily_logs d
  where d.follower_id = p_parent_id
    and d.log_date >  current_date - 14
    and d.log_date <= current_date - 7;

  select public.hard_moment_label(d.hard_moment) into v_trigger
  from public.daily_logs d
  where d.follower_id = p_parent_id and d.hard_moment is not null
  group by d.hard_moment order by count(*) desc limit 1;

  select string_agg(line, v_nl) into v_calms from (
    select '• ' || coalesce(d.step_given, d.seed_text) || ' — نجحت '
           || (count(*) filter (where d.step_status = 'done'))::text
           || ' من ' || count(*)::text as line
    from public.daily_logs d
    where d.follower_id = p_parent_id
      and coalesce(d.step_given, d.seed_text) is not null
    group by coalesce(d.step_given, d.seed_text)
    having count(*) filter (where d.step_status = 'done') > 0
    order by count(*) filter (where d.step_status = 'done') desc, count(*) desc
    limit 3
  ) t;

  v_stage := public.stage_state(p_parent_id);

  v_nights_word := case when v_nights between 3 and 10 then 'ليالٍ' else 'ليلة' end;

  v_state := case
    when not v_paid and v_nights = 0 then 'locked'
    when not v_paid and v_nights > 0 then 'locked_preview'
    when v_nights = 0    then 'opened'
    when v_nights < 7    then 'gathering'
    else                      'full' end;

  if v_state = 'locked' then
    v_lines := array_append(v_lines, '✨ بصائر آدم');
    v_lines := array_append(v_lines, '');
    if v_sit is not null and v_child is not null then
      v_lines := array_append(v_lines, ('أعرف أنّ ما يتعبكم مع ' || v_child || ' هو ' || v_sit || '.'));
    elsif v_child is not null then
      v_lines := array_append(v_lines, ('أعرف ' || v_child || '، ولا أعرف بعد ما الذي يهدّئ ' || v_child || '.'));
    else
      v_lines := array_append(v_lines, 'لا أعرف بيتكم بعد بما يكفي لأقرأه.');
    end if;
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, 'والبصائر الكاملة تعطيكم شيئاً أهم من المعلومات:');
    v_lines := array_append(v_lines, 'تعرفون بالضبط وين وصلتوا، بدل ما تحسّون أنكم تدورون في نفس الدائرة كل يوم.');
    v_lines := array_append(v_lines, 'كل أسبوع تشوفون بأعينكم: هل تحسّن الوضع فعلاً أم لا — بالأرقام لا بالإحساس.');
    v_lines := array_append(v_lines, 'وتعرفون أي خطوة نفعت مع طفلكم بالذات، فلا تكرّرون تجربة فشلت من قبل.');
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, 'ابدأوا بالحكي عن يومكم معه، وتُفتح لكم أول لمحة من هنا.');

  elsif v_state = 'locked_preview' then
    v_lines := array_append(v_lines, ('✨ بصائر ' || v_who || ' — لمحة'));
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, ('حتى الآن: ' || v_nights::text || ' ' || v_nights_word || ' حكيتم لي عنها، '
                           || v_calm::text || ' منها مرّت بهدوء.'));
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, (public.render_progress_bar(v_calm::numeric / greatest(v_nights,1)::numeric) || ' هدوء'));
    v_lines := array_append(v_lines, '');
    if v_trigger is not null then
      v_lines := array_append(v_lines, '🔒 ولاحظت نمطاً يتكرّر عندكم بالذات — يظهر كاملاً، بالاسم والتفصيل، مع المرافقة الكاملة.');
    else
      v_lines := array_append(v_lines, '🔒 وبعد أسبوع كامل من الحكي، أقدر أقول لكم أي خطوة نفعت فعلاً وأيها لا — هذا يُفتح مع المرافقة الكاملة.');
    end if;

  elsif v_state = 'opened' then
    v_lines := array_append(v_lines, ('✨ بصائر ' || v_who || ' — فُتحت الآن'));
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, 'هذا ما أعرفه عنكم حتى اللحظة:');
    if v_child is not null then
      v_lines := array_append(v_lines, ('• طفلكم ' || v_child || '.'));
    end if;
    if v_sit is not null then
      v_lines := array_append(v_lines, ('• وما يتعبكم هو ' || v_sit || '.'));
    end if;
    if (v_stage->>'in_stage')::boolean then
      v_lines := array_append(v_lines, ('• واتّفقنا على: ' || (v_stage->>'objective_text') || '.'));
    end if;
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, 'من الليلة أبدأ أسألكم كل مساء سؤالاً واحداً قصيراً.');
    v_lines := array_append(v_lines, 'كل إجابة تضيف سطراً إلى هذه الصفحة.');
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, 'بعد ثلاث ليالٍ أريكم ما يتكرّر.');
    v_lines := array_append(v_lines, ('وبعد أسبوع أريكم ما يهدّئ ' || v_who || ' فعلاً، وكيف تغيّر.'));
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, 'لا شيء مطلوب منكم الآن سوى أن تحكوا لي كيف مرّت الليلة.');

  elsif v_state = 'gathering' then
    v_lines := array_append(v_lines, ('✨ بصائر ' || v_who));
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, ('حتى الآن: ' || v_nights::text || ' ' || v_nights_word || ' حكيتم لي عنها، '
                           || v_calm::text || ' منها مرّت بهدوء.'));
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, (public.render_progress_bar(v_calm::numeric / greatest(v_nights,1)::numeric) || ' هدوء'));
    v_lines := array_append(v_lines, '');
    if v_trigger is not null then
      v_lines := array_append(v_lines, ('وأصعبها يتكرّر ' || v_trigger || '.'));
      v_lines := array_append(v_lines, '');
    end if;
    if v_calms is not null then
      v_lines := array_append(v_lines, 'وما نجح معكم حتى الآن:');
      v_lines := array_append(v_lines, v_calms);
      v_lines := array_append(v_lines, '');
    end if;
    -- ⭐ Gap framing: concrete countdown instead of a vague "الصورة تتشكل".
    -- Honest here (unlike the free tier) because this IS governed by
    -- night count -- 'full' triggers at 7 logged nights.
    v_lines := array_append(v_lines, ('باقي ' || (7 - v_nights)::text || ' ' ||
      (case when 7 - v_nights = 1 then 'ليلة' else 'ليالٍ' end) ||
      ' حتى تكتمل الصورة الأسبوعية — وأقول لكم بالأرقام إن كان ما تفعلونه يعمل أم لا.'));

  else
    v_lines := array_append(v_lines, ('✨ بصائر ' || v_who));
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, ('من ' || v_nights::text || ' ' || v_nights_word || ' حكيتم لي عنها، '
                           || v_calm::text || ' مرّت بهدوء و'
                           || v_hard::text || ' كانت صعبة.'));
    v_lines := array_append(v_lines, '');
    v_lines := array_append(v_lines, (public.render_progress_bar(v_calm::numeric / greatest(v_nights,1)::numeric) || ' هدوء'));
    if v_trigger is not null then
      v_lines := array_append(v_lines, '');
      v_lines := array_append(v_lines, ('ما يتكرّر: أصعب اللحظات تأتي ' || v_trigger || '.'));
    end if;
    if v_calms is not null then
      v_lines := array_append(v_lines, '');
      v_lines := array_append(v_lines, ('وما يهدّئ ' || v_who || ' فعلاً — من تجربتكم أنتم، لا من نصيحة عامّة:'));
      v_lines := array_append(v_lines, v_calms);
    end if;
    v_lines := array_append(v_lines, '');
    if v_calm > v_calm_prev then
      v_lines := array_append(v_lines, 'وهذا الأسبوع أهدأ من الذي قبله.');
    elsif v_calm < v_calm_prev then
      v_lines := array_append(v_lines, 'وهذا الأسبوع أصعب من الذي قبله — يحدث، والمهم أنكم واصلتم.');
    else
      v_lines := array_append(v_lines, 'وهو ثابت مع الأسبوع الماضي.');
    end if;
    if (v_stage->>'in_stage')::boolean then
      v_lines := array_append(v_lines, '');
      v_lines := array_append(v_lines, ('الهدف: ' || (v_stage->>'objective_text') || '.'));
      v_lines := array_append(v_lines, (v_stage->>'phase_ar'));
    end if;
  end if;

  v_body := array_to_string(v_lines, v_nl);

  return jsonb_build_object(
    'state', v_state,
    'body', v_body,
    'child_name', v_child,
    'nights', v_nights,
    'calm', v_calm,
    'in_stage', coalesce((v_stage->>'in_stage')::boolean, false));
end $function$;


-- ------------------------------------------------------------
-- BEHAVIOURAL: menu_family (a real count of families, and an
-- unambiguous statement of belonging), the child screen falling
-- back through light_memory when no situation is confirmed yet,
-- and a progress screen that refuses to draw a bar before three
-- attempts exist to draw it from.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.compose_menu_body(p_key text, p_parent_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_nl text := chr(10); v_country text; v_today date;
  v_child uuid; v_name text; v_age text; v_sit text; v_pat text;
  v_e jsonb; v_tried integer; v_prev integer; v_calm integer; v_ever integer;
  v_cs jsonb; v_who text;
  v_lines text[] := '{}';
  v_light_raw text; v_light jsonb;
  v_sits text[]; v_pats text[];
  v_facts_count int := 0;
  v_families int;
begin
  -- ⭐ Two distinct feelings, in order: (1) trust/social proof — real
  -- families confide in Adam, so it's safe to; (2) belonging — a direct,
  -- unambiguous statement of membership, its own standalone line so it
  -- lands clearly rather than blending into the proof paragraph.
  if p_key = 'menu_family' then
    select count(distinct f.id) into v_families
    from public.followers f
    join public.children c on c.follower_id = f.id
    where f.platform_user_id not in ('7377091520','8074049810');

    return '🌳 عائلة آدم' || v_nl || v_nl
        || v_families::text || ' أماً وأباً يحكون لآدم كل يوم أشياء ما يقولونها لحد غيره — بنفس الصراحة اللي حكيتوها أنتم بأول رسالة.' || v_nl || v_nl
        || 'يثقون فيه لأنه يستحق الثقة: يسمع بلا حكم، ويتذكّر، ولا ينسى بيتاً واحداً منهم.' || v_nl || v_nl
        || '🌳 وأنتم، من هالثانية، جزء من عائلة آدم.';
  end if;

  if p_parent_id is null then
    if p_key = 'menu_ask_team' then
      return '🌿 احكوا لي ما حدث في أيّ وقت، وأعطيكم خطوة صغيرة تناسب موقفكم — بلا مقابل.' || v_nl || v_nl ||
             'وللفرق بين هذا وبين المرافقة الكاملة، اكتبوا /adam.';
    end if;
    if p_key = 'menu_child' then
      return '👦 ما أعرفه عن طفلكم' || v_nl || v_nl
          || 'ما زلت لا أعرف عنه شيئاً — وهذا بيدكم تماماً.' || v_nl || v_nl
          || 'كل ما حكيتم أكثر، فهمته أعمق؛ ولما أفهمه أكثر، تصير الخطوة التي أقترحها له هو، لا لأي طفل آخر.' || v_nl || v_nl
          || 'ابدأوا الآن: اكتبوا اسمه وما أكثر ما يتعبكم معه هذه الأيام.';
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
          || '🌿 كل ما بيننا الآن مجاني، ويبقى مجانياً — هذا لن يتغيّر أبداً.';
    elsif (v_cs->>'state') = 'unknown' then
      return 'لم أتعرّف على البلد.' || v_nl
          || 'لا بأس — كل ما بيننا يبقى كما هو، دون نقص.';
    else
      return '✅ سجّلنا بلدكم.' || v_nl || v_nl
          || 'وكل ما بيننا يبقى كما هو تماماً، مجاناً.' || v_nl || v_nl
          || 'أمّا المرافقة الكاملة فلم تصل إليه بعد، لسبب واحد:' || v_nl
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
    return '🌿 احكوا لي ما حدث في أيّ وقت، وأعطيكم خطوة صغيرة تناسب موقفكم مع ' || v_who || ' — بلا مقابل.' || v_nl || v_nl ||
           'وللفرق بين هذا وبين المرافقة الكاملة، اكتبوا /adam.';
  end if;

  if p_key = 'menu_child' then
    if v_name is null then
      return '👦 ما أعرفه عن طفلكم' || v_nl || v_nl
          || 'ما زلت لا أعرف عنه شيئاً — وهذا بيدكم تماماً.' || v_nl || v_nl
          || 'كل ما حكيتم أكثر، فهمته أعمق؛ ولما أفهمه أكثر، تصير الخطوة التي أقترحها له هو، لا لأي طفل آخر.' || v_nl || v_nl
          || 'ابدأوا الآن: اكتبوا اسمه وما أكثر ما يتعبكم معه هذه الأيام.';
    end if;

    select array_agg(distinct public.situation_label_ar(s.key))
      into v_sits
    from public.situations s
    where s.child_id = v_child and s.status in ('candidate','confirmed')
      and s.key is not null and s.key <> 'other';

    select array_agg(cp.pattern_label order by cp.evidence_count desc)
      into v_pats
    from public.child_patterns cp
    where cp.child_id = v_child and cp.safe_for_record;

    begin
      select light_memory into v_light_raw from public.followers where id = p_parent_id;
      if v_light_raw is not null and btrim(v_light_raw) <> '' then
        v_light := v_light_raw::jsonb;
      end if;
    exception when others then
      v_light := null;
    end;

    v_lines := array['👦 ما أعرفه عن ' || v_name || coalesce(' · ' || v_age, '')];
    v_lines := v_lines || ''::text;

    if v_light is not null and coalesce(v_light->>'child_insight','') <> '' then
      v_lines := v_lines || (v_light->>'child_insight')::text;
      v_facts_count := v_facts_count + 1;

      if v_sits is not null and array_length(v_sits,1) > 0 then
        v_lines := v_lines || ''::text;
        v_lines := v_lines || ('🔍 وأصعب اللحظات: ' || array_to_string(v_sits, '، '))::text;
      end if;

      v_lines := v_lines || ''::text;
      v_lines := v_lines || 'وهذا كله من كلامكم أنتم — وكلما حكيتم أكثر، صارت الخطوة أدق لبيتكم بالذات.'::text;

      return array_to_string(v_lines, v_nl);
    end if;

    if v_sits is not null and array_length(v_sits,1) > 0 then
      v_lines := v_lines || ('🔍 أصعب اللحظات مع ' || v_name || ': ' || array_to_string(v_sits, '، '))::text;
      v_facts_count := v_facts_count + 1;
    end if;

    if v_pats is not null and array_length(v_pats,1) > 0 then
      v_lines := v_lines || ('🧩 لاحظنا نمطاً متكرراً: ' || v_pats[1] ||
        case when array_length(v_pats,1) > 1 then '، و' || v_pats[2] else '' end)::text;
      v_facts_count := v_facts_count + 1;
    end if;

    if v_light is not null then
      if coalesce(v_light->>'core_pain','') <> '' then
        v_lines := v_lines || ('💭 ما يتعبكم أكثر: ' || (v_light->>'core_pain'))::text;
        v_facts_count := v_facts_count + 1;
      end if;
      if coalesce(v_light->>'emotional_state','') <> '' then
        v_lines := v_lines || ('🤍 حالتكم هذه الأيام: ' || (v_light->>'emotional_state'))::text;
        v_facts_count := v_facts_count + 1;
      end if;
      if coalesce(v_light->>'last_win','') <> '' then
        v_lines := v_lines || ('✨ آخر ما نجح: ' || (v_light->>'last_win'))::text;
        v_facts_count := v_facts_count + 1;
      end if;
    end if;

    if v_facts_count = 0 then
      v_lines := v_lines || 'لم يتّضح بعد ما الذي يتكرّر معه.'::text;
      v_lines := v_lines || ''::text;
      v_lines := v_lines || ('احكوا لي عن يومكم مع ' || v_name || '، وكلما حكيتم عرفته أكثر.')::text;
    else
      v_lines := v_lines || ''::text;
      v_lines := v_lines || ('وهذا كله من كلامكم أنتم — وكلما حكيتم أكثر، صارت الخطوة أدق لبيتكم بالذات.')::text;
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
      return '📈 تقدّمكم مع ' || v_who || v_nl || v_nl
          || 'لم نجرّب شيئاً معاً بعد.' || v_nl || v_nl
          || 'كيف تمشي الأمور: تحكون لي ما تعبتم منه اليوم، فأعطيكم شيئاً واحداً صغيراً تجرّبونه،' || v_nl
          || 'ثم أسألكم مساءً: هل تغيّر شيء؟' || v_nl || v_nl
          || 'وبعد ثلاث محاولات يصير عندي ما يكفي لأريكم الموقف الذي يتكرّر في بيتكم بالذات،' || v_nl
          || 'وما الذي يهدّئ ' || v_who || ' فيه.' || v_nl || v_nl
          || 'نبدأ الآن: احكوا لي ما حدث معه اليوم.';
    elsif v_ever < 3 then
      return '📈 تقدّمكم مع ' || v_who || v_nl || v_nl
          || 'جرّبتم معه ' || public.occasions_latin(v_ever) || ' حتى الآن.' || v_nl || v_nl
          || 'بعد ثلاث محاولات يصير عندي ما يكفي لأريكم الموقف الذي يتكرّر عندكم بالذات،' || v_nl
          || 'وما الذي يهدّئ ' || v_who || ' فيه — وهناك يبدأ الفرق الحقيقي.' || v_nl || v_nl
          || 'احكوا لي عن يومكم معه، ونكمل.';
    end if;

    v_lines := array['📈 تقدّمكم مع ' || v_who];
    v_lines := v_lines || ''::text;
    v_lines := v_lines || ('هذا الأسبوع: جرّبتم ' || public.occasions_latin(v_tried) || ' مع ' || v_who || '.')::text;

    if v_tried > 0 then
      v_lines := v_lines || ''::text;
      v_lines := v_lines || ('هذا الأسبوع  ' || public.render_progress_bar(v_calm::numeric / v_tried::numeric))::text;
      if v_prev > 0 then
        v_lines := v_lines || ('الأسبوع الماضي ' || public.render_progress_bar((select coalesce((v_e->>'calm_last_week')::numeric,0)) / v_prev::numeric))::text;
      end if;
      v_lines := v_lines || ''::text;
    end if;

    if v_calm > 0 then
      v_lines := v_lines || (case
        when v_calm = 1 then 'واحدة منها مرّت بهدوء.'
        when v_calm = 2 then 'اثنتان منها مرّتا بهدوء.'
        else v_calm::text || ' منها مرّت بهدوء.' end)::text;
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
-- BEHAVIOURAL: the whole tap router. The repo's version predates
-- the journey form (jf_*), the step-commitment card (sc_*), the
-- seed-intent taps (sdi_*) and the internal pattern review
-- (pat_yes_/pat_no_). Every one of those buttons ships in a live
-- message today; on a database built from the repo alone they
-- all fall through to «لم أفهم هذه تماماً» — the dead-button bug
-- the routing test exists to catch, reintroduced by drift rather
-- than by a code change.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_moment_after_tap(p_key text, p_parent_id uuid, p_country_code text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_rec  jsonb;
  v_req  uuid;
  v_done text := null;
  v_moment text := p_key;
  v_reading jsonb;
  v_join jsonb;
  v_cap jsonb;
  v_intent_result jsonb;
  v_screen jsonb;
  v_field  text;
  v_result jsonb;
  v_cs jsonb;
  v_reading_buttons jsonb;
  v_offer jsonb;
  v_review jsonb;
  v_commit jsonb;
  v_nl text := chr(10);
begin
  if p_key <> 'menu_capture_country' then
    update public.followers
       set country_asked_at = null
     where id = p_parent_id and country_asked_at is not null;
  end if;

  -- ⭐ NEW: step commitment card taps ("سأطبق ذلك" / "عندي استفسار آخر").
  if p_key = 'sc_commit' then
    v_commit := public.commit_chat_step(p_parent_id);
    if not coalesce((v_commit->>'committed')::boolean, false) then
      return jsonb_build_object('found', true, 'key', 'sc_commit', 'allowed', true,
        'category', 'reference', 'tier', 'fixed',
        'body', 'ما لقيت خطوة اليوم بعد — احكوا لي الموقف الأول.',
        'buttons', '[]'::jsonb, 'buttons_forbidden', false, 'max_lines', 2,
        'action_done', 'step_commit_missing');
    end if;
    return jsonb_build_object('found', true, 'key', 'sc_commit', 'allowed', true,
      'category', 'reference', 'tier', 'fixed',
      'body', case when coalesce((v_commit->>'is_paid')::boolean, false) and v_commit->>'objective_text' is not null
        then '✅ تمام — سجّلتها. هذي خطوة حقيقية تقرّبكم من هدفكم: «' || (v_commit->>'objective_text') || '».'
        else '✅ تمام — سجّلتها. كل خطوة صغيرة توخذ بجدية تصنع فرق حقيقي.' end,
      'buttons', '[]'::jsonb, 'buttons_forbidden', false, 'max_lines', 3,
      'action_done', 'step_committed');
  end if;

  if p_key = 'sc_more' then
    return jsonb_build_object('found', true, 'key', 'sc_more', 'allowed', true,
      'category', 'reference', 'tier', 'fixed',
      'body', 'تمام، احكوا لي شنو يشغل بالكم أكثر — كل ما تحكون أكثر، صارت الخطوة أدق.',
      'buttons', '[]'::jsonb, 'buttons_forbidden', false, 'max_lines', 2,
      'action_done', 'step_more_context_requested');
  end if;

  -- ⭐ NEW: pattern review taps (from the internal review message, not a
  -- family-facing menu). No parent_id needed -- the pattern id is self-
  -- contained in the callback data.
  if p_key like 'pat\_yes\_%' escape '\' then
    v_review := public.handle_pattern_review_tap(substring(p_key from 9)::uuid, true);
    return jsonb_build_object('found', true, 'key', 'pattern_review', 'allowed', true,
      'category', 'reference', 'tier', 'fixed',
      'body', v_review->>'body', 'buttons', '[]'::jsonb,
      'buttons_forbidden', false, 'max_lines', 4, 'action_done', 'pattern_approved');
  end if;
  if p_key like 'pat\_no\_%' escape '\' then
    v_review := public.handle_pattern_review_tap(substring(p_key from 8)::uuid, false);
    return jsonb_build_object('found', true, 'key', 'pattern_review', 'allowed', true,
      'category', 'reference', 'tier', 'fixed',
      'body', v_review->>'body', 'buttons', '[]'::jsonb,
      'buttons_forbidden', false, 'max_lines', 4, 'action_done', 'pattern_rejected');
  end if;

  if p_key in ('sdi_yes', 'sdi_no') then
    select platform_user_id into v_moment from public.followers where id = p_parent_id;
    v_intent_result := public.record_seed_intent(
      v_moment, case when p_key = 'sdi_yes' then 'will_try' else 'not_tonight' end);
    return jsonb_build_object(
      'found', true, 'key', p_key, 'allowed', true, 'category', 'rhythm',
      'tier', 'fixed',
      'body', case when p_key = 'sdi_yes' then '🌿 نتابع الليلة.' else 'تمام، نكون هنا لما يناسبكم.' end,
      'buttons', '[]'::jsonb, 'buttons_forbidden', false, 'max_lines', 2,
      'action_done', case when coalesce((v_intent_result->>'recorded')::boolean, false)
                           then 'intent_recorded' else 'intent_not_recorded' end);
  end if;

  if p_key = 'jf_start' then
    perform public.start_journey_form(p_parent_id);
    v_screen := public.compose_journey_form_screen(p_parent_id);
    return jsonb_build_object('found', true, 'key', 'jf_screen', 'allowed', true,
      'category', 'journey_form', 'tier', 'fixed',
      'body', v_screen->>'body', 'buttons', coalesce(v_screen->'buttons','[]'::jsonb),
      'buttons_forbidden', false, 'max_lines', 20, 'action_done', 'form_started');
  end if;

  if p_key = 'menu_change_goal' then
    update public.followers set agreed_objective = null, agreed_at = null where id = p_parent_id;
    perform public.start_journey_form(p_parent_id);
    v_screen := public.compose_journey_form_screen(p_parent_id);
    return jsonb_build_object('found', true, 'key', 'jf_screen', 'allowed', true,
      'category', 'journey_form', 'tier', 'fixed',
      'body', v_screen->>'body', 'buttons', coalesce(v_screen->'buttons','[]'::jsonb),
      'buttons_forbidden', false, 'max_lines', 20, 'action_done', 'form_restarted');
  end if;

  if p_key like 'jf_%' and p_key <> 'jf_capture_text' then
    if p_key = 'jf_other_problem' then
      perform public.await_journey_form_text(p_parent_id, 'problem_text');
      return jsonb_build_object('found', true, 'key', p_key, 'allowed', true,
        'category', 'journey_form', 'tier', 'fixed',
        'body', 'احكوا لي بكلماتكم: ما الذي يتعبكم معه؟', 'buttons', '[]'::jsonb,
        'buttons_forbidden', false, 'max_lines', 4, 'action_done', 'awaiting_problem_text');

    elsif p_key = 'jf_other_outcome' then
      perform public.await_journey_form_text(p_parent_id, 'outcome_text');
      return jsonb_build_object('found', true, 'key', p_key, 'allowed', true,
        'category', 'journey_form', 'tier', 'fixed',
        'body', 'بكلماتكم: ماذا تحبّون أن يتغيّر؟', 'buttons', '[]'::jsonb,
        'buttons_forbidden', false, 'max_lines', 4, 'action_done', 'awaiting_outcome_text');

    elsif p_key like 'jf_problem\_%' escape '\' then
      perform public.capture_journey_form_answer(p_parent_id, 'problem_key', substring(p_key from 12));

    elsif p_key like 'jf_freq\_%' escape '\' then
      perform public.capture_journey_form_answer(p_parent_id, 'frequency_key', substring(p_key from 9));

    elsif p_key like 'jf_outcome\_%' escape '\' then
      declare
        v_idx int;
        v_prob text;
        v_opts jsonb;
        v_text text;
      begin
        v_idx := substring(p_key from 12)::int;
        select journey_form_state->>'problem_key' into v_prob from public.followers where id = p_parent_id;
        v_opts := public.journey_outcome_options(v_prob);
        v_text := v_opts->>(v_idx - 1);
        perform public.capture_journey_form_answer(p_parent_id, 'outcome_text', coalesce(v_text, 'ما اخترتموه'));
      end;

    elsif p_key = 'jf_confirm_restart' then
      perform public.start_journey_form(p_parent_id);

    elsif p_key = 'jf_confirm_yes' then
      v_result := public.agree_objective_from_form(p_parent_id);
      if coalesce((v_result->>'agreed')::boolean, false) then
        if public.commerce_allowed_after_voluntary_form(p_parent_id) then
          v_offer := public.get_conversation_moment('menu_journey', p_parent_id, true);
          return v_offer || jsonb_build_object('action_done', 'goal_agreed_from_form');
        end if;
        return jsonb_build_object('found', true, 'key', 'jf_goal_saved_no_offer',
          'allowed', true, 'category', 'journey_form', 'tier', 'fixed',
          'body', 'سجّلت هدفكم: ' || coalesce(v_result->>'objective_text','') || '.' || chr(10) || chr(10)
               || 'خلّونا نكمل نتكلم شوي، ونرجع لهذا الموضوع لما يناسب الوقت أكثر.' || chr(10)
               || 'هو محفوظ عندي، ما يضيع.',
          'buttons', '[]'::jsonb, 'buttons_forbidden', false, 'max_lines', 4,
          'action_done', 'goal_agreed_offer_deferred');
      end if;
      perform public.start_journey_form(p_parent_id);
    end if;

    v_screen := public.compose_journey_form_screen(p_parent_id);
    if v_screen ? 'await_field' then
      perform public.await_journey_form_text(p_parent_id, v_screen->>'await_field');
    end if;
    return jsonb_build_object('found', true, 'key', 'jf_screen', 'allowed', true,
      'category', 'journey_form', 'tier', 'fixed',
      'body', v_screen->>'body', 'buttons', coalesce(v_screen->'buttons','[]'::jsonb),
      'buttons_forbidden', false, 'max_lines', 20, 'action_done', 'form_advanced');
  end if;

  if p_key = 'jf_capture_text' then
    select journey_form_state->>'awaiting_free_text_for' into v_field
    from public.followers where id = p_parent_id;
    if v_field is null then
      v_field := 'problem_text';
    end if;
    perform public.capture_journey_form_answer(p_parent_id, v_field, p_country_code);
    v_screen := public.compose_journey_form_screen(p_parent_id);
    if v_screen ? 'await_field' then
      perform public.await_journey_form_text(p_parent_id, v_screen->>'await_field');
    end if;
    return jsonb_build_object('found', true, 'key', 'jf_screen', 'allowed', true,
      'category', 'journey_form', 'tier', 'fixed',
      'body', v_screen->>'body', 'buttons', coalesce(v_screen->'buttons','[]'::jsonb),
      'buttons_forbidden', false, 'max_lines', 20, 'action_done', 'form_text_captured');
  end if;

  if p_key = 'menu_capture_country' then
    v_cap := public.capture_country_text(p_parent_id, p_country_code);
    if (v_cap->>'captured')::boolean then
      if (v_cap->>'joined')::boolean then
        v_moment := 'menu_waitlist_joined'; v_done := 'waitlisted';
      else
        v_moment := 'country_recorded'; v_done := 'country_recorded';
      end if;
    else
      v_moment := 'country_not_recognised'; v_done := 'country_unrecognised';
    end if;
    return coalesce(public.get_conversation_moment(v_moment, p_parent_id), '{}'::jsonb)
        || jsonb_build_object('action_done', v_done)
        || jsonb_build_object('captured', coalesce((v_cap->>'captured')::boolean, false));
  end if;

  if nullif(btrim(coalesce(p_country_code,'')), '') is not null then
    v_rec := public.record_country(p_parent_id, p_country_code);
    if coalesce((v_rec->>'ok')::boolean, false) is not true then
      v_done   := 'country_unknown';
      v_moment := 'country_other';
    end if;
  end if;

  if p_parent_id is not null and v_moment = p_key then
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
                else                                   21::smallint end);
      v_done   := 'hour_set';
      v_moment := 'menu_settings_hour_set';
    elsif p_key = 'menu_privacy_erased' then
      v_req := public.request_erasure(p_parent_id);
      if v_req is not null then
        perform public.execute_erasure(v_req);
        v_done := 'erased';
      end if;
    elsif p_key = 'menu_waitlist_join' then
      v_join := public.join_waitlist(p_parent_id);
      if (v_join->>'joined')::boolean then
        v_done   := 'waitlisted';
        v_moment := 'menu_waitlist_joined';
      elsif v_join->>'reason' = 'needs_country' then
        update public.followers set country_asked_at = now() where id = p_parent_id;
        v_done   := 'waitlist_needs_country';
        v_moment := 'menu_waitlist_ask_country';
      else
        v_done   := 'waitlist_not_needed';
        v_moment := 'menu_journey';
      end if;
    end if;
  end if;

  if p_key = 'menu_reading' then
    v_reading := public.adam_reading(p_parent_id);
    v_reading_buttons := case when v_reading->>'state' in ('locked','locked_preview')
      then jsonb_build_array(jsonb_build_object('label','🎯 أشوف المرافقة الكاملة','cb','menu_journey'))
      else '[]'::jsonb end;
    return coalesce(public.get_conversation_moment('menu_reading', p_parent_id), '{}'::jsonb)
        || jsonb_build_object('body', v_reading->>'body')
        || jsonb_build_object('buttons', v_reading_buttons)
        || jsonb_build_object('reading_state', v_reading->>'state')
        || jsonb_build_object('country_recorded', coalesce(v_rec, 'null'::jsonb))
        || jsonb_build_object('action_done', 'null'::jsonb);
  end if;

  return public.get_conversation_moment(
           v_moment,
           case when v_done = 'erased' then null else p_parent_id end)
       || jsonb_build_object('country_recorded', coalesce(v_rec, 'null'::jsonb))
       || jsonb_build_object('action_done', coalesce(to_jsonb(v_done), 'null'::jsonb));
end;
$function$;

commit;
