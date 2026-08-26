import type { CSSProperties } from "react";

/**
 * تجزئة ثابتة بسيطة — تُستعمل لتوليد مدة/تأخير التمايل بشكل يبدو عشوائياً
 * لكنه ثابت لكل ورقة (نفس الفهرس = نفس الحركة دائماً)، بدل رياح موحّدة تتحرك
 * فيها كل الأوراق بنفس الإيقاع في نفس اللحظة.
 */
function hash(n: number): number {
  const x = Math.sin(n * 12.9898) * 43758.5453;
  return x - Math.floor(x);
}

export function GoldLeaf({
  left,
  top,
  width,
  rotateDeg,
  grow = false,
  delayMs = 0,
  index = 0,
}: {
  left: string;
  top: string;
  width: number;
  rotateDeg: number;
  grow?: boolean;
  delayMs?: number;
  index?: number;
}) {
  const swayDuration = 3.2 + hash(index * 4.4 + 5) * 2.4;
  const swayDelay = hash(index * 6.6 + 9) * -swayDuration;

  const outerStyle: CSSProperties = {
    left,
    top,
    width,
    transform: `rotate(${rotateDeg}deg)`,
  };

  const swayStyle: CSSProperties = {
    animationDuration: `${swayDuration}s`,
    animationDelay: grow ? `${delayMs}ms` : `${swayDelay}s`,
  };

  return (
    <span className="absolute" style={outerStyle} aria-hidden="true">
      <svg
        viewBox="0 0 24 28"
        className={`leaf-sway block drop-shadow-[0_0_6px_rgba(227,178,60,0.55)] ${grow ? "leaf-grow-in" : ""}`}
        style={swayStyle}
      >
        <defs>
          <linearGradient id={`leafGrad${index}`} x1="0" y1="0" x2="1" y2="1">
            <stop offset="0%" stopColor="#f4d675" />
            <stop offset="55%" stopColor="#e3b23c" />
            <stop offset="100%" stopColor="#b8860b" />
          </linearGradient>
        </defs>
        {/* شكل ورقة حقيقي: فصّان متماثلان يلتقيان بحدّ علوي وسفلي، لا نقطة دمعة مجردة */}
        <path
          d="M12 1.5C16.5 5 20 9.5 20 15c0 6.5-4.2 11-8 11.5C8.2 26 4 21.5 4 15 4 9.5 7.5 5 12 1.5Z"
          fill={`url(#leafGrad${index})`}
        />
        {/* العرق الأوسط + عروق جانبية خفيفة تكسر البقعة اللونية المسطّحة */}
        <path
          d="M12 3.5v21.5M12 10l-3 2.2M12 14l3.4 2M12 18.5l-3 2"
          stroke="#7a5410"
          strokeWidth="0.6"
          strokeLinecap="round"
          fill="none"
          opacity="0.55"
        />
      </svg>
    </span>
  );
}
