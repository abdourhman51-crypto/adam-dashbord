/**
 * رابط دعوة "المرافقة الكاملة" — يرجّع الوالد لمحادثة بوت آدم على تيليغرام
 * (start payload "journey" يوجّه البوت لمسار الاتفاق على الرحلة).
 * بلا أي عدّاد وقت أو إلحاح — الفضول من المحتوى المطموس نفسه، لا من ضغط زمني.
 */
export function getUpgradeDeepLink(): string | null {
  const username = process.env.NEXT_PUBLIC_TELEGRAM_BOT_USERNAME;
  if (!username) return null;
  return `https://t.me/${username}?start=journey`;
}
