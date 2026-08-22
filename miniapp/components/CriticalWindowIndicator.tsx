"use client";

import { useEffect, useState } from "react";
import { criticalWindowState } from "@/lib/criticalWindow";
import { GlassCard } from "@/components/GlassCard";

interface Props {
  labelAr: string;
  windowStartHour: number;
  windowEndHour: number;
  serverNowMinutes: number;
  serverTimestampMs: number;
}

const STATE_COPY = {
  in_window: { title: "الآن", tone: "text-gold-strong" },
  approaching: { title: "تقترب", tone: "text-text" },
  calm: { title: "هادئ", tone: "text-text-muted" },
} as const;

/** يتابع الوقت حياً بالعميل بالاعتماد على لقطة السيرفر — بلا إعادة استعلام كل ثانية. */
export function CriticalWindowIndicator({
  labelAr,
  windowStartHour,
  windowEndHour,
  serverNowMinutes,
}: Props) {
  const [nowMinutes, setNowMinutes] = useState(serverNowMinutes);

  useEffect(() => {
    const receivedAt = Date.now();
    const tick = () => {
      const elapsedMinutes = Math.floor((Date.now() - receivedAt) / 60000);
      setNowMinutes(serverNowMinutes + elapsedMinutes);
    };
    tick();
    const id = setInterval(tick, 30_000);
    return () => clearInterval(id);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [serverNowMinutes]);

  const state = criticalWindowState(nowMinutes, windowStartHour, windowEndHour);
  const copy = STATE_COPY[state];

  return (
    <GlassCard variant={state === "in_window" ? "gold" : "default"} className="rise-in">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-xs font-medium text-text-muted">اللحظة الحرجة اليوم</p>
          <p className="font-display mt-1 text-[17px] text-text">{labelAr}</p>
        </div>
        <div className="text-left">
          <span
            className={`inline-block h-2.5 w-2.5 rounded-full ${
              state === "in_window" ? "glow-pulse bg-gold" : state === "approaching" ? "bg-emerald-strong" : "bg-text-muted"
            }`}
          />
          <p className={`mt-1 text-sm font-semibold ${copy.tone}`}>{copy.title}</p>
        </div>
      </div>
    </GlassCard>
  );
}
