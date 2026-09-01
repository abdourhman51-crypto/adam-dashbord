-- Mini App analytics: the founder has zero visibility into who opens the Mini
-- App, which screens actually get used, and where people drop off ("احس كأنني
-- اعمى"). This adds a single lean events table plus a small set of Postgres
-- functions that pre-aggregate it, so the dashboard queries stay cheap even as
-- the table grows past what the "pull all rows, reduce in JS" convention used
-- for the small entity tables (followers, children, ...) can handle.
--
-- Event shape, deliberately minimal:
--   event_type: 'screen_view' | 'screen_time' | 'click' | 'session_start'
--   screen:     route name ('home','insights','child','journey','journey_start')
--   element:    click target label (null for screen_view/screen_time/session_start)
--   meta:       jsonb, currently only used for screen_time's duration_ms
--   session_id: client-generated, one per Mini App open (sessionStorage-scoped)

create table if not exists public.miniapp_events (
  id bigint generated always as identity primary key,
  follower_id uuid not null references public.followers(id) on delete cascade,
  session_id text not null,
  event_type text not null check (event_type in ('screen_view', 'screen_time', 'click', 'session_start')),
  screen text,
  element text,
  meta jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_miniapp_events_follower on public.miniapp_events (follower_id, created_at desc);
create index if not exists idx_miniapp_events_session on public.miniapp_events (session_id, created_at);
create index if not exists idx_miniapp_events_type_screen on public.miniapp_events (event_type, screen, created_at desc);
create index if not exists idx_miniapp_events_created on public.miniapp_events (created_at desc);

alter table public.miniapp_events enable row level security;
-- No client-side policies: every write goes through the Mini App's server
-- route using the service-role key (same trust model as every other write
-- path in this product), so RLS stays deny-by-default with no policies.

-- ── Overview KPIs ────────────────────────────────────────────────────────
create or replace function public.get_miniapp_overview()
returns jsonb
language sql
stable
security definer
set search_path to 'pg_catalog', 'public'
as $function$
  select jsonb_build_object(
    'total_visitors', (select count(distinct follower_id) from public.miniapp_events),
    'visitors_today', (select count(distinct follower_id) from public.miniapp_events where created_at >= current_date),
    'visitors_7d', (select count(distinct follower_id) from public.miniapp_events where created_at >= now() - interval '7 days'),
    'visitors_30d', (select count(distinct follower_id) from public.miniapp_events where created_at >= now() - interval '30 days'),
    'sessions_today', (select count(distinct session_id) from public.miniapp_events where created_at >= current_date),
    'sessions_7d', (select count(distinct session_id) from public.miniapp_events where created_at >= now() - interval '7 days'),
    'total_screen_views', (select count(*) from public.miniapp_events where event_type = 'screen_view'),
    'avg_session_seconds', (
      select coalesce(round(avg(dur)::numeric, 1), 0)
      from (
        select extract(epoch from (max(created_at) - min(created_at))) as dur
        from public.miniapp_events
        where created_at >= now() - interval '30 days'
        group by session_id
        having count(*) > 1
      ) s
    )
  );
$function$;

-- ── Daily active visitors/sessions, for the trend chart ─────────────────
create or replace function public.get_miniapp_daily_active(p_days int default 30)
returns table(day date, visitors bigint, sessions bigint, screen_views bigint)
language sql
stable
security definer
set search_path to 'pg_catalog', 'public'
as $function$
  select
    d::date as day,
    coalesce(count(distinct e.follower_id), 0) as visitors,
    coalesce(count(distinct e.session_id), 0) as sessions,
    coalesce(count(*) filter (where e.event_type = 'screen_view'), 0) as screen_views
  from generate_series(current_date - (p_days - 1), current_date, interval '1 day') d
  left join public.miniapp_events e on e.created_at::date = d::date
  group by d
  order by d;
$function$;

-- ── Per-screen performance: views, reach, time spent, where people leave ──
create or replace function public.get_miniapp_screen_performance()
returns table(screen text, views bigint, unique_visitors bigint, avg_seconds numeric, exits bigint, exit_rate numeric)
language sql
stable
security definer
set search_path to 'pg_catalog', 'public'
as $function$
  with sv as (
    select
      session_id, follower_id, screen, created_at,
      row_number() over (partition by session_id order by created_at desc) as rn
    from public.miniapp_events
    where event_type = 'screen_view' and screen is not null
  ),
  views as (
    select screen, count(*) as views, count(distinct follower_id) as unique_visitors
    from sv
    group by screen
  ),
  exits as (
    select screen, count(*) as exits
    from sv
    where rn = 1
    group by screen
  ),
  times as (
    select screen, avg((meta->>'duration_ms')::numeric / 1000.0) as avg_seconds
    from public.miniapp_events
    where event_type = 'screen_time' and screen is not null and meta ? 'duration_ms'
    group by screen
  )
  select
    v.screen,
    v.views,
    v.unique_visitors,
    coalesce(round(t.avg_seconds::numeric, 1), 0) as avg_seconds,
    coalesce(ex.exits, 0) as exits,
    case when v.views > 0 then round((coalesce(ex.exits, 0)::numeric / v.views), 3) else 0 end as exit_rate
  from views v
  left join exits ex on ex.screen = v.screen
  left join times t on t.screen = v.screen
  order by v.views desc;
$function$;

-- ── Most-clicked elements, across screens ────────────────────────────────
create or replace function public.get_miniapp_top_clicks(p_limit int default 15)
returns table(element text, screen text, clicks bigint)
language sql
stable
security definer
set search_path to 'pg_catalog', 'public'
as $function$
  select element, screen, count(*) as clicks
  from public.miniapp_events
  where event_type = 'click' and element is not null
  group by element, screen
  order by clicks desc
  limit p_limit;
$function$;

-- ── New vs. returning today, plus D1/D7 cohort retention ─────────────────
create or replace function public.get_miniapp_retention()
returns jsonb
language sql
stable
security definer
set search_path to 'pg_catalog', 'public'
as $function$
  with first_seen as (
    select follower_id, min(created_at)::date as first_day
    from public.miniapp_events
    group by follower_id
  ),
  active_today as (
    select distinct follower_id from public.miniapp_events where created_at >= current_date
  ),
  d1_cohort as (
    select follower_id from first_seen where first_day = current_date - 1
  ),
  d1_returned as (
    select fs.follower_id
    from d1_cohort fs
    join public.miniapp_events e on e.follower_id = fs.follower_id
    where e.created_at::date = current_date
  ),
  d7_cohort as (
    select follower_id from first_seen where first_day = current_date - 7
  ),
  d7_returned as (
    select fs.follower_id
    from d7_cohort fs
    join public.miniapp_events e on e.follower_id = fs.follower_id
    where e.created_at::date = current_date
  )
  select jsonb_build_object(
    'new_today', (select count(*) from first_seen where first_day = current_date),
    'returning_today', (
      select count(*) from active_today a
      join first_seen fs on fs.follower_id = a.follower_id
      where fs.first_day < current_date
    ),
    'd1_retention', case when (select count(*) from d1_cohort) = 0 then null
      else round((select count(*) from d1_returned)::numeric / (select count(*) from d1_cohort), 3) end,
    'd1_sample_size', (select count(*) from d1_cohort),
    'd7_retention', case when (select count(*) from d7_cohort) = 0 then null
      else round((select count(*) from d7_returned)::numeric / (select count(*) from d7_cohort), 3) end,
    'd7_sample_size', (select count(*) from d7_cohort)
  );
$function$;
