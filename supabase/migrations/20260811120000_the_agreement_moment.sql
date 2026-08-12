-- ============================================================
-- لحظة الاتفاق — the conversion moment, built.
-- Design: docs/the-agreement-moment.md · docs/the-conversion-seam.md
--
-- The founder's ordered flow:
--   free → ADAM gathers real evidence → «this is the pattern I see»
--        → parent «yes, that is what I want to change»
--        → ⭐ THE AGREEMENT → ADAM explains how + the price
--        → parent decides to pay → paid
--
-- This migration builds only the ⭐ — the agreement, agreed while it is
-- still FREE, over a goal, before any price. It writes a reversible
-- receipt that the PARENT (not a human) agreed the goal, so a later
-- build can let activate_subscription read the goal instead of a human
-- typing it. That later build is deliberately NOT here — this one is
-- reviewed on its own.
--
-- ------------------------------------------------------------
-- Why it needs ZERO n8n change
--
-- The parent taps «نشتغل عليه» → the Router (n8n) maps it to the key
-- `menu_journey` and calls get_moment_after_tap('menu_journey', …).
-- Any callback that begins with `menu_` already flows through that same
-- function untouched. So the whole moment lives in the database:
--   · get_moment_after_tap learns to show the agreement BEFORE the offer
--     when the parent is ready and has not agreed yet;
--   · the two agreement buttons carry `menu_goal_agreed` (menu-prefixed,
--     so it routes with no Router edit) and `other` (the constitutional
--     escape hatch, F9, which already routes to the open free space).
-- Nothing in n8n moves. No engine is turned on. No data is collected.
--
-- ------------------------------------------------------------
-- Why get_conversation_moment is NOT redefined here
--
-- It is a large, critical, live function. Touching it to add one screen
-- risks the other twenty. Instead the agreement screen is composed by a
-- new, dedicated function (compose_agreement_moment) and only the small
-- tap router (get_moment_after_tap) is redefined — copied verbatim from
-- 20260807270000 with exactly two branches added, both marked ⭐.
-- ============================================================

begin;

-- ------------------------------------------------------------
-- 1 · The receipt. A fact about the PARENT, like offer_fork_at and
-- intention_asked_at — one agreed goal at a time, so it self-heals
-- across retries and expires quietly rather than haunting them.
-- ------------------------------------------------------------
alter table public.followers
  add column if not exists agreed_objective jsonb,
  add column if not exists agreed_at        timestamptz;

comment on column public.followers.agreed_objective is
  'The goal the parent agreed, in their own conversion moment, while it was still free: the suggest_objective payload they said «نعم» to (problem_key, objective_text, target, window, planned_logged_days). Read by a later activate_subscription so the human confirms money and never types the goal. Null until agreed; re-set if a stale agreement is re-mirrored.';
comment on column public.followers.agreed_at is
  'When the parent agreed the goal. Also the expiry anchor: an agreement left unpaid past AGREEMENT_TTL is treated as stale and the pattern is mirrored afresh from current evidence, never resurrected as a follow-up.';


-- ------------------------------------------------------------
-- 2 · The composed agreement screen. Built at read time from
-- suggest_objective — no price, never stored. Three beats in one
-- surface: the mirror (the Witness naming the pattern), the goal
-- (one falsifiable sentence), and the question that hands the parent
-- ownership. The «شيء آخر» button is the escape hatch and the
-- re-ground door in one: it carries `other`, the live open free
-- space, where a parent can name the problem that actually hurts.
-- ------------------------------------------------------------
insert into public.conversation_moments
  (key, category, tier, body_ar, buttons, buttons_forbidden, max_lines, requires_commerce, note)
values
  ('menu_agree_goal', 'goal', 'composed',
   null, '[]'::jsonb, false, 8, true,
   'لحظة الاتفاق. Composed by compose_agreement_moment from suggest_objective at read time: mirror + one falsifiable goal + the ownership question. requires_commerce means strain withdraws it silently. Buttons are composed, not stored: «نعم»→menu_goal_agreed writes the receipt then shows the offer; «شيء آخر»→other is the escape hatch and the open free space to name a different problem.')
