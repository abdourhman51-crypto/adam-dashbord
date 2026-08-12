-- The thirteen functions that live only in the database
--
-- CORRECTION, and it matters. docs/what-is-missing.md §6b said "34 of 88
-- production functions have no source in this repo". That number was wrong. It
-- came from diffing production against the OFFLINE TEST CHAIN — the 35 migration
-- files the harness loads on top of fixture_minimal.sql — and not against the
-- repository, which holds 64. Everything the chain does not load counted as
-- absent when it was merely untested. Seventeen of the "missing" functions were
-- in git the whole time: the whole child-record and erasure family, the checkin
-- family, get_pricing, the two chat-history guards, record_mirror_delivered,
-- derive_aha_class, jsonb_text_values, commit_child_name_by_platform.
--
-- Re-checked on 2026-08-07 against all 64 migrations, name by name. Thirteen
-- functions genuinely have no source anywhere in this repository, and they are
-- restored below, read out of production with pg_get_functiondef. (Twelve were
-- found by that pass; get_agent_context was found by the thirteenth thing —
-- actually trying the rebuild, which is the only check that cannot be fooled.)
--
-- They are, in one sentence each: the two writers W2 runs (writer_commit,
-- _ensure_child) and its queue (get_extraction_batch); the free tier's light
-- memory (get_heart_batch, heart_commit) and the history reader all of it goes
-- through (get_conversation_for); the free session clock (get_free_session_state)
-- and the message cap (check_daily_message_cap); the pre-commit_child_name
-- writer W2 still calls (write_child_name); the keyboard's one changing item
-- (surface_changing_item); the legacy end-of-subscription reset (return_to_free);
-- and set_updated_at, which eight tables hang a trigger off; plus
-- get_agent_context, which assembles everything ADAM knows about one family
-- into the paid prompt.
--
-- One deliberate departure from the production text: return_to_free's Arabic
-- comments are mojibake in production (UTF-8 bytes stored as latin-1) and its
-- body is CRLF. The logic is untouched; the comments are written here in
-- readable Arabic and the line endings are LF. Restoring garbage into the repo
-- would defeat the point of restoring it. Nothing else differs — where a body
-- looks wrong it is left wrong on purpose and noted in docs/what-is-missing.md,
-- so the fix is a visible change and not a silent edit smuggled in under the
-- word "restore".
--
-- Dated before week 0, alongside the tables baseline. These functions predate
-- this repository exactly as those tables do, and week 0 itself pins their
-- search_path — so a rebuild that met them at the end would fail at the
-- beginning. See docs/what-is-missing.md §6b.

begin;

-- ── set_updated_at, and the triggers that hang off it ─────────────────────────

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path to 'pg_catalog', 'public'
as $fn$
begin
  new.updated_at = now();
  return new;
end;
$fn$;

-- ── Children, names, and the extraction writer (W2) ───────────────────────────

-- Resolves a child by name, else the primary child, else any child, else a
-- placeholder. Never invents a second sibling out of a missing name.
create or replace function public._ensure_child(p_follower_id uuid, p_name text)
returns uuid
language plpgsql
set search_path to 'pg_catalog', 'public'
as $fn$
declare
  v_id uuid;
  v_name text := nullif(trim(coalesce(p_name,'')),'');
begin
  if v_name is not null then
    insert into children(follower_id, name)
    values (p_follower_id, v_name)
    on conflict (follower_id, name) do update set updated_at = now()
    returning id into v_id;
    return v_id;
  end if;

  -- بلا اسم: الطفل الأساسي أولاً، ثم أي طفل، ثم إنشاء افتراضي
  select id into v_id from children
   where follower_id = p_follower_id
   order by is_primary desc, created_at asc limit 1;
  if v_id is not null then return v_id; end if;

  insert into children(follower_id, name, is_primary)
  values (p_follower_id, 'الطفل', true)
  on conflict (follower_id, name) do update set updated_at = now()
  returning id into v_id;
  return v_id;
end $fn$;

