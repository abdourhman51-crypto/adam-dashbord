-- Brand CRM: manual controls from the dashboard, a per-person timeline, and a lead score.
-- Writes come only through the noor-dashboard edge function (dashboard token) or n8n (noor token).

alter table public.follower_profiles
  add column if not exists nour_paused_until timestamptz,
  add column if not exists tags text[] not null default '{}',
  add column if not exists manual_stage text;

create table if not exists public.crm_notes (
  id               bigserial primary key,
  conversation_id  uuid not null references public.inbox_conversations(id) on delete cascade,
  body             text not null check (length(body) between 1 and 2000),
  created_at       timestamptz not null default now()
);
create index if not exists crm_notes_conv_idx on public.crm_notes (conversation_id, created_at desc);

-- Actions that need Zernio (sending a DM). n8n claims them every minute and reports back.
create table if not exists public.admin_commands (
  id               bigserial primary key,
  kind             text not null check (kind in ('send_dm')),
  conversation_id  uuid not null references public.inbox_conversations(id) on delete cascade,
  payload          jsonb not null default '{}',
  status           text not null default 'pending' check (status in ('pending','running','done','failed')),
  result           text,
  created_at       timestamptz not null default now(),
  done_at          timestamptz
);
create index if not exists admin_commands_pending_idx on public.admin_commands (status, created_at) where status in ('pending','running');

alter table public.crm_notes enable row level security;
alter table public.admin_commands enable row level security;
revoke all on public.crm_notes, public.admin_commands from anon, authenticated;

-- Interest score, 0..100. Signals fade: full weight this week, half next week, gone after a month.
create or replace function public.adam_lead_score(p_conv uuid)
returns int language sql stable set search_path = public as $$
  with p as (select * from follower_profiles where conversation_id = p_conv),
  code as (select noor_conv_code(p_conv) c),
  site as (select bool_or(event = 'view_buy') pr, bool_or(event in ('cta_click','whop_link')) co, max(ts) last_ts
           from site_events where conv_code = (select c from code)),
  fade as (select greatest(0, 1 - extract(epoch from now() - greatest(p.last_seen_at, coalesce(site.last_ts, p.last_seen_at))) / (30 * 86400)) f from p, site)
  select case when (select is_customer from p) then 100 else least(100, round((
      least(coalesce((select buying_signals from p), 0), 3) * 15
    + case when cardinality(coalesce((select products_offered from p), '{}')) > 0 then 10 else 0 end
    + case when (select stage from p) in ('ready','committed') then 15 else 0 end
    + case when (select pr from site) then 15 else 0 end
    + case when (select co from site) then 25 else 0 end
    + least(coalesce((select replies_count from p), 0), 10)
  ) * coalesce((select f from fade), 0))::int) end
$$;

-- One person, everything we know, newest first.
create or replace function public.adam_contact(p_conv uuid)
returns jsonb language sql stable set search_path = public as $$
  with c as (select * from inbox_conversations where id = p_conv),
  code as (select noor_conv_code(p_conv) k),
  tl as (
    select created_at at_, 'in' kind, body text, message_type extra from inbox_messages where conversation_id = p_conv and direction = 'inbound'
    union all
    select coalesce(completed_at, created_at), 'nour', reply_text, null from reply_jobs where conversation_id = p_conv and status = 'sent' and coalesce(reply_text, '') <> ''
    union all
    select created_at, 'note', body, null from crm_notes where conversation_id = p_conv
    union all
    select created_at, 'payment', coalesce(proof_text, ''), status || coalesce(':' || product, '') from payment_approvals where conversation_id = p_conv
    union all
    select created_at, 'cmd', payload->>'text', status from admin_commands where conversation_id = p_conv
    union all
    select min(ts), 'site', regexp_replace(coalesce(page, ''), '^site:', ''), string_agg(distinct event, ',')
    from site_events where conv_code = (select k from code) group by sid, regexp_replace(coalesce(page, ''), '^site:', '')
  )
  select jsonb_build_object(
    'conversation', (select jsonb_build_object('id', id, 'channel', channel, 'name', contact_name, 'username', contact_username,
                      'external_id', external_conversation_id, 'created_at', created_at, 'last_message_at', last_message_at) from c),
    'profile', (select to_jsonb(p) from follower_profiles p where conversation_id = p_conv),
    'score', adam_lead_score(p_conv),
    'code', (select k from code),
    'site', (select jsonb_build_object('visits', count(distinct sid), 'price', bool_or(event = 'view_buy'),
                     'checkout', bool_or(event in ('cta_click','whop_link')), 'bought', bool_or(event in ('purchase','whop_complete')))
             from site_events where conv_code = (select k from code)),
    'timeline', (select coalesce(jsonb_agg(jsonb_build_object('at', at_, 'kind', kind, 'text', left(text, 1200), 'extra', extra) order by at_ desc), '[]')
                 from (select * from tl order by at_ desc limit 150) x)
  )
