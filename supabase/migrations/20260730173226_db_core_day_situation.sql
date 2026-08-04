begin;

-- ============================================================
-- situations — the recurring hard moment, WITH a time window
-- Required by architecture §5.4: the Seed is scheduled before
-- the situation and the Harvest after it. Impossible without a clock.
-- ============================================================
create table if not exists public.situations (
  id            uuid primary key default gen_random_uuid(),
  child_id      uuid not null references public.children(id) on delete cascade,
  parent_id     uuid not null references public.followers(id) on delete cascade,
  key           text not null,
  label_ar      text not null,
  window_start  smallint not null check (window_start between 0 and 23),
  window_end    smallint not null check (window_end   between 0 and 23),
  status        text not null default 'candidate'
                  check (status in ('candidate','confirmed','resolved')),
  evidence_count integer not null default 0 check (evidence_count >= 0),
  first_observed timestamptz not null default now(),
  last_observed  timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  unique (child_id, key)
);

comment on table public.situations is
  'CURRENT. The recurring hard moment with its time-of-day window. Distinct from child_patterns: a pattern is a correlation ADAM noticed; a situation is a moment in the day with a clock, which is what the timing model (arch §5.4) schedules against.';
comment on column public.situations.window_start is
  'Local hour the situation typically begins. The Seed must arrive before this with time to act.';
comment on column public.situations.window_end is
  'Local hour it ends. The Harvest must arrive after this — asking at 20:00 how bedtime went asks about a thing that has not happened.';

create index if not exists idx_situations_parent on public.situations(parent_id);
create index if not exists idx_situations_child_status on public.situations(child_id, status);

alter table public.situations enable row level security;
revoke all on public.situations from anon, authenticated, public;
grant select, insert, update, delete on public.situations to service_role;

-- ============================================================
-- daily_logs becomes the Day (arch §8.1)
-- Evolved, not replaced: it already carries UNIQUE(follower_id, log_date),
-- which is exactly the one-Day-per-parent-per-date shape, and it holds
-- the only measurement history that exists.
-- ============================================================
alter table public.daily_logs
  add column if not exists source             text not null default 'legacy',
  add column if not exists journey_id         uuid references public.stages(id) on delete set null,
  add column if not exists situation_id       uuid references public.situations(id) on delete set null,
  add column if not exists seed_text          text,
  add column if not exists seed_grounded_on   jsonb,
  add column if not exists seed_scheduled_for timestamptz,
  add column if not exists seed_sent_at       timestamptz,
  add column if not exists harvest_sent_at    timestamptz,
  add column if not exists harvest_answered_at timestamptz;

do $$ begin
  alter table public.daily_logs
    add constraint chk_daily_logs_source check (source in ('legacy','rhythm'));
exception when duplicate_object then null; end $$;

-- INVARIANT 1 (arch §8.2, P11): a sent Seed must record the Knowledge it came from.
-- This is the enforcement point for "the Seed must never be generic".
do $$ begin
  alter table public.daily_logs add constraint chk_seed_grounded check (
    source <> 'rhythm'
    or seed_sent_at is null
    or (seed_grounded_on is not null and jsonb_typeof(seed_grounded_on) = 'array'
        and jsonb_array_length(seed_grounded_on) > 0)
  );
exception when duplicate_object then null; end $$;

-- INVARIANT 2 (arch §5.3): no Harvest without a Seed. The pair is atomic.
do $$ begin
  alter table public.daily_logs add constraint chk_harvest_needs_seed check (
    source <> 'rhythm'
    or (night_result is null and step_status is null and harvest_answered_at is null)
    or seed_sent_at is not null
  );
exception when duplicate_object then null; end $$;

comment on table public.daily_logs is
  'CURRENT — the Day (arch §8.1). One row per parent per local date. Carries the Seed (morning) and its Harvest (evening) as one atomic unit. source=legacy marks rows written before the pair existed; they are exempt from its invariants so the live workflow keeps working.';
comment on column public.daily_logs.seed_grounded_on is
  'JSON array of the Knowledge that produced this Seed, e.g. ["child_name","situation","prior_outcome"]. Enforced non-empty for sent rhythm Seeds by chk_seed_grounded — an ungrounded Seed is a constraint violation, not something noticed later in a sample.';
comment on column public.daily_logs.source is
  'legacy = written by the pre-rhythm check-in. rhythm = Seed/Harvest pair, subject to both invariants.';

create index if not exists idx_daily_logs_seed_due
  on public.daily_logs(seed_scheduled_for) where seed_sent_at is null;
create index if not exists idx_daily_logs_journey on public.daily_logs(journey_id);

commit;
