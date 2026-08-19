import type { ReactNode } from "react";

export function EmptyState({ title, body }: { title: string; body?: ReactNode }) {
  return (
    <div className="flex flex-col items-center gap-1.5 rounded-xl border border-dashed border-[color:var(--border-strong)] px-6 py-10 text-center">
      <p className="text-sm font-medium text-[color:var(--text-secondary)]">{title}</p>
      {body && <p className="text-xs text-[color:var(--text-muted)]">{body}</p>}
    </div>
  );
}
