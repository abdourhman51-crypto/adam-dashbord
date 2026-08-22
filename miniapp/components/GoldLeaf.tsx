import type { CSSProperties } from "react";

export function GoldLeaf({
  left,
  top,
  width,
  rotateDeg,
  grow = false,
  delayMs = 0,
}: {
  left: string;
  top: string;
  width: number;
  rotateDeg: number;
  grow?: boolean;
  delayMs?: number;
}) {
  const outerStyle: CSSProperties = {
    left,
    top,
    width,
    transform: `rotate(${rotateDeg}deg)`,
  };

  return (
    <span className="absolute" style={outerStyle} aria-hidden="true">
      <svg
        viewBox="0 0 24 24"
        className={`block drop-shadow-[0_0_6px_rgba(227,178,60,0.55)] ${grow ? "leaf-grow-in" : ""}`}
        style={grow ? { animationDelay: `${delayMs}ms` } : undefined}
      >
        <path d="M12 2c5 3 8 7 8 11a8 8 0 0 1-16 0c0-4 3-8 8-11Z" fill="#e3b23c" />
      </svg>
    </span>
  );
}
