"use client";

export function getWebApp() {
  if (typeof window === "undefined") return null;
  return window.Telegram?.WebApp ?? null;
}

export function getInitDataRaw(): string | null {
  const wa = getWebApp();
  return wa?.initData && wa.initData.length > 0 ? wa.initData : null;
}

export function openLink(url: string) {
  const wa = getWebApp();
  if (wa?.openTelegramLink && url.startsWith("https://t.me/")) {
    wa.openTelegramLink(url);
    return;
  }
  window.open(url, "_blank", "noopener,noreferrer");
}

export function haptic(style: "light" | "medium" | "heavy" = "light") {
  try {
    getWebApp()?.HapticFeedback?.impactOccurred(style);
  } catch {
    // تجاهل بأمان — ليست كل الأجهزة تدعم الاهتزاز
  }
}

export function initWebApp() {
  const wa = getWebApp();
  if (!wa) return;
  wa.ready();
  wa.expand();
  try {
    wa.setHeaderColor?.("#0d1a12");
    wa.setBackgroundColor?.("#0d1a12");
    wa.disableVerticalSwipes?.();
  } catch {
    // بعض إصدارات العميل لا تدعم هذه الاستدعاءات — تجاهل بأمان
  }
}
