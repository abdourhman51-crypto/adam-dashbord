"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Sparkles, Compass, Sprout, MessageCircle } from "lucide-react";
import { returnToAdamChat } from "@/lib/upsell";
import { haptic } from "@/lib/telegram/client";

const TABS_BEFORE = [
  { href: "/", label: "الآن", icon: Sparkles },
  { href: "/insights", label: "طريقتي", icon: Compass },
] as const;

const TABS_AFTER = [{ href: "/child", label: "طفلي", icon: Sprout }] as const;

function TabLink({ href, label, icon: Icon, active }: { href: string; label: string; icon: typeof Sparkles; active: boolean }) {
  return (
    <Link
      href={href}
      data-active={active}
      className="pressable flex flex-1 flex-col items-center gap-1 border-0 bg-transparent px-2 py-2 text-center data-[active=true]:border"
      aria-current={active ? "page" : undefined}
    >
      <Icon size={22} strokeWidth={2} />
      <span className="text-[11px] font-medium leading-none">{label}</span>
    </Link>
  );
}

export function BottomNav() {
  const pathname = usePathname();

  return (
    <nav
      className="fixed inset-x-0 bottom-0 z-20 px-4 pb-[max(env(safe-area-inset-bottom),16px)] pt-2"
      aria-label="التنقل بين شاشات آدم"
    >
      <div className="glass-strong relative mx-auto flex max-w-md items-center justify-between gap-1 !rounded-full p-2">
        {TABS_BEFORE.map((t) => (
          <TabLink key={t.href} {...t} active={pathname === t.href} />
        ))}

        <button
          type="button"
          onClick={() => {
            haptic("light");
            returnToAdamChat();
          }}
          className="pressable flex flex-1 flex-col items-center gap-1 border-0 bg-transparent px-2 py-2 text-center"
          aria-label="تحدّث مع آدم"
        >
          <MessageCircle size={22} strokeWidth={2} />
          <span className="text-[11px] font-medium leading-none">آدم</span>
        </button>

        {TABS_AFTER.map((t) => (
          <TabLink key={t.href} {...t} active={pathname === t.href} />
        ))}
      </div>
    </nav>
  );
}
