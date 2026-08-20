import Image from "next/image";

/**
 * جملة واحدة بصوت آدم أعلى كل شاشة: توضح لأجل شنو الشاشة وكيف تُقرأ،
 * قبل أي محتوى — بافتراض أن الوالد يفتحها أول مرة. إلزامية بكل شاشة.
 */
export function AdamIntro({ text }: { text: string }) {
  return (
    <div className="relative z-10 flex items-start gap-3 px-1">
      <div
        className="glass-gold flex h-14 w-14 shrink-0 items-center justify-center overflow-hidden !rounded-full p-0"
        aria-hidden="true"
      >
        <Image
          src="/brand/adam.png"
          alt=""
          width={112}
          height={112}
          className="h-full w-full object-cover object-top"
          priority
        />
      </div>
      <p className="font-display pt-2 text-[17px] leading-relaxed text-text-secondary">{text}</p>
    </div>
  );
}
