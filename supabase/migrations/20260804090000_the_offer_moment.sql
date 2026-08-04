begin;

-- ============================================================
-- The offer moment — the fork, presented once, only when earned.
-- (docs/adam-system.md §5, §10 item 5 · give_before_asking migration)
--
-- offer_ready() was built and tested and called from nowhere. It
-- returns the FORK — «هل نتركه يتكرّر... أم نشتغل عليه حتى يتغيّر؟» —
-- no price, no product name, no urgency, and only once the parent
-- has SEEN their own evidence (child named, a confirmed situation,
-- three attempts, two outcomes, and commerce not withdrawn by
-- strain). §5: the one who chooses «نشتغل عليه» is the one who
-- asked. The fork is not a push; it is a question, and the answer
-- is the request.
--
-- WHY IT RIDES THE HARVEST, AND WHY IT IS STAMPED ONCE
--
-- §10.5 is «لحظة العرض بعد أول نمط» — after the first pattern, not
-- on demand. The evening harvest is exactly that moment: the reply
-- is already being composed on a night the parent said it went
-- well, and offer_ready reads the evidence that has by then
-- accumulated. So the fork is appended to the harvest, the same
-- mechanism as the intention ask.
--
-- But offer_ready is purely derived — left alone it returns
-- ready:true every night until the parent converts, which is the
-- push that produced 8 offers and 0 clicks. So the presentation is
-- stamped once, atomically, exactly as record_country_ask and
-- record_intention_ask stamp theirs: a fork shown twice from
-- something that claims to wait for you is the brand's own
-- accusation against itself.
--
-- WHY THE BUTTONS REUSE LIVE CALLBACKS, AND ADD NO NEW ROUTE
--
-- «نشتغل عليه» carries cta_full_companion — already in the Router's
-- tap table, already routed to menu_journey, which is the live
-- journey door built from supported_countries at read time, with
-- فريق آدم as the cashier (§7) and, at strain, the presence form
-- that withholds the price. «نتركه يتكرّر» carries not_now — the
-- graceful no, into the open free space. Neither invents a new
-- node, a new callback, or a new handoff; the dead CTA LLM
-- offer-writer chain stays dead.
-- ============================================================


-- ------------------------------------------------------------
-- The one-time stamp. A fact about the PERSON, not the message —
-- the message-shaped version of this idea is what cost six
-- families their consent footer (see the seed exit).
-- ------------------------------------------------------------
alter table public.followers
  add column if not exists offer_fork_at timestamptz;

comment on column public.followers.offer_fork_at is
  'When the offer fork (offer_ready) was presented on the evening harvest. Stamped once, ever; the fork is never shown twice. Mirrors intention_asked_at and country_asked_at — a fact about the parent, so it self-heals across retries.';


-- ------------------------------------------------------------
-- take_offer_moment — claim the fork atomically, or decline to.
-- Volatile: it writes the stamp. Returns present:false whenever
-- the evidence is not there OR the fork has already been shown.
-- ------------------------------------------------------------
create or replace function public.take_offer_moment(p_parent_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  v_offer jsonb;
begin
  v_offer := public.offer_ready(p_parent_id);

  -- offer_ready owns the whole evidence gate, including strain
  -- (commerce_blocked) which withdraws the fork silently.
  if not coalesce((v_offer->>'ready')::boolean, false) then
    return jsonb_build_object('present', false);
  end if;

  -- Claim the one-time moment. The stamp lands before the fork is
  -- handed back, so a retry cannot present it twice: a spent stamp
  -- with no send costs one fork, never a repeat.
  update public.followers
     set offer_fork_at = now()
   where id = p_parent_id and offer_fork_at is null;

  if not found then
    return jsonb_build_object('present', false);
  end if;

  return jsonb_build_object(
    'present', true,
    'fork_ar', v_offer->>'fork_ar',
    -- Live callbacks only. «نشتغل عليه» → the journey door; «نتركه
    -- يتكرّر» → the open free space. Both already handled by the Router.
    'buttons', jsonb_build_array(
      jsonb_build_object('label', 'نشتغل عليه',  'cb', 'cta_full_companion'),
      jsonb_build_object('label', 'نتركه يتكرّر', 'cb', 'not_now')));
end;
$function$;

comment on function public.take_offer_moment(uuid) is
  'The offer moment (§10.5). Presents offer_ready''s fork exactly once, only when the evidence gate passes, and stamps offer_fork_at atomically so it never repeats — the discipline that separates a fork from the push that produced 8 offers, 0 clicks. Buttons reuse live callbacks: «نشتغل عليه»→cta_full_companion (the journey door, فريق آدم the cashier), «نتركه يتكرّر»→not_now (the open free space). Returns present:false when unearned, strained, or already shown.';

revoke all on function public.take_offer_moment(uuid) from anon, authenticated, public;
grant execute on function public.take_offer_moment(uuid) to service_role;


-- ------------------------------------------------------------
-- get_harvest_context — the offer fork outranks the intention ask.
--
-- One proactive add-on per harvest, and only on a positive night.
-- The offer is rarer, gated higher, and it is the conversion
-- moment, so it takes precedence; when it presents, the intention
-- ask is NOT spent and waits for a later harvest. By the time the
-- offer is earned the intention has usually been asked already
-- (one calm night is enough for it), so they rarely collide — but
-- when they do, the fork wins and the anchor is not lost.
-- ------------------------------------------------------------
create or replace function public.get_harvest_context(
  p_parent_id uuid,
  p_answer    text)
returns jsonb
language plpgsql
volatile
security definer
set search_path to 'pg_catalog','public'
as $function$
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

  select d.seed_text, d.step_given into v_seed, v_step
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

  v_tok := public.family_tokens(p_parent_id);

  -- Only one proactive add-on, and only on a positive night. The offer
  -- fork is tried first; if it presents, the intention ask is left for a
  -- future harvest (its stamp is not spent).
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
    -- What the reply must contain at least one of, or it does not send.
    'must_mention_one_of', v_tok->'measured',
    'fallback_key', case p_answer
                      when 'ok'     then 'harvest_reply_ok'
                      when 'failed' then 'harvest_reply_failed'
                      else               'harvest_reply_skip' end,
    'ask_intention',      v_ask_intention,
    'intention_ask_body', v_intention_body,
    'offer_present',      v_offer_present,
    'offer_fork_ar',      case when v_offer_present then v_offer->>'fork_ar' else null end,
    'offer_buttons',      case when v_offer_present then v_offer->'buttons' else '[]'::jsonb end);
end;
$function$;

comment on function public.get_harvest_context(uuid, text) is
  'Tier-1 facts for the evening reply: the child, the situation, today''s seed, her answer, this week against last week, and the measured tokens the reply must contain one of. On a positive night it also decides the ONE proactive add-on: the offer fork if earned (once, ever), otherwise the intention ask if due (once, ever). The composer receives facts and produces language; it never queries.';

commit;
