import type { Metadata } from "next";
import { IBM_Plex_Sans_Arabic } from "next/font/google";
import "./globals.css";
import Sidebar from "@/components/layout/Sidebar";
import Header from "@/components/layout/Header";
import { getUnreadConversationCount } from "@/lib/queries/inbox";

const plexArabic = IBM_Plex_Sans_Arabic({
  subsets: ["arabic", "latin"],
  weight: ["300", "400", "500", "600", "700"],
  variable: "--font-plex-arabic",
  display: "swap",
});

export const metadata: Metadata = {
  title: {
    default: "مركز قيادة آدم",
    template: "%s · مركز قيادة آدم",
  },
  description: "لوحة التحليلات والقيادة التشغيلية لمنصة آدم للمرافقة التربوية",
  icons: { icon: "/brand/tree-mark.png" },
};

const themeInit = `
try {
  const stored = localStorage.getItem("adam-theme");
  const dark = stored ? stored === "dark" : window.matchMedia("(prefers-color-scheme: dark)").matches;
  if (dark) document.documentElement.classList.add("dark");
} catch (_) {}
`;

export default async function RootLayout({ children }: { children: React.ReactNode }) {
  const unreadCount = await getUnreadConversationCount().catch(() => 0);

  return (
    <html lang="ar" dir="rtl" suppressHydrationWarning>
      <head>
        <script dangerouslySetInnerHTML={{ __html: themeInit }} />
      </head>
      <body className={`${plexArabic.variable} font-[family-name:var(--font-plex-arabic)] antialiased`}>
        <div className="flex min-h-dvh">
          <Sidebar unreadCount={unreadCount} />
          <div className="flex min-w-0 flex-1 flex-col">
            <Header />
            <main className="mx-auto w-full max-w-7xl flex-1 px-4 pb-20 pt-6 sm:px-6 md:pb-6 lg:px-8">
              {children}
            </main>
            <footer className="no-print hidden border-t px-6 py-4 text-center text-xs text-[color:var(--text-muted)] md:block">
              مركز قيادة آدم — بيانات حيّة من Supabase · جميع الأرقام من قاعدة البيانات الفعلية
            </footer>
          </div>
        </div>
      </body>
    </html>
  );
}
