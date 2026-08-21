"use client";

import { useState } from "react";
import { Menu, X, ChevronLeft } from "lucide-react";
import { GlassCard } from "@/components/GlassCard";
import { fetchScreen } from "@/lib/telegram/fetcher";
import { openLink, haptic } from "@/lib/telegram/client";
import { getChatLink } from "@/lib/upsell";

interface MenuButton {
  label: string;
  cb?: string;
  url?: string;
}

interface MenuMoment {
  body: string;
  buttons: MenuButton[];
}

const ENTRIES: { key: string; label: string }[] = [
  { key: "menu_faq", label: "🌳 تعرّف على آدم" },
  { key: "menu_how", label: "⚙️ كيف يشتغل؟" },
  { key: "menu_why", label: "✨ وما الذي يميّزه؟" },
  { key: "menu_pricing_diff", label: "💎 المجاني مقابل المرافقة الكاملة" },
  { key: "menu_family", label: "🌿 عائلة آدم" },
];

export function Sidebar() {
  const [open, setOpen] = useState(false);
  const [activeKey, setActiveKey] = useState<string | null>(null);
  const [moment, setMoment] = useState<MenuMoment | null>(null);
  const [loading, setLoading] = useState(false);
  const chatHref = getChatLink();

  async function loadKey(key: string) {
    setActiveKey(key);
    setLoading(true);
    setMoment(null);
    const r = await fetchScreen<MenuMoment>(`/api/menu?key=${encodeURIComponent(key)}`);
    if (r.state === "ok") setMoment(r.data);
    setLoading(false);
  }

  function onButtonPress(b: MenuButton) {
    haptic("light");
    if (b.url) {
      openLink(b.url);
      return;
    }
    if (b.cb === "other" && chatHref) {
      openLink(chatHref);
      return;
    }
    if (b.cb && ENTRIES.some((e) => e.key === b.cb)) {
      loadKey(b.cb);
    }
  }

  function close() {
    setOpen(false);
    setActiveKey(null);
    setMoment(null);
  }

  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        className="pressable fixed start-4 top-16 z-20 flex h-9 w-9 items-center justify-center !rounded-full border-0"
        aria-label="القائمة"
      >
        <Menu size={17} strokeWidth={2.2} />
      </button>

      {open && (
        <div className="fixed inset-0 z-40 flex" role="dialog" aria-modal="true">
          <div className="absolute inset-0 bg-bg-deep/80 backdrop-blur-sm" onClick={close} aria-hidden="true" />
          <div className="glass-strong relative z-10 flex h-full w-[86%] max-w-sm flex-col gap-4 overflow-y-auto !rounded-none border-e border-glass-border p-5 pt-[max(env(safe-area-inset-top),20px)]">
            <div className="flex items-center justify-between">
              <p className="font-display text-[18px] text-gold-strong">قائمة آدم</p>
              <button
                type="button"
                onClick={close}
                className="pressable flex h-9 w-9 items-center justify-center !rounded-full border-0"
                aria-label="إغلاق"
              >
                <X size={17} />
              </button>
            </div>

            {!activeKey ? (
              <div className="flex flex-col gap-2.5">
                {ENTRIES.map((e) => (
                  <button
                    key={e.key}
                    type="button"
                    onClick={() => loadKey(e.key)}
                    className="pressable flex items-center justify-between !rounded-2xl px-4 py-3.5 text-sm font-medium"
                  >
                    <span>{e.label}</span>
                    <ChevronLeft size={16} />
                  </button>
                ))}
              </div>
            ) : (
              <div className="flex flex-1 flex-col gap-4">
                <button
                  type="button"
                  onClick={() => {
                    setActiveKey(null);
                    setMoment(null);
                  }}
                  className="flex items-center gap-1 self-start text-xs text-text-muted"
                >
                  <ChevronLeft size={14} className="rotate-180" />
                  رجوع للقائمة
                </button>

                {loading ? (
                  <div className="glow-pulse mx-auto h-10 w-10 rounded-full bg-gold-soft" />
                ) : moment ? (
                  <>
                    <GlassCard variant="strong" className="whitespace-pre-line text-sm leading-relaxed text-text">
                      {moment.body}
                    </GlassCard>
                    {moment.buttons.length > 0 && (
                      <div className="flex flex-col gap-2.5">
                        {moment.buttons.map((b) => (
                          <button
                            key={b.label}
                            type="button"
                            onClick={() => onButtonPress(b)}
                            className="pressable px-4 py-3 text-sm font-medium"
                          >
                            {b.label}
                          </button>
                        ))}
                      </div>
                    )}
                  </>
                ) : (
                  <p className="text-sm text-text-muted">تعذّر تحميل هذي الشاشة الآن.</p>
                )}
              </div>
            )}
          </div>
        </div>
      )}
    </>
  );
}
