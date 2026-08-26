"use client";

import { useEffect, useMemo, useState } from "react";
import Image from "next/image";
import { useScreenData } from "@/lib/telegram/useScreenData";
import { ScreenShell } from "@/components/ScreenShell";
import { AdamIntro } from "@/components/AdamIntro";
import { GlassCard } from "@/components/GlassCard";
import { QuickReplyCard } from "@/components/QuickReplyCard";
import { UpsellButton } from "@/components/UpsellButton";
import { AchievementCelebration } from "@/components/AchievementCelebration";
import { useScrollReveal } from "@/components/useScrollReveal";
import { LoadingState, OutsideTelegramState, NotFoundState, ErrorState } from "@/components/states";
import { formatNightLabel } from "@/lib/format";
import { computeStreak, isMilestone } from "@/lib/streak";
import { IconText } from "@/lib/emojiIcons";

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

function Section({ children }: { children: React.ReactNode }) {
  const { ref, visible } = useScrollReveal<HTMLDivElement>();
  return (
    <div ref={ref} className={visible ? "rise-in" : "opacity-0"}>
      {children}
    </div>
  );
}

export default function InsightsPage() {
  const [result, refetch] = useScreenData<InsightsResponse>("/api/insights");
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

  const { childName, insight, effort, todayOpen, patterns, wall } = result.data;
  const child = childName ?? "طفلكم";

  // "لحظات تستاهل تُذكر" — أفضل 3 لحظات فقط، قصة قصيرة لا سجلّاً كاملاً.
  const highlightMoments = wall.moments.slice(0, 3);
  const visibleMoments = wall.isPaid ? highlightMoments : highlightMoments.slice(0, 1);
  const hiddenCount = wall.isPaid ? 0 : Math.max(0, highlightMoments.length - 1);

  return (
    <ScreenShell>
      <AdamIntro text={`هذي كل ما أعرفه عنكم وعن ${child}، وشو بدأ يتغيّر — بمكان واحد.`} />

      {/* قسم ١: ماذا تعلّم آدم عن الطفل */}
      <Section>
        <div className="mt-2 flex flex-col items-center gap-4 text-center">
          <div className="glass-gold h-24 w-24 overflow-hidden !rounded-full p-0">
            <Image src="/brand/adam.png" alt="" width={192} height={192} className="h-full w-full object-cover object-top" priority />
          </div>
          <div>
            <p className="text-sm text-text-muted">آدم يحكي لكم عن</p>
            <h1 className="font-display text-[24px] text-gold-strong">{child}</h1>
          </div>
          {insight ? (
            <GlassCard variant="strong" className="text-right">
              <p className="font-display text-[18px] leading-loose text-text">
                <IconText text={insight} />
              </p>
            </GlassCard>
          ) : (
            <GlassCard>
              <p className="text-sm leading-relaxed text-text-muted">
                لسّا آدم يتعرّف على {child} أكثر. كل ما تحكوا لي، تتوضّح لي شخصيته أكثر.
              </p>
            </GlassCard>
          )}
        </div>
      </Section>

      {todayOpen && (
        <Section>
          <QuickReplyCard onAnswered={refetch} />
        </Section>
      )}

      {/* قسم ٢: شو بدأ يتغيّر — دليل التحوّل، لا أرقام مجردة */}
      <Section>
        <p className="font-display mb-3 mt-2 text-[16px] text-gold-strong">شو بدأ يتغيّر</p>
        {patterns.length > 0 ? (
          <GlassCard>
            <div className="flex flex-col gap-3">
              {patterns.map((p, i) => (
                <div
                  key={p.label}
                  className="rise-in flex items-start gap-2 border-e-2 border-e-emerald-strong pe-3"
                  style={{ animationDelay: `${i * 70}ms` }}
                >
                  <div>
                    <p className="text-sm font-medium text-text">
                      <IconText text={p.label} />
                    </p>
                    {p.description && (
                      <p className="mt-0.5 text-xs leading-relaxed text-text-muted">
                        <IconText text={p.description} />
                      </p>
                    )}
                  </div>
                </div>
              ))}
            </div>
            {effort.triedThisWeek > 0 && (
              <p className="mt-3 border-t border-glass-border pt-3 text-xs text-text-muted">
                جرّبتوا هالأسبوع {effort.triedThisWeek} {effort.triedThisWeek === 1 ? "مرة" : "مرات"}
                {effort.triedLastWeek > 0 ? ` — الأسبوع اللي فات ${effort.triedLastWeek}.` : "."}
              </p>
            )}
          </GlassCard>
        ) : (
          <GlassCard className="text-center">
            <p className="text-sm leading-relaxed text-text-muted">
              لسّا آدم يلاحظ معكم. أول نمط يتوضّح، يبان هنا.
            </p>
          </GlassCard>
        )}
      </Section>

      {/* قسم ٣: لحظات تستاهل تُذكر — قصة قصيرة، لا سجلّ كامل */}
      <Section>
        <p className="font-display mb-3 mt-2 text-[16px] text-gold-strong">لحظات تستاهل تُذكر</p>
        {highlightMoments.length === 0 ? (
          <GlassCard className="text-center">
            <p className="text-sm leading-relaxed text-text-muted">أول خطوة تجرّبونها وتنجح، بتصير أول لحظة هنا.</p>
          </GlassCard>
        ) : (
          <div className="flex flex-col gap-3">
            {visibleMoments.map((m, i) => (
              <div
                key={m.logDate}
                className="glass-gold glow-pulse card-form-in flex flex-col gap-2 !p-5"
                style={{ animationDelay: `${i * 90}ms` }}
              >
                <span className="text-xs font-medium text-text-muted">{formatNightLabel(m.logDate)}</span>
                <p className="font-display text-[17px] leading-relaxed text-text">
                  لمّا جرّبتوا «{m.stepGiven}»، هدأ {child}.
                  <span className="mt-1 block text-gold-strong">هذا أنتم.</span>
                </p>
              </div>
            ))}
            {hiddenCount > 0 && (
              <div className="relative">
                <div className="blur-content glass-gold flex flex-col gap-2 !p-5">
                  <span className="text-xs font-medium text-text-muted">{formatNightLabel(highlightMoments[1].logDate)}</span>
                  <p className="font-display text-[17px] leading-relaxed text-text">لمّا جرّبتوا «{highlightMoments[1].stepGiven}»، هدأ {child}.</p>
                </div>
                <span className="blur-badge absolute top-4 start-4 px-4 py-1.5 text-sm">+{hiddenCount} لحظات محجوبة</span>
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
