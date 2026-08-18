import type { ReactNode } from "react";

export type BadgeTone = "success" | "gold" | "error" | "violet" | "info" | "muted" | "warning" | "primary";

const TONE_STYLES: Record<BadgeTone, { bg: string; fg: string }> = {
  success: { bg: "var(--success-soft)", fg: "var(--success)" },
  gold: { bg: "var(--gold-soft)", fg: "var(--gold-strong)" },
  error: { bg: "var(--error-soft)", fg: "var(--error)" },
  violet: { bg: "var(--violet-soft)", fg: "var(--violet)" },
  info: { bg: "var(--info-soft)", fg: "var(--info)" },
  warning: { bg: "var(--warning-soft)", fg: "var(--warning)" },
  primary: { bg: "var(--primary-soft)", fg: "var(--primary)" },
  muted: { bg: "var(--surface-2)", fg: "var(--text-muted)" },
};

export function Badge({ tone = "muted", children }: { tone?: BadgeTone; children: ReactNode }) {
  const styles = TONE_STYLES[tone];
  return (
    <span
      className="inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-medium"
      style={{ backgroundColor: styles.bg, color: styles.fg }}
    >
      {children}
    </span>
  );
}

export function funnelTone(stage: string): BadgeTone {
  switch (stage) {
    case "paid_active":
      return "success";
    case "payment_pending_manual":
    case "offer_presented":
      return "gold";
    case "waitlist_non_algerian":
      return "info";
    case "expired":
      return "error";
    default:
      return "muted";
  }
}

export function strainTone(level: number): BadgeTone {
  if (level >= 3) return "error";
  if (level === 2) return "warning";
  return "success";
}
