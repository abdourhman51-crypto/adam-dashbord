"use client";

import { useState } from "react";
import { haptic } from "@/lib/telegram/client";

type Kind = "flood" | "demand";
type Stage = "idle" | "asking" | "answered";

/**
 * السكربتان ثابتان بنصّهما — لا توليد، لا استدعاء شبكة. الوالد في هذه
 * اللحظة لا يملك ثانية ينتظر فيها تحميلاً، ولا شيء هنا يستحق التخصيص أكثر
 * من الوصول الفوري. النصّان معتمدان مسبقاً (نفس صياغة migration الوكيل).
 */
const SCRIPTS: Record<Kind, string[]> = {
  flood: [
    "جسده أكبر منه الآن، والكلام لا يصله.",
    "اجلسوا قريباً منه، صوت أخفض، كلمات أقل — ولا شيء تعلّمونه في هذه اللحظة.",
    "ستمرّ. وأنتم لم تخسروا شيئاً.",
  ],
  demand: [
    "ما زال معكم، وهذا يعني أنه يطلب — لا ينهار.",
    "جملة واحدة قصيرة، تُقال مرة: «لا. وأنا هنا.» ثم صمت، بلا نقاش.",
    "ثباتكم الآن هو الجواب كلّه.",
  ],
};

/**
 * زرّ النجدة — أضخم عنصر في شاشة "الآن" عمداً. الذهبي القويّ هنا، لا في
 * دعوة الاشتراك: والدٌ على وشك الانفجار يجب أن يرى المخرج قبل أي شيء آخر.
 */
export function PanicButton() {
  const [stage, setStage] = useState<Stage>("idle");
  const [kind, setKind] = useState<Kind | null>(null);
  const [acked, setAcked] = useState(false);

  function open() {
    haptic("medium");
    setAcked(false);
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
        <p className="font-display text-[17px] leading-relaxed text-text">
          أنا معكم الآن.
          <br />
          هل يراكم وينتظر ردّكم — أم غائب عنكم تماماً؟
        </p>
        <div className="flex flex-col gap-2.5">
          <button
            type="button"
            onClick={() => choose("flood")}
            className="pressable px-5 py-3 text-sm font-medium"
          >
            غائب عني تماماً
          </button>
          <button
            type="button"
            onClick={() => choose("demand")}
            className="pressable px-5 py-3 text-sm font-medium"
          >
            يراني ويطلب شيئاً
          </button>
          <button
            type="button"
            onClick={reset}
            className="px-4 py-3 text-center text-xs font-medium text-text-muted"
          >
            شيء آخر
          </button>
        </div>
      </div>
    );
  }

  if (stage === "answered" && kind) {
    return (
      <div className="glass-gold rise-in relative z-10 flex flex-col gap-3 p-5">
        {SCRIPTS[kind].map((line, i) => (
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
    <div className="rise-in flex flex-col gap-2">
      <button
        type="button"
        onClick={open}
        className="pressable-gold glow-pulse flex w-full flex-col items-center gap-1 !rounded-[28px] px-6 py-5 text-center"
      >
        <span className="font-display text-[19px] font-extrabold leading-tight">الوضع ينفجر الآن</span>
        <span className="text-[13px] font-medium opacity-80">اضغطوا — أنا معكم في ثانية</span>
      </button>
      {!acked ? (
        <button
          type="button"
          onClick={() => {
            haptic("light");
            setAcked(true);
          }}
          className="px-4 py-2 text-center text-xs font-medium text-text-muted"
        >
          انفجرتُ اليوم
        </button>
      ) : (
        <p className="rise-in px-4 text-center text-xs leading-relaxed text-text-muted">
          لا شيء مطلوب منكم الآن. أنا هنا، وغداً ليلة جديدة.
        </p>
      )}
    </div>
  );
}
