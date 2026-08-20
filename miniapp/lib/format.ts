const numberFormatter = new Intl.NumberFormat("ar", { maximumFractionDigits: 0 });
const dayLabelFormatter = new Intl.DateTimeFormat("ar", { day: "numeric", month: "long" });
const weekdayFormatter = new Intl.DateTimeFormat("ar", { weekday: "long" });

export function formatNumber(n: number | null | undefined) {
  if (n === null || n === undefined || Number.isNaN(n)) return "٠";
  return numberFormatter.format(n);
}

/** "الثلاثاء، ١٢ أغسطس" — لنقاط الخط الزمني */
export function formatNightLabel(logDate: string) {
  const d = new Date(`${logDate}T12:00:00`);
  return `${weekdayFormatter.format(d)}، ${dayLabelFormatter.format(d)}`;
}

export function safeParseLightMemory(raw: string | null): Record<string, string> | null {
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw);
    if (parsed && typeof parsed === "object") return parsed as Record<string, string>;
    return null;
  } catch {
    return null;
  }
}
