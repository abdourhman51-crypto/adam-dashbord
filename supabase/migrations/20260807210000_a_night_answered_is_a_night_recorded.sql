-- A night answered is a night recorded
--
-- Found on 2026-08-07 while checking, at the founder's request, whether
-- `/progress` is a real feature or just a button. It is real. But proving it
-- turned up this:
--
--     select record_harvest_answer(parent, 'calm');
--     -> {"recorded": true, "day_id": "...", "local_date": "2026-08-05"}
--
--     select night_result, step_status from daily_logs where ...;
--     -> null, null
--
-- The outcome vocabulary is `succeeded` / `tried_failed` / `no_chance`. Anything
-- else falls through every CASE with no ELSE branch, so `step_status` is set to
-- NULL and `night_result` keeps the value it already had — which is NULL. And
-- yet `harvest_answered_at` is stamped and the function returns
-- `recorded: true`.
--
-- The result is silent loss of exactly the evidence the product is built on. The
-- night is now marked answered, so `can_send('harvest')` will not ask again; the
-- parent told us how it went; and nothing was written down. `/progress` stays
-- empty, `knowledge_depth` never rises, `offer_ready` never becomes true — and
-- every one of those looks like the parent simply never tried.
--
-- The live caller is fine today. `CK - Update Step Status` maps its three
-- callbacks onto the right three words and falls back to 'no_chance'. So this
-- has never lost a real night. It is being fixed because "correct only because
-- the one caller happens to be correct" is not a property worth relying on:
--
--   * 'calm' and 'hard' are the vocabulary of `night_result`, sitting right
--     beside this one in the same table. Reaching for them here is the natural
--     mistake, and it is the one I made within a minute of writing the call.
--   * A silent no-op that reports success is the worst possible failure shape.
--     It cannot be seen in the data, because what it produces is indistinguishable
--     from a parent who never answered.
--
-- After this, an unrecognised outcome changes nothing at all — no stamp, no
-- write, no reset of the consent streak — and says so.

begin;

create or replace function public.record_harvest_answer(
  p_parent_id uuid, p_outcome text, p_hard_moment text default null)
returns jsonb
language plpgsql
set search_path to 'pg_catalog', 'public'
as $fn$
declare
  v_day  public.daily_logs%rowtype;
  v_tz   text;
  v_date date;
begin
  -- Refuse before touching anything. An outcome we cannot read is not an answer,
  -- and burning the night's harvest on it would cost the parent the question.
  if p_outcome is null or p_outcome not in ('succeeded', 'tried_failed', 'no_chance') then
    return jsonb_build_object(
      'recorded', false,
      'reason', 'unknown_outcome',
      'given', p_outcome,
      'expected', jsonb_build_array('succeeded', 'tried_failed', 'no_chance'));
  end if;

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
         -- 'no_chance' deliberately leaves night_result alone: a night they were
         -- too tired to try is honest, and parent_effort counts only calm and
         -- hard, so it costs them nothing.
         night_result = case p_outcome
                         when 'succeeded'    then 'calm'
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

  -- Any reply restores the rhythm: engagement resets the decay counter. It does
  -- NOT revive a cadence she stopped — that stays her decision, made by tapping
  -- resume. See 20260807190000.
  update public.checkin_state
     set consecutive_ignored = 0, last_responded_at = now(), updated_at = now()
   where parent_id = p_parent_id;

  return jsonb_build_object('recorded', true, 'day_id', v_day.id, 'local_date', v_date);
end;
$fn$;

comment on function public.record_harvest_answer(uuid, text, text) is
  'Records how the night went, for today''s seed only. The outcome must be one '
  'of succeeded / tried_failed / no_chance; anything else is refused outright '
  'rather than stamping the night as answered and writing nothing.';

commit;
