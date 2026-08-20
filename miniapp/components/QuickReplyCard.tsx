"use client";

import { useState } from "react";
import { GlassCard } from "@/components/GlassCard";
import { postAction } from "@/lib/telegram/fetcher";
import { haptic } from "@/lib/telegram/client";

const OPTIONS = [
  { outcome: "succeeded", label: "مرّت بهدوء" },
  { outcome: "tried_failed", label: "جرّبناها ولم تنفع" },
  { outcome: "no_chance", label: "لم تُجرَّب" },
] as const;

export function QuickReplyCard({ onAnswered }: { onAnswered: () => void }) {
  const [pending, setPending] = useState<string | null>(null);
  const [error, setError] = useState(false);

  async function answer(outcome: string) {
    if (pending) return;
    setPending(outcome);
    setError(false);
    const result = await postAction<{ recorded: boolean }>("/api/reply", { outcome });
    if (result.state === "ok" && result.data.recorded) {
      haptic("light");
      onAnswered();
    } else {
      setError(true);
      setPending(null);
    }
  }

  return (
    <GlassCard variant="strong" className="rise-in text-center">
      <p className="font-display text-[17px] leading-relaxed text-text">كيف مرّت الليلة؟</p>
      <div className="mt-4 flex flex-col gap-2.5">
        {OPTIONS.map((o) => (
          <button
            key={o.outcome}
            type="button"
            onClick={() => answer(o.outcome)}
            disabled={pending !== null}
            className="pressable px-5 py-3 text-sm font-medium disabled:opacity-60"
          >
            {pending === o.outcome ? "جاري التسجيل…" : o.label}
          </button>
        ))}
      </div>
      {error && (
        <p className="mt-3 text-xs text-text-muted">ما قدرنا نسجّل الإجابة، جرّبوا مرة ثانية.</p>
      )}
    </GlassCard>
  );
}
