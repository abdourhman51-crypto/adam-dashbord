-- ============================================================
-- set_checkin_hour writes 'daily' — checkin_state.cadence allows
-- only 'nightly', 'weekly', 'stopped'. Found by a repo↔production
-- drift audit (2026-08-11), not by a report: production has always
-- held the correct 'nightly' and was never at risk. The bug lives
-- only in this repo's copy of the function, introduced somewhere
-- between the version that actually ran against production and the
-- version currently checked in — this migration was hand-verified
-- against the live source, not guessed.
--
-- Nothing in production changes. This exists so a REBUILD from this
-- repository stays honest: `select set_checkin_hour(p, 20)` on a
-- freshly rebuilt database throws `checkin_state_cadence_check`
-- immediately, for every parent, on the exact three settings buttons
-- (menu_settings_hour_morning/evening/night) that call it.
--
-- The only test that touched this function checked that it EXISTS
-- (`to_regprocedure(...) is not null`) and never called it — which is
-- exactly how a CHECK-constraint violation on every real call survived
-- every offline suite. checkin_hour_test.sql (new) calls it for real.
-- ============================================================

begin;

create or replace function public.set_checkin_hour(p_parent_id uuid, p_hour smallint)
returns boolean
language plpgsql
volatile
security definer
set search_path to 'pg_catalog','public'
as $function$
begin
  if p_hour is null or p_hour < 0 or p_hour > 23 then
    return false;
  end if;
  insert into public.checkin_state (parent_id, local_hour, cadence)
  values (p_parent_id, p_hour, 'nightly')
  on conflict (parent_id) do update
    set local_hour = excluded.local_hour, updated_at = now();
  return true;
end;
$function$;

comment on function public.set_checkin_hour(uuid, smallint) is
  'Writes the parent''s chosen evening hour (menu_settings_hour_*). cadence is set to ''nightly'' — the only value checkin_state_cadence_check allows besides ''weekly''/''stopped''. A prior repo-only copy of this function wrote ''daily'', which the constraint has never permitted; production was never exposed to it.';

commit;
