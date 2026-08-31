import { openLink } from "@/lib/telegram/client";

/**
 * مثبّت في الكود عمداً، لا عبر متغيّر بيئة: اسم البوت الحقيقي الوحيد هو
 * @adam_os_brain_bot. اعتماد متغيّر بيئة هنا هو بالضبط ما سبّب المشكلة —
 * قيمة محلية خاطئة (AdamCompanionBot) كانت كافية لتوجيه كل أزرار "تحدّث
 * مع آدم" لبوت لا وجود له.
 */
const BOT_USERNAME = "adam_os_brain_bot";

/** ينقل الوالد فعلياً إلى محادثته مع بوت آدم — openLink يتولّى إغلاق التطبيق المصغّر بعدها. */
export function returnToAdamChat() {
  openLink(`https://t.me/${BOT_USERNAME}`);
}
