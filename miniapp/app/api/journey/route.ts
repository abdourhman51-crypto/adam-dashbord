import { NextResponse } from "next/server";
import { resolveParent } from "@/lib/telegram/parent";
import { supabaseAdmin } from "@/lib/supabase/admin";
import { getCriticalWindow } from "@/lib/supabase/criticalWindow.server";

export const dynamic = "force-dynamic";

interface StageStateRpc {
  in_stage: boolean;
  stage_id?: string;
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

interface StoryRow {
  log_date: string;
  step_given: string | null;
  step_status: "done" | "tried_failed" | "not_tried" | null;
  night_result: "calm" | "hard" | "normal" | null;
}

/**
 * سطر واحد لكل يوم مختار في قصة الرحلة — مبني حصراً من حقول حقيقية
 * (step_given/step_status/night_result). ما نختلق حالة نفسية للوالد لم
 * تُسجَّل فعلاً؛ الجملة تصف الفعل والنتيجة، لا تفسّرهما.
 */
function storyLine(row: StoryRow, child: string): string {
  if (!row.step_given) {
    if (row.night_result === "calm") return "ليلة هادئة، بلا خطوة محدّدة مسجّلة.";
    if (row.night_result === "hard") return "ليلة صعبة — بدأنا نراقب.";
    return "يوم البداية — بدأنا نراقب.";
  }
  if (row.step_status === "done" && row.night_result === "calm") {
    return `جرّبتوا «${row.step_given}»، وهدأ ${child}.`;
  }
  if (row.step_status === "tried_failed") {
    return `جرّبتوا «${row.step_given}»، لكن الليلة كانت صعبة.`;
  }
  if (row.step_status === "done") {
    return `جرّبتوا «${row.step_given}».`;
  }
  return `آدم اقترح: «${row.step_given}».`;
}

export async function GET(request: Request) {
  const parent = await resolveParent(request);
  if (!parent.ok) {
    return NextResponse.json({ error: parent.message }, { status: parent.status });
  }

  // مستخدم مجاني: لا توجد بيانات رحلة حقيقية أصلاً — لا نستعلم، لا نُرجع أي رقم حقيقي.
  if (!parent.isPaid) {
    return NextResponse.json({ isPaid: false, childName: parent.childName });
  }

  const [stageRes, criticalWindow] = await Promise.all([
    supabaseAdmin().rpc("stage_state", { p_parent_id: parent.parentId }),
    getCriticalWindow(parent.parentId, parent.country),
  ]);

  if (stageRes.error) {
    return NextResponse.json({ error: "تعذّر قراءة الرحلة" }, { status: 500 });
  }

  const stage = (stageRes.data ?? { in_stage: false }) as StageStateRpc;

  // ⭐ لا رحلة نشطة لا تعني بالضرورة "لم يبدأ بعد" — قد يكون قد أنهى رحلته
  // للتوّ (close_stage تحوّل الحالة إلى completed/failed ولا تُبقيها active).
  // الرسالة العامة "ما عندكم رحلة نشطة" كانت تُقال للحالتين بلا تمييز؛
  // نميّز هنا لنعرض إنجازاً حقيقياً بدل جملة محايدة تبتلع نجاحاً فعلياً.
  if (!stage.in_stage) {
    const lastStageRes = await supabaseAdmin()
      .from("stages")
      .select("status, objective_text, started_at, completed_at")
      .eq("parent_id", parent.parentId)
      .in("status", ["completed", "failed"])
      .order("completed_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    const last = lastStageRes.data as
      | { status: "completed" | "failed"; objective_text: string; started_at: string; completed_at: string }
      | null;

    return NextResponse.json({
      isPaid: true,
      inStage: false,
      childName: parent.childName,
      lastStage: last
        ? {
            status: last.status,
            objectiveText: last.objective_text,
            daysTogether: Math.max(
              1,
              Math.round((new Date(last.completed_at).getTime() - new Date(last.started_at).getTime()) / 86400000)
            ),
          }
        : null,
    });
  }

  const child = parent.childName ?? "طفلكم";
  let storyDays: { dayNumber: number; logDate: string; line: string }[] = [];

  if (stage.stage_id) {
    const stageRow = await supabaseAdmin().from("stages").select("started_at").eq("id", stage.stage_id).maybeSingle();
    const startedAt = stageRow.data?.started_at as string | undefined;
    if (startedAt) {
      const startDate = startedAt.slice(0, 10);
      const logsRes = await supabaseAdmin()
        .from("daily_logs")
        .select("log_date, step_given, step_status, night_result")
        .eq("follower_id", parent.parentId)
        .gte("log_date", startDate)
        .order("log_date", { ascending: true })
        .limit(60);
      const rows = (logsRes.data ?? []) as StoryRow[];
      const n = rows.length;
      const indices = n === 0 ? [] : n <= 2 ? rows.map((_, i) => i) : [0, Math.floor((n - 1) / 2), n - 1];
      storyDays = indices.map((i) => ({
        dayNumber: i + 1,
        logDate: rows[i].log_date,
        line: storyLine(rows[i], child),
      }));
    }
  }

  return NextResponse.json({
    isPaid: true,
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
    storyDays,
    criticalWindow,
  });
}
