"use client";

import { CountUpNumber } from "@/components/CountUpNumber";

/** حلقة نسبة مئوية ذهبية — تتحرك لقيمتها الحقيقية لمّا trigger تصير true. */
export function ProgressRing({
  percent,
  trigger,
  size = 96,
  label,
}: {
  percent: number;
  trigger: boolean;
  size?: number;
  label: string;
}) {
  const stroke = 8;
  const radius = (size - stroke) / 2;
  const circumference = 2 * Math.PI * radius;
  const offset = circumference - (trigger ? percent / 100 : 0) * circumference;

  return (
    <div className="flex flex-col items-center gap-2">
      <div className="relative" style={{ width: size, height: size }}>
        <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} className="-rotate-90">
          <circle
            cx={size / 2}
            cy={size / 2}
            r={radius}
            stroke="var(--glass-bg-strong)"
            strokeWidth={stroke}
            fill="none"
          />
          <circle
            cx={size / 2}
            cy={size / 2}
            r={radius}
            stroke="url(#adam-ring-gradient)"
            strokeWidth={stroke}
            strokeLinecap="round"
            fill="none"
            strokeDasharray={circumference}
            strokeDashoffset={offset}
            style={{ transition: "stroke-dashoffset 900ms cubic-bezier(0.16,1,0.3,1)" }}
          />
          <defs>
            <linearGradient id="adam-ring-gradient" x1="0" y1="0" x2="1" y2="1">
              <stop offset="0%" stopColor="#e3b23c" />
              <stop offset="100%" stopColor="#f0c96a" />
            </linearGradient>
          </defs>
        </svg>
        <div className="absolute inset-0 flex items-center justify-center">
          <span className="font-display text-lg text-gold-strong">
            <CountUpNumber value={percent} trigger={trigger} />٪
          </span>
        </div>
      </div>
      <p className="text-xs text-text-muted">{label}</p>
    </div>
  );
}
