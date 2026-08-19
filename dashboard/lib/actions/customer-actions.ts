"use server";

import { revalidatePath } from "next/cache";
import { supabaseAdmin } from "@/lib/supabase/admin";

function revalidateCustomer(followerId: string) {
  revalidatePath("/");
  revalidatePath("/stages");
  revalidatePath("/customers");
  revalidatePath(`/customers/${followerId}`);
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