$$;

-- Dashboard writes. Every action names the conversation; unknown actions do nothing.
create or replace function public.adam_admin(p_action text, p jsonb)
returns jsonb language plpgsql set search_path = public as $$
declare v_conv uuid := nullif(p->>'conversation_id', '')::uuid; v_id bigint;
begin
  if v_conv is null or not exists (select 1 from inbox_conversations where id = v_conv) then
    return jsonb_build_object('ok', false, 'reason', 'unknown_conversation');
  end if;
  insert into follower_profiles (conversation_id, channel, contact_name, contact_username)
  select id, channel, contact_name, contact_username from inbox_conversations where id = v_conv
  on conflict (conversation_id) do nothing;

  if p_action = 'pause' then
    update follower_profiles set nour_paused_until = now() + make_interval(hours => least(greatest(coalesce((p->>'hours')::int, 24), 1), 24 * 365)), updated_at = now()
     where conversation_id = v_conv;
  elsif p_action = 'resume' then
    update follower_profiles set nour_paused_until = null, updated_at = now() where conversation_id = v_conv;
  elsif p_action = 'note' then
    insert into crm_notes (conversation_id, body) values (v_conv, left(btrim(p->>'body'), 2000));
  elsif p_action = 'stage' then
    if coalesce(p->>'stage', '') not in ('', 'cold','warm','ready','committed','customer','freebie','closed') then
      return jsonb_build_object('ok', false, 'reason', 'bad_stage');
    end if;
    update follower_profiles set manual_stage = nullif(p->>'stage', ''), updated_at = now() where conversation_id = v_conv;
  elsif p_action = 'tags' then
    update follower_profiles set tags = coalesce(array(select distinct left(btrim(t), 30) from jsonb_array_elements_text(coalesce(p->'tags', '[]')) t where btrim(t) <> ''), '{}'),
           updated_at = now() where conversation_id = v_conv;
  elsif p_action = 'send_dm' then
    if length(btrim(coalesce(p->>'text', ''))) not between 1 and 990 then
      return jsonb_build_object('ok', false, 'reason', 'bad_text');
    end if;
    insert into admin_commands (kind, conversation_id, payload) values ('send_dm', v_conv, jsonb_build_object('text', btrim(p->>'text')))
    returning id into v_id;
    -- Nour stays quiet for 30 minutes after the founder writes, as with a reply typed in the app.
    update follower_profiles set nour_paused_until = greatest(coalesce(nour_paused_until, now()), now() + interval '30 minutes') where conversation_id = v_conv;
    return jsonb_build_object('ok', true, 'command_id', v_id);
  else
    return jsonb_build_object('ok', false, 'reason', 'unknown_action');
  end if;
  return jsonb_build_object('ok', true);
end $$;

-- n8n side: take pending commands (oldest first), then report each result.
create or replace function public.noor_claim_commands(p_limit int default 10)
returns jsonb language sql set search_path = public as $$
  with picked as (
    update admin_commands a set status = 'running'
     where a.id in (select id from admin_commands where status = 'pending' order by created_at limit greatest(1, least(p_limit, 50)) for update skip locked)
    returning a.*
  )
  select coalesce(jsonb_agg(jsonb_build_object('id', picked.id, 'kind', kind, 'text', payload->>'text',
           'external_conversation_id', c.external_conversation_id, 'channel', c.channel)), '[]')
  from picked join inbox_conversations c on c.id = picked.conversation_id
$$;

create or replace function public.noor_finish_command(p_id bigint, p_ok boolean, p_result text)
returns jsonb language sql set search_path = public as $$
  update admin_commands set status = case when p_ok then 'done' else 'failed' end, result = left(p_result, 500), done_at = now()
   where id = p_id returning jsonb_build_object('ok', true, 'status', status)
$$;

revoke all on function public.adam_lead_score(uuid), public.adam_contact(uuid), public.adam_admin(text, jsonb),
  public.noor_claim_commands(int), public.noor_finish_command(bigint, boolean, text) from public, anon, authenticated;
grant execute on function public.adam_lead_score(uuid), public.adam_contact(uuid), public.adam_admin(text, jsonb),
  public.noor_claim_commands(int), public.noor_finish_command(bigint, boolean, text) to service_role;
