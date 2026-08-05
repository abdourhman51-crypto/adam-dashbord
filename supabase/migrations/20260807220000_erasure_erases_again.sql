-- Erasure erases again
--
-- MY REGRESSION, same day, and the worst possible one to introduce.
--
-- 20260807200000 dropped `session_tracker`. `execute_erasure` still deleted from
-- it, so from that moment every erasure raised:
--
--     ERROR: relation "public.session_tracker" does not exist
--     CONTEXT: PL/pgSQL function execute_erasure(uuid) line 15
--
-- A parent taps «نعم، امحوا كل شيء», and nothing is erased. The promise the
-- product makes about privacy — «تطلبون محوه فيُمحى كلّه» — was the one thing
-- broken by a cleanup whose whole purpose was tidiness.
--
-- The founder found it by using the product. The offline suite did not, because
-- nothing tested the tap that triggers it: `erasure_test` covered
-- `request_erasure` and `execute_erasure` directly, never
-- `get_moment_after_tap('menu_privacy_erased', …)` — the only path a parent can
-- actually reach. A function tested only where nobody calls it is tested in the
-- wrong place. `privacy_erasure_test.sql` now walks the tap.
--
-- The check that would have caught this is cheap and is now part of the routine:
-- after dropping anything, grep every remaining function body for its name.
-- Running it afterwards found exactly one hit — this one.

begin;

create or replace function public.execute_erasure(p_request_id uuid)
returns jsonb
language plpgsql
set search_path to 'pg_catalog', 'public'
as $fn$
declare
  v_parent uuid; v_pid text; v_status text;
  v_chat int; v_surv int; v_pay int;
begin
  select parent_id, platform_user_id, status
    into v_parent, v_pid, v_status
    from public.erasure_requests where id = p_request_id;

  if v_parent is null then raise exception 'unknown erasure request %', p_request_id; end if;
  if v_status <> 'requested' then raise exception 'erasure % already %', p_request_id, v_status; end if;

  -- Conversations are keyed by session_id, not by a foreign key, so they must
  -- be removed explicitly and via the normalised key or drifted rows survive.
  delete from public.n8n_chat_histories
   where public.normalise_session_key(session_id) = v_pid;
  get diagnostics v_chat = row_count;

  -- session_tracker was deleted here. The table went with the old session
  -- model in 20260807200000; there is nothing left to clear.

  delete from public.survey_responses where platform_user_id = v_pid;
  get diagnostics v_surv = row_count;

  -- Payments are retained but de-identified: financial records must survive,
  -- the link to a person must not.
  update public.payments set follower_id = null, notes = '[erased]'
   where follower_id = v_parent;
  get diagnostics v_pay = row_count;

  -- Cascades clear children, daily_logs, stages, crisis_flags, patterns,
  -- memory events, situations, checkin_state and record requests.
  delete from public.followers where id = v_parent;

  update public.erasure_requests
     set status = 'completed', completed_at = now(),
         notes = format('chat=%s surveys=%s payments_anonymised=%s',
                        v_chat, v_surv, v_pay)
   where id = p_request_id;

  return jsonb_build_object('erased', true, 'chat_rows', v_chat,
                            'surveys', v_surv, 'payments_anonymised', v_pay);
end $fn$;

commit;
