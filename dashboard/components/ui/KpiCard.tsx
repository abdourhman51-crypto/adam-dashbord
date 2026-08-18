import type { ComponentType, ReactNode } from "react";

type Tone = "default" | "primary" | "gold" | "success" | "warning" | "error" | "info";

const TONE_STYLES: Record<Tone, { bg: string; fg: string }> = {
  default: { bg: "var(--surface-2)", fg: "var(--text)" },
  primary: { bg: "var(--primary-soft)", fg: "var(--primary)" },
  gold: { bg: "var(--gold-soft)", fg: "var(--gold-strong)" },
  success: { bg: "var(--success-soft)", fg: "var(--success)" },
  warning: { bg: "var(--warning-soft)", fg: "var(--warning)" },
  error: { bg: "var(--error-soft)", fg: "var(--error)" },
  info: { bg: "var(--info-soft)", fg: "var(--info)" },
};

export function KpiCard({
  label,
  value,
  hint,
  icon: Icon,
  tone = "default",
}: {
  label: string;
  value: ReactNode;
  hint?: ReactNode;
  icon?: ComponentType<{ size?: number; className?: string }>;
  tone?: Tone;
}) {
  const styles = TONE_STYLES[tone];
  return (
    <div className="rise-in flex flex-col gap-3 rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-5 shadow-[var(--shadow-card)]">
      <div className="flex items-center justify-between">
        <span className="text-xs font-medium text-[color:var(--text-muted)]">{label}</span>
        {Icon && (
          <span
            className="flex h-8 w-8 items-center justify-center rounded-lg"
            style={{ backgroundColor: styles.bg, color: styles.fg }}
          >
            <Icon size={16} />
          </span>
        )}
      </div>
      <div className="tabular text-2xl font-bold text-[color:var(--text)]">{value}</div>
      {hint && <div className="text-xs text-[color:var(--text-muted)]">{hint}</div>}
    </div>
  );
}
