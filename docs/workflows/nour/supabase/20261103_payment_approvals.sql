-- Noor: founder approval of a payment receipt from Telegram buttons.
-- Each receipt gets a random one-time token (the row id). A Telegram URL button
-- carries the token; tapping it decides the row once, and only once.

create table if not exists public.payment_approvals (
  id                      uuid primary key default gen_random_uuid(),
  conversation_id         uuid references public.inbox_conversations(id) on delete set null,
  external_conversation_id text not null,
  account_id              text not null,
  platform                text,
  contact_name            text,
  proof_text              text,
  images                  text[] not null default '{}',
  suggested_product       text,
  status                  text not null default 'pending' check (status in ('pending','approved','rejected')),
  product                 text,
  delivered               boolean not null default false,
  delivery_error          text,
  created_at              timestamptz not null default now(),
  decided_at              timestamptz
);
create index if not exists payment_approvals_status_idx on public.payment_approvals (status, created_at desc);
alter table public.payment_approvals enable row level security;
revoke all on public.payment_approvals from anon, authenticated;

create or replace function public.noor_create_approval(p jsonb)
returns jsonb language plpgsql set search_path = public as $$
declare v_id uuid;
begin
  insert into public.payment_approvals
    (conversation_id, external_conversation_id, account_id, platform, contact_name, proof_text, images, suggested_product)
  values
    (nullif(p->>'conversation_id','')::uuid, p->>'external_conversation_id', p->>'account_id', p->>'platform',
     p->>'contact_name', left(p->>'proof_text', 2000),
     coalesce(array(select jsonb_array_elements_text(coalesce(p->'images','[]'::jsonb))), '{}'),
     nullif(p->>'suggested_product',''))
  returning id into v_id;
  return jsonb_build_object('ok', true, 'token', v_id);
end $$;

-- Decides a pending approval exactly once. A second tap returns ok=false, already=true.
create or replace function public.noor_decide_approval(p_token uuid, p_decision text, p_product text)
returns jsonb language plpgsql set search_path = public as $$
declare r public.payment_approvals%rowtype;
begin
  if p_decision not in ('approved','rejected') then
    return jsonb_build_object('ok', false, 'reason', 'bad_decision');
  end if;
  if p_decision = 'approved' and coalesce(p_product,'') not in ('hodn','inad','cards') then
    return jsonb_build_object('ok', false, 'reason', 'bad_product');
  end if;
  update public.payment_approvals
     set status = p_decision, product = case when p_decision = 'approved' then p_product end, decided_at = now()
   where id = p_token and status = 'pending'
  returning * into r;
  if not found then
    select * into r from public.payment_approvals where id = p_token;
    return jsonb_build_object('ok', false, 'already', found, 'status', r.status, 'product', r.product);
  end if;
  if p_decision = 'approved' and r.conversation_id is not null then
    perform public.noor_mark_customer(r.conversation_id, p_product);
  end if;
  return jsonb_build_object('ok', true, 'approval', to_jsonb(r));
end $$;

create or replace function public.noor_mark_delivered(p_token uuid, p_error text)
returns jsonb language sql set search_path = public as $$
  update public.payment_approvals set delivered = (p_error is null or p_error = ''), delivery_error = nullif(p_error,'')
   where id = p_token returning jsonb_build_object('ok', true, 'delivered', delivered);
$$;

revoke all on function public.noor_create_approval(jsonb) from public, anon, authenticated;
revoke all on function public.noor_decide_approval(uuid, text, text) from public, anon, authenticated;
revoke all on function public.noor_mark_delivered(uuid, text) from public, anon, authenticated;
grant execute on function public.noor_create_approval(jsonb) to service_role;
grant execute on function public.noor_decide_approval(uuid, text, text) to service_role;
grant execute on function public.noor_mark_delivered(uuid, text) to service_role;
