-- One read-only call that returns every number the dashboard shows.
-- Days are bucketed in Algeria time (UTC+1). Service role only.
-- Everyone who has written to Nour, with the profile when there is one, newest first.
create or replace function public.adam_people(p_limit int default 300)
returns jsonb language sql stable set search_path = public as $$
  select coalesce(jsonb_agg(x order by (x->>'last_seen') desc nulls last), '[]') from (
    select jsonb_build_object('id', c.id, 'name', coalesce(c.contact_name, p.contact_name), 'username', coalesce(c.contact_username, p.contact_username),
      'channel', c.channel, 'stage', coalesce(p.manual_stage, p.stage), 'country', p.country, 'problem', p.main_problem,
      'topics', coalesce(p.topics, '{}'), 'objections', coalesce(p.objections, '{}'), 'children', coalesce(p.children, '[]'),
      'offered', coalesce(p.products_offered, '{}'), 'bought', coalesce(p.products_bought, '{}'), 'customer', coalesce(p.is_customer, false),
      'signals', coalesce(p.buying_signals, 0), 'replies', coalesce(p.replies_count, 0), 'summary', p.summary, 'tags', coalesce(p.tags, '{}'),
      'paused', coalesce(p.nour_paused_until > now(), false), 'score', adam_lead_score(c.id),
      'last_seen', coalesce(c.last_message_at, p.last_seen_at, c.created_at)) x
    from inbox_conversations c left join follower_profiles p on p.conversation_id = c.id
    order by coalesce(c.last_message_at, p.last_seen_at, c.created_at) desc nulls last
    limit greatest(1, least(p_limit, 1000))
  ) t
$$;
revoke all on function public.adam_people(int) from public, anon, authenticated;
grant execute on function public.adam_people(int) to service_role;

create or replace function public.noor_dashboard_stats(p_days int default 14)
returns jsonb
language sql
stable
set search_path = public
as $$
with
  tz as (select 'Africa/Algiers'::text z),
  since as (select (date_trunc('day', now() at time zone (select z from tz)) - make_interval(days => greatest(p_days, 1) - 1)) at time zone (select z from tz) t),
  days as (
    select generate_series(date_trunc('day', now() at time zone (select z from tz)) - make_interval(days => greatest(p_days, 1) - 1),
                           date_trunc('day', now() at time zone (select z from tz)), interval '1 day')::date d
  ),
  msg as (select (created_at at time zone (select z from tz))::date d, extract(hour from created_at at time zone (select z from tz))::int h, conversation_id
          from inbox_messages where direction = 'inbound' and created_at >= (select t from since)),
  job as (select (coalesce(completed_at, created_at) at time zone (select z from tz))::date d, status,
                 extract(epoch from (completed_at - due_at)) lag_s
          from reply_jobs where created_at >= (select t from since)),
  conv as (select (created_at at time zone (select z from tz))::date d, channel from inbox_conversations where created_at >= (select t from since)),
  ins as (select (created_at at time zone (select z from tz))::date d, * from conversation_insights where created_at >= (select t from since)),
  prof as (select * from follower_profiles)
select jsonb_build_object(
  'generated_at', now(),
  'days', p_days,
  'totals', jsonb_build_object(
    'conversations_all', (select count(*) from inbox_conversations),
    'conversations_new', (select count(*) from conv),
    'inbound', (select count(*) from msg),
    'active_conversations', (select count(distinct conversation_id) from msg),
    'replies_sent', (select count(*) from job where status = 'sent'),
    'replies_failed', (select count(*) from job where status = 'failed'),
    'grouped_messages', (select count(*) from job where status = 'superseded'),
    'cancelled', (select count(*) from job where status = 'cancelled'),
    'reply_seconds_median', (select round(percentile_cont(0.5) within group (order by lag_s))::int from job where status = 'sent' and lag_s is not null and lag_s >= 0),
    'buying_signals', (select count(*) from ins where buying_signal),
    'escalations', (select count(*) from ins where escalate),
    'payment_proofs', (select count(*) from ins where payment_proof),
    'profiles', (select count(*) from prof),
    'customers', (select count(*) from prof where is_customer),
    'offered', (select count(*) from prof where cardinality(products_offered) > 0),
    'offered_not_bought', (select count(*) from prof where cardinality(products_offered) > 0 and not is_customer)
  ),
  'daily', (select jsonb_agg(jsonb_build_object(
      'd', days.d,
      'inbound', (select count(*) from msg where msg.d = days.d),
      'replies', (select count(*) from job where job.d = days.d and status = 'sent'),
      'new', (select count(*) from conv where conv.d = days.d),
      'signals', (select count(*) from ins where ins.d = days.d and buying_signal),
      'offers', (select count(*) from ins where ins.d = days.d and product_offered is not null)
    ) order by days.d) from days),
  'hours', (select jsonb_agg(jsonb_build_object('h', h, 'n', (select count(*) from msg where msg.h = hs.h)) order by h) from generate_series(0, 23) hs(h)),
  'channels', (select coalesce(jsonb_object_agg(channel, n), '{}') from (select channel, count(*) n from inbox_conversations group by 1) x),
  'stages', (select coalesce(jsonb_object_agg(coalesce(stage, 'unknown'), n), '{}') from (select stage, count(*) n from prof group by 1) x),
  'countries', (select coalesce(jsonb_agg(jsonb_build_object('k', country, 'n', n) order by n desc), '[]') from (select country, count(*) n from prof where country is not null and country <> '' group by 1 order by 2 desc limit 8) x),
  'problems', (select coalesce(jsonb_agg(jsonb_build_object('k', main_problem, 'n', n) order by n desc), '[]') from (select main_problem, count(*) n from prof where main_problem is not null group by 1 order by 2 desc limit 10) x),
  'topics', (select coalesce(jsonb_agg(jsonb_build_object('k', t, 'n', n) order by n desc), '[]') from (select t, count(*) n from prof, unnest(topics) t group by 1 order by 2 desc limit 12) x),
  'objections', (select coalesce(jsonb_agg(jsonb_build_object('k', o, 'n', n) order by n desc), '[]') from (select o, count(*) n from prof, unnest(objections) o group by 1 order by 2 desc limit 8) x),
  'products', (select jsonb_object_agg(p, jsonb_build_object(
      'offered', (select count(*) from prof where p = any(products_offered)),
      'bought', (select count(*) from prof where p = any(products_bought)))) from unnest(array['hodn','inad','cards','21']) p),
  'approvals', jsonb_build_object(
    'pending', (select count(*) from payment_approvals where status = 'pending'),
    'approved', (select count(*) from payment_approvals where status = 'approved'),
    'rejected', (select count(*) from payment_approvals where status = 'rejected'),
    'undelivered', (select count(*) from payment_approvals where status = 'approved' and not delivered),
    'by_product', (select coalesce(jsonb_object_agg(product, n), '{}') from (select product, count(*) n from payment_approvals where status = 'approved' group by 1) x),
    'recent', (select coalesce(jsonb_agg(jsonb_build_object('id', id, 'name', contact_name, 'platform', platform, 'status', status, 'product', product,
                 'suggested', suggested_product, 'delivered', delivered, 'error', delivery_error, 'at', created_at) order by created_at desc), '[]')
               from (select * from payment_approvals order by created_at desc limit 15) x)
  ),
  'followers', adam_people(300)
);
$$;
revoke all on function public.noor_dashboard_stats(int) from public, anon, authenticated;
grant execute on function public.noor_dashboard_stats(int) to service_role;
