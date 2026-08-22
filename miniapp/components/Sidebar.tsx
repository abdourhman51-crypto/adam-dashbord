"use client";

import { useState } from "react";
import { Menu, X, ChevronLeft, ArrowRight, Sparkles, Cog, Gem, Users, type LucideIcon } from "lucide-react";
import { GlassCard } from "@/components/GlassCard";
import { TreeLoader } from "@/components/TreeLoader";
import { IconText } from "@/lib/emojiIcons";
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

const ENTRIES: { key: string; label: string; icon: LucideIcon }[] = [
  { key: "menu_faq", label: "تعرّف على آدم", icon: Sparkles },
  { key: "menu_how", label: "كيف يشتغل؟", icon: Cog },
  { key: "menu_why", label: "وما الذي يميّزه؟", icon: Gem },
  { key: "menu_pricing_diff", label: "المجاني مقابل المرافقة الكاملة", icon: Gem },
  { key: "menu_family", label: "عائلة آدم", icon: Users },
];

export function Sidebar() {
  const [menuOpen, setMenuOpen] = useState(false);
  const [activeKey, setActiveKey] = useState<string | null>(null);
  const [moment, setMoment] = useState<MenuMoment | null>(null);
  const [loading, setLoading] = useState(false);
  const chatHref = getChatLink();

  async function loadKey(key: string) {
    setMenuOpen(false);
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

  function backToList() {
    setActiveKey(null);
    setMoment(null);
    setMenuOpen(true);
  }

  function closeAll() {
    setMenuOpen(false);
    setActiveKey(null);
    setMoment(null);
  }

  return (
    <>
      <button
        type="button"
        onClick={() => setMenuOpen(true)}
        className="pressable fixed start-4 top-16 z-20 flex h-11 w-11 items-center justify-center !rounded-2xl border-[1.5px] border-emerald-strong"
        aria-label="القائمة"
      >
        <Menu size={19} strokeWidth={2.3} />
      </button>

      {/* قائمة العناوين — درج جانبي */}
      {menuOpen && (
        <div className="fixed inset-0 z-40 flex" role="dialog" aria-modal="true">
          <div className="absolute inset-0 bg-bg-deep/80 backdrop-blur-sm" onClick={closeAll} aria-hidden="true" />
          <div className="glass-strong relative z-10 flex h-full w-[82%] max-w-sm flex-col gap-3 overflow-y-auto !rounded-none border-e border-glass-border p-5 pt-[max(env(safe-area-inset-top),20px)]">
            <div className="mb-2 flex items-center justify-between">
              <p className="font-display text-[19px] text-gold-strong">قائمة آدم</p>
              <button
                type="button"
                onClick={closeAll}
                className="pressable flex h-9 w-9 items-center justify-center !rounded-full border-0"
                aria-label="إغلاق"
              >
                <X size={17} />
              </button>
            </div>
            {ENTRIES.map((e) => (
              <button
                key={e.key}
                type="button"
                onClick={() => loadKey(e.key)}
                className="pressable flex items-center justify-between !rounded-2xl px-4 py-3.5 text-sm font-medium"
              >
                <span className="flex items-center gap-2.5">
                  <e.icon size={17} className="text-gold-strong" strokeWidth={2.2} />
                  {e.label}
                </span>
                <ChevronLeft size={16} />
              </button>
            ))}
          </div>
        </div>
      )}

      {/* شاشة كاملة لمحتوى العنصر — منصة، لا نافذة صغيرة */}
      {activeKey && (
        <div className="fixed inset-0 z-50 overflow-y-auto bg-bg-deep">
          <div
            className="absolute inset-0"
            style={{
              background:
                "radial-gradient(120% 60% at 50% -10%, var(--bg-glow) 0%, transparent 60%), linear-gradient(180deg, var(--bg-mid) 0%, var(--bg-deep) 55%, #081009 100%)",
            }}
          />
          <div className="relative z-10 mx-auto flex min-h-full max-w-md flex-col gap-5 px-4 pb-16 pt-[max(env(safe-area-inset-top),20px)]">
            <div className="flex items-center justify-between">
              <button
                type="button"
                onClick={backToList}
                className="pressable flex h-10 w-10 items-center justify-center !rounded-full border-0"
                aria-label="رجوع للقائمة"
              >
                <ArrowRight size={18} />
              </button>
              <button
                type="button"
                onClick={closeAll}
                className="pressable flex h-10 w-10 items-center justify-center !rounded-full border-0"
                aria-label="إغلاق"
              >
                <X size={18} />
              </button>
            </div>

            {loading ? (
              <div className="flex flex-1 items-center justify-center pt-16">
                <TreeLoader size="lg" />
              </div>
            ) : moment ? (
              <>
                <GlassCard variant="strong" className="whitespace-pre-line text-[15px] leading-loose text-text">
                  <IconText text={moment.body} />
                </GlassCard>
                {moment.buttons.length > 0 && (
                  <div className="flex flex-col gap-2.5">
                    {moment.buttons.map((b) => (
                      <button
                        key={b.label}
                        type="button"
                        onClick={() => onButtonPress(b)}
                        className="pressable px-4 py-3.5 text-sm font-medium"
                      >
                        <IconText text={b.label} />
                      </button>
                    ))}
                  </div>
                )}
              </>
            ) : (
              <p className="pt-16 text-center text-sm text-text-muted">تعذّر تحميل هذي الشاشة الآن.</p>
            )}
          </div>
        </div>
      )}
    </>
  );
}
