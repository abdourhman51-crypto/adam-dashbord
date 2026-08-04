begin;

-- ============================================================
-- get_rhythm_due — the single decision for BOTH halves of the rhythm
-- (n8n architecture §3)
--
-- The Seed and the Harvest share: local time, situation window,
-- strain, quiet hours, paused state, cadence, and the once-per-day
-- ceiling. Splitting them into two workflows would put that logic
-- in two places, and two copies of a rule are one divergence
-- waiting to happen. So the decision is here, and n8n only delivers.
--
-- Returns nothing at all when the answer is "stay silent" — the
-- caller never has to interpret.
-- ============================================================
create or replace function public.get_rhythm_due(p_limit integer default 200)
returns table (
  parent_id      uuid,
  platform_user_id text,
  action         text,
  local_date     date,
  local_hour     smallint,
  child_id       uuid,
  child_name     text,
  situation_id   uuid,
  situation_key  text,
  day_id         uuid,
  seed_text      text,
  grounding      jsonb
)
language sql
stable
security definer
set search_path to 'pg_catalog','public'
as $function$
with base as (
  select
    f.id            as parent_id,
    f.platform_user_id,
    ct.iana_tz,
    (now() at time zone ct.iana_tz)             as local_ts,
    (now() at time zone ct.iana_tz)::date       as local_date,
    extract(hour from (now() at time zone ct.iana_tz))::smallint as local_hour,
    coalesce(ps.level, 1)                       as strain_level
  from public.followers f
  join public.country_timezone ct
    on upper(btrim(f.country)) = ct.code
  left join public.parent_strain ps on ps.parent_id = f.id
  join public.checkin_state cs on cs.parent_id = f.id
  where
    ct.iana_tz is not null
    and coalesce(ps.level, 1) = 1
    and (cs.paused_until is null or cs.paused_until < (now() at time zone ct.iana_tz)::date)
    and coalesce(cs.cadence, 'daily') <> 'stopped'
),
awake as (
  select * from base where local_hour >= 7 and local_hour < 23
),
ctx as (
  select
    a.*,
    ch.id   as child_id,
    nullif(btrim(ch.name),'') as child_name,
    s.id    as situation_id,
    s.key   as situation_key,
    coalesce(s.window_start, 20)::smallint as win_start,
    coalesce(s.window_end,   22)::smallint as win_end,
    d.id    as day_id,
    d.seed_sent_at,
    d.harvest_sent_at,
    d.seed_text
  from awake a
  left join lateral (
    select c.id, c.name from public.children c
    where c.follower_id = a.parent_id
    order by c.is_primary desc nulls last, c.created_at limit 1
  ) ch on true
  left join lateral (
    select s2.id, s2.key, s2.window_start, s2.window_end
    from public.situations s2
    where s2.child_id = ch.id and s2.status in ('candidate','confirmed')
    order by (s2.status='confirmed') desc, s2.evidence_count desc, s2.last_observed desc
    limit 1
  ) s on true
  left join public.daily_logs d
    on d.follower_id = a.parent_id and d.log_date = a.local_date
),
decided as (
  select
    c.*,
    case
      when c.seed_sent_at is not null
       and c.harvest_sent_at is null
       and c.local_hour > c.win_end
        then 'harvest'
      when c.seed_sent_at is null
       and c.local_hour < c.win_start
       and c.local_hour >= 7
        then 'seed'
      else null
    end as action
  from ctx c
)
select
  d.parent_id, d.platform_user_id, d.action, d.local_date, d.local_hour,
  d.child_id, d.child_name, d.situation_id, d.situation_key,
  d.day_id, d.seed_text,
  case when d.action = 'seed' then public.can_ground_seed(d.parent_id) else null end
from decided d
where d.action is not null
  and (d.action <> 'seed'
       or (public.can_ground_seed(d.parent_id)->>'can_ground')::boolean)
order by d.local_hour desc
limit p_limit;
$function$;

comment on function public.get_rhythm_due(integer) is
  'The single decision for both halves of the daily rhythm (n8n arch §3). Returns who is due and for what. Encapsulates local time, situation windows, strain suppression, quiet hours, pause, cadence, the once-per-day ceiling, and the Knowledge gate. n8n branches on the action column and does no deciding of its own. Returns no row when the answer is stay silent.';

revoke all on function public.get_rhythm_due(integer) from anon, authenticated, public;
grant execute on function public.get_rhythm_due(integer) to service_role;

commit;
