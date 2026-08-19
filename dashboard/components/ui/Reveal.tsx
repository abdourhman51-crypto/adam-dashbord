"use client";

import { useState } from "react";
import { Eye, EyeOff } from "lucide-react";

/** حقل حسّاس مخفي افتراضياً خلف زر "إظهار" — لا يظهر بأي جدول/قائمة تلقائياً. */
export function Reveal({ children, label = "إظهار" }: { children: React.ReactNode; label?: string }) {
  const [shown, setShown] = useState(false);

  if (!shown) {
    return (
      <button
        type="button"
        onClick={() => setShown(true)}
        className="inline-flex items-center gap-1.5 rounded-lg border border-dashed border-[color:var(--border-strong)] px-2.5 py-1 text-xs text-[color:var(--text-muted)] transition hover:border-[color:var(--primary)] hover:text-[color:var(--primary)]"
      >
        <Eye size={13} />
        {label}
      </button>
    );
  }

  return (
    <div className="flex items-start gap-2">
      <div className="flex-1">{children}</div>
      <button
        type="button"
        onClick={() => setShown(false)}
        aria-label="إخفاء"
        className="shrink-0 rounded-lg p-1 text-[color:var(--text-muted)] hover:bg-[color:var(--surface-2)]"
      >
        <EyeOff size={13} />
      </button>
    </div>
  );
}
