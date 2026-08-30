begin;

-- ============================================================
-- THE SEVEN SIGNATURES COME HOME
--
-- The worst class of drift found, because it hides from every
-- other check: seven functions exist in the repository under a
-- DIFFERENT PARAMETER LIST from the one running in production.
-- `create or replace` cannot replace a function whose signature
-- changed — it creates a second one — so the repo kept building
-- the old shape while production had long since moved on.
--
--   repo built                          production runs
--   ----------------------------------  ----------------------------------
--   get_rhythm_due(integer)             get_rhythm_due(integer, text)
--   get_heart_batch(integer)            get_heart_batch(integer, text, text)
--   get_situation_batch(integer)        get_situation_batch(integer, text, text)
--   get_strain_batch(integer)           get_strain_batch(integer, text, text)
--   get_conversation_moment(text,uuid)  get_conversation_moment(text, uuid, boolean)
--   start_stage(…8 args)                start_stage(…10 args)
--   activate_subscription(…10 args,     activate_subscription(…10 args,
--     different order)                    production's order)
--
-- The consequences are not theoretical. Every n8n schedule calls
-- the three-argument batch readers with p_only_platform_user_id
-- and p_only_branch, so a database built from this repository
-- answers `function does not exist`. And activate_subscription's
-- arguments are REORDERED between the two, not merely extended:
-- renew_stage_same_objective passes production's order, so
-- against the repo's shape a renewal would silently bind an
-- amount to a day count.
--
-- The stale signatures are dropped, not left beside the new
-- ones. An overload that nothing calls is a trap for the next
-- person reading the schema.
-- ============================================================

drop function if exists public.get_rhythm_due(integer);
drop function if exists public.get_heart_batch(integer);
drop function if exists public.get_situation_batch(integer);
drop function if exists public.get_strain_batch(integer);
drop function if exists public.get_conversation_moment(text, uuid);
drop function if exists public.start_stage(uuid, text, text, integer, integer, integer, text, uuid);
drop function if exists public.activate_subscription(uuid, integer, numeric, text, text, text, text, integer, integer, integer);


-- p_only_branch lets one on-demand refresh ask for exactly one
-- branch instead of all three — zero model calls for the rest.
CREATE OR REPLACE FUNCTION public.get_heart_batch(p_limit integer DEFAULT 40, p_only_platform_user_id text DEFAULT NULL::text, p_only_branch text DEFAULT NULL::text)
 RETURNS TABLE(platform_user_id text, first_name text, conversation text, light_memory text)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
    f         record;
    m         record;
    v_lines   text[];
    v_text    text;
    v_latest  timestamptz;
    v_count   integer;
    v_content text;
    v_reply   text;
    v_emitted integer := 0;
begin
    -- ⭐ Branch scoping: an on-demand refresh triggered by one button can ask
    -- for exactly one branch (heart/situation/strain) instead of all three.
    -- Skipping here means zero LLM calls for the branches not requested.
    if p_only_branch is not null and p_only_branch <> 'heart' then
        return;
    end if;

    for f in
        select fo.platform_user_id        as pid,
               fo.first_name              as fname,
               fo.light_memory            as lm,
               fo.light_memory_updated_at as lmu
          from followers fo
         where fo.funnel_stage = 'free_conversation'
           and (p_only_platform_user_id is null or fo.platform_user_id = p_only_platform_user_id)
         order by fo.light_memory_updated_at asc nulls first,
                  fo.platform_user_id
    loop
        exit when v_emitted >= greatest(coalesce(p_limit, 40), 1);

        select max(c.created_at), count(*)
          into v_latest, v_count
          from get_conversation_for(f.pid) c;

        if v_count = 0 then
            continue;
        end if;

        if not (f.lm is null
                or v_latest > coalesce(f.lmu, '-infinity'::timestamptz)) then
            continue;
        end if;

        v_lines := array[]::text[];

        for m in
            select s.id, s.message
              from (select c.id, c.message
                      from get_conversation_for(f.pid) c
                     order by c.id desc
                     limit 60) s
             order by s.id asc
        loop
            if m.message->>'type' = 'human' then
                v_lines := v_lines || ('الأم: ' || btrim(coalesce(m.message->>'content', '')));
            elsif m.message->>'type' = 'ai' then
                v_content := coalesce(m.message->>'content', '');
                v_reply   := null;
                begin
                    if btrim(v_content) like '{%' then
                        v_reply := (v_content::jsonb)->>'reply';
                    end if;
                exception when others then
                    v_reply := null;
                end;
                v_lines := v_lines || ('آدم: ' || btrim(coalesce(v_reply, v_content)));
            end if;
        end loop;

        v_text := array_to_string(v_lines, E'\n');
        if length(v_text) > 7000 then
            v_text := right(v_text, 7000);
        end if;

        platform_user_id := f.pid;
        first_name       := coalesce(f.fname, '');
        conversation     := v_text;
        light_memory     := f.lm;
        v_emitted        := v_emitted + 1;
        return next;
    end loop;
end;
$function$;


CREATE OR REPLACE FUNCTION public.get_situation_batch(p_limit integer DEFAULT 20, p_only_platform_user_id text DEFAULT NULL::text, p_only_branch text DEFAULT NULL::text)
 RETURNS TABLE(parent_id uuid, child_id uuid, child_name text, conversation text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
with guard as (select 1 where p_only_branch is null or p_only_branch = 'situation'),
candidates as (
  select f.id as parent_id, c.id as child_id, nullif(btrim(c.name),'') as child_name,
         c.situation_checked_at
  from public.followers f
  join public.children c on c.follower_id = f.id
  where nullif(btrim(c.name),'') is not null
    and (p_only_platform_user_id is null or f.platform_user_id = p_only_platform_user_id)
    and exists (select 1 from guard)
    and not exists (
      select 1 from public.situations s
      where s.child_id = c.id and s.status = 'confirmed')
    -- ⭐ The valve: only if a message arrived after the last time we checked.
    and exists (
      select 1 from public.n8n_chat_histories h
      where h.session_id = f.platform_user_id
        and h.created_at > coalesce(c.situation_checked_at, '-infinity'::timestamptz))
)
select
  k.parent_id, k.child_id, k.child_name,
  (select string_agg(
       case when h.message->>'type' = 'human' then 'الوالد: ' else 'آدم: ' end
       || left(coalesce(h.message->>'content',''), 400),
       chr(10) order by h.id asc)
   from (select hh.id, hh.message from public.n8n_chat_histories hh
         where hh.session_id = (select platform_user_id from public.followers where id = k.parent_id)
         order by hh.id desc
         limit 30) h
  ) as conversation
from candidates k
limit p_limit;
$function$;


CREATE OR REPLACE FUNCTION public.get_strain_batch(p_limit integer DEFAULT 30, p_only_platform_user_id text DEFAULT NULL::text, p_only_branch text DEFAULT NULL::text)
 RETURNS TABLE(parent_id uuid, current_level smallint, conversation text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
select
  f.id,
  coalesce(ps.level, 1)::smallint,
  (select string_agg(
       case when h.message->>'type' = 'human' then 'الوالد: ' else 'آدم: ' end
       || left(coalesce(h.message->>'content',''), 300),
       chr(10) order by h.id asc)
   from (select * from public.n8n_chat_histories hh
         where hh.session_id = f.platform_user_id
         order by hh.id desc limit 12) h)
from public.followers f
left join public.parent_strain ps on ps.parent_id = f.id
where (p_only_branch is null or p_only_branch = 'strain')
  and exists (
  select 1 from public.n8n_chat_histories h2
  where h2.session_id = f.platform_user_id
    and h2.id > coalesce((
      select max(h3.id) - 200 from public.n8n_chat_histories h3), 0))
  -- ⭐ The valve: only if a message arrived after the last time we checked
  -- THIS specific parent (not just "recently active platform-wide").
  and exists (
    select 1 from public.n8n_chat_histories h4
    where h4.session_id = f.platform_user_id
      and h4.created_at > coalesce(f.strain_checked_at, '-infinity'::timestamptz))
  and (p_only_platform_user_id is null or f.platform_user_id = p_only_platform_user_id)
order by coalesce(ps.updated_at, 'epoch'::timestamptz)
limit p_limit;
$function$;


-- The two extra arguments are the parent's own words for the
-- problem and how often it happens, carried onto the stage so
-- ADAM can say them back later.
CREATE OR REPLACE FUNCTION public.start_stage(p_parent_id uuid, p_problem_key text, p_objective_text text, p_objective_target integer DEFAULT 5, p_objective_window integer DEFAULT 7, p_planned_logged_days integer DEFAULT 29, p_objective_metric text DEFAULT 'calm_nights_in_window'::text, p_child_id uuid DEFAULT NULL::uuid, p_problem_context_text text DEFAULT NULL::text, p_frequency_label text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_child uuid; v_id uuid; v_live uuid;
begin
  if p_parent_id is null
     or nullif(btrim(coalesce(p_problem_key, '')), '') is null
     or nullif(btrim(coalesce(p_objective_text, '')), '') is null then
    return jsonb_build_object('started', false, 'reason', 'objective_required');
  end if;

  if not exists (select 1 from public.followers where id = p_parent_id) then
    return jsonb_build_object('started', false, 'reason', 'no_such_parent');
  end if;

  select id into v_live from public.stages
  where parent_id = p_parent_id and status in ('active','extended','paused')
  limit 1;
  if v_live is not null then
    return jsonb_build_object('started', false, 'reason', 'stage_already_live',
                              'stage_id', v_live);
  end if;

  if p_objective_target > p_objective_window then
    return jsonb_build_object('started', false, 'reason', 'target_exceeds_window');
  end if;
  if p_planned_logged_days < 7 or p_planned_logged_days > 60 then
    return jsonb_build_object('started', false, 'reason', 'clock_out_of_range');
  end if;

  v_child := p_child_id;
  if v_child is null then
    select c.id into v_child from public.children c
    where c.follower_id = p_parent_id
    order by c.is_primary desc nulls last, c.created_at limit 1;
  end if;

  insert into public.stages (
    parent_id, child_id, problem_key, objective_text,
    objective_metric, objective_target, objective_window,
    planned_logged_days, status, started_at,
    problem_context_text, frequency_label)
  values (
    p_parent_id, v_child, btrim(p_problem_key), btrim(p_objective_text),
    p_objective_metric, p_objective_target, p_objective_window,
    p_planned_logged_days, 'active', now(),
    p_problem_context_text, p_frequency_label)
  returning id into v_id;

  update public.stage_proposals
  set outcome = 'accepted', stage_id = v_id
  where parent_id = p_parent_id and problem_key = btrim(p_problem_key)
    and outcome = 'pending';

  return jsonb_build_object('started', true, 'stage_id', v_id)
      || public.stage_state(p_parent_id);
end;
$function$;


-- The argument order here is the one every caller in production
-- uses, renew_stage_same_objective included. Read it against the
-- repo's old shape before changing anything: they are not the
-- same list with two appended, they are reordered.
CREATE OR REPLACE FUNCTION public.activate_subscription(p_follower_id uuid, p_amount numeric DEFAULT NULL::numeric, p_currency text DEFAULT NULL::text, p_notes text DEFAULT NULL::text, p_problem_key text DEFAULT NULL::text, p_objective_text text DEFAULT NULL::text, p_objective_target integer DEFAULT 5, p_objective_window integer DEFAULT 7, p_planned_logged_days integer DEFAULT 29, p_objective_metric text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  f public.followers%rowtype;
  v_country text; v_amount numeric; v_currency text;
  v_start timestamptz := now();
  v_pay_id uuid; v_journey jsonb;
  v_problem_context text; v_frequency_label text;
begin
  select * into f from public.followers where id = p_follower_id;
  if not found then
    raise exception 'follower_not_found' using errcode = 'P0002';
  end if;

  if nullif(btrim(coalesce(p_objective_text, '')), '') is null
     and nullif(btrim(coalesce(p_problem_key, '')), '') is null
     and f.agreed_objective is not null then
    p_problem_key         := f.agreed_objective->>'problem_key';
    p_objective_text      := f.agreed_objective->>'objective_text';
    p_objective_target    := coalesce((f.agreed_objective->>'objective_target')::int,    p_objective_target);
    p_objective_window    := coalesce((f.agreed_objective->>'objective_window')::int,    p_objective_window);
    p_planned_logged_days := coalesce((f.agreed_objective->>'planned_logged_days')::int, p_planned_logged_days);
    -- ⭐ FIX: was hardcoded to calm_nights_in_window regardless of what the
    -- form actually determined (sleep vs everything else).
    p_objective_metric    := coalesce(p_objective_metric, f.agreed_objective->>'objective_metric');
    v_problem_context := f.agreed_objective->>'problem_context_text';
    v_frequency_label := f.agreed_objective->>'frequency_label';
  end if;
  p_objective_metric := coalesce(p_objective_metric, 'calm_nights_in_window');

  v_country := nullif(btrim(coalesce(f.country, '')), '');

  select sc.price_subscription, sc.currency into v_amount, v_currency
  from public.supported_countries sc where sc.code = coalesce(v_country, 'DZ') limit 1;
  if v_amount is null then
    select sc.price_subscription, sc.currency into v_amount, v_currency
    from public.supported_countries sc where sc.code = 'DZ' limit 1;
  end if;
  v_amount   := coalesce(p_amount, v_amount, 2300);
  v_currency := coalesce(p_currency, v_currency, 'DZD');

  update public.followers
  set funnel_stage = 'paid_active', payment_status = 'paid',
      subscription_started_at = v_start, subscription_expires_at = null,
      offer_status = 'converted', payment_pending_at = null,
      renewal_d5_sent_at = null, renewal_d0_sent_at = null
  where id = p_follower_id;

  insert into public.payments (follower_id, amount, currency, plan_type, status,
                               claimed_at, confirmed_at, confirmed_by, notes, created_at)
  values (p_follower_id, v_amount, v_currency, 'basic', 'confirmed',
          coalesce(f.payment_pending_at, v_start), now(), 'dashboard', p_notes, now())
  returning id into v_pay_id;

  v_journey := public.start_stage(
    p_follower_id, p_problem_key, p_objective_text,
    p_objective_target, p_objective_window, p_planned_logged_days,
    p_objective_metric, null, v_problem_context, v_frequency_label);

  if coalesce((v_journey->>'started')::boolean, false) then
    update public.followers set agreed_objective = null, agreed_at = null
    where id = p_follower_id;
  end if;

  return jsonb_build_object(
    'follower_id', p_follower_id,
    'payment_id',  v_pay_id,
    'funnel_stage','paid_active',
    'subscription_started_at', v_start,
    'amount', v_amount, 'currency', v_currency,
    'journey', v_journey);
end;
$function$;


-- The single query the whole proactive side runs on. Note the
-- seed hour: the parent's own preference, but never later than
-- three hours before the hard window, so there is real time to
-- try the step before it is needed.
CREATE OR REPLACE FUNCTION public.get_rhythm_due(p_limit integer DEFAULT 200, p_only_platform_user_id text DEFAULT NULL::text)
 RETURNS TABLE(parent_id uuid, platform_user_id text, action text, local_date date, local_hour smallint, child_id uuid, child_name text, situation_id uuid, situation_key text, day_id uuid, seed_text text, grounding jsonb, is_first_proactive boolean, footer_ar text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
with base as (
  select
    f.id            as parent_id,
    f.platform_user_id,
    ct.iana_tz,
    (now() at time zone ct.iana_tz)::date       as local_date,
    extract(hour from (now() at time zone ct.iana_tz))::smallint as local_hour,
    (f.proactive_footer_at is null)             as owes_exit,
    cs.local_hour                               as preferred_hour
  from public.followers f
  join public.country_timezone ct
    on upper(btrim(f.country)) = ct.code
  left join public.checkin_state cs on cs.parent_id = f.id
  where
    ct.iana_tz is not null
    and (cs.paused_until is null or cs.paused_until < (now() at time zone ct.iana_tz)::date)
    and coalesce(cs.cadence, 'nightly') <> 'stopped'
    and (p_only_platform_user_id is null or f.platform_user_id = p_only_platform_user_id)
),
awake as (
  select * from base where local_hour >= 7 and local_hour < 23
),
ctx as (
  select
    a.*,
    ch.id   as child_id,
    nullif(btrim(ch.name),'') as child_name,
    s.id    as situation_id,
    s.key   as situation_key,
    coalesce(s.window_start, 20)::smallint as win_start,
    coalesce(s.window_end,   22)::smallint as win_end,
    d.id    as day_id,
    d.seed_sent_at,
    d.harvest_sent_at,
    d.seed_text
  from awake a
  left join lateral (
    select c.id, c.name from public.children c
    where c.follower_id = a.parent_id
    order by c.is_primary desc nulls last, c.created_at limit 1
  ) ch on true
  left join lateral (
    select s2.id, s2.key, s2.window_start, s2.window_end
    from public.situations s2
    where s2.child_id = ch.id and s2.status in ('candidate','confirmed')
    order by (s2.status='confirmed') desc, s2.evidence_count desc, s2.last_observed desc
    limit 1
  ) s on true
  left join public.daily_logs d
    on d.follower_id = a.parent_id and d.log_date = a.local_date
),
decided as (
  select
    c.*,
    -- ⭐ target hour: parent's preference, or 9am default, always kept at
    -- least 3 hours before the situation window so there's real lead time
    -- to actually try the step before it's needed.
    least(coalesce(c.preferred_hour, 9), c.win_start - 3) as seed_target_hour,
    case
      when c.seed_sent_at is not null
       and c.harvest_sent_at is null
       and c.local_hour > c.win_end
        then 'harvest'
      when c.seed_sent_at is null
       and c.local_hour >= 7
       and c.local_hour < c.win_start
       and c.local_hour >= least(coalesce(c.preferred_hour, 9), c.win_start - 3)
       and c.local_hour <= least(coalesce(c.preferred_hour, 9), c.win_start - 3) + 3
        then 'seed'
      else null
    end as base_action,
    exists (
      select 1 from public.stages st
      where st.parent_id = c.parent_id and st.status in ('active','extended')
    ) as in_journey
  from ctx c
),
routed as (
  select
    d.*,
    case
      when d.base_action = 'seed' and d.in_journey
       and coalesce((public.compose_journey_step(d.parent_id)->>'can_send')::boolean, false)
        then 'journey_step'
      else d.base_action
    end as action
  from decided d
)
select
  r.parent_id, r.platform_user_id, r.action, r.local_date, r.local_hour,
  r.child_id, r.child_name, r.situation_id, r.situation_key,
  r.day_id, r.seed_text,
  case
    when r.action = 'seed'         then public.can_ground_seed(r.parent_id)
    when r.action = 'journey_step' then public.compose_journey_step(r.parent_id)
    else null
  end as grounding,
  r.owes_exit as is_first_proactive,
  case when r.owes_exit
       then (select cm.body_ar from public.conversation_moments cm
              where cm.key = 'proactive_first_footer')
       else null end as footer_ar
from routed r
where r.action is not null
  and (
    r.action = 'harvest'
    or (r.action = 'seed'
        and (public.can_ground_seed(r.parent_id)->>'can_ground')::boolean)
    or (r.action = 'journey_step'
        and (public.compose_journey_step(r.parent_id)->>'can_send')::boolean)
  )
order by r.local_hour desc
limit p_limit;
$function$;


-- p_skip_commerce_gate exists for exactly one caller: the parent
-- who has just finished the form voluntarily and asked for the
-- offer. Refusing them their own answer because the generic
-- commerce gate is shut would be absurd.
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
          '🎉 تمّت الخطة.' || v_nl ||
          'هدفكم مع ' || v_who || ': ' || (v_agreed->>'objective_text') || ' — خلال ' || coalesce(v_agreed->>'planned_logged_days','29') || ' يوماً.' || v_nl || v_nl ||
          'تخيّلوا تلك الليلة: بيتٌ هادئ، بلا معركة — هذا بالضبط ما نبنيه معاً، يوماً بعد يوم، لا دفعة واحدة.' || v_nl || v_nl ||
          '✨ وكيف نصل؟' || v_nl ||
          'كل يوم: خطوة صغيرة تناسب ' || v_who || ' بالذات، لا نصيحة عامة.' || v_nl ||
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
            'label', case when v_name is null then '📞 نُفعّل الخطة مع فريق آدم'
                          else '📞 نُفعّل خطة ' || v_name || ' مع الفريق' end,
            'url',   'https://t.me/Abdouleg'),
          jsonb_build_object('label', '📝 أُعيد الاستمارة من جديد', 'cb', 'jf_start'),
          jsonb_build_object('label', '🔄 أُغيّر الهدف', 'cb', 'menu_change_goal'),
          jsonb_build_object('label', '🌿 ليس الآن — نكمل مجاناً', 'cb', 'menu_not_now'));
      else
        v_body :=
          '🎯 المرافقة الكاملة' || v_nl || v_nl ||
          'لا أعدكم بطفلٍ مثالي خلال 29 يوماً.' || v_nl ||
          'لكن أعدكم أن نعمل معاً حتى يتغيّر بالضبط ما يتعبكم أكثر من غيره — لا نصيحة عامة، بل خطة مبنية على ' || v_who || ' وحده:' || v_nl ||
          '😌 عناد أقلّ، وإصغاء أسهل' || v_nl ||
          '🌙 نوم بلا معركة كل ليلة' || v_nl ||
          '🔥 نوبات غضب أقصر وأقلّ' || v_nl ||
          '📱 وقت أقلّ أمام الشاشة، دون حرب يومية' || v_nl ||
          '🤝 وجسر أقوى بينكم وبين ' || v_who || v_nl || v_nl ||
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
