"use server";

import { revalidatePath } from "next/cache";
import { supabaseAdmin } from "@/lib/supabase/admin";

function revalidateCustomer(followerId: string) {
  revalidatePath("/");
  revalidatePath("/stages");
  revalidatePath("/customers");
  revalidatePath(`/customers/${followerId}`);
}

// activate_subscription/renew_stage_same_objective always record the payment even when
// the journey itself does not start (design: taking money is never refused — see
// supabase/tests/README.md "start_stage deliberately does not check"). They report that
// loudly via journey.started/reason on the return value; without this, the dashboard
// silently closed the dialog as if a new stage had begun.
const JOURNEY_NOT_STARTED_MESSAGES: Record<string, string> = {
  stage_already_live: "سُجِّل الدفع، لكن لم تبدأ رحلة جديدة: توجد رحلة أخرى نشطة بالفعل لهذا العميل.",
  objective_required: "سُجِّل الدفع، لكن لم تبدأ الرحلة بعد: لا يوجد هدف متفق عليه. أدخِلوا هدفاً يدوياً أو انتظروا اتفاقه في المحادثة.",
  target_exceeds_window: "سُجِّل الدفع، لكن الهدف يتجاوز مدة النافذة المحددة.",
  clock_out_of_range: "سُجِّل الدفع، لكن عدد أيام المرافقة المخطَّط خارج النطاق المسموح (7–60).",
};

function assertJourneyStarted(data: unknown) {
  const journey = (data as { journey?: { started?: boolean; reason?: string } } | null)?.journey;
  if (journey && journey.started === false) {
    const reason = journey.reason ?? "";
    throw new Error(JOURNEY_NOT_STARTED_MESSAGES[reason] ?? `سُجِّل الدفع، لكن لم تبدأ الرحلة (${reason}).`);
  }
}

function assertRenewed(data: unknown) {
  const renewed = (data as { renewed?: boolean; reason?: string } | null)?.renewed;
  if (renewed === false) {
    throw new Error("لا توجد رحلة سابقة لهذا العميل يمكن التجديد بهدفها.");
  }
}

export async function activateSubscriptionAction(
  followerId: string,
  input: {
    amount?: number;
    currency?: string;
    notes?: string;
    problemKey?: string;
    objectiveText?: string;
    objectiveTarget?: number;
    objectiveWindow?: number;
    plannedLoggedDays?: number;
    objectiveMetric?: string;
  }
) {
  const { data, error } = await supabaseAdmin().rpc("activate_subscription", {
    p_follower_id: followerId,
    p_amount: input.amount ?? null,
    p_currency: input.currency ?? null,
    p_notes: input.notes ?? null,
    p_problem_key: input.problemKey ?? null,
    p_objective_text: input.objectiveText ?? null,
    p_objective_target: input.objectiveTarget ?? 5,
    p_objective_window: input.objectiveWindow ?? 7,
    p_planned_logged_days: input.plannedLoggedDays ?? 29,
    p_objective_metric: input.objectiveMetric ?? null,
  });
  if (error) throw new Error(error.message);
  revalidateCustomer(followerId);
  assertJourneyStarted(data);
  return data;
}

export async function deactivateSubscriptionAction(followerId: string, reason?: string) {
  const { data, error } = await supabaseAdmin().rpc("deactivate_subscription", {
    p_follower_id: followerId,
    p_reason: reason ?? null,
  });
  if (error) throw new Error(error.message);
  revalidateCustomer(followerId);
  return data;
}

export async function renewStageSameObjectiveAction(
  followerId: string,
  input: { amount?: number; currency?: string; notes?: string }
) {
  const { data, error } = await supabaseAdmin().rpc("renew_stage_same_objective", {
    p_follower_id: followerId,
    p_amount: input.amount ?? null,
    p_currency: input.currency ?? null,
    p_notes: input.notes ?? null,
  });
  if (error) throw new Error(error.message);
  revalidateCustomer(followerId);
  assertRenewed(data);
  assertJourneyStarted(data);
  return data;
}

export async function requestErasureAction(followerId: string) {
  const { data, error } = await supabaseAdmin().rpc("request_erasure", { p_parent_id: followerId });
  if (error) throw new Error(error.message);
  revalidateCustomer(followerId);
  return data as string;
}

export async function executeErasureAction(requestId: string, followerId: string) {
  const { data, error } = await supabaseAdmin().rpc("execute_erasure", { p_request_id: requestId });
  if (error) throw new Error(error.message);
  revalidatePath("/");
  revalidatePath("/stages");
  revalidatePath("/customers");
  return data;
}
