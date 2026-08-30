begin;

-- ============================================================
-- THE CONSTRAINT THAT BLOCKS PAYMENT
--
-- `followers.chk_active_has_expiry` exists in this repository
-- and does NOT exist in production. It reads:
--
--   check (funnel_stage <> 'paid_active'
--          or subscription_expires_at is not null)
--
-- and it was right when it was written: paid access always has
-- an end, and a subscription with no expiry is one nobody can
-- close. But the 29-day stage moved that clock. The end of a
-- paid period now lives on `stages` — started_at,
-- planned_logged_days, extension_days — and check_stage_clock()
-- is what closes it. `followers.subscription_expires_at` was
-- retired, and activate_subscription() sets it to null on
-- purpose.
--
-- So on a database built from this repository, activating a
-- subscription raises
--
--   new row for relation "followers" violates check constraint
--   "chk_active_has_expiry"
--
-- Payment is the one flow that cannot be allowed to fail, and
-- this is the repo's own constraint failing it. Dropping it
-- brings the repo to production.
--
-- The guarantee it protected has not been abandoned, only
-- moved: chk_started_when_live and chk_target_fits_window on
-- `stages`, plus check_stage_clock(), are what now make sure a
-- paid period ends.
-- ============================================================

alter table public.followers
  drop constraint if exists chk_active_has_expiry;


-- ------------------------------------------------------------
-- And two production constraints the repo never had. An hour
-- outside 0-23 in the catalog would put a family's hard window
-- somewhere that does not exist.
-- ------------------------------------------------------------
do $$
begin
  if not exists (select 1 from pg_constraint
                 where conrelid = 'public.situation_catalog'::regclass
                   and conname = 'situation_catalog_window_start_check') then
    alter table public.situation_catalog
      add constraint situation_catalog_window_start_check
      check (window_start >= 0 and window_start <= 23);
  end if;

  if not exists (select 1 from pg_constraint
                 where conrelid = 'public.situation_catalog'::regclass
                   and conname = 'situation_catalog_window_end_check') then
    alter table public.situation_catalog
      add constraint situation_catalog_window_end_check
      check (window_end >= 0 and window_end <= 23);
  end if;
end $$;

commit;
