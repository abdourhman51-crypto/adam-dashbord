begin;

-- ============================================================
-- journey_problem_catalog was applied straight to production and
-- never written down — the same drift docs/situation_catalog
-- describes ("thirty-four of eighty-eight production functions
-- were in that state").
--
-- The cost is concrete and was measured, not guessed: a clean
-- rebuild of the schema from this repository fails one migration
-- and then 20 assertions across 7 suites, because the objects
-- they exercise do not exist. A repository that cannot rebuild
-- its own database is not a repository you can launch from —
-- there is no recovery path and no way to test a change before
-- applying it.
--
-- Restored from production via the catalogs, not retyped: the
-- column list, the primary key, and the eight rows are exactly
-- what production holds today.
--
-- This file is timestamped 20260825190000 — deliberately ten
-- minutes BEFORE 20260825200000_grant_service_role_select_
-- journey_problem_catalog, which grants on this table and was the
-- migration failing on every rebuild. That file is left untouched;
-- ordering alone resolves it.
-- ============================================================

create table if not exists public.journey_problem_catalog (
  key        text     not null,
  label_ar   text     not null,
  emoji      text     not null,
  sort_order smallint not null default 0,
  constraint journey_problem_catalog_pkey primary key (key)
);

comment on table public.journey_problem_catalog is
  'The CLOSED list of problems a paid journey may be aimed at, shown by the wizard. Restored from production 2026-08-30 after a clean rebuild proved the repo could not recreate it.';

insert into public.journey_problem_catalog (key, label_ar, emoji, sort_order) values
  ('anger',    'نوبات الغضب والصراخ',        '🔥',   1),
  ('out',      'الاستعداد والخروج من البيت', '🚪',   2),
  ('screen',   'وقت الشاشة',                 '📱',   3),
  ('stubborn', 'العناد ورفض التعليمات',      '😤',   4),
  ('study',    'الدراسة والواجبات',          '📚',   5),
  ('sleep',    'النوم',                      '🌙',   6),
  ('meal',     'الطعام',                     '🍽️',  7),
  ('sibling',  'الغيرة من الإخوة أو المقارنة','👦',  8)
on conflict (key) do update
  set label_ar   = excluded.label_ar,
      emoji      = excluded.emoji,
      sort_order = excluded.sort_order;

alter table public.journey_problem_catalog enable row level security;
revoke all on public.journey_problem_catalog from anon, authenticated;
grant select on public.journey_problem_catalog to service_role;

commit;