-- The pre-commit_child_name writer, still called by W2. A recorded name is never
-- replaced by a new inference, and back-linking of old rows happens only when
-- there is exactly one child, so a sibling's nights are never reassigned.
create or replace function public.write_child_name(p_platform_user_id text, p_name text)
returns void
language plpgsql
security definer
set search_path to 'pg_catalog', 'public'
as $fn$
declare
  v_follower_id uuid;
  v_child_id uuid;
  v_child_count int;
begin
  select id into v_follower_id from followers where platform_user_id = p_platform_user_id;
  if v_follower_id is null then
    return;
  end if;

  -- لا نبدّل اسماً مسجّلاً باستنتاج جديد
  if exists (select 1 from children
             where follower_id = v_follower_id and name is not null and name <> '') then
    return;
  end if;

  if exists (select 1 from children where follower_id = v_follower_id) then
    update children set name = p_name, updated_at = now()
    where follower_id = v_follower_id and (name is null or name = '')
    returning id into v_child_id;
  else
    insert into children (follower_id, name, is_primary)
    values (v_follower_id, p_name, true)
    returning id into v_child_id;
  end if;

  -- ربط رجعي: يُطبَّق فقط إن كان لهذا المربّي طفل واحد (نسبة مؤكّدة)
  select count(*) into v_child_count from children where follower_id = v_follower_id;
  if v_child_count = 1 and v_child_id is not null then
    update daily_logs   set child_id = v_child_id
      where follower_id = v_follower_id and child_id is null;
    update weekly_plans set child_id = v_child_id
      where follower_id = v_follower_id and child_id is null;
  end if;
end;
$fn$;

-- Session keys drifted three ways over the product's life ('123', '123_s4',
-- '=123'). Every reader of the history has to accept all three or it silently
-- reads an empty conversation.
create or replace function public.get_conversation_for(p_platform_user_id text)
returns table(id integer, session_id text, message jsonb, created_at timestamptz)
language sql
stable security definer
set search_path to 'public'
as $fn$
    select h.id,
           h.session_id::text,
           h.message,
           h.created_at
      from n8n_chat_histories h
     where h.session_id = p_platform_user_id
        or h.session_id like p_platform_user_id || '\_s%'
        or h.session_id = '=' || p_platform_user_id
     order by h.id asc;
$fn$;

-- W2's queue: every paid parent with messages newer than the snapshot they were
-- last summarised from. max_history_id is returned so writer_commit can move the
-- watermark to exactly what was read, not to "now".
create or replace function public.get_extraction_batch(p_max_messages integer default 80)
returns table(follower_id uuid, platform_user_id text, first_name text,
              snapshot_text text, known_children jsonb, known_patterns jsonb,
              conversation jsonb, max_history_id integer)
language sql
stable
set search_path to 'pg_catalog', 'public'
as $fn$
  select
    f.id,
    f.platform_user_id,
    coalesce(f.first_name,''),
    coalesce(s.snapshot_text,''),
    coalesce((select jsonb_agg(jsonb_build_object('name', c.name, 'gender', c.gender, 'age_note', c.age_note))
              from children c where c.follower_id = f.id), '[]'::jsonb),
    coalesce((select jsonb_agg(jsonb_build_object('pattern_label', p.pattern_label, 'status', p.status))
              from child_patterns p where p.follower_id = f.id), '[]'::jsonb),
    coalesce((select jsonb_agg(jsonb_build_object('role', t.role, 'content', t.content) order by t.id)
              from (select h.id,
                           case when h.message->>'type' = 'human' then 'الأم' else 'آدم' end as role,
                           h.message->>'content' as content
                    from n8n_chat_histories h
                    where (h.session_id = f.platform_user_id or h.session_id like f.platform_user_id || '\_s%')
                      and h.id > coalesce(nullif(s.built_from->>'last_history_id','')::int, 0)
                    order by h.id asc
                    limit p_max_messages) t), '[]'::jsonb),
    coalesce((select max(t2.id)
              from (select h.id
                    from n8n_chat_histories h
                    where (h.session_id = f.platform_user_id or h.session_id like f.platform_user_id || '\_s%')
                      and h.id > coalesce(nullif(s.built_from->>'last_history_id','')::int, 0)
                    order by h.id asc
                    limit p_max_messages) t2), 0)
  from followers f
  left join memory_snapshots s on s.follower_id = f.id
  where f.funnel_stage = 'paid_active'
    and exists (select 1 from n8n_chat_histories h
                where (h.session_id = f.platform_user_id or h.session_id like f.platform_user_id || '\_s%')
                  and h.id > coalesce(nullif(s.built_from->>'last_history_id','')::int, 0));
