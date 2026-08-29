"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { Check } from "lucide-react";
import { useScreenData } from "@/lib/telegram/useScreenData";
import { ScreenShell } from "@/components/ScreenShell";
import { AdamIntro } from "@/components/AdamIntro";
import { GlassCard } from "@/components/GlassCard";
import { QuickReplyCard } from "@/components/QuickReplyCard";
import { UpsellButton } from "@/components/UpsellButton";
import { AchievementCelebration } from "@/components/AchievementCelebration";
import { useScrollReveal } from "@/components/useScrollReveal";
import { LoadingState, OutsideTelegramState, NotFoundState, ErrorState } from "@/components/states";
import { formatNumber } from "@/lib/format";
import { computeStreak, isMilestone } from "@/lib/streak";

function celebratedKey(streak: number) {
  return `adam_celebrated_streak_${streak}`;
}

interface Night {
  logDate: string;
  result: "calm" | "hard" | "normal" | null;
  stepGiven: string | null;
  stepStatus: "done" | "tried_failed" | "not_tried" | null;
}

interface InsightsResponse {
  isPaid: boolean;
  childName: string | null;
  insight: string | null;
  effort: { triedThisWeek: number; triedLastWeek: number; calmThisWeek: number; calmLastWeek: number; triedEver: number };
  todayOpen: boolean;
  nights: Night[];
  patterns: { label: string; description: string | null }[];
  wall: { isPaid: boolean; moments: { logDate: string; stepGiven: string | null }[] };
}

interface Move {
  text: string;
  count: number;
  lastDate: string;
}

interface JourneyResponse {
  isPaid: boolean;
  inStage?: boolean;
  objectiveText?: string | null;
  objectiveTarget?: number | null;
  objectiveCurrent?: number | null;
  objectiveMet?: boolean;
  loggedDays?: number;
  daysRemaining?: number;
}

/**
 * بطاقة الهدف الذي دفع المشترك مقابله — نفس بيانات /api/journey، معروضة
 * هنا لأن هذا هو المكان الذي يفتحه يومياً أصلاً. اختفاؤها من هنا كان يعني
 * أن المشترك المدفوع لا يجد مقياس تقدّمه في أول مكان ينظر إليه.
 */
function ObjectiveCard({ j }: { j: JourneyResponse }) {
  const progress =
    j.objectiveTarget && j.objectiveTarget > 0
      ? Math.min(100, Math.round(((j.objectiveCurrent ?? 0) / j.objectiveTarget) * 100))
      : 0;

  return (
    <Section>
      <GlassCard variant="gold" className="rise-in">
        <div className="flex items-center justify-between">
          <p className="text-xs font-medium text-text-muted">الهدف اللي اتفقنا عليه</p>
          {j.daysRemaining !== undefined && j.daysRemaining > 0 && (
            <span className="text-xs text-text-muted">و{formatNumber(j.daysRemaining)} يوم متبقّي</span>
          )}
        </div>
        <p className="font-display mt-2 text-[19px] leading-relaxed text-text">{j.objectiveText}</p>

        <div className="mt-5">
          <div className="h-3 w-full overflow-hidden rounded-full bg-glass-bg">
            <div
              className="h-full rounded-full bg-gradient-to-l from-gold to-gold-strong transition-all duration-700"
              style={{ width: `${progress}%` }}
            />
          </div>
          <div className="mt-2 flex items-center justify-between text-xs text-text-muted">
            <span>
              {formatNumber(j.objectiveCurrent ?? 0)} من {formatNumber(j.objectiveTarget ?? 0)}
            </span>
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

        <Link href="/journey" className="mt-4 block text-center text-xs font-medium text-gold-strong">
          شوفوا قصة رحلتكم كاملة
        </Link>
      </GlassCard>
    </Section>
  );
}

/**
 * تجميع "اللحظات الهادئة" (نفس بيانات wall.moments، لا استعلام جديد) حسب
 * نصّ الخطوة — فتتحول كل خطوة نجحت أكثر من مرة إلى "حركة" لها عدد. هذا هو
 * الفرق كله بين "سجلّ ماضٍ" و"طريقة تُبنى": نفس البيانات، ترتيب مختلف.
 */
function groupMoves(moments: { logDate: string; stepGiven: string | null }[]): Move[] {
  const map = new Map<string, Move>();
  for (const m of moments) {
    const text = m.stepGiven?.trim();
    if (!text) continue;
    const existing = map.get(text);
    if (existing) {
      existing.count += 1;
      if (m.logDate > existing.lastDate) existing.lastDate = m.logDate;
    } else {
      map.set(text, { text, count: 1, lastDate: m.logDate });
    }
  }
  return Array.from(map.values()).sort((a, b) => b.count - a.count || (a.lastDate < b.lastDate ? 1 : -1));
}

const FREE_MOVE_LIMIT = 10;
const ESTABLISHED_AT = 4;

function Section({ children }: { children: React.ReactNode }) {
  const { ref, visible } = useScrollReveal<HTMLDivElement>();
  return (
    <div ref={ref} className={visible ? "rise-in" : "opacity-0"}>
      {children}
    </div>
  );
}

