"use client";

import { GlassCard } from "@/components/GlassCard";
import { formatNumber } from "@/lib/format";

export interface CurveData {
  ready: boolean;
  heldWeek: number;
  eruptWeek: number;
  heldPrev: number;
  eruptPrev: number;
  heldTotal: number;
  eruptDelta: number;
}

/**
 * المنحنى — الرقم الوحيد الذي يستحق أن يكون كبيراً في التطبيق: كم مرة
 * وقع الاقتراب من الحافة بلا انفجار. وهو الوعد المُباع نفسه، مقيساً.
 *
 * قاعدتان تحكمان هذا المكوّن:
 * ١ — لا يُعرض أي حكم على «انفجرتُ». الرقم بيانات، لا وصمة.
 * ٢ — لا تُرسم مقارنة قبل أن يوجد أسبوع سابق حقيقي (ready=false)، لأن
 *     منحنى من أربعة أيام يضلّل في أي اتجاه سقطت فيه الصدفة.
 */
function Bar({ label, held, erupt, dim = false }: { label: string; held: number; erupt: number; dim?: boolean }) {
  const total = Math.max(held + erupt, 1);
  return (
    <div className={dim ? "opacity-60" : ""}>
      <div className="mb-1.5 flex items-baseline justify-between">
        <span className="text-xs text-text-muted">{label}</span>
        <span className="text-xs text-text-secondary">
          تماسك {formatNumber(held)} · انفجار {formatNumber(erupt)}
        </span>
      </div>
      <div className="flex h-3 w-full overflow-hidden rounded-full bg-glass-bg">
        <div
          className="h-full bg-gradient-to-l from-gold to-gold-strong"
          style={{ width: `${(held / total) * 100}%` }}
        />
        <div className="h-full bg-text-muted/50" style={{ width: `${(erupt / total) * 100}%` }} />
      </div>
    </div>
  );
}

export function ProgressCurve({ curve }: { curve: CurveData }) {
  const { ready, heldWeek, eruptWeek, heldPrev, eruptPrev, heldTotal, eruptDelta } = curve;

  return (
    <GlassCard variant="gold" className="rise-in">
      <div className="text-center">
        <p className="font-display text-[44px] leading-none text-gold-strong">{formatNumber(heldTotal)}</p>
        <p className="mt-1.5 text-sm text-text-muted">
          {heldTotal > 0 ? "مرة اقتُرب فيها من الحافة ولم يقع الانفجار" : "لسّا ما عندنا لحظة مسجّلة"}
        </p>
      </div>

      {(heldWeek > 0 || eruptWeek > 0 || heldPrev > 0 || eruptPrev > 0) && (
        <div className="mt-5 flex flex-col gap-3.5 border-t border-glass-border pt-4">
          <Bar label="هذا الأسبوع" held={heldWeek} erupt={eruptWeek} />
          {ready && <Bar label="الأسبوع الماضي" held={heldPrev} erupt={eruptPrev} dim />}
        </div>
      )}

      {ready && eruptDelta < 0 && (
        <p className="mt-4 border-t border-glass-border pt-3 text-center text-sm leading-relaxed text-text">
          الانفجارات نقصت{" "}
          <span className="font-semibold text-gold-strong">
            {formatNumber(Math.abs(eruptDelta))} {Math.abs(eruptDelta) === 1 ? "مرة" : "مرات"}
          </span>{" "}
          عن الأسبوع الماضي.
        </p>
      )}

      {ready && eruptDelta === 0 && (
        <p className="mt-4 border-t border-glass-border pt-3 text-center text-sm leading-relaxed text-text-muted">
          أسبوع مثل الذي قبله. والثبات نفسه ليس قليلاً.
        </p>
      )}

      {ready && eruptDelta > 0 && (
        <p className="mt-4 border-t border-glass-border pt-3 text-center text-sm leading-relaxed text-text-muted">
          أسبوع أثقل من الذي قبله. تحدث أسابيع كهذي، ولا تُلغي ما قبلها.
        </p>
      )}

      {!ready && (heldWeek > 0 || eruptWeek > 0) && (
        <p className="mt-4 border-t border-glass-border pt-3 text-center text-xs leading-relaxed text-text-muted">
          بعد أسبوع كامل، تظهر المقارنة هنا.
        </p>
      )}
    </GlassCard>
  );
}
