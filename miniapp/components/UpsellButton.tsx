"use client";

import { Lock } from "lucide-react";
import { returnToAdamChat } from "@/lib/upsell";
import { haptic } from "@/lib/telegram/client";

/**
 * زر فضول لا ضغط بيع — بلا عدّاد وقت أو إلحاح، بصوت آدم. يرجّع الوالد لمحادثة
 * آدم على تيليغرام (WebApp.close) ليكمل مسار الاتفاق على المرافقة الكاملة هناك.
 */
export function UpsellButton({ label }: { label: string }) {
  return (
    <button
      type="button"
      onClick={() => {
        haptic("light");
        returnToAdamChat();
      }}
      className="pressable-gold flex w-full items-center justify-center gap-2 px-5 py-3 text-sm font-semibold"
    >
      <Lock size={16} strokeWidth={2.2} />
      <span>{label}</span>
    </button>
  );
}
