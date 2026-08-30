begin;

-- ============================================================
-- THE THIRTY-FOUR COME HOME
--
-- 34 functions existed only in production. They were applied by
-- hand and never written down, so the repository could not
-- rebuild its own database: a fresh `supabase db reset` produced
-- a schema that the n8n workflows and the mini app would both
-- crash against.
--
-- This file is the transcription of `pg_get_functiondef()` for
-- all 34, taken from production on 2026-08-30. Nothing here is
-- new behaviour and nothing here is a rewrite — it is the code
-- that is already running, finally under version control.
--
-- Verified by comparing md5(pg_get_functiondef()) per function
-- between production and a database built from these migrations
-- alone; see supabase/tests/README.md.
--
-- The EXECUTE grants deliberately are NOT repeated here. The
-- migration that follows this one in time
-- (20260830140000_close_the_anon_rpc_hole.sql) sweeps every
-- SECURITY DEFINER function in `public` and hands EXECUTE to
-- service_role alone — a sweep, not a list, so functions added
-- later are covered without anyone remembering to add a line.
-- ============================================================


-- ------------------------------------------------------------
-- 0. Two definitions moved to the front of the file.
--
-- They are referenced by LANGUAGE sql functions below
-- (compose_stage_welcome_json, get_activation_welcome_due), and
-- Postgres validates the body of a SQL-language function at
-- creation time. Defined later in the file, a fresh
-- `supabase db reset` would fail on them -- which is precisely
-- the class of breakage this whole file exists to end.
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.journey_completion_promises(p_problem_key text)
 RETURNS jsonb
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select case p_problem_key
    when 'anger' then '[
      "😌 هدوء يعود أسرع بكثير من قبل، لا نوبة تمتد لساعة",
      "🗣️ كلام بدل صراخ — تعبير عن الغضب لا انفجار منه",
      "🧠 تفهمون ما وراء الغضب فعلاً، لا مجرد ردة الفعل عليه",
      "💪 يزول شعور العجز أمام كل نوبة، ويحل مكانه إحساس أنكم تعرفون ماذا تفعلون"
    ]'::jsonb
    when 'out' then '[
      "🚪 خروج بلا معركة يومية عند الباب",
      "⏱️ استعداد أسرع، بلا تذكير متكرر ولا صراخ",
      "🤝 تعاون حقيقي بدل شد وجذب كل صباح",
      "🧠 فهم واضح لما يصعّب عليه الخروج بالذات"
    ]'::jsonb
    when 'screen' then '[
      "📱 إغلاق الجهاز بهدوء، بلا نوبة غضب كل مرة",
      "⏳ وقت شاشة متوازن، بلا حرب يومية عليه",
      "🎨 أنشطة أخرى تعود لحياته تدريجياً",
      "🧠 فهم السبب الحقيقي وراء تعلّقه، لا مجرد منعه"
    ]'::jsonb
    when 'stubborn' then '[
      "✅ استجابة من أول مرة، بلا تكرار الطلب عشر مرات",
      "💬 نقاش أقل عند كل طلب بسيط",
      "🌿 تقبّل الرفض بهدوء حين يكون الجواب لا",
      "🧠 فهم ما يقف وراء العناد، لا مجرد مواجهته"
    ]'::jsonb
    when 'study' then '[
      "📚 بدء الواجب بلا مماطلة ولا معركة يومية",
      "🎯 تركيز أطول، بجلسة واحدة لا عشر محاولات",
      "😌 إنهاء الواجب بهدوء، لا بصراخ من الطرفين",
      "🧠 معرفة أي وقت وطريقة تناسبه هو بالذات"
    ]'::jsonb
    when 'sleep' then '[
      "🌙 نوم بلا بكاء ولا صراخ عند وقت السرير",
      "⏰ نوم مبكر، بلا ساعات من التعب والمقاومة",
      "🌛 هدوء سريع لو استيقظ ليلاً",
      "💪 يزول القلق كل مساء من معركة النوم قبل أن تبدأ"
    ]'::jsonb
    when 'meal' then '[
      "🍽️ أكل بلا معركة على الطاولة كل وجبة",
      "🥦 استعداد أكبر لتجربة أطعمة جديدة",
      "⏱️ إنهاء الوجبة بوقت معقول، بلا مطاردة بالملعقة",
      "🧠 فهم ما يقف فعلاً وراء رفضه للطعام"
    ]'::jsonb
    when 'sibling' then '[
      "🤍 تقبّل مشاركة وقت الأهل مع إخوته بهدوء أكبر",
      "🕊️ مقارنات أقل، وتوتر أقل بين الإخوة",
      "🤝 علاقة أهدأ وأقرب بينه وبين إخوته",
      "🧠 فهم أعمق لمصدر الغيرة الحقيقي"
    ]'::jsonb
    else '[
      "🎯 تغيّر حقيقي وملموس فيما كان يتعبكم يومياً",
      "🧠 فهم أعمق لما وراء سلوكه، لا مجرد ردة الفعل عليه",
      "📊 صورة واضحة بالأرقام لما ينفع ولما لا ينفع معه بالذات",
      "💪 زوال شعور العجز، ومكانه إحساس أنكم تعرفون كيف تتصرفون"
    ]'::jsonb
  end;
$function$;

CREATE OR REPLACE FUNCTION public.compose_stage_welcome(p_parent_id uuid, p_is_extension boolean DEFAULT false)
 RETURNS text
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_nl text := chr(10);
  v_who text; v_problem_key text; v_objective text; v_context text;
  v_promises jsonb; v_lines text[] := '{}'; v_row record;
  v_ext_days text;
