-- commerce_allowed, restored — the fourteenth function with no source
--
-- The last one, found by diffing a full offline rebuild against production
-- rather than by reading. It belongs to the strain layer immediately above it
-- (20260730183000_strain_detection_and_graded_return.sql), which was one of the
-- three comment-only migrations, and it was applied straight to the database.
--
-- It is the single gate on whether ADAM may mention the journey at all: a parent
-- under strain, or one who has raised a crisis flag in the last fourteen days,
-- is never sold to. `surface_changing_item` uses the SAME label whether this
-- returns true or false, so the withholding is silent — she is never told that
-- something is being kept from her.
--
-- RESTORED AS IT RUNS, INCLUDING A CLAUSE THAT CANNOT BE FALSE:
--
--     ps.level = 1 and (ps.entered_at < now() - interval '14 days' or ps.level = 1)
--                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
--
-- The `or ps.level = 1` makes the whole parenthesis true whenever the first
-- condition already passed, so the fourteen-day settling period after a parent
-- returns to level 1 never applies: commerce reopens the instant strain steps
-- down. Whether it SHOULD wait fourteen days is a product decision about how
-- soon it is decent to mention money to someone who was drowning last week, and
-- that is the founder's to make — so the line is restored exactly, named here,
-- and left for §7 of docs/what-is-missing.md rather than quietly changed inside
-- a migration whose title says "restored".
--
-- Note also that lifecycle_test.sql exercises the FIXTURE's simplified
-- commerce_allowed (level < 2), not this body. The recovery window it asserts is
-- the fixture's, not production's. That gap is what let this sit unnoticed.

create or replace function public.commerce_allowed(p_parent_id uuid)
returns boolean
language sql
stable security definer
set search_path to 'pg_catalog', 'public'
as $fn$
  select coalesce((
    select ps.level = 1
       and (ps.entered_at < now() - interval '14 days' or ps.level = 1)
       and not exists (
         select 1 from public.crisis_flags cf
         where cf.parent_id = p_parent_id
           and cf.detected_at > now() - interval '14 days')
    from public.parent_strain ps
    where ps.parent_id = p_parent_id
  ), true);
$fn$;

-- A parent with no strain row at all has never been seen struggling, so the
-- coalesce defaults to true. That is the right default: silence is not distress.
comment on function public.commerce_allowed(uuid) is
  'The only gate on mentioning the journey. False under strain, or within 14 '
  'days of a crisis flag. Withholding is silent — surface_changing_item shows '
  'the same label either way.';
