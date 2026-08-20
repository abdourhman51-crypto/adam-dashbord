import { NextResponse } from "next/server";
import { resolveParent } from "@/lib/telegram/parent";
import { supabaseAdmin } from "@/lib/supabase/admin";

export const dynamic = "force-dynamic";

interface StageStateRpc {
  in_stage: boolean;
  objective_text?: string;
  objective_target?: number;
  objective_window?: number;
  objective_current?: number | null;
  window_filled?: number;
  objective_met?: boolean;
  logged_days?: number;
  allowed_days?: number;
  days_remaining?: number;
  clock_exhausted?: boolean;
  extended?: boolean;
  phase?: "observe" | "build" | "hold";
  phase_ar?: string;
  baseline_text?: string | null;
}

export async function GET(request: Request) {
  const parent = await resolveParent(request);
  if (!parent.ok) {
    return NextResponse.json({ error: parent.message }, { status: parent.status });
  }

  const { data, error } = await supabaseAdmin().rpc("stage_state", {
    p_parent_id: parent.parentId,
  });

  if (error) {
    return NextResponse.json({ error: "تعذّر قراءة الرحلة" }, { status: 500 });
  }

  const stage = (data ?? { in_stage: false }) as StageStateRpc;

  if (!stage.in_stage) {
    return NextResponse.json({ inStage: false, childName: parent.childName });
  }

  return NextResponse.json({
    inStage: true,
    childName: parent.childName,
    objectiveText: stage.objective_text ?? null,
    objectiveTarget: stage.objective_target ?? null,
    objectiveWindow: stage.objective_window ?? null,
    objectiveCurrent: stage.objective_current ?? null,
    windowFilled: stage.window_filled ?? 0,
    objectiveMet: stage.objective_met ?? false,
    loggedDays: stage.logged_days ?? 0,
    allowedDays: stage.allowed_days ?? 0,
    daysRemaining: stage.days_remaining ?? 0,
    extended: stage.extended ?? false,
    phaseAr: stage.phase_ar ?? null,
    baselineText: stage.baseline_text ?? null,
  });
}
