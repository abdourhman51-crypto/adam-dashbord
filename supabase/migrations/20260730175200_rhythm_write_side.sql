-- Write side of the rhythm. Sending and recording happen in one
-- transaction: their separation is what left 23 of 25 days with no result.
-- Full bodies applied via Supabase migration `rhythm_write_side`.
-- record_seed_sent      : the only sanctioned way a Seed becomes a fact.
--                         Rejects an ungrounded Seed (P11) and logs A1/A2.
-- record_harvest_sent   : returns false rather than raising, so an hourly
--                         trigger firing twice cannot double-send.
-- record_harvest_answer : the parent's tap. Refuses when no Seed went out
--                         that day, and resets the consent-decay counter.

-- ------------------------------------------------------------
-- RESTORED 2026-08-07 from production via pg_get_functiondef.
-- This file was nine lines of comment and no SQL. See the note in
-- 20260730180000_situation_catalog_and_detection.sql.
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.record_harvest_answer(p_parent_id uuid, p_outcome text, p_hard_moment text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_day  public.daily_logs%rowtype;
  v_tz   text;
  v_date date;
begin
  select ct.iana_tz into v_tz
  from public.followers f
  join public.country_timezone ct on upper(btrim(f.country)) = ct.code
  where f.id = p_parent_id;

  v_date := (now() at time zone coalesce(v_tz, 'UTC'))::date;

  update public.daily_logs
     set step_status = case p_outcome
                         when 'succeeded'    then 'done'
                         when 'tried_failed' then 'tried_failed'
                         when 'no_chance'    then 'not_tried' end,
         night_result = case p_outcome
                         when 'succeeded' then 'calm'
                         when 'tried_failed' then 'hard'
                         else night_result end,
         hard_moment  = coalesce(p_hard_moment, hard_moment),
         harvest_answered_at = now(),
         updated_at = now()
   where follower_id = p_parent_id
     and log_date = v_date
     and seed_sent_at is not null
  returning * into v_day;

  if v_day.id is null then
    return jsonb_build_object('recorded', false, 'reason', 'no_seed_today');
  end if;

  -- Any reply restores the rhythm: engagement resets the decay counter.
  update public.checkin_state
     set consecutive_ignored = 0, last_responded_at = now(), updated_at = now()
   where parent_id = p_parent_id;

  return jsonb_build_object('recorded', true, 'day_id', v_day.id, 'local_date', v_date);
end;
$function$;

CREATE OR REPLACE FUNCTION public.record_harvest_sent(p_day_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare v_ok boolean; v_parent uuid;
begin
  update public.daily_logs
     set harvest_sent_at = now(), updated_at = now()
   where id = p_day_id
     and seed_sent_at is not null
     and harvest_sent_at is null
  returning true, follower_id into v_ok, v_parent;

  if coalesce(v_ok, false) then
    update public.followers
       set proactive_footer_at = coalesce(proactive_footer_at, now())
     where id = v_parent;
  end if;

  return coalesce(v_ok, false);
end;
$function$;

revoke all on function public.record_harvest_answer(uuid, text, text) from anon, authenticated, public;
revoke all on function public.record_harvest_sent(uuid)               from anon, authenticated, public;
grant execute on function public.record_harvest_answer(uuid, text, text) to service_role;
grant execute on function public.record_harvest_sent(uuid)               to service_role;
