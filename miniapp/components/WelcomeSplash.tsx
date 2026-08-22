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
    <div className="fixed inset-0 z-50 bg-bg-deep">
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img src={WELCOME_IMAGE_URL} alt="آدم يرحّب بكم" className="absolute inset-0 h-full w-full object-cover" />
      <div
        className="absolute inset-0"
        style={{
          background:
            "linear-gradient(180deg, rgba(8,16,9,0.05) 0%, rgba(8,16,9,0.15) 45%, rgba(8,16,9,0.75) 72%, var(--bg-deep) 96%)",
        }}
      />
      <div className="absolute inset-x-0 bottom-0 flex flex-col items-center gap-4 px-6 pb-[max(env(safe-area-inset-bottom),32px)] pt-10 text-center">
        <p className="font-display text-[26px] text-gold-strong">أهلاً، أنا آدم</p>
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
