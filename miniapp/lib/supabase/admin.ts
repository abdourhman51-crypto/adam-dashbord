import { createClient } from "@supabase/supabase-js";

/**
 * SERVICE_ROLE client. Bypasses RLS entirely. سيرفر فقط — لا يُستورد أبداً
 * من أي ملف "use client"، ولا يُمرَّر مفتاحه للعميل بأي شكل.
 */
function buildAdminClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!url || !serviceKey) {
    throw new Error(
      "متغيرات Supabase غير مكتملة: تأكد من NEXT_PUBLIC_SUPABASE_URL و SUPABASE_SERVICE_ROLE_KEY"
    );
  }

  return createClient(url, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}

let cached: ReturnType<typeof buildAdminClient> | null = null;

export function supabaseAdmin() {
  if (!cached) cached = buildAdminClient();
  return cached;
}
