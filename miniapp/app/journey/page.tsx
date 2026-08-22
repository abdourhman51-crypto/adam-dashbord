"use client";

import Link from "next/link";
import { Target, Check } from "lucide-react";
import { useScreenData } from "@/lib/telegram/useScreenData";
import { ScreenShell } from "@/components/ScreenShell";
import { AdamIntro } from "@/components/AdamIntro";
import { GlassCard } from "@/components/GlassCard";
import { CriticalWindowIndicator } from "@/components/CriticalWindowIndicator";
import { LoadingState, OutsideTelegramState, NotFoundState, ErrorState } from "@/components/states";
import { formatNumber } from "@/lib/format";
import type { CriticalWindowSnapshot } from "@/lib/criticalWindow";

interface JourneyResponse {
  isPaid: boolean;
  inStage?: boolean;
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
  criticalWindow?: CriticalWindowSnapshot | null;
}

function FreeTierPreview() {
  return (
    <ScreenShell>
      <AdamIntro text="هذي شاشة رحلتكم — تُفتح لمّا نتّفق سوا على هدف واضح مع المرافقة الكاملة. هذا شكلها:" />

      <div className="blur-content pointer-events-none flex flex-col gap-5" aria-hidden="true">
        <GlassCard variant="gold" className="rise-in">
          <p className="text-xs font-medium text-text-muted">الهدف اللي اتفقنا عليه</p>
          <p className="font-display mt-2 text-[20px] leading-relaxed text-text">
            ينام طفلكم بهدوء بلا صراخ 5 ليالٍ من كل 7
          </p>
          <div className="mt-5">
            <div className="h-3 w-full overflow-hidden rounded-full bg-glass-bg">
              <div className="h-full w-[45%] rounded-full bg-gradient-to-l from-gold to-gold-strong" />
            </div>
          </div>
        </GlassCard>
        <GlassCard className="rise-in grid grid-cols-2 gap-4 text-center">
          <div>
            <p className="font-display text-2xl text-text">١٨</p>
            <p className="mt-1 text-xs text-text-muted">يوم سجّلتوه</p>
          </div>
          <div>
            <p className="font-display text-2xl text-text">١٢</p>
            <p className="mt-1 text-xs text-text-muted">يوم متبقّي</p>
          </div>
        </GlassCard>
      </div>

      <Link
        href="/journey/start"
        className="pressable-gold flex items-center justify-center gap-2 px-5 py-3.5 text-sm font-semibold"
      >
        <Target size={17} strokeWidth={2.2} />
        نبني خطتكم الآن — نصف دقيقة، بلا التزام
      </Link>
    </ScreenShell>
  );
}

export default function JourneyPage() {
  const [result] = useScreenData<JourneyResponse>("/api/journey");

  if (result.state === "loading") return <LoadingState />;
  if (result.state === "outside_telegram") return <OutsideTelegramState />;
  if (result.state === "not_found") return <NotFoundState />;
  if (result.state === "error") return <ErrorState message={result.message} />;

  const j = result.data;

  if (!j.isPaid) return <FreeTierPreview />;

  if (!j.inStage) {
    return (
      <ScreenShell>
        <AdamIntro text="هذي شاشة رحلتكم — وين وصلتوا بالضبط بالهدف اللي اتفقنا عليه." />
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

      {j.criticalWindow && (
        <CriticalWindowIndicator
          labelAr={j.criticalWindow.labelAr}
          windowStartHour={j.criticalWindow.windowStartHour}
          windowEndHour={j.criticalWindow.windowEndHour}
          serverNowMinutes={j.criticalWindow.serverNowMinutes}
          serverTimestampMs={j.criticalWindow.serverTimestampMs}
        />
      )}

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
            <span className="flex items-center gap-1">
              {j.objectiveMet ? (
                <>
                  <Check size={13} strokeWidth={2.5} />
                  تحقّق الهدف
                </>
              ) : (
                `${progress}٪`
              )}
            </span>
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
