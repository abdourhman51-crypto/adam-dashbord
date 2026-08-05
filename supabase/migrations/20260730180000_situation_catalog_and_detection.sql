-- Situation detection. Applied via Supabase migration
-- `situation_catalog_and_detection`.
--
-- situation_catalog   : the CLOSED taxonomy, each key carrying the time
--                       window the rhythm schedules against.
-- commit_situation    : the only way a situation is created. Takes the
--                       window from the catalog, never from the caller,
--                       so no LLM can smuggle in a window that would
--                       misschedule the rhythm. Three independent
--                       observations promote candidate -> confirmed.
-- get_situation_batch : parents with a named child but no confirmed
--                       situation, plus conversation to classify from.
--
-- Keys: sleep(20-22) study(16-18) meal(13-15) screen(16-20) out(16-19) other(20-22)

-- ------------------------------------------------------------
-- RESTORED 2026-08-07 from production via pg_get_functiondef.
--
-- This file was fourteen lines of comment and no SQL. The objects
-- it describes were applied straight to the database and never
-- written down, so the repo could not rebuild them — which meant
-- the offline suite could not test them and a rebuild would have
-- produced a product missing its situation layer entirely.
-- Thirty-four of eighty-eight production functions were in that
-- state; these are the first of them to come home.
-- ------------------------------------------------------------

create table if not exists public.situation_catalog (
  key          text primary key,
  label_ar     text     not null,
  window_start smallint not null,
  window_end   smallint not null,
  hint_ar      text,
  sort_order   integer
);

comment on table public.situation_catalog is
  'The CLOSED taxonomy of situations. commit_situation() takes the time window from here and never from the caller, so no model can smuggle in a window that would misschedule the rhythm.';

insert into public.situation_catalog (key, label_ar, window_start, window_end, hint_ar, sort_order) values
  ('sleep', 'عند النوم',   20, 22, 'رفض النوم، التأخر، الاستيقاظ ليلاً، المقاومة عند وقت السرير', 1),
  ('study', 'عند الدراسة', 16, 18, 'الواجبات، المذاكرة، رفض الجلوس للدراسة بعد المدرسة',        2),
  ('meal',  'عند الأكل',   13, 15, 'رفض الطعام، الانتقائية، المعارك على المائدة',                3),
  ('screen','وقت الشاشة',  16, 20, 'الجهاز، إنهاء الوقت، الغضب عند الإغلاق',                     4),
  ('out',   'عند الخروج',  16, 19, 'الاستعداد للخروج، الانتقالات، مغادرة المكان',                5),
  ('other', 'موقف آخر',    20, 22, 'موقف متكرر لا يندرج تحت ما سبق',                             6)
on conflict (key) do update
  set label_ar     = excluded.label_ar,
      window_start = excluded.window_start,
      window_end   = excluded.window_end,
      hint_ar      = excluded.hint_ar,
      sort_order   = excluded.sort_order;

CREATE OR REPLACE FUNCTION public.commit_situation(p_parent_id uuid, p_child_id uuid, p_key text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
declare
  v_cat public.situation_catalog%rowtype;
  v_id  uuid;
  v_ev  integer;
  v_new boolean := false;
begin
  select * into v_cat from public.situation_catalog where key = p_key;
  if not found then
    return jsonb_build_object('committed', false, 'reason', 'unknown_situation_key');
  end if;

  if p_child_id is null then
    return jsonb_build_object('committed', false, 'reason', 'no_child');
  end if;

  insert into public.situations
    (child_id, parent_id, key, label_ar, window_start, window_end, status, evidence_count)
  values
    (p_child_id, p_parent_id, v_cat.key, v_cat.label_ar,
     v_cat.window_start, v_cat.window_end, 'candidate', 1)
  on conflict (child_id, key) do update
    set evidence_count = public.situations.evidence_count + 1,
        last_observed  = now(),
        updated_at     = now(),
        -- three independent observations promote it to confirmed
        status = case when public.situations.evidence_count + 1 >= 3
                      then 'confirmed' else public.situations.status end
  returning id, evidence_count into v_id, v_ev;

  return jsonb_build_object(
    'committed', true, 'situation_id', v_id, 'key', v_cat.key,
    'evidence_count', v_ev,
    'status', case when v_ev >= 3 then 'confirmed' else 'candidate' end,
    'window', jsonb_build_object('start', v_cat.window_start, 'end', v_cat.window_end));
end;
$function$;

CREATE OR REPLACE FUNCTION public.get_situation_batch(p_limit integer DEFAULT 20)
 RETURNS TABLE(parent_id uuid, child_id uuid, child_name text, conversation text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'public'
AS $function$
with candidates as (
  select f.id as parent_id, c.id as child_id, nullif(btrim(c.name),'') as child_name
  from public.followers f
  join public.children c on c.follower_id = f.id
  where nullif(btrim(c.name),'') is not null
    and not exists (
      select 1 from public.situations s
      where s.child_id = c.id and s.status = 'confirmed')
)
select
  k.parent_id, k.child_id, k.child_name,
  (select string_agg(
       case when h.message->>'type' = 'human' then 'الوالد: ' else 'آدم: ' end
       || left(coalesce(h.message->>'content',''), 400),
       chr(10) order by h.id desc)
   from public.n8n_chat_histories h
   where h.session_id = (select platform_user_id from public.followers where id = k.parent_id)
   limit 1) as conversation
from candidates k
where exists (
  select 1 from public.n8n_chat_histories h2
  where h2.session_id = (select platform_user_id from public.followers where id = k.parent_id))
limit p_limit;
$function$;

revoke all on function public.commit_situation(uuid, uuid, text)  from anon, authenticated, public;
revoke all on function public.get_situation_batch(integer)        from anon, authenticated, public;
grant execute on function public.commit_situation(uuid, uuid, text) to service_role;
grant execute on function public.get_situation_batch(integer)       to service_role;
