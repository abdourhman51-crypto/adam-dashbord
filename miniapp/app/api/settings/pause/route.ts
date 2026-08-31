import { NextResponse } from "next/server";
import { resolveParent } from "@/lib/telegram/parent";
import { supabaseAdmin } from "@/lib/supabase/admin";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  const parent = await resolveParent(request);
  if (!parent.ok) {
    return NextResponse.json({ error: parent.message }, { status: parent.status });
  }

  const body = (await request.json().catch(() => null)) as { paused?: unknown } | null;
  if (typeof body?.paused !== "boolean") {
    return NextResponse.json({ error: "قيمة غير صالحة" }, { status: 400 });
  }

  const { data, error } = await supabaseAdmin().rpc("set_checkin_paused", {
    p_parent_id: parent.parentId,
    p_paused: body.paused,
  });

  if (error) {
    return NextResponse.json({ error: "تعذّر الحفظ" }, { status: 500 });
  }

  const result = data as { updated: boolean; paused: boolean };
  return NextResponse.json({ updated: result.updated, paused: result.paused });
}
