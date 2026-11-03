// Site funnel, computed in Supabase (adam_site_stats) from site_events, which n8n's hodn-track
// webhook mirrors live. One visitor = one sid; each step includes only visitors who reached the ones before it.

export type Step = { visitors: number; engaged: number; price: number; checkout: number; buyers: number };
export type SiteDay = Step & { d: string; paid: number };
export type SiteStats = {
  days: SiteDay[];
  funnel: Step & { paid: number };
  sources: (Step & { k: string })[];
  pages: (Step & { k: string })[];
  countries: { k: string; n: number }[];
  devices: { k: string; n: number }[];
  tools: { k: string; started: number; done: number }[];
  freeDownloads: number;
  waClicks: number;
  productClicks: number;
  fromNour: number;
  events_total: number;
  last_event_at: string | null;
};

const URL_ = "https://vpinaehjfflnrlpfxlko.supabase.co/functions/v1/noor-dashboard";

export async function getSite(days = 14): Promise<{ data: SiteStats | null; error: string | null }> {
  const token = process.env.NOOR_DASH_TOKEN;
  if (!token) return { data: null, error: "NOOR_DASH_TOKEN غير مضبوط في Vercel" };
  try {
    const r = await fetch(`${URL_}?view=site&days=${days}`, { headers: { "x-dash-token": token }, next: { revalidate: 120 } });
    if (!r.ok) return { data: null, error: `Supabase ردّ بـ ${r.status}` };
    return { data: (await r.json()) as SiteStats, error: null };
  } catch (e) {
    return { data: null, error: "تعذّر جلب أحداث الموقع: " + String(e instanceof Error ? e.message : e) };
  }
}

export const TOOL_NAMES: Record<string, string> = {
  mirror: "مرآة المشاعر", no: "مترجم «لا»", clock: "الساعة الحمراء", boil: "ميزان الغليان", breathe: "تسعون ثانية",
  tank: "خزّان الأم", swap: "بدّلي الجملة", repair: "بطاقة الإصلاح", father: "أي أبٍ أنت؟",
};

export const PAGE_NAMES: Record<string, string> = {
  "/": "الرئيسية / صفحة الحضن", "/hodn": "صفحة الحضن", "/hodn/a1": "الحضن · زاوية 1", "/hodn/a2": "الحضن · زاوية 2",
  "/hodn/a3": "الحضن · زاوية 3", "/en": "الصفحة الإنجليزية", "/shukran.html": "صفحة الشكر", "/cards": "صفحة البطاقات", "/21": "قائمة 21 يوماً",
};
export const pageName = (p: string) => PAGE_NAMES[p.replace(/\/$/, "") || "/"] ?? (p.startsWith("/tools/") ? "أداة: " + (TOOL_NAMES[p.slice(7).replace(/\/$/, "")] ?? p.slice(7)) : p);
