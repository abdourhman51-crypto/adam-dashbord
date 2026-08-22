import type { Metadata, Viewport } from "next";
import Script from "next/script";
import "./globals.css";
import { BottomNav } from "@/components/BottomNav";
import { TopBar } from "@/components/TopBar";
import { WelcomeSplash } from "@/components/WelcomeSplash";

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
