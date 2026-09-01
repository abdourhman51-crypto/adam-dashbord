"use client";

import { MessageCircle } from "lucide-react";
import { returnToAdamChat } from "@/lib/upsell";
import { haptic } from "@/lib/telegram/client";
import { trackClick } from "@/lib/analytics";

/**
 * زر الرجوع لمحادثة آدم — دائم عبر التطبيق (بند ٧). الصياغة تتغيّر حسب مكانها
 * لتفادي تكرار نفس الدعوة (بند ٣)، لكنه دائماً بذهبي محجوز لدعوات المرافقة.
 */
export function ChatCTAButton({ label, full = true }: { label: string; full?: boolean }) {
  return (
    <button
      type="button"
      onClick={() => {
        haptic("light");
        trackClick("chat_cta");
        returnToAdamChat();
      }}
      className={`pressable-gold flex items-center justify-center gap-2 px-5 py-3 text-sm font-semibold ${full ? "w-full" : ""}`}
    >
      <MessageCircle size={16} strokeWidth={2.2} />
      <span>{label}</span>
    </button>
  );
}
