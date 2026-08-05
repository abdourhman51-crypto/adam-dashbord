-- ============================================================
-- The journey can be started, run, and finished.
--
-- Until now the complete list of journey functions in production
-- was: `can_propose_stage`. A gate, and nothing to gate.
--
-- `stages` held the shape. `v_stage_progress` derived the phase,
-- the clock and whether the objective was met. Neither of them
-- could ever run, because nothing has ever written a row.
--
-- So the offer sold this —
--
--     نتّفق قبل أن نبدأ على هدف واضح ترونه بأعينكم.
--     وإن لم نصل إليه في المدّة، أُكمل معكم نصف المدّة
--     كاملةً مجاناً حتى نصل.
--
-- — and the only tool that turned a payment into access granted
-- 30 calendar days on a clock, with no goal, no measurement, and
-- nothing for «نصل» to refer to.
--
-- This migration is the missing half: the write side.
--
--   suggest_objective(parent)   what to agree on, grounded in
--                               what we already know about them
--   start_stage(...)            the journey begins, once
--   stage_state(parent)         where they are, for the
--                               conversation and for /progress
--   close_stage(stage)          met → completed; missed → the
--                               unrequested extension, once;
--                               missed again → failed
--
-- ------------------------------------------------------------
-- What is deliberately NOT enforced in start_stage
--
-- `can_propose_stage` refuses on a 30-day cadence, a lifetime cap
-- per problem, and an improving trend. Those are rules about when
-- ADAM may *raise* the subject. They must not block a parent who
-- has already agreed and paid — refusing to start a journey
-- someone bought is not a safeguard, it is a bug that takes
-- money. start_stage enforces only the structural invariants:
-- one live journey, a target that fits its window, a clock inside
-- 7..60.
--
-- ------------------------------------------------------------
-- The extension is granted by the same call that detects the miss
--
-- `close_stage` is the only place a stage changes status, and it
-- grants the extension in the same statement that finds the clock
-- exhausted. That is why the column comment can say
-- «unrequested»: there is no path where a parent has to ask, and
-- no path where an operator has to remember.
-- ============================================================

begin;

-- ------------------------------------------------------------
-- suggest_objective — what to agree on, and never invented.
--
-- فريق آدم agrees the goal with the parent before any money
-- moves. This gives them the sentence to agree, built from the
-- situation ADAM already confirmed, so the goal that gets typed
-- into a stage is the one the evidence supports.
--
-- Returns ready = false with a reason when we do not know enough
-- yet. That is not a failure — it is the honest state, and it is
-- the same rule the free tier lives by: never claim to know a
-- house we have not been told about.
-- ------------------------------------------------------------
create or replace function public.suggest_objective(p_parent_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  v_child uuid; v_name text; v_sit text; v_label text; v_calm int;
begin
  select c.id, nullif(btrim(c.name), '') into v_child, v_name
  from public.children c where c.follower_id = p_parent_id
  order by c.is_primary desc nulls last, c.created_at limit 1;

  if v_child is null then
    return jsonb_build_object('ready', false, 'reason', 'no_child');
  end if;

  select s.key into v_sit
  from public.situations s
  where s.child_id = v_child and s.status = 'confirmed'
    and s.key is not null and s.key <> 'other'
  order by s.evidence_count desc limit 1;

  if v_sit is null then
    return jsonb_build_object('ready', false, 'reason', 'no_confirmed_situation',
                              'child', v_name);
  end if;

  v_label := public.situation_label_ar(v_sit);

  select count(*) into v_calm from public.daily_logs d
  where d.follower_id = p_parent_id and d.night_result = 'calm';

  return jsonb_build_object(
    'ready',            true,
    'child',            v_name,
    'problem_key',      v_sit,
    'objective_metric', 'calm_nights_in_window',
    'objective_target', 5,
    'objective_window', 7,
    'planned_logged_days', 29,
    -- The sentence فريق آدم reads out and agrees. Written as a
    -- result the parent can see, not as a metric.
    'objective_text',
      'خمس ليالٍ هادئة من سبع في ' || v_label
      || case when v_name is not null then ' مع ' || v_name else '' end,
    'calm_so_far',      v_calm);
end;
$function$;

comment on function public.suggest_objective(uuid) is
  'The goal to agree with a parent before a journey starts, grounded in the situation already confirmed for their child. Returns ready=false with a reason rather than inventing a goal for a house we do not know.';


-- ------------------------------------------------------------
-- start_stage — the journey begins.
-- ------------------------------------------------------------
create or replace function public.start_stage(
  p_parent_id           uuid,
  p_problem_key         text,
  p_objective_text      text,
  p_objective_target    integer default 5,
  p_objective_window    integer default 7,
  p_planned_logged_days integer default 29,
  p_objective_metric    text    default 'calm_nights_in_window',
  p_child_id            uuid    default null)
returns jsonb
language plpgsql
volatile
security definer
set search_path to 'pg_catalog','public'
as $function$
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

  -- One live journey per parent. The unique index enforces it; this check
  -- exists so the caller gets a reason instead of a constraint violation.
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
    planned_logged_days, status, started_at)
  values (
    p_parent_id, v_child, btrim(p_problem_key), btrim(p_objective_text),
    p_objective_metric, p_objective_target, p_objective_window,
    p_planned_logged_days, 'active', now())
  returning id into v_id;

  -- Close any open proposal for this problem, so the cadence cap in
  -- can_propose_stage counts an accepted offer as accepted.
  update public.stage_proposals
  set outcome = 'accepted', stage_id = v_id
  where parent_id = p_parent_id and problem_key = btrim(p_problem_key)
    and outcome = 'pending';

  return jsonb_build_object('started', true, 'stage_id', v_id)
      || public.stage_state(p_parent_id);
