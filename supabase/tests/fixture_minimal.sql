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

create table public.children (
  id uuid primary key default gen_random_uuid(),
  follower_id uuid references public.followers(id) on delete cascade,
  name text,
  is_primary boolean,
  created_at timestamptz not null default now()
);

create table public.country_timezone (
  code text primary key, iana_tz text not null, name_ar text
);

create table public.supported_countries (
  code text primary key,
  is_active boolean default false,
  is_supported boolean default false
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

create table public.stages (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid references public.followers(id) on delete cascade,
  child_id uuid,
  problem_key text,
  objective_text text,
  status text
);

create table public.daily_logs (
  id uuid primary key default gen_random_uuid(),
  follower_id uuid references public.followers(id) on delete cascade,
  child_id uuid,
  log_date date not null,
  night_result text,
  step_status text,
  step_given text,
  hard_moment text,
  seed_sent_at timestamptz,
  harvest_sent_at timestamptz,
  unique (follower_id, log_date)
);

create table public.child_patterns (
  id uuid primary key default gen_random_uuid(),
  child_id uuid references public.children(id) on delete cascade,
  pattern_label text,
  status text,
  evidence_count integer default 1,
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

insert into public.country_timezone (code, iana_tz) values
  ('DZ','Africa/Algiers'), ('EG','Africa/Cairo'), ('MA','Africa/Casablanca'),
  ('SA','Asia/Riyadh');
insert into public.supported_countries (code, is_active, is_supported) values
  ('DZ',true,true), ('EG',true,true), ('MA',true,true), ('SA',false,false);
