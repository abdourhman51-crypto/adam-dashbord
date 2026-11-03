import type { Metadata } from "next";
import { IBM_Plex_Sans_Arabic } from "next/font/google";
import Nav from "@/components/Nav";
import "./globals.css";

const font = IBM_Plex_Sans_Arabic({ subsets: ["arabic", "latin"], weight: ["400", "500", "600", "700"], display: "swap" });

export const metadata: Metadata = {
  title: { default: "لوحة آدم", template: "%s · لوحة آدم" },
  description: "مؤشرات نور والموقع: الرسائل، المراحل، العروض، المدفوعات",
  robots: { index: false, follow: false },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ar" dir="rtl">
      <body className={`${font.className} antialiased`}>
        <header className="sticky top-0 z-10 border-b border-[var(--border)] bg-[var(--bg)]/95 backdrop-blur">
          <div className="mx-auto flex max-w-6xl flex-wrap items-center justify-between gap-3 px-4 py-3">
            <div className="font-bold">لوحة آدم <span className="font-normal text-[var(--muted)]">· نور والموقع</span></div>
            <Nav />
          </div>
        </header>
        <main className="mx-auto max-w-6xl px-4 py-6">{children}</main>
      </body>
    </html>
  );
}
