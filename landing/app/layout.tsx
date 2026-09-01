import type { Metadata, Viewport } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "آدم — مرافق أبوّة يومي",
  description: "ما تعيشونه كل ليلة مع طفلكم لن يمرّ دون أن يُرى، ولن يضيع دون أن يُبنى عليه. احكوا لآدم سطرًا عن يومكم، ويردّ بخطوة صغيرة تناسب هذه الليلة بالذات.",
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
      <body>{children}</body>
    </html>
  );
}
