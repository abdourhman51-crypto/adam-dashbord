-- Test seed — the only thing the suites need that migrations do not carry.
--
-- This file replaced `fixture_minimal.sql` on 2026-08-07. That fixture existed
-- because the repository could not build production's schema; it described the
-- tables by hand, and every place its description drifted from production was a
-- place the suites tested the fixture instead of the product. It found three
-- separate false bugs and hid at least six real ones.
--
-- Now the migrations build the real schema (docs/what-is-missing.md §6b), so the
-- suites run against it and there is nothing left to describe. What remains is
-- DATA, not schema: prices are business facts, and no migration carries them.
--
-- `country_timezone` is NOT here — the migrations seed all 30 rows, including
-- the ones the suites depend on:
--   * TN, deliberately unsupported and on Africa/Tunis, which is permanently
--     UTC+1 exactly like Africa/Algiers. An earlier suite compared an
--     unsupported parent against a DZ one using SA, whose local date rolls over
--     four hours earlier, so their seven-day windows landed on different dates
--     and the test failed for roughly two hours every night.
--   * SA and SY: countries we can put on a clock but do not sell in. Without one
--     of those, "unsupported" and "unknown" collapse into the same state and the
--     test that matters cannot be written.
--
-- Every active market carries every price it can be asked for, because
-- chk_active_market_has_pricing refuses anything less. SA is inactive on
-- purpose, and therefore allowed to have no prices at all.

insert into public.supported_countries
  (code, name_ar, currency, price_subscription, price_comeback, price_continuation,
   price_display_full, price_display_short, price_continuation_display, is_active)
values
  ('DZ','الجزائر','DZD', 2300, 1500, 1500,
   '2,300 دينار جزائري', '2,300 دج', '1,500 دينار جزائري', true),
  ('EG','مصر','EGP',  490,  320,  320,
   '490 جنيهاً مصرياً', '490 ج.م', '320 جنيهاً مصرياً', true),
  ('MA','المغرب','MAD', 110,   75,   75,
   '110 دراهم مغربية', '110 د.م', '75 درهماً مغربياً', true),
  ('SA','السعودية','SAR',  65,   45,   45,
   null, null, null, false)
on conflict (code) do nothing;
