-- record_winback_sent was UPDATE-only, so it silently no-op'd for every parent
-- who had never had a checkin_state row -- exactly the population a manual
-- win-back campaign targets (dormant enough to have no nightly rhythm state
-- at all). Found by sending a 20-family recovery broadcast and then finding
-- zero rows with winback_sent_at set afterwards.
--
-- The insert deliberately pins cadence = 'stopped' rather than leaving the
-- column default ('nightly'): a manual win-back send must not silently
-- enroll a never-engaged parent into the automatic nightly check-in rhythm.
-- On conflict, cadence is left untouched -- only winback_sent_at moves, same
-- as before -- so an existing rhythm participant's cadence is never touched
-- by this function.

create or replace function public.record_winback_sent(p_parent_id uuid)
returns void
language sql
set search_path to 'pg_catalog', 'public'
as $function$
  insert into public.checkin_state (parent_id, cadence, winback_sent_at, updated_at)
  values (p_parent_id, 'stopped', now(), now())
  on conflict (parent_id) do update
    set winback_sent_at = now(), updated_at = now();
$function$;
