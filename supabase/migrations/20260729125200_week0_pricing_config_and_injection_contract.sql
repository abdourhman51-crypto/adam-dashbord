-- ============================================================================
-- Week-0 data validity · pricing configuration and the injection contract
-- ============================================================================
-- PROBLEM
--   A parent was quoted "150 جنيه" by the agent. The real Egypt price is 490
--   EGP. The main agent's system prompt carries NO price data at all -- it is
--   told to route money questions to the team, yet answered with a number.
--   The agent invented a price. A hallucinated price is a broken promise, and
--   trust is the only moat this product has.
--
-- APPROVED DESIGN (blueprint 8.2, journey-architecture 4)
--   "Price is injected into agent context from configuration, never generated."
--   "One published price per market. Never improvised, never negotiated."
--
-- DESIGN NOTES
--   supported_countries already holds the canonical amounts (DZ 2300 /
--   EG 490 / MA 110), all ~$10 equivalent. This adds the display strings so
--   the exact wording an agent may emit is configuration rather than model
--   output, plus the approved second-stage continuation price.
--
--   price_comeback is deliberately NOT reused: it holds the legacy win-back
--   price, which is HIGHER than subscription (2900/520/119), whereas the
--   approved continuation price is LOWER. Reusing it would silently invert
--   the meaning for the Renewal Guard, which still reads it.
--
--   Display strings are lifted verbatim from the existing Silent Seller
--   PRICES map so the agent's voice does not change.
-- ============================================================================

ALTER TABLE public.supported_countries
  ADD COLUMN IF NOT EXISTS price_continuation          numeric,
  ADD COLUMN IF NOT EXISTS price_display_full          text,
  ADD COLUMN IF NOT EXISTS price_display_short         text,
  ADD COLUMN IF NOT EXISTS price_continuation_display  text;

COMMENT ON COLUMN public.supported_countries.price_continuation IS
  'Approved price for a second and subsequent stage (~$6-7 equivalent). Lower '
  'than price_subscription by design. Distinct from price_comeback, which is '
  'the legacy win-back price and higher.';

COMMENT ON COLUMN public.supported_countries.price_display_full IS
  'The exact wording an agent may emit for the first stage. Injected verbatim. '
  'The agent must never format or generate a price itself.';

UPDATE public.supported_countries SET
  price_continuation = 1500, price_display_full = '2,300 دينار جزائري',
  price_display_short = '2,300 دج', price_continuation_display = '1,500 دينار جزائري'
WHERE code = 'DZ';

UPDATE public.supported_countries SET
  price_continuation = 290, price_display_full = '490 جنيهاً مصرياً',
  price_display_short = '490 جنيهاً', price_continuation_display = '290 جنيهاً مصرياً'
WHERE code = 'EG';

UPDATE public.supported_countries SET
  price_continuation = 65, price_display_full = '110 دراهم مغربية',
  price_display_short = '110 دراهم', price_continuation_display = '65 درهماً مغربياً'
WHERE code = 'MA';

-- An active market must carry complete pricing. This is precisely the gap an
-- agent fills by inventing a number.
ALTER TABLE public.supported_countries DROP CONSTRAINT IF EXISTS chk_active_market_has_pricing;
ALTER TABLE public.supported_countries ADD CONSTRAINT chk_active_market_has_pricing CHECK (
  NOT is_active OR (
    price_subscription IS NOT NULL AND price_continuation IS NOT NULL AND
    price_display_full IS NOT NULL AND price_continuation_display IS NOT NULL));

-- The injection contract: the only sanctioned source of price for agent
-- context. is_supported = false means no payment rail exists for that market;
-- say so plainly (blueprint 12.3) rather than improvising.
CREATE OR REPLACE FUNCTION public.get_pricing(p_country text)
RETURNS TABLE (
  country text, is_supported boolean, currency text,
  first_stage_amount numeric, first_stage_display text,
  first_stage_display_short text, continuation_amount numeric,
  continuation_display text)
LANGUAGE sql STABLE SECURITY INVOKER
SET search_path = pg_catalog, public
AS $$
  SELECT
    COALESCE(sc.code, upper(trim(COALESCE(p_country,'')))),
    (sc.code IS NOT NULL),
    sc.currency, sc.price_subscription, sc.price_display_full,
    sc.price_display_short, sc.price_continuation, sc.price_continuation_display
  FROM (SELECT 1) AS anchor
  LEFT JOIN public.supported_countries sc
         ON sc.code = upper(trim(COALESCE(p_country,''))) AND sc.is_active
$$;

COMMENT ON FUNCTION public.get_pricing(text) IS
  'The ONLY sanctioned source of price for agent context. Callers inject '
  'first_stage_display verbatim and must never format or generate a price. '
  'Added after the agent quoted a parent 150 EGP against a real price of 490.';

REVOKE EXECUTE ON FUNCTION public.get_pricing(text) FROM anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.get_pricing(text) TO service_role;
