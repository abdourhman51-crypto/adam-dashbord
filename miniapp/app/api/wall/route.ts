import { NextResponse } from "next/server";
import { resolveParent } from "@/lib/telegram/parent";
import { supabaseAdmin } from "@/lib/supabase/admin";

export const dynamic = "force-dynamic";

interface DoneRow {
  log_date: string;
  step_given: string | null;
}

export async function GET(request: Request) {
  const parent = await resolveParent(request);
  if (!parent.ok) {
    return NextResponse.json({ error: parent.message }, { status: parent.status });
  }

  const { data, error } = await supabaseAdmin()
    .from("daily_logs")
    .select("log_date, step_given")
    .eq("follower_id", parent.parentId)
    .eq("step_status", "done")
    .eq("night_result", "calm")
    .not("step_given", "is", null)
    .order("log_date", { ascending: false })
    .limit(20);

  if (error) {
    return NextResponse.json({ error: "تعذّر قراءة جدار الإنجاز" }, { status: 500 });
  }

  const moments = (data ?? []) as DoneRow[];

  return NextResponse.json({
    isPaid: parent.isPaid,
    childName: parent.childName,
    moments: moments.map((m) => ({ logDate: m.log_date, stepGiven: m.step_given })),
  });
}
