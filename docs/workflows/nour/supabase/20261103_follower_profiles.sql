-- Noor: a durable profile per follower, plus one insight row per reply.
-- Project: adam-noor-inbox (vpinaehjfflnrlpfxlko). Written only through the
-- noor-inbox-rpc edge function (service role); no anon/authenticated access.

create table if not exists public.follower_profiles (
  conversation_id        uuid primary key references public.inbox_conversations(id) on delete cascade,
  channel                text,
  external_contact_id    text,
  contact_name           text,
  contact_username       text,
  gender                 text,
  country                text,
  children               jsonb not null default '[]'::jsonb,
  main_problem           text,
  topics                 text[] not null default '{}',
  objections             text[] not null default '{}',
  stage                  text,
  stage_history          jsonb not null default '[]'::jsonb,
  buying_signals         integer not null default 0,
  last_buying_signal_at  timestamptz,
  products_offered       text[] not null default '{}',
  last_offer_at          timestamptz,
  products_bought        text[] not null default '{}',
  is_customer            boolean not null default false,
  payment_proof_at       timestamptz,
  summary                text,
  replies_count          integer not null default 0,
  first_seen_at          timestamptz not null default now(),
  last_seen_at           timestamptz not null default now(),
  updated_at             timestamptz not null default now()
);
comment on table public.follower_profiles is
  'Noor: one durable profile per DM conversation, merged after every reply. Source for prompts, follow-ups and analysis.';

create table if not exists public.conversation_insights (
  id               bigserial primary key,
  conversation_id  uuid not null references public.inbox_conversations(id) on delete cascade,
  created_at       timestamptz not null default now(),
  channel          text,
  user_text        text,
  reply_text       text,
  stage            text,
  buying_signal    boolean,
  payment_proof    boolean,
  escalate         boolean,
  escalate_reason  text,
  analysis         text,
  problem          text,
  topics           text[] not null default '{}',
  objection        text,
  product_offered  text,
  keyword          text,
  human_active     boolean not null default false
);
create index if not exists conversation_insights_conv_idx on public.conversation_insights (conversation_id, created_at desc);
create index if not exists conversation_insights_created_idx on public.conversation_insights (created_at desc);
comment on table public.conversation_insights is
  'Noor: one row per reply — what she said, what Noor read, what was offered. The raw material for content and product analysis.';

alter table public.follower_profiles enable row level security;
alter table public.conversation_insights enable row level security;

-- Merge one reply's reading into the profile. Facts only accumulate: a blank
-- field never erases a known one, arrays are unioned, counters only grow.
create or replace function public.noor_save_profile(p_conversation_id uuid, p_insight jsonb)
returns jsonb
language plpgsql
set search_path = public
as $$
declare
  c        public.inbox_conversations%rowtype;
  v_child  jsonb := nullif(p_insight->'child', 'null'::jsonb);
  v_topics text[] := coalesce(array(select jsonb_array_elements_text(coalesce(p_insight->'topics', '[]'::jsonb))), '{}');
  v_stage  text := nullif(btrim(p_insight->>'stage'), '');
  v_offer  text := nullif(btrim(p_insight->>'product_offered'), '');
  v_obj    text := nullif(btrim(p_insight->>'objection'), '');
  v_signal boolean := coalesce((p_insight->>'buying_signal')::boolean, false);
  v_proof  boolean := coalesce((p_insight->>'payment_proof')::boolean, false);
  v_row    public.follower_profiles%rowtype;
