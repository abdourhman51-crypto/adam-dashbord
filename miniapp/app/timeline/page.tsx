"use client";

import { useEffect, useMemo, useState } from "react";
import { useScreenData } from "@/lib/telegram/useScreenData";
import { ScreenShell } from "@/components/ScreenShell";
import { AdamIntro } from "@/components/AdamIntro";
import { GlassCard } from "@/components/GlassCard";
import { QuickReplyCard } from "@/components/QuickReplyCard";
import { AchievementCelebration } from "@/components/AchievementCelebration";
import { LoadingState, OutsideTelegramState, NotFoundState, ErrorState } from "@/components/states";
import { formatNightLabel } from "@/lib/format";
import { computeStreak, isMilestone } from "@/lib/streak";

interface TimelineNight {
  logDate: string;
  result: "calm" | "hard" | "normal" | null;
  stepGiven: string | null;
  stepStatus: "done" | "tried_failed" | "not_tried" | null;
}

interface TimelineResponse {
  childName: string | null;
  trendLine: string | null;
  todayOpen: boolean;
  nights: TimelineNight[];
  patterns: { label: string; description: string | null }[];
}

const STEP_LABEL: Record<string, string> = {
  done: "جُرّبت",
  tried_failed: "جُرّبت ولم تنجح بعد",
  not_tried: "لم تُجرَّب",
};

function celebratedKey(streak: number) {
  return `adam_celebrated_streak_${streak}`;
}

export default function TimelinePage() {
  const [result, refetch] = useScreenData<TimelineResponse>("/api/timeline");
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

  const { childName, trendLine, todayOpen, nights, patterns } = result.data;
  const child = childName ?? "طفلكم";

  return (
    <ScreenShell>
      <AdamIntro
        text={`هذي كل ليلة حكيتوا لي عنها مع ${child}، مرتّبة كما حصلت فعلاً — نقطة ذهبية للّيلة الهادئة، ونقطة رمادية هادئة للصعبة، بلا حكم على أي منهما.`}
      />

      {todayOpen && <QuickReplyCard onAnswered={refetch} />}

      {trendLine && (
        <GlassCard variant="strong" className="rise-in text-center">
          <p className="font-display text-[19px] leading-relaxed text-gold-strong">{trendLine}</p>
        </GlassCard>
      )}

      {nights.length === 0 ? (
        <GlassCard className="text-center">
          <p className="text-sm leading-relaxed text-text-muted">
            ما عندنا ليالٍ مسجّلة بعد. أول ما تحكوا لي عن ليلة، تبدأ تظهر هنا.
          </p>
        </GlassCard>
      ) : (
        <div className="relative flex flex-col gap-4 ps-3">
          <div
            className="absolute bottom-2 top-2 w-px bg-glass-border"
            style={{ insetInlineStart: "7px" }}
            aria-hidden="true"
          />
          {nights.map((n, i) => {
            const isCalm = n.result === "calm";
            const isHard = n.result === "hard";
            return (
              <div key={n.logDate} className="relative rise-in" style={{ animationDelay: `${i * 40}ms` }}>
                <span
                  className={`absolute top-1.5 h-3.5 w-3.5 rounded-full ${
                    isCalm ? "glow-pulse bg-gold" : isHard ? "bg-hard" : "bg-emerald"
                  }`}
                  style={{ insetInlineStart: "-3px" }}
                  aria-hidden="true"
                />
                <div className="ms-6">
                  <GlassCard variant={isCalm ? "gold" : "default"} className="!p-4">
                    <div className="flex items-center justify-between">
                      <span className="text-sm font-medium text-text">{formatNightLabel(n.logDate)}</span>
                      <span
                        className={`text-xs font-semibold ${isCalm ? "text-gold-strong" : "text-text-muted"}`}
                      >
                        {isCalm ? "هادئة" : isHard ? "صعبة" : "عادية"}
                      </span>
                    </div>
                    {isHard && n.stepGiven && (
                      <p className="mt-2 text-xs leading-relaxed text-text-muted">
                        الخطوة اللي جرّبناها بعدها: «{n.stepGiven}» — {STEP_LABEL[n.stepStatus ?? ""] ?? "بانتظار النتيجة"}
                      </p>
                    )}
                    {!isHard && n.stepGiven && n.stepStatus === "done" && (
                      <p className="mt-2 text-xs leading-relaxed text-text-secondary">
                        الخطوة اللي نجحت: «{n.stepGiven}»
                      </p>
                    )}
                  </GlassCard>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {patterns.length > 0 && (
        <GlassCard className="rise-in">
          <p className="font-display mb-3 text-[15px] text-gold-strong">ما يتكرّر ويربط بين الليالي</p>
          <div className="flex flex-col gap-3">
            {patterns.map((p) => (
              <div key={p.label} className="flex items-start gap-2 border-e-2 border-e-emerald-strong pe-3">
                <div>
                  <p className="text-sm font-medium text-text">{p.label}</p>
                  {p.description && (
                    <p className="mt-0.5 text-xs leading-relaxed text-text-muted">{p.description}</p>
                  )}
                </div>
              </div>
            ))}
          </div>
        </GlassCard>
      )}

      {celebrating && (
        <AchievementCelebration streak={streak} childName={child} onClose={() => setCelebrating(false)} />
      )}
    </ScreenShell>
  );
}