end;
$function$;

comment on function public.start_stage(uuid, text, text, integer, integer, integer, text, uuid) is
  'Begins the one live journey a parent may have. Enforces only structural invariants — one live stage, a target inside its window, a clock of 7..60 logged days — deliberately NOT the proposal cadence in can_propose_stage, because refusing to start a journey someone has already agreed and paid for is not a safeguard.';


-- ------------------------------------------------------------
-- stage_state — where they are.
--
-- One call, everything the conversation and /progress need. The
-- phase labels are the parent-facing names of observe/build/hold,
-- and `hold` is the one that matters: it exists so ADAM fades and
-- the change is shown to belong to the family rather than to him.
-- ------------------------------------------------------------
create or replace function public.stage_state(p_parent_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'pg_catalog','public'
as $function$
declare v record;
begin
  select * into v from public.v_stage_progress
  where parent_id = p_parent_id and status in ('active','extended')
  limit 1;

  if not found then
    return jsonb_build_object('in_stage', false);
  end if;

  return jsonb_build_object(
    'in_stage',          true,
    'stage_id',          v.stage_id,
    'problem_key',       v.problem_key,
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
    end);
end;
$function$;

comment on function public.stage_state(uuid) is
  'The live journey and everything derived from it, in one call: the agreed objective, progress towards it, the clock, and the phase. Returns in_stage=false for a parent who is not in one, which is most parents.';


-- ------------------------------------------------------------
-- close_stage — the only place a stage changes status.
--
-- Met                     → completed.
-- Clock out, not met,
--   no extension yet      → half the length again, granted here,
--                           unrequested. status = extended.
-- Clock out, not met,
--   already extended      → failed.
-- Otherwise               → still running, nothing written.
--
-- `objective_met` requires a FULL measurement window, so a 5-of-7
-- target can never be declared met on three nights of data. That
-- rule lives in the view and is not restated here — restating a
-- rule is how two versions of it start to disagree.
-- ------------------------------------------------------------
create or replace function public.close_stage(p_stage_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path to 'pg_catalog','public'
as $function$
declare v record; v_grant integer;
begin
  select * into v from public.v_stage_progress where stage_id = p_stage_id;
  if not found then
    return jsonb_build_object('closed', false, 'reason', 'no_such_stage');
  end if;
  if v.status not in ('active','extended') then
    return jsonb_build_object('closed', false, 'reason', 'not_live',
                              'status', v.status);
  end if;

  if v.objective_met then
    update public.stages
    set status = 'completed', completed_at = now()
    where id = p_stage_id;
    return jsonb_build_object('closed', true, 'outcome', 'completed',
                              'logged_days', v.logged_days);
  end if;

  if not v.clock_exhausted then
    return jsonb_build_object('closed', false, 'outcome', 'running',
                              'days_remaining', v.days_remaining);
  end if;

  if v.extension_days = 0 then
    -- Half the agreed length, again, without being asked. greatest(...,1)
    -- so a 7-day journey still gets a real extension rather than zero.
    v_grant := greatest(1, v.planned_logged_days / 2);
    update public.stages
    set status = 'extended', extension_days = v_grant, extension_granted_at = now()
    where id = p_stage_id;
    return jsonb_build_object('closed', false, 'outcome', 'extended',
                              'extension_days', v_grant);
  end if;

  update public.stages
  set status = 'failed', completed_at = now()
  where id = p_stage_id;
  return jsonb_build_object('closed', true, 'outcome', 'failed',
                            'logged_days', v.logged_days);
end;
$function$;

comment on function public.close_stage(uuid) is
  'The only place a stage changes status. Grants the half-length extension in the same call that detects the missed clock — which is what lets the offer promise it «بلا أن تطلبوا», with no parent asking and no operator remembering.';


-- ------------------------------------------------------------
-- activate_subscription now starts a journey, and says so.
--
-- The money side is unchanged: same signature, same payment row,
-- same fields, so the dashboard keeps working. What changes is
-- that it reports whether a JOURNEY exists, loudly, in its return
-- value — because a paid parent with no stage is the exact silent
-- half-state this whole migration exists to remove.
--
-- The objective is required and has no default. There is no
-- sensible fallback: a goal nobody agreed is not a goal, and
-- inventing one here would recreate the gap in a new place.
-- ------------------------------------------------------------
create or replace function public.activate_subscription(
  p_follower_id uuid,
  p_days integer default 30,
  p_amount numeric default null::numeric,
  p_currency text default null::text,
  p_notes text default null::text,
  p_problem_key text default null::text,
  p_objective_text text default null::text,
  p_objective_target integer default 5,
  p_objective_window integer default 7,
  p_planned_logged_days integer default 29)
returns jsonb
language plpgsql
volatile
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  f public.followers%rowtype;
  v_country text; v_amount numeric; v_currency text;
  v_start timestamptz := now(); v_expires timestamptz;
  v_pay_id uuid; v_journey jsonb;
begin
  select * into f from public.followers where id = p_follower_id;
  if not found then
    raise exception 'follower_not_found' using errcode = 'P0002';
  end if;

  v_expires := v_start + make_interval(days => greatest(coalesce(p_days, 30), 1));
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
      subscription_started_at = v_start, subscription_expires_at = v_expires,
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
    p_objective_target, p_objective_window, p_planned_logged_days);

  return jsonb_build_object(
    'follower_id', p_follower_id,
    'payment_id',  v_pay_id,
    'funnel_stage','paid_active',
    'subscription_started_at', v_start,
    'subscription_expires_at', v_expires,
    'amount', v_amount, 'currency', v_currency,
    'journey', v_journey);
end;
$function$;

comment on function public.activate_subscription(uuid, integer, numeric, text, text, text, text, integer, integer, integer) is
  'Records the payment AND starts the agreed journey. The objective has no default on purpose: a goal nobody agreed is not a goal. When it is missing the money is still recorded and `journey.started` comes back false with `objective_required`, so a paid parent with no journey is visible in the return value instead of silent.';

revoke all on function public.suggest_objective(uuid) from anon, authenticated, public;
revoke all on function public.start_stage(uuid, text, text, integer, integer, integer, text, uuid) from anon, authenticated, public;
revoke all on function public.stage_state(uuid) from anon, authenticated, public;
revoke all on function public.close_stage(uuid) from anon, authenticated, public;

grant execute on function public.suggest_objective(uuid) to service_role;
grant execute on function public.start_stage(uuid, text, text, integer, integer, integer, text, uuid) to service_role;
grant execute on function public.stage_state(uuid) to service_role;
grant execute on function public.close_stage(uuid) to service_role;

commit;
