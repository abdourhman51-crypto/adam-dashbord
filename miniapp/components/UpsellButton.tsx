"use client";

import { Lock } from "lucide-react";
import { getUpgradeDeepLink } from "@/lib/upsell";
import { openLink, haptic } from "@/lib/telegram/client";

/**
 * زر فضول لا ضغط بيع — بلا عدّاد وقت أو إلحاح، بصوت آدم. يفتح محادثة البوت
 * على تيليغرام مباشرة (start=journey). لو ما تم ضبط اسم البوت بعد، لا نعرض
 * زراً معطّلاً بصمت — نُخفيه كلياً حتى يُضبط.
 */
export function UpsellButton({ label }: { label: string }) {
  const href = getUpgradeDeepLink();
  if (!href) return null;

  return (
    <button
      type="button"
      onClick={() => {
        haptic("light");
        openLink(href);
      }}
      className="pressable-gold flex w-full items-center justify-center gap-2 px-5 py-3 text-sm font-semibold"
    >
      <Lock size={16} strokeWidth={2.2} />
      <span>{label}</span>
    </button>
  );
}