begin
  select nullif(btrim(c.name),''), s.problem_key, s.objective_text, s.problem_context_text,
         coalesce(s.extension_days::text, '15')
    into v_who, v_problem_key, v_objective, v_context, v_ext_days
  from public.stages s
  left join public.children c on c.id = s.child_id
  where s.parent_id = p_parent_id and s.status in ('active','extended')
  order by s.started_at desc limit 1;

  if v_objective is null then
    return null;
  end if;
  v_who := coalesce(v_who, 'طفلكم');
  v_promises := public.journey_completion_promises(v_problem_key);

  if not p_is_extension then
    v_lines := v_lines || ('🌱 تبدأ رحلتنا الآن، مع ' || v_who || '.')::text;
    v_lines := v_lines || ''::text;
    if v_context is not null then
      v_lines := v_lines || (v_context || ' — نعرفها، وسنعمل عليها معاً كل يوم حتى تتغيّر فعلاً.')::text;
      v_lines := v_lines || ''::text;
    end if;
    v_lines := v_lines || ('الهدف الذي اتّفقنا عليه: ' || v_objective || '.')::text;
    v_lines := v_lines || ''::text;
    v_lines := v_lines || '✨ بعد نهاية رحلتنا معاً:'::text;
  else
    v_lines := v_lines || ('🌿 لسنا انتهينا بعد مع ' || v_who || '.')::text;
    v_lines := v_lines || ''::text;
    -- ⭐ Fixed: matches the real policy (half the duration extra, once),
    -- not an open-ended promise. Same wording as the pricing/journey
    -- screens now, everywhere, no contradiction.
    v_lines := v_lines || ('وعدناكم: إن لم نصل إلى الهدف في المدّة، نُكمل معكم ' || v_ext_days || ' يوماً إضافية مجاناً. وهذا ما نفعله الآن.')::text;
    v_lines := v_lines || ''::text;
    v_lines := v_lines || 'هذا ليس تنازلاً منّا — هذا التزام. والمدة الإضافية ليست وقتاً زائداً بلا معنى، بل فرصة حقيقية أن يُثمر ما بنيتموه حتى الآن.'::text;
    v_lines := v_lines || ('الهدف نفسه، ولم يتغيّر: ' || v_objective || '.')::text;
    v_lines := v_lines || ''::text;
    v_lines := v_lines || '✨ وما زال ينتظركم عند الوصول:'::text;
  end if;

  for v_row in select value as p from jsonb_array_elements_text(v_promises) loop
    v_lines := v_lines || ('- ' || v_row.p)::text;
  end loop;

  v_lines := v_lines || ''::text;
  v_lines := v_lines || 'وهذا لا يصل من تلقاء نفسه.'::text;
  v_lines := v_lines || 'يحتاج التزاماً منكم بالخطوة كل يوم، مهما كانت صغيرة — فالثبات هو ما يبني الفرق، لا يوم واحد ممتاز وسط أيام متروكة.'::text;
  v_lines := v_lines || ''::text;
  v_lines := v_lines || 'نبدأ الآن. وأنا هنا معكم في كل خطوة.'::text;

  return array_to_string(v_lines, v_nl);
end;
$function$;


-- ------------------------------------------------------------
-- 1. Small writes and reads
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.await_journey_form_text(p_parent_id uuid, p_field text)
 RETURNS jsonb
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
  update public.followers
     set journey_form_state = coalesce(journey_form_state, jsonb_build_object('step','problem'))
         || jsonb_build_object('awaiting_free_text_for', p_field, 'awaiting_since', now())
   where id = p_parent_id
  returning journey_form_state;
$function$;

