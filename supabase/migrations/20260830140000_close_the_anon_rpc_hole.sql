begin;

-- ============================================================
-- CRITICAL: the public REST API could grant itself a subscription.
--
-- WHAT WAS WRONG
--
-- 37 SECURITY DEFINER functions in `public` were EXECUTE-able by
-- the `anon` role. Supabase exposes every such function at
-- /rest/v1/rpc/<name>, and the anon key is public by design — it
-- ships in client bundles and is printed in the dashboard. So any
-- person on the internet holding that key could call, among others:
--
--   activate_subscription(follower_id, amount, ...)  → free paid access
--   deactivate_subscription(follower_id, ...)        → cancel anyone
--   start_stage / renew_stage_same_objective         → write journeys
--   record_chat_step / commit_chat_step              → write to any parent
--   get_heart_batch / get_strain_batch / get_rhythm_due
--       → these RETURN BATCHES OF PARENT ROWS INCLUDING CONVERSATION
--         TEXT. This is the data-exposure half, and it is worse than
--         the write half.
--
-- SECURITY DEFINER means the function runs as its owner and bypasses
-- RLS entirely, so the Week-0 policy cleanup did not cover this: the
-- policies were fixed, the function EXECUTE grants never were.
--
-- WHY REVOKING IS SAFE HERE
--
-- Every legitimate caller uses the service_role key: n8n workflows,
-- the mini app's route handlers (lib/supabase/admin.ts), and the
-- dashboard's data reads. The anon key appears in exactly one place
-- in the whole repo — dashboard/lib/supabase/session.ts — and is
-- used only for Auth (signInWithPassword / getUser / refreshSession),
-- never for RPC. Nothing legitimate loses access.
--
-- HOW
--
-- Done as a loop over pg_proc rather than a hand-written list, so a
-- function added later without an explicit REVOKE is still caught the
-- next time this runs — a hand-maintained list is how this drifted in
-- the first place.
-- ============================================================


-- ------------------------------------------------------------
-- A test bypass function must never exist in production.
-- Its name says what it does: it skips a guard.
-- ------------------------------------------------------------
drop function if exists public._test_reflection_bypass(uuid);


-- ------------------------------------------------------------
-- Revoke EXECUTE from every public-facing role on every
-- SECURITY DEFINER function in `public`, then hand it back to
-- service_role alone.
--
-- PUBLIC is revoked as well, because a grant to PUBLIC is
-- inherited by anon and authenticated and would silently undo
-- the two explicit revokes below it.
-- ------------------------------------------------------------
do $$
declare
  f record;
  n integer := 0;
begin
  for f in
    select p.oid::regprocedure as sig
    from pg_proc p
    join pg_namespace ns on ns.oid = p.pronamespace
    where ns.nspname = 'public'
      and p.prosecdef                      -- SECURITY DEFINER only
      and p.prokind = 'f'
  loop
    execute format('revoke all on function %s from public', f.sig);
    execute format('revoke all on function %s from anon', f.sig);
    execute format('revoke all on function %s from authenticated', f.sig);
    execute format('grant execute on function %s to service_role', f.sig);
    n := n + 1;
  end loop;

  raise notice 'locked % SECURITY DEFINER functions to service_role', n;
end $$;


-- ------------------------------------------------------------
-- A mutable search_path on a SECURITY DEFINER function lets a
-- caller who can create objects shadow a referenced table or
-- function and have it run with the owner's rights. Pinning it
-- is the standard remedy and changes no behaviour.
-- ------------------------------------------------------------
do $$
declare f record;
begin
  for f in
    select p.oid::regprocedure as sig
    from pg_proc p
    join pg_namespace ns on ns.oid = p.pronamespace
    where ns.nspname = 'public'
      and p.prokind = 'f'
      and p.prosecdef
      and not exists (
        select 1 from unnest(coalesce(p.proconfig, '{}')) c
        where c like 'search_path=%')
  loop
    execute format('alter function %s set search_path to ''pg_catalog'', ''public''', f.sig);
  end loop;
end $$;

commit;
