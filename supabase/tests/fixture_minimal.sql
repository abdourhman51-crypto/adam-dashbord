-- Minimal fixture reproducing only the columns get_telegram_surface() reads.
-- Column names and types copied from the real migrations, not invented.

-- Roles are cluster-wide, not per-database, so this must be idempotent:
-- a second test database in the same cluster would otherwise fail here
-- and leave every later statement unrun.
do $$
declare r text;
begin
  foreach r in array array['service_role','authenticated','anon'] loop
    if not exists (select 1 from pg_roles where rolname = r) then
      execute format('create role %I', r);
    end if;
  end loop;
end $$;

create table public.followers (
  id uuid primary key default gen_random_uuid(),
  platform_user_id text,
  country text,
  first_seen timestamptz default now()
);

-- Columns copied from production. age_note is read by compose_menu_body();
-- it was added here the moment that function started reading it, rather than
-- after production returned 42703 — which is the mistake this fixture exists
-- to stop repeating.
create table public.children (
  id uuid primary key default gen_random_uuid(),
  follower_id uuid references public.followers(id) on delete cascade,
  name text,
  gender text, birth_year integer, age_note text, temperament text,
  is_primary boolean,
  created_at timestamptz not null default now(),
  updated_at timestamptz default now()
);

create table public.country_timezone (
  code text primary key, iana_tz text not null, name_ar text
);

-- Columns copied from production. There is NO is_supported column: an
-- earlier fixture invented one, the tests passed, and every production call
-- to get_telegram_surface returned 42703 (execution 5456). A fixture that
-- invents a column tests the fixture, not the schema.
create table public.supported_countries (
  code text primary key,
  name_ar text, currency text,
  price_subscription numeric, price_comeback numeric, price_continuation numeric,
  price_display_full text, price_display_short text, price_continuation_display text,
  is_active boolean default false,
  created_at timestamptz default now()
);

create table public.situations (
  id uuid primary key default gen_random_uuid(),
  child_id uuid references public.children(id) on delete cascade,
  key text,
  status text check (status in ('candidate','confirmed','rejected')),
  window_start smallint, window_end smallint,
  evidence_count integer default 1,
  last_observed timestamptz default now()
);

-- planned_logged_days and extension_days are here because the offer copy now
-- promises what they hold — 29 days, and half of that again if we miss — and
-- a promise the schema does not back is the thing the tests exist to catch.
-- Types and the 7..60 bound are copied from
-- 20260729130100_journey_engine_core_schema.sql, not invented.
create table public.stages (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid references public.followers(id) on delete cascade,
  child_id uuid,
  problem_key text,
  objective_text text,
  planned_logged_days integer check (planned_logged_days between 7 and 60),
  extension_days integer not null default 0 check (extension_days >= 0),
  status text
);

-- Columns copied from production (information_schema), not from memory.
create table public.daily_logs (
  id uuid primary key default gen_random_uuid(),
  follower_id uuid references public.followers(id) on delete cascade,
  log_date date not null,
  summary text, guardian_mood text,
  step_given text, step_completed boolean, step_status text,
  created_at timestamptz default now(), updated_at timestamptz default now(),
  checkin_sent_at timestamptz,
  child_id uuid,
  night_result text, hard_moment text,
  source text, journey_id uuid, situation_id uuid,
  seed_text text, seed_grounded_on jsonb,
  seed_scheduled_for timestamptz, seed_sent_at timestamptz,
  harvest_sent_at timestamptz, harvest_answered_at timestamptz,
  unique (follower_id, log_date)
);

create table public.child_patterns (
  id uuid primary key default gen_random_uuid(),
  follower_id uuid,
  child_id uuid references public.children(id) on delete cascade,
  pattern_label text,
  description text,
  status text,
  evidence_count integer default 1,
  first_observed timestamptz default now(),
  last_observed timestamptz default now(),
  updated_at timestamptz default now(),
  safe_for_record boolean not null default false
);

create table public.checkin_state (
  parent_id uuid primary key references public.followers(id) on delete cascade,
  cadence text not null default 'nightly',
  paused_until date
);

create table public.parent_strain (
  parent_id uuid primary key references public.followers(id) on delete cascade,
  level smallint not null default 1,
  return_eligible_at timestamptz
);

create table public.n8n_chat_histories (
  id bigserial primary key,
  session_id text,
  message jsonb,
  created_at timestamptz default now()
);

create function public.normalise_session_key(p text) returns text
language sql immutable as $$ select p $$;

