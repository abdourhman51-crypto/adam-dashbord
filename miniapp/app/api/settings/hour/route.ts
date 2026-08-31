import { NextResponse } from "next/server";
import { resolveParent } from "@/lib/telegram/parent";
import { supabaseAdmin } from "@/lib/supabase/admin";

export const dynamic = "force-dynamic";

/**
 * set_checkin_hour موجودة أصلاً وتستدعيها محادثة البوت — التطبيق المصغّر
 * يستدعي نفس الدالة، لا نسخة موازية منها، فيبقى مصدر الحقيقة واحداً.
 */
export async function POST(request: Request) {
  const parent = await resolveParent(request);
  if (!parent.ok) {
    return NextResponse.json({ error: parent.message }, { status: parent.status });
  }

  const body = (await request.json().catch(() => null)) as { hour?: unknown } | null;
  const hour = Number(body?.hour);
  if (!Number.isInteger(hour) || hour < 5 || hour > 22) {
    return NextResponse.json({ error: "ساعة غير صالحة" }, { status: 400 });
  }

  const { data, error } = await supabaseAdmin().rpc("set_checkin_hour", {
    p_parent_id: parent.parentId,
    p_hour: hour,
  });

  if (error || data !== true) {
    return NextResponse.json({ error: "تعذّر حفظ الوقت" }, { status: 500 });
  }

  return NextResponse.json({ updated: true, hour });
}