$fn$;

-- W2's writer. Everything it takes is model output, so every field is trimmed,
-- every enum is clamped to a known value, and anything blank is skipped rather
-- than written as an empty string over something true.
create or replace function public.writer_commit(
  p_follower_id uuid, p_last_history_id integer, p_payload jsonb)
returns void
language plpgsql
set search_path to 'pg_catalog', 'public'
as $fn$
declare
  ch jsonb; ev jsonb; pt jsonb;
  v_child_id uuid; v_name text; v_snap text; v_sc boolean;
  v_placeholder_id uuid;
begin
  -- children
  for ch in select * from jsonb_array_elements(coalesce(p_payload->'children','[]'::jsonb)) loop
    v_name := nullif(trim(ch->>'name'),'');
    if v_name is null then continue; end if;

    -- ترقية الطفل الافتراضي: إن وُجد "الطفل" ولا يوجد صف بهذا الاسم بعد → أعد تسميته
    if v_name <> 'الطفل' then
      select id into v_placeholder_id from children
       where follower_id = p_follower_id and name = 'الطفل'
         and not exists (select 1 from children c2 where c2.follower_id = p_follower_id and c2.name = v_name);
      if v_placeholder_id is not null then
        update children set name = v_name, updated_at = now() where id = v_placeholder_id;
      end if;
    end if;

    insert into children(follower_id, name, gender, age_note, temperament)
    values (p_follower_id, v_name, nullif(trim(ch->>'gender'),''), nullif(trim(ch->>'age_note'),''), nullif(trim(ch->>'temperament'),''))
    on conflict (follower_id, name) do update
      set gender      = coalesce(excluded.gender, children.gender),
          age_note    = coalesce(excluded.age_note, children.age_note),
          temperament = coalesce(excluded.temperament, children.temperament),
          updated_at  = now();
  end loop;

  -- memory events — لا يتم أبداً: _ensure_child دائماً
  for ev in select * from jsonb_array_elements(coalesce(p_payload->'events','[]'::jsonb)) loop
    if nullif(trim(ev->>'title'),'') is null then continue; end if;
    v_child_id := public._ensure_child(p_follower_id, ev->>'child_name');
    insert into memory_events(follower_id, child_id, event_type, title, summary, emotional_weight, occurred_at, source)
    values (
      p_follower_id, v_child_id,
      case when ev->>'event_type' in ('win','breakthrough','setback','disclosure','milestone','pattern_change')
           then ev->>'event_type' else 'other' end,
      trim(ev->>'title'),
      nullif(trim(ev->>'summary'),''),
      least(5, greatest(1, coalesce(nullif(ev->>'emotional_weight','')::int, 3))),
      now(), 'agent_extraction');
    if ev->>'event_type' = 'breakthrough' then
      update plan_sessions set has_breakthrough = true, updated_at = now()
       where follower_id = p_follower_id;
    end if;
  end loop;

  -- patterns — نفس الحماية
  for pt in select * from jsonb_array_elements(coalesce(p_payload->'patterns','[]'::jsonb)) loop
    if nullif(trim(pt->>'pattern_label'),'') is null then continue; end if;
    v_child_id := public._ensure_child(p_follower_id, pt->>'child_name');
    insert into child_patterns(follower_id, child_id, pattern_label, description, status, evidence_count, first_observed, last_observed)
    values (
      p_follower_id, v_child_id, trim(pt->>'pattern_label'),
      nullif(trim(pt->>'description'),''),
      case when pt->>'status' in ('active','improving','resolved','dormant')
           then pt->>'status' else 'active' end,
      1, now(), now())
    on conflict (follower_id, pattern_label) do update
      set description    = coalesce(excluded.description, child_patterns.description),
          status         = excluded.status,
          evidence_count = child_patterns.evidence_count + 1,
          child_id       = coalesce(child_patterns.child_id, excluded.child_id),
          last_observed  = now(),
          updated_at     = now();
  end loop;

  -- daily log
  if nullif(trim(p_payload->'daily_log'->>'summary'),'') is not null then
    v_sc := case when p_payload->'daily_log'->>'step_completed' in ('true','false')
                 then (p_payload->'daily_log'->>'step_completed')::boolean else null end;
    insert into daily_logs(follower_id, log_date, summary, guardian_mood, step_given, step_completed)
    values (
      p_follower_id, current_date,
      trim(p_payload->'daily_log'->>'summary'),
      nullif(trim(p_payload->'daily_log'->>'guardian_mood'),''),
      nullif(trim(p_payload->'daily_log'->>'step_given'),''),
      v_sc)
    on conflict (follower_id, log_date) do update
      set summary        = excluded.summary,
          guardian_mood  = coalesce(excluded.guardian_mood, daily_logs.guardian_mood),
          step_given     = coalesce(excluded.step_given, daily_logs.step_given),
          step_completed = coalesce(excluded.step_completed, daily_logs.step_completed),
          updated_at     = now();
  end if;

  -- snapshot
  v_snap := nullif(trim(p_payload->>'snapshot_text'),'');
  insert into memory_snapshots(follower_id, snapshot_text, built_from, updated_at)
  values (p_follower_id, coalesce(v_snap,''),
          jsonb_build_object('source','machine_3','at',now(),'last_history_id',p_last_history_id), now())
  on conflict (follower_id) do update
    set snapshot_text = coalesce(nullif(trim(excluded.snapshot_text),''), memory_snapshots.snapshot_text),
        built_from    = jsonb_build_object('source','machine_3','at',now(),
                          'last_history_id', greatest(p_last_history_id,
                            coalesce(nullif(memory_snapshots.built_from->>'last_history_id','')::int, 0))),
        updated_at    = now();
