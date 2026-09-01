import { cache } from "react";
import { supabaseAdmin } from "@/lib/supabase/admin";

/**
 * كل هذه الأرقام مصدرها public.miniapp_events عبر دوال Postgres مخصّصة
 * (get_miniapp_*) — الجدول قد ينمو كثيراً بخلاف جداول الكيانات الصغيرة في
 * shared.ts، لذلك التجميع يحدث في قاعدة البيانات لا بجلب كل الصفوف هنا.
 */

export interface MiniappOverview {
  totalVisitors: number;
  visitorsToday: number;
  visitors7d: number;
  visitors30d: number;
  sessionsToday: number;
  sessions7d: number;
  totalScreenViews: number;
  avgSessionSeconds: number;
}

export const getMiniappOverview = cache(async (): Promise<MiniappOverview> => {
  const { data, error } = await supabaseAdmin().rpc("get_miniapp_overview");
  if (error) throw new Error(error.message);
  const d = (data ?? {}) as Record<string, number>;
  return {
    totalVisitors: d.total_visitors ?? 0,
    visitorsToday: d.visitors_today ?? 0,
    visitors7d: d.visitors_7d ?? 0,
    visitors30d: d.visitors_30d ?? 0,
    sessionsToday: d.sessions_today ?? 0,
    sessions7d: d.sessions_7d ?? 0,
    totalScreenViews: d.total_screen_views ?? 0,
    avgSessionSeconds: d.avg_session_seconds ?? 0,
  };
});

export interface MiniappDailyPoint {
  day: string;
  visitors: number;
  sessions: number;
  screenViews: number;
}

export const getMiniappDailyActive = cache(async (days = 30): Promise<MiniappDailyPoint[]> => {
  const { data, error } = await supabaseAdmin().rpc("get_miniapp_daily_active", { p_days: days });
  if (error) throw new Error(error.message);
  return ((data ?? []) as Array<{ day: string; visitors: number; sessions: number; screen_views: number }>).map(
    (r) => ({ day: r.day, visitors: r.visitors, sessions: r.sessions, screenViews: r.screen_views })
  );
});

const SCREEN_LABELS: Record<string, string> = {
  home: "الآن (الرئيسية)",
  insights: "طريقتي",
  child: "طفلي",
  journey: "رحلتي",
  journey_start: "استمارة الرحلة",
};

export function screenLabel(screen: string): string {
  return SCREEN_LABELS[screen] ?? screen;
}

export interface MiniappScreenStat {
  screen: string;
  views: number;
  uniqueVisitors: number;
  avgSeconds: number;
  exits: number;
  exitRate: number;
}

export const getMiniappScreenPerformance = cache(async (): Promise<MiniappScreenStat[]> => {
  const { data, error } = await supabaseAdmin().rpc("get_miniapp_screen_performance");
  if (error) throw new Error(error.message);
  return (
    (data ?? []) as Array<{
      screen: string;
      views: number;
      unique_visitors: number;
      avg_seconds: number;
      exits: number;
      exit_rate: number;
    }>
  ).map((r) => ({
    screen: r.screen,
    views: r.views,
    uniqueVisitors: r.unique_visitors,
    avgSeconds: r.avg_seconds,
    exits: r.exits,
    exitRate: r.exit_rate,
  }));
});

export interface MiniappClickStat {
  element: string;
  screen: string | null;
  clicks: number;
}

export const getMiniappTopClicks = cache(async (limit = 15): Promise<MiniappClickStat[]> => {
  const { data, error } = await supabaseAdmin().rpc("get_miniapp_top_clicks", { p_limit: limit });
  if (error) throw new Error(error.message);
  return ((data ?? []) as Array<{ element: string; screen: string | null; clicks: number }>).map((r) => ({
    element: r.element,
    screen: r.screen,
    clicks: r.clicks,
  }));
});

export interface MiniappRetention {
  newToday: number;
  returningToday: number;
  d1Retention: number | null;
  d1SampleSize: number;
  d7Retention: number | null;
  d7SampleSize: number;
}

export const getMiniappRetention = cache(async (): Promise<MiniappRetention> => {
  const { data, error } = await supabaseAdmin().rpc("get_miniapp_retention");
  if (error) throw new Error(error.message);
  const d = (data ?? {}) as Record<string, number | null>;
  return {
    newToday: d.new_today ?? 0,
    returningToday: d.returning_today ?? 0,
    d1Retention: d.d1_retention ?? null,
    d1SampleSize: d.d1_sample_size ?? 0,
    d7Retention: d.d7_retention ?? null,
    d7SampleSize: d.d7_sample_size ?? 0,
  };
});
