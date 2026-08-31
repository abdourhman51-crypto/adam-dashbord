import { NextResponse } from "next/server";
import { resolveParent } from "@/lib/telegram/parent";
import { supabaseAdmin } from "@/lib/supabase/admin";

export const dynamic = "force-dynamic";

export async function GET(request: Request) {
  const parent = await resolveParent(request);
  if (!parent.ok) {
    return NextResponse.json({ error: parent.message }, { status: parent.status });
  }

  const { data, error } = await supabaseAdmin().rpc("get_checkin_settings", {
    p_parent_id: parent.parentId,
  });

  if (error) {
    return NextResponse.json({ error: "تعذّر قراءة الإعدادات" }, { status: 500 });
  }

  const result = data as { local_hour: number; paused: boolean };
  return NextResponse.json({ localHour: result.local_hour, paused: result.paused });
}
