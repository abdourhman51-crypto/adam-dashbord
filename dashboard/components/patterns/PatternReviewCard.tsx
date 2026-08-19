"use client";

import { useState } from "react";
import { Check, X } from "lucide-react";
import { Card } from "@/components/ui/Card";
import { reviewPatternAction } from "@/lib/actions/pattern-actions";
import type { PatternPendingReview } from "@/lib/types";

export function PatternReviewCard({ pattern }: { pattern: PatternPendingReview }) {
  const [approver, setApprover] = useState("");
  const [pending, setPending] = useState<"approve" | "reject" | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [done, setDone] = useState<boolean | null>(null);

  async function act(decision: boolean) {
    if (!approver.trim()) {
      setError("اكتب اسمك للموافقة أو الرفض.");
      return;
    }
    setError(null);
    setPending(decision ? "approve" : "reject");
    try {
      await reviewPatternAction(pattern.pattern_id, decision, approver);
      setDone(decision);
    } catch (e) {
      setError(e instanceof Error ? e.message : "حدث خطأ.");
    } finally {
      setPending(null);
    }
  }

  if (done !== null) {
    return (
      <Card>
        <p className="text-sm text-[color:var(--text-secondary)]">
          {done ? "✅ تمت الموافقة — سيظهر النمط للوالدين." : "🚫 تم الرفض — يبقى النمط مخفياً."}
        </p>
      </Card>
    );
  }

  return (
    <Card title={pattern.pattern_label} subtitle={`الطفل: ${pattern.child_name}`}>
      <div className="flex flex-col gap-4">
        {pattern.description && <p className="text-sm leading-relaxed text-[color:var(--text-secondary)]">{pattern.description}</p>}

        <label className="flex flex-col gap-1.5">
          <span className="text-xs font-medium text-[color:var(--text-muted)]">اسمك (للتوثيق)</span>
          <input
            value={approver}
            onChange={(e) => setApprover(e.target.value)}
            placeholder="مثال: معز"
            className="w-full rounded-lg border border-[color:var(--border)] bg-[color:var(--surface)] px-3 py-2 text-sm outline-none focus:border-[color:var(--primary)]"
          />
        </label>

        {error && <p className="text-xs text-[color:var(--error)]">{error}</p>}

        <div className="flex gap-2">
          <button
            onClick={() => act(true)}
            disabled={pending !== null}
            className="flex flex-1 items-center justify-center gap-1.5 rounded-lg bg-[color:var(--success)] px-4 py-2 text-sm font-semibold text-white transition disabled:opacity-60"
          >
            <Check size={15} /> موافقة
          </button>
          <button
            onClick={() => act(false)}
            disabled={pending !== null}
            className="flex flex-1 items-center justify-center gap-1.5 rounded-lg border border-[color:var(--error)] px-4 py-2 text-sm font-semibold text-[color:var(--error)] transition disabled:opacity-60"
          >
            <X size={15} /> رفض
          </button>
        </div>
      </div>
    </Card>
  );
}
