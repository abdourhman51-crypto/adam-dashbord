import { formatNumber, formatPercent } from "@/lib/format";

export interface BarBreakdownItem {
  label: string;
  value: number;
  hint?: string;
}

/**
 * قائمة أشرطة أفقية بلون واحد (primary) — الشكل الآمن للتصنيفات المتعددة
 * (أكثر من صنفين) بدل الاعتماد على تمييز ألوان متعددة (راجع dataviz skill).
 * كل صف يحمل اسمه كنص دائماً، لا اعتماد على اللون للتعرّف.
 */
export function BarBreakdown({ items, maxRows }: { items: BarBreakdownItem[]; maxRows?: number }) {
  const shown = maxRows ? items.slice(0, maxRows) : items;
  const total = items.reduce((s, i) => s + i.value, 0);
  const max = Math.max(1, ...shown.map((i) => i.value));

  return (
    <div className="flex flex-col gap-3">
      {shown.map((item) => (
        <div key={item.label} className="flex flex-col gap-1">
          <div className="flex items-baseline justify-between gap-2 text-xs">
            <span className="truncate font-medium text-[color:var(--text-secondary)]">{item.label}</span>
            <span className="tabular shrink-0 text-[color:var(--text-muted)]">
              {formatNumber(item.value)}
              {total > 0 && <span className="mr-1">({formatPercent(item.value / total)})</span>}
            </span>
          </div>
          <div className="h-2 w-full overflow-hidden rounded-full bg-[color:var(--surface-2)]">
            <div
              className="h-full rounded-full bg-[color:var(--primary)]"
              style={{ width: `${Math.max(3, (item.value / max) * 100)}%` }}
            />
          </div>
          {item.hint && <span className="text-[11px] text-[color:var(--text-muted)]">{item.hint}</span>}
        </div>
      ))}
    </div>
  );
}
