"use client";

import Link from "next/link";
import Image from "next/image";
import { usePathname } from "next/navigation";
import { NAV_ITEMS } from "./nav";

function isActive(pathname: string, href: string) {
  if (href === "/") return pathname === "/";
  return pathname === href || pathname.startsWith(`${href}/`);
}

export default function Sidebar() {
  const pathname = usePathname();
  if (pathname === "/login") return null;

  return (
    <>
      {/* سطح المكتب: عمود جانبي ثابت */}
      <aside className="sticky top-0 hidden h-dvh w-60 shrink-0 flex-col border-l border-[color:var(--border)] bg-[color:var(--surface)] md:flex">
        <div className="flex items-center gap-2.5 px-5 py-5">
          <div className="flex h-9 w-9 items-center justify-center rounded-full bg-[color:var(--primary-soft)] p-1.5">
            <Image src="/brand/tree-mark.png" alt="" width={36} height={36} className="h-full w-full object-contain" />
          </div>
          <div>
            <p className="text-sm font-bold text-[color:var(--text)]">مركز قيادة آدم</p>
            <p className="text-[11px] text-[color:var(--text-muted)]">لوحة داخلية</p>
          </div>
        </div>

        <nav className="flex flex-1 flex-col gap-1 px-3">
          {NAV_ITEMS.map(({ href, label, icon: Icon }) => {
            const active = isActive(pathname, href);
            return (
              <Link
                key={href}
                href={href}
                className={`flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition ${
                  active
                    ? "bg-[color:var(--primary-soft)] text-[color:var(--primary)]"
                    : "text-[color:var(--text-secondary)] hover:bg-[color:var(--surface-2)]"
                }`}
              >
                <Icon size={18} />
                {label}
              </Link>
            );
          })}
        </nav>
      </aside>

      {/* الهاتف: شريط تنقّل سفلي ثابت */}
      <nav
        className="fixed inset-x-0 bottom-0 flex border-t border-[color:var(--border)] bg-[color:var(--surface)] md:hidden"
        style={{ zIndex: "var(--z-sticky)" as unknown as number }}
      >
        {NAV_ITEMS.map(({ href, label, icon: Icon }) => {
          const active = isActive(pathname, href);
          return (
            <Link
              key={href}
              href={href}
              className={`flex flex-1 flex-col items-center gap-1 py-2.5 text-[10px] font-medium ${
                active ? "text-[color:var(--primary)]" : "text-[color:var(--text-muted)]"
              }`}
            >
              <Icon size={19} />
              {label}
            </Link>
          );
        })}
      </nav>
    </>
  );
}
