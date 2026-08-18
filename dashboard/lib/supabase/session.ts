import { createClient } from "@supabase/supabase-js";

/**
 * Session handling without @supabase/ssr (unavailable in this environment —
 * no new npm packages could be installed). Built directly on @supabase/supabase-js:
 * the login Server Action calls signInWithPassword and stores the resulting
 * access/refresh tokens in httpOnly cookies; middleware.ts verifies the access
 * token against Supabase Auth on every request (and transparently refreshes it
 * when expired), which is what actually enforces the login requirement — the
 * cookies alone are inert without that server-side check.
 */

export const ACCESS_COOKIE = "adam-access-token";
export const REFRESH_COOKIE = "adam-refresh-token";

function anonClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !anonKey) {
    throw new Error("NEXT_PUBLIC_SUPABASE_URL أو NEXT_PUBLIC_SUPABASE_ANON_KEY غير مضبوطة");
  }
  return createClient(url, anonKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}

export async function signInWithPassword(email: string, password: string) {
  return anonClient().auth.signInWithPassword({ email, password });
}

export async function verifyAccessToken(token: string) {
  const { data, error } = await anonClient().auth.getUser(token);
  if (error || !data.user) return null;
  return data.user;
}

export async function refreshSession(refreshToken: string) {
  const { data, error } = await anonClient().auth.refreshSession({ refresh_token: refreshToken });
  if (error || !data.session) return null;
  return data.session;
}
