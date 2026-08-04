begin;

-- ============================================================
-- The intention question, sent — not just written.
-- (docs/adam-system.md §10 item 4 · 20260801170000_give_before_asking.sql)
--
-- should_ask_intention() and record_intention() were built and
-- tested, and never called from anywhere. The evening harvest
-- reply is the one place §10 item 4 says it belongs: "asked once,
-- ever, and only after something has already worked" is exactly
-- the moment a calm night has just been logged and the reply is
-- already being composed.
--
-- WHY get_harvest_context, NOT A NEW CALL
--
-- The established rule on this workflow (35099f1, 20260803120000):
-- no new authenticated node reliably gets a credential through the
-- MCP API. get_harvest_context is the one call already on this
-- path, already credentialed, already live. It carries the ask the
-- same way get_agent_bundle already carries the country ask.
--
-- WHY STAMPED HERE, NOT ON CAPTURE
--
-- record_country_ask() (20260801230000) already settled this:
-- "stamped when ASKED, because ignoring the question is an
-- answer." Whether or not the next free-text reply is ever wired
-- to record_intention() is a separate, harder question — capturing
-- a free-text answer to a proactive question needs a routing
-- decision this change does not make. But failing to capture it
-- must never mean asking again. Stamping intention_asked_at the
-- moment the question is actually sent, inside the same call that
-- builds it, makes that true regardless of what happens next.
-- ============================================================


-- ------------------------------------------------------------
-- record_intention_ask — idempotent stamp, no answer required.
-- Mirrors record_country_ask(). Never touches intention_text.
-- ------------------------------------------------------------
create or replace function public.record_intention_ask(p_parent_id uuid)
returns void
language sql
volatile
security definer
set search_path to 'pg_catalog','public'
as $function$
  update public.followers
  set intention_asked_at = coalesce(intention_asked_at, now())
  where id = p_parent_id and intention_asked_at is null;
$function$;

comment on function public.record_intention_ask(uuid) is
  'Stamps intention_asked_at with no answer required, the moment the question is actually sent. Idempotent. Exists so a capture path that is not yet wired cannot cause the question to be asked twice.';

revoke all on function public.record_intention_ask(uuid) from anon, authenticated, public;
grant execute on function public.record_intention_ask(uuid) to service_role;


-- ------------------------------------------------------------
-- get_harvest_context — now also decides and stamps the intention
-- ask. Volatile (it was stable): the stamp is the point.
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

  -- The intention is asked once, ever, and only on a positive answer —
  -- "after something has already worked" means this reply, not a future
  -- one. Stamped now, in the same call that hands the question back.
  if p_answer = 'ok' and public.should_ask_intention(p_parent_id) then
    v_ask_intention := true;
    perform public.record_intention_ask(p_parent_id);
    select body_ar into v_intention_body
    from public.conversation_moments where key = 'intention_ask';
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
    'intention_ask_body', v_intention_body);
end;
$function$;

comment on function public.get_harvest_context(uuid, text) is
  'Tier-1 facts for the evening reply: the child, the situation, today''s seed, her answer, this week against last week, and the measured tokens the reply must contain one of. Also decides and stamps the once-ever intention ask on a positive answer. The composer receives facts and produces language; it never queries.';

commit;
