-- Baseline: the five dashboard views that predate this repository
--
-- The third and last piece of the pre-repo baseline, after the tables
-- (20260729000000) and the functions (20260729000100). Found the same way as
-- get_agent_context — not by reading, but by running the rebuild and watching
-- week 0 fail on `relation "public.v_funnel_summary" does not exist`.
--
-- These are read-only reporting views over `followers`. Nothing in the product
-- reads them; the founder's dashboard does. They are in the baseline rather than
-- omitted because week 0 revokes anon SELECT on all five, and a REVOKE on a view
-- that does not exist aborts the file — taking the rest of the revocations with
-- it and leaving parent data readable with the anon key.
--
-- Reproduced as production has them, including two things worth naming:
--
--   * Every view excludes the same two Telegram ids, '7377091520' and
--     '8074049810'. They are the founder's own test accounts, hardcoded so the
--     funnel numbers are not two families larger than reality. Faithful to the
--     source, and a fair thing to move into a table one day.
--   * They read `cohort`, `offer_score`, `judge_reason`, `offer_text` and other
--     columns that docs/what-is-missing.md §3 marks dead. Deleting those columns
--     therefore means rewriting these views first — which is exactly the kind of
--     coupling a baseline exists to make visible before the deletion, not during.

begin;

-- The funnel as eight cumulative gates, per cohort. s3 is "said anything at
-- all", s4 is "said fifteen things" — the difference between a visit and a
-- relationship.
create or replace view public.v_funnel_summary as
 select coalesce(cohort, 'new'::text) as cohort,
    count(*) as s1_entered,
    count(*) filter (where (coalesce(waitlist, false) = false)) as s2_supported,
    count(*) filter (where ((coalesce(waitlist, false) = false) and (coalesce(message_count, 0) >= 1))) as s3_talked,
    count(*) filter (where ((coalesce(waitlist, false) = false) and (coalesce(message_count, 0) >= 15))) as s4_deep,
    count(*) filter (where (last_judged_at is not null)) as s5_judged,
    count(*) filter (where (offer_sent_at is not null)) as s6_offer_sent,
    count(*) filter (where (cta_clicked_at is not null)) as s7_clicked,
    count(*) filter (where (funnel_stage = 'paid_active'::text)) as s8_paid
   from followers
  where (platform_user_id <> all (array['7377091520'::text, '8074049810'::text]))
  group by coalesce(cohort, 'new'::text);

-- The same gates, cut by the week a family first arrived.
create or replace view public.v_funnel_weekly as
 select (date_trunc('week'::text, first_seen))::date as week_start,
    coalesce(cohort, 'new'::text) as cohort,
    count(*) as entered,
    count(*) filter (where (coalesce(waitlist, false) = false)) as supported,
    count(*) filter (where (coalesce(message_count, 0) >= 1)) as talked,
    count(*) filter (where (coalesce(message_count, 0) >= 15)) as deep,
    count(*) filter (where (offer_sent_at is not null)) as offer_sent,
    count(*) filter (where (cta_clicked_at is not null)) as clicked,
    count(*) filter (where (funnel_stage = 'paid_active'::text)) as paid
   from followers
  where ((first_seen is not null) and (platform_user_id <> all (array['7377091520'::text, '8074049810'::text])))
  group by ((date_trunc('week'::text, first_seen))::date), coalesce(cohort, 'new'::text)
  order by ((date_trunc('week'::text, first_seen))::date) desc;

-- Every offer ever sent, with what it said and whether it landed.
create or replace view public.v_offers_log as
 select id,
    platform_user_id,
    coalesce(nullif(first_name, ''::text), username, ('…'::text || "right"(platform_user_id, 4))) as name,
    country,
    coalesce(cohort, 'new'::text) as cohort,
    offer_score,
    offer_child_name,
    offer_pain_safe,
    judge_reason,
    offer_text,
    offer_sent_at,
    cta_clicked_at,
    (cta_clicked_at is not null) as clicked,
    (funnel_stage = 'paid_active'::text) as paid,
    offer_status,
    funnel_stage,
    message_count,
    coalesce(return_count, 0) as return_count
   from followers f
  where ((offer_sent_at is not null) and (platform_user_id <> all (array['7377091520'::text, '8074049810'::text])))
  order by offer_sent_at desc;

-- One row per conversation, keyed by the NORMALISED session id — the same three
-- historical shapes ('123', '123_s4', '=123') that get_conversation_for() folds
-- together, done inline here because this view predates that function.
create or replace view public.v_conversations_list as
 with norm as (
         select regexp_replace(regexp_replace((n8n_chat_histories.session_id)::text, '^='::text, ''::text), '_s[0-9]+$'::text, ''::text) as pid,
            n8n_chat_histories.id,
            (n8n_chat_histories.message ->> 'type'::text) as mtype,
            (n8n_chat_histories.message ->> 'content'::text) as content,
            n8n_chat_histories.created_at
           from n8n_chat_histories
        ), agg as (
         select norm.pid,
            count(*) as msg_count,
            count(*) filter (where (norm.mtype = 'human'::text)) as human_count,
            count(*) filter (where (norm.mtype = 'ai'::text)) as ai_count,
            max(norm.id) as last_id,
            max(norm.created_at) as last_at
           from norm
          where (norm.pid ~ '^[0-9]+$'::text)
          group by norm.pid
        ), last_msg as (
         select distinct on (norm.pid) norm.pid,
            norm.mtype as last_sender,
            "left"(norm.content, 140) as preview
           from norm
          where (norm.pid ~ '^[0-9]+$'::text)
          order by norm.pid, norm.id desc
        )
 select a.pid as platform_user_id,
    f.id as follower_id,
    coalesce(nullif(f.first_name, ''::text), f.username, ('…'::text || "right"(a.pid, 4))) as name,
    f.country,
    coalesce(f.cohort, 'new'::text) as cohort,
    f.funnel_stage,
    coalesce(f.waitlist, false) as waitlist,
    a.msg_count,
    a.human_count,
    a.ai_count,
    a.last_at,
    l.last_sender,
    l.preview,
    f.offer_sent_at,
    f.offer_score,
    coalesce(f.return_count, 0) as return_count,
    f.last_active,
    f.first_seen
   from ((agg a
     left join last_msg l on ((l.pid = a.pid)))
     left join followers f on ((f.platform_user_id = a.pid)))
  where (a.pid <> all (array['7377091520'::text, '8074049810'::text]))
  order by a.last_at desc nulls last;

-- What a paid family has to show for their month, next to how much of it is
-- left. Built on the legacy subscription clock, which §3 replaces with `stages`.
create or replace view public.v_renewal_summary as
 select f.id as follower_id,
    f.first_name,
    f.platform_user_id,
    f.subscription_expires_at,
    greatest(0, (extract(day from (f.subscription_expires_at - now())))::integer) as days_left,
    ps.child_name,
    ps.main_challenge,
    ps.wins,
    ps.has_breakthrough,
    ps.next_step,
    ps.progress_score,
    ( select count(*) as count
           from memory_events me
          where ((me.follower_id = f.id) and (me.event_type = any (array['win'::text, 'breakthrough'::text])))) as win_count,
    ( select count(*) as count
           from daily_logs dl
          where ((dl.follower_id = f.id) and (dl.step_completed is true))) as completed_steps,
    ( select count(*) as count
           from child_patterns cp
          where ((cp.follower_id = f.id) and (cp.status = any (array['improving'::text, 'resolved'::text])))) as improved_patterns
   from (followers f
     left join plan_sessions ps on ((ps.follower_id = f.id)))
  where (f.funnel_stage = 'paid_active'::text);

commit;