CREATE OR REPLACE FUNCTION public.commerce_allowed_after_voluntary_form(p_parent_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
  select coalesce((
    select ps.level < 3
       and not exists (
         select 1 from public.crisis_flags cf
         where cf.parent_id = p_parent_id
           and cf.detected_at > now() - interval '24 hours')
    from public.parent_strain ps
    where ps.parent_id = p_parent_id
  ), true);
$function$;

CREATE OR REPLACE FUNCTION public.compose_stage_welcome_json(p_parent_id uuid, p_is_extension boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
  select jsonb_build_object('message', public.compose_stage_welcome(p_parent_id, p_is_extension));
$function$;

CREATE OR REPLACE FUNCTION public.mark_activation_welcome_sent(p_parent_id uuid)
 RETURNS void
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
  update public.followers set activation_welcome_sent_at = now() where id = p_parent_id;
$function$;

CREATE OR REPLACE FUNCTION public.mark_pattern_revealed(p_pattern_id uuid)
 RETURNS void
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
  update public.child_patterns set revealed_at = now() where id = p_pattern_id;
$function$;

CREATE OR REPLACE FUNCTION public.mark_situation_checked(p_child_id uuid)
 RETURNS void
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
  update public.children set situation_checked_at = now() where id = p_child_id;
$function$;

CREATE OR REPLACE FUNCTION public.mark_strain_checked(p_parent_id uuid)
 RETURNS void
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
  update public.followers set strain_checked_at = now() where id = p_parent_id;
$function$;

-- The mini app asks this before spending a model call on a
-- refresh: has the parent said anything since the last one?
CREATE OR REPLACE FUNCTION public.needs_live_refresh(p_platform_user_id text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
  select exists (
    select 1
    from public.n8n_chat_histories h
    join public.followers f on f.platform_user_id = p_platform_user_id
    where h.session_id = p_platform_user_id
      and h.created_at > coalesce(f.light_memory_updated_at, '-infinity'::timestamptz)
  );
$function$;

CREATE OR REPLACE FUNCTION public.needs_live_refresh_json(p_platform_user_id text)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
  select jsonb_build_object('should_refresh', public.needs_live_refresh(p_platform_user_id));
$function$;

CREATE OR REPLACE FUNCTION public.occasions_latin(p_n integer)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'pg_catalog', 'public'
AS $function$
  select case
    when p_n is null or p_n <= 0 then 'لا شيء بعد'
    when p_n = 1                 then 'مرة واحدة'
    when p_n = 2                 then 'مرّتين'
    when p_n <= 10               then p_n::text || ' مرات'
    else                              p_n::text || ' مرة'
  end;
$function$;

CREATE OR REPLACE FUNCTION public.record_winback_sent(p_parent_id uuid)
 RETURNS void
 LANGUAGE sql
 SET search_path TO 'pg_catalog', 'public'
AS $function$
  update public.checkin_state
     set winback_sent_at = now(), updated_at = now()
   where parent_id = p_parent_id;
$function$;

CREATE OR REPLACE FUNCTION public.render_progress_bar(p_ratio numeric, p_segments integer DEFAULT 10)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_filled integer;
  v_pct    integer;
begin
  if p_ratio is null then return null; end if;
  v_pct    := round(greatest(0, least(1, p_ratio)) * 100)::integer;
  v_filled := round(greatest(0, least(1, p_ratio)) * p_segments)::integer;
  return repeat('▓', v_filled) || repeat('░', p_segments - v_filled)
       || ' ' || v_pct::text || '%';
end;
$function$;

CREATE OR REPLACE FUNCTION public.start_journey_form(p_parent_id uuid)
 RETURNS jsonb
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
  update public.followers
     set journey_form_state = jsonb_build_object('step', 'problem')
   where id = p_parent_id
  returning journey_form_state;
$function$;


-- ------------------------------------------------------------
-- 2. Batch readers the n8n schedules poll, and the writes they
--    pair with. Each one is hour-aware: nothing reaches a parent
--    outside their own waking hours.
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.capture_journey_form_answer(p_parent_id uuid, p_field text, p_value text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_state jsonb;
  v_step  text;
begin
  if p_field not in ('problem_key','problem_text','frequency_key','outcome_key','outcome_text') then
    return jsonb_build_object('ok', false, 'reason', 'unknown_field');
  end if;

  select coalesce(journey_form_state, jsonb_build_object('step','problem'))
    into v_state
  from public.followers where id = p_parent_id;

  v_state := v_state || jsonb_build_object(p_field, nullif(btrim(coalesce(p_value,'')), ''));
  v_state := v_state - 'awaiting_free_text_for' - 'awaiting_since';

  v_step := case
    when p_field in ('problem_key','problem_text') then 'frequency'
    when p_field = 'frequency_key'                 then 'outcome'
    when p_field in ('outcome_key','outcome_text')  then 'confirm'
    else v_state->>'step' end;

  v_state := v_state || jsonb_build_object('step', v_step);

  update public.followers set journey_form_state = v_state where id = p_parent_id;

  return jsonb_build_object('ok', true, 'state', v_state);
end;
$function$;

CREATE OR REPLACE FUNCTION public.deactivate_subscription(p_follower_id uuid, p_reason text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_stage_id uuid;
begin
  if not exists (select 1 from public.followers where id = p_follower_id) then
    return jsonb_build_object('deactivated', false, 'reason', 'no_such_follower');
  end if;

  select id into v_stage_id from public.stages
  where parent_id = p_follower_id and status in ('active','extended','paused')
  limit 1;

  if v_stage_id is not null then
    update public.stages
    set status = 'cancelled', completed_at = now()
    where id = v_stage_id;
  end if;

  update public.followers
  set funnel_stage = 'free_conversation',
      subscription_started_at = null,
      subscription_expires_at = null
  where id = p_follower_id;

  return jsonb_build_object('deactivated', true, 'stage_id', v_stage_id,
    'reason_note', p_reason, 'follower_id', p_follower_id);
end;
$function$;

-- Strain steps DOWN one level at a time, never straight to zero:
-- a parent who was drowning yesterday is not fine today.
CREATE OR REPLACE FUNCTION public.decay_strain_levels()
 RETURNS TABLE(parent_id uuid, from_level smallint, to_level smallint)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
begin
  return query
  with due as (
    select ps.parent_id, ps.level
    from public.parent_strain ps
    where ps.level > 1
      and ps.return_eligible_at is not null
      and now() >= ps.return_eligible_at
  ),
  stepped as (
    update public.parent_strain ps
       set level = ps.level - 1,
           entered_at = now(),
           return_eligible_at = case when ps.level - 1 = 2 then now() + interval '24 hours'
                                      else null end,
           updated_at = now()
      from due d
     where ps.parent_id = d.parent_id
    returning ps.parent_id, d.level as from_lvl, ps.level as to_lvl
  )
  select s.parent_id, s.from_lvl::smallint, s.to_lvl::smallint from stepped s;
end;
$function$;

CREATE OR REPLACE FUNCTION public.get_activation_welcome_due(p_limit integer DEFAULT 50, p_only_platform_user_id text DEFAULT NULL::text)
 RETURNS TABLE(parent_id uuid, platform_user_id text, message_text text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
  select f.id, f.platform_user_id, public.compose_stage_welcome(f.id, false)
  from public.followers f
  where f.funnel_stage = 'paid_active'
    and f.activation_welcome_sent_at is null
    and public.compose_stage_welcome(f.id, false) is not null
    and (p_only_platform_user_id is null or f.platform_user_id = p_only_platform_user_id)
  limit p_limit;
$function$;

CREATE OR REPLACE FUNCTION public.get_patterns_pending_review(p_limit integer DEFAULT 50)
 RETURNS TABLE(pattern_id uuid, child_name text, pattern_label text, description text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
  select cp.id, coalesce(nullif(btrim(c.name),''), 'الطفل'), cp.pattern_label, cp.description
  from public.child_patterns cp
  join public.children c on c.id = cp.child_id
  where cp.safe_for_record = false
    and not exists (
      select 1 from public.pattern_record_approvals a
      where a.pattern_id = cp.id and a.pattern_label_at_approval = cp.pattern_label
        and a.approved_by not like 'system:%'
    )
  order by cp.last_observed desc
  limit p_limit;
$function$;

CREATE OR REPLACE FUNCTION public.get_reveal_due(p_limit integer DEFAULT 100, p_only_platform_user_id text DEFAULT NULL::text)
 RETURNS TABLE(pattern_id uuid, parent_id uuid, platform_user_id text, child_name text, pattern_label text, description text, local_hour smallint)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
  select
    cp.id, f.id, f.platform_user_id,
    coalesce(nullif(btrim(c.name),''), 'طفلكم'),
    cp.pattern_label, cp.description,
    extract(hour from (now() at time zone ct.iana_tz))::smallint
  from public.child_patterns cp
  join public.followers f on f.id = cp.follower_id
  join public.children  c on c.id = cp.child_id
  join public.country_timezone ct on upper(btrim(f.country)) = ct.code
  where cp.safe_for_record = true
    and cp.revealed_at is null
    and f.platform_user_id not in ('7377091520','8074049810')
    and (p_only_platform_user_id is null or f.platform_user_id = p_only_platform_user_id)
    and extract(hour from (now() at time zone ct.iana_tz))::smallint between 10 and 21
  order by cp.last_observed desc
  limit p_limit;
$function$;

CREATE OR REPLACE FUNCTION public.get_winback_due(p_limit integer DEFAULT 200, p_only_platform_user_id text DEFAULT NULL::text)
 RETURNS TABLE(parent_id uuid, platform_user_id text, child_name text, local_hour smallint)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
  with base as (
    select
      f.id  as parent_id,
      f.platform_user_id,
      extract(hour from (now() at time zone ct.iana_tz))::smallint as local_hour
    from public.followers f
    join public.country_timezone ct on upper(btrim(f.country)) = ct.code
    join public.checkin_state cs on cs.parent_id = f.id
    where cs.cadence <> 'stopped'
      and coalesce(cs.consecutive_ignored, 0) >= 3
      and cs.winback_sent_at is null
      and (p_only_platform_user_id is null or f.platform_user_id = p_only_platform_user_id)
  ),
  awake as (
    select * from base where local_hour >= 10 and local_hour < 21
  )
  select
    a.parent_id, a.platform_user_id,
    (select nullif(btrim(c.name),'') from public.children c
      where c.follower_id = a.parent_id
      order by c.is_primary desc nulls last, c.created_at limit 1) as child_name,
    a.local_hour
  from awake a
  limit p_limit;
$function$;

CREATE OR REPLACE FUNCTION public.handle_pattern_review_tap(p_pattern_id uuid, p_decision boolean, p_approver text DEFAULT 'معز'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_label text;
begin
  select pattern_label into v_label from public.child_patterns where id = p_pattern_id;
  if v_label is null then
    return jsonb_build_object('body', 'ما لقيت هالنمط، يمكن اتراجع مسبقاً.', 'buttons', '[]'::jsonb);
  end if;

  perform public.set_pattern_record_visibility(
    p_pattern_id, p_decision, p_approver,
    case when p_decision then 'وافق عبر تيليغرام على عرض هذا النمط للوالدين.'
         else 'رفض عبر تيليغرام عرض هذا النمط للوالدين.' end);

  return jsonb_build_object(
    'body', case when p_decision
      then '✅ تمّ. صار النمط "' || v_label || '" يظهر للوالدين.'
      else '🚫 تمام. النمط "' || v_label || '" يبقى مخفياً.' end,
    'buttons', '[]'::jsonb);
end;
$function$;


-- ------------------------------------------------------------
-- 3. The 29-day stage: its clock, its renewal, and the daily
--    step the parent commits to.
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.check_stage_clock(p_parent_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v record;
  v_message text;
begin
  select * into v from public.v_stage_progress
  where parent_id = p_parent_id and status in ('active','extended')
  limit 1;

  if not found then
    return jsonb_build_object('action', 'none', 'reason', 'no_live_stage');
  end if;

  if not v.clock_exhausted or v.objective_met then
    return jsonb_build_object('action', 'none');
  end if;

  if v.status = 'active' then
    update public.stages
       set status = 'extended', extension_days = 15, extension_granted_at = now()
     where id = v.stage_id;
    -- ⭐ compose the full extension message here, so the n8n side only ever
    -- needs to check .message and send it -- one unified path for both
    -- extend and close, no second HTTP call needed.
    v_message := public.compose_stage_welcome(p_parent_id, true);
    return jsonb_build_object('action', 'extended', 'stage_id', v.stage_id, 'message', v_message);
  end if;

  v_message := public.close_stage_report(p_parent_id);

  update public.stages
     set status = 'failed', completed_at = now()
   where id = v.stage_id;

  update public.followers
     set funnel_stage = 'free_conversation',
         subscription_started_at = null
   where id = p_parent_id;

  return jsonb_build_object('action', 'closed', 'stage_id', v.stage_id, 'message', v_message);
end;
$function$;

CREATE OR REPLACE FUNCTION public.commit_chat_step(p_parent_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_country text; v_today date; v_step text; v_is_paid boolean;
  v_objective text;
begin
  select upper(btrim(country)), funnel_stage = 'paid_active'
    into v_country, v_is_paid
  from public.followers where id = p_parent_id;

  select coalesce((now() at time zone ct.iana_tz)::date, current_date) into v_today
  from public.country_timezone ct where ct.code = v_country;
  v_today := coalesce(v_today, current_date);

  select step_given into v_step from public.daily_logs
  where follower_id = p_parent_id and log_date = v_today;

  if v_step is null then
    return jsonb_build_object('committed', false, 'reason', 'no_step_today');
  end if;

  update public.daily_logs
     set step_committed_at = coalesce(step_committed_at, now()),
         updated_at = now()
   where follower_id = p_parent_id and log_date = v_today;

  -- ⭐ الفرق القيمي بين المجاني والمدفوع: المشترك يشوف التزامه مربوطاً
  -- بهدفه الفعلي بالرحلة، لا تأكيداً عاماً.
  if v_is_paid then
    select objective_text into v_objective
    from public.stages
    where parent_id = p_parent_id and status in ('active','extended')
    order by started_at desc limit 1;
  end if;

  return jsonb_build_object(
    'committed', true, 'step', v_step,
    'is_paid', coalesce(v_is_paid, false),
    'objective_text', v_objective);
end;
$function$;

CREATE OR REPLACE FUNCTION public.journey_outcome_options(p_problem_key text)
 RETURNS jsonb
 LANGUAGE sql
 IMMUTABLE
AS $function$
  -- ⭐ Rewritten gender-neutral (nominal/masdar phrasing, no conjugated verb
  -- tied to the child) -- same discipline as the confirm-screen fix and the
  -- main prompt's gender-neutrality rule.
  select case p_problem_key
    when 'anger'    then '["هدوء أسرع من المعتاد","نوبات أقل تكراراً","تعبير بالكلام بدل الصراخ"]'::jsonb
    when 'out'      then '["خروج بلا معركة يومية","استعداد أسرع للخروج","تعاون بلا تذكير متكرر"]'::jsonb
    when 'screen'   then '["قبول إغلاق الجهاز بهدوء","وقت شاشة أقصر يومياً","توازن بين الشاشة وأنشطة أخرى"]'::jsonb
    when 'stubborn' then '["استجابة من أول مرة","نقاش أقل عند كل طلب","تقبّل الرفض بهدوء"]'::jsonb
    when 'study'    then '["بدء الواجب بلا مماطلة","تركيز لفترة أطول","إنهاء الواجب بلا صراخ"]'::jsonb
    when 'sleep'    then '["نوم بلا بكاء ولا صراخ","نوم مبكر بلا ساعات تعب","هدوء سريع عند الاستيقاظ ليلاً"]'::jsonb
    when 'meal'     then '["تجربة أطعمة جديدة","أكل بلا معركة على الطاولة","إنهاء الوجبة بوقت معقول"]'::jsonb
    when 'sibling'  then '["تقبّل مشاركة وقت الأهل مع الإخوة","مقارنات أقل بين الإخوة","علاقة أهدأ بين الإخوة"]'::jsonb
    else '[]'::jsonb
  end;
$function$;

CREATE OR REPLACE FUNCTION public.record_chat_step(p_parent_id uuid, p_step_text text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_country text; v_today date; v_child_id uuid; v_existing_id uuid;
begin
  select upper(btrim(country)) into v_country from public.followers where id = p_parent_id;
  select coalesce((now() at time zone ct.iana_tz)::date, current_date) into v_today
  from public.country_timezone ct where ct.code = v_country;
  v_today := coalesce(v_today, current_date);

  select id into v_child_id from public.children
  where follower_id = p_parent_id order by is_primary desc nulls last, created_at limit 1;

  select id into v_existing_id from public.daily_logs
  where follower_id = p_parent_id and log_date = v_today;

  if v_existing_id is not null then
    -- Chat step arrived first today: fill it in, but never overwrite a
    -- step that already exists (first voice wins, whoever it was).
    update public.daily_logs
       set step_given = coalesce(nullif(btrim(step_given),''), p_step_text),
           seed_text  = coalesce(nullif(btrim(seed_text),''), p_step_text),
           seed_sent_at = coalesce(seed_sent_at, now()),
           source = case when nullif(btrim(step_given),'') is null then 'chat' else source end,
           updated_at = now()
     where id = v_existing_id;
  else
    insert into public.daily_logs
      (id, follower_id, child_id, log_date, step_given, seed_text, seed_sent_at, source, created_at, updated_at)
    values
      (gen_random_uuid(), p_parent_id, v_child_id, v_today, p_step_text, p_step_text, now(), 'chat', now(), now());
  end if;

  return jsonb_build_object('recorded', true, 'log_date', v_today);
end;
$function$;

CREATE OR REPLACE FUNCTION public.record_seed_intent(p_platform_user_id text, p_intent text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_follower_id uuid;
  v_day_id uuid;
begin
  if p_intent not in ('will_try','not_tonight') then
    return jsonb_build_object('recorded', false, 'reason', 'unknown_intent');
  end if;

  select id into v_follower_id from public.followers where platform_user_id = p_platform_user_id;
  if v_follower_id is null then
    return jsonb_build_object('recorded', false, 'reason', 'no_follower');
  end if;

  -- Most recent seed still awaiting an intent tap. Not a strict "today" match:
  -- a late tap on an older seed should still land somewhere sane rather than
  -- silently fail.
  select id into v_day_id
    from public.daily_logs
   where follower_id = v_follower_id
     and seed_sent_at is not null
     and seed_intent is null
   order by log_date desc
   limit 1;

  if v_day_id is null then
    return jsonb_build_object('recorded', false, 'reason', 'no_open_seed');
  end if;

  update public.daily_logs
     set seed_intent = p_intent, seed_intent_at = now(), updated_at = now()
   where id = v_day_id;

  return jsonb_build_object('recorded', true, 'day_id', v_day_id, 'intent', p_intent);
end;
$function$;

CREATE OR REPLACE FUNCTION public.renew_stage_same_objective(p_follower_id uuid, p_amount numeric DEFAULT NULL::numeric, p_currency text DEFAULT NULL::text, p_notes text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_prev record;
  v_result jsonb;
begin
  select * into v_prev from public.stages
  where parent_id = p_follower_id
  order by started_at desc limit 1;

  if not found then
    return jsonb_build_object('renewed', false, 'reason', 'no_previous_stage');
  end if;

  -- Reuse activate_subscription's payment + funnel_stage + start_stage
  -- machinery, just feeding it the OLD stage's objective explicitly instead
  -- of letting it fall back to agreed_objective (which may be empty or
  -- stale here).
  v_result := public.activate_subscription(
    p_follower_id, p_amount, p_currency, coalesce(p_notes, 'تجديد بنفس الهدف'),
    v_prev.problem_key, v_prev.objective_text,
    v_prev.objective_target, v_prev.objective_window, 29,
    v_prev.objective_metric);

  if coalesce(((v_result->'journey')->>'started')::boolean, false) then
    update public.stages
    set problem_context_text = v_prev.problem_context_text,
        frequency_label      = v_prev.frequency_label
    where id = ((v_result->'journey')->>'stage_id')::uuid;
  end if;

  return jsonb_build_object('renewed', true) || v_result;
end;
$function$;


-- ------------------------------------------------------------
-- 4. What is promised at the start of the 29 days, and what is
--    promised again if the days run out before the objective
--    does. The extension is half the duration, once, free —
--    stated in the same words everywhere so no screen
--    contradicts another.
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.agree_objective_from_form(p_parent_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_state jsonb;
  v_problem_key text;
  v_problem_context text;
  v_frequency_label text;
  v_objective_text text;
  v_metric text;
begin
  select journey_form_state into v_state from public.followers where id = p_parent_id;
  if v_state is null or v_state->>'outcome_text' is null then
    return jsonb_build_object('agreed', false, 'reason', 'form_incomplete');
  end if;

  v_problem_key := coalesce(v_state->>'problem_key', 'other');
  v_objective_text := v_state->>'outcome_text';
  v_metric := case when v_problem_key = 'sleep' then 'calm_nights_in_window' else 'steps_done_in_window' end;

  -- ⭐ Problem context: the catalog label if a button was tapped, or the
  -- parent's own literal words if they used "أمر آخر". Either way, this is
  -- what Adam should be able to say back during the journey ("زي ما حكيتوا
  -- لي عن...").
  v_problem_context := coalesce(
    (select jpc.label_ar from public.journey_problem_catalog jpc where jpc.key = v_problem_key),
    v_state->>'problem_text');

  v_frequency_label := case v_state->>'frequency_key'
    when 'daily'      then 'كل يوم تقريباً'
    when 'weekly'     then 'عدة مرات في الأسبوع'
    when 'occasional' then 'بين فترة وأخرى'
    else null end;

  update public.followers
  set agreed_objective = jsonb_build_object(
        'problem_key',          v_problem_key,
        'problem_context_text', v_problem_context,
        'frequency_label',      v_frequency_label,
        'objective_text',       v_objective_text,
        'objective_metric',     v_metric,
        'objective_target',     5,
        'objective_window',     7,
        'planned_logged_days',  29),
      agreed_at = now(),
      journey_form_state = null
  where id = p_parent_id;

  return jsonb_build_object('agreed', true, 'problem_key', v_problem_key,
    'problem_context_text', v_problem_context, 'frequency_label', v_frequency_label,
    'objective_text', v_objective_text);
end;
$function$;



-- ------------------------------------------------------------
-- 5. The two composed screens: the four-step form that agrees an
--    objective, and the pattern reveal that escalates as the
--    patterns accumulate.
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.compose_journey_form_screen(p_parent_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_state    jsonb;
  v_step     text;
  v_who      text;
  v_nl       text := chr(10);
  v_problem_label text;
  v_freq_label    text;
  v_outcome_opts  jsonb;
  v_buttons  jsonb;
  v_body     text;
  v_row      record;
begin
  select coalesce(nullif(btrim(c.name),''), 'طفلكم') into v_who
  from public.children c where c.follower_id = p_parent_id
  order by c.is_primary desc nulls last, c.created_at limit 1;
  v_who := coalesce(v_who, 'طفلكم');

  select journey_form_state into v_state from public.followers where id = p_parent_id;
  v_state := coalesce(v_state, jsonb_build_object('step','problem'));
  v_step := coalesce(v_state->>'step', 'problem');

  if v_step = 'problem' then
    v_body := 'خطوة 1 من 4' || v_nl ||
              '🎯 لنبنِ خطة تخصّ ' || v_who || ' وحده — لا خطة عامة.' || v_nl ||
              'ما الأمر الذي يتعبكم أكثر هذه الأيام؟';
    v_buttons := '[]'::jsonb;
    for v_row in select key, emoji, label_ar from public.journey_problem_catalog order by sort_order loop
      v_buttons := v_buttons || jsonb_build_array(jsonb_build_object(
        'label', v_row.emoji || ' ' || v_row.label_ar, 'cb', 'jf_problem_' || v_row.key));
    end loop;
    v_buttons := v_buttons || jsonb_build_array(jsonb_build_object('label','💬 أمر آخر','cb','jf_other_problem'));

  elsif v_step = 'frequency' then
    v_problem_label := coalesce(
      (select jpc.label_ar from public.journey_problem_catalog jpc
        where jpc.key = v_state->>'problem_key'),
      v_state->>'problem_text', 'هذا الأمر');
    v_body := 'خطوة 2 من 4' || v_nl ||
              'وكم مرة يتكرر «' || v_problem_label || '» معكم؟';
    v_buttons := '[
      {"label":"📅 كل يوم تقريباً","cb":"jf_freq_daily"},
      {"label":"🗓️ عدة مرات في الأسبوع","cb":"jf_freq_weekly"},
      {"label":"〰️ بين فترة وأخرى، لكنه يوجع حين يحدث","cb":"jf_freq_occasional"}
    ]'::jsonb;

  elsif v_step = 'outcome' then
    if v_state->>'problem_key' is not null then
      v_outcome_opts := public.journey_outcome_options(v_state->>'problem_key');
      v_body := 'خطوة 3 من 4' || v_nl ||
                'ولو تغيّر أمر واحد فقط خلال 29 يوماً، ماذا تحبّون أن يحدث؟';
      v_buttons := '[]'::jsonb;
      for v_row in select value as opt, ordinality as i from jsonb_array_elements_text(v_outcome_opts) with ordinality loop
        v_buttons := v_buttons || jsonb_build_array(jsonb_build_object('label', v_row.opt, 'cb', 'jf_outcome_' || v_row.i));
      end loop;
      v_buttons := v_buttons || jsonb_build_array(jsonb_build_object('label','💬 أمر آخر','cb','jf_other_outcome'));
    else
      return jsonb_build_object(
        'body', 'خطوة 3 من 4' || v_nl || 'بكلماتكم: ماذا تحبّون أن يتغيّر؟',
        'buttons', '[]'::jsonb, 'await_field', 'outcome_text');
    end if;

  elsif v_step = 'confirm' then
    v_problem_label := coalesce(
      (select jpc.emoji || ' ' || jpc.label_ar from public.journey_problem_catalog jpc
        where jpc.key = v_state->>'problem_key'),
      v_state->>'problem_text');
    v_freq_label := case v_state->>'frequency_key'
      when 'daily'      then 'كل يوم تقريباً'
      when 'weekly'     then 'عدة مرات في الأسبوع'
      when 'occasional' then 'بين فترة وأخرى'
      else 'بشكل متكرر' end;

    v_body :=
      'خطوة 4 من 4 — آخر خطوة' || v_nl || v_nl ||
      '📋 خطتكم جاهزة:' || v_nl ||
      '• الأمر الذي يتعبكم مع ' || v_who || ': ' || coalesce(v_problem_label, 'ما ذكرتموه') || '، ' || v_freq_label || v_nl ||
      '• الهدف خلال 29 يوماً: ' || coalesce(v_state->>'outcome_text', 'ما اخترتموه') || v_nl || v_nl ||
      '🎁 ومعها تُفتح ✨ بصائر آدم — صفحة تتابعون فيها بالأرقام كل أسبوع: هل تحسّن الوضع فعلاً؟' || v_nl || v_nl ||
      '🛡️ وباتفاق واضح: إن لم نصل لهذا الهدف بالذات خلال المدة، أُكمل معكم نصف المدة إضافية مجاناً حتى نصل.' || v_nl || v_nl ||
      'هل هذا صحيح؟';
    v_buttons := '[
      {"label":"✅ نعم، هذا بالضبط","cb":"jf_confirm_yes"},
      {"label":"🔄 نبدأ من جديد","cb":"jf_confirm_restart"}
    ]'::jsonb;
  else
    v_body := null; v_buttons := '[]'::jsonb;
  end if;

  return jsonb_build_object('body', v_body, 'buttons', v_buttons);
end;
$function$;

CREATE OR REPLACE FUNCTION public.compose_pattern_reveal(p_pattern_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_nl text := chr(10);
  v_child text; v_label text; v_follower uuid; v_body text;
  v_seq int; v_prev1 text; v_prev2 text;
  v_buttons jsonb;
begin
  select coalesce(nullif(btrim(c.name),''), 'طفلكم'), cp.pattern_label, cp.follower_id
    into v_child, v_label, v_follower
  from public.child_patterns cp
  join public.children c on c.id = cp.child_id
  where cp.id = p_pattern_id;

  if v_label is null then
    return jsonb_build_object('body', null, 'buttons', '[]'::jsonb);
  end if;

  select count(*) into v_seq
  from public.child_patterns cp2
  where cp2.follower_id = v_follower and cp2.revealed_at is not null;
  v_seq := v_seq + 1;

  select pattern_label into v_prev1
  from public.child_patterns
  where follower_id = v_follower and revealed_at is not null
  order by revealed_at desc limit 1;

  select pattern_label into v_prev2
  from public.child_patterns
  where follower_id = v_follower and revealed_at is not null
  order by revealed_at desc offset 1 limit 1;

  if v_seq = 1 then
    v_body :=
      '🔍 لاحظت شي بـ' || v_child || ':' || v_nl || v_nl ||
      v_label || '.' || v_nl ||
      'هذا مو انطباع — لاحظته يتكرر فعلاً بكلامكم معي.' || v_nl || v_nl ||
      'وهذا نمط واحد بس من كذا لاحظتهم. باقي الصورة الكاملة، وكيف نكسر هالنمط بالذات، يظهر مع المرافقة الكاملة.';
    v_buttons := jsonb_build_array(
      jsonb_build_object('label','🎯 أشوف المرافقة الكاملة','cb','menu_journey'),
      jsonb_build_object('label','💬 عندي سؤال أولاً','cb','other'));

  elsif v_seq = 2 then
    v_body :=
      '🔍 وفيه شي ثاني لاحظته بـ' || v_child || ':' || v_nl || v_nl ||
      v_label || '.' || v_nl || v_nl ||
      'مو صدفة — نفس القدر اللي لاحظت فيه «' || coalesce(v_prev1,'الأول') || '»، هذا كمان يتكرر.' || v_nl || v_nl ||
      'كل ملاحظة جديدة تقرّبنا من فهم الصورة كاملة.';
    v_buttons := jsonb_build_array(
      jsonb_build_object('label','🎯 أشوف المرافقة الكاملة','cb','menu_journey'),
      jsonb_build_object('label','💬 عندي سؤال أولاً','cb','other'));

  elsif v_seq = 3 then
    v_body :=
      '🔍 وصلت الصورة تترابط عند ' || v_child || '.' || v_nl || v_nl ||
      '«' || coalesce(v_prev2,'') || '» ← «' || coalesce(v_prev1,'') || '» ← «' || v_label || '»' || v_nl || v_nl ||
      'هذي مو ٣ أشياء منفصلة — سلسلة وحدة. وهذا كله من كلامكم أنتم فقط، خلال أيام قليلة.' || v_nl || v_nl ||
      'تخيّلوا لو بنينا خطة كاملة حول هالسلسلة بالذات، لا كل جزء لحاله.';
    v_buttons := jsonb_build_array(
      jsonb_build_object('label','🎯 نبني خطة حول هالسلسلة','cb','menu_journey'),
      jsonb_build_object('label','💬 عندي سؤال أولاً','cb','other'));

  else
    v_body :=
      '🔍 هذا رابع شي نكتشفه سوا عن ' || v_child || ':' || v_nl || v_nl ||
      v_label || '.' || v_nl || v_nl ||
      'كل هذا بنيناه من حكيكم اليومي وحده، بلا أي استمارة ولا سؤال مباشر.' || v_nl || v_nl ||
      'تخيّلوا لو صار عندنا خطة واحدة تجمع كل هالأنماط مع بعض — هذا بالضبط اللي تسويه المرافقة الكاملة.';
    v_buttons := jsonb_build_array(
      jsonb_build_object('label','🚀 نبني الخطة الآن','cb','jf_start'),
      jsonb_build_object('label','💬 عندي سؤال أولاً','cb','other'));
  end if;

  return jsonb_build_object('body', v_body, 'buttons', v_buttons, 'seq', v_seq);
end;
$function$;


-- ------------------------------------------------------------
-- 6. The closing report. It is required to say, in plain words,
--    that the objective was not reached — «لا نزيّنه». A report
--    that only ever congratulates is not a report.
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.close_stage_report(p_parent_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_nl text := chr(10);
  v_child text; v_objective text; v_context text; v_freq text;
  v_child_id uuid; v_started date; v_days int;
  v_nights int; v_calm int; v_hard int;
  v_calm_w1 int; v_calm_last int;
  v_calms text;
  v_sits text[]; v_pats text[];
  v_lines text[] := '{}';
begin
  select s.child_id, s.objective_text, s.problem_context_text, s.frequency_label, s.started_at::date
    into v_child_id, v_objective, v_context, v_freq, v_started
  from public.stages s
  where s.parent_id = p_parent_id and s.status in ('active','extended')
  order by s.started_at desc limit 1;

  select nullif(btrim(c.name),'') into v_child
  from public.children c where c.id = v_child_id;
  v_child := coalesce(v_child, 'طفلكم');
  v_days := greatest(1, (current_date - coalesce(v_started, current_date)));

  select count(*) filter (where d.night_result is not null),
         count(*) filter (where d.night_result = 'calm'),
         count(*) filter (where d.night_result = 'hard')
    into v_nights, v_calm, v_hard
  from public.daily_logs d where d.follower_id = p_parent_id;

  select count(*) filter (where d.night_result = 'calm') into v_calm_w1
  from public.daily_logs d
  where d.follower_id = p_parent_id and d.log_date >= coalesce(v_started, current_date)
    and d.log_date < coalesce(v_started, current_date) + 7;

  select count(*) filter (where d.night_result = 'calm') into v_calm_last
  from public.daily_logs d
  where d.follower_id = p_parent_id and d.log_date > current_date - 7 and d.log_date <= current_date;

  select array_agg(distinct public.situation_label_ar(s.key))
    into v_sits
  from public.situations s
  where s.child_id = v_child_id and s.status = 'confirmed';

  select array_agg(cp.pattern_label order by cp.evidence_count desc)
    into v_pats
  from public.child_patterns cp
  where cp.child_id = v_child_id and cp.safe_for_record;

  select string_agg(line, v_nl) into v_calms from (
    select '• ' || coalesce(d.step_given, d.seed_text) || ' — نجحت '
           || public.ar_digits((count(*) filter (where d.step_status = 'done'))::text)
           || ' من ' || public.ar_digits(count(*)::text)
      as line
    from public.daily_logs d
    where d.follower_id = p_parent_id
      and coalesce(d.step_given, d.seed_text) is not null
    group by coalesce(d.step_given, d.seed_text)
    order by count(*) filter (where d.step_status = 'done') desc, count(*) desc
    limit 5
  ) t;

  v_lines := array['📖 تقرير رحلتكم الكاملة مع ' || v_child];
  v_lines := v_lines || ''::text;
  v_lines := v_lines || ('من ' || to_char(coalesce(v_started, current_date), 'DD/MM') || ' إلى اليوم — '
                          || public.ar_digits(v_days::text) || ' يوماً معاً.')::text;
  v_lines := v_lines || ''::text;
  v_lines := v_lines || ('الهدف الذي بنينا عليه هذه الرحلة: ' || coalesce(v_objective,'') || '.')::text;
  if v_context is not null then
    v_lines := v_lines || ('بدأنا من: ' || v_context || coalesce('، '||v_freq, '') || '.')::text;
  end if;

  v_lines := v_lines || ''::text;
  v_lines := v_lines || '📊 بالأرقام'::text;
  v_lines := v_lines || ('• ' || public.ar_digits(coalesce(v_nights,0)::text) || ' ليلة سجّلتموها معنا، '
                          || public.ar_digits(coalesce(v_calm,0)::text) || ' منها مرّت بهدوء فعلاً.')::text;
  if v_calm_w1 is not null and v_calm_last is not null then
    if v_calm_last > v_calm_w1 then
      v_lines := v_lines || ('• الأسبوع الأخير كان أهدأ من أول أسبوع معنا — تحسّن حقيقي وواضح بالأرقام.')::text;
    elsif v_calm_last = v_calm_w1 then
      v_lines := v_lines || ('• الهدوء ثابت من أول أسبوع لآخر أسبوع — لم يتراجع رغم كل التعب.')::text;
    else
      v_lines := v_lines || ('• كانت هناك أسابيع أصعب من غيرها — وهذا طبيعي، النمو لا يمشي بخط مستقيم.')::text;
    end if;
  end if;

  if v_calms is not null then
    v_lines := v_lines || ''::text;
    v_lines := v_lines || '✅ ما نجح معكم فعلاً'::text;
    v_lines := v_lines || v_calms;
  end if;

  if v_pats is not null and array_length(v_pats,1) > 0 then
    v_lines := v_lines || ''::text;
    v_lines := v_lines || '🧩 أنماط لاحظناها معاً'::text;
    v_lines := v_lines || ('• ' || array_to_string(v_pats[1:3], E'\n• '))::text;
  end if;

  if v_sits is not null and array_length(v_sits,1) > 0 then
    v_lines := v_lines || ''::text;
    v_lines := v_lines || ('🔍 اللحظات اللي عرفنا مصدرها بالضبط: ' || array_to_string(v_sits, '، ') || '.')::text;
  end if;

  v_lines := v_lines || ''::text;
  v_lines := v_lines || ('لم نصل بعد بشكل كامل إلى «' || coalesce(v_objective,'') || '» — وهذا ما نقوله لكم بصراحة، لا نزيّنه.')::text;

  v_lines := v_lines || ''::text;
  v_lines := v_lines || '🌿 آدم كان معكم كل يوم — يقترح خطوة مبنية على ما نجح أمس، لا نصيحة عامة، ويتابع كل ليلة بلا كلل.'::text;
  v_lines := v_lines || ('لكن كل ما تحقق فعلياً هو اجتهادكم أنتم — أنتم من طبّق، أنتم من واظب، وأنتم من لم يستسلموا رغم الأيام الصعبة.')::text;

  v_lines := v_lines || ''::text;
  v_lines := v_lines || 'المرافقة الكاملة تنتهي اليوم.'::text;
  v_lines := v_lines || 'وما بنيتموه حتى الآن لا يستحق أن يتوقف هنا.'::text;

  return array_to_string(v_lines, v_nl);
end;
$function$;


-- ------------------------------------------------------------
-- 7. The weekly reflection. Two deliberately conservative rules:
--    a trigger must dominate at least half the hard nights, and
--    a step must have been tried at least twice and worked 70%
--    of the time. Anything looser produces a horoscope.
--
--    The standing approval recorded here is a real decision by a
--    named human, written into pattern_record_approvals so the
--    audit trail says who allowed a pattern to be spoken and why.
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.run_weekly_pattern_reflection(p_limit integer DEFAULT 200, p_only_platform_user_id text DEFAULT NULL::text)
 RETURNS TABLE(follower_id uuid, child_id uuid, patterns_upserted integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_follower record;
  v_child_id uuid;
  v_count    integer;
  v_trigger  record;
  v_step     record;
  v_upserted integer;
  v_new_id   uuid;
  v_standing_reason text := 'موافقة قياسية دائمة على أنماط القاعدتين المحافظتين (تكرار محفّز ≥3 مرات و≥50% من الليالي الصعبة، أو خطوة مثبتة ≥2 محاولة و≥70% نجاح) — قرار معز بتاريخ 20 أغسطس 2026 بعد اختبار متكرر للنظام.';
begin
  for v_follower in
    select f.id
    from public.followers f
    where f.platform_user_id not in ('7377091520','8074049810')
      and (p_only_platform_user_id is null or f.platform_user_id = p_only_platform_user_id)
      and exists (
        select 1 from public.daily_logs d
        where d.follower_id = f.id
          and d.night_result is not null
          and d.log_date > coalesce(f.last_pattern_reflection_at::date, '-infinity'::date)
      )
    limit p_limit
  loop
    v_upserted := 0;

    select c.id into v_child_id
    from public.children c where c.follower_id = v_follower.id
    order by c.is_primary desc nulls last, c.created_at limit 1;

    if v_child_id is not null then

      -- RULE A: dominant recurring trigger among hard nights, last 14 days.
      for v_trigger in
        select d.hard_moment, count(*) as n,
               (select count(*) from public.daily_logs d2
                 where d2.follower_id = v_follower.id
                   and d2.night_result = 'hard'
                   and d2.log_date > current_date - 14) as total_hard
        from public.daily_logs d
        where d.follower_id = v_follower.id
          and d.night_result = 'hard'
          and d.hard_moment is not null
          and d.log_date > current_date - 14
        group by d.hard_moment
        having count(*) >= 3
      loop
        if v_trigger.total_hard > 0 and v_trigger.n::numeric / v_trigger.total_hard::numeric >= 0.5 then
          declare
            v_label text := 'يتكرر الاحتكاك ' || public.hard_moment_label(v_trigger.hard_moment);
          begin
            select id into v_new_id from public.child_patterns
             where child_id = v_child_id and pattern_label = v_label;

            if v_new_id is not null then
              update public.child_patterns
                 set evidence_count = v_trigger.n, last_observed = now(),
                     updated_at = now(), status = 'active'
               where id = v_new_id;
              if not (select safe_for_record from public.child_patterns where id = v_new_id) then
                insert into public.pattern_record_approvals
                  (pattern_id, child_id, parent_id, pattern_label_at_approval, decision, approved_by, reason)
                values (v_new_id, v_child_id, v_follower.id, v_label, true, 'معز', v_standing_reason);
                update public.child_patterns set safe_for_record = true where id = v_new_id;
              end if;
            else
              insert into public.child_patterns
                (id, follower_id, child_id, pattern_label, description, status,
                 evidence_count, first_observed, last_observed, updated_at, safe_for_record)
              values
                (gen_random_uuid(), v_follower.id, v_child_id, v_label,
                 'نمط مستخرج تلقائياً: ' || v_trigger.n || ' من ' || v_trigger.total_hard || ' ليالٍ صعبة آخر 14 يوماً كان سببها هذا الموقف.',
                 'active', v_trigger.n, now(), now(), now(), false)
              returning id into v_new_id;
              insert into public.pattern_record_approvals
                (pattern_id, child_id, parent_id, pattern_label_at_approval, decision, approved_by, reason)
              values (v_new_id, v_child_id, v_follower.id, v_label, true, 'معز', v_standing_reason);
              update public.child_patterns set safe_for_record = true where id = v_new_id;
            end if;
            v_upserted := v_upserted + 1;
          end;
        end if;
      end loop;

      -- RULE B: a step with a proven track record (>=2 tries, >=70% success).
      for v_step in
        select coalesce(d.step_given, d.seed_text) as step_text,
               count(*) as n,
               count(*) filter (where d.step_status = 'done') as wins
        from public.daily_logs d
        where d.follower_id = v_follower.id
          and coalesce(d.step_given, d.seed_text) is not null
          and d.log_date > current_date - 30
        group by coalesce(d.step_given, d.seed_text)
        having count(*) >= 2
      loop
        if v_step.wins::numeric / v_step.n::numeric >= 0.7 then
          declare
            v_label text := '"' || left(v_step.step_text, 60) || '" ينجح غالباً';
          begin
            select id into v_new_id from public.child_patterns
             where child_id = v_child_id and pattern_label = v_label;

            if v_new_id is not null then
              update public.child_patterns
                 set evidence_count = v_step.wins, last_observed = now(),
                     updated_at = now(), status = 'active'
               where id = v_new_id;
              if not (select safe_for_record from public.child_patterns where id = v_new_id) then
                insert into public.pattern_record_approvals
                  (pattern_id, child_id, parent_id, pattern_label_at_approval, decision, approved_by, reason)
                values (v_new_id, v_child_id, v_follower.id, v_label, true, 'معز', v_standing_reason);
                update public.child_patterns set safe_for_record = true where id = v_new_id;
              end if;
            else
              insert into public.child_patterns
                (id, follower_id, child_id, pattern_label, description, status,
                 evidence_count, first_observed, last_observed, updated_at, safe_for_record)
              values
                (gen_random_uuid(), v_follower.id, v_child_id, v_label,
                 'نمط مستخرج تلقائياً: نجحت ' || v_step.wins || ' من ' || v_step.n || ' مرات آخر 30 يوماً.',
                 'active', v_step.wins, now(), now(), now(), false)
              returning id into v_new_id;
              insert into public.pattern_record_approvals
                (pattern_id, child_id, parent_id, pattern_label_at_approval, decision, approved_by, reason)
              values (v_new_id, v_child_id, v_follower.id, v_label, true, 'معز', v_standing_reason);
              update public.child_patterns set safe_for_record = true where id = v_new_id;
            end if;
            v_upserted := v_upserted + 1;
          end;
        end if;
      end loop;

    end if;

    update public.followers set last_pattern_reflection_at = now() where id = v_follower.id;

    follower_id := v_follower.id;
    child_id := v_child_id;
    patterns_upserted := v_upserted;
    return next;
  end loop;
end;
$function$;

commit;
