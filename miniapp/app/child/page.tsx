"use client";

import Image from "next/image";
import { useScreenData } from "@/lib/telegram/useScreenData";
import { ScreenShell } from "@/components/ScreenShell";
import { GlassCard } from "@/components/GlassCard";
import { LoadingState, OutsideTelegramState, NotFoundState, ErrorState } from "@/components/states";

interface ChildResponse {
  childName: string | null;
  insight: string | null;
}

export default function ChildPage() {
  const result = useScreenData<ChildResponse>("/api/child");

  if (result.state === "loading") return <LoadingState />;
  if (result.state === "outside_telegram") return <OutsideTelegramState />;
  if (result.state === "not_found") return <NotFoundState />;
  if (result.state === "error") return <ErrorState message={result.message} />;

  const { childName, insight } = result.data;
  const child = childName ?? "طفلكم";

  return (
    <ScreenShell>
      <div className="mt-6 flex flex-col items-center gap-6 text-center">
        <div className="glass-gold glow-pulse h-28 w-28 overflow-hidden !rounded-full p-0">
          <Image
            src="/brand/adam.png"
            alt=""
            width={224}
            height={224}
            className="h-full w-full object-cover object-top"
            priority
          />
        </div>

        <div>
          <p className="text-sm text-text-muted">آدم يحكي لكم عن</p>
          <h1 className="font-display text-[26px] text-gold-strong">{child}</h1>
        </div>

        {insight ? (
          <GlassCard variant="strong" className="rise-in">
            <p className="font-display text-[19px] leading-loose text-text">{insight}</p>
          </GlassCard>
        ) : (
          <GlassCard>
            <p className="text-sm leading-relaxed text-text-muted">
              لسّا آدم يتعرّف على {child} أكثر. كل ما تحكوا لي، تتوضّح لي شخصيته أكثر — وبتلقون هنا وصفاً حقيقياً عنه، لا عن مشاكله.
            </p>
          </GlassCard>
        )}
      </div>
    </ScreenShell>
  );
}
