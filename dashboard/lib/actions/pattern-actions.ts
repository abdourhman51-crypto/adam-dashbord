"use server";

import { revalidatePath } from "next/cache";
import { supabaseAdmin } from "@/lib/supabase/admin";

export async function reviewPatternAction(patternId: string, decision: boolean, approverName: string) {
  const trimmed = approverName.trim();
  if (!trimmed) throw new Error("اسم الموافِق مطلوب.");

  const { data, error } = await supabaseAdmin().rpc("handle_pattern_review_tap", {
    p_pattern_id: patternId,
    p_decision: decision,
    p_approver: trimmed,
  });
  if (error) throw new Error(error.message);
  revalidatePath("/patterns");
  return data;
}
