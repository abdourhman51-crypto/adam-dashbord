"use client";

import { useEffect, useRef, useState, type CSSProperties } from "react";
import { Share2, X } from "lucide-react";
import { drawAchievementCard, canvasToBlob, shareOrDownload } from "@/lib/shareCard";
import { haptic } from "@/lib/telegram/client";

const PARTICLE_COLORS = ["#e3b23c", "#f0c96a", "#7ab890"];

function Confetti() {
  const particles = useRef(
    Array.from({ length: 24 }, () => ({
      angle: Math.random() * 360,
      dist: 120 + Math.random() * 160,
      delay: Math.random() * 150,
      size: 6 + Math.random() * 8,
      color: PARTICLE_COLORS[Math.floor(Math.random() * PARTICLE_COLORS.length)],
    }))
  ).current;

  return (
    <div className="pointer-events-none absolute inset-0 overflow-hidden" aria-hidden="true">
      {particles.map((p, i) => (
        <span
          key={i}
          className="confetti-particle rounded-sm"
          style={
            {
              width: p.size,
              height: p.size,
              background: p.color,
              animationDelay: `${p.delay}ms`,
              "--confetti-rot": `${p.angle}deg`,
              "--confetti-dist": `-${p.dist}px`,
              transform: `translate(-50%, -50%) rotate(${p.angle}deg)`,
            } as CSSProperties
          }
        />
      ))}
    </div>
  );
}

export function AchievementCelebration({
  streak,
  childName,
  onClose,
}: {
  streak: number;
  childName: string;
  onClose: () => void;
}) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [sharing, setSharing] = useState(false);

  useEffect(() => {
    haptic("medium");
    if (canvasRef.current) {
      drawAchievementCard(canvasRef.current, { childName, streak });
    }
  }, [childName, streak]);

  async function handleShare() {
    if (!canvasRef.current) return;
    setSharing(true);
    const blob = await canvasToBlob(canvasRef.current);
    if (blob) await shareOrDownload(blob, `adam-${streak}-nights.png`);
    setSharing(false);
  }

  return (
    <div
      className="fixed inset-0 z-50 flex flex-col items-center justify-center gap-6 bg-bg-deep/95 px-6 backdrop-blur-sm"
      role="dialog"
      aria-modal="true"
    >
      <Confetti />

      <button
        type="button"
        onClick={onClose}
        className="pressable absolute left-5 top-[max(env(safe-area-inset-top),20px)] flex h-10 w-10 items-center justify-center !rounded-full border-0"
        aria-label="إغلاق"
      >
        <X size={20} />
      </button>

      <div className="celebration-pop text-center">
        <p className="font-display text-[22px] text-gold-strong">وصلتوا محطة جديدة!</p>
        <p className="mt-1 text-sm text-text-muted">{streak} ليلة متتالية حكيتوا لي فيها كيف مرّت</p>
      </div>

      <div className="celebration-pop relative w-full max-w-[280px] overflow-hidden !rounded-[24px] border border-glass-border-gold shadow-[var(--shadow-gold-glow)]">
        <canvas ref={canvasRef} className="block w-full" />
      </div>

      <button
        type="button"
        onClick={handleShare}
        disabled={sharing}
        className="pressable-gold flex w-full max-w-[280px] items-center justify-center gap-2 px-5 py-3 text-sm font-semibold disabled:opacity-60"
      >
        <Share2 size={16} strokeWidth={2.2} />
        <span>{sharing ? "جاري التجهيز…" : "شاركوا هذي البطاقة"}</span>
      </button>
    </div>
  );
}
