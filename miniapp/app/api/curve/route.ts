import { NextResponse } from "next/server";
import { resolveParent } from "@/lib/telegram/parent";
import { supabaseAdmin } from "@/lib/supabase/admin";
import { getLocalDateString } from "@/lib/supabase/localDate.server";

export const dynamic = "force-dynamic";

interface Curve {
  ready: boolean;
  heldWeek: number;
  eruptWeek: number;
  heldPrev: number;
  eruptPrev: number;
  heldTotal: number;
  eruptDelta: number;
  firstDay: string | null;
}

/**
 * المنحنى الوحيد الذي يعرضه التطبيق: كم مرة أوشك الوالد ولم ينفجر. هذا هو
 * الوعد المُباع ("من الانفجار كل يوم إلى مرّتين في الأسبوع") مقيساً بصدق —
 * eruptDelta سالباً يعني أنّ الانفجارات نقصت عن الأسبوع الماضي.
 */
export async function GET(request: Request) {
  const parent = await resolveParent(request);
  if (!parent.ok) {
    return NextResponse.json({ error: parent.message }, { status: parent.status });
  }

  const db = supabaseAdmin();
  const today = await getLocalDateString(parent.country);

  const [curveRes, todayRes] = await Promise.all([
    db.rpc("get_parent_curve", { p_parent_id: parent.parentId }),
    db
      .from("parent_moments")
      .select("id", { count: "exact", head: true })
      .eq("parent_id", parent.parentId)
      .eq("occurred_on", today),
  ]);

  if (curveRes.error) {
    return NextResponse.json({ error: "تعذّر قراءة هذي الشاشة" }, { status: 500 });
  }

  const curve = (curveRes.data ?? {}) as Curve;

  return NextResponse.json({
    ...curve,
    childName: parent.childName,
    // هل أجاب اليوم أصلاً — تحدّد إن كان سؤال المساء يُعرض أم لا
    answeredToday: (todayRes.count ?? 0) > 0,
  });
}
