// أنواع مطابقة للمخطط الحي في Supabase (project aajqbmjasnbwwyvgrlzy)، تحقّقنا منها مباشرة عبر MCP.

export type FunnelStage =
  | "free_conversation"
  | "offer_presented"
  | "payment_pending_manual"
  | "paid_active"
  | "waitlist_non_algerian"
  | "expired";

export interface Follower {
  id: string;
  platform: string | null;
  platform_user_id: string;
  username: string | null;
  first_name: string | null;
  first_seen: string;
  last_active: string;
  funnel_stage: FunnelStage;
  country: string | null;
  payment_status: "none" | "paid";
  subscription_started_at: string | null;
  subscription_expires_at: string | null;
  /** JSON نصي: core_pain, emotional_state, life_context, continuity, child_insight, last_win, child_name */
  light_memory: string | null;
  light_memory_updated_at: string | null;
  parent_gender: string | null;
  intention_text: string | null;
  agreed_objective: AgreedObjective | null;
  agreed_at: string | null;
  journey_form_state: Record<string, unknown> | null;
}

export interface LightMemory {
  core_pain?: string;
  emotional_state?: string;
  life_context?: string;
  continuity?: string;
  child_insight?: string;
  last_win?: string;
  child_name?: string;
}

export interface AgreedObjective {
  problem_key?: string;
  objective_text?: string;
  objective_target?: number;
  objective_window?: number;
  planned_logged_days?: number;
  objective_metric?: string;
  problem_context_text?: string;
  frequency_label?: string;
}

export interface Child {
  id: string;
  follower_id: string;
  name: string | null;
  gender: string | null;
  birth_year: number | null;
  age_note: string | null;
  temperament: string | null;
  is_primary: boolean;
  created_at: string;
}

export type NightResult = "calm" | "hard" | "normal";
export type StepStatus = "done" | "tried_failed" | "not_tried";

export interface DailyLog {
  id: string;
  follower_id: string;
  child_id: string | null;
  log_date: string;
  step_given: string | null;
  step_status: StepStatus | null;
  night_result: NightResult | null;
  hard_moment: string | null;
  situation_id: string | null;
  seed_sent_at: string | null;
  harvest_sent_at: string | null;
  harvest_answered_at: string | null;
}

export type StageStatus =
  | "proposed"
  | "active"
  | "extended"
  | "completed"
  | "failed"
  | "paused"
  | "refunded"
  | "cancelled";

export interface StageProgress {
  stage_id: string;
  parent_id: string;
  child_id: string | null;
  problem_key: string;
  status: StageStatus;
  objective_text: string;
  objective_metric: string;
  objective_target: number;
  objective_window: number;
  planned_logged_days: number;
  extension_days: number;
  allowed_days: number;
  logged_days: number;
  days_remaining: number;
  phase: "observe" | "build" | "hold";
  objective_current: number | null;
  window_filled: number;
  objective_met: boolean;
  clock_exhausted: boolean;
  started_at: string | null;
  completed_at: string | null;
}

export interface Situation {
  id: string;
  child_id: string;
  parent_id: string;
  key: string;
  label_ar: string;
  window_start: number;
  window_end: number;
  status: "candidate" | "confirmed" | "resolved";
  evidence_count: number;
  first_observed: string;
  last_observed: string;
}

export interface ChildPattern {
  id: string;
  follower_id: string;
  child_id: string | null;
  pattern_label: string;
  description: string | null;
  status: "active" | "improving" | "resolved" | "dormant";
  evidence_count: number;
  last_observed: string;
  safe_for_record: boolean;
}

export interface ParentStrain {
  parent_id: string;
  level: 1 | 2 | 3;
  reason: string | null;
  entered_at: string;
  return_eligible_at: string | null;
}

export interface CheckinState {
  parent_id: string;
  cadence: "nightly" | "weekly" | "stopped";
  local_hour: number;
  consecutive_ignored: number;
  last_sent_at: string | null;
  last_responded_at: string | null;
  paused_until: string | null;
  winback_sent_at: string | null;
}

export interface Payment {
  id: string;
  follower_id: string | null;
  amount: number;
  currency: string;
  plan_type: string;
  status: string;
  claimed_at: string | null;
  confirmed_at: string | null;
  confirmed_by: string | null;
  notes: string | null;
  created_at: string;
}

export interface ChatMessage {
  id: number;
  session_id: string;
  message: { type: "human" | "ai"; content: string };
  created_at: string;
}

export interface PatternPendingReview {
  pattern_id: string;
  child_name: string;
  pattern_label: string;
  description: string | null;
}

export interface InboxConversation {
  follower_id: string;
  platform_user_id: string;
  first_name: string | null;
  username: string | null;
  last_message_at: string;
  last_message_preview: string | null;
  last_message_from: "human" | "ai";
  last_human_message_at: string | null;
  viewed_at: string | null;
}
