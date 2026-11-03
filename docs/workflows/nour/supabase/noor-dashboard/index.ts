import "jsr:@supabase/functions-js/edge-runtime.d.ts";

// Read-only feed for the Adam dashboard. The caller sends x-dash-token, which must equal the
// edge function secret DASHBOARD_TOKEN (the same value is NOOR_DASH_TOKEN in Vercel).
const PROJECT_URL = Deno.env.get("SUPABASE_URL") ?? "https://vpinaehjfflnrlpfxlko.supabase.co";

const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), { status, headers: { "Content-Type": "application/json", "Cache-Control": "no-store" } });

async function sha256(s: string) {
  return new Uint8Array(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(s)));
}

// Compare digests, so the check takes the same time whatever the token.
async function same(a: string, b: string) {
  const [x, y] = await Promise.all([sha256(a), sha256(b)]);
  let d = 0;
  for (let i = 0; i < x.length; i++) d |= x[i] ^ y[i];
  return d === 0;
}

function serviceKey() {
  return Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")
    ?? (() => { try { return JSON.parse(Deno.env.get("SUPABASE_SECRET_KEYS") ?? "{}").default; } catch { return undefined; } })();
}

Deno.serve(async (req: Request) => {
  if (req.method !== "GET") return json({ error: "method_not_allowed" }, 405);
  const expected = Deno.env.get("DASHBOARD_TOKEN") ?? "";
  if (expected.length < 24) return json({ error: "dashboard_token_not_set" }, 503);
  const token = req.headers.get("x-dash-token") ?? "";
  if (!token || !(await same(token, expected))) return json({ error: "unauthorized" }, 401);
  const key = serviceKey();
  if (!key) return json({ error: "service_key_missing" }, 500);
  const days = Math.min(90, Math.max(1, Number(new URL(req.url).searchParams.get("days")) || 14));
  const r = await fetch(PROJECT_URL + "/rest/v1/rpc/noor_dashboard_stats", {
    method: "POST",
    headers: { apikey: key, Authorization: "Bearer " + key, "Content-Type": "application/json" },
    body: JSON.stringify({ p_days: days }),
  });
  return new Response(await r.text(), { status: r.status, headers: { "Content-Type": "application/json", "Cache-Control": "no-store" } });
});
