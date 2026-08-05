-- Nobody grants themselves a journey
--
-- Found on 2026-08-07 while proving the repo could rebuild production. Week 0
-- (20260729124500) revoked EXECUTE from anon and authenticated on every
-- SECURITY DEFINER function that touches a parent. Checking those grants against
-- production today, four were open again — or had never closed:
--
--   activate_subscription(uuid,int,numeric,text,text,text,text,int,int,int)
--       GRANTS PAID ACCESS and starts a journey. Callable by anyone holding the
--       public anon key, for any follower id.
--   get_conversation_for(text)
--       Returns a parent's entire conversation history, by Telegram id.
--   heart_commit(text, jsonb)
--       Overwrites the free tier's memory of any family.
--   write_child_name(text, text)
--       Writes a child's name for any parent.
--
-- Two separate causes, and both are worth naming because neither was a typo in
-- the security model — they were both side effects of ordinary work:
--
--   1. The ten-argument activate_subscription is an OVERLOAD, created by
--      20260807090000 when the journey engine gained its start parameters. A new
--      function is born with EXECUTE granted to PUBLIC. Week 0 had revoked the
--      five-argument one by exact signature, and an exact signature does not
--      cover an overload. My own migration reopened the hole week 0 closed.
--
--   2. Week 0 wrote `REVOKE ... ON FUNCTION public.get_heart_batch()`. That
--      function takes `p_limit integer default 40`, so the signature matched
--      nothing, the statement raised, and the two REVOKEs written after it —
--      heart_commit and write_child_name — never ran. One wrong signature
--      silently cancelled the rest of the list. That file is now a guarded loop
--      so it cannot happen again.
--
-- A third thing, found while verifying the fix on a bare cluster: REVOKE ...
-- FROM anon does NOT remove a privilege anon holds through PUBLIC. Postgres
-- grants EXECUTE on every new function to PUBLIC, and Supabase happens to
-- revoke that and grant anon explicitly instead — so week 0's revoke worked
-- there and would have been a no-op anywhere else. Every revoke below names
-- PUBLIC as well, so the intent survives outside this one platform's defaults.
--
-- Nothing in the product loses access: n8n authenticates as service_role, which
-- is granted separately and explicitly below. This only closes the public door.

begin;

do $revoke$
declare f text;
begin
  foreach f in array array[
    -- Every overload of activate_subscription, present and future, by name
    -- rather than by signature. This is the lesson of cause (1): revoking a
    -- signature protects one function, not one capability.
    'public.return_to_free(uuid)',
    'public.check_daily_message_cap(uuid)',
    'public.get_conversation_for(text)',
    'public.get_free_session_state(text, numeric)',
    'public.get_heart_batch(integer)',
    'public.heart_commit(text, jsonb)',
    'public.write_child_name(text, text)',
    'public.commit_child_name_by_platform(text, text, text, text)',
    'public.writer_commit(uuid, integer, jsonb)',
    'public.get_child_record(uuid, text)',
    'public.request_erasure(uuid)',
    'public.execute_erasure(uuid)',
    'public.set_pattern_record_visibility(uuid, boolean, text, text)'
  ] loop
    if to_regprocedure(f) is not null then
      execute 'revoke execute on function ' || f || ' from public, anon, authenticated';
    end if;
  end loop;
end $revoke$;

-- By name, so every current and future overload is covered.
do $revoke$
declare r record;
begin
  for r in
    select p.oid::regprocedure::text as sig
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in ('activate_subscription', 'start_stage', 'close_stage')
  loop
    execute 'revoke execute on function ' || r.sig || ' from public, anon, authenticated';
  end loop;
end $revoke$;

-- The default that caused (1). Without this, the NEXT function anyone adds is
-- born callable by the public key, and closing it depends on somebody
-- remembering. Applies to functions created from here on by the same role.
alter default privileges in schema public revoke execute on functions from public;
alter default privileges in schema public revoke execute on functions from anon, authenticated;

-- n8n and the dashboard authenticate as service_role. Restated so this file
-- cannot be read as "revoke everything" and reverted in a panic.
grant execute on all functions in schema public to service_role;

commit;
