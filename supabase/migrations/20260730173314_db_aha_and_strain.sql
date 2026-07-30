begin;

-- ============================================================
-- aha_moments — the conversion signal, instrumented (arch §3.8.9)
-- Without a row per moment there is nothing for E10-E12 to
-- correlate, and "understanding drives revenue" (§0.2) stays
-- an opinion rather than a claim.
-- ============================================================
create table if not exists public.aha_moments (
  id             uuid primary key default gen_random_uuid(),
  parent_id      uuid not null references public.followers(id) on delete cascade,
  child_id       uuid references public.children(id) on delete set null,
  kind           text not null check (kind in ('A1','A2','A3','A4','A5','A6')),
  moment_class   text not null check (moment_class in ('free_value','hinge','premium')),
  first_occurrence boolean not null default false,
  day_id         uuid references public.daily_logs(id) on delete set null,
  journey_id     uuid references public.stages(id) on delete set null,
  occurred_at    timestamptz not null default now()
);

comment on table public.aha_moments is
  'CURRENT. Ledger of Aha moments (arch §3.8). A1-A3 free_value predict retention; A4 hinge predicts journeys started; A5-A6 premium occur AFTER payment and therefore cannot predict conversion at all. The class field is what makes that testable.';
comment on column public.aha_moments.first_occurrence is
  'The first occurrence CREATES the feeling; every one after SUSTAINS it (arch §3.8.6). Only first occurrences are the signal — totals mostly count A1 and A2 repeating.';

-- The first occurrence is structurally unique per parent per kind.
-- The distinction between creating a feeling and sustaining it is
-- an invariant, not a reporting convention.
create unique index if not exists uq_aha_first_per_kind
  on public.aha_moments(parent_id, kind) where first_occurrence;

create index if not exists idx_aha_parent_time on public.aha_moments(parent_id, occurred_at desc);
create index if not exists idx_aha_class on public.aha_moments(moment_class, kind);

-- moment_class is DERIVED from kind, never passed in.
-- A caller must not be able to mislabel A5 as free_value and
-- quietly move the free/paid boundary.
create or replace function public.derive_aha_class()
returns trigger
language plpgsql
set search_path to 'pg_catalog','public'
as $function$
begin
  new.moment_class := case new.kind
    when 'A1' then 'free_value' when 'A2' then 'free_value' when 'A3' then 'free_value'
    when 'A4' then 'hinge'
    else 'premium' end;
  return new;
end;
$function$;

drop trigger if exists trg_aha_class on public.aha_moments;
create trigger trg_aha_class before insert or update of kind
  on public.aha_moments for each row execute function public.derive_aha_class();

alter table public.aha_moments enable row level security;
revoke all on public.aha_moments from anon, authenticated, public;
grant select, insert on public.aha_moments to service_role;

-- ============================================================
-- parent_strain — three levels, graded return (AD-2, arch §8)
-- L2 is the level that matters: a parent drowning but not in
-- danger previously received cheerful morning suggestions and a
-- menu inviting them to buy.
-- ============================================================
create table if not exists public.parent_strain (
  parent_id          uuid primary key references public.followers(id) on delete cascade,
  level              smallint not null default 1 check (level in (1,2,3)),
  reason             text,
  entered_at         timestamptz not null default now(),
  return_eligible_at timestamptz,
  updated_at         timestamptz not null default now()
);

comment on table public.parent_strain is
  'CURRENT. Strain level per parent (AD-2). L1 normal, L2 high strain no danger, L3 danger. At L2 and L3 the rhythm, journeys and every commercial surface are suppressed and the changing menu item reverts to neutral.';
comment on column public.parent_strain.return_eligible_at is
  'When the graded return may begin. Stored rather than recomputed: five engines each deciding independently when a parent has recovered is five chances to get it wrong.';

create index if not exists idx_strain_level on public.parent_strain(level) where level > 1;

alter table public.parent_strain enable row level security;
revoke all on public.parent_strain from anon, authenticated, public;
grant select, insert, update on public.parent_strain to service_role;

commit;
