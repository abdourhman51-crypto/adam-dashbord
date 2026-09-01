"use client";

import { useEffect, useRef } from "react";
import { usePathname } from "next/navigation";
import { trackScreenView, trackScreenTime, trackSessionStart } from "@/lib/analytics";

const SCREEN_NAMES: Record<string, string> = {
  "/": "home",
  "/insights": "insights",
  "/child": "child",
  "/journey": "journey",
  "/journey/start": "journey_start",
};

function screenNameFor(pathname: string): string {
  return SCREEN_NAMES[pathname] ?? (pathname.replace(/^\//, "").replace(/\//g, "_") || "home");
}

/**
 * مكوّن واحد في الـ layout يتتبّع كل شاشة تلقائياً — بلا حاجة لتعديل كل صفحة
 * على حدة. يراقب تغيّر المسار: عند كل تغيّر، يسجّل وقت الشاشة السابقة، ثم
 * يبدأ عدّاً جديداً للشاشة الحالية. visibilitychange يغطي إخفاء التبويب دون
 * تغيير مسار (قفل الشاشة، تبديل تطبيق)، وpagehide يغطي إغلاق التطبيق فعلياً.
 */
export function ScreenViewTracker() {
  const pathname = usePathname();
  const enteredAtRef = useRef<number>(Date.now());
  const currentScreenRef = useRef<string | null>(null);

  useEffect(() => {
    trackSessionStart();
  }, []);

  useEffect(() => {
    const screen = screenNameFor(pathname);

    if (currentScreenRef.current) {
      trackScreenTime(currentScreenRef.current, Date.now() - enteredAtRef.current);
    }

    currentScreenRef.current = screen;
    enteredAtRef.current = Date.now();
    trackScreenView(screen);
  }, [pathname]);

  useEffect(() => {
    function flushOnHide() {
      if (document.visibilityState !== "hidden") return;
      if (currentScreenRef.current) {
        trackScreenTime(currentScreenRef.current, Date.now() - enteredAtRef.current);
      }
      enteredAtRef.current = Date.now();
    }
    function flushOnLeave() {
      if (currentScreenRef.current) {
        trackScreenTime(currentScreenRef.current, Date.now() - enteredAtRef.current);
      }
    }
    document.addEventListener("visibilitychange", flushOnHide);
    window.addEventListener("pagehide", flushOnLeave);
    return () => {
      document.removeEventListener("visibilitychange", flushOnHide);
      window.removeEventListener("pagehide", flushOnLeave);
    };
  }, []);

  return null;
}
