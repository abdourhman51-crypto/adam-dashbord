const nf = new Intl.NumberFormat("ar-DZ-u-nu-latn");
export const n = (x: number | null | undefined) => (x == null ? "—" : nf.format(x));
export const pct = (a: number, b: number) => {
  if (!b) return "—";
  const v = (100 * a) / b;
  return (v > 0 && v < 10 ? v.toFixed(1) : Math.round(v)) + "%";
};
export const day = (d: string) => new Date(d + "T12:00:00Z").toLocaleDateString("ar-DZ-u-nu-latn", { day: "numeric", month: "short" });
export const ago = (iso: string) => {
  const s = (Date.now() - new Date(iso).getTime()) / 1000;
  if (s < 90) return "الآن";
  if (s < 3600) return `قبل ${Math.round(s / 60)} د`;
  if (s < 86400) return `قبل ${Math.round(s / 3600)} سا`;
  return `قبل ${Math.round(s / 86400)} يوم`;
};
export const secs = (s: number | null | undefined) => (s == null ? "—" : s < 90 ? `${s} ث` : `${Math.round(s / 60)} د`);
export const COUNTRY: Record<string, string> = {
  DZ: "الجزائر", SA: "السعودية", EG: "مصر", MA: "المغرب", TN: "تونس", FR: "فرنسا", AE: "الإمارات", JO: "الأردن", KW: "الكويت",
  QA: "قطر", IQ: "العراق", LB: "لبنان", SY: "سوريا", PS: "فلسطين", LY: "ليبيا", YE: "اليمن", OM: "عُمان", BH: "البحرين",
  SD: "السودان", US: "أمريكا", GB: "بريطانيا", DE: "ألمانيا", TR: "تركيا", CA: "كندا", "?": "غير معروف",
};
