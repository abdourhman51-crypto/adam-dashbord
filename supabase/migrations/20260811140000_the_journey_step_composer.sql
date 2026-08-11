-- ============================================================
-- compose_journey_step — the daily plan, grown one day at a time.
-- Design: docs/the-conversion-seam.md step 5 · §10 of adam-system.md
--
-- There are no fixed plans in this product — no «حزمة النوم». Each
-- family's plan is generated every day from their own child's evidence,
-- bounded by the goal they agreed and shaped by where they are in the
-- journey. This function is the engine of that: it does for the paid
-- daily step exactly what get_harvest_context does for the evening
-- reply — it assembles FACTS and a POSTURE, and the composer (the LLM,
-- at send time) writes the language. It never invents copy itself, and
-- it never sends.
--
-- ------------------------------------------------------------
-- The posture is the phase, and the phase is what makes it a plan
--
-- v_stage_progress derives observe → build → hold from logged days.
-- Each phase changes what tonight's step IS, which is the difference
-- between a journey and a stream of tips:
--
--   observe — change NOTHING. Watch the situation, learn the real
--             trigger. A step here would be guessing before we know.
--   build   — one small step a day, each built on what worked
--             yesterday for THIS child. Small enough for the worst night.
--   hold     — ADAM fades on purpose. No step; only the evening
--             question. The calm must be shown to belong to the family,
--             not to ADAM. Nothing may shorten this phase.
--
-- So two families who both said «النوم» get different steps every night:
-- their children differ, and last night differed. The personalisation
-- is not a feature bolted on — it is what you get once the step reads
-- the child instead of a template.
--
-- ------------------------------------------------------------
-- What it does NOT do
--
-- It does not compose the final sentence (the LLM does, under the
-- send-time copy law and the uniqueness test). It does not decide WHEN
-- to send (get_rhythm_due does, in the next reviewed step). It does not
-- touch any workflow, and it turns no engine on. It is a pure read.
-- ============================================================

begin;

create or replace function public.compose_journey_step(p_parent_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'pg_catalog','public'
as $function$
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
  v_nl text := chr(10);
begin
  -- No live journey → nothing to compose. Most parents.
  v_stage := public.stage_state(p_parent_id);
  if not coalesce((v_stage->>'in_stage')::boolean, false) then
    return jsonb_build_object('in_journey', false);
  end if;

  -- The send gate (§2.5) owns readiness: a live journey, an objective,
  -- and at least one outcome to build on. Carried through so the caller
  -- can refuse without re-deriving the rule.
  v_gate  := public.can_send('journey_step', p_parent_id);
  v_phase := v_stage->>'phase';

  select nullif(btrim(c.name), '') into v_child
  from public.children c where c.follower_id = p_parent_id
  order by c.is_primary desc nulls last, c.created_at limit 1;

  v_sit := public.hard_moment_label(v_stage->>'problem_key');

  -- Last night on record: what was tried, and whether it landed.
  select d.night_result, d.step_given, d.step_status
    into v_last_result, v_last_step, v_last_status
  from public.daily_logs d
  where d.follower_id = p_parent_id and d.night_result is not null
  order by d.log_date desc limit 1;

  -- The most recent step that actually worked, for `build` to lean on.
  select nullif(btrim(d.step_given), '') into v_working
  from public.daily_logs d
  where d.follower_id = p_parent_id
    and nullif(btrim(d.step_given), '') is not null
    and (d.step_status = 'done' or d.night_result = 'calm')
  order by d.log_date desc limit 1;

  -- Recent steps, so the composer does not repeat one.
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

  -- The posture. This is guidance for the composer, never sent as-is.
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

  return jsonb_build_object(
    'in_journey',        true,
    'can_send',          coalesce((v_gate->>'can_send')::boolean, false),
    'reason',            v_gate->>'reason',
    'phase',             v_phase,
    'phase_ar',          v_stage->>'phase_ar',
    'phase_directive',   v_directive,
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

comment on function public.compose_journey_step(uuid) is
  'The daily plan, one day at a time: facts + posture for the composer to write tonight''s single step, never fixed copy and never sent here. The phase (observe/build/hold, derived in v_stage_progress) decides what the step IS — observe changes nothing, build leans on what worked yesterday for this child, hold fades ADAM out. Returns in_journey=false for a parent with no live stage, and carries can_send(''journey_step'') so the caller refuses when there is no outcome yet.';

revoke all on function public.compose_journey_step(uuid) from anon, authenticated, public;
grant execute on function public.compose_journey_step(uuid) to service_role;

commit;
