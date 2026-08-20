import { NextResponse } from "next/server";
import { resolveParent } from "@/lib/telegram/parent";
import { supabaseAdmin } from "@/lib/supabase/admin";

export const dynamic = "force-dynamic";

interface NightRow {
  log_date: string;
  night_result: "calm" | "hard" | "normal" | null;
  step_given: string | null;
  step_status: "done" | "tried_failed" | "not_tried" | null;
}

interface PatternRow {
  pattern_label: string;
  description: string | null;
}

/** الجملة المحسوبة أعلى الخط الزمني — من parent_effort الجاهزة، بلا منطق SQL جديد. */
function buildTrendLine(effort: {
  tried_this_week?: number;
  tried_last_week?: number;
  calm_this_week?: number;
}): string | null {
  const tried = effort.tried_this_week ?? 0;
  const calm = effort.calm_this_week ?? 0;
  const triedPrev = effort.tried_last_week ?? 0;
  if (tried === 0) return null;

  const base = `من ${tried} ${tried === 1 ? "ليلة حكيتوا" : "ليالٍ حكيتوا"} لي عنها هالأسبوع، ${calm} ${calm === 1 ? "كانت" : "كانت"} أهدأ.`;
  if (triedPrev === 0) return base;
  if (tried > triedPrev) return `${base} وهالأسبوع حكيتوا أكثر من اللي قبله.`;
  if (tried < triedPrev) return `${base} أقل من اللي قبله بالحكي، وهذا طبيعي — المهم الاستمرار.`;
  return `${base} بنفس وتيرة الأسبوع اللي قبله.`;
}

export async function GET(request: Request) {
  const parent = await resolveParent(request);
  if (!parent.ok) {
    return NextResponse.json({ error: parent.message }, { status: parent.status });
  }

  const db = supabaseAdmin();

  const [nightsRes, effortRes, patternsRes] = await Promise.all([
    db
      .from("daily_logs")
      .select("log_date, night_result, step_given, step_status")
      .eq("follower_id", parent.parentId)
      .not("night_result", "is", null)
      .order("log_date", { ascending: false })
      .limit(30),
    db.rpc("parent_effort", { p_parent_id: parent.parentId }),
    db
      .from("child_patterns")
      .select("pattern_label, description")
      .eq("follower_id", parent.parentId)
      .eq("safe_for_record", true)
      .order("last_observed", { ascending: false })
      .limit(6),
  ]);

  if (nightsRes.error || effortRes.error || patternsRes.error) {
    return NextResponse.json({ error: "تعذّر قراءة الخط الزمني" }, { status: 500 });
  }

  const nights = (nightsRes.data ?? []) as NightRow[];
  const patterns = (patternsRes.data ?? []) as PatternRow[];
  const effort = (effortRes.data ?? {}) as Record<string, number>;

  return NextResponse.json({
    childName: parent.childName,
    trendLine: buildTrendLine(effort),
    nights: nights.map((n) => ({
      logDate: n.log_date,
      result: n.night_result,
      stepGiven: n.step_given,
      stepStatus: n.step_status,
    })),
    patterns: patterns.map((p) => ({ label: p.pattern_label, description: p.description })),
  });
}
