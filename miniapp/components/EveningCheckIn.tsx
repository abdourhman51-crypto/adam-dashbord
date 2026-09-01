"use client";

import { useState } from "react";
import { GlassCard } from "@/components/GlassCard";
import { postAction } from "@/lib/telegram/fetcher";
import { haptic } from "@/lib/telegram/client";
import { trackClick } from "@/lib/analytics";

/**
 * سؤال المساء — عن الوالد، لا عن الطفل.
 *
 * كان السؤال «كيف مرّت الليلة؟» يقيس نتيجة عند الطفل لا يملك الوالد
 * التحكّم فيها. الجواب هنا يقيس ما يملكه فعلاً، وهو ما يُباع: كم مرة أوشك
 * ولم ينفجر. بلا هذا السؤال لا يوجد قياس، وبلا قياس لا يوجد وعد.
 *
 * الخيارات ثلاثة لا أكثر، ولا واحد منها يحمل لوماً — «انفجرتُ» يُسجَّل
 * كبيانات للمنحنى، ولا يُعرض عليه أبداً أي حكم.
 */
const OPTIONS = [
  { kind: "none", label: "مرّ بهدوء — ما أوشكتُ" },
  { kind: "held", label: "أوشكتُ وتماسكتُ" },
  { kind: "erupted", label: "انفجرتُ" },
] as const;

const THANKS: Record<string, string> = {
  none: "يوم هادئ يستحق أن يُذكر. سُجّل.",
  held: "هذي هي اللحظة التي نعدّها — اقتراب من الحافة بلا انفجار.",
  erupted: "سُجّلت، بلا حكم. غداً يوم جديد، وأنا هنا.",
};

export function EveningCheckIn({ onAnswered }: { onAnswered?: () => void }) {
  const [pending, setPending] = useState<string | null>(null);
  const [answered, setAnswered] = useState<string | null>(null);
  const [error, setError] = useState(false);

  async function answer(kind: (typeof OPTIONS)[number]["kind"]) {
    if (pending) return;
    setPending(kind);
    setError(false);
    trackClick(`evening_checkin_${kind}`, "home");

    // «ما أوشكتُ» ليس حدثاً يُسجَّل — لا شيء حدث. نشكرها ولا نكتب صفاً وهمياً
    // يضخّم العدّاد.
    if (kind === "none") {
      haptic("light");
      setAnswered(kind);
      onAnswered?.();
      setPending(null);
      return;
    }

    const r = await postAction<{ recorded: boolean }>("/api/moment", { kind, source: "evening" });
    if (r.state === "ok" && r.data.recorded) {
      haptic(kind === "held" ? "medium" : "light");
      setAnswered(kind);
      onAnswered?.();
    } else {
      setError(true);
    }
    setPending(null);
  }

  if (answered) {
    return (
      <GlassCard variant="gold" className="rise-in text-center">
        <p className="font-display text-[16px] leading-loose text-text">{THANKS[answered]}</p>
      </GlassCard>
    );
  }

  return (
    <GlassCard variant="strong" className="rise-in text-center">
      <p className="font-display text-[17px] leading-relaxed text-text">كيف كان اليوم؟</p>
      <p className="mt-1 text-xs text-text-muted">السؤال عن حالكم أنتم، لا عنه.</p>
      <div className="mt-4 flex flex-col gap-2.5">
        {OPTIONS.map((o) => (
          <button
            key={o.kind}
            type="button"
            onClick={() => answer(o.kind)}
            disabled={pending !== null}
            className="pressable px-5 py-3 text-sm font-medium disabled:opacity-60"
          >
            {pending === o.kind ? "جاري التسجيل…" : o.label}
          </button>
        ))}
      </div>
      {error && <p className="mt-3 text-xs text-text-muted">ما قدرنا نسجّل، جرّبوا مرة ثانية.</p>}
    </GlassCard>
  );
}
