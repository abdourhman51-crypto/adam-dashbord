import { NextResponse } from "next/server";
import { resolveParent } from "@/lib/telegram/parent";
import { supabaseAdmin } from "@/lib/supabase/admin";

export const dynamic = "force-dynamic";

/**
 * الاستثناء الوحيد الآخر لقاعدة "قراءة فقط" في هذا المسار — يكتب الاتفاق
 * فقط عبر agree_objective الحقيقية نفسها التي تكتبه لحظة الاتفاق في
 * المحادثة. لا هدف يُخترع هنا: agree_objective ترفض إن لم يكن الدليل
 * جاهزاً (suggest_objective.ready)، وهذا هو نفس الرفض الذي تراه المحادثة.
 */
export async function POST(request: Request) {
  const parent = await resolveParent(request);
  if (!parent.ok) {
    return NextResponse.json({ error: parent.message }, { status: parent.status });
  }

  const { data, error } = await supabaseAdmin().rpc("agree_objective", {
    p_parent_id: parent.parentId,
  });

  if (error) {
    return NextResponse.json({ error: "تعذّر تسجيل الاتفاق الآن" }, { status: 500 });
  }

  const result = data as { agreed: boolean; reason?: string; objective_text?: string } | null;
  if (!result?.agreed) {
    return NextResponse.json({ agreed: false, reason: result?.reason ?? "unknown" }, { status: 409 });
  }

  return NextResponse.json({ agreed: true, objectiveText: result.objective_text ?? null });
}
