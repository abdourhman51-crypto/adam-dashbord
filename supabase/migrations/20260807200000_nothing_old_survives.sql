-- Nothing old survives
--
-- Founder's decision, 2026-08-07: «اريد التخلص من كل ما هو قديم ولا نحتاجه —
-- اريد المنتج يكون نضيف». The dashboard breaking is accepted and expected; it is
-- being rebuilt.
--
-- Everything dropped here was checked three ways first, and nothing is dropped
-- on the strength of its name:
--
--   1. against every surviving function's source (`pg_proc.prosrc`)
--   2. against every surviving view's definition
--   3. against the 62 nodes of W1 that are actually REACHABLE from the Telegram
--      trigger — walking `connections` forward, and backwards along
--      `ai_languageModel` / `ai_memory` edges, which attach a model or a memory
--      to its agent
--
-- The third check is the one that matters, and it is why this is safe: the live
-- workflow touches `followers` through exactly twelve nodes, and between them
-- they name 24 columns. Everything else on that table is written by nobody and
-- read by nobody.
--
-- ── The dashboard views ───────────────────────────────────────────────────────
--
-- All five go. They were the only readers of eleven of the columns below, which
-- is precisely why those columns could not be dropped before today. They are not
-- rewritten here: what the next dashboard should show is a question about the
-- product as it now is — stages, situations, the rhythm — and not a port of a
-- funnel that no longer exists.
--
-- ── The legacy plan model ─────────────────────────────────────────────────────
--
-- `plan_sessions` is the 30-day plan that `stages` replaced: `current_day`,
-- `current_week`, `progress_score`, `has_breakthrough`. Three rows, and the only
-- reason it survived this long is that `get_agent_context` opens the paid prompt
-- with `PLAN_DAY: n`. That number counts a plan nobody runs. It is removed from
-- the prompt rather than left to count nothing.
--
-- ── The old session tracker ───────────────────────────────────────────────────
--
-- `session_tracker` + `get_free_session_state` + `followers.is_golden`,
-- `return_count`, `last_return_at`, `last_gap_hours`. "Golden" meant a parent who
-- came back twice after an eight-hour gap. Nothing has called it since the tap
-- system landed — it is not among the eleven endpoints W1 reaches — and the
-- product's own measure of a returning parent is now the rhythm.
--
-- ── Kept on purpose, though nothing calls them today ──────────────────────────
--
--   * `check_daily_message_cap` and its three columns. A cap that caps nobody is
--     not a safeguard, but deleting it removes the option of one, and this is the
--     only brake on spend the product has. It must be WIRED before launch — see
--     docs/what-is-missing.md §7.
--   * `payments`. The financial record outlives the funnel that produced it, and
--     `execute_erasure` de-identifies it rather than deleting it.
--   * `survey_responses` and `followers.survey_mode`. `SV - Save Survey Reply` and
--     `SV - Clear Survey Mode` are both reachable — this one is live.

begin;

-- ── 1. The dashboard views ────────────────────────────────────────────────────

drop view if exists public.v_funnel_summary;
drop view if exists public.v_funnel_weekly;
drop view if exists public.v_offers_log;
drop view if exists public.v_conversations_list;
drop view if exists public.v_renewal_summary;

-- ── 2. Functions that only served what is being dropped ───────────────────────

drop function if exists public.get_free_session_state(text, numeric);

-- The legacy end-of-subscription reset. It writes six columns that go below, and
-- the only caller was the dashboard's activate.ts. Ending a journey is
-- close_stage() now.
drop function if exists public.return_to_free(uuid);

-- ── 3. The paid prompt stops counting a plan nobody runs ──────────────────────

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
  v_days_left int;
begin
  -- PLAN_DAY is gone with plan_sessions. DAYS_LEFT stays: it is the access clock
  -- the parent actually paid for, and it comes straight off followers.
  select greatest(0, extract(day from f.subscription_expires_at - now())::int)
    into v_days_left
  from followers f
  where f.id = p_follower_id;

  v_out := 'DAYS_LEFT: ' || coalesce(v_days_left::text, '?');

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

