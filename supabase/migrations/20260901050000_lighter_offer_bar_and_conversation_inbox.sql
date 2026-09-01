-- Two changes, requested together:
--
-- 1. offer_ready() loosened to match suggest_objective()'s bar (child name +
--    one confirmed situation, plus the existing safety gate). The old bar
--    (3 tried steps + 2 calm nights) meant literally 0 of 328 real followers
--    ever qualified, given how little the seed/harvest loop gets completed —
--    so wiring take_offer_moment() into the main conversation (previous
--    migration) would have fired for nobody. This is a deliberate,
--    explicitly-requested trade: reach over rigor, to test real demand now.
--
-- 2. A conversation inbox: get_conversation_inbox() returns one row per
--    follower who has ever exchanged a real message, ordered by most recent
--    activity, with the timestamp of their latest HUMAN message kept
--    separate from the overall latest message -- so "new" means the parent
--    said something, not that Adam's own proactive send moved them to the
--    top. dashboard_conversation_reads/mark_conversation_read() track when
--    the dashboard last opened each conversation, purely for that badge —
--    it carries no product meaning beyond "somebody on the team saw this".

create or replace function public.offer_ready(p_parent_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'pg_catalog', 'public'
as $function$
declare
  v_sit text; v_name text;
  v_missing text[] := '{}';
begin
  select nullif(btrim(c.name), '') into v_name
  from public.children c where c.follower_id = p_parent_id
  order by c.is_primary desc nulls last, c.created_at limit 1;

  select public.situation_label_ar(s.key) into v_sit
  from public.situations s
  join public.children c2 on c2.id = s.child_id
  where c2.follower_id = p_parent_id and s.status = 'confirmed'
  order by s.evidence_count desc limit 1;

  if v_name is null                then v_missing := v_missing || 'child_name'::text; end if;
  if v_sit is null                 then v_missing := v_missing || 'confirmed_situation'::text; end if;
  if not coalesce(public.commerce_allowed(p_parent_id), true)
                                    then v_missing := v_missing || 'commerce_blocked'::text; end if;

  return jsonb_build_object(
    'ready',   cardinality(v_missing) = 0,
    'missing', to_jsonb(v_missing),
    'child',   v_name,
    'situation', v_sit,
    'fork_ar', case when cardinality(v_missing) = 0 and v_name is not null
                    then 'لاحظنا شيئاً يتكرّر مع ' || v_name || '.' || chr(10) || chr(10)
                      || 'هل نتركه يتكرّر... أم نشتغل عليه حتى يتغيّر؟'
                    else null end);
end;
$function$;

create table if not exists public.dashboard_conversation_reads (
  follower_id uuid primary key references public.followers(id) on delete cascade,
  viewed_at   timestamptz not null default now()
);

create or replace function public.mark_conversation_read(p_follower_id uuid)
returns void
language sql
security definer
set search_path to 'pg_catalog', 'public'
as $function$
  insert into public.dashboard_conversation_reads (follower_id, viewed_at)
  values (p_follower_id, now())
  on conflict (follower_id) do update set viewed_at = now();
$function$;

create or replace function public.get_conversation_inbox()
returns table(
  follower_id            uuid,
  platform_user_id       text,
  first_name             text,
  username               text,
  last_message_at        timestamptz,
  last_message_preview   text,
  last_message_from      text,
  last_human_message_at  timestamptz,
  viewed_at              timestamptz
)
language sql
stable
security definer
set search_path to 'pg_catalog', 'public'
as $function$
  select
    f.id,
    f.platform_user_id,
    f.first_name,
    f.username,
    lm.created_at,
    left(lm.content, 160),
    lm.msg_type,
    lh.created_at,
    dr.viewed_at
  from public.followers f
  join lateral (
    select h.created_at, h.message->>'content' as content, h.message->>'type' as msg_type
    from public.n8n_chat_histories h
    where public.normalise_session_key(h.session_id) = f.platform_user_id
    order by h.created_at desc
    limit 1
  ) lm on true
  left join lateral (
    select h.created_at
    from public.n8n_chat_histories h
    where public.normalise_session_key(h.session_id) = f.platform_user_id
      and h.message->>'type' = 'human'
    order by h.created_at desc
    limit 1
  ) lh on true
  left join public.dashboard_conversation_reads dr on dr.follower_id = f.id
  order by lm.created_at desc;
$function$;
