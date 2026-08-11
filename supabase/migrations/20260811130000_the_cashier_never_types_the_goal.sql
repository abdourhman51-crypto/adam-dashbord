-- ============================================================
-- The cashier confirms money, and never types the goal.
-- Design: docs/the-agreement-moment.md · docs/the-conversion-seam.md (step 4)
--
-- لحظة الاتفاق (20260811120000) writes a receipt when the parent agrees
-- their goal, in the chat, while it is still free:
-- followers.agreed_objective. This migration closes the loop so §7 is
-- literally true — «فريق آدم أمين صندوق، لا وكيل مبيعات»:
--
--   activate_subscription, called with NO goal — which is exactly what a
--   cashier confirming a payment passes — now reads the goal the PARENT
--   already agreed, instead of a human typing one.
--
-- ------------------------------------------------------------
-- What changes, and what does NOT
--
-- Only the ten-argument activate_subscription body changes, and only in
-- two additive ways, both marked ⭐:
--   ⭐1  when no goal is passed AND the parent has an agreed receipt,
--        the receipt fills the goal before start_stage is called;
--   ⭐2  once a journey actually starts, the receipt is consumed, so a
--        completed journey later cannot leave a stale agreement behind.
--
-- Everything else is byte-for-byte the live function from 20260807090000:
-- same signature, same defaults, same pricing, same payment row, same
-- security. Callers that DO pass a goal are unaffected — an explicit goal
-- still wins. Callers that pass none and have no receipt still get
-- journey.started=false, objective_required, exactly as before. Nothing
-- regresses; the only new behaviour is a receipt being honoured.
--
-- The signature is unchanged, so this is a true replace, not an overload
-- (the trap 20260807170000 exists to remember).
-- ============================================================

begin;

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

  -- ⭐1 The cashier passes money, not a goal. When no goal is supplied and
  -- the parent agreed one in لحظة الاتفاق, the receipt fills it — so the
  -- goal is the one the PARENT agreed, never one a human invents at the
  -- till. An explicitly passed goal still wins (this branch does not run).
  if nullif(btrim(coalesce(p_objective_text, '')), '') is null
     and nullif(btrim(coalesce(p_problem_key, '')), '') is null
     and f.agreed_objective is not null then
    p_problem_key         := f.agreed_objective->>'problem_key';
    p_objective_text      := f.agreed_objective->>'objective_text';
    p_objective_target    := coalesce((f.agreed_objective->>'objective_target')::int,    p_objective_target);
    p_objective_window    := coalesce((f.agreed_objective->>'objective_window')::int,    p_objective_window);
    p_planned_logged_days := coalesce((f.agreed_objective->>'planned_logged_days')::int, p_planned_logged_days);
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

  -- ⭐2 A receipt becomes a journey exactly once. Consuming it keeps a
  -- later completed journey from leaving a stale agreement that would
  -- block a fresh one (should_agree_first reads agreed_at).
  if coalesce((v_journey->>'started')::boolean, false) then
    update public.followers set agreed_objective = null, agreed_at = null
    where id = p_follower_id;
  end if;

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

comment on function public.activate_subscription(
  uuid, integer, numeric, text, text, text, text, integer, integer, integer) is
  'The only way to activate a subscription. Records the payment and starts the agreed journey. When called with no goal — as the cashier''s dashboard does — it reads the goal the parent agreed in لحظة الاتفاق (followers.agreed_objective) and consumes that receipt once the journey starts, so the human confirms money and never types a goal. With no goal passed AND no receipt, the payment is still recorded and journey.started comes back false with objective_required.';

-- Re-affirm the security posture from 20260807160000. CREATE OR REPLACE
-- preserves privileges, but stating them here means a rebuild of this file
-- alone cannot silently reopen the door the escalation fix closed.
revoke all on function public.activate_subscription(
  uuid, integer, numeric, text, text, text, text, integer, integer, integer)
  from anon, authenticated, public;
grant execute on function public.activate_subscription(
  uuid, integer, numeric, text, text, text, text, integer, integer, integer)
  to service_role;

commit;
