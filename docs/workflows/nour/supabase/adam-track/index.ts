import "jsr:@supabase/functions-js/edge-runtime.d.ts";

// Public ingest for site events, same exposure as n8n's hodn-track webhook (which forwards here).
// Accepts one event or an array of up to 1000; fields are clipped in SQL; duplicates are ignored.
const PROJECT_URL = Deno.env.get("SUPABASE_URL") ?? "https://vpinaehjfflnrlpfxlko.supabase.co";
const json = (d: unknown, s = 200) => new Response(JSON.stringify(d), { status: s, headers: { "Content-Type": "application/json" } });
const key = () => Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")
  ?? (() => { try { return JSON.parse(Deno.env.get("SUPABASE_SECRET_KEYS") ?? "{}").default; } catch { return undefined; } })();
const FIELDS = ["ts", "sid", "event", "page", "src", "country", "detail", "device"];

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  const raw = await req.text();
  if (raw.length > 1_500_000) return json({ error: "too_large" }, 413);
  let body: unknown;
  try { body = JSON.parse(raw); } catch { return json({ error: "invalid_json" }, 400); }
  const list = (Array.isArray(body) ? body : [body]).slice(0, 1000);
  const rows = list.filter((r) => r && typeof r === "object").map((r) => {
    const o: Record<string, string> = {};
    for (const f of FIELDS) { const v = (r as Record<string, unknown>)[f]; if (v != null) o[f] = String(v); }
    return o;
  });
  if (!rows.length) return json({ inserted: 0 });
  const k = key();
  if (!k) return json({ error: "service_key_missing" }, 500);
  const r = await fetch(PROJECT_URL + "/rest/v1/rpc/adam_track_events", {
    method: "POST",
    headers: { apikey: k, Authorization: "Bearer " + k, "Content-Type": "application/json" },
    body: JSON.stringify({ p_rows: rows }),
  });
  if (!r.ok) return json({ error: "insert_failed", status: r.status }, 502);
  return json({ inserted: Number(await r.text()) || 0 });
});
