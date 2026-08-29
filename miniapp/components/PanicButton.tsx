"use client";

import { useState } from "react";
import { LifeBuoy, ChevronLeft } from "lucide-react";
import { haptic } from "@/lib/telegram/client";

type Kind = "demand" | "flood";
type Stage = "idle" | "asking" | "answered";

/**
 * السكربتان ثابتان بنصّهما — لا توليد، لا استدعاء شبكة. الوالد في هذه
 * اللحظة لا يملك ثانية ينتظر فيها تحميلاً. النصّان معتمدان مسبقاً (نفس
 * صياغة migration الوكيل)، والوسم فوقهما يعطي الجواب دفعة واحدة قبل القراءة.
 */
const RESULT: Record<Kind, { tag: string; lines: string[] }> = {
  demand: {
    tag: "لسّا يطلب منكم",
    lines: [
      "ما زال معكم، وهذا يعني أنه يطلب — لا ينهار.",
      "جملة واحدة قصيرة، تُقال مرة: «لا. وأنا هنا.» ثم صمت، بلا نقاش.",
      "ثباتكم الآن هو الجواب كلّه.",
    ],
  },
  flood: {
    tag: "دخل في انهيار",
    lines: [
      "جسده أكبر منه الآن، والكلام لا يصله.",
      "اجلسوا قريباً منه، صوت أخفض، كلمات أقل — ولا شيء تعلّمونه في هذه اللحظة.",
      "ستمرّ. وأنتم لم تخسروا شيئاً.",
    ],
  },
};

/**
 * زرّ النجدة — متاح دائماً بضغطة واحدة، لكن بوزن بصري هادئ لا يزاحم خطوة
 * اليوم (الفعل الرئيسي اليومي). لا يشتعل إلا حين يُفتح فعلاً.
 */
export function PanicButton() {
  const [stage, setStage] = useState<Stage>("idle");
  const [kind, setKind] = useState<Kind | null>(null);

  function open() {
    haptic("medium");
    setStage("asking");
  }

  function choose(k: Kind) {
    haptic("light");
    setKind(k);
    setStage("answered");
  }

  function reset() {
    haptic("light");
    setStage("idle");
    setKind(null);
  }

  if (stage === "asking") {
    return (
      <div className="glass-strong rise-in relative z-10 flex flex-col gap-4 p-5">
        <p className="font-display text-[16px] leading-relaxed text-text">
          أيّ وصف أقرب لِما تشوفونه فيه الآن؟
        </p>
        <div className="flex flex-col gap-2.5">
          <button
            type="button"
            onClick={() => choose("demand")}
            className="pressable px-5 py-3.5 text-start text-sm font-medium leading-relaxed"
          >
            يراقبكم وينتظر ردّكم، ويقدر يتكلّم
          </button>
          <button
            type="button"
            onClick={() => choose("flood")}
            className="pressable px-5 py-3.5 text-start text-sm font-medium leading-relaxed"
          >
            ما يشوفكم، صراخ بلا كلام، وجسمه متيبّس
          </button>
          <button type="button" onClick={reset} className="px-4 py-3 text-center text-xs font-medium text-text-muted">
            رجوع
          </button>
        </div>
      </div>
    );
  }

  if (stage === "answered" && kind) {
    const r = RESULT[kind];
    return (
      <div className="glass-gold rise-in relative z-10 flex flex-col gap-3 p-5">
        <span className="w-fit rounded-full bg-bg-deep/40 px-3 py-1 text-[11px] font-semibold text-gold-strong">
          {r.tag}
        </span>
        {r.lines.map((line, i) => (
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
