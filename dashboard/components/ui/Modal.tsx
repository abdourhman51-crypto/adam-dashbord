"use client";

import { useEffect, type ReactNode } from "react";
import { createPortal } from "react-dom";
import { X } from "lucide-react";

export function Modal({
  open,
  onClose,
  title,
  children,
  wide = false,
}: {
  open: boolean;
  onClose: () => void;
  title?: ReactNode;
  children: ReactNode;
  wide?: boolean;
}) {
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    document.addEventListener("keydown", onKey);
    const prevOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", onKey);
      document.body.style.overflow = prevOverflow;
    };
  }, [open, onClose]);

  if (!open || typeof document === "undefined") return null;

  return createPortal(
    <div
      className="fixed inset-0 flex items-center justify-center p-4"
      style={{ zIndex: "var(--z-overlay)" as unknown as number }}
    >
      <div className="absolute inset-0 bg-black/50" onClick={onClose} />
      <div
        className={`rise-in relative flex max-h-[85dvh] w-full flex-col overflow-hidden rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] shadow-[var(--shadow-pop)] ${
          wide ? "max-w-2xl" : "max-w-md"
        }`}
      >
        {title && (
          <header className="flex items-center justify-between border-b border-[color:var(--border)] px-5 py-4">
            <h2 className="text-sm font-semibold text-[color:var(--text)]">{title}</h2>
            <button
              onClick={onClose}
              aria-label="إغلاق"
              className="rounded-lg p-1.5 text-[color:var(--text-muted)] transition hover:bg-[color:var(--surface-2)]"
            >
              <X size={18} />
            </button>
          </header>
        )}
        <div className="overflow-y-auto p-5">{children}</div>
      </div>
    </div>,
    document.body
  );
}
