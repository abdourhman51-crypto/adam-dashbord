begin;

-- ============================================================
-- The Knowledge layer: what ADAM knows, what that makes
-- possible, and what may not be said.
-- (architecture §2)
--
-- §0.2 says this is the conversion engine — "if revenue is weak,
-- this is where the work is". Three things in §2 were prose:
--
--   §2.4  capability grows with context
--   §2.5  the send gate, five message kinds, one row each
--   §2.6  "Could this exact message be sent to a different
--         family? If yes, it does not send."
--
-- §2.6 is the one that has never been implemented, and it is the
-- test the architecture names for every proactive message. A test
-- nobody runs is a paragraph.
-- ============================================================


-- ------------------------------------------------------------
-- family_tokens — the Tier-1 facts that make a message this
-- family's and no one else's.
--
-- TWO CLASSES, and the distinction is the whole point:
--
--   identity  the child's name. Supplied, not earned.
--   measured  a situation ADAM detected, a step that worked for
--             THIS child, an outcome counted from their own logs.
--
-- A generic parenting tip with a name substituted into it passes
-- a naive uniqueness test and fails the real one. That is exactly
-- risk R2 — "the Seed became a tip library" — so identity alone
-- is never sufficient for a proactive message.
--
-- Reads only what ADAM authored or measured. It never touches
-- n8n_chat_histories or memory_events: §2.8's rule is provenance,
-- not content filtering, because filtering Arabic free text
-- cannot be done safely. Two live rows settled that — a child
-- assault disclosure and a pattern label revealing family
-- separation, neither distinguishable from a safe label by
-- pattern matching.
-- ------------------------------------------------------------
create or replace function public.family_tokens(p_parent_id uuid)
returns jsonb
language sql
stable
security definer
set search_path to 'pg_catalog','public'
as $function$
  select jsonb_build_object(
    'identity', coalesce((
      select jsonb_agg(distinct nullif(btrim(c.name), ''))
      from public.children c
      where c.follower_id = p_parent_id
        and nullif(btrim(c.name), '') is not null
        and btrim(c.name) not in ('الطفل','الطفلة')
    ), '[]'::jsonb),

    'measured', coalesce((
      select jsonb_agg(distinct t) from (
        -- situations ADAM detected, in the words the parent hears
        select public.hard_moment_label(s.key) as t
        from public.situations s
        join public.children c on c.id = s.child_id
        where c.follower_id = p_parent_id
          and s.status in ('candidate','confirmed')
          and public.hard_moment_label(s.key) is not null

        union all
        -- steps that actually worked for this child
        select d.step_given
        from public.daily_logs d
        where d.follower_id = p_parent_id
          and d.step_status = 'done'
          and nullif(btrim(d.step_given), '') is not null

        union all
        -- patterns, but only those explicitly cleared for the record
        select p.pattern_label
        from public.child_patterns p
        join public.children c2 on c2.id = p.child_id
        where c2.follower_id = p_parent_id
          and p.safe_for_record
          and nullif(btrim(p.pattern_label), '') is not null
      ) x where t is not null
    ), '[]'::jsonb)
  );
$function$;

comment on function public.family_tokens(uuid) is
  'The facts that make a message this family''s: identity (the child''s name, supplied) and measured (situations detected, steps that worked, patterns cleared for the record). Reads only what ADAM authored or measured — never chat history or disclosures (§2.8, provenance not content filtering).';


-- ------------------------------------------------------------
-- passes_uniqueness_test — §2.6, mechanised.
--
-- "Could this exact message be sent to a different family?"
--
-- Answered by asking whether the message contains anything only
-- true of this family. A proactive message must carry at least
-- one MEASURED token. The child's name is recorded when present
-- but does not on its own earn the right to interrupt.
--
-- Returns why, not just whether. A caller that gets `false` with
-- no reason logs a mystery.
-- ------------------------------------------------------------
create or replace function public.passes_uniqueness_test(
  p_parent_id uuid,
  p_body      text)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  v_tok      jsonb;
  v_body     text := coalesce(p_body, '');
  v_identity text[] := '{}';
  v_measured text[] := '{}';