end $fn$;

-- Everything ADAM knows about one family, assembled into the paid prompt: the
-- day counter, the compressed snapshot, the children, the unresolved patterns,
-- the five heaviest moments and the last three days. Resolved patterns are left
-- out on purpose — a family should not keep meeting what they already fixed.
create or replace function public.get_agent_context(p_follower_id uuid)
returns text
language plpgsql
stable
set search_path to 'pg_catalog', 'public'
as $fn$
declare
  v_out text := '';
  v_snap text;
  v_children text;
  v_patterns text;
  v_events text;
  v_logs text;
  v_day int;
  v_days_left int;
begin
  -- عداد الأيام
  select ps.current_day,
         greatest(0, extract(day from f.subscription_expires_at - now())::int)
    into v_day, v_days_left
  from followers f
  left join plan_sessions ps on ps.follower_id = f.id
  where f.id = p_follower_id;

  v_out := 'PLAN_DAY: ' || coalesce(v_day::text,'?')
        || E'\nDAYS_LEFT: ' || coalesce(v_days_left::text,'?');

  -- الملخص المضغوط
  select snapshot_text into v_snap
  from memory_snapshots where follower_id = p_follower_id and char_count > 0;
  if v_snap is not null then
    v_out := v_out || E'\n\n== SUMMARY ==\n' || v_snap;
  end if;

  -- الأطفال
  select string_agg(
    '- ' || name
    || coalesce(' ('||gender||')','')
    || coalesce(', '||age_note,'')
    || coalesce(', طبع: '||temperament,''), E'\n')
  into v_children from children where follower_id = p_follower_id;
  if v_children is not null then
    v_out := v_out || E'\n\n== CHILDREN ==\n' || v_children;
  end if;

  -- الأنماط النشطة (غير المحلولة)
  select string_agg(
    '- ['||status||' x'||evidence_count||'] '||pattern_label
    || coalesce(': '||description,''), E'\n')
  into v_patterns from child_patterns
  where follower_id = p_follower_id and status <> 'resolved';
  if v_patterns is not null then
    v_out := v_out || E'\n\n== PATTERNS ==\n' || v_patterns;
  end if;

  -- آخر 5 أحداث مهمة (وزن شعوري >= 3)
  select string_agg(line, E'\n') into v_events from (
    select '- ['||event_type||', '||to_char(occurred_at,'MM/DD')||'] '||title
           || coalesce(': '||summary,'') as line
    from memory_events
    where follower_id = p_follower_id and emotional_weight >= 3
    order by occurred_at desc limit 5
  ) t;
  if v_events is not null then
    v_out := v_out || E'\n\n== KEY_MOMENTS ==\n' || v_events;
  end if;

  -- آخر 3 أيام
  select string_agg(line, E'\n') into v_logs from (
    select '- ['||log_date||'] '||coalesce(summary,'')
           || coalesce(' | خطوة: '||step_given,'')
           || case step_completed when true then ' (نُفذت)' when false then ' (لم تُنفذ)' else '' end as line
    from daily_logs
    where follower_id = p_follower_id
    order by log_date desc limit 3
  ) t;
  if v_logs is not null then
    v_out := v_out || E'\n\n== RECENT_DAYS ==\n' || v_logs;
  end if;

  return v_out;