on conflict (key) do update
  set category = excluded.category, tier = excluded.tier,
      max_lines = excluded.max_lines, requires_commerce = excluded.requires_commerce,
      note = excluded.note;


-- ------------------------------------------------------------
-- 3 · should_agree_first — the gatekeeper at every door.
--
-- The agreement may only be shown when it can be shown honestly:
-- the evidence is there (suggest_objective ready), commerce is not
-- withdrawn by strain, the parent is not already in a journey, and
-- they have not already agreed a still-fresh goal. Any «no» means the
-- journey door shows its ordinary offer surface (or, at strain, the
-- presence form) exactly as it does today — nothing regresses.
-- ------------------------------------------------------------
create or replace function public.should_agree_first(p_parent_id uuid)
returns boolean
language plpgsql
stable
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  v_ready   boolean;
  v_agreed  timestamptz;
  v_ttl     constant interval := interval '14 days';
begin
  if p_parent_id is null then
    return false;
  end if;

  -- Strain withdraws the whole moment, silently.
  if not coalesce(public.commerce_allowed(p_parent_id), true) then
    return false;
  end if;

  -- Already in a live journey → they are past this moment.
  if exists (select 1 from public.stages
             where parent_id = p_parent_id
               and status in ('active','extended','paused')) then
    return false;
  end if;

  -- Already agreed a still-fresh goal → show the offer, not the agreement.
  -- A stale, unpaid agreement (older than the TTL) is allowed to lapse, so
  -- the pattern is mirrored afresh rather than resurrected.
  select agreed_at into v_agreed from public.followers where id = p_parent_id;
  if v_agreed is not null and v_agreed > now() - v_ttl then
    return false;
  end if;

  -- The evidence must actually support a real goal.
  v_ready := coalesce((public.suggest_objective(p_parent_id)->>'ready')::boolean, false);
  return v_ready;
end;
$function$;

comment on function public.should_agree_first(uuid) is
  'True when the journey door should open onto the agreement (لحظة الاتفاق) rather than the offer: evidence ready, commerce not withdrawn by strain, no live journey, and no still-fresh prior agreement. False in every other case, so the offer surface behaves exactly as before.';


