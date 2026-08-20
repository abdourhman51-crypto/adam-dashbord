"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Flame, Trophy, Heart, Sprout } from "lucide-react";

const TABS = [
  { href: "/timeline", label: "الخط الصادق", icon: Flame },
  { href: "/wall", label: "جدار الإنجاز", icon: Trophy },
  { href: "/child", label: "طفلي", icon: Heart },
  { href: "/journey", label: "رحلتي", icon: Sprout },
] as const;

export function BottomNav() {
  const pathname = usePathname();

  return (
    <nav
      className="fixed inset-x-0 bottom-0 z-20 px-4 pb-[max(env(safe-area-inset-bottom),16px)] pt-2"
      aria-label="التنقل بين شاشات آدم"
    >
      <div className="glass-strong mx-auto flex max-w-md items-center justify-between gap-1 !rounded-full p-2">
        {TABS.map(({ href, label, icon: Icon }) => {
          const active = pathname === href;
          return (
            <Link
              key={href}
              href={href}
              data-active={active}
              className="pressable flex flex-1 flex-col items-center gap-1 border-0 bg-transparent px-2 py-2 text-center data-[active=true]:border"
              aria-current={active ? "page" : undefined}
            >
              <Icon size={22} strokeWidth={2} />
              <span className="text-[11px] font-medium leading-none">{label}</span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
