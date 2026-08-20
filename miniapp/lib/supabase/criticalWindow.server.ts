import { supabaseAdmin } from "@/lib/supabase/admin";
import type { CriticalWindowSnapshot } from "@/lib/criticalWindow";

/** يقرأ الموقف المؤكّد الأبرز لهذا الوالد + توقيته المحلي الحقيقي — أو null لو ما فيه موقف مؤكّد بعد. سيرفر فقط. */
export async function getCriticalWindow(
  parentId: string,
  country: string | null
): Promise<CriticalWindowSnapshot | null> {
  const db = supabaseAdmin();

  const { data: situation } = await db
    .from("situations")
    .select("label_ar, window_start, window_end")
    .eq("parent_id", parentId)
    .eq("status", "confirmed")
    .order("evidence_count", { ascending: false })
    .order("last_observed", { ascending: false })
    .limit(1)
    .maybeSingle();

  if (!situation) return null;

  let ianaTz = "UTC";
  if (country) {
    const { data: tz } = await db
      .from("country_timezone")
      .select("iana_tz")
      .eq("code", country.trim().toUpperCase())
      .maybeSingle();
    if (tz?.iana_tz) ianaTz = tz.iana_tz as string;
  }

  const now = new Date();
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone: ianaTz,
    hour: "numeric",
    minute: "numeric",
    hourCycle: "h23",
  }).formatToParts(now);
  const hour = Number(parts.find((p) => p.type === "hour")?.value ?? "0");
  const minute = Number(parts.find((p) => p.type === "minute")?.value ?? "0");

  return {
    labelAr: situation.label_ar as string,
    windowStartHour: situation.window_start as number,
    windowEndHour: situation.window_end as number,
    serverNowMinutes: hour * 60 + minute,
    serverTimestampMs: now.getTime(),
  };
}
