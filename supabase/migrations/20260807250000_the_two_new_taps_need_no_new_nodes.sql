-- The two new taps need no new nodes
--
-- قراءة آدم (20260807230000) and the waitlist (20260807240000) were built as
-- functions with nothing calling them. The obvious way to reach them is two new
-- n8n nodes — and it is the wrong way. Every HTTP node added to W1 needs a
-- credential the MCP API cannot bind, so each one is a manual step in the UI and
-- another place the service key gets pasted in plaintext.
--
-- W1 already has a tap pipeline: a callback arrives, `get_moment_after_tap` is
-- called with the key, and whatever it returns is sent. It is 61 lines. Adding
-- two branches there makes both features reachable with **zero** workflow
-- changes, zero new credentials, and the existing copy law and gate applied on
-- the way out.
--
-- ── The waitlist tap carries its own country ──────────────────────────────────
--
-- The first thing this function already does is record `p_country_code` when one
-- is passed. That is what makes the whole flow a single round trip:
--
--   tap «سجّلوني» with no country   → needs_country → ask, with the country
--                                     buttons the purchase flow already has
--   tap a country button with the
--   waitlist key + that country     → record_country, then join_waitlist,
--                                     then the confirmation
--
-- No second button set, no state held between messages, and no way to record a
-- signup whose country nobody knows.

begin;

create or replace function public.get_moment_after_tap(
  p_key text, p_parent_id uuid, p_country_code text default null::text)
returns jsonb
language plpgsql
security definer
set search_path to 'pg_catalog', 'public'
as $function$
declare
  v_rec  jsonb;
  v_req  uuid;
  v_done text := null;
  v_moment text := p_key;
  v_reading jsonb;
  v_join jsonb;
begin
  if nullif(btrim(coalesce(p_country_code,'')), '') is not null then
    v_rec := public.record_country(p_parent_id, p_country_code);
  end if;

  -- The tap actions. Each of these was a button that promised something
  -- and answered with the rescue text. The action runs BEFORE the moment
  -- is composed, so a confirmation can never describe something that did
  -- not happen.
  if p_parent_id is not null then
    if p_key = 'menu_settings_paused' then
      insert into public.checkin_state (parent_id, cadence, cadence_changed_at)
      values (p_parent_id, 'stopped', now())
      on conflict (parent_id) do update
        set cadence = 'stopped', cadence_changed_at = now(), updated_at = now();
      v_done := 'paused';

    elsif p_key = 'menu_settings_resumed' then
      insert into public.checkin_state (parent_id, cadence, paused_until, cadence_changed_at)
      values (p_parent_id, 'nightly', null, now())
      on conflict (parent_id) do update
        set cadence = 'nightly', paused_until = null,
            cadence_changed_at = now(), updated_at = now();
      v_done := 'resumed';

    elsif p_key in ('menu_settings_hour_morning','menu_settings_hour_evening','menu_settings_hour_night') then
      -- The chosen hour is carried by the key itself: this call has no
      -- free slot for it, and adding one would mean a new n8n node, which
      -- cannot be given a credential through the MCP API.
      perform public.set_checkin_hour(p_parent_id, case p_key
                when 'menu_settings_hour_morning' then 8::smallint
                when 'menu_settings_hour_evening' then 17::smallint
                else                                   21::smallint end);
      v_done   := 'hour_set';
      v_moment := 'menu_settings_hour_set';

    elsif p_key = 'menu_privacy_erased' then
      v_req := public.request_erasure(p_parent_id);
      if v_req is not null then
        perform public.execute_erasure(v_req);
        v_done := 'erased';
      end if;

    elsif p_key = 'menu_waitlist_join' then
      -- record_country already ran above if a country came with the tap, so by
      -- here the state is as good as it is going to get.
      v_join := public.join_waitlist(p_parent_id);
      if (v_join->>'joined')::boolean then
        v_done   := 'waitlisted';
        v_moment := 'menu_waitlist_joined';
      elsif v_join->>'reason' = 'needs_country' then
        -- Ask, rather than record a signup with no address.
        v_done   := 'waitlist_needs_country';
        v_moment := 'menu_waitlist_ask_country';
      else
        -- already_supported: they can have it today, so send them where the
        -- journey is explained instead of onto a list.
        v_done   := 'waitlist_not_needed';
        v_moment := 'menu_journey';
      end if;
    end if;
  end if;

  -- قراءة آدم is composed by its own function rather than by compose_menu_body,
  -- because its four states are a ladder and not a body. The moment row still
  -- supplies the buttons and the line budget, so the copy law still owns it.
  if p_key = 'menu_reading' then
    v_reading := public.adam_reading(p_parent_id);
    return coalesce(public.get_conversation_moment('menu_reading', p_parent_id), '{}'::jsonb)
        || jsonb_build_object('body', v_reading->>'body')
        || jsonb_build_object('reading_state', v_reading->>'state')
        || jsonb_build_object('country_recorded', coalesce(v_rec, 'null'::jsonb))
        || jsonb_build_object('action_done', 'null'::jsonb);
  end if;

  -- After an erasure the parent row is gone, so the moment is composed
  -- without an id; otherwise every parent-scoped lookup inside it would
  -- silently resolve to nothing.
  return public.get_conversation_moment(
           v_moment,
           case when v_done = 'erased' then null else p_parent_id end)
       || jsonb_build_object('country_recorded', coalesce(v_rec, 'null'::jsonb))
       || jsonb_build_object('action_done', coalesce(to_jsonb(v_done), 'null'::jsonb));
end;
$function$;

comment on function public.get_moment_after_tap(text, uuid, text) is
  'The tap router. Runs the action first, then composes the moment, so a '
  'confirmation can never describe something that did not happen. Handles '
  'menu_reading (قراءة آدم, composed by adam_reading) and menu_waitlist_join '
  '(which asks for a country rather than recording a signup without one) '
  'without any new workflow node.';

commit;
