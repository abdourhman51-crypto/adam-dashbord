"use client";

import { useEffect, useState } from "react";
import { Leaf } from "lucide-react";
import { getInitDataRaw } from "@/lib/telegram/client";
import { MAX_LEAVES, leafPosition } from "@/lib/treeLeaves";
import { GoldLeaf } from "@/components/GoldLeaf";
import { TreeLightbox } from "@/components/TreeLightbox";
import { formatNumber } from "@/lib/format";

const SEEN_KEY = "adam_tree_seen_calm_count";

export function LivingTree() {
  const [calmCount, setCalmCount] = useState<number | null>(null);
  const [seenCount, setSeenCount] = useState(0);
  const [open, setOpen] = useState(false);

  useEffect(() => {
    const initData = getInitDataRaw();
    if (!initData) return;
    let cancelled = false;

    const seen = Number(window.localStorage.getItem(SEEN_KEY) ?? "0");
    setSeenCount(Number.isFinite(seen) ? seen : 0);

    fetch("/api/tree", { headers: { "x-telegram-init-data": initData } })
      .then((res) => (res.ok ? res.json() : null))
      .then((data: { calmCount: number } | null) => {
        if (cancelled || !data) return;
        setCalmCount(data.calmCount);
        window.localStorage.setItem(SEEN_KEY, String(data.calmCount));
      })
      .catch(() => {});

    return () => {
      cancelled = true;
    };
  }, []);

  const visibleLeaves = Math.min(calmCount ?? 0, MAX_LEAVES);

  return (
    <>
      <button
        type="button"
        onClick={() => calmCount !== null && setOpen(true)}
        className="absolute inset-x-0 top-0 z-0 h-[420px] cursor-pointer border-0 bg-transparent p-0"
        style={{ touchAction: "manipulation" }}
        aria-label="افتحوا الشجرة لتكبيرها"
      >
        <div className="tree-backdrop" aria-hidden="true" />
        {calmCount !== null &&
          Array.from({ length: visibleLeaves }, (_, i) => {
            const p = leafPosition(i);
            const isNew = i >= seenCount;
            return (
              <GoldLeaf
                key={i}
                left={`${p.leftPct}%`}
                top={`${p.topPct * 0.9 + 4}%`}
                width={p.sizePx}
                rotateDeg={p.rotateDeg}
                grow={isNew}
                delayMs={(i - seenCount) * 90}
              />
            );
          })}
      </button>

      {calmCount !== null && (
        <button
          type="button"
          onClick={() => setOpen(true)}
          className="pressable absolute start-4 top-4 z-20 flex items-center gap-1.5 px-3 py-1.5 text-xs"
          style={{ touchAction: "manipulation" }}
          aria-label="افتحوا شجرتكم لتكبيرها"
        >
          <Leaf size={14} className="text-gold-strong" strokeWidth={2.2} />
          <span className="tabular font-medium">{formatNumber(calmCount)}</span>
        </button>
      )}

      {open && calmCount !== null && (
        <TreeLightbox leafCount={calmCount} onClose={() => setOpen(false)} />
      )}
    </>
  );
}
