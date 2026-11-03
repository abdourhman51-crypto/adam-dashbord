// Shape returned by public.noor_dashboard_stats (Supabase, adam-noor-inbox).
export type KV = { k: string; n: number };
export type Daily = { d: string; inbound: number; replies: number; new: number; signals: number; offers: number };
export type Follower = {
  id: string; name: string | null; username: string | null; channel: string | null; stage: string | null;
  country: string | null; problem: string | null; topics: string[]; objections: string[];
  children: { name?: string; age?: string }[]; offered: string[]; bought: string[]; customer: boolean;
  signals: number; replies: number; summary: string | null; last_seen: string;
};
export type Approval = {
  id: string; name: string | null; platform: string | null; status: "pending" | "approved" | "rejected";
  product: string | null; suggested: string | null; delivered: boolean; error: string | null; at: string;
};
export type NoorStats = {
  generated_at: string;
  days: number;
  totals: {
    conversations_all: number; conversations_new: number; inbound: number; active_conversations: number;
    replies_sent: number; replies_failed: number; grouped_messages: number; cancelled: number;
    reply_seconds_median: number | null; buying_signals: number; escalations: number; payment_proofs: number;
    profiles: number; customers: number; offered: number; offered_not_bought: number;
  };
  daily: Daily[];
  hours: { h: number; n: number }[];
  channels: Record<string, number>;
  stages: Record<string, number>;
  countries: KV[];
  problems: KV[];
  topics: KV[];
  objections: KV[];
  products: Record<string, { offered: number; bought: number }>;
  approvals: {
    pending: number; approved: number; rejected: number; undelivered: number;
    by_product: Record<string, number>; recent: Approval[];
  };
  followers: Follower[];
};

const URL_ = "https://vpinaehjfflnrlpfxlko.supabase.co/functions/v1/noor-dashboard";

export async function getNoor(days = 14): Promise<{ data: NoorStats | null; error: string | null }> {
  const token = process.env.NOOR_DASH_TOKEN;
  if (!token) return { data: null, error: "NOOR_DASH_TOKEN غير مضبوط في Vercel" };
  try {
    const r = await fetch(`${URL_}?days=${days}`, { headers: { "x-dash-token": token }, next: { revalidate: 60 } });
    if (!r.ok) return { data: null, error: `Supabase ردّ بـ ${r.status}` };
    return { data: (await r.json()) as NoorStats, error: null };
  } catch (e) {
    return { data: null, error: "تعذّر الوصول إلى Supabase: " + String(e instanceof Error ? e.message : e) };
  }
}

export const PRODUCTS: Record<string, { name: string; usd: number; dzd?: number }> = {
  hodn: { name: "من الصرخة إلى الحضن", usd: 9, dzd: 1900 },
  inad: { name: "وراء كلّ لا حكاية", usd: 12 },
  cards: { name: "بطاقات مشاعر آدم", usd: 7 },
  "21": { name: "21 يوماً (قائمة انتظار)", usd: 0 },
};

export const STAGES: Record<string, { label: string; tone: string }> = {
  cold: { label: "فضول", tone: "muted" },
  warm: { label: "تحكي مشكلتها", tone: "info" },
  ready: { label: "جاهزة للعرض", tone: "gold" },
  committed: { label: "ملتزمة", tone: "primary" },
  customer: { label: "مشترية", tone: "success" },
  freebie: { label: "تطلب مجاناً", tone: "muted" },
  closed: { label: "انتهت", tone: "muted" },
  unknown: { label: "غير محدد", tone: "muted" },
};
export const STAGE_ORDER = ["cold", "warm", "ready", "committed", "customer", "freebie", "closed", "unknown"];
