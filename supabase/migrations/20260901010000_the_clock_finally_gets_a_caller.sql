-- ============================================================
-- The clock finally gets a caller.
--
-- Simulated a complete 29-day paid journey end to end (fresh follower →
-- agreement → activate_subscription → 29 days of daily_logs → clock
-- exhausted). close_stage() itself works correctly — tested it directly:
-- objective met → 'completed'; not met → the unrequested half-length
-- extension; extended and still not met → 'failed'. But nothing in
-- production ever calls it: not one of the 5 live n8n workflows, not the
-- dashboard, not the mini app. A stage whose clock runs out just sits in
-- status='active' forever — clock_exhausted=true, nobody told, no
-- extension ever actually granted, and start_stage's one-live-journey
-- rule then blocks that parent from ever starting a new one. The core
-- guarantee this whole engine exists for («وإن لم نصل إليه، أُكمل معكم
-- نصف المدة إضافية مجاناً») was structurally unable to fire.
--
-- Second, smaller bug found in the same pass: close_stage_report() always
-- opens with "لم نصل بعد بشكل كامل" — it was written only for the
-- not-fully-met case. But the simulation showed the objective is usually
-- met BEFORE the clock exhausts (the "hold" phase's whole purpose is to
-- sustain an already-met goal through the end of the window), so
-- "clock exhausted AND objective_met" is the COMMON case, not the rare
-- one — and it was being told "you haven't gotten there yet" on the day
-- they succeeded. close_stage_success_report is the missing celebratory
-- twin, reusing the same evidence gathering, for exactly that case.
--
-- This migration adds only the read-side pieces a scheduler needs:
--   stages_due_for_close()       which live stages actually need closing
--   close_stage_success_report() the congratulatory twin of the existing
--                                 close_stage_report, for objective_met
-- close_stage() itself is untouched. The n8n workflow that calls these
-- ("ADAM · Stage Clock", daily) is built and wired separately.
-- ============================================================

begin;

-- ------------------------------------------------------------
-- stages_due_for_close — every live stage whose clock has run out,
-- with just enough to let a scheduler decide which report to compose
-- before calling close_stage (which then flips the status).
-- ------------------------------------------------------------
create or replace function public.stages_due_for_close()
returns table(
  stage_id uuid,
  parent_id uuid,
  platform_user_id text,
  objective_met boolean
)
language sql
stable
security definer
set search_path to 'pg_catalog', 'public'
as $function$
  select v.stage_id, v.parent_id, f.platform_user_id, v.objective_met
  from public.v_stage_progress v
  join public.followers f on f.id = v.parent_id
  where v.status in ('active', 'extended')
    and v.clock_exhausted;
$function$;

comment on function public.stages_due_for_close() is
  'Every live stage (active/extended) whose clock has already run out — the set a daily scheduler must call close_stage() on. objective_met tells the caller which report to compose (close_stage_success_report vs close_stage_report) BEFORE calling close_stage, since both report functions read the stage while it is still active/extended.';


-- ------------------------------------------------------------
-- close_stage_success_report — the congratulatory twin.
--
-- Same evidence, same honesty rule (never invent a number), different
-- frame: this is the day they got there. Ends by inviting the next goal,
-- not a renewal pitch — the parent stays a companionship member either
-- way (funnel_stage is untouched by close_stage), so there is no sale
-- to make here, only the next agreement to offer.
-- ------------------------------------------------------------
create or replace function public.close_stage_success_report(p_parent_id uuid)
returns text
language plpgsql
stable
security definer
set search_path to 'pg_catalog', 'public'
as $function$
declare
  v_nl text := chr(10);
  v_child text; v_objective text;
  v_child_id uuid; v_started date; v_days int;
  v_nights int; v_calm int;
  v_calms text;
  v_sits text[];
  v_lines text[] := '{}';
  v_held_total int;
begin
  select s.child_id, s.objective_text, s.started_at::date
    into v_child_id, v_objective, v_started
  from public.stages s
  where s.parent_id = p_parent_id and s.status in ('active','extended')
  order by s.started_at desc limit 1;

  select nullif(btrim(c.name),'') into v_child
  from public.children c where c.id = v_child_id;
  v_child := coalesce(v_child, 'طفلكم');
  v_days := greatest(1, (current_date - coalesce(v_started, current_date)));

  select count(*) filter (where d.night_result is not null),
         count(*) filter (where d.night_result = 'calm')
    into v_nights, v_calm
  from public.daily_logs d where d.follower_id = p_parent_id;

  select count(*) into v_held_total
  from public.parent_moments where parent_id = p_parent_id and kind = 'held';

  select array_agg(distinct public.situation_label_ar(s.key))
    into v_sits
  from public.situations s
  where s.child_id = v_child_id and s.status = 'confirmed';

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

  v_lines := array['🎉 وصلتم.'];
  v_lines := v_lines || ''::text;
  v_lines := v_lines || ('الهدف اللي اتّفقنا عليه: ' || coalesce(v_objective,'') || '.')::text;
  v_lines := v_lines || ('وتحقّق — بأرقامكم أنتم، لا بكلامي.')::text;

  v_lines := v_lines || ''::text;
  v_lines := v_lines || '📊 بالأرقام'::text;
  v_lines := v_lines || ('• ' || public.ar_digits(v_days::text) || ' يوماً معاً، من ' || to_char(coalesce(v_started, current_date), 'DD/MM') || ' إلى اليوم.')::text;
  if v_held_total > 0 then
    v_lines := v_lines || ('• ' || public.ar_digits(v_held_total::text) || ' مرة أوشكتم فيها ولم تنفجروا.')::text;
  end if;
  v_lines := v_lines || ('• ' || public.ar_digits(coalesce(v_nights,0)::text) || ' ليلة سجّلتموها مع ' || v_child || '، '
                          || public.ar_digits(coalesce(v_calm,0)::text) || ' منها مرّت بهدوء.')::text;

  if v_calms is not null then
    v_lines := v_lines || ''::text;
    v_lines := v_lines || '✅ ما نجح معكم فعلاً'::text;
    v_lines := v_lines || v_calms;
  end if;

  if v_sits is not null and array_length(v_sits,1) > 0 then
    v_lines := v_lines || ''::text;
    v_lines := v_lines || ('🔍 اللحظة اللي عرفنا مصدرها بالضبط: ' || array_to_string(v_sits, '، ') || '.')::text;
  end if;

  v_lines := v_lines || ''::text;
  v_lines := v_lines || 'آدم كان معكم كل يوم، لكن اللي تحقق فعلياً هو اجتهادكم أنتم وحدكم.'::text;
  v_lines := v_lines || ''::text;
  v_lines := v_lines || 'ولا شيء يمنعنا نتّفق الآن على هدف جديد — أنتم من يقرّر متى وعلى ماذا.'::text;

  return array_to_string(v_lines, v_nl);
end;
$function$;

comment on function public.close_stage_success_report(uuid) is
  'The congratulatory twin of close_stage_report, for the common case the latter mishandled: clock exhausted AND objective_met=true (the expected outcome of the hold phase). Same evidence, same no-invention rule; ends by inviting the next agreement instead of a renewal pitch, since funnel_stage is untouched by close_stage — there is no sale to make here.';

revoke all on function public.stages_due_for_close() from anon, authenticated, public;
revoke all on function public.close_stage_success_report(uuid) from anon, authenticated, public;
grant execute on function public.stages_due_for_close() to service_role;
grant execute on function public.close_stage_success_report(uuid) to service_role;

commit;
