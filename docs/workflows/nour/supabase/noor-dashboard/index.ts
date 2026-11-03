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

const rpc = (key: string, fn: string, body: unknown) =>
  fetch(PROJECT_URL + "/rest/v1/rpc/" + fn, {
    method: "POST",
    headers: { apikey: key, Authorization: "Bearer " + key, "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
const pass = async (r: Response) =>
  new Response(await r.text(), { status: r.status, headers: { "Content-Type": "application/json", "Cache-Control": "no-store" } });
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const ACTIONS = ["pause", "resume", "note", "stage", "tags", "send_dm"];

Deno.serve(async (req: Request) => {
  if (req.method !== "GET" && req.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  const expected = Deno.env.get("DASHBOARD_TOKEN") ?? "";
  if (expected.length < 24) return json({ error: "dashboard_token_not_set" }, 503);
  const token = req.headers.get("x-dash-token") ?? "";
  if (!token || !(await same(token, expected))) return json({ error: "unauthorized" }, 401);
  const key = serviceKey();
  if (!key) return json({ error: "service_key_missing" }, 500);

  // Writes from the dashboard: one action on one conversation.
  if (req.method === "POST") {
    let input: { action?: string; payload?: Record<string, unknown> };
    try { input = await req.json(); } catch { return json({ error: "invalid_json" }, 400); }
    const action = String(input.action ?? "");
    if (!ACTIONS.includes(action)) return json({ error: "unsupported_action" }, 400);
    return pass(await rpc(key, "adam_admin", { p_action: action, p: input.payload ?? {} }));
  }

  const q = new URL(req.url).searchParams;
  const view = q.get("view");
  if (view === "contact") {
    const id = q.get("id") ?? "";
    if (!UUID.test(id)) return json({ error: "bad_id" }, 400);
    return pass(await rpc(key, "adam_contact", { p_conv: id }));
  }
  const days = Math.min(90, Math.max(1, Number(q.get("days")) || 14));
  return pass(await rpc(key, view === "site" ? "adam_site_stats" : "noor_dashboard_stats", { p_days: days }));
});
