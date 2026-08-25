"use client";

import { useEffect } from "react";
import { GlassCard } from "@/components/GlassCard";

/**
 * حاجز أخطاء React لكل الشاشات: بلا هذا، أي استثناء غير متوقع بالعميل يعرض
 * شاشة تيليغرام الفارغة الافتراضية بلا أي تفسير — تبدو "معطّلة" بلا أي دليل
 * لتشخيصها. هنا نعرض رسالة الخطأ الفعلية وزر إعادة محاولة بدل شاشة فارغة.
 */
export default function ErrorBoundary({ error, reset }: { error: Error & { digest?: string }; reset: () => void }) {
  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <div className="flex min-h-dvh flex-col items-center justify-center gap-4 px-6 pb-32 pt-[calc(env(safe-area-inset-top)+84px)] text-center">
      <GlassCard>
        <p className="font-display text-lg text-text">حدث خطأ غير متوقع</p>
        <p className="mt-2 whitespace-pre-line break-words text-sm leading-relaxed text-text-muted">
          {error.message || "بلا تفاصيل إضافية."}
        </p>
        <button type="button" onClick={reset} className="pressable-gold mt-4 px-5 py-2.5 text-sm font-semibold">
          حاول مرة أخرى
        </button>
      </GlassCard>
    </div>
  );
}
