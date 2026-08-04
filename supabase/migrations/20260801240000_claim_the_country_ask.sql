begin;

-- ============================================================
-- One call, or the question asks itself twice.
--
-- The sender needs three things to append the country question:
-- whether to ask, the sentence, and the buttons. Three calls
-- means three chances for the workflow to ask, crash, retry, and
-- ask again — and "once, ever" is the entire promise of this
-- moment. n8n retries. It has retried on this exact path before.
--
-- take_country_ask CLAIMS the question. The stamp lands before
-- the text is returned, and record_country_ask's
--
--     where id = ... and country_asked_at is null
--
-- means exactly one caller can ever win. A second call — retry,
-- duplicate webhook, two workers — gets ask:false and sends
-- nothing.
--
-- WHAT THIS TRADES AWAY, DELIBERATELY
--
-- If Telegram then fails to deliver, the question is spent and
-- that parent is never asked again. That is the correct side to
-- fail on: the alternative is a family being asked where they
-- live twice by something that claims to remember them, which is
-- the brand's own accusation against itself. And it is not a dead
-- end — /journey still asks, on demand, forever.
-- ============================================================

create or replace function public.take_country_ask(p_parent_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'pg_catalog','public'
as $function$
declare v_m jsonb;
begin
  if not public.should_ask_country(p_parent_id) then
    return jsonb_build_object('ask', false, 'reason', 'not_due');
  end if;

  -- The claim. Loser of a race gets false and stays silent.
  if not public.record_country_ask(p_parent_id) then
    return jsonb_build_object('ask', false, 'reason', 'already_claimed');
  end if;

  v_m := public.get_conversation_moment('country_ask_footer', p_parent_id);

  -- If the moment ever goes missing, the stamp is already spent and we
  -- say nothing rather than sending half a question. Losing one ask is
  -- recoverable; a parent receiving buttons with no sentence is not.
  if not coalesce((v_m->>'found')::boolean, false) then
    return jsonb_build_object('ask', false, 'reason', 'moment_missing');
  end if;

  return jsonb_build_object(
    'ask', true,
    'body', v_m->>'body',
    'buttons', coalesce(v_m->'buttons', '[]'::jsonb));
end;
$function$;

comment on function public.take_country_ask(uuid) is
  'Claims the one country question for a parent and returns it, or returns ask:false. Atomic by way of the null check in record_country_ask, so a retried workflow cannot ask twice. Fails toward silence: a spent stamp with no send costs one ask, and /journey still asks on demand.';

revoke all on function public.take_country_ask(uuid) from anon, authenticated, public;
grant execute on function public.take_country_ask(uuid) to service_role;

commit;