end $fn$;

-- ── The light memory (free tier) ──────────────────────────────────────────────

-- The free tier's queue: free parents whose light memory is missing or older
-- than their newest message. Ordered oldest-memory-first so nobody starves.
create or replace function public.get_heart_batch(p_limit integer default 40)
returns table(platform_user_id text, first_name text, conversation text, light_memory text)
language plpgsql
stable security definer
set search_path to 'public'
as $fn$
declare
    f         record;
    m         record;
    v_lines   text[];
    v_text    text;
    v_latest  timestamptz;
    v_count   integer;
    v_content text;
    v_reply   text;
    v_emitted integer := 0;
begin
    for f in
        select fo.platform_user_id        as pid,
               fo.first_name              as fname,
               fo.light_memory            as lm,
               fo.light_memory_updated_at as lmu
          from followers fo
         where fo.funnel_stage = 'free_conversation'
         order by fo.light_memory_updated_at asc nulls first,
                  fo.platform_user_id
    loop
        exit when v_emitted >= greatest(coalesce(p_limit, 40), 1);

        select max(c.created_at), count(*)
          into v_latest, v_count
          from get_conversation_for(f.pid) c;

        if v_count = 0 then
            continue;
        end if;

        -- stale only: no memory yet, or newest message newer than the memory
        if not (f.lm is null
                or v_latest > coalesce(f.lmu, '-infinity'::timestamptz)) then
            continue;
        end if;

        v_lines := array[]::text[];

        for m in
            select s.id, s.message
              from (select c.id, c.message
                      from get_conversation_for(f.pid) c
                     order by c.id desc
                     limit 60) s
             order by s.id asc
        loop
            if m.message->>'type' = 'human' then
                v_lines := v_lines || ('الأم: ' || btrim(coalesce(m.message->>'content', '')));
            elsif m.message->>'type' = 'ai' then
                v_content := coalesce(m.message->>'content', '');
                v_reply   := null;
                begin
                    if btrim(v_content) like '{%' then
                        v_reply := (v_content::jsonb)->>'reply';
                    end if;
                exception when others then
                    v_reply := null;
                end;
                v_lines := v_lines || ('آدم: ' || btrim(coalesce(v_reply, v_content)));
            end if;
        end loop;

        v_text := array_to_string(v_lines, E'\n');
        if length(v_text) > 7000 then
            v_text := right(v_text, 7000);
        end if;

        platform_user_id := f.pid;
        first_name       := coalesce(f.fname, '');
        conversation     := v_text;
        light_memory     := f.lm;
        v_emitted        := v_emitted + 1;
        return next;
    end loop;
end;
$fn$;

-- An empty extraction must never overwrite a real memory, and must not stamp the
-- freshness clock either — otherwise the parent is skipped forever after one bad
-- run. All five fields blank means: write nothing, try again next cycle.
create or replace function public.heart_commit(p_platform_user_id text, p_light_memory jsonb)
returns boolean
language plpgsql
security definer
set search_path to 'public'
as $fn$
declare
    v_has_content boolean := false;
    v_updated     integer := 0;
    k             text;
    v             text;
