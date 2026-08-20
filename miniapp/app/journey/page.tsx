"use client";

import { useScreenData } from "@/lib/telegram/useScreenData";
import { ScreenShell } from "@/components/ScreenShell";
import { AdamIntro } from "@/components/AdamIntro";
import { GlassCard } from "@/components/GlassCard";
import { LoadingState, OutsideTelegramState, NotFoundState, ErrorState } from "@/components/states";
import { formatNumber } from "@/lib/format";

interface JourneyResponse {
  inStage: boolean;
  childName: string | null;
  objectiveText?: string | null;
  objectiveTarget?: number | null;
  objectiveWindow?: number | null;
  objectiveCurrent?: number | null;
  windowFilled?: number;
  objectiveMet?: boolean;
  loggedDays?: number;
  allowedDays?: number;
  daysRemaining?: number;
  extended?: boolean;
  phaseAr?: string | null;
  baselineText?: string | null;
}

export default function JourneyPage() {
  const result = useScreenData<JourneyResponse>("/api/journey");

  if (result.state === "loading") return <LoadingState />;
  if (result.state === "outside_telegram") return <OutsideTelegramState />;
  if (result.state === "not_found") return <NotFoundState />;
  if (result.state === "error") return <ErrorState message={result.message} />;

  const j = result.data;

  if (!j.inStage) {
    return (
      <ScreenShell>
        <AdamIntro text="هذي شاشة رحلتكم المدفوعة — وين وصلتوا بالضبط بالهدف اللي اتفقنا عليه." />
        <GlassCard className="text-center">
          <p className="text-sm leading-relaxed text-text-muted">
            ما عندكم رحلة نشطة الحين. لمّا نتّفق على هدف واضح سوا، تتابعون تقدّمكم فيه هنا خطوة بخطوة.
          </p>
        </GlassCard>
      </ScreenShell>
    );
  }

  const progress =
    j.objectiveTarget && j.objectiveTarget > 0
      ? Math.min(100, Math.round(((j.objectiveCurrent ?? 0) / j.objectiveTarget) * 100))
      : 0;

  return (
    <ScreenShell>
      <AdamIntro text="هذي رحلتكم بالضبط — الهدف اللي اتفقنا عليه، وكم قطعتوا منه لين الحين." />

      <GlassCard variant="gold" className="rise-in">
        <p className="text-xs font-medium text-text-muted">الهدف اللي اتفقنا عليه</p>
        <p className="font-display mt-2 text-[20px] leading-relaxed text-text">{j.objectiveText}</p>

        <div className="mt-5">
          <div className="h-3 w-full overflow-hidden rounded-full bg-glass-bg">
            <div
              className="h-full rounded-full bg-gradient-to-l from-gold to-gold-strong transition-all duration-700"
              style={{ width: `${progress}%` }}
            />
          </div>
          <div className="mt-2 flex items-center justify-between text-xs text-text-muted">
            <span>{formatNumber(j.objectiveCurrent ?? 0)} من {formatNumber(j.objectiveTarget ?? 0)}</span>
            <span>{j.objectiveMet ? "تحقّق الهدف ✓" : `${progress}٪`}</span>
          </div>
        </div>

        {j.phaseAr && <p className="mt-4 text-sm leading-relaxed text-text-secondary">{j.phaseAr}</p>}
      </GlassCard>

      {j.extended && (
        <GlassCard variant="soft" className="rise-in text-center">
          <p className="text-sm leading-relaxed text-gold-strong">
            رحلتكم دخلت فترة التمديد — آدم واصل معكم بلا أي مقابل إضافي، لين نوصل للهدف سوا.
          </p>
        </GlassCard>
      )}

      <GlassCard className="rise-in grid grid-cols-2 gap-4 text-center">
        <div>
          <p className="font-display text-2xl text-text">{formatNumber(j.loggedDays ?? 0)}</p>
          <p className="mt-1 text-xs text-text-muted">يوم سجّلتوه</p>
        </div>
        <div>
          <p className="font-display text-2xl text-text">{formatNumber(j.daysRemaining ?? 0)}</p>
          <p className="mt-1 text-xs text-text-muted">يوم متبقّي</p>
        </div>
      </GlassCard>

      {j.baselineText && (
        <GlassCard className="rise-in">
          <p className="text-sm leading-relaxed text-text-secondary">{j.baselineText}</p>
        </GlassCard>
      )}
    </ScreenShell>
  );
}
