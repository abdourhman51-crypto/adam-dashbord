"use client";

import { useEffect, useState } from "react";
import { haptic } from "@/lib/telegram/client";

const SEEN_KEY = "adam_welcomed";
const WELCOME_IMAGE_URL =
  "https://d8j0ntlcm91z4.cloudfront.net/user_3CPnImgjiKIeQIfolIn0s2fo89h/hf_20260821_202241_ecd9d6d8-6e6c-4c90-8bc1-9da346ed015f.png";

export function WelcomeSplash() {
  const [show, setShow] = useState(false);

  useEffect(() => {
    try {
      if (!window.localStorage.getItem(SEEN_KEY)) setShow(true);
    } catch {
      // خصوصية المتصفح تمنع localStorage أحياناً — لا نعرض الترحيب حينها بأمان
    }
  }, []);

  if (!show) return null;

  function dismiss() {
    haptic("light");
    try {
      window.localStorage.setItem(SEEN_KEY, "1");
    } catch {
      // تجاهل بأمان
    }
    setShow(false);
  }

  return (
    <div className="fixed inset-0 z-50 flex flex-col items-center justify-end bg-bg-deep">
      <div className="tree-backdrop" aria-hidden="true" style={{ opacity: 0.1 }} />
      <div className="relative z-10 flex w-full flex-1 items-end justify-center overflow-hidden">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src={WELCOME_IMAGE_URL}
          alt="آدم يرحّب بكم"
          className="max-h-[65vh] w-auto object-contain"
        />
      </div>
      <div className="relative z-10 flex flex-col items-center gap-4 px-6 pb-[max(env(safe-area-inset-bottom),32px)] pt-6 text-center">
        <p className="font-display text-[22px] text-gold-strong">أهلاً، أنا آدم</p>
        <p className="max-w-xs text-sm leading-relaxed text-text-secondary">
          هذي مساحتكم الخاصة — أتابع فيها معكم كل خطوة، وأحكي لكم بصدق كيف تمشي الأمور.
        </p>
        <button type="button" onClick={dismiss} className="pressable-gold w-full max-w-xs px-6 py-3 text-sm font-semibold">
          نبدأ
        </button>
      </div>
    </div>
  );
}
