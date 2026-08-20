const numberFormatter = new Intl.NumberFormat("ar", { maximumFractionDigits: 0 });
const weekdayFormatter = new Intl.DateTimeFormat("ar", { weekday: "long" });

/** أسماء الأشهر بالدارجة المستخدمة بالجزائر والمغرب العربي — لا الفصحى المشرقية */
const MAGHREBI_MONTHS = [
  "جانفي",
  "فيفري",
  "مارس",
  "أفريل",
  "ماي",
  "جوان",
  "جويلية",
  "أوت",
  "سبتمبر",
  "أكتوبر",
  "نوفمبر",
  "ديسمبر",
] as const;

export function formatNumber(n: number | null | undefined) {
  if (n === null || n === undefined || Number.isNaN(n)) return "٠";
  return numberFormatter.format(n);
}

/** "الثلاثاء، 12 جانفي" — لنقاط الخط الزمني، بأشهر الدارجة المغاربية */
export function formatNightLabel(logDate: string) {
  const d = new Date(`${logDate}T12:00:00`);
  return `${weekdayFormatter.format(d)}، ${d.getDate()} ${MAGHREBI_MONTHS[d.getMonth()]}`;
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
