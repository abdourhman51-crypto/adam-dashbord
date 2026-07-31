begin;

-- ============================================================
-- The outgoing gate, and the context a composed reply needs.
-- (architecture §2.2, §2.6, §3.2 · experience principle E7)
--
-- WHY THE HARVEST REPLY IS WORTH AN LLM CALL AND MOST THINGS
-- ARE NOT
--
-- Peak-End says an experience is remembered by its most intense
-- moment and its ending. ADAM's ending is the evening reply to
-- "how did it go?" — and it has been one of three fixed strings,
-- byte-identical every night forever. The single most memorable
-- message in the product was its most generic.
--
-- Composing it is the exception to §2.2's "tier 1 first", not a
-- violation of it: what to say cannot be derived, because it
-- depends on what she just reported about a specific evening.
--
-- THE GATE IS THE POINT, NOT THE PROMPT
--
-- A prompt asking for warmth produces warmth on average. This
-- runs every composed message through the same three checks and
-- refuses on failure, so the fixed reply is what she gets when
-- the model is off — never nothing, never something unchecked.
-- ============================================================


-- ------------------------------------------------------------
-- gate_composed_reply — one gate for every composed message.
--
-- Three checks, all of which must pass:
--   vocabulary  copy_violations()      — §0.7, P17
--   length      the moment's budget    — P6
--   uniqueness  passes_uniqueness_test — §2.6
--
-- Returns every failure, not the first. A composer fixing one
-- problem per round trip is a composer that gets switched off.
--
-- Uniqueness is skipped only where the architecture says a
-- message need not be family-specific: the rescue is
-- unconditional (§2.5) and answers whatever exists, possibly
-- nothing.
-- ------------------------------------------------------------
create or replace function public.gate_composed_reply(
  p_parent_id uuid,
  p_key       text,
  p_body      text)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  v_outgoing jsonb;
  v_unique   jsonb;
  v_reasons  text[] := '{}';
  v_needs_unique boolean;
begin
  v_outgoing := public.validate_outgoing(p_key, p_body);

  if not coalesce((v_outgoing->>'ok')::boolean, false) then
    v_reasons := v_reasons || (v_outgoing->>'reason');
  end if;

  -- The rescue may be generic; everything proactive may not.
  v_needs_unique := p_key not in ('rescue', 'first_contact');

  if v_needs_unique then
    v_unique := public.passes_uniqueness_test(p_parent_id, p_body);
    if not coalesce((v_unique->>'passes')::boolean, false) then
      v_reasons := v_reasons || ('uniqueness:' || coalesce(v_unique->>'reason', 'unknown'));
    end if;
  else
    v_unique := jsonb_build_object('passes', true, 'reason', 'not_required');
  end if;

  return jsonb_build_object(
    'ok',       cardinality(v_reasons) = 0,
    'reasons',  to_jsonb(v_reasons),
    'outgoing', v_outgoing,
    'unique',   v_unique);
end;
$function$;

comment on function public.gate_composed_reply(uuid, text, text) is
  'The single gate every composed message passes: vocabulary (§0.7), line budget (P6) and family-uniqueness (§2.6). Returns every failure rather than the first. Uniqueness is waived only for the rescue and first contact, which the architecture allows to be generic.';


-- ------------------------------------------------------------
-- get_harvest_context — Tier-1 assembly for the evening reply.
--
-- The composer receives facts and produces language; it never
-- queries. Everything here is measured or authored — no chat
-- history, so §2.8 holds on this path too.
--
-- `what_worked` is the load-bearing field: it is what lets the
-- reply say something only true of this child, which is what
-- gate_composed_reply will then require.
-- ------------------------------------------------------------
create or replace function public.get_harvest_context(
  p_parent_id uuid,
  p_answer    text)
returns jsonb
language plpgsql
stable
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
                      else               'harvest_reply_skip' end);
end;
$function$;

comment on function public.get_harvest_context(uuid, text) is
  'Tier-1 facts for the evening reply: the child, the situation, today''s seed, her answer, this week against last week, and the measured tokens the reply must contain one of. The composer receives facts and produces language; it never queries.';


revoke all on function public.gate_composed_reply(uuid, text, text) from anon, authenticated, public;
revoke all on function public.get_harvest_context(uuid, text)       from anon, authenticated, public;

grant execute on function public.gate_composed_reply(uuid, text, text) to service_role;
grant execute on function public.get_harvest_context(uuid, text)       to service_role;

commit;
