export interface CriticalWindowSnapshot {
  labelAr: string;
  windowStartHour: number;
  windowEndHour: number;
  /** دقائق منذ منتصف الليل بتوقيت عائلة الوالد، لحظة استعلام السيرفر */
  serverNowMinutes: number;
  /** وقت السيرفر بالمللي ثانية لحظة الحساب — المرجع لمتابعة العدّاد حياً بالعميل */
  serverTimestampMs: number;
}

const APPROACH_LOOKAHEAD_MINUTES = 45;

/** دالة صِرفة آمنة للعميل — بلا أي استيراد لـ Supabase. */
export function criticalWindowState(
  nowMinutes: number,
  startHour: number,
  endHour: number
): "in_window" | "approaching" | "calm" {
  const start = startHour * 60;
  const end = endHour * 60;
  if (nowMinutes >= start && nowMinutes < end) return "in_window";
  if (nowMinutes >= start - APPROACH_LOOKAHEAD_MINUTES && nowMinutes < start) return "approaching";
  return "calm";
}
