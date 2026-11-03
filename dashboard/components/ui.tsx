import type { ReactNode } from "react";

export function Card({ title, hint, children, className = "" }: { title?: string; hint?: string; children: ReactNode; className?: string }) {
  return (
    <section className={`card ${className}`}>
      {title && (
        <header className="mb-3 flex items-baseline justify-between gap-2">
          <h2 className="text-sm font-semibold">{title}</h2>
          {hint && <span className="text-xs text-[var(--muted)]">{hint}</span>}
        </header>
      )}
      {children}
    </section>
  );
}

export function Kpi({ label, value, sub, tone = "default" }: { label: string; value: ReactNode; sub?: ReactNode; tone?: "default" | "gold" | "good" | "warn" }) {
  const ring = { default: "", gold: "kpi-gold", good: "kpi-good", warn: "kpi-warn" }[tone];
  return (
    <div className={`card kpi ${ring}`}>
      <div className="text-xs text-[var(--muted)]">{label}</div>
      <div className="mt-1 text-2xl font-bold tabular-nums">{value}</div>
      {sub && <div className="mt-1 text-xs text-[var(--muted)]">{sub}</div>}
    </div>
  );
}

// Horizontal bars for ranked lists. The label sits on its own line so long Arabic text never squeezes the bar.
export function Bars({ items, empty = "لا بيانات بعد", max }: { items: { k: string; n: number; extra?: string }[]; empty?: string; max?: number }) {
  if (!items.length) return <p className="text-sm text-[var(--muted)]">{empty}</p>;
  const top = max ?? Math.max(...items.map((i) => i.n), 1);
  return (
    <ul className="space-y-2.5">
      {items.map((i) => (
        <li key={i.k}>
          <div className="flex justify-between gap-3 text-sm">
            <span className="truncate">{i.k}</span>
            <span className="shrink-0 tabular-nums text-[var(--muted)]">{i.n}{i.extra ? ` · ${i.extra}` : ""}</span>
          </div>
          <div className="mt-1 h-1.5 rounded-full bg-[var(--track)]">
            <div className="h-1.5 rounded-full bg-[var(--primary)]" style={{ width: `${Math.max(3, (100 * i.n) / top)}%` }} />
          </div>
        </li>
      ))}
    </ul>
  );
}

// Funnel steps: each bar is relative to the first step, with the step-to-step rate beside it.
export function Funnel({ steps }: { steps: { label: string; n: number }[] }) {
  const first = Math.max(steps[0]?.n ?? 0, 1);
  return (
    <ol className="space-y-3">
      {steps.map((s, i) => {
        const prev = i ? steps[i - 1].n : 0;
        return (
          <li key={s.label}>
            <div className="flex justify-between gap-3 text-sm">
              <span>{i + 1}. {s.label}</span>
              <span className="tabular-nums">
                <b>{s.n}</b>
                {i > 0 && <span className="text-[var(--muted)]"> · {prev ? Math.round((100 * s.n) / prev) : 0}% من السابق</span>}
              </span>
            </div>
            <div className="mt-1 h-2.5 rounded-full bg-[var(--track)]">
              <div className="h-2.5 rounded-full bg-[var(--gold)]" style={{ width: `${Math.max(2, (100 * s.n) / first)}%` }} />
            </div>
          </li>
        );
      })}
    </ol>
  );
}

export function Pill({ children, tone = "muted" }: { children: ReactNode; tone?: string }) {
  return <span className={`pill pill-${tone}`}>{children}</span>;
}

export function Problem({ error }: { error: string }) {
  return (
    <div className="card border-[var(--warn)] text-sm">
      <b>تعذّر جلب البيانات.</b> {error}
    </div>
  );
}
