import { NextResponse } from "next/server";
import { resolveParent } from "@/lib/telegram/parent";
import { supabaseAdmin } from "@/lib/supabase/admin";
import { getLocalDateString } from "@/lib/supabase/localDate.server";

export const dynamic = "force-dynamic";

export async function GET(request: Request) {
  const parent = await resolveParent(request);
  if (!parent.ok) {
    return NextResponse.json({ error: parent.message }, { status: parent.status });
  }

  const today = await getLocalDateString(parent.country);

  const { data, error } = await supabaseAdmin()
    .from("daily_logs")
    .select("step_given, step_committed_at")
    .eq("follower_id", parent.parentId)
    .eq("log_date", today)
    .maybeSingle();

  if (error) {
    return NextResponse.json({ error: "تعذّر قراءة خطوة اليوم" }, { status: 500 });
  }

  return NextResponse.json({
    childName: parent.childName,
    stepGiven: data?.step_given ?? null,
    stepCommittedAt: data?.step_committed_at ?? null,
  });
}
