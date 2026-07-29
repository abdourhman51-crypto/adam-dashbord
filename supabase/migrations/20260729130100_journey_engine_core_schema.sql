-- ============================================================================
-- Journey Engine · core schema
-- ============================================================================
-- Implements architecture-review.md Part 2 and journey-architecture.md 3.x.
-- A "stage" (مرحلة) is a bounded period of focused work on one named child
-- problem, inside one continuous relationship. It is NOT a product; the parent
-- is never shown a catalogue (journey-architecture 3.0).
--
-- KEY DESIGN DECISIONS
--   1. The clock counts LOGGED days, not calendar days (review A2). A 14-day
--      stage means 14 days on which she logged. Self-handles crisis pauses,
--      travel, illness and Ramadan with no pause feature, and makes the
--      guarantee fair in both directions.
--   2. Progress is DERIVED from daily_logs, never a stored counter. Same
--      principle Week-0 established after followers.message_count froze at 0
--      while parents were actively conversing. A counter that can drift will.
--   3. ONE active stage per PARENT, not per child (review A5). The scarce
--      resource is the parent's attention. Free rescue always covers every
--      child regardless.
--   4. Phase is derived from progress, never set by hand. observe -> build ->
--      hold. Hold exists so ADAM fades and the change is shown to be real
--      rather than compliance; nothing may shorten it.
--   5. erasure_requests carries NO foreign key to followers -- the audit
--      record must survive the erasure it records (review A11).
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.crisis_flags (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_id   uuid NOT NULL REFERENCES public.followers(id) ON DELETE CASCADE,
  category    text NOT NULL CHECK (category IN (
                'self_harm','domestic_violence','child_abuse_third_party',
                'parent_violence','bereavement','substance_use_minor','other')),
  detected_at timestamptz NOT NULL DEFAULT now(),
  source      text NOT NULL DEFAULT 'agent' CHECK (source IN ('agent','operator','system')),
  confidence  text CHECK (confidence IN ('low','medium','high')),
  handled_at  timestamptz,
  handled_by  text,
  notes       text,
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_crisis_flags_parent    ON public.crisis_flags (parent_id, detected_at DESC);
CREATE INDEX IF NOT EXISTS idx_crisis_flags_unhandled ON public.crisis_flags (detected_at) WHERE handled_at IS NULL;
COMMENT ON TABLE public.crisis_flags IS
  'Safeguarding queue. A flag suppresses ALL commercial messaging for 7 days '
  '(P1) and routes to human review. The escalation destination is a founder '
  'decision that remains open (architecture-review D1); this table records the '
  'event regardless so nothing is silently lost.';

CREATE TABLE IF NOT EXISTS public.stages (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_id            uuid NOT NULL REFERENCES public.followers(id) ON DELETE CASCADE,
  child_id             uuid REFERENCES public.children(id) ON DELETE SET NULL,
  problem_key          text NOT NULL,
  objective_text       text NOT NULL,
  objective_metric     text NOT NULL DEFAULT 'calm_nights_in_window'
                         CHECK (objective_metric IN ('calm_nights_in_window','steps_done_in_window')),
  objective_target     integer NOT NULL CHECK (objective_target > 0),
  objective_window     integer NOT NULL CHECK (objective_window > 0),
  planned_logged_days  integer NOT NULL CHECK (planned_logged_days BETWEEN 7 AND 60),
  extension_days       integer NOT NULL DEFAULT 0 CHECK (extension_days >= 0),
  extension_granted_at timestamptz,
  status               text NOT NULL DEFAULT 'proposed' CHECK (status IN (
                         'proposed','active','extended','completed','failed','paused','refunded')),
  price_amount         numeric,
  price_currency       text,
  proposed_at          timestamptz NOT NULL DEFAULT now(),
  started_at           timestamptz,
  paused_at            timestamptz,
  completed_at         timestamptz,
  refunded_at          timestamptz,
  created_at           timestamptz NOT NULL DEFAULT now(),
  updated_at           timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT chk_target_fits_window CHECK (objective_target <= objective_window),
  CONSTRAINT chk_started_when_live  CHECK (status NOT IN ('active','extended') OR started_at IS NOT NULL)
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_one_live_stage_per_parent
  ON public.stages (parent_id) WHERE status IN ('active','extended','paused');
CREATE INDEX IF NOT EXISTS idx_stages_parent ON public.stages (parent_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_stages_live   ON public.stages (status) WHERE status IN ('active','extended');
CREATE TRIGGER trg_stages_updated BEFORE UPDATE ON public.stages
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
COMMENT ON COLUMN public.stages.extension_days IS
  'The single automatic extension granted when the objective is not met '
  '(review A1: half the stage length, unrequested). A second extension is '
  'never granted -- an automatic refund follows instead.';

CREATE TABLE IF NOT EXISTS public.stage_proposals (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_id   uuid NOT NULL REFERENCES public.followers(id) ON DELETE CASCADE,
  child_id    uuid REFERENCES public.children(id) ON DELETE SET NULL,
  problem_key text NOT NULL,
  proposed_at timestamptz NOT NULL DEFAULT now(),
  outcome     text NOT NULL DEFAULT 'pending'
                CHECK (outcome IN ('pending','accepted','declined','superseded')),
  stage_id    uuid REFERENCES public.stages(id) ON DELETE SET NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_proposals_parent  ON public.stage_proposals (parent_id, proposed_at DESC);
CREATE INDEX IF NOT EXISTS idx_proposals_problem ON public.stage_proposals (parent_id, problem_key);
COMMENT ON TABLE public.stage_proposals IS
  'Every time ADAM names what he thinks matters next. Guidance is free and '
  'carries no price or button; this table exists to cap how often it may be '
  'offered (review A7) so guidance never becomes pushing.';

CREATE TABLE IF NOT EXISTS public.erasure_requests (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_id        uuid NOT NULL,
  platform_user_id text NOT NULL,
  requested_at     timestamptz NOT NULL DEFAULT now(),
  completed_at     timestamptz,
  status           text NOT NULL DEFAULT 'requested'
                     CHECK (status IN ('requested','completed','failed')),
  refund_due       boolean NOT NULL DEFAULT false,
  notes            text
);
CREATE INDEX IF NOT EXISTS idx_erasure_open ON public.erasure_requests (requested_at) WHERE completed_at IS NULL;
COMMENT ON TABLE public.erasure_requests IS
  'Right-to-erasure audit trail. No FK to followers by design: the record of '
  'an erasure must survive the erasure. refund_due marks an active paid stage '
  'that must be refunded pro-rata (review A11).';

-- Locked to service_role from the outset. Week-0 found 17 permissive anon
-- policies exposing 4,174 conversations; these tables start closed.
ALTER TABLE public.crisis_flags     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stages           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stage_proposals  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.erasure_requests ENABLE ROW LEVEL SECURITY;
CREATE POLICY service_all ON public.crisis_flags     FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY service_all ON public.stages           FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY service_all ON public.stage_proposals  FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY service_all ON public.erasure_requests FOR ALL TO service_role USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE ON public.crisis_flags, public.stages,
      public.stage_proposals, public.erasure_requests TO service_role;
