"use client";

import { MessageCircle } from "lucide-react";
import { getChatLink } from "@/lib/upsell";
import { openLink, haptic } from "@/lib/telegram/client";

/**
 * زر الرجوع لمحادثة آدم — دائم عبر التطبيق (بند ٧). الصياغة تتغيّر حسب مكانها
 * لتفادي تكرار نفس الدعوة (بند ٣)، لكنه دائماً بذهبي محجوز لدعوات المرافقة.
 */
export function ChatCTAButton({ label, full = true }: { label: string; full?: boolean }) {
  const href = getChatLink();
  if (!href) return null;

  return (
    <button
      type="button"
      onClick={() => {
        haptic("light");
        openLink(href);
      }}
      className={`pressable-gold flex items-center justify-center gap-2 px-5 py-3 text-sm font-semibold ${full ? "w-full" : ""}`}
    >
      <MessageCircle size={16} strokeWidth={2.2} />
      <span>{label}</span>
    </button>
  );
}
