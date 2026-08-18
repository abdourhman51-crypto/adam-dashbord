"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { CheckCircle2, XCircle, RotateCcw, Trash2 } from "lucide-react";
import { ConfirmDialog } from "@/components/ui/ConfirmDialog";
import {
  activateSubscriptionAction,
  deactivateSubscriptionAction,
  renewStageSameObjectiveAction,
  requestErasureAction,
  executeErasureAction,
} from "@/lib/actions/customer-actions";
import { PROBLEM_LABELS } from "@/lib/format";
import type { AgreedObjective } from "@/lib/types";

const inputClass =
  "w-full rounded-lg border border-[color:var(--border)] bg-[color:var(--surface)] px-3 py-2 text-sm outline-none focus:border-[color:var(--primary)]";
const labelClass = "text-xs font-medium text-[color:var(--text-muted)]";

export function ActionBar({
  followerId,
  followerName,
  hasActiveStage,
  agreedObjective,
  pendingErasureId,
}: {
  followerId: string;
  followerName: string;
  hasActiveStage: boolean;
  agreedObjective: AgreedObjective | null;
  pendingErasureId: string | null;
}) {
  const router = useRouter();
  const [open, setOpen] = useState<"activate" | "deactivate" | "renew" | "erasureRequest" | "erasureExecute" | null>(
    null
  );

  // نموذج التفعيل اليدوي (يُستخدم فقط إن لم يوجد agreed_objective جاهز من رحلة العميل)
  const [problemKey, setProblemKey] = useState(agreedObjective?.problem_key ?? "sleep");
  const [objectiveText, setObjectiveText] = useState(agreedObjective?.objective_text ?? "");
  const [amount, setAmount] = useState("");
  const [currency, setCurrency] = useState("DZD");
  const [notes, setNotes] = useState("");
  const [reason, setReason] = useState("");
  const [erasureRequestId, setErasureRequestId] = useState<string | null>(pendingErasureId);

  return (
    <div className="flex flex-wrap gap-2">
      <button
        onClick={() => setOpen("activate")}
        className="flex items-center gap-1.5 rounded-lg bg-[color:var(--primary)] px-3.5 py-2 text-xs font-semibold text-[color:var(--on-primary)] transition hover:bg-[color:var(--primary-strong)]"
      >
        <CheckCircle2 size={14} /> تفعيل اشتراك
      </button>
      <button
        onClick={() => setOpen("deactivate")}
        className="flex items-center gap-1.5 rounded-lg border border-[color:var(--border)] px-3.5 py-2 text-xs font-semibold text-[color:var(--text-secondary)] transition hover:bg-[color:var(--surface-2)]"
      >
        <XCircle size={14} /> إلغاء اشتراك
      </button>
      <button
        onClick={() => setOpen("renew")}
        disabled={!hasActiveStage}
        className="flex items-center gap-1.5 rounded-lg border border-[color:var(--gold)] px-3.5 py-2 text-xs font-semibold text-[color:var(--gold-strong)] transition hover:bg-[color:var(--gold-soft)] disabled:cursor-not-allowed disabled:opacity-40"
        title={hasActiveStage ? undefined : "لا توجد رحلة سابقة للتجديد بنفس هدفها"}
      >
        <RotateCcw size={14} /> تمديد بنفس الهدف
      </button>
      <button
        onClick={() => setOpen(erasureRequestId ? "erasureExecute" : "erasureRequest")}
        className="flex items-center gap-1.5 rounded-lg border border-[color:var(--error)] px-3.5 py-2 text-xs font-semibold text-[color:var(--error)] transition hover:bg-[color:var(--error-soft)]"
      >
        <Trash2 size={14} /> {erasureRequestId ? "تنفيذ حذف البيانات نهائياً" : "طلب حذف بيانات العميل"}
      </button>

      <ConfirmDialog
        open={open === "activate"}
        onClose={() => setOpen(null)}
        title="تفعيل اشتراك"
        description={
          agreedObjective?.objective_text ? (
            <p>
              سيُستخدم الهدف الذي وافق عليه العميل بالفعل: <strong>{agreedObjective.objective_text}</strong>
            </p>
          ) : (
            <p>لا يوجد هدف متفق عليه مسجَّل — أدخل تفاصيل الهدف يدوياً.</p>
          )
        }
        confirmLabel="تفعيل"
        onConfirm={() =>
          activateSubscriptionAction(followerId, {
            amount: amount ? Number(amount) : undefined,
            currency: currency || undefined,
            notes: notes || undefined,
            problemKey: agreedObjective?.objective_text ? undefined : problemKey,
            objectiveText: agreedObjective?.objective_text ? undefined : objectiveText || undefined,
          })
        }
      >
        <div className="grid grid-cols-2 gap-3">
          {!agreedObjective?.objective_text && (
            <>
              <label className="col-span-2 flex flex-col gap-1">
                <span className={labelClass}>نوع المشكلة</span>
                <select value={problemKey} onChange={(e) => setProblemKey(e.target.value)} className={inputClass}>
                  {Object.entries(PROBLEM_LABELS).map(([key, label]) => (
                    <option key={key} value={key}>
                      {label}
                    </option>
                  ))}
                </select>
              </label>
              <label className="col-span-2 flex flex-col gap-1">
                <span className={labelClass}>نص الهدف</span>
                <input value={objectiveText} onChange={(e) => setObjectiveText(e.target.value)} className={inputClass} />
              </label>
            </>
          )}
          <label className="flex flex-col gap-1">
            <span className={labelClass}>المبلغ (اختياري)</span>
            <input value={amount} onChange={(e) => setAmount(e.target.value)} type="number" className={inputClass} />
          </label>
          <label className="flex flex-col gap-1">
            <span className={labelClass}>العملة</span>
            <input value={currency} onChange={(e) => setCurrency(e.target.value)} className={inputClass} />
          </label>
          <label className="col-span-2 flex flex-col gap-1">
            <span className={labelClass}>ملاحظات</span>
            <input value={notes} onChange={(e) => setNotes(e.target.value)} className={inputClass} />
          </label>
        </div>
      </ConfirmDialog>

      <ConfirmDialog
        open={open === "deactivate"}
        onClose={() => setOpen(null)}
        title="إلغاء الاشتراك"
        description={`سيتم إيقاف رحلة ${followerName} النشطة وإعادته لمرحلة "محادثة مجانية".`}
        confirmLabel="إلغاء الاشتراك"
        danger
        onConfirm={() => deactivateSubscriptionAction(followerId, reason || undefined)}
      >
        <label className="flex flex-col gap-1">
          <span className={labelClass}>السبب (اختياري)</span>
          <input value={reason} onChange={(e) => setReason(e.target.value)} className={inputClass} />
        </label>
      </ConfirmDialog>

      <ConfirmDialog
        open={open === "renew"}
        onClose={() => setOpen(null)}
        title="تمديد بنفس الهدف"
        description="سيُنشأ اشتراك ودفعة جديدان بنفس هدف آخر رحلة لهذا العميل."
        confirmLabel="تمديد"
        onConfirm={() =>
          renewStageSameObjectiveAction(followerId, {
            amount: amount ? Number(amount) : undefined,
            currency: currency || undefined,
            notes: notes || undefined,
          })
        }
      >
        <div className="grid grid-cols-2 gap-3">
          <label className="flex flex-col gap-1">
            <span className={labelClass}>المبلغ (اختياري)</span>
            <input value={amount} onChange={(e) => setAmount(e.target.value)} type="number" className={inputClass} />
          </label>
          <label className="flex flex-col gap-1">
            <span className={labelClass}>العملة</span>
            <input value={currency} onChange={(e) => setCurrency(e.target.value)} className={inputClass} />
          </label>
        </div>
      </ConfirmDialog>

      <ConfirmDialog
        open={open === "erasureRequest"}
        onClose={() => setOpen(null)}
        title="طلب حذف بيانات العميل"
        description="هذه الخطوة الأولى فقط (طلب) — لا تحذف شيئاً بعد. سيلزم تنفيذ منفصل لإتمام الحذف الفعلي نهائياً."
        confirmLabel="تسجيل الطلب"
        danger
        onConfirm={async () => {
          const id = await requestErasureAction(followerId);
          setErasureRequestId(id);
        }}
      />

      <ConfirmDialog
        open={open === "erasureExecute"}
        onClose={() => setOpen(null)}
        title="تنفيذ الحذف نهائياً"
        description="لا يمكن التراجع عن هذا الإجراء: ستُحذف محادثات العميل ويُخفى ربط مدفوعاته ويُحذف سجله بالكامل."
        confirmLabel="حذف نهائي"
        danger
        requireTypedText={followerName}
        onConfirm={async () => {
          if (!erasureRequestId) throw new Error("لا يوجد طلب حذف مسجَّل.");
          await executeErasureAction(erasureRequestId, followerId);
          router.push("/customers");
        }}
      />
    </div>
  );
}