-- v_parent_engagement: only the four columns the surface function reads.
create view public.v_parent_engagement as
with chat as (
  select public.normalise_session_key(h.session_id) as key,
         count(*) filter (where h.message->>'type' = 'human') as human_messages,
         max(h.created_at) as last_message_at
  from public.n8n_chat_histories h group by 1
),
logs as (
  select d.follower_id,
         count(distinct d.log_date) filter (where d.night_result is not null) as nights_with_result
  from public.daily_logs d group by 1
)
select f.id as parent_id, f.platform_user_id,
       coalesce(c.human_messages, 0) as human_messages,
       c.last_message_at,
       coalesce(l.nights_with_result, 0) as nights_with_result
from public.followers f
left join chat c on c.key = f.platform_user_id
left join logs l on l.follower_id = f.id;

-- get_agent_context(): the shape production returns, not the real assembly.
-- The PLAN_DAY / DAYS_LEFT preamble is reproduced deliberately — stripping it
-- is the behaviour under test, and a stub without it would test nothing.
create or replace function public.get_agent_context(p_follower_id uuid)
returns text language sql stable as $$
  select 'PLAN_DAY: ?' || chr(10) || 'DAYS_LEFT: 0' || chr(10) || chr(10)
      || coalesce(
           (select '== CHILDREN ==' || chr(10) || '- ' || c.name
            from public.children c
            where c.follower_id = p_follower_id and nullif(btrim(c.name),'') is not null
            order by c.is_primary desc nulls last limit 1),
           '');
$$;

-- commerce_allowed(): real signature, simplified body (blocks at L2/L3).
-- hard_moment_label(): copied verbatim from the child-record migration.
create function public.hard_moment_label(p_key text) returns text
language sql immutable as $$
  select case lower(coalesce(p_key,''))
    when 'meal' then 'عند الأكل' when 'sleep' then 'عند النوم'
    when 'out' then 'عند الخروج' when 'screen' then 'في وقت الشاشة'
    when 'study' then 'عند الدراسة' when 'other' then 'في موقف آخر'
    else null end
$$;

-- can_ground_seed(): the real one lives in a migration this fixture does
-- not load. Same contract — a child name AND one of situation / prior
-- outcome / pattern — reimplemented so can_send('seed') is exercised.
create function public.can_ground_seed(p_parent_id uuid) returns jsonb
language sql stable as $$
  with ctx as (
    select (select nullif(btrim(c.name),'') from public.children c
             where c.follower_id = p_parent_id
             order by c.is_primary desc nulls last, c.created_at limit 1) as nm,
           exists (select 1 from public.situations s join public.children c on c.id = s.child_id
                    where c.follower_id = p_parent_id and s.status in ('candidate','confirmed')) as sit,
           exists (select 1 from public.daily_logs d
                    where d.follower_id = p_parent_id and d.step_status = 'done') as outc
  )
  select jsonb_build_object(
    'can_ground', nm is not null and (sit or outc),
    'child_name', nm,
    'basis', (select coalesce(jsonb_agg(b),'[]'::jsonb) from (
                select 'situation' as b where sit
                union all select 'prior_outcome' where outc) z),
    'missing', (select coalesce(jsonb_agg(b),'[]'::jsonb) from (
                select 'child_name' as b where nm is null
                union all select 'grounding' where not (sit or outc)) z))
  from ctx;
$$;

create function public.commerce_allowed(p_parent_id uuid) returns boolean
language sql stable as $$
  select coalesce((select ps.level from public.parent_strain ps
                    where ps.parent_id = p_parent_id), 1) < 2;
$$;

-- SA and SY are here on purpose: a country we can put on a clock but do NOT
-- sell in. Without one of those, "unsupported" and "unknown" collapse into
-- the same fixture state and the test that matters cannot be written.
insert into public.country_timezone (code, iana_tz) values
  ('DZ','Africa/Algiers'), ('EG','Africa/Cairo'), ('MA','Africa/Casablanca'),
  ('SA','Asia/Riyadh'), ('SY','Asia/Damascus'),
  -- Tunisia: genuinely unsupported, and on Africa/Tunis — permanently UTC+1,
  -- exactly like Africa/Algiers. The unsupported-vs-supported comparison in
  -- telegram_surface_test used SA, whose local date rolls over four hours
  -- before DZ's, so the two parents' seven-day windows landed on different
  -- dates and the test failed for roughly two hours every night.
  ('TN','Africa/Tunis');
-- name_ar is read by country_recorded. It was absent, and the confirmation
-- fell back to «بلدكم» in a test that still passed.
insert into public.supported_countries (code, name_ar, is_active, price_display_full) values
  ('DZ','الجزائر',true,'2,300 دينار جزائري'), ('EG','مصر',true,'490 جنيهاً مصرياً'),
  ('MA','المغرب',true,'110 دراهم مغربية'), ('SA','السعودية',false,null);
