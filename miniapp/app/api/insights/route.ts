import { NextResponse } from "next/server";
import { resolveParent } from "@/lib/telegram/parent";
import { supabaseAdmin } from "@/lib/supabase/admin";
import { safeParseLightMemory } from "@/lib/format";
import { getLocalDateString } from "@/lib/supabase/localDate.server";

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

interface DoneRow {
  log_date: string;
  step_given: string | null;
}

export async function GET(request: Request) {
  const parent = await resolveParent(request);
  if (!parent.ok) {
    return NextResponse.json({ error: parent.message }, { status: parent.status });
  }

  const db = supabaseAdmin();
  const today = await getLocalDateString(parent.country);

  const [followerRes, nightsRes, effortRes, patternsRes, wallRes, todayRes] = await Promise.all([
    db.from("followers").select("light_memory").eq("id", parent.parentId).maybeSingle(),
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
    db
      .from("daily_logs")
      .select("log_date, step_given")
      .eq("follower_id", parent.parentId)
      .eq("step_status", "done")
      .eq("night_result", "calm")
      .not("step_given", "is", null)
      .order("log_date", { ascending: false })
      .limit(20),
    db
      .from("daily_logs")
      .select("seed_sent_at, harvest_answered_at")
      .eq("follower_id", parent.parentId)
      .eq("log_date", today)
      .maybeSingle(),
  ]);

  if (nightsRes.error || effortRes.error || patternsRes.error || wallRes.error) {
    return NextResponse.json({ error: "تعذّر قراءة هذي الشاشة" }, { status: 500 });
  }

  const memory = safeParseLightMemory(followerRes.data?.light_memory ?? null);
  const nights = (nightsRes.data ?? []) as NightRow[];
  const patterns = (patternsRes.data ?? []) as PatternRow[];
  const moments = (wallRes.data ?? []) as DoneRow[];
  const effort = (effortRes.data ?? {}) as Record<string, number>;
  const todayRow = todayRes.data as { seed_sent_at: string | null; harvest_answered_at: string | null } | null;
  const todayOpen = Boolean(todayRow?.seed_sent_at && !todayRow?.harvest_answered_at);

  return NextResponse.json({
    isPaid: parent.isPaid,
    childName: parent.childName,
    insight: memory?.child_insight ?? null,
    effort: {
      triedThisWeek: effort.tried_this_week ?? 0,
      triedLastWeek: effort.tried_last_week ?? 0,
      calmThisWeek: effort.calm_this_week ?? 0,
      calmLastWeek: effort.calm_last_week ?? 0,
      triedEver: effort.tried_ever ?? 0,
    },
    todayOpen,
    nights: nights.map((n) => ({
      logDate: n.log_date,
      result: n.night_result,
      stepGiven: n.step_given,
      stepStatus: n.step_status,
    })),
    patterns: patterns.map((p) => ({ label: p.pattern_label, description: p.description })),
    wall: {
      isPaid: parent.isPaid,
      moments: moments.map((m) => ({ logDate: m.log_date, stepGiven: m.step_given })),
    },
  });
}
