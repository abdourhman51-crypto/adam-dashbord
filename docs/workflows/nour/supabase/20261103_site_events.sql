-- Brand warehouse, part 1: every adamvoices.site event, mirrored from n8n's hodn_events.
-- Written by the public edge function adam-track (same exposure as the hodn-track webhook);
-- read only through service-role functions.

create table if not exists public.site_events (
  id          bigserial primary key,
  ts          timestamptz not null default now(),
  sid         text not null,
  event       text not null,
  page        text,
  src         text,
  country     text,
  detail      text,
  device      text,
  conv_code   text,            -- dm_<code> in src: the visitor came from a link Nour sent
  dedupe_key  text unique      -- sid|event|ts|page, so a backfill can run twice safely
);
create index if not exists site_events_ts_idx on public.site_events (ts desc);
create index if not exists site_events_sid_idx on public.site_events (sid, ts);
create index if not exists site_events_conv_idx on public.site_events (conv_code) where conv_code is not null;
alter table public.site_events enable row level security;
revoke all on public.site_events from anon, authenticated;

-- Short code Nour appends to links (?src=dm_<code>): first 10 hex chars of the conversation id.
create or replace function public.noor_conv_code(p uuid) returns text language sql immutable as $$
  select left(replace(p::text, '-', ''), 10)
$$;

create or replace function public.adam_track_events(p_rows jsonb)
returns int language plpgsql set search_path = public as $$
declare n int;
begin
  insert into public.site_events (ts, sid, event, page, src, country, detail, device, conv_code, dedupe_key)
  select coalesce(nullif(r->>'ts','')::timestamptz, now()),
         left(r->>'sid', 40), left(r->>'event', 40), left(r->>'page', 80), left(r->>'src', 40),
         left(r->>'country', 10), left(r->>'detail', 200), left(r->>'device', 30),
         substring(r->>'src' from '^dm_([0-9a-f]{10})'),
         left(r->>'sid', 40) || '|' || left(r->>'event', 40) || '|' || coalesce(r->>'ts', '') || '|' || coalesce(left(r->>'page', 80), '')
  from jsonb_array_elements(case when jsonb_typeof(p_rows) = 'array' then p_rows else jsonb_build_array(p_rows) end) r
  where coalesce(r->>'sid', '') <> '' and coalesce(r->>'event', '') <> ''
  on conflict (dedupe_key) do nothing;
  get diagnostics n = row_count;
  return n;
end $$;

-- Site funnel per visitor, same rules as the Telegram report. Each step implies the ones before it.
create or replace function public.adam_site_stats(p_days int default 14)
returns jsonb language sql stable set search_path = public as $$
with
  z as (select 'Africa/Algiers'::text tz),
  since as (select (date_trunc('day', now() at time zone (select tz from z)) - make_interval(days => greatest(p_days,1) - 1)) at time zone (select tz from z) t),
  ev as (
    select * from site_events
    where ts >= (select t from since)
      and coalesce(src,'') !~* '(test|vercel\.(app|com)|eventsmanager)'
      and sid <> 'claude1' and coalesce(page,'') !~ 'test\.html'
  ),
  hooks as (select ts from ev where src = 'whop_webhook' and event ~ 'payment\.succeeded'),
  v as (
    select sid,
      (min(ts) at time zone (select tz from z))::date d,
      coalesce((array_agg(src order by ts) filter (where src ~ '^ig_a[123]$'))[1],
               (array_agg(src order by ts) filter (where event = 'page_view' and coalesce(src,'') <> ''))[1],
               (array_agg(src order by ts) filter (where coalesce(src,'') <> ''))[1], '') src,
      upper(coalesce((array_agg(country order by ts) filter (where coalesce(country,'') <> ''))[1], '?')) country,
      coalesce((array_agg(device order by ts) filter (where coalesce(device,'') <> ''))[1], '?') device,
      (array_agg(conv_code order by ts) filter (where conv_code is not null))[1] conv_code,
      bool_or(event in ('purchase','whop_complete')) buy,
      bool_or(event in ('cta_click','whop_link')) co,
      bool_or(event = 'view_buy') pr,
      bool_or(event in ('engaged','moved','tool_start') or (event = 'scroll' and detail ~ '^\d+$' and detail::int >= 25)) en,
      bool_or(event = 'product_click') pc,
      bool_or(event = 'free_dl') fd,
      bool_or(event = 'wa_click') wa,
      array_agg(distinct regexp_replace(coalesce(page,''), '^site:', '')) filter (where event = 'page_view') pages
    from ev where coalesce(src,'') <> 'whop_webhook' group by sid
  ),
  vf as (
    select *, buy b, (buy or co) c, (buy or co or pr) p, (buy or co or pr or en) e,
      case
        when src ~ '^ig_a[123]$' then 'إعلانات إنستغرام'
        when src ~ '^dm_' or src = 'ig_dm' then 'رسائل نور'
        when src = 'ig_bio' then 'رابط البايو'
        when src ~* 'instagram' then 'منشورات إنستغرام'
        when src ~* 'facebook|^fb' then 'فيسبوك'
        when src = 'wa_channel' then 'قناة واتساب'
        when src ~* 'google' then 'قوقل'
        when src = '' or src ~* 'adamvoices|direct|sanitized' then 'مباشر'
        else src end source,
      case when country in ('WORLD','XX') then '?' else country end ctry
    from v
  ),
  days as (select generate_series(date_trunc('day', now() at time zone (select tz from z)) - make_interval(days => greatest(p_days,1) - 1),
                                  date_trunc('day', now() at time zone (select tz from z)), interval '1 day')::date d),
  tool_ev as (
    select coalesce(nullif(substring(detail from '"tool":"([a-z_]+)"'), ''), substring(page from '/tools/([a-z]+)')) tool, event, sid
    from ev where event in ('tool_start','tool_done')
  ),
  pg as (select unnest(pages) page, sid, e, p, c, b from vf)
