-- Stub for the Mirror engine's dependencies (v_child_record, crisis_flags).
--
-- The real v_child_record lives behind the journey_engine / child_record
-- migration chain, which assumes columns (stages.started_at, stages.created_at)
-- that predate this repo's migration history and cannot be reproduced from a
-- blank fixture. Same contract, simplified body -- the pattern
-- fixture_minimal.sql already uses for get_agent_context and can_ground_seed.
-- Only the shape v_mirror_first_due actually reads is reproduced.
--
-- Load after fixture_minimal.sql and before mirror_engine_core.sql.

-- crisis_flags was stubbed here once. It now lives in fixture_minimal.sql, in
-- its production shape (category NOT NULL), and the second CREATE aborted this
-- file at line 16 — taking v_child_record with it and leaving the whole Mirror
-- suite unrunnable without saying so. Deleted rather than guarded with IF NOT
-- EXISTS: two fixtures owning one table is how the shapes drift apart.

create view public.v_child_record as
select
  c.id as child_id, c.follower_id as parent_id,
  jsonb_build_object(
    'identity', jsonb_build_object('name', c.name),
    'rhythm', jsonb_build_object(
      'nights_logged', (select count(*) from public.daily_logs d
                          where d.follower_id = c.follower_id and d.night_result is not null),
      'calm', (select count(*) from public.daily_logs d
                where d.follower_id = c.follower_id and d.night_result = 'calm'),
      'hard', (select count(*) from public.daily_logs d
                where d.follower_id = c.follower_id and d.night_result = 'hard')),
    'what_triggers', '["الانتقال بين الأنشطة"]'::jsonb,
    'what_calms', '["التنبيه قبل خمس دقائق"]'::jsonb
  ) as record
from public.children c;
