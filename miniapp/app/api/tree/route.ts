import { NextResponse } from "next/server";
import { resolveParent } from "@/lib/telegram/parent";
import { supabaseAdmin } from "@/lib/supabase/admin";

export const dynamic = "force-dynamic";

/**
 * ورقة تُكسب بفعل الوالد نفسه — التزام بخطوة، أو تماسك عند وشك الانفجار —
 * لا بليلة هدوء عند الطفل. هذا كان سابقاً عدّاد ليالٍ هادئة، وهو مقياس
 * الطفل، فتنافس صامتاً مع منحنى الوالد على أنه «الرقم المهم» في نفس الشاشة.
 */
export async function GET(request: Request) {
  const parent = await resolveParent(request);
  if (!parent.ok) {
    return NextResponse.json({ error: parent.message }, { status: parent.status });
  }

  const db = supabaseAdmin();
  const [stepsRes, heldRes] = await Promise.all([
    db
      .from("daily_logs")
      .select("id", { count: "exact", head: true })
      .eq("follower_id", parent.parentId)
      .not("step_committed_at", "is", null),
    db
      .from("parent_moments")
      .select("id", { count: "exact", head: true })
      .eq("parent_id", parent.parentId)
      .eq("kind", "held"),
  ]);

  if (stepsRes.error || heldRes.error) {
    return NextResponse.json({ error: "تعذّر قراءة الشجرة" }, { status: 500 });
  }

  return NextResponse.json({ calmCount: (stepsRes.count ?? 0) + (heldRes.count ?? 0) });
}
