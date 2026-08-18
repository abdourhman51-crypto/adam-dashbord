import { createClient } from "@supabase/supabase-js";

/**
 * SERVICE_ROLE client. Bypasses RLS entirely.
 * Never import this file from anything marked "use client" — verified manually
 * (grep) since the `server-only` package isn't available in this environment.
 */
function buildAdminClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!url || !serviceKey) {
    throw new Error(
      "متغيرات Supabase غير مكتملة: تأكد من NEXT_PUBLIC_SUPABASE_URL و SUPABASE_SERVICE_ROLE_KEY في .env.local"
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

export function hasServiceRole() {
  return Boolean(process.env.SUPABASE_SERVICE_ROLE_KEY);
}

export const TEST_PLATFORM_USER_IDS = ["7377091520", "8074049810"] as const;
