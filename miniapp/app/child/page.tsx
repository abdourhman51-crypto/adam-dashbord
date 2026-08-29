"use client";

import Image from "next/image";
import { useScreenData } from "@/lib/telegram/useScreenData";
import { ScreenShell } from "@/components/ScreenShell";
import { AdamIntro } from "@/components/AdamIntro";
import { GlassCard } from "@/components/GlassCard";
import { useScrollReveal } from "@/components/useScrollReveal";
import { LoadingState, OutsideTelegramState, NotFoundState, ErrorState } from "@/components/states";
import { formatNightLabel } from "@/lib/format";
import { IconText } from "@/lib/emojiIcons";

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

const NIGHT_LABEL: Record<NonNullable<Night["result"]>, string> = {
  calm: "مرّت بهدوء",
  hard: "كانت صعبة",
  normal: "عادية",
};

function Section({ children }: { children: React.ReactNode }) {
  const { ref, visible } = useScrollReveal<HTMLDivElement>();
  return (
    <div ref={ref} className={visible ? "rise-in" : "opacity-0"}>
      {children}
    </div>
  );
}

export default function ChildPage() {
  const [result] = useScreenData<InsightsResponse>("/api/insights");

  if (result.state === "loading") return <LoadingState />;
  if (result.state === "outside_telegram") return <OutsideTelegramState />;
  if (result.state === "not_found") return <NotFoundState />;
  if (result.state === "error") return <ErrorState message={result.message} />;

  const { childName, insight, patterns, nights, effort } = result.data;
  const child = childName ?? "طفلكم";
  const recentNights = nights.slice(0, 3);

  return (
    <ScreenShell>
      <AdamIntro text={`هذا ما فهمته عن ${child} حتى الآن — وتقدرون تصحّحوني إن حسّيتوا إني أخطأت.`} />

      <Section>
        <div className="mt-2 flex flex-col items-center gap-4 text-center">
          <div className="glass-gold h-24 w-24 overflow-hidden !rounded-full p-0">
            <Image
              src="/brand/adam.png"
              alt=""
              width={192}
              height={192}
              className="h-full w-full object-cover object-top"
              priority
            />
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

      <Section>
        <p className="font-display mb-3 mt-2 text-[16px] text-gold-strong">ما يلاحظه آدم فيه</p>
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

      {recentNights.length > 0 && (
        <Section>
          <p className="font-display mb-3 mt-2 text-[16px] text-gold-strong">آخر ما حكيتوه لي</p>
          <GlassCard>
            <div className="flex flex-col gap-3">
              {recentNights.map((n, i) => (
                <div
                  key={n.logDate}
                  className={`flex items-center justify-between gap-3 ${
                    i > 0 ? "border-t border-glass-border pt-3" : ""
                  }`}
                >
                  <span className="text-xs text-text-muted">{formatNightLabel(n.logDate)}</span>
                  <span className="text-sm font-medium text-text">
                    {n.result ? NIGHT_LABEL[n.result] : "—"}
                  </span>
                </div>
              ))}
            </div>
          </GlassCard>
        </Section>
      )}
    </ScreenShell>
  );
}
