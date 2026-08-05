-- Strain detection and graded return (AD-2).
-- Applied via Supabase migration `strain_detection_and_graded_return`.
--
-- This closes a live safety gap: get_rhythm_due() already refused to send
-- at strain level > 1, but nothing in the system ever wrote level 2 or 3,
-- so the guardrail was declared and inert. A parent disclosing violence at
-- night would have received a cheerful Seed the next morning.
--
-- set_strain_level(parent_id, level, reason)
--   Escalation is IMMEDIATE. Recovery is GRADED: one level at a time, and
--   never before return_eligible_at. The asymmetry is the design — a parent
--   in danger cannot wait for a cooling period, and "they seem fine now" is
--   not a judgement a scheduler should be trusted to make.
--   L3 holds 7 days before it may step to L2. L2 holds 3 days before L1.
--
-- commerce_allowed(parent_id)
--   The single answer to "may anything commercial reach this parent right
--   now?". Blocks at L2/L3 and for 14 days after any crisis flag. One
--   function, so five engines cannot each reach a different conclusion.
--   Defaults true where no strain record exists: absence of strain is not
--   strain.
--
-- get_strain_batch(limit)
--   Recent conversation, oldest-assessed first. Batch rather than realtime
--   is acceptable because the Seed only sends in a morning window and this
--   runs every 2h, so a night disclosure is caught before it.

-- ------------------------------------------------------------
-- RESTORED 2026-08-07 from production via pg_get_functiondef.
-- This file was twenty-six lines of comment and no SQL. See the
-- note in 20260730180000_situation_catalog_and_detection.sql.
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.set_strain_level(p_parent_id uuid, p_level smallint, p_reason text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_cur    smallint;
  v_elig   timestamptz;
  v_new    smallint;
  v_action text;
begin
  if p_level not in (1,2,3) then
    return jsonb_build_object('ok', false, 'reason', 'invalid_level');
  end if;

  select level, return_eligible_at into v_cur, v_elig
  from public.parent_strain where parent_id = p_parent_id;

  if v_cur is null then
    v_cur := 1;
    insert into public.parent_strain(parent_id, level) values (p_parent_id, 1)
      on conflict (parent_id) do nothing;
  end if;

  if p_level > v_cur then
    -- ESCALATE: immediate, no waiting.
    v_new := p_level;
    v_action := 'escalated';
  elsif p_level < v_cur then
    -- DE-ESCALATE: only when eligible, and only one step.
    if v_elig is not null and now() < v_elig then
      return jsonb_build_object(
        'ok', true, 'action', 'held', 'level', v_cur,
        'return_eligible_at', v_elig,
        'note', 'recovery window not yet elapsed');
    end if;
    v_new := v_cur - 1;
    v_action := case when v_new < v_cur - 1 then 'stepped' else 'stepped_down' end;
  else
    v_new := v_cur;
    v_action := 'unchanged';
  end if;

  update public.parent_strain
     set level  = v_new,
         reason = coalesce(p_reason, reason),
         entered_at = case when v_new <> v_cur then now() else entered_at end,
         -- L3 holds for 7 days before it may step to L2.
         -- L2 holds for 3 days before it may step to L1.
         return_eligible_at = case
           when v_new = 3 then now() + interval '7 days'
           when v_new = 2 then now() + interval '3 days'
           else null end,
         updated_at = now()
   where parent_id = p_parent_id;

  return jsonb_build_object(
    'ok', true, 'action', v_action, 'from', v_cur, 'level', v_new,
    'return_eligible_at', case when v_new = 3 then now() + interval '7 days'
                               when v_new = 2 then now() + interval '3 days'
                               else null end);
end;
$function$;

CREATE OR REPLACE FUNCTION public.get_strain_batch(p_limit integer DEFAULT 30)
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
       chr(10) order by h.id desc)
   from (select * from public.n8n_chat_histories hh
         where hh.session_id = f.platform_user_id
         order by hh.id desc limit 12) h)
from public.followers f
left join public.parent_strain ps on ps.parent_id = f.id
where exists (
  select 1 from public.n8n_chat_histories h2
  where h2.session_id = f.platform_user_id
    and h2.id > coalesce((
      select max(h3.id) - 200 from public.n8n_chat_histories h3), 0))
order by coalesce(ps.updated_at, 'epoch'::timestamptz)
limit p_limit;
$function$;

revoke all on function public.set_strain_level(uuid, smallint, text) from anon, authenticated, public;
revoke all on function public.get_strain_batch(integer)              from anon, authenticated, public;
grant execute on function public.set_strain_level(uuid, smallint, text) to service_role;
grant execute on function public.get_strain_batch(integer)              to service_role;
