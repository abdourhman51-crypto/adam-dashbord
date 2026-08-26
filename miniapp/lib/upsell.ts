import { getWebApp } from "@/lib/telegram/client";

/**
 * رابط احتياطي فقط لمعاينة خارج تيليغرام (حيث لا وجود لـ WebApp.close). داخل
 * تيليغرام فعلياً لا حاجة له إطلاقاً — انظر returnToAdamChat أدناه.
 */
function getChatLinkFallback(): string | null {
  const username = process.env.NEXT_PUBLIC_TELEGRAM_BOT_USERNAME || "adam_os_brain_bot";
  return `https://t.me/${username}`;
}

/**
 * يرجّع الوالد لمحادثته الفعلية مع بوت آدم على تيليغرام. التطبيق المصغّر
 * دائماً يُفتح من داخل تلك المحادثة بالذات، فأقرب وأصح طريق هو ببساطة إغلاقه
 * (WebApp.close) — يرجع تيليغرام تلقائياً لنفس المحادثة، بلا أي حاجة لمعرفة
 * اسم مستخدم البوت أو بناء رابط قد يكون خاطئاً.
 */
export function returnToAdamChat() {
  const wa = getWebApp();
  if (wa?.close) {
    wa.close();
    return;
  }
  const href = getChatLinkFallback();
  if (href && typeof window !== "undefined") {
    window.open(href, "_blank", "noopener,noreferrer");
  }
}
