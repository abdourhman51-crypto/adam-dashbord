"use client";

import { useState } from "react";
import { LifeBuoy, ChevronLeft } from "lucide-react";
import { haptic } from "@/lib/telegram/client";
import { postAction } from "@/lib/telegram/fetcher";
import { returnToAdamChat } from "@/lib/upsell";
import { trackClick } from "@/lib/analytics";

type Route = "away" | "stay";
type Stage = "idle" | "asking" | "script" | "closing" | "done";

/**
 * سكربتان ثابتان — لا توليد ولا انتظار شبكة. والدٌ على وشك الانفجار لا يملك
 * ثانية للتحميل، ولا شيء هنا يستحق التخصيص أكثر من الوصول الفوري.
 *
 * المحتوى موجّه للوالد لا للطفل، لأنّ هذه هي المشكلة الأولى في البيانات:
 * ٤٩ من ١٨٦ أسرة كتبت عن انفجارها هي. والافتراق بين السكربتين ليس عن حالة
 * الطفل بل عمّا يستطيعه الوالد الآن — والابتعاد الجسدي هو الأنجع حين يمكن.
 */
const SCRIPTS: Record<Route, { tag: string; lines: string[] }> = {
  away: {
    tag: "ابتعاد لحظة",
    lines: [
      "الابتعاد خطوتين وإدارة الظهر — الآن، قبل أي كلمة.",
      "زفير طويل من الفم، أطول من الشهيق. ثلاث مرات.",
      "هو بأمان في هذه الثواني — وهذه الثواني هي ما ينقص الآن، لا هو.",
    ],
  },
  stay: {
    tag: "لا يمكن الابتعاد",
    lines: [
      "خفض الصوت عمداً بدل رفعه — الجسد يتبع الصوت.",
      "جملة واحدة بهدوء بدل الانفعال، مثل: «الوضع صعب الآن، ونتكلّم بعد قليل.» ثم صمت.",
      "تأجيل العقاب ليس ضعفاً — الضعف أن يقع في ذروة الانفعال.",
    ],
  },
};

/**
 * زرّ النجدة — متاح دائماً بضغطة، بوزن بصري هادئ لا يزاحم خطوة اليوم.
 * وينتهي دائماً بسؤال واحد صادق، لأنّ إجابته هي المقياس الشمالي للمنتج.
 */
export function PanicButton() {
  const [stage, setStage] = useState<Stage>("idle");
  const [route, setRoute] = useState<Route | null>(null);
  const [held, setHeld] = useState(false);

  function open() {
    haptic("medium");
    trackClick("panic_button_open", "home");
    setStage("asking");
  }

  function choose(r: Route) {
    haptic("light");
    setRoute(r);
    setStage("script");
  }

  async function close(kind: "held" | "erupted") {
    haptic(kind === "held" ? "medium" : "light");
    setHeld(kind === "held");
    setStage("done");
    // بأفضل جهد: الردّ وصل بالفعل، وفشل التسجيل لا يُظهر خطأً في هذه اللحظة
    await postAction("/api/moment", { kind, source: "panic_button" });
  }

  function reset() {
    haptic("light");
    setStage("idle");
    setRoute(null);
  }

  if (stage === "asking") {
    return (
      <div className="glass-strong rise-in relative z-10 flex flex-col gap-4 p-5">
        <p className="font-display text-[16px] leading-relaxed text-text">
          أنا معكم. ممكن الابتعاد لحظة عنه الآن؟
        </p>
        <div className="flex flex-col gap-2.5">
          <button
            type="button"
            onClick={() => choose("away")}
            className="pressable px-5 py-3.5 text-start text-sm font-medium leading-relaxed"
          >
            نعم، ممكن الابتعاد دقيقة
          </button>
          <button
            type="button"
            onClick={() => choose("stay")}
            className="pressable px-5 py-3.5 text-start text-sm font-medium leading-relaxed"
          >
            لا، لازم البقاء معه
          </button>
          <button type="button" onClick={reset} className="px-4 py-3 text-center text-xs font-medium text-text-muted">
            رجوع
          </button>
        </div>
      </div>
    );
  }

  if (stage === "script" && route) {
    const s = SCRIPTS[route];
    return (
      <div className="glass-gold rise-in relative z-10 flex flex-col gap-3 p-5">
        <span className="w-fit rounded-full bg-bg-deep/40 px-3 py-1 text-[11px] font-semibold text-gold-strong">
          {s.tag}
        </span>
        {s.lines.map((line, i) => (
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
        <button
          type="button"
          onClick={() => setStage("closing")}
          className="pressable mt-2 px-5 py-2.5 text-sm font-medium"
        >
          مرّت اللحظة
        </button>
      </div>
    );
  }

  if (stage === "closing") {
    return (
      <div className="glass-strong rise-in relative z-10 flex flex-col gap-4 p-5">
        <p className="font-display text-[16px] leading-relaxed text-text">كيف انتهت؟</p>
        <div className="flex flex-col gap-2.5">
          <button
            type="button"
            onClick={() => close("held")}
            className="pressable px-5 py-3.5 text-sm font-medium"
          >
            تماسكتُ
          </button>
          <button
            type="button"
            onClick={() => close("erupted")}
            className="pressable px-5 py-3.5 text-sm font-medium"
          >
            انفجرتُ رغم ذلك
          </button>
        </div>
      </div>
    );
  }

  if (stage === "done") {
    return (
      <div className="glass-gold rise-in relative z-10 flex flex-col gap-3 p-5 text-center">
        <p className="font-display text-[17px] leading-loose text-text">
          {held
            ? "هذي مرة اقتُرب فيها من الحافة ولم يقع الانفجار. سُجّلت — وهي التي نعدّها."
            : "حدث. ولا يُلغي هذا المحاولة — فتح هذي الشاشة أصلاً يعني شيئاً."}
        </p>
        <button type="button" onClick={reset} className="pressable px-5 py-2.5 text-sm font-medium">
          تمام
        </button>
      </div>
    );
  }

  return (
    <div className="rise-in flex flex-col gap-2">
      <button
        type="button"
        onClick={open}
        className="glass-soft relative z-10 flex w-full items-center gap-3 !rounded-2xl px-4 py-3.5 text-start transition-transform active:scale-[0.97]"
        style={{ touchAction: "manipulation" }}
      >
        <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-bg-deep/30 text-gold-strong">
          <LifeBuoy size={18} strokeWidth={2.2} />
        </span>
        <span className="flex-1">
          <span className="block text-[14px] font-semibold text-text">على وشك الانفجار؟</span>
          <span className="block text-[12px] text-text-muted">اضغطوا، أنا معكم في ثانية</span>
        </span>
        <ChevronLeft size={16} className="shrink-0 text-text-muted" />
      </button>

      {/* باب الاعتراف — آدم يحسن الردّ عليه فعلاً، وينقصه أن يُدعى إليه */}
      <button
        type="button"
        onClick={() => {
          haptic("light");
          trackClick("panic_confession", "home");
          returnToAdamChat();
        }}
        className="px-4 py-3 text-center text-xs font-medium text-text-muted"
      >
        انفجرتُ اليوم — أريد أن أحكي
      </button>
    </div>
  );
}