begin
    -- defensive: bad input never writes
    if p_platform_user_id is null
       or p_light_memory is null
       or jsonb_typeof(p_light_memory) <> 'object' then
        return false;
    end if;

    -- is there at least one field with real content?
    foreach k in array array['child_name','core_pain','emotional_state','last_win','continuity']
    loop
        v := btrim(coalesce(p_light_memory->>k, ''));
        if v <> '' then
            v_has_content := true;
        end if;
    end loop;

    -- all five blank -> skip entirely.
    -- no write, no timestamp: freshness gate stays OPEN so she is re-attempted
    -- next cycle once she actually says something. This also enforces
    -- "never overwrite a good memory with an empty one".
    if not v_has_content then
        return false;
    end if;

    -- writes ONLY these two columns, on this one follower
    update followers
       set light_memory            = p_light_memory::text,
           light_memory_updated_at = now()
     where platform_user_id = p_platform_user_id;

    get diagnostics v_updated = row_count;
    return v_updated > 0;
end;
$fn$;

-- ── The free session clock, and the cap ───────────────────────────────────────

-- A "session" is a gap, not a clock: more than p_session_gap_hours of silence
-- starts a new one. Returning after a gap is also what makes a parent golden,
-- because coming back twice is the only unfaked signal of value in the free tier.
create or replace function public.get_free_session_state(
  p_platform_user_id text, p_session_gap_hours numeric default 8)
returns table(is_new_session boolean, session_number integer, dynamic_session_id text,
              session_anchor_id bigint, hours_since_last numeric, session_turn integer)
language plpgsql
security definer
set search_path to 'public'
as $fn$
declare
    v_prev_last_seen timestamptz;
    v_prev_anchor    bigint;
    v_prev_turns     integer;
    v_prev_sessnum   integer;
    v_current_max_id bigint;
    v_is_new         boolean;
    v_gap_hours      numeric;
begin
    select coalesce(max(id), 0)
      into v_current_max_id
      from n8n_chat_histories
     where session_id = p_platform_user_id
        or session_id = '=' || p_platform_user_id;

    select st.last_seen_at, st.session_anchor_id, st.session_msg_turns, st.session_number
      into v_prev_last_seen, v_prev_anchor, v_prev_turns, v_prev_sessnum
      from session_tracker st
     where st.platform_user_id = p_platform_user_id;

    if v_prev_last_seen is null then
        v_is_new       := true;
        v_gap_hours    := null;
        v_prev_sessnum := 0;
    else
        v_gap_hours := extract(epoch from (now() - v_prev_last_seen)) / 3600.0;
        v_is_new    := v_gap_hours > p_session_gap_hours;
    end if;

    if v_is_new then
        v_prev_anchor  := v_current_max_id;
        v_prev_turns   := 0;
        v_prev_sessnum := v_prev_sessnum + 1;
    end if;

    v_prev_turns := v_prev_turns + 1;

    insert into session_tracker as st (
        platform_user_id, session_anchor_id, session_started_at,
        last_seen_at, session_msg_turns, session_number
    )
    values (
        p_platform_user_id, v_prev_anchor,
        case when v_is_new then now() else coalesce(v_prev_last_seen, now()) end,
        now(), v_prev_turns, v_prev_sessnum
    )
    on conflict (platform_user_id) do update
       set session_anchor_id  = excluded.session_anchor_id,
           session_started_at = case when v_is_new then now()
                                     else st.session_started_at end,
           last_seen_at       = now(),
           session_msg_turns  = excluded.session_msg_turns,
           session_number     = excluded.session_number;

    if v_gap_hours is not null and v_gap_hours >= p_session_gap_hours then
        update followers
           set return_count   = return_count + 1,
               last_return_at = now(),
               last_gap_hours = v_gap_hours,
               is_golden      = case when return_count + 1 >= 2 then true
                                     else is_golden end
         where platform_user_id = p_platform_user_id;
    end if;

    is_new_session     := v_is_new;
    session_number     := v_prev_sessnum;
    dynamic_session_id := p_platform_user_id;
    session_anchor_id  := v_prev_anchor;
    hours_since_last   := v_gap_hours;
    session_turn       := v_prev_turns;
    return next;
end;
$fn$;

