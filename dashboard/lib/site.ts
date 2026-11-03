// Site funnel from the n8n data table hodn_events (via the hodn-report webhook).
// Same rules as the Telegram report: one visitor = one sid, test traffic removed,
// a sale counts once per visitor (purchase / whop_complete) or per Whop payment webhook.

type Row = { ts: string; sid: string; event: string; page?: string; src?: string; country?: string; detail?: string; device?: string };

const REPORT_URL = "https://adam-voices-n8n.hawiyat.cloud/webhook/hodn-report-k7x29q";
const OFFSET = 60 * 60 * 1000; // Algeria, UTC+1

export type SiteDay = { d: string; visitors: number; engaged: number; price: number; checkout: number; buyers: number; paid: number };
export type SiteStats = {
  days: SiteDay[];
  funnel: { visitors: number; engaged: number; price: number; checkout: number; buyers: number; paid: number };
  sources: { k: string; visitors: number; buyers: number }[];
  countries: { k: string; n: number }[];
  devices: { k: string; n: number }[];
  tools: { k: string; started: number; done: number }[];
  freeDownloads: number;
  waClicks: number;
  productClicks: number;
};

const dayKey = (t: number) => new Date(t + OFFSET).toISOString().slice(0, 10);

const SOURCE = (src: string) => {
  const f = (src || "").toLowerCase();
  if (/^ig_a[123]$/.test(f)) return "إعلانات إنستغرام";
  if (f === "ig_bio") return "رابط البايو";
  if (f === "ig_dm") return "رسائل إنستغرام (نور)";
  if (/instagram/.test(f)) return "منشورات إنستغرام";
  if (/facebook|fb/.test(f)) return "فيسبوك";
  if (f === "wa_channel") return "قناة واتساب";
  if (/google/.test(f)) return "قوقل";
  if (!f || /adamvoices|direct|sanitized/.test(f)) return "مباشر";
  return f;
};

const TOOL_NAMES: Record<string, string> = {
  mirror: "مرآة المشاعر", no: "مترجم «لا»", clock: "الساعة الحمراء", boil: "ميزان الغليان", breathe: "تسعون ثانية",
  tank: "خزّان الأم", swap: "بدّلي الجملة", repair: "بطاقة الإصلاح", father: "أي أبٍ أنت؟",
};

export async function getSite(days = 14): Promise<{ data: SiteStats | null; error: string | null }> {
  let rows: Row[];
  try {
    const r = await fetch(REPORT_URL, { next: { revalidate: 300 } });
    if (!r.ok) return { data: null, error: `تقرير الموقع ردّ بـ ${r.status}` };
    const j = await r.json();
    rows = (Array.isArray(j) ? j : []).map((x: { json?: Row } & Row) => x.json ?? x);
  } catch (e) {
    return { data: null, error: "تعذّر جلب أحداث الموقع: " + String(e instanceof Error ? e.message : e) };
  }
  return { data: aggregate(rows, days), error: null };
}

