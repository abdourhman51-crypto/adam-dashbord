-- One way to activate a subscription
--
-- PRODUCTION WAS BROKEN. Not "carrying a legacy path" — broken:
--
--     select public.activate_subscription(id, 30, null, null, null);
--     ERROR:  42725: function public.activate_subscription(uuid, integer,
--             numeric, text, text) is not unique
--
-- On 2026-08-07 the journey engine gave activate_subscription five more
-- parameters, all with defaults. Written as CREATE OR REPLACE with a longer
-- parameter list, that does not replace anything — it creates an OVERLOAD. And
-- because arguments six through ten have defaults, a five-argument call matches
-- both candidates equally, so Postgres refuses to choose.
--
-- Every five-argument call has failed since. That is the dashboard's activation
-- path: confirming a payment. Nobody noticed because nobody has been paying —
-- ADAM is stopped. It would have been noticed by the first sale.
--
-- Two lessons, both cheap to state and expensive to relearn:
--
--   * CREATE OR REPLACE FUNCTION replaces a function only when the parameter
--     list is identical. Add a parameter and you have two functions.
--   * An overload whose extra parameters all have defaults does not merely sit
--     beside the original — it makes the original uncallable.
--
-- The fix is the one §3 of docs/what-is-missing.md asked for anyway: one paid
-- model. The five-argument version goes; the ten-argument one answers every call
-- that used to reach it, because arguments one to five are identical in name,
-- type, order and default. Existing callers change nothing.
--
-- What they gain: when no objective is passed — which is exactly what the
-- dashboard passes today — the money is still recorded, and the return value
-- carries `journey.started = false` with `reason = 'objective_required'`. A paid
-- parent with no journey becomes visible in the response instead of silent.
-- That is the whole point of the journey engine, and it now applies to the only
-- activation path there is.

begin;

-- Guarded so this is a no-op on a database that never had the overload — a
-- rebuild from this repository creates only the ten-argument version.
do $one_way$
begin
  if to_regprocedure('public.activate_subscription(uuid, integer, numeric, text, text)') is not null then
    drop function public.activate_subscription(uuid, integer, numeric, text, text);
  end if;
end $one_way$;

comment on function public.activate_subscription(
  uuid, integer, numeric, text, text, text, text, integer, integer, integer) is
  'The only way to activate a subscription. Records the payment and starts the '
  'agreed journey. Called with five arguments — as the dashboard calls it — the '
  'payment is recorded and journey.started comes back false with '
  'objective_required, because a goal nobody agreed is not a goal.';

commit;
