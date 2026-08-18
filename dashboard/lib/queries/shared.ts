import { cache } from "react";
import { supabaseAdmin, TEST_PLATFORM_USER_IDS } from "@/lib/supabase/admin";
import type {
  CheckinState,
  Child,
  ChildPattern,
  DailyLog,
  Follower,
  ParentStrain,
  Payment,
  Situation,
  StageProgress,
} from "@/lib/types";

/**
 * جداول المشروع صغيرة (مئات الصفوف) — نجلبها كاملة مرة واحدة لكل طلب (مُخزَّنة
 * عبر React cache) ونُجري التجميعات في الخادم بدل استعلامات SQL مركّبة هشة.
 * كل دالة تستبعد حسابي الاختبار افتراضياً.
 */

async function fetchAllPages<T>(
  query: (from: number, to: number) => PromiseLike<{ data: T[] | null; error: { message: string } | null }>
): Promise<T[]> {
  const pageSize = 1000;
  let from = 0;
  const all: T[] = [];
  for (;;) {
    const { data, error } = await query(from, from + pageSize - 1);
    if (error) throw new Error(error.message);
    if (!data || data.length === 0) break;
    all.push(...data);
    if (data.length < pageSize) break;
    from += pageSize;
  }
  return all;
}

export const getFollowers = cache(async (): Promise<Follower[]> => {
  return fetchAllPages<Follower>((from, to) =>
    supabaseAdmin()
      .from("followers")
      .select(
        "id, platform, platform_user_id, username, first_name, first_seen, last_active, funnel_stage, country, payment_status, subscription_started_at, subscription_expires_at, light_memory, light_memory_updated_at, parent_gender, intention_text, agreed_objective, agreed_at, journey_form_state"
      )
      .not("platform_user_id", "in", `(${TEST_PLATFORM_USER_IDS.join(",")})`)
      .range(from, to)
  );
});

export const getChildren = cache(async (): Promise<Child[]> => {
  const followers = await getFollowers();
  const ids = new Set(followers.map((f) => f.id));
  const rows = await fetchAllPages<Child>((from, to) =>
    supabaseAdmin()
      .from("children")
      .select("id, follower_id, name, gender, birth_year, age_note, temperament, is_primary, created_at")
      .range(from, to)
  );
  return rows.filter((c) => ids.has(c.follower_id));
});

export const getDailyLogs = cache(async (): Promise<DailyLog[]> => {
  const followers = await getFollowers();
  const ids = new Set(followers.map((f) => f.id));
  const rows = await fetchAllPages<DailyLog>((from, to) =>
    supabaseAdmin()
      .from("daily_logs")
      .select(
        "id, follower_id, child_id, log_date, step_given, step_status, night_result, hard_moment, situation_id, seed_sent_at, harvest_sent_at, harvest_answered_at"
      )
      .range(from, to)
  );
  return rows.filter((d) => ids.has(d.follower_id));
});

export const getStageProgress = cache(async (): Promise<StageProgress[]> => {
  const followers = await getFollowers();
  const ids = new Set(followers.map((f) => f.id));
  const rows = await fetchAllPages<StageProgress>((from, to) =>
    supabaseAdmin().from("v_stage_progress").select("*").range(from, to)
  );
  return rows.filter((s) => ids.has(s.parent_id));
});

export const getSituations = cache(async (): Promise<Situation[]> => {
  const followers = await getFollowers();
  const ids = new Set(followers.map((f) => f.id));
  const rows = await fetchAllPages<Situation>((from, to) =>
    supabaseAdmin().from("situations").select("*").range(from, to)
  );
  return rows.filter((s) => ids.has(s.parent_id));
});

export const getChildPatterns = cache(async (): Promise<ChildPattern[]> => {
  const followers = await getFollowers();
  const ids = new Set(followers.map((f) => f.id));
  const rows = await fetchAllPages<ChildPattern>((from, to) =>
    supabaseAdmin().from("child_patterns").select("*").range(from, to)
  );
  return rows.filter((p) => ids.has(p.follower_id));
});

export const getPayments = cache(async (): Promise<Payment[]> => {
  const followers = await getFollowers();
  const ids = new Set(followers.map((f) => f.id));
  const rows = await fetchAllPages<Payment>((from, to) =>
    supabaseAdmin().from("payments").select("*").range(from, to)
  );
  return rows.filter((p) => !p.follower_id || ids.has(p.follower_id));
});

export const getCheckinStates = cache(async (): Promise<CheckinState[]> => {
  const followers = await getFollowers();
  const ids = new Set(followers.map((f) => f.id));
  const rows = await fetchAllPages<CheckinState>((from, to) =>
    supabaseAdmin().from("checkin_state").select("*").range(from, to)
  );
  return rows.filter((s) => ids.has(s.parent_id));
});

export const getParentStrains = cache(async (): Promise<ParentStrain[]> => {
  const followers = await getFollowers();
  const ids = new Set(followers.map((f) => f.id));
  const rows = await fetchAllPages<ParentStrain>((from, to) =>
    supabaseAdmin().from("parent_strain").select("*").range(from, to)
  );
  return rows.filter((s) => ids.has(s.parent_id));
});
