"use client";

import { useEffect, useState } from "react";
import Image from "next/image";
import { getInitDataRaw } from "@/lib/telegram/client";
import { TreeLightbox } from "@/components/TreeLightbox";
import { formatNumber } from "@/lib/format";

const SEEN_KEY = "adam_tree_seen_calm_count";

/**
 * الشجرة كشعار آدم — علامة صغيرة واضحة كاملة الوضوح (لا خلفية خافتة)، وهي نفسها
 * زر فتح الشجرة الحية (الأوراق الذهبية والتكبير) داخل TreeLightbox.
 */
export function LivingTree() {
  const [calmCount, setCalmCount] = useState<number | null>(null);
  const [open, setOpen] = useState(false);

  useEffect(() => {
    const initData = getInitDataRaw();
    if (!initData) return;
    let cancelled = false;

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

  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        className="pressable fixed start-4 top-4 z-20 flex h-12 w-12 items-center justify-center !rounded-2xl border-[1.5px] border-gold p-0"
        style={{ touchAction: "manipulation" }}
        aria-label="شجرة آدم — افتحوها لتكبيرها"
      >
        <Image src="/brand/tree.png" alt="آدم" width={40} height={40} className="h-8 w-8 object-contain" priority />
        {calmCount !== null && calmCount > 0 && (
          <span className="glass-gold absolute -end-1.5 -top-1.5 flex h-5 min-w-5 items-center justify-center rounded-full px-1 text-[10px] font-bold text-gold-strong">
            <span className="tabular">{formatNumber(calmCount)}</span>
          </span>
        )}
      </button>

      {open && <TreeLightbox leafCount={calmCount ?? 0} onClose={() => setOpen(false)} />}
    </>
  );
}