-- ── 4. writer_commit stops writing to a table that is going ───────────────────

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
  for ch in select * from jsonb_array_elements(coalesce(p_payload->'children','[]'::jsonb)) loop
    v_name := nullif(trim(ch->>'name'),'');
    if v_name is null then continue; end if;

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
    -- The plan_sessions.has_breakthrough flag was set here. That table is gone;
    -- a breakthrough is a memory_event of that type, which is where it belonged.
  end loop;

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

-- ── 5. write_child_name stops back-linking to a table that is going ───────────

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

  -- ربط رجعي: يُطبَّق فقط إن كان لهذا المربّي طفل واحد (نسبة مؤكّدة).
  -- weekly_plans is gone; daily_logs is the only orphan table left.
  select count(*) into v_child_count from children where follower_id = v_follower_id;
  if v_child_count = 1 and v_child_id is not null then
    update daily_logs set child_id = v_child_id
      where follower_id = v_follower_id and child_id is null;
  end if;
end;
$fn$;

-- ── 6. The tables ─────────────────────────────────────────────────────────────
--
-- Archived first where they hold anything. follower_insights has 4 rows and
-- plan_sessions 3; both are a record of real families and cost nothing to keep
-- out of the way. weekly_plans and session_tracker are empty of anything worth
-- carrying — weekly_plans has no rows at all.

create schema if not exists archive;

create table if not exists archive.plan_sessions_20260807 as
  select *, now() as archived_at from public.plan_sessions;
create table if not exists archive.follower_insights_20260807 as
  select *, now() as archived_at from public.follower_insights;

drop table if exists public.plan_sessions;
drop table if exists public.follower_insights;
drop table if exists public.weekly_plans;
drop table if exists public.session_tracker;

-- ── 7. The columns ────────────────────────────────────────────────────────────
--
-- Grouped by what they belonged to, so the next person reads a history rather
-- than a list. Every one of them: not named by any surviving function, not named
-- by any surviving view, not named by any reachable node of W1.

-- The judge/seller funnel — an LLM scored parents and wrote an offer for them.
alter table public.followers
  drop column if exists offer_score,
  drop column if exists offer_hook,
  drop column if exists offer_text,
  drop column if exists offer_child_name,
  drop column if exists offer_pain_safe,
  drop column if exists offer_source,
  drop column if exists offer_sent_at,
  drop column if exists offer_count,
  drop column if exists offer_declined_count,
  drop column if exists judge_reason,
  drop column if exists last_judged_at,
  drop column if exists ready_for_offer,
  drop column if exists cta_clicked_at,
  drop column if exists followup_sent_at;
-- offer_ready() derives all of this on demand now, from evidence rather than
-- from a score somebody wrote down once.

-- The scored-lead model: three numbers an LLM assigned to a parent in distress.
alter table public.followers
  drop column if exists pain_score,
  drop column if exists urgency_score,
  drop column if exists intent_score;

-- The button onboarding (OB - *, 27 unreachable nodes). Everything it asked is
-- now learned from the conversation itself.
alter table public.followers
  drop column if exists onboarding_step,
  drop column if exists onboarding_done,
  drop column if exists child_age_band,
  drop column if exists main_pain,
  drop column if exists pain_time,
  drop column if exists guardian_state,
  drop column if exists trial_started_at,
  drop column if exists clarity_seen_at;

-- Reactivation and the insight blast — outbound campaigns, all of them removed.
alter table public.followers
  drop column if exists reactivation_sent_at,
  drop column if exists reactivation_clicked_at,
  drop column if exists insight_sent_at,
  drop column if exists survey_sent_at,
  drop column if exists cap_reached_at;

-- The old session tracker. See the header.
alter table public.followers
  drop column if exists is_golden,
  drop column if exists return_count,
  drop column if exists last_return_at,
  drop column if exists last_gap_hours,
  drop column if exists cohort,
  drop column if exists signup_source;

-- The CHECK constraints that named the dropped columns went with them
-- automatically; this one names a column that survives, and its partner is gone.
alter table public.followers drop constraint if exists chk_no_offer_for_active;
alter table public.followers drop constraint if exists chk_offer_source_valid;

commit;
