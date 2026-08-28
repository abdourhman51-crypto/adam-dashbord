import type { Metadata, Viewport } from "next";
import Script from "next/script";
import "./globals.css";
import { BottomNav } from "@/components/BottomNav";
import { TopBar } from "@/components/TopBar";
import { WelcomeSplash } from "@/components/WelcomeSplash";

// Force every route to render on each request instead of being statically
// prerendered and cached at Vercel's edge. The Cache-Control: no-store header
// (next.config.ts) only tells downstream caches not to keep a response —
// it doesn't stop Next.js itself from treating this as a static/ISR page in
// the first place, which is what was actually serving a stale build to the
// production domain alias for days across multiple newer deployments.
export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: "آدم — رفيق التربية",
  description: "مساحتكم الخاصة مع آدم: ما تقدّمتم فيه فعلاً، وما يميّز طفلكم.",
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  themeColor: "#0d1a12",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ar" dir="rtl">
      <body>
        <Script src="https://telegram.org/js/telegram-web-app.js" strategy="beforeInteractive" />
        <TopBar />
        {children}
        <BottomNav />
        <WelcomeSplash />
      </body>
    </html>
  );
}
