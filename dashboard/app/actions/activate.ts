"use server";

import { revalidatePath } from "next/cache";
import {
  activateSubscription,
  returnToFree,
  type ActivateResult,
  type ReturnToFreeResult,
} from "@/lib/queries";

export type ActivateActionState =
  | { ok: true; data: ActivateResult }
  | { ok: false; error: string };

export type ReturnToFreeActionState =
  | { ok: true; data: ReturnToFreeResult }
  | { ok: false; error: string };

function revalidateSubscriptionPages(followerId: string) {
  revalidatePath("/");
  revalidatePath("/followers");
  revalidatePath(`/followers/${followerId}`);
  revalidatePath("/funnel");
  revalidatePath("/revenue");
}

/**
 * إجراء خادمي لتأكيد الدفع وتفعيل الاشتراك.
 * يستدعي دالة activate_subscription الذرّية ثم يُحدِّث صفحات لوحة التحكم.
 */
export async function activateSubscriptionAction(args: {
  followerId: string;
  days: number;
  amount: number | null;
  currency: string | null;
  notes: string | null;
}): Promise<ActivateActionState> {
  if (!args.followerId) return { ok: false, error: "معرّف المتابع مفقود" };
  try {
    const data = await activateSubscription({
      followerId: args.followerId,
      days: args.days,
      amount: args.amount,
      currency: args.currency,
      notes: args.notes,
    });
    revalidateSubscriptionPages(args.followerId);
    return { ok: true, data };
  } catch (e) {
    const msg = e instanceof Error ? e.message : "فشل تفعيل الاشتراك";
    // رسالة أوضح إن لم تُنشأ الدالة بعد
    if (/function .*activate_subscription.* does not exist|PGRST202|could not find/i.test(msg)) {
      return {
        ok: false,
        error:
          "دالة activate_subscription غير موجودة بعد. شغّل ملف الهجرة supabase/migrations/20260708_add_activate_subscription_fn.sql في محرّر SQL لمشروع Supabase ثم أعد المحاولة.",
      };
    }
    return { ok: false, error: msg };
  }
}

/**
 * إجراء خادمي لإلغاء الاشتراك وإعادة المتابع للحالة المجانية القائمة.
 */
export async function returnToFreeAction(
  followerId: string
): Promise<ReturnToFreeActionState> {
  if (!followerId) return { ok: false, error: "معرّف المتابع مفقود" };
  try {
    const data = await returnToFree(followerId);
    revalidateSubscriptionPages(followerId);
    return { ok: true, data };
  } catch (e) {
    const msg = e instanceof Error ? e.message : "فشل إعادة المتابع للمجاني";
    if (/function .*return_to_free.* does not exist|PGRST202|could not find/i.test(msg)) {
      return {
        ok: false,
        error:
          "دالة return_to_free غير موجودة بعد. شغّل ملف الهجرة supabase/migrations/20260708_add_return_to_free_fn.sql في محرّر SQL لمشروع Supabase ثم أعد المحاولة.",
      };
    }
    return { ok: false, error: msg };
  }
}
