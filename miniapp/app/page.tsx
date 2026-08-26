"use client";

import { useState } from "react";
import { CheckCircle2, MessageCircle, Sprout } from "lucide-react";
import { useScreenData } from "@/lib/telegram/useScreenData";
import { ScreenShell } from "@/components/ScreenShell";
import { AdamIntro } from "@/components/AdamIntro";
import { GlassCard } from "@/components/GlassCard";
import { ChatCTAButton } from "@/components/ChatCTAButton";
import { TreeLightbox } from "@/components/TreeLightbox";
import { LoadingState, OutsideTelegramState, NotFoundState, ErrorState } from "@/components/states";
import { postAction } from "@/lib/telegram/fetcher";
import { haptic, getInitDataRaw } from "@/lib/telegram/client";
import { returnToAdamChat } from "@/lib/upsell";
import { formatNumber } from "@/lib/format";

/**
 * جمل التحوّل — كل ليلة تُلتزم يُختار منها واحدة عشوائياً بدل "تم الحفظ" أو
 * تهنئة عامة. الهدف: الأم تحس "أنا تغيّرت"، لا مجرد "الفعل تسجّل".
 */
const COMMIT_LINES = [
  "ليلة أخرى اخترتم فيها طريقة جديدة.",
  "هذه ليست مصادفة — هذا نمط بدأ يتكوّن.",
  "خطوة أخرى، ونفس الاتجاه.",
  "هذا بالذات ما يصنع الفرق مع الوقت.",
];

interface TodayResponse {
  childName: string | null;
  stepGiven: string | null;
  stepCommittedAt: string | null;
}

export default function HomePage() {
  const [result, refetch] = useScreenData<TodayResponse>("/api/today");
  const [committing, setCommitting] = useState(false);
  const [error, setError] = useState(false);
  const [leafCount, setLeafCount] = useState<number | null>(null);
  const [treeOpen, setTreeOpen] = useState(false);
  const [justCommitted, setJustCommitted] = useState(false);
  const [commitLine] = useState(() => COMMIT_LINES[Math.floor(Math.random() * COMMIT_LINES.length)]);

  if (result.state === "loading") return <LoadingState />;
  if (result.state === "outside_telegram") return <OutsideTelegramState />;
  if (result.state === "not_found") return <NotFoundState />;
  if (result.state === "error") return <ErrorState message={result.message} />;

  const { childName, stepGiven, stepCommittedAt } = result.data;
  const child = childName ?? "طفلكم";

  async function commit() {
    if (committing) return;
    setCommitting(true);
    setError(false);
    const r = await postAction<{ committed: boolean }>("/api/commit-step", {});
    if (r.state === "ok" && r.data.committed) {
      haptic("medium");
      setJustCommitted(true);
      refetch();
      const initData = getInitDataRaw();
      if (initData) {
        fetch("/api/tree", { headers: { "x-telegram-init-data": initData } })
          .then((res) => (res.ok ? res.json() : null))
          .then((data: { calmCount: number } | null) => {
            if (data) setLeafCount(data.calmCount);
          })
          .catch(() => {});
      }
    } else {
      setError(true);
    }
    setCommitting(false);
  }

  // حالة ب — لا خطوة اليوم بعد
  if (!stepGiven) {
    return (
      <ScreenShell>
        <AdamIntro text={`هذي شاشتكم كل يوم — خطوة واحدة صغيرة تناسب ${child} بالذات، تُبنى من حكاياتكم لي.`} />
        <GlassCard variant="gold" className="rise-in text-center">
          <p className="font-display text-[19px] leading-relaxed text-text">
            ما عندنا خطوة لليوم بعد.
          </p>
          <p className="mt-2 text-sm leading-relaxed text-text-muted">
            احكوا لي كيف كان يومكم مع {child}، وأعطيكم شيئاً واحداً صغيراً تجرّبونه الليلة.
          </p>
          <div className="mt-5">
            <ChatCTAButton label="احكوا لآدم عن يومكم" />
          </div>
        </GlassCard>
      </ScreenShell>
    );
  }

  const committed = Boolean(stepCommittedAt);

  return (
    <ScreenShell>
      <AdamIntro text={`هذي خطوة اليوم مع ${child} — بُنيت من آخر شي حكيتوه لي، جرّبوها بأسوأ لحظة لا أحسنها.`} />

      <GlassCard variant="gold" className="rise-in">
        <p className="text-xs font-medium text-text-muted">خطوة اليوم</p>
        <p className="font-display mt-3 text-[22px] leading-loose text-text">{stepGiven}</p>

        {committed && justCommitted ? (
          <div className="mt-5 flex flex-col items-center gap-3">
            <svg viewBox="0 0 24 24" width={36} className="leaf-grow-in drop-shadow-[0_0_8px_rgba(227,178,60,0.55)]">
              <path d="M12 2c5 3 8 7 8 11a8 8 0 0 1-16 0c0-4 3-8 8-11Z" fill="#e3b23c" />
            </svg>
            <p className="font-display text-center text-[16px] text-text">{commitLine}</p>
            {leafCount !== null && (
              <button
                type="button"
                onClick={() => {
                  haptic("light");
                  setTreeOpen(true);
                }}
                className="pressable flex items-center gap-1.5 !rounded-full px-4 py-2 text-xs font-medium text-text-muted"
              >
                <Sprout size={14} strokeWidth={2.2} />
                شجرتكم كبرت لـ {formatNumber(leafCount)} ورقة — شوفوها
              </button>
            )}
          </div>
        ) : committed ? (
          <div className="mt-5 flex w-full items-center justify-center gap-2 rounded-full border-[1.5px] border-emerald-strong px-5 py-3 text-sm font-semibold text-emerald-strong">
            <CheckCircle2 size={18} strokeWidth={2.2} />
            <span>تم الالتزام</span>
          </div>
        ) : (
          <div className="mt-5 flex flex-col gap-2.5">
            <button
              type="button"
              onClick={commit}
              disabled={committing}
              className="pressable-gold flex items-center justify-center gap-2 px-5 py-3 text-sm font-semibold disabled:opacity-60"
            >
              {committing ? (
                "جاري التسجيل…"
              ) : (
                <>
                  <CheckCircle2 size={17} strokeWidth={2.2} />
                  سأطبّق ذلك
                </>
              )}
            </button>
            <button
              type="button"
              onClick={() => {
                haptic("light");
                returnToAdamChat();
              }}
              className="pressable flex items-center justify-center gap-2 px-5 py-3 text-sm font-medium"
            >
              <MessageCircle size={16} strokeWidth={2.2} />
              عندي استفسار آخر
            </button>
            {error && (
              <p className="text-center text-xs text-text-muted">ما قدرنا نسجّل، جرّبوا مرة ثانية.</p>
            )}
          </div>
        )}
      </GlassCard>

      {treeOpen && <TreeLightbox leafCount={leafCount ?? 0} onClose={() => setTreeOpen(false)} />}
    </ScreenShell>
  );
}
