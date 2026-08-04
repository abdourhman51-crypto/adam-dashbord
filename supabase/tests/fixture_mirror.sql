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

create table public.crisis_flags (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid references public.followers(id) on delete cascade,
  detected_at timestamptz not null default now()
);

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