export function aggregate(all: Row[], days: number, now = Date.now()): SiteStats {
  const start = Math.floor((now + OFFSET) / 86400000) * 86400000 - OFFSET - (days - 1) * 86400000;
  const T = (r: Row) => new Date(r.ts).getTime();
  const NOISE = /test|vercel\.(app|com)|eventsmanager/i;
  const rows = all.filter(
    (r) => r && r.sid && r.event && T(r) >= start && !NOISE.test(r.src || "") && r.sid !== "claude1" && !/test\.html/.test(r.page || ""),
  );
  const J = (r: Row) => { try { return JSON.parse(r.detail || "{}"); } catch { return {}; } };

  // A Whop payment webhook has no visitor behind it; count it on its own.
  const hooks = rows.filter((r) => r.src === "whop_webhook" && /payment\.succeeded/.test(r.event));
  const visits = rows.filter((r) => r.src !== "whop_webhook");

  const bySid = new Map<string, Row[]>();
  for (const r of visits) (bySid.get(r.sid) ?? bySid.set(r.sid, []).get(r.sid)!).push(r);

  type V = { day: string; src: string; country: string; device: string; engaged: boolean; price: boolean; checkout: boolean; buyer: boolean; product: boolean };
  const visitors: V[] = [];
  for (const [, rs] of bySid) {
    rs.sort((a, b) => T(a) - T(b));
    const has = (f: (r: Row) => boolean) => rs.some(f);
    const ad = rs.find((r) => /^ig_a[123]$/.test(r.src || ""));
    const pv = rs.find((r) => r.event === "page_view" && r.src);
    // Each step implies the ones before it, so the funnel never grows from one step to the next.
    const buyer = has((r) => r.event === "purchase" || r.event === "whop_complete");
    const checkout = buyer || has((r) => r.event === "cta_click" || r.event === "whop_link");
    const price = checkout || has((r) => r.event === "view_buy");
    const engaged = price || has((r) => r.event === "engaged" || r.event === "moved" || (r.event === "scroll" && Number(r.detail) >= 25) || r.event === "tool_start");
    const c = (rs.find((r) => r.country)?.country || "?").toUpperCase();
    visitors.push({
      day: dayKey(T(rs[0])),
      src: SOURCE(ad?.src || pv?.src || rs.find((r) => r.src)?.src || ""),
      country: c === "WORLD" || c === "XX" ? "?" : c,
      device: rs.find((r) => r.device)?.device || "?",
      engaged, price, checkout, buyer,
      product: has((r) => r.event === "product_click"),
    });
  }

  const dayList: SiteDay[] = [];
  for (let i = 0; i < days; i++) {
    const d = dayKey(start + i * 86400000 + 1);
    const vs = visitors.filter((v) => v.day === d);
    dayList.push({
      d, visitors: vs.length, engaged: vs.filter((v) => v.engaged).length, price: vs.filter((v) => v.price).length,
      checkout: vs.filter((v) => v.checkout).length, buyers: vs.filter((v) => v.buyer).length,
      paid: hooks.filter((r) => dayKey(T(r)) === d).length,
    });
  }
  const sum = (k: keyof Omit<SiteDay, "d">) => dayList.reduce((a, x) => a + x[k], 0);

  const count = (keyOf: (v: V) => string) => {
    const m = new Map<string, number>();
    for (const v of visitors) m.set(keyOf(v), (m.get(keyOf(v)) ?? 0) + 1);
    return [...m].map(([k, n]) => ({ k, n })).sort((a, b) => b.n - a.n);
  };
  const srcMap = new Map<string, { visitors: number; buyers: number }>();
  for (const v of visitors) {
    const s = srcMap.get(v.src) ?? { visitors: 0, buyers: 0 };
    s.visitors++; if (v.buyer) s.buyers++;
    srcMap.set(v.src, s);
  }

  const toolOf = (r: Row) => J(r).tool || ((r.page || "").match(/\/tools\/([a-z]+)/) || [])[1] || "";
  const tools = Object.keys(TOOL_NAMES).map((t) => ({
    k: TOOL_NAMES[t],
    started: new Set(visits.filter((r) => r.event === "tool_start" && toolOf(r) === t).map((r) => r.sid)).size,
    done: new Set(visits.filter((r) => r.event === "tool_done" && toolOf(r) === t).map((r) => r.sid)).size,
  })).filter((x) => x.started || x.done).sort((a, b) => b.started - a.started);

  return {
    days: dayList,
    funnel: { visitors: sum("visitors"), engaged: sum("engaged"), price: sum("price"), checkout: sum("checkout"), buyers: sum("buyers"), paid: sum("paid") },
    sources: [...srcMap].map(([k, s]) => ({ k, ...s })).sort((a, b) => b.visitors - a.visitors).slice(0, 10),
    countries: count((v) => v.country).slice(0, 8),
    devices: count((v) => v.device).slice(0, 5),
    tools,
    freeDownloads: new Set(visits.filter((r) => r.event === "free_dl").map((r) => r.sid)).size,
    waClicks: new Set(visits.filter((r) => r.event === "wa_click").map((r) => r.sid)).size,
    productClicks: visitors.filter((v) => v.product).length,
  };
}
