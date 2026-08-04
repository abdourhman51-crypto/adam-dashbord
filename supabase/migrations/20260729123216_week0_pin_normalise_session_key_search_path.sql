-- Supabase security advisor 0011: function_search_path_mutable.
-- Pin search_path on the function introduced in week0_engagement_truth_layer.
-- A mutable search_path lets a caller shadow regexp_replace via a schema
-- earlier in their path, changing what the key normalises to. Pinning it
-- makes the function deterministic regardless of caller context -- which it
-- must be, since it backs a functional index.

CREATE OR REPLACE FUNCTION public.normalise_session_key(p_key text)
RETURNS text
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
SET search_path = pg_catalog, public
AS $$
  SELECT regexp_replace(
           regexp_replace(COALESCE(p_key, ''), '^=+', ''),
           '_s[0-9]+$', ''
         )
$$;
