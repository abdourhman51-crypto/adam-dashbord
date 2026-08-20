import { NextResponse } from "next/server";
import { resolveParent } from "@/lib/telegram/parent";
import { supabaseAdmin } from "@/lib/supabase/admin";

export const dynamic = "force-dynamic";

export async function GET(request: Request) {
  const parent = await resolveParent(request);
  if (!parent.ok) {
    return NextResponse.json({ error: parent.message }, { status: parent.status });
  }

  const { count, error } = await supabaseAdmin()
    .from("daily_logs")
    .select("id", { count: "exact", head: true })
    .eq("follower_id", parent.parentId)
    .eq("night_result", "calm");

  if (error) {
    return NextResponse.json({ error: "تعذّر قراءة الشجرة" }, { status: 500 });
  }

  return NextResponse.json({ calmCount: count ?? 0 });
}