select jsonb_build_object(
  'days', (select jsonb_agg(jsonb_build_object('d', days.d,
      'visitors', (select count(*) from vf where vf.d = days.d),
      'engaged', (select count(*) from vf where vf.d = days.d and e),
      'price', (select count(*) from vf where vf.d = days.d and p),
      'checkout', (select count(*) from vf where vf.d = days.d and c),
      'buyers', (select count(*) from vf where vf.d = days.d and b),
      'paid', (select count(*) from hooks where (hooks.ts at time zone (select tz from z))::date = days.d)) order by days.d) from days),
  'funnel', jsonb_build_object('visitors', (select count(*) from vf), 'engaged', (select count(*) from vf where e),
      'price', (select count(*) from vf where p), 'checkout', (select count(*) from vf where c),
      'buyers', (select count(*) from vf where b), 'paid', (select count(*) from hooks)),
  'sources', (select coalesce(jsonb_agg(x order by (x->>'visitors')::int desc), '[]') from (
      select jsonb_build_object('k', source, 'visitors', count(*), 'engaged', count(*) filter (where e), 'price', count(*) filter (where p),
                                'checkout', count(*) filter (where c), 'buyers', count(*) filter (where b)) x
      from vf group by source order by count(*) desc limit 12) s),
  'pages', (select coalesce(jsonb_agg(x order by (x->>'visitors')::int desc), '[]') from (
      select jsonb_build_object('k', nullif(page,''), 'visitors', count(distinct sid), 'engaged', count(distinct sid) filter (where e),
                                'price', count(distinct sid) filter (where p), 'checkout', count(distinct sid) filter (where c),
                                'buyers', count(distinct sid) filter (where b)) x
      from pg where page <> '' group by page order by count(distinct sid) desc limit 15) s),
  'countries', (select coalesce(jsonb_agg(jsonb_build_object('k', ctry, 'n', n) order by n desc), '[]') from (select ctry, count(*) n from vf group by 1 order by 2 desc limit 8) s),
  'devices', (select coalesce(jsonb_agg(jsonb_build_object('k', device, 'n', n) order by n desc), '[]') from (select device, count(*) n from vf group by 1 order by 2 desc limit 5) s),
  'tools', (select coalesce(jsonb_agg(jsonb_build_object('k', tool, 'started', st, 'done', dn) order by st desc), '[]') from (
      select tool, count(distinct sid) filter (where event = 'tool_start') st, count(distinct sid) filter (where event = 'tool_done') dn
      from tool_ev where tool is not null and tool <> 'hero_video' group by tool) s),
  'freeDownloads', (select count(*) from vf where fd),
  'waClicks', (select count(*) from vf where wa),
  'productClicks', (select count(*) from vf where pc),
  'fromNour', (select count(*) from vf where conv_code is not null),
  'events_total', (select count(*) from site_events),
  'last_event_at', (select max(ts) from site_events)
);
$$;

revoke all on function public.adam_track_events(jsonb) from public, anon, authenticated;
revoke all on function public.adam_site_stats(int) from public, anon, authenticated;
grant execute on function public.adam_track_events(jsonb) to service_role;
grant execute on function public.adam_site_stats(int) to service_role;
