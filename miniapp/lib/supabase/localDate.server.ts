import { supabaseAdmin } from "@/lib/supabase/admin";

/** تاريخ اليوم بتوقيت عائلة الوالد (YYYY-MM-DD) — نفس منطق timezone الذي تستخدمه دوال السيرفر (record_harvest_answer إلخ). سيرفر فقط. */
export async function getLocalDateString(country: string | null): Promise<string> {
  let ianaTz = "UTC";
  if (country) {
    const { data: tz } = await supabaseAdmin()
      .from("country_timezone")
      .select("iana_tz")
      .eq("code", country.trim().toUpperCase())
      .maybeSingle();
    if (tz?.iana_tz) ianaTz = tz.iana_tz as string;
  }

  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: ianaTz,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(new Date());

  const year = parts.find((p) => p.type === "year")?.value ?? "1970";
  const month = parts.find((p) => p.type === "month")?.value ?? "01";
  const day = parts.find((p) => p.type === "day")?.value ?? "01";
  return `${year}-${month}-${day}`;
}
