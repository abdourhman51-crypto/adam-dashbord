import type { ReactNode } from "react";

export function StatRow({ label, value }: { label: ReactNode; value: ReactNode }) {
  return (
    <div className="flex items-center justify-between gap-3">
      <span className="text-[color:var(--text-muted)]">{label}</span>
      <span className="text-left font-medium text-[color:var(--text)]">{value}</span>
    </div>
  );
}
