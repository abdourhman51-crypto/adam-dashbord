"use client";

import { useEffect, useState } from "react";
import { usePathname } from "next/navigation";
import { Moon, Sun, LogOut } from "lucide-react";
import { logoutAction } from "@/lib/actions/auth-actions";
import { NAV_ITEMS } from "./nav";

export default function Header() {
  const pathname = usePathname();
  const [dark, setDark] = useState(false);

  useEffect(() => {
    setDark(document.documentElement.classList.contains("dark"));
  }, []);

  if (pathname === "/login") return null;

  function toggleTheme() {
    const next = !dark;
    setDark(next);
    document.documentElement.classList.toggle("dark", next);
    try {
      localStorage.setItem("adam-theme", next ? "dark" : "light");
    } catch {}
  }

  const current = NAV_ITEMS.find((n) => (n.href === "/" ? pathname === "/" : pathname.startsWith(n.href)));

  return (
    <header
      className="app-header sticky top-0 flex items-center justify-between border-b border-[color:var(--border)] bg-[color:var(--surface)]/90 px-4 py-3.5 backdrop-blur sm:px-6 lg:px-8"
      style={{ zIndex: "var(--z-sticky)" as unknown as number }}
    >
      <h1 className="text-sm font-semibold text-[color:var(--text)] md:text-base">
        {current?.label ?? "مركز قيادة آدم"}
      </h1>

      <div className="flex items-center gap-1.5">
        <button
          onClick={toggleTheme}
          aria-label="تبديل الوضع الليلي"
          className="flex h-9 w-9 items-center justify-center rounded-lg text-[color:var(--text-secondary)] transition hover:bg-[color:var(--surface-2)]"
        >
          {dark ? <Sun size={17} /> : <Moon size={17} />}
        </button>
        <form action={logoutAction}>
          <button
            type="submit"
            aria-label="تسجيل الخروج"
            className="flex h-9 w-9 items-center justify-center rounded-lg text-[color:var(--text-secondary)] transition hover:bg-[color:var(--error-soft)] hover:text-[color:var(--error)]"
          >
            <LogOut size={17} />
          </button>
        </form>
      </div>
    </header>
  );
}
