"use client";

import { useState } from "react";
import { LifeBuoy, ChevronLeft } from "lucide-react";
import { haptic } from "@/lib/telegram/client";
import { postAction } from "@/lib/telegram/fetcher";
import { TreeLoader } from "@/components/TreeLoader";

type Kind = "demand" | "flood";
type Stage = "idle" | "asking" | "loading" | "answered";

interface PanicResponse {
  childName: string;
  tag: string;
  lines: string[];
  personalized: boolean;
}

/**
 * سكربتان احتياطيان فقط — تُستعمل حين يتعذّر الوصول للخادم (بلا اتصال، أو
 * فشل). المسار الطبيعي دائماً عبر /api/panic، الذي يقرأ نمط هذه الأسرة
 * بالذات (get_tantrum_frame) بدل نص واحد يُعطى للجميع.
 */
function fallback(kind: Kind, child: string): PanicResponse {
  return {
    childName: child,
    tag: kind === "flood" ? "دخل في انهيار" : "لسّا يطلب منكم",
    lines:
      kind === "flood"
        ? [
            `${child} جسده أكبر منه الآن، والكلام لا يصله.`,
            "اجلسوا قريباً منه، صوت أخفض، كلمات أقل — ولا شيء تعلّمونه في هذه اللحظة.",
            "ستمرّ. وأنتم لم تخسروا شيئاً.",
          ]
        : [
            `${child} ما زال معكم، وهذا يعني أنه يطلب — لا ينهار.`,
            "جملة واحدة قصيرة، تُقال مرة: «لا. وأنا هنا.» ثم صمت، بلا نقاش.",
            "ثباتكم الآن هو الجواب كلّه.",
          ],
    personalized: false,
  };
}

/**
 * زرّ النجدة — متاح دائماً بضغطة واحدة، بوزن بصري هادئ لا يزاحم خطوة
 * اليوم. الردّ يأتي من /api/panic فيخصَّص فعلياً بمعرفة آدم بهذا الطفل
 * بالذات، لا نصّ عام واحد لكل المواقف.
 */
export function PanicButton({ child }: { child: string }) {
  const [stage, setStage] = useState<Stage>("idle");
  const [result, setResult] = useState<PanicResponse | null>(null);

  function open() {
    haptic("medium");
    setStage("asking");
  }

  async function choose(kind: Kind) {
    haptic("light");
    setStage("loading");
    const r = await postAction<PanicResponse>("/api/panic", { kind });
    setResult(r.state === "ok" ? r.data : fallback(kind, child));
    setStage("answered");
  }

  function reset() {
    haptic("light");
    setStage("idle");
    setResult(null);
  }

  if (stage === "asking") {
    return (
      <div className="glass-strong rise-in relative z-10 flex flex-col gap-4 p-5">
        <p className="font-display text-[16px] leading-relaxed text-text">
          أيّ وصف أقرب لِما تشوفونه في {child} الآن؟
        </p>
        <div className="flex flex-col gap-2.5">
          <button
            type="button"
            onClick={() => choose("demand")}
            className="pressable px-5 py-3.5 text-start text-sm font-medium leading-relaxed"
          >
            {child} يراقبكم وينتظر ردّكم، ويقدر يتكلّم
          </button>
          <button
            type="button"
            onClick={() => choose("flood")}
            className="pressable px-5 py-3.5 text-start text-sm font-medium leading-relaxed"
          >
            {child} ما يشوفكم، صراخ بلا كلام، وجسمه متيبّس
          </button>
          <button type="button" onClick={reset} className="px-4 py-3 text-center text-xs font-medium text-text-muted">
            رجوع
          </button>
        </div>
      </div>
    );
  }

  if (stage === "loading") {
    return (
      <div className="glass-strong rise-in relative z-10 flex items-center justify-center gap-3 p-6 text-sm text-text-muted">
        <TreeLoader size="sm" />
        <span>لحظة، أفكّر في حالة {child}…</span>
      </div>
    );
  }

  if (stage === "answered" && result) {
    return (
      <div className="glass-gold rise-in relative z-10 flex flex-col gap-3 p-5">
        <span className="w-fit rounded-full bg-bg-deep/40 px-3 py-1 text-[11px] font-semibold text-gold-strong">
          {result.tag}
        </span>
        {result.lines.map((line, i) => (
          <p
            key={i}
            className={
              i === 0
                ? "font-display text-[17px] leading-loose text-text"
                : "text-[15px] leading-loose text-text-secondary"
            }
          >
            {line}
          </p>
        ))}
        <button type="button" onClick={reset} className="pressable mt-1 px-5 py-2.5 text-sm font-medium">
          رجوع
        </button>
      </div>
    );
  }

  return (
    <button
      type="button"
      onClick={open}
      className="glass-soft rise-in relative z-10 flex w-full items-center gap-3 !rounded-2xl px-4 py-3.5 text-start transition-transform active:scale-[0.97]"
      style={{ touchAction: "manipulation" }}
    >
      <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-bg-deep/30 text-gold-strong">
        <LifeBuoy size={18} strokeWidth={2.2} />
      </span>
      <span className="flex-1">
        <span className="block text-[14px] font-semibold text-text">الوضع صعب الآن؟</span>
        <span className="block text-[12px] text-text-muted">اضغطوا، أنا معكم في ثانية</span>
      </span>
      <ChevronLeft size={16} className="shrink-0 text-text-muted" />
    </button>
  );
}