begin
  select * into c from public.inbox_conversations where id = p_conversation_id;
  if not found then
    return jsonb_build_object('ok', false, 'reason', 'unknown_conversation');
  end if;

  insert into public.conversation_insights
    (conversation_id, channel, user_text, reply_text, stage, buying_signal, payment_proof, escalate,
     escalate_reason, analysis, problem, topics, objection, product_offered, keyword, human_active)
  values
    (p_conversation_id, c.channel, left(p_insight->>'user_text', 4000), left(p_insight->>'reply_text', 4000), v_stage,
     v_signal, v_proof, coalesce((p_insight->>'escalate')::boolean, false), nullif(p_insight->>'escalate_reason', ''),
     left(p_insight->>'analysis', 2000), nullif(btrim(p_insight->>'problem'), ''), v_topics, v_obj, v_offer,
     nullif(btrim(p_insight->>'keyword'), ''), coalesce((p_insight->>'human_active')::boolean, false));

  insert into public.follower_profiles (conversation_id, channel, external_contact_id, contact_name, contact_username)
  values (p_conversation_id, c.channel, c.external_contact_id, c.contact_name, c.contact_username)
  on conflict (conversation_id) do nothing;

  update public.follower_profiles p set
    contact_name     = coalesce(c.contact_name, p.contact_name),
    contact_username = coalesce(c.contact_username, p.contact_username),
    gender           = case when coalesce(p_insight->>'gender', '') in ('', 'unknown') then p.gender else p_insight->>'gender' end,
    country          = coalesce(nullif(btrim(p_insight->>'country'), ''), p.country),
    main_problem     = coalesce(nullif(btrim(p_insight->>'problem'), ''), p.main_problem),
    children = case
      when v_child is null or coalesce(nullif(btrim(v_child->>'name'), ''), nullif(btrim(v_child->>'age'), '')) is null then p.children
      when exists (select 1 from jsonb_array_elements(p.children) e
                   where coalesce(e->>'name', '') = coalesce(v_child->>'name', '')
                     and coalesce(v_child->>'name', '') <> '')
        then (select jsonb_agg(case when coalesce(e->>'name', '') = coalesce(v_child->>'name', '')
                                    then e || jsonb_strip_nulls(v_child) else e end)
              from jsonb_array_elements(p.children) e)
      else p.children || jsonb_build_array(jsonb_strip_nulls(v_child))
    end,
    topics           = (select coalesce(array_agg(distinct t), '{}') from unnest(p.topics || v_topics) t where btrim(t) <> ''),
    objections       = case when v_obj is null or v_obj = any(p.objections) then p.objections else p.objections || v_obj end,
    stage_history    = case when v_stage is not null and v_stage is distinct from p.stage
                            then p.stage_history || jsonb_build_object('stage', v_stage, 'at', now()) else p.stage_history end,
    stage            = coalesce(v_stage, p.stage),
    buying_signals   = p.buying_signals + case when v_signal then 1 else 0 end,
    last_buying_signal_at = case when v_signal then now() else p.last_buying_signal_at end,
    products_offered = case when v_offer is null or v_offer = any(p.products_offered) then p.products_offered else p.products_offered || v_offer end,
    last_offer_at    = case when v_offer is not null then now() else p.last_offer_at end,
    payment_proof_at = case when v_proof then now() else p.payment_proof_at end,
    summary          = coalesce(nullif(btrim(p_insight->>'summary'), ''), p.summary),
    replies_count    = p.replies_count + 1,
    last_seen_at     = now(),
    updated_at       = now()
  where p.conversation_id = p_conversation_id
  returning * into v_row;

  return jsonb_build_object('ok', true, 'profile', to_jsonb(v_row));
end;
$$;

create or replace function public.noor_get_profile(p_conversation_id uuid)
returns jsonb
language sql
stable
set search_path = public
as $$
  select coalesce(
    (select jsonb_build_object('ok', true, 'profile', to_jsonb(p)) from public.follower_profiles p where p.conversation_id = p_conversation_id),
    jsonb_build_object('ok', true, 'profile', null));
$$;

-- Marks a purchase confirmed by the founder (payment approval flow).
create or replace function public.noor_mark_customer(p_conversation_id uuid, p_product text)
returns jsonb
language plpgsql
set search_path = public
as $$
declare v_row public.follower_profiles%rowtype;
begin
  insert into public.follower_profiles (conversation_id) values (p_conversation_id) on conflict do nothing;
  update public.follower_profiles set
    is_customer = true,
    products_bought = case when p_product is null or p_product = any(products_bought) then products_bought else products_bought || p_product end,
    stage = 'customer',
    stage_history = stage_history || jsonb_build_object('stage', 'customer', 'at', now()),
    updated_at = now()
  where conversation_id = p_conversation_id
  returning * into v_row;
  return jsonb_build_object('ok', true, 'profile', to_jsonb(v_row));
end;
$$;

revoke all on function public.noor_save_profile(uuid, jsonb) from public, anon, authenticated;
revoke all on function public.noor_get_profile(uuid) from public, anon, authenticated;
revoke all on function public.noor_mark_customer(uuid, text) from public, anon, authenticated;
grant execute on function public.noor_save_profile(uuid, jsonb) to service_role;
grant execute on function public.noor_get_profile(uuid) to service_role;
grant execute on function public.noor_mark_customer(uuid, text) to service_role;
revoke all on public.follower_profiles, public.conversation_insights from anon, authenticated;
