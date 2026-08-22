import type { ReactNode } from "react";

const VARIANT_CLASS = {
  default: "glass",
  strong: "glass-strong",
  gold: "glass-gold",
  soft: "glass-soft",
} as const;

export function GlassCard({
  children,
  variant = "default",
  className = "",
}: {
  children: ReactNode;
  variant?: keyof typeof VARIANT_CLASS;
  className?: string;
}) {
  return (
    <div className={`${VARIANT_CLASS[variant]} relative z-10 p-5 ${className}`}>{children}</div>
  );
}