-- Counts the message as a side effect of asking, which is why nothing may call
-- it twice per turn. See docs/what-is-missing.md §7: its node has no inbound
-- connection today, so this caps nobody.
create or replace function public.check_daily_message_cap(p_follower_id uuid)
returns table(daily_count integer, cap integer, is_over_cap boolean, is_waitlisted boolean)
language plpgsql
security definer
set search_path to 'public'
as $fn$
declare
    v_waitlist boolean;
    v_count    integer;
    v_cap      integer;
begin
    update followers
       set daily_msg_count = case when daily_msg_date = current_date
                                  then daily_msg_count + 1 else 1 end,
           daily_msg_date  = current_date,
           last_active     = now()
     where id = p_follower_id
     returning daily_msg_count, waitlist
       into v_count, v_waitlist;

    if v_count is null then
        daily_count := 0; cap := 0; is_over_cap := false; is_waitlisted := false;
        return next; return;
    end if;

    v_cap := case when coalesce(v_waitlist, false) then 15 else 68 end;

    daily_count   := v_count;
    cap           := v_cap;
    is_over_cap   := v_count > v_cap;
    is_waitlisted := coalesce(v_waitlist, false);
    return next;
end;
$fn$;

-- ── The keyboard's one changing item ──────────────────────────────────────────

-- When commerce is blocked the label is identical to the ordinary one — the
-- journey is withheld silently, never announced as a thing being withheld.
create or replace function public.surface_changing_item(
  p_state text, p_paused boolean, p_commerce boolean, p_supported boolean, p_goal text)
returns jsonb
language sql
immutable
set search_path to 'pg_catalog', 'public'
as $fn$
  select case
    -- Paused is the parent's own explicit choice, so naming it is not a mode
    -- she did not ask for — it is the thing she asked for.
    when p_paused then
      jsonb_build_object('label','كيف نعود؟','meaning','resume')

    -- Commerce blocked (strain, or a recent crisis flag): SAME label as
    -- normal. The journey is withheld silently.
    when not p_commerce then
      jsonb_build_object('label','ما الذي يمكن أن نعمل عليه؟','meaning','open_question')

    when not p_supported and p_state in ('rhythm','journey_ended_no_next') then
      jsonb_build_object('label','أخبروني حين يصل آدم إلى بلدي','meaning','waitlist')

    when p_state = 'journey_active' then
      jsonb_build_object(
        'label', case when p_goal is not null then 'كيف تسير رحلة ' || p_goal || '؟'
                      else 'كيف تسير الرحلة؟' end,
        'meaning','journey_progress')

    when p_state = 'journey_ended_no_next' then
      jsonb_build_object(
        'label', case when p_goal is not null then 'ما بعد ' || p_goal || '؟'
                      else 'ما الذي يمكن أن نعمل عليه؟' end,
        'meaning','next_goal')

    else
      jsonb_build_object('label','ما الذي يمكن أن نعمل عليه؟','meaning','open_question')
  end;
$fn$;

-- ── The legacy layer, restored so it can be deleted ───────────────────────────
--
-- return_to_free belongs to the pre-stages payment model that
-- docs/what-is-missing.md §3 marks for deletion. It is restored anyway, and
-- deleted next: the deletion has to be a diff against something.
--
-- Payments and conversations are never touched — the record of what was paid,
-- and everything she ever said, survive.
create or replace function public.return_to_free(p_follower_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $fn$
declare
  f followers%rowtype;
begin
  select * into f from followers where id = p_follower_id;
  if not found then
    raise exception 'follower_not_found' using errcode = 'P0002';
  end if;

  update followers set
    funnel_stage            = 'free_conversation', -- الحالة المجانية القائمة
    payment_status          = 'none',
    offer_status            = 'none',
    subscription_started_at = null,                -- إيقاف الاشتراك النشط
    subscription_expires_at = null,
    payment_pending_at      = null,
    renewal_d5_sent_at      = null,
    renewal_d0_sent_at      = null
  where id = p_follower_id;

  -- ملاحظة: لا نلمس جدول payments (يحفظ سجل الدفع) ولا n8n_chat_histories (المحادثات)
  return jsonb_build_object(
    'follower_id', p_follower_id,
    'funnel_stage', 'free_conversation',
    'previous_stage', f.funnel_stage,
    'previous_expires_at', f.subscription_expires_at
  );
end;
$fn$;

commit;
