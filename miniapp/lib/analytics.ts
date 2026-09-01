"use client";

import { getInitDataRaw } from "./telegram/client";

const SESSION_KEY = "adam_miniapp_session_id";
const SESSION_START_SENT_KEY = "adam_miniapp_session_start_sent";

function getSessionId(): string {
  if (typeof window === "undefined") return "";
  let id = sessionStorage.getItem(SESSION_KEY);
  if (!id) {
    id = crypto.randomUUID();
    sessionStorage.setItem(SESSION_KEY, id);
  }
  return id;
}

type EventType = "screen_view" | "screen_time" | "click" | "session_start";

interface TrackPayload {
  event_type: EventType;
  screen?: string;
  element?: string;
  meta?: Record<string, unknown>;
}

/**
 * initData يصل هنا عبر معامل الرابط لا الترويسة، لأن navigator.sendBeacon —
 * الوسيلة الوحيدة الموثوقة لإرسال آخر حدث عند إغلاق التطبيق أو تبديل الشاشة —
 * لا يسمح بترويسات مخصّصة، فقط رابط وجسم. /api/track هو المسار الوحيد الذي
 * يقبل initData بهذه الطريقة تحديداً.
 */
function send(payload: TrackPayload) {
  const initData = getInitDataRaw();
  if (!initData) return; // خارج تيليجرام — لا تتبّع

  const body = JSON.stringify({ ...payload, session_id: getSessionId() });
  const url = `/api/track?d=${encodeURIComponent(initData)}`;

  try {
    if (navigator.sendBeacon) {
      const blob = new Blob([body], { type: "application/json" });
      if (navigator.sendBeacon(url, blob)) return;
    }
  } catch {
    // تجاهل، وجرّب fetch كبديل
  }

  fetch(url, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body,
    keepalive: true,
  }).catch(() => {});
}

export function trackScreenView(screen: string) {
  send({ event_type: "screen_view", screen });
}

export function trackScreenTime(screen: string, durationMs: number) {
  if (durationMs < 200) return; // انتقال شبه فوري، لا وقت حقيقي على الشاشة
  send({ event_type: "screen_time", screen, meta: { duration_ms: Math.round(durationMs) } });
}

export function trackClick(element: string, screen?: string) {
  send({ event_type: "click", element, screen });
}

export function trackSessionStart() {
  if (typeof window === "undefined") return;
  if (sessionStorage.getItem(SESSION_START_SENT_KEY)) return;
  sessionStorage.setItem(SESSION_START_SENT_KEY, "1");
  send({ event_type: "session_start" });
}
