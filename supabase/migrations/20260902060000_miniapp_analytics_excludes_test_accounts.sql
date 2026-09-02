-- The rest of the dashboard has always excluded TEST_PLATFORM_USER_IDS
-- ('7377091520','8074049810' -- dashboard/lib/supabase/admin.ts) from every
-- stat; the miniapp analytics RPCs added today did not, so any verification
-- traffic sent through those two sanctioned test followers would silently
-- count as real visitors/sessions on the dashboard. Same five functions,
-- each now filtered to real followers only via a shared CTE.
create or replace function public.get_miniapp_overview()
returns jsonb
language sql
stable
security definer
set search_path to 'pg_catalog', 'public'
as $function$
  with real_events as (
    select e.* from public.miniapp_events e
    join public.followers f on f.id = e.follower_id
    where f.platform_user_id not in ('7377091520', '8074049810')
  )
  select jsonb_build_object(
    'total_visitors', (select count(distinct follower_id) from real_events),
    'visitors_today', (select count(distinct follower_id) from real_events where created_at >= current_date),
    'visitors_7d', (select count(distinct follower_id) from real_events where created_at >= now() - interval '7 days'),
    'visitors_30d', (select count(distinct follower_id) from real_events where created_at >= now() - interval '30 days'),
    'sessions_today', (select count(distinct session_id) from real_events where created_at >= current_date),
    'sessions_7d', (select count(distinct session_id) from real_events where created_at >= now() - interval '7 days'),
    'total_screen_views', (select count(*) from real_events where event_type = 'screen_view'),
    'avg_session_seconds', (
      select coalesce(round(avg(dur)::numeric, 1), 0)
      from (
        select extract(epoch from (max(created_at) - min(created_at))) as dur
        from real_events
        where created_at >= now() - interval '30 days'
        group by session_id
        having count(*) > 1
      ) s
    )
  );
$function$;

create or replace function public.get_miniapp_daily_active(p_days int default 30)
returns table(day date, visitors bigint, sessions bigint, screen_views bigint)
language sql
stable
security definer
set search_path to 'pg_catalog', 'public'
as $function$
  with real_events as (
    select e.* from public.miniapp_events e
    join public.followers f on f.id = e.follower_id
    where f.platform_user_id not in ('7377091520', '8074049810')
  )
  select
    d::date as day,
    coalesce(count(distinct e.follower_id), 0) as visitors,
    coalesce(count(distinct e.session_id), 0) as sessions,
    coalesce(count(*) filter (where e.event_type = 'screen_view'), 0) as screen_views
  from generate_series(current_date - (p_days - 1), current_date, interval '1 day') d
  left join real_events e on e.created_at::date = d::date
  group by d
  order by d;
$function$;

create or replace function public.get_miniapp_screen_performance()
returns table(screen text, views bigint, unique_visitors bigint, avg_seconds numeric, exits bigint, exit_rate numeric)
language sql
stable
security definer
set search_path to 'pg_catalog', 'public'
as $function$
  with real_events as (
    select e.* from public.miniapp_events e
    join public.followers f on f.id = e.follower_id
    where f.platform_user_id not in ('7377091520', '8074049810')
  ),
  sv as (
    select
      session_id, follower_id, screen, created_at,
      row_number() over (partition by session_id order by created_at desc) as rn
    from real_events
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
    from real_events
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

create or replace function public.get_miniapp_top_clicks(p_limit int default 15)
returns table(element text, screen text, clicks bigint)
language sql
stable
security definer
set search_path to 'pg_catalog', 'public'
as $function$
  select e.element, e.screen, count(*) as clicks
  from public.miniapp_events e
  join public.followers f on f.id = e.follower_id
  where e.event_type = 'click' and e.element is not null
    and f.platform_user_id not in ('7377091520', '8074049810')
  group by e.element, e.screen
  order by clicks desc
  limit p_limit;
$function$;

create or replace function public.get_miniapp_retention()
returns jsonb
language sql
stable
security definer
set search_path to 'pg_catalog', 'public'
as $function$
  with real_events as (
    select e.* from public.miniapp_events e
    join public.followers f on f.id = e.follower_id
    where f.platform_user_id not in ('7377091520', '8074049810')
  ),
  first_seen as (
    select follower_id, min(created_at)::date as first_day
    from real_events
    group by follower_id
  ),
  active_today as (
    select distinct follower_id from real_events where created_at >= current_date
  ),
  d1_cohort as (
    select follower_id from first_seen where first_day = current_date - 1
  ),
  d1_returned as (
    select fs.follower_id
    from d1_cohort fs
    join real_events e on e.follower_id = fs.follower_id
    where e.created_at::date = current_date
  ),
  d7_cohort as (
    select follower_id from first_seen where first_day = current_date - 7
  ),
  d7_returned as (
    select fs.follower_id
    from d7_cohort fs
    join real_events e on e.follower_id = fs.follower_id
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
