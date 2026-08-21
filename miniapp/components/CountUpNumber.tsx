"use client";

import { useEffect, useRef, useState } from "react";
import { formatNumber } from "@/lib/format";

/** يعدّ من صفر إلى القيمة الحقيقية بحركة تدريجية، يبدأ فقط لمّا trigger تصير true. */
export function CountUpNumber({
  value,
  trigger,
  durationMs = 900,
}: {
  value: number;
  trigger: boolean;
  durationMs?: number;
}) {
  const [display, setDisplay] = useState(0);
  const started = useRef(false);

  useEffect(() => {
    if (!trigger || started.current) return;
    started.current = true;
    const start = performance.now();
    let raf: number;
    const tick = (now: number) => {
      const progress = Math.min(1, (now - start) / durationMs);
      const eased = 1 - Math.pow(1 - progress, 3);
      setDisplay(Math.round(eased * value));
      if (progress < 1) raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [trigger, value, durationMs]);

  return <span className="tabular">{formatNumber(display)}</span>;
}
