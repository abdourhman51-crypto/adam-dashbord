// Copies a file into the public `adam-media` bucket and returns its permanent URL.
// POST { url, path }        -> fetch from an allowed source host
// POST { data, path, type } -> base64 upload, only into brand/ or fonts/ (small assets prepared in n8n)
// POST { zip_url, entries: { "<file name inside zip>": "fonts/<name>.otf" } } -> pull fonts out of a zip (allowed hosts only)
// Only known source hosts and fixed folders are accepted, so the endpoint cannot be used as an open proxy.
import { createClient } from "jsr:@supabase/supabase-js@2";

const ALLOWED_HOSTS = ["elevenlabsusercontent.com", "api.wapito.com", "drive.usercontent.google.com"];
const PATH_RE = /^(voices|cards|videos|music|docs|fonts|brand)\/[a-z0-9._-]{1,80}$/;
const MAX_BYTES = 50 * 1024 * 1024;
const BY_EXT: Record<string, string> = { pdf: "application/pdf", mp3: "audio/mpeg", ogg: "audio/ogg", mp4: "video/mp4", png: "image/png", jpg: "image/jpeg", jpeg: "image/jpeg", webp: "image/webp", otf: "font/otf", ttf: "font/ttf" };

const json = (b: unknown, s = 200) => new Response(JSON.stringify(b), { status: s, headers: { "Content-Type": "application/json" } });
const hostOk = (url: string) => { try { const u = new URL(url); return u.protocol === "https:" && ALLOWED_HOSTS.some((h) => u.hostname === h || u.hostname.endsWith("." + h)); } catch { return false; } };
const isFont = (b: Uint8Array) => String.fromCharCode(...b.slice(0, 4)) === "OTTO" || (b[0] === 0 && b[1] === 1 && b[2] === 0 && b[3] === 0);
const sb = () => createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

async function unzipEntries(buf: Uint8Array, want: Record<string, string>) {
  const dv = new DataView(buf.buffer, buf.byteOffset, buf.byteLength);
  let e = buf.length - 22; while (e > 0 && dv.getUint32(e, true) !== 0x06054b50) e--;
  const cnt = dv.getUint16(e + 10, true); let p = dv.getUint32(e + 16, true);
  const dec = new TextDecoder();
  const out: { name: string; path: string; bytes: Uint8Array }[] = [];
  for (let i = 0; i < cnt; i++) {
    const method = dv.getUint16(p + 10, true), csize = dv.getUint32(p + 20, true);
    const nl = dv.getUint16(p + 28, true), xl = dv.getUint16(p + 30, true), cl = dv.getUint16(p + 32, true), lo = dv.getUint32(p + 42, true);
    const name = dec.decode(buf.subarray(p + 46, p + 46 + nl)); p += 46 + nl + xl + cl;
    const base = name.split("/").pop()!;
    if (name.includes("__MACOSX") || !want[base]) continue;
    const ds = lo + 30 + dv.getUint16(lo + 26, true) + dv.getUint16(lo + 28, true);
    const raw = buf.slice(ds, ds + csize);
    const bytes = method === 8 ? new Uint8Array(await new Response(new Blob([raw]).stream().pipeThrough(new DecompressionStream("deflate-raw"))).arrayBuffer()) : raw;
    out.push({ name: base, path: want[base], bytes });
  }
  return out;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ ok: false, reason: "method" }, 405);
  let body: { url?: string; path?: string; data?: string; zip_url?: string; entries?: Record<string, string> };
  try { body = await req.json(); } catch { return json({ ok: false, reason: "bad_json" }, 400); }

  if (body.zip_url) {
    const want = body.entries || {};
    if (!Object.values(want).length || !Object.values(want).every((p) => PATH_RE.test(p) && p.startsWith("fonts/"))) return json({ ok: false, reason: "zip_only_into_fonts" }, 400);
    if (!hostOk(body.zip_url)) return json({ ok: false, reason: "host_not_allowed" }, 403);
    const r = await fetch(body.zip_url);
    if (!r.ok) return json({ ok: false, reason: "source_" + r.status }, 502);
    const buf = new Uint8Array(await r.arrayBuffer());
    if (buf.byteLength > MAX_BYTES || buf[0] !== 0x50 || buf[1] !== 0x4b) return json({ ok: false, reason: "not_a_zip" }, 502);
    const files = await unzipEntries(buf, want);
    const client = sb(); const done = [];
    for (const f of files) {
      if (!isFont(f.bytes)) { done.push({ name: f.name, ok: false, reason: "not_a_font" }); continue; }
      const { error } = await client.storage.from("adam-media").upload(f.path, f.bytes, { contentType: "font/otf", upsert: true });
      done.push({ name: f.name, ok: !error, bytes: f.bytes.byteLength, url: client.storage.from("adam-media").getPublicUrl(f.path).data.publicUrl, reason: error?.message });
    }
    return json({ ok: done.length > 0 && done.every((d) => d.ok), files: done });
  }

  const { url, path, data } = body;
  if (!path || !PATH_RE.test(path)) return json({ ok: false, reason: "bad_input" }, 400);
  const ext = path.split(".").pop()!.toLowerCase();
  let buf: Uint8Array;
  let type = BY_EXT[ext] || "application/octet-stream";

  if (data) {
    if (!path.startsWith("brand/") && !path.startsWith("fonts/")) return json({ ok: false, reason: "upload_only_to_brand_or_fonts" }, 403);
    try { buf = Uint8Array.from(atob(data), (c) => c.charCodeAt(0)); } catch { return json({ ok: false, reason: "bad_base64" }, 400); }
    if (buf.byteLength > 5 * 1024 * 1024) return json({ ok: false, reason: "too_large" }, 413);
    if (path.startsWith("fonts/") && !isFont(buf)) return json({ ok: false, reason: "not_a_font" }, 400);
  } else {
    if (!url) return json({ ok: false, reason: "bad_input" }, 400);
    if (!hostOk(url)) return json({ ok: false, reason: "host_not_allowed" }, 403);
    const r = await fetch(url);
    if (!r.ok) return json({ ok: false, reason: "source_" + r.status }, 502);
    buf = new Uint8Array(await r.arrayBuffer());
    if (buf.byteLength > MAX_BYTES) return json({ ok: false, reason: "too_large" }, 413);
    const t = r.headers.get("content-type")?.split(";")[0] || "";
    // Drive sometimes answers with an HTML page (virus-scan or login) instead of the file.
    if (t.startsWith("text/html")) return json({ ok: false, reason: "source_returned_html" }, 502);
    // Generic types from the source: trust the extension we asked for instead.
    if (t && t !== "application/octet-stream" && t !== "binary/octet-stream" && !BY_EXT[ext]) type = t;
  }
  if (ext === "pdf" && String.fromCharCode(...buf.slice(0, 4)) !== "%PDF") return json({ ok: false, reason: "not_a_pdf" }, 502);

  const client = sb();
  const { error } = await client.storage.from("adam-media").upload(path, buf, { contentType: type, upsert: true });
  if (error) return json({ ok: false, reason: "storage: " + error.message }, 500);
  const { data: pub } = client.storage.from("adam-media").getPublicUrl(path);
  return json({ ok: true, public_url: pub.publicUrl, bytes: buf.byteLength, type });
});
