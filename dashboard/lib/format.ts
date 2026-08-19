const numberFormatter = new Intl.NumberFormat("ar", { maximumFractionDigits: 0 });
const percentFormatter = new Intl.NumberFormat("ar", { maximumFractionDigits: 1 });
const dateFormatter = new Intl.DateTimeFormat("ar", { day: "numeric", month: "short", year: "numeric" });
const dateTimeFormatter = new Intl.DateTimeFormat("ar", {
  day: "numeric",
  month: "short",
  year: "numeric",
  hour: "numeric",
  minute: "2-digit",
});
const timeFormatter = new Intl.DateTimeFormat("ar", { hour: "numeric", minute: "2-digit" });

export function formatNumber(n: number | null | undefined) {
  if (n === null || n === undefined || Number.isNaN(n)) return "—";
  return numberFormatter.format(n);
}

export function formatPercent(n: number | null | undefined) {
  if (n === null || n === undefined || Number.isNaN(n)) return "—";
  return `${percentFormatter.format(n)}٪`;
}

export function formatDate(iso: string | null | undefined) {
  if (!iso) return "—";
  return dateFormatter.format(new Date(iso));
}

export function formatDateTime(iso: string | null | undefined) {
  if (!iso) return "—";
  return dateTimeFormatter.format(new Date(iso));
}

export function formatTime(iso: string | null | undefined) {
  if (!iso) return "—";
  return timeFormatter.format(new Date(iso));
}

export function formatCurrency(amount: number | null | undefined, currency: string | null | undefined) {
  if (amount === null || amount === undefined) return "—";
  return `${numberFormatter.format(amount)} ${currency ?? ""}`.trim();
}

export function relativeTime(iso: string | null | undefined) {
  if (!iso) return "—";
  const then = new Date(iso).getTime();
  const diffMs = Date.now() - then;
  const diffMin = Math.round(diffMs / 60000);
  if (diffMin < 1) return "الآن";
  if (diffMin < 60) return `منذ ${formatNumber(diffMin)} د`;
  const diffH = Math.round(diffMin / 60);
  if (diffH < 24) return `منذ ${formatNumber(diffH)} س`;
  const diffD = Math.round(diffH / 24);
  if (diffD < 30) return `منذ ${formatNumber(diffD)} يوم`;
  return formatDate(iso);
}

export const FUNNEL_STAGE_LABELS: Record<string, string> = {
  free_conversation: "محادثة مجانية",
  offer_presented: "عُرض عليه الاشتراك",
  payment_pending_manual: "بانتظار تأكيد الدفع",
  paid_active: "مشترك نشط",
  waitlist_non_algerian: "قائمة انتظار",
  expired: "منتهي",
};

export const STAGE_STATUS_LABELS: Record<string, string> = {
  proposed: "مُقترحة",
  active: "نشطة",
  extended: "مُمدَّدة",
  completed: "مكتملة",
  failed: "لم تتحقق",
  paused: "مُوقفة",
  refunded: "مُستردة",
  cancelled: "مُلغاة",
};

export const STAGE_PHASE_LABELS: Record<string, string> = {
  observe: "مراقبة",
  build: "بناء",
  hold: "تثبيت",
};

export const STRAIN_LEVEL_LABELS: Record<number, string> = {
  1: "طبيعي",
  2: "ضغط مرتفع",
  3: "خطر",
};

export const NIGHT_RESULT_LABELS: Record<string, string> = {
  calm: "هادئة",
  hard: "صعبة",
  normal: "عادية",
};

export const STEP_STATUS_LABELS: Record<string, string> = {
  done: "تمّت",
  tried_failed: "جُرّبت ولم تنجح",
  not_tried: "لم تُجرَّب",
};

export const PROBLEM_LABELS: Record<string, string> = {
  anger: "نوبات الغضب والصراخ",
  out: "الاستعداد والخروج من البيت",
  screen: "وقت الشاشة",
  stubborn: "العناد ورفض التعليمات",
  study: "الدراسة والواجبات",
  sleep: "النوم",
  meal: "الطعام",
  sibling: "الغيرة من الإخوة أو المقارنة",
};

export const SITUATION_LABELS: Record<string, string> = {
  sleep: "عند النوم",
  study: "عند الدراسة",
  meal: "عند الأكل",
  screen: "وقت الشاشة",
  out: "عند الخروج",
  other: "موقف آخر",
};

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
