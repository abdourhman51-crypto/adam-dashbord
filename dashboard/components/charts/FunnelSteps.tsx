import { formatNumber, formatPercent } from "@/lib/format";

export interface FunnelStep {
  label: string;
  value: number;
}

/**
 * قمع مراحل بلون واحد (primary) بشفافية متدرجة — لا اعتماد على تمييز الألوان
 * (راجع dataviz skill)، القيمة والنسبة نصّان مباشران على كل مرحلة، ونسبة التسرّب
 * تظهر بين كل مرحلتين متتاليتين.
 */
export function FunnelSteps({ steps }: { steps: FunnelStep[] }) {
  const max = Math.max(1, ...steps.map((s) => s.value));

  return (
    <div className="flex flex-col gap-1.5">
      {steps.map((step, i) => {
        const width = Math.max(6, (step.value / max) * 100);
        const opacity = 1 - i * (0.55 / Math.max(1, steps.length - 1));
        const prev = i > 0 ? steps[i - 1] : null;
        const dropRate = prev && prev.value > 0 ? step.value / prev.value : null;

        return (
          <div key={step.label} className="flex flex-col gap-1.5">
            {prev && (
              <div className="flex items-center gap-2 px-1 text-[11px] text-[color:var(--text-muted)]">
                <span className="h-px flex-1 bg-[color:var(--border)]" />
                {dropRate !== null && (
                  <span
                    className={dropRate < 0.5 ? "font-semibold text-[color:var(--error)]" : ""}
                  >
                    {formatPercent(dropRate)} استمرار · تسرّب {formatPercent(1 - dropRate)}
                  </span>
                )}
                <span className="h-px flex-1 bg-[color:var(--border)]" />
              </div>
            )}
            <div className="flex items-center gap-3">
              <div className="w-28 shrink-0 text-xs font-medium text-[color:var(--text-secondary)] sm:w-40 sm:text-sm">
                {step.label}
              </div>
              <div className="relative h-8 flex-1 overflow-hidden rounded-lg bg-[color:var(--surface-2)]">
                <div
                  className="flex h-full items-center justify-end rounded-lg px-3 transition-[width]"
                  style={{ width: `${width}%`, backgroundColor: "var(--primary)", opacity }}
                >
                  <span className="tabular text-xs font-semibold text-[color:var(--on-primary)]">
                    {formatNumber(step.value)}
                  </span>
                </div>
              </div>
            </div>
          </div>
        );
      })}
    </div>
  );
}