-- ------------------------------------------------------------
-- 4 · compose_agreement_moment — the screen itself.
--
-- Returns the same jsonb shape get_conversation_moment returns, so the
-- tap router can hand it straight back. If for any reason the evidence
-- is not there when this is called, it falls back to the ordinary offer
-- surface rather than inventing a goal — the same honesty the free tier
-- lives by.
-- ------------------------------------------------------------
create or replace function public.compose_agreement_moment(p_parent_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  m       public.conversation_moments%rowtype;
  v_offer jsonb;
  v_nl    text := chr(10);
  v_who   text;
  v_sit   text;
  v_body  text;
begin
  v_offer := public.suggest_objective(p_parent_id);
  if not coalesce((v_offer->>'ready')::boolean, false) then
    -- Never fake a goal. Show the ordinary journey door instead.
    return public.get_conversation_moment('menu_journey', p_parent_id);
  end if;

  select * into m from public.conversation_moments where key = 'menu_agree_goal';
  if not found then
    return public.get_conversation_moment('menu_journey', p_parent_id);
  end if;

  v_who := coalesce(nullif(btrim(v_offer->>'child'), ''), 'طفلكم');
  v_sit := public.hard_moment_label(v_offer->>'problem_key');

  -- Three beats: the mirror, the agreement, the ownership question.
  v_body :=
    'لاحظتُ أن أصعب لحظة معكم ومع ' || v_who ||
      coalesce(' هي ' || v_sit, ' تتكرّر أكثر من غيرها') || '.' || v_nl ||
    'ولو أردنا أن نعمل عليها حتى تتغيّر، فلنتّفق أوّلاً على شكل الوصول —' || v_nl ||
    'لا شعوراً نتجادل فيه، بل شيئاً نراه بأعيننا معاً:' || v_nl ||
    (v_offer->>'objective_text') || '.' || v_nl ||
    'هل هذا هو ما تريدون أن يتغيّر؟';

  return jsonb_build_object(
    'found', true, 'key', 'menu_agree_goal', 'allowed', true,
    'category', m.category, 'tier', m.tier, 'body', v_body,
    'buttons', jsonb_build_array(
      jsonb_build_object('label', 'نعم، هذا ما أريده',        'cb', 'menu_goal_agreed'),
      jsonb_build_object('label', 'المشكلة الأكبر شيء آخر',   'cb', 'other')),
    'buttons_forbidden', m.buttons_forbidden,
    'max_lines', m.max_lines);
end;
$function$;

comment on function public.compose_agreement_moment(uuid) is
  'The agreement screen (لحظة الاتفاق), composed at read time from suggest_objective: the mirror, one falsifiable goal, and the ownership question — no price, never stored. Buttons: «نعم»→menu_goal_agreed, «شيء آخر»→other. Falls back to the offer surface rather than inventing a goal when evidence is absent.';


-- ------------------------------------------------------------
-- 5 · agree_objective — the parent says «نعم», recorded.
--
-- Writes the reversible receipt: the agreed goal on the parent, and a
-- pending stage_proposals row so start_stage's existing accounting (it
-- flips a pending proposal to accepted) and the cadence cap both see an
-- accepted offer. Takes no money and starts no clock. Idempotent: a
-- second «نعم» refreshes the same receipt, never a duplicate journey.
-- ------------------------------------------------------------
create or replace function public.agree_objective(p_parent_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  v_offer   jsonb;
  v_child   uuid;
  v_problem text;
begin
  if p_parent_id is null then
    return jsonb_build_object('agreed', false, 'reason', 'no_parent');
  end if;

  if not exists (select 1 from public.followers where id = p_parent_id) then
    return jsonb_build_object('agreed', false, 'reason', 'no_such_parent');
  end if;

  -- Never agree over a parent who is drowning.
  if not coalesce(public.commerce_allowed(p_parent_id), true) then
    return jsonb_build_object('agreed', false, 'reason', 'commerce_blocked');
  end if;

  -- Already in a live journey → nothing to agree.
  if exists (select 1 from public.stages
             where parent_id = p_parent_id
               and status in ('active','extended','paused')) then
    return jsonb_build_object('agreed', false, 'reason', 'already_in_journey');
  end if;

  v_offer := public.suggest_objective(p_parent_id);
  if not coalesce((v_offer->>'ready')::boolean, false) then
    return jsonb_build_object('agreed', false,
                              'reason', coalesce(v_offer->>'reason', 'not_ready'));
  end if;

  v_problem := v_offer->>'problem_key';

  -- The receipt. Only the fields a journey needs, so nothing stale can
  -- ride along.
  update public.followers
  set agreed_objective = jsonb_build_object(
        'problem_key',         v_problem,
        'objective_text',      v_offer->>'objective_text',
        'objective_metric',    coalesce(v_offer->>'objective_metric', 'calm_nights_in_window'),
        'objective_target',    (v_offer->>'objective_target')::int,
        'objective_window',    (v_offer->>'objective_window')::int,
        'planned_logged_days', (v_offer->>'planned_logged_days')::int),
      agreed_at = now()
  where id = p_parent_id;

  -- The primary child, for the proposal row.
  select c.id into v_child from public.children c
  where c.follower_id = p_parent_id
  order by c.is_primary desc nulls last, c.created_at limit 1;

  -- A pending proposal for start_stage's accounting and the cadence cap.
  -- One per problem: if a pending one already exists, leave it.
  if not exists (
        select 1 from public.stage_proposals
        where parent_id = p_parent_id and problem_key = v_problem
          and outcome = 'pending') then
    insert into public.stage_proposals (parent_id, child_id, problem_key, outcome)
    values (p_parent_id, v_child, v_problem, 'pending');
  end if;

  return jsonb_build_object(
    'agreed',         true,
    'problem_key',    v_problem,
    'objective_text', v_offer->>'objective_text');
end;
$function$;

comment on function public.agree_objective(uuid) is
  'The parent''s «نعم» in the conversion moment, recorded — free and reversible: writes the agreed goal onto the parent (agreed_objective/agreed_at) and a pending stage_proposals row for start_stage''s accounting and the cadence cap. Takes no money, starts no clock. Idempotent. Refuses at strain, in a live journey, or before the evidence supports a real goal.';


-- ------------------------------------------------------------
-- 6 · get_moment_after_tap — copied verbatim from
-- 20260807270000, with exactly two branches added, both marked ⭐:
--   ⭐A  menu_journey, when should_agree_first → show the agreement.
--   ⭐B  menu_goal_agreed → record the «نعم», then show the offer.
-- Everything else is byte-for-byte the live function.
-- ------------------------------------------------------------
create or replace function public.get_moment_after_tap(
  p_key text, p_parent_id uuid, p_country_code text default null::text)
returns jsonb
language plpgsql
security definer
set search_path to 'pg_catalog', 'public'
as $function$
declare
  v_rec  jsonb;
  v_req  uuid;
  v_done text := null;
  v_moment text := p_key;
  v_reading jsonb;
  v_join jsonb;
  v_cap jsonb;
begin
  -- ⭐B The parent agreed the goal. Record it (free, reversible), then
  -- open the offer surface — how we get there, and the price. From here
  -- the journey door will show the offer directly, not the agreement.
  if p_key = 'menu_goal_agreed' then
    perform public.agree_objective(p_parent_id);
    return public.get_conversation_moment('menu_journey', p_parent_id)
        || jsonb_build_object('action_done', 'goal_agreed');
  end if;

  -- ⭐A The journey door. When the parent is ready and has not agreed a
  -- goal yet, it opens onto the agreement (لحظة الاتفاق) — never onto a
  -- price. Every other case falls straight through to the ordinary offer
  -- surface below, unchanged.
  if p_key = 'menu_journey' and public.should_agree_first(p_parent_id) then
    return public.compose_agreement_moment(p_parent_id)
        || jsonb_build_object('country_recorded', 'null'::jsonb)
        || jsonb_build_object('action_done', 'null'::jsonb);
  end if;

  -- A TYPED country answer arrives here with the raw text in p_country_code and a
  -- reserved key, routed by W1's M2 - Classify Track (track=country_answer) into
  -- the SAME credentialed tap node the buttons already use — so free-text capture
  -- needs no new credentialed workflow node. Handled first, before record_country
  -- would choke on «انا من تونس». The classify gate only sends us here inside the
  -- open 36h window, so we always return a sendable moment: a confirmation if
  -- caught, or «اكتبه مرّة أخرى» if not.
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

    -- A code we cannot place IS the «بلد آخر» answer, however it was spelled.
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
        -- Open the window they will type into. Without this stamp,
        -- capture_country_text refuses their answer as not_awaiting.
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
    return coalesce(public.get_conversation_moment('menu_reading', p_parent_id), '{}'::jsonb)
        || jsonb_build_object('body', v_reading->>'body')
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


-- ------------------------------------------------------------
-- 7 · Grants. Locked to service_role from birth, like every other
-- function in this schema.
-- ------------------------------------------------------------
revoke all on function public.should_agree_first(uuid)       from anon, authenticated, public;
revoke all on function public.compose_agreement_moment(uuid) from anon, authenticated, public;
revoke all on function public.agree_objective(uuid)          from anon, authenticated, public;

grant execute on function public.should_agree_first(uuid)       to service_role;
grant execute on function public.compose_agreement_moment(uuid) to service_role;
grant execute on function public.agree_objective(uuid)          to service_role;

commit;
