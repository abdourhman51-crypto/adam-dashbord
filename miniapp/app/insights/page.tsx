"use client";

import { useEffect, useMemo, useState } from "react";
import Image from "next/image";
import { useScreenData } from "@/lib/telegram/useScreenData";
import { ScreenShell } from "@/components/ScreenShell";
import { AdamIntro } from "@/components/AdamIntro";
import { GlassCard } from "@/components/GlassCard";
import { QuickReplyCard } from "@/components/QuickReplyCard";
import { UpsellButton } from "@/components/UpsellButton";
import { ProgressRing } from "@/components/ProgressRing";
import { CountUpNumber } from "@/components/CountUpNumber";
import { AchievementCelebration } from "@/components/AchievementCelebration";
import { useScrollReveal } from "@/components/useScrollReveal";
import { LoadingState, OutsideTelegramState, NotFoundState, ErrorState } from "@/components/states";
import { formatNightLabel, formatNumber } from "@/lib/format";
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

const STEP_LABEL: Record<string, string> = {
  done: "جُرّبت",
  tried_failed: "جُرّبت ولم تنجح بعد",
  not_tried: "لم تُجرَّب",
};

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

  const { childName, insight, effort, todayOpen, nights, patterns, wall } = result.data;
  const child = childName ?? "طفلكم";
  const percent = effort.triedThisWeek > 0 ? Math.round((effort.calmThisWeek / effort.triedThisWeek) * 100) : 0;
  const visibleMoments = wall.isPaid ? wall.moments : wall.moments.slice(0, 1);
  const hiddenCount = wall.isPaid ? 0 : Math.max(0, wall.moments.length - 1);

  return (
    <ScreenShell>
      <AdamIntro text={`هذي كل ما أعرفه عنكم وعن ${child} — من شخصيته لتقدّمكم لإنجازاتكم، بمكان واحد.`} />

      {/* قسم ١: من هو الطفل */}
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

      {/* قسم ٢: التقدّم بالأرقام */}
      <Section>
        <GlassCard variant="strong">
          <p className="font-display mb-4 text-[16px] text-gold-strong">تقدّمكم بالأرقام</p>
          <div className="flex items-center justify-around">
            <ScrollRingWrapper percent={percent} />
            <div className="flex flex-col gap-3 text-center">
              <div>
                <p className="font-display text-2xl text-text">
                  <CountUpTrigger value={effort.triedThisWeek} />
                </p>
                <p className="text-xs text-text-muted">جرّبتوها هالأسبوع</p>
              </div>
              <div>
                <p className="font-display text-2xl text-text">
                  <CountUpTrigger value={effort.triedLastWeek} />
                </p>
                <p className="text-xs text-text-muted">الأسبوع اللي فات</p>
              </div>
            </div>
          </div>
        </GlassCard>
      </Section>

      {/* قسم ٣: الخط الزمني */}
      <Section>
        <p className="font-display mb-3 mt-2 text-[16px] text-gold-strong">الخط الصادق</p>
        {todayOpen && (
          <div className="mb-4">
            <QuickReplyCard onAnswered={refetch} />
          </div>
        )}
        {nights.length === 0 ? (
          <GlassCard className="text-center">
            <p className="text-sm leading-relaxed text-text-muted">
              ما عندنا ليالٍ مسجّلة بعد. أول ما تحكوا لي عن ليلة، تبدأ تظهر هنا.
            </p>
          </GlassCard>
        ) : (
          <div className="relative flex flex-col gap-4 ps-3">
            <div className="absolute bottom-2 top-2 w-px bg-glass-border" style={{ insetInlineStart: "7px" }} aria-hidden="true" />
            {nights.map((n) => {
              const isCalm = n.result === "calm";
              const isHard = n.result === "hard";
              return (
                <div key={n.logDate} className="relative">
                  <span
                    className={`absolute top-1.5 h-3.5 w-3.5 rounded-full ${isCalm ? "glow-pulse bg-gold" : isHard ? "bg-hard" : "bg-emerald"}`}
                    style={{ insetInlineStart: "-3px" }}
                    aria-hidden="true"
                  />
                  <div className="ms-6">
                    <GlassCard variant={isCalm ? "gold" : "default"} className="!p-4">
                      <div className="flex items-center justify-between">
                        <span className="text-sm font-medium text-text">{formatNightLabel(n.logDate)}</span>
                        <span className={`text-xs font-semibold ${isCalm ? "text-gold-strong" : "text-text-muted"}`}>
                          {isCalm ? "هادئة" : isHard ? "صعبة" : "عادية"}
                        </span>
                      </div>
                      {isHard && n.stepGiven && (
                        <p className="mt-2 text-xs leading-relaxed text-text-muted">
                          الخطوة اللي جرّبناها بعدها: «{n.stepGiven}» — {STEP_LABEL[n.stepStatus ?? ""] ?? "بانتظار النتيجة"}
                        </p>
                      )}
                      {!isHard && n.stepGiven && n.stepStatus === "done" && (
                        <p className="mt-2 text-xs leading-relaxed text-text-secondary">الخطوة اللي نجحت: «{n.stepGiven}»</p>
                      )}
                    </GlassCard>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </Section>

      {/* قسم ٤: الأنماط المتكرّرة */}
      {patterns.length > 0 && (
        <Section>
          <GlassCard>
            <p className="font-display mb-3 text-[15px] text-gold-strong">ما يتكرّر ويربط بين الليالي</p>
            <div className="flex flex-col gap-3">
              {patterns.map((p) => (
                <div key={p.label} className="flex items-start gap-2 border-e-2 border-e-emerald-strong pe-3">
                  <div>
                    <p className="text-sm font-medium text-text"><IconText text={p.label} /></p>
                    {p.description && (
                      <p className="mt-0.5 text-xs leading-relaxed text-text-muted">
                        <IconText text={p.description} />
                      </p>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </GlassCard>
        </Section>
      )}

      {/* قسم ٥: جدار الإنجاز */}
      <Section>
        <p className="font-display mb-3 mt-2 text-[16px] text-gold-strong">جدار الإنجاز</p>
        {wall.moments.length === 0 ? (
          <GlassCard className="text-center">
            <p className="text-sm leading-relaxed text-text-muted">أول خطوة تجرّبونها وتنجح، بتصير أول بطاقة هنا.</p>
          </GlassCard>
        ) : (
          <div className="-mx-4 flex snap-x snap-mandatory gap-4 overflow-x-auto px-4 pb-2">
            {visibleMoments.map((m) => (
              <div
                key={m.logDate}
                className="glass-gold glow-pulse flex w-[78%] shrink-0 snap-center flex-col justify-between gap-4 !p-6"
                style={{ minHeight: "200px" }}
              >
                <span className="text-xs font-medium text-text-muted">{formatNightLabel(m.logDate)}</span>
                <p className="font-display text-[18px] leading-relaxed text-text">
                  لمّا جرّبتوا «{m.stepGiven}»، هدأ {child}.
                  <span className="mt-2 block text-gold-strong">هذا أنتم.</span>
                </p>
              </div>
            ))}
            {hiddenCount > 0 && (
              <div className="relative flex w-[78%] shrink-0 snap-center items-center justify-center" style={{ minHeight: "200px" }}>
                <div className="glass absolute inset-x-3 bottom-0 top-4 opacity-40" aria-hidden="true" />
                <div className="glass absolute inset-x-1.5 bottom-0 top-2 opacity-70" aria-hidden="true" />
                <div className="blur-content glass-gold flex w-full flex-col justify-between gap-4 !p-6" style={{ minHeight: "200px" }}>
                  <span className="text-xs font-medium text-text-muted">{formatNightLabel(wall.moments[1].logDate)}</span>
                  <p className="font-display text-[18px] leading-relaxed text-text">لمّا جرّبتوا «{wall.moments[1].stepGiven}»، هدأ {child}.</p>
                </div>
                <span className="blur-badge absolute top-4 px-4 py-1.5 text-sm">+{formatNumber(hiddenCount)} إنجازات محجوبة</span>
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

function ScrollRingWrapper({ percent }: { percent: number }) {
  const { ref, visible } = useScrollReveal<HTMLDivElement>();
  return (
    <div ref={ref}>
      <ProgressRing percent={percent} trigger={visible} label="هدوء هالأسبوع" />
    </div>
  );
}

function CountUpTrigger({ value }: { value: number }) {
  const { ref, visible } = useScrollReveal<HTMLSpanElement>();
  return (
    <span ref={ref}>
      <CountUpNumber value={value} trigger={visible} />
    </span>
  );
}