begin
  v_tok := public.family_tokens(p_parent_id);

  select coalesce(array_agg(t), '{}')
    into v_identity
  from jsonb_array_elements_text(v_tok->'identity') as t
  where v_body like '%' || t || '%';

  select coalesce(array_agg(t), '{}')
    into v_measured
  from jsonb_array_elements_text(v_tok->'measured') as t
  where v_body like '%' || t || '%';

  if cardinality(v_measured) > 0 then
    return jsonb_build_object(
      'passes', true,
      'matched_measured', to_jsonb(v_measured),
      'matched_identity', to_jsonb(v_identity));
  end if;

  return jsonb_build_object(
    'passes', false,
    'reason', case
      when cardinality(v_identity) > 0
        then 'identity_only'   -- a tip with a name in it is still a tip
      else 'generic'
    end,
    'matched_identity', to_jsonb(v_identity),
    'available_measured', v_tok->'measured');
end;
$function$;

comment on function public.passes_uniqueness_test(uuid, text) is
  '§2.6: could this exact message be sent to a different family? A proactive message must contain at least one MEASURED token. reason=identity_only means the message is a generic tip with the child''s name substituted in — risk R2 — and does not send.';


-- ------------------------------------------------------------
-- knowledge_depth — §2.4, and the honest reason a journey
-- becomes possible only later.
--
-- Not a gate and not a trial expiring. ADAM genuinely could not
-- have named a real goal in week one. The constraint is real,
-- which is why it does not read as a tactic — and it is computed
-- here rather than asserted, so it stays real.
--
-- The parent never sees this and is never told what is locked
-- (§2.4). It exists so the composer knows what it may attempt.
-- ------------------------------------------------------------
create or replace function public.knowledge_depth(p_parent_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  v_name      text;
  v_situation boolean;
  v_nights    integer;
  v_outcomes  integer;
  v_level     smallint;
begin
  select nullif(btrim(c.name), '') into v_name
  from public.children c
  where c.follower_id = p_parent_id
    and btrim(coalesce(c.name,'')) not in ('الطفل','الطفلة')
  order by c.is_primary desc nulls last, c.created_at
  limit 1;

  select exists (
    select 1 from public.situations s
    join public.children c on c.id = s.child_id
    where c.follower_id = p_parent_id and s.status in ('candidate','confirmed')
  ) into v_situation;

  select count(*) filter (where d.night_result is not null),
         count(*) filter (where d.step_status is not null)
    into v_nights, v_outcomes
  from public.daily_logs d
  where d.follower_id = p_parent_id;

  v_level := case
    when v_outcomes >= 15 then 4   -- a month of outcomes
    when coalesce(v_nights,0) >= 3 then 3
    when v_situation      then 2
    when v_name is not null then 1
    else 0
  end;

  return jsonb_build_object(
    'level',  v_level,
    'child_name', v_name,
    'nights_with_result', coalesce(v_nights, 0),
    'outcomes', coalesce(v_outcomes, 0),
    'has_situation', v_situation,
    'now_possible', case v_level
      when 0 then jsonb_build_array('answer_this_moment')
      when 1 then jsonb_build_array('answer_this_moment','speak_by_name')
      when 2 then jsonb_build_array('answer_this_moment','speak_by_name','aim_a_seed')
      when 3 then jsonb_build_array('answer_this_moment','speak_by_name','aim_a_seed','notice_a_pattern')
      else        jsonb_build_array('answer_this_moment','speak_by_name','aim_a_seed','notice_a_pattern','name_a_goal')
    end);
end;
$function$;

comment on function public.knowledge_depth(uuid) is
  '§2.4: what is known, and what that makes possible. Level 4 (naming a goal worth pursuing) requires a month of outcomes. Computed rather than asserted, so the honest reason a journey becomes possible only later stays honest. The parent never sees this.';


-- ------------------------------------------------------------
-- can_send — §2.5's five rows, as one answer.
--
-- can_ground_seed() already covered the Seed. The other four
-- lived in whichever workflow remembered them, which is the same
-- shape of bug as five engines deciding when a parent has
-- recovered. One function, five kinds.
--
-- THE RESCUE IS UNCONDITIONAL and returns true before anything
-- else is read — no strain check, no knowledge check, no pause
-- check. Everything proactive earns the right to interrupt by
-- being specific; the rescue does not have to earn anything.
-- ------------------------------------------------------------
create or replace function public.can_send(
  p_kind      text,
  p_parent_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'pg_catalog','public'
as $function$
declare
  v_depth   jsonb;
  v_ground  jsonb;
  v_today   date;
  v_seed    timestamptz;
  v_harvest timestamptz;
  v_nights  integer;
  v_stage   record;
begin
  if p_kind = 'rescue' then
    return jsonb_build_object('kind','rescue','can_send',true,'reason','unconditional');
  end if;

  if p_kind not in ('seed','harvest','mirror','journey_step') then
    return jsonb_build_object('kind',p_kind,'can_send',false,'reason','unknown_kind');
  end if;

  select coalesce((now() at time zone ct.iana_tz)::date, current_date)
    into v_today
  from public.followers f
  left join public.country_timezone ct on ct.code = upper(btrim(f.country))
  where f.id = p_parent_id;
  v_today := coalesce(v_today, current_date);

  if p_kind = 'seed' then
    v_ground := public.can_ground_seed(p_parent_id);
    return jsonb_build_object(
      'kind','seed',
      'can_send', coalesce((v_ground->>'can_ground')::boolean, false),
      'reason', case when coalesce((v_ground->>'can_ground')::boolean, false)
                     then 'grounded' else 'missing_knowledge' end,
      'missing', v_ground->'missing',
      'basis',   v_ground->'basis');
  end if;

  if p_kind = 'harvest' then
    select d.seed_sent_at, d.harvest_sent_at into v_seed, v_harvest
    from public.daily_logs d
    where d.follower_id = p_parent_id and d.log_date = v_today;

    return jsonb_build_object(
      'kind','harvest',
      'can_send', v_seed is not null and v_harvest is null,
      'reason', case
        when v_seed is null      then 'no_seed_today'
        when v_harvest is not null then 'already_sent'
        else 'seed_exists' end);
  end if;

  if p_kind = 'mirror' then
    select count(*) filter (where d.night_result is not null) into v_nights
    from public.daily_logs d where d.follower_id = p_parent_id;
    return jsonb_build_object(
      'kind','mirror',
      'can_send', coalesce(v_nights,0) >= 3,
      'reason', case when coalesce(v_nights,0) >= 3 then 'enough_results'
                     else 'fewer_than_three_results' end,
      'nights_with_result', coalesce(v_nights,0));
  end if;

  -- journey_step: goal + progress + last outcome. Missing anything and
  -- the journey PAUSES and the parent is told plainly (§2.5) — it does
  -- not improvise a step from nothing.
  select s.id, s.objective_text into v_stage
  from public.stages s
  where s.parent_id = p_parent_id and s.status in ('active','extended')
  limit 1;

  if v_stage.id is null then
    return jsonb_build_object('kind','journey_step','can_send',false,'reason','no_live_journey');
  end if;

  v_depth := public.knowledge_depth(p_parent_id);
  return jsonb_build_object(
    'kind','journey_step',
    'can_send', (v_depth->>'outcomes')::integer > 0
            and coalesce(btrim(v_stage.objective_text),'') <> '',
    'reason', case
      when coalesce(btrim(v_stage.objective_text),'') = '' then 'no_objective'
      when (v_depth->>'outcomes')::integer = 0 then 'no_outcome_yet'
      else 'ready' end);
end;
$function$;

comment on function public.can_send(text, uuid) is
  '§2.5''s send gate, all five kinds in one answer. The rescue is unconditional and returns before anything else is read. Everything proactive earns the right to interrupt by being specific.';


revoke all on function public.family_tokens(uuid)                    from anon, authenticated, public;
revoke all on function public.passes_uniqueness_test(uuid, text)     from anon, authenticated, public;
revoke all on function public.knowledge_depth(uuid)                  from anon, authenticated, public;
revoke all on function public.can_send(text, uuid)                   from anon, authenticated, public;

grant execute on function public.family_tokens(uuid)                 to service_role;
grant execute on function public.passes_uniqueness_test(uuid, text)  to service_role;
grant execute on function public.knowledge_depth(uuid)               to service_role;
grant execute on function public.can_send(text, uuid)                to service_role;

commit;
