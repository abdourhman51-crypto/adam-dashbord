"use client";

import { useState, type ReactNode } from "react";
import { Modal } from "./Modal";

export function ConfirmDialog({
  open,
  onClose,
  title,
  description,
  confirmLabel = "تأكيد",
  cancelLabel = "إلغاء",
  danger = false,
  requireTypedText,
  onConfirm,
  children,
}: {
  open: boolean;
  onClose: () => void;
  title: string;
  description?: ReactNode;
  confirmLabel?: string;
  cancelLabel?: string;
  /** إن كان صحيحاً، تُصبغ خلفية زر التأكيد بلون تحذيري */
  danger?: boolean;
  /** إن مُرِّر نص، يجب على المستخدم كتابته حرفياً لتفعيل زر التأكيد (للإجراءات التي لا رجعة فيها) */
  requireTypedText?: string;
  onConfirm: () => Promise<void> | void;
  children?: ReactNode;
}) {
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [typed, setTyped] = useState("");

  const locked = Boolean(requireTypedText) && typed.trim() !== requireTypedText;

  async function handleConfirm() {
    setError(null);
    setPending(true);
    try {
      await onConfirm();
      setTyped("");
      onClose();
    } catch (e) {
      setError(e instanceof Error ? e.message : "حدث خطأ غير متوقع.");
    } finally {
      setPending(false);
    }
  }

  return (
    <Modal open={open} onClose={onClose} title={title}>
      <div className="flex flex-col gap-4">
        {description && <div className="text-sm text-[color:var(--text-secondary)]">{description}</div>}
        {children}

        {requireTypedText && (
          <div className="flex flex-col gap-1.5">
            <label className="text-xs text-[color:var(--text-muted)]">
              اكتب <span className="font-semibold text-[color:var(--text)]">{requireTypedText}</span> للتأكيد
            </label>
            <input
              value={typed}
              onChange={(e) => setTyped(e.target.value)}
              dir="rtl"
              className="w-full rounded-lg border border-[color:var(--border)] bg-[color:var(--surface)] px-3 py-2 text-sm outline-none focus:border-[color:var(--primary)]"
            />
          </div>
        )}

        {error && (
          <p className="rounded-lg bg-[color:var(--error-soft)] px-3 py-2 text-xs text-[color:var(--error)]">
            {error}
          </p>
        )}

        <div className="flex justify-end gap-2 pt-1">
          <button
            onClick={onClose}
            disabled={pending}
            className="rounded-lg border border-[color:var(--border)] px-4 py-2 text-sm font-medium text-[color:var(--text-secondary)] transition hover:bg-[color:var(--surface-2)]"
          >
            {cancelLabel}
          </button>
          <button
            onClick={handleConfirm}
            disabled={pending || locked}
            className="rounded-lg px-4 py-2 text-sm font-semibold text-white transition disabled:opacity-50"
            style={{ backgroundColor: danger ? "var(--error)" : "var(--primary)" }}
          >
            {pending ? "جارٍ التنفيذ…" : confirmLabel}
          </button>
        </div>
      </div>
    </Modal>
  );
}
