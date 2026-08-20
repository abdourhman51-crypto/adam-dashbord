import { createHmac, timingSafeEqual } from "node:crypto";

/**
 * التحقق من initData وفق توثيق Telegram Mini Apps الرسمي:
 * https://core.telegram.org/bots/webapps#validating-data-received-via-the-mini-app
 *
 * secret_key = HMAC_SHA256(key="WebAppData", data=BOT_TOKEN)
 * hash_محسوب = HMAC_SHA256(key=secret_key, data=data_check_string)
 *
 * data_check_string = كل الحقول (عدا hash) مرتّبة أبجدياً حسب المفتاح،
 * بصيغة "key=value" مفصولة بسطر جديد.
 *
 * أي initData بلا توقيع صحيح، أو أقدم من النافذة المسموحة، يُرفض بالكامل —
 * بلا استعلام واحد لقاعدة البيانات.
 */

const MAX_AUTH_AGE_SECONDS = 24 * 60 * 60; // 24 ساعة

export interface VerifiedTelegramUser {
  id: number;
  first_name?: string;
  last_name?: string;
  username?: string;
  language_code?: string;
}

export type VerifyResult =
  | { ok: true; user: VerifiedTelegramUser; authDate: number }
  | { ok: false; reason: string };

function buildDataCheckString(params: URLSearchParams): string {
  const pairs: string[] = [];
  for (const key of Array.from(params.keys()).sort()) {
    if (key === "hash") continue;
    pairs.push(`${key}=${params.get(key)}`);
  }
  return pairs.join("\n");
}

export function verifyInitData(raw: string | null | undefined): VerifyResult {
  const botToken = process.env.TELEGRAM_BOT_TOKEN;
  if (!botToken) {
    return { ok: false, reason: "TELEGRAM_BOT_TOKEN غير مضبوط على السيرفر" };
  }
  if (!raw || raw.length === 0 || raw.length > 8192) {
    return { ok: false, reason: "initData مفقود أو غير صالح" };
  }

  let params: URLSearchParams;
  try {
    params = new URLSearchParams(raw);
  } catch {
    return { ok: false, reason: "تعذّر تحليل initData" };
  }

  const receivedHash = params.get("hash");
  if (!receivedHash || !/^[0-9a-f]{64}$/i.test(receivedHash)) {
    return { ok: false, reason: "hash مفقود أو بصيغة غير صالحة" };
  }

  const dataCheckString = buildDataCheckString(params);
  const secretKey = createHmac("sha256", "WebAppData").update(botToken).digest();
  const computedHash = createHmac("sha256", secretKey).update(dataCheckString).digest("hex");

  const received = Buffer.from(receivedHash, "hex");
  const computed = Buffer.from(computedHash, "hex");
  if (received.length !== computed.length || !timingSafeEqual(received, computed)) {
    return { ok: false, reason: "توقيع initData غير مطابق" };
  }

  const authDateRaw = params.get("auth_date");
  const authDate = authDateRaw ? Number(authDateRaw) : NaN;
  if (!Number.isFinite(authDate)) {
    return { ok: false, reason: "auth_date مفقود" };
  }
  const ageSeconds = Math.floor(Date.now() / 1000) - authDate;
  if (ageSeconds < 0 || ageSeconds > MAX_AUTH_AGE_SECONDS) {
    return { ok: false, reason: "initData منتهي الصلاحية" };
  }

  const userRaw = params.get("user");
  if (!userRaw) {
    return { ok: false, reason: "حقل user مفقود" };
  }
  let user: VerifiedTelegramUser;
  try {
    const parsed = JSON.parse(userRaw);
    if (typeof parsed.id !== "number") {
      return { ok: false, reason: "user.id مفقود أو غير رقمي" };
    }
    user = parsed;
  } catch {
    return { ok: false, reason: "تعذّر تحليل حقل user" };
  }

  return { ok: true, user, authDate };
}
