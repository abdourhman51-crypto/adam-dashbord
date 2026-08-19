import { supabaseAdmin, TEST_PLATFORM_USER_IDS } from "@/lib/supabase/admin";
import { getFollowers, getChildren, getDailyLogs, getPayments, getStageProgress } from "./shared";
import type { FunnelStep } from "@/components/charts/FunnelSteps";

function startOfDayUtcIso(daysAgo = 0) {
  const d = new Date();
  d.setUTCHours(0, 0, 0, 0);
  d.setUTCDate(d.getUTCDate() - daysAgo);
  return d.toISOString();
}

export async function getOverviewKpis() {
  const [followers, dailyLogs] = await Promise.all([getFollowers(), getDailyLogs()]);

  const todayStart = startOfDayUtcIso(0);
  const weekStart = startOfDayUtcIso(7);

  const total = followers.length;
  const newToday = followers.filter((f) => f.first_seen >= todayStart).length;
  const newWeek = followers.filter((f) => f.first_seen >= weekStart).length;
  const paid = followers.filter((f) => f.funnel_stage === "paid_active").length;
  const free = total - paid;

  const { count: messagesToday } = await supabaseAdmin()
    .from("n8n_chat_histories")
    .select("id", { count: "exact", head: true })
    .gte("created_at", todayStart)
    .not("session_id", "in", `(${TEST_PLATFORM_USER_IDS.join(",")})`);

  const activeDailyToday = new Set(dailyLogs.filter((d) => d.log_date === new Date().toISOString().slice(0, 10)).map((d) => d.follower_id)).size;

  return { total, newToday, newWeek, paid, free, messagesToday: messagesToday ?? 0, activeDailyToday };
}

export async function getConversionFunnel(): Promise<FunnelStep[]> {
  const [followers, children, dailyLogs, stages, payments] = await Promise.all([
    getFollowers(),
    getChildren(),
    getDailyLogs(),
    getStageProgress(),
    getPayments(),
  ]);

  const namedChildFollowerIds = new Set(children.map((c) => c.follower_id));
  const realCheckinFollowerIds = new Set(
    dailyLogs.filter((d) => d.night_result !== null).map((d) => d.follower_id)
  );
  const stageFollowerIds = new Set(stages.map((s) => s.parent_id));
  const confirmedPaymentFollowerIds = new Set(
    payments.filter((p) => p.status === "confirmed" && p.follower_id).map((p) => p.follower_id as string)
  );

  const firstMessage = followers.length;
  const namedChild = followers.filter((f) => namedChildFollowerIds.has(f.id)).length;
  const realCheckin = followers.filter((f) => realCheckinFollowerIds.has(f.id)).length;
  const startedForm = followers.filter((f) => f.journey_form_state !== null).length;
  const agreedObjective = followers.filter(
    (f) => f.agreed_objective !== null || f.agreed_at !== null || stageFollowerIds.has(f.id)
  ).length;
  const paidActive = followers.filter(
    (f) => f.funnel_stage === "paid_active" || confirmedPaymentFollowerIds.has(f.id)
  ).length;

  return [
    { label: "أول رسالة", value: firstMessage },
    { label: "تسمية الطفل", value: namedChild },
    { label: "أول تفاعل يومي حقيقي", value: realCheckin },
    { label: "بدء الاستمارة", value: startedForm },
    { label: "هدف متفق عليه", value: agreedObjective },
    { label: "دفع فعلي", value: paidActive },
  ];
}

export const TEST_ACCOUNTS = TEST_PLATFORM_USER_IDS;
