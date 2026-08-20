"use client";

import { useScreenData } from "@/lib/telegram/useScreenData";
import { ScreenShell } from "@/components/ScreenShell";
import { AdamIntro } from "@/components/AdamIntro";
import { GlassCard } from "@/components/GlassCard";
import { UpsellButton } from "@/components/UpsellButton";
import { LoadingState, OutsideTelegramState, NotFoundState, ErrorState } from "@/components/states";
import { formatNightLabel, formatNumber } from "@/lib/format";

interface WallMoment {
  logDate: string;
  stepGiven: string | null;
}

interface WallResponse {
  isPaid: boolean;
  childName: string | null;
  moments: WallMoment[];
}

function MomentCard({
  m,
  child,
  index,
  blurred,
}: {
  m: WallMoment;
  child: string;
  index: number;
  blurred: boolean;
}) {
  return (
    <div
      className="glass-gold glow-pulse rise-in relative flex w-[78%] shrink-0 snap-center flex-col justify-between gap-4 overflow-hidden !p-6"
      style={{ animationDelay: `${index * 60}ms`, minHeight: "220px" }}
    >
      <div className={blurred ? "blur-content" : undefined}>
        <span className="text-xs font-medium text-text-muted">{formatNightLabel(m.logDate)}</span>
        <p className="font-display mt-4 text-[19px] leading-relaxed text-text">
          لمّا جرّبتوا «{m.stepGiven}»، هدأ {child}.
          <span className="mt-2 block text-gold-strong">هذا أنتم.</span>
        </p>
      </div>
    </div>
  );
}

export default function WallPage() {
  const [result] = useScreenData<WallResponse>("/api/wall");

  if (result.state === "loading") return <LoadingState />;
  if (result.state === "outside_telegram") return <OutsideTelegramState />;
  if (result.state === "not_found") return <NotFoundState />;
  if (result.state === "error") return <ErrorState message={result.message} />;

  const { childName, moments, isPaid } = result.data;
  const child = childName ?? "طفلكم";
  const visible = isPaid ? moments : moments.slice(0, 1);
  const hiddenCount = isPaid ? 0 : Math.max(0, moments.length - 1);

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
          {visible.map((m, i) => (
            <MomentCard key={m.logDate} m={m} child={child} index={i} blurred={false} />
          ))}

          {hiddenCount > 0 && (
            <div
              className="relative flex w-[78%] shrink-0 snap-center items-center justify-center"
              style={{ minHeight: "220px" }}
            >
              <div
                className="glass absolute inset-x-3 bottom-0 top-4 opacity-40"
                aria-hidden="true"
              />
              <div
                className="glass absolute inset-x-1.5 bottom-0 top-2 opacity-70"
                aria-hidden="true"
              />
              <MomentCard m={moments[1]} child={child} index={1} blurred />
              <span className="blur-badge absolute top-4 px-4 py-1.5 text-sm">
                +{formatNumber(hiddenCount)} إنجازات أخرى محجوبة
              </span>
            </div>
          )}
        </div>
      )}

      {hiddenCount > 0 && (
        <UpsellButton label="🔒 وفيه أكثر من هذا — يظهر كامل مع المرافقة الكاملة" />
      )}
    </ScreenShell>
  );
}
