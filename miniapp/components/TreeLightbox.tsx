"use client";

import Image from "next/image";
import { X } from "lucide-react";
import { usePinchZoom } from "@/components/usePinchZoom";
import { MAX_LEAVES, leafPosition } from "@/lib/treeLeaves";
import { GoldLeaf } from "@/components/GoldLeaf";

export function TreeLightbox({ leafCount, onClose }: { leafCount: number; onClose: () => void }) {
  const { scale, pos, onPointerDown, onPointerMove, onPointerUp, onPointerCancel, onDoubleClick, reset } =
    usePinchZoom();
  const visibleLeaves = Math.min(leafCount, MAX_LEAVES);

  return (
    <div
      className="fixed inset-0 z-50 flex flex-col bg-bg-deep/95 backdrop-blur-sm"
      role="dialog"
      aria-modal="true"
      aria-label="شجرة آدم — كبّروها وحرّكوها"
    >
      <div className="flex items-start justify-between gap-3 px-5 pt-[max(env(safe-area-inset-top),20px)]">
        <div>
          <p className="text-sm font-medium text-text">كل ورقة ذهبية = ليلة اخترتم فيها الهدوء مع طفلكم</p>
          <p className="mt-1 text-xs text-text-muted">مرّروا إصبعين لتكبير الشجرة، واسحبوا لتحريكها</p>
        </div>
        <button
          type="button"
          onClick={onClose}
          className="pressable flex h-10 w-10 items-center justify-center !rounded-full border-0"
          aria-label="إغلاق"
        >
          <X size={20} />
        </button>
      </div>

      <div
        className="relative flex-1 touch-none overflow-hidden"
        onPointerDown={onPointerDown}
        onPointerMove={onPointerMove}
        onPointerUp={onPointerUp}
        onPointerCancel={onPointerCancel}
        onDoubleClick={onDoubleClick}
      >
        <div
          className="absolute inset-0 flex items-center justify-center"
          style={{
            transform: `translate(${pos.x}px, ${pos.y}px) scale(${scale})`,
            transition: scale === 1 && pos.x === 0 && pos.y === 0 ? "transform 200ms ease-out" : undefined,
          }}
        >
          <div className="relative h-[70vh] w-[90vw] max-w-md">
            <Image src="/brand/tree.png" alt="شجرة آدم" fill className="object-contain" priority />
            {Array.from({ length: visibleLeaves }, (_, i) => {
              const p = leafPosition(i);
              return (
                <GoldLeaf
                  key={i}
                  left={`${p.leftPct}%`}
                  top={`${p.topPct}%`}
                  width={p.sizePx * 1.6}
                  rotateDeg={p.rotateDeg}
                />
              );
            })}
          </div>
        </div>
      </div>

      <button
        type="button"
        onClick={reset}
        className="pressable mx-auto mb-[max(env(safe-area-inset-bottom),20px)] px-6 py-2 text-sm"
      >
        إعادة الضبط
      </button>
    </div>
  );
}