function Chip({ children, tone = "default" }: { children: React.ReactNode; tone?: "default" | "gold" }) {
  return (
    <span
      className={
        tone === "gold"
          ? "glass-gold rounded-full px-3 py-1 text-[11px] font-semibold text-gold-strong"
          : "rounded-full border-[1.5px] border-emerald-strong px-3 py-1 text-[11px] font-medium text-text-secondary"
      }
    >
      {children}
    </span>
  );
}

export default function MyWayPage() {
  const [result, refetch] = useScreenData<InsightsResponse>("/api/insights");
  const [journeyResult] = useScreenData<JourneyResponse>("/api/journey");
  const [celebrating, setCelebrating] = useState(false);

  const streak = useMemo(() => {
    if (result.state !== "ok") return 0;
    return computeStreak(result.data.nights);
  }, [result]);

  useEffect(() => {
    if (streak === 0 || !isMilestone(streak)) return;
    const key = celebratedKey(streak);
    if (window.localStorage.getItem(key)) return;
    window.localStorage.setItem(key, "1");
    setCelebrating(true);
  }, [streak]);

  if (result.state === "loading") return <LoadingState />;
  if (result.state === "outside_telegram") return <OutsideTelegramState />;
  if (result.state === "not_found") return <NotFoundState />;
  if (result.state === "error") return <ErrorState message={result.message} />;

  const { childName, todayOpen, wall } = result.data;
  const child = childName ?? "طفلكم";

  const allMoves = groupMoves(wall.moments);
  const visibleMoves = wall.isPaid ? allMoves : allMoves.slice(0, FREE_MOVE_LIMIT);
  const hiddenCount = wall.isPaid ? 0 : Math.max(0, allMoves.length - FREE_MOVE_LIMIT);
  const establishedCount = allMoves.filter((m) => m.count >= ESTABLISHED_AT).length;

  const journey = journeyResult.state === "ok" ? journeyResult.data : null;
  const hasActiveObjective = Boolean(journey?.isPaid && journey?.inStage && journey?.objectiveText);

  return (
    <ScreenShell>
      <AdamIntro text={`هذي الحركات اللي جرّبتوها ونفعت مع ${child} — كل ما تتكرّر، تصير أكثر طريقتكم.`} />

      {hasActiveObjective && journey && <ObjectiveCard j={journey} />}

      <Section>
        <div className="mt-2 flex flex-col items-center gap-1 text-center">
          <p className="font-display text-[44px] leading-none text-gold-strong">
            {formatNumber(establishedCount)}
          </p>
          <p className="text-sm text-text-muted">
            {establishedCount > 0 ? `حركة صارت طريقتكم مع ${child}` : `لسّا ما عندنا حركة ثابتة مع ${child}`}
          </p>
        </div>
      </Section>

      {todayOpen && (
        <Section>
          <QuickReplyCard onAnswered={refetch} />
        </Section>
      )}

      <Section>
        {allMoves.length === 0 ? (
          <GlassCard className="text-center">
            <p className="text-sm leading-relaxed text-text-muted">
              أول حركة تجرّبونها وتنجح مع {child}، تصير أول شيء هنا.
            </p>
          </GlassCard>
        ) : (
          <div className="flex flex-col gap-3">
            {visibleMoves.map((m, i) => (
              <div
                key={m.text}
                className={`card-form-in flex flex-col gap-2.5 !p-5 ${
                  m.count >= ESTABLISHED_AT ? "glass-gold glow-pulse" : "glass"
                }`}
                style={{ animationDelay: `${i * 70}ms` }}
              >
                <p className="font-display text-[16px] leading-relaxed text-text">{m.text}</p>
                <div className="flex flex-wrap items-center gap-2">
                  {m.count === 1 ? (
                    <Chip>جديدة</Chip>
                  ) : (
                    <Chip tone={m.count >= ESTABLISHED_AT ? "gold" : "default"}>
                      نفعت {formatNumber(m.count)} {m.count === 2 ? "مرتين" : "مرات"}
                    </Chip>
                  )}
                  {m.count >= ESTABLISHED_AT && <Chip tone="gold">صارت طريقتكم</Chip>}
                </div>
              </div>
            ))}

            {hiddenCount > 0 && (
              <div className="relative">
                <div className="blur-content glass flex flex-col gap-2.5 !p-5">
                  <p className="font-display text-[16px] leading-relaxed text-text">حركة أخرى نفعت معكم</p>
                </div>
                <span className="blur-badge absolute top-4 start-4 px-4 py-1.5 text-sm">
                  +{hiddenCount} حركات محجوبة
                </span>
              </div>
            )}
          </div>
        )}

        {hiddenCount > 0 && (
          <div className="mt-4">
            <UpsellButton label="وفيه أكثر من هذا — يظهر كامل مع المرافقة الكاملة" />
          </div>
        )}
      </Section>

      {celebrating && (
        <AchievementCelebration streak={streak} childName={child} onClose={() => setCelebrating(false)} />
      )}
    </ScreenShell>
  );
}
