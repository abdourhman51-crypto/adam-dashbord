"use client";

import { useScreenData } from "@/lib/telegram/useScreenData";
import { ScreenShell } from "@/components/ScreenShell";
import { AdamIntro } from "@/components/AdamIntro";
import { GlassCard } from "@/components/GlassCard";
import { LoadingState, OutsideTelegramState, NotFoundState, ErrorState } from "@/components/states";
import { formatNightLabel } from "@/lib/format";

interface WallMoment {
  logDate: string;
  stepGiven: string | null;
}

interface WallResponse {
  childName: string | null;
  moments: WallMoment[];
}

export default function WallPage() {
  const result = useScreenData<WallResponse>("/api/wall");

  if (result.state === "loading") return <LoadingState />;
  if (result.state === "outside_telegram") return <OutsideTelegramState />;
  if (result.state === "not_found") return <NotFoundState />;
  if (result.state === "error") return <ErrorState message={result.message} />;

  const { childName, moments } = result.data;
  const child = childName ?? "طفلكم";

  return (
    <ScreenShell>
      <AdamIntro text="هذي لحظات نجاح حقيقية صارت — وكل وحدة منها بسبب شي جرّبتوه أنتم، لا أنا. مرّروا يمين ويسار لتشوفوها." />

      {moments.length === 0 ? (
        <GlassCard className="text-center">
          <p className="text-sm leading-relaxed text-text-muted">
            أول خطوة تجرّبونها وتنجح، بتصير أول بطاقة هنا. الجدار بينتظركم.
          </p>
        </GlassCard>
      ) : (
        <div className="-mx-4 flex snap-x snap-mandatory gap-4 overflow-x-auto px-4 pb-2">
          {moments.map((m, i) => (
            <div
              key={m.logDate}
              className="glass-gold glow-pulse rise-in flex w-[78%] shrink-0 snap-center flex-col justify-between gap-4 !p-6"
              style={{ animationDelay: `${i * 60}ms`, minHeight: "220px" }}
            >
              <span className="text-xs font-medium text-text-muted">{formatNightLabel(m.logDate)}</span>
              <p className="font-display text-[19px] leading-relaxed text-text">
                لمّا جرّبتوا «{m.stepGiven}»، هدأ {child}.
                <span className="mt-2 block text-gold-strong">هذا أنتم.</span>
              </p>
            </div>
          ))}
        </div>
      )}
    </ScreenShell>
  );
}
