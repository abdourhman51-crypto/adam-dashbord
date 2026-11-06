// Renders the «أمٌّ تعود» card for one mother (her name + her child's name) and stores it in the public adam-media bucket.
// POST { name, child?, key, date? } -> { ok, public_url }. key = stable file name (e.g. week + participant hash).
import { createClient } from "jsr:@supabase/supabase-js@2";
import { encodeBase64 } from "jsr:@std/encoding@1/base64";
import { initWasm, Resvg } from "npm:@resvg/resvg-wasm@2.6.2";

const CDN = "https://cdn.jsdelivr.net/npm/";
const MEDIA = (Deno.env.get("SUPABASE_URL") ?? "") + "/storage/v1/object/public/adam-media/";
const FONTS = [
  CDN + "@expo-google-fonts/amiri@0.4.1/400Regular/Amiri_400Regular.ttf",
  CDN + "@expo-google-fonts/amiri@0.4.1/700Bold/Amiri_700Bold.ttf",
  CDN + "@expo-google-fonts/aref-ruqaa@0.4.1/700Bold/ArefRuqaa_700Bold.ttf",
  MEDIA + "fonts/thmanyah-sans-regular.otf",
  MEDIA + "fonts/thmanyah-sans-bold.otf",
  MEDIA + "fonts/thmanyah-sans-black.otf",
];
const bytes = async (u: string) => { const r = await fetch(u); if (!r.ok) throw new Error("fetch " + r.status + " " + u.split("/").pop()); return new Uint8Array(await r.arrayBuffer()); };
let ready: Promise<{ fonts: Uint8Array[]; face: string; tree: string }> | null = null;
const boot = () => ready ??= (async () => {
  await initWasm(fetch(CDN + "@resvg/resvg-wasm@2.6.2/index_bg.wasm"));
  const [fonts, face, tree] = await Promise.all([
    Promise.all(FONTS.map(bytes)),
    bytes(MEDIA + "brand/adam-face.png"),
    bytes(MEDIA + "brand/adam-tree.png"),
  ]);
  return { fonts, face: "data:image/png;base64," + encodeBase64(face), tree: "data:image/png;base64," + encodeBase64(tree) };
})().catch((e) => { ready = null; throw e; });

// «أمٌّ تعود» certificate, 1080x1350 SVG. Pure function: runs in Node (local test) and Deno (adam-card edge function).
// Ivory paper, deep green ink (Adam's sweater), gold accents. Adam rises from the bottom edge in front of a gold sun.
// face / tree = image hrefs (data URIs in production). Font families are passed in by the caller.
function cardSvg({ name, child = '', date = '', face = '', tree = '', faceW = 700, faceH = 883,
  fontBlack = "'thmanyah sans'", fontName = "'thmanyah sans'", fontText = "'thmanyah sans'", fontOld = "'Aref Ruqaa'" }: Record<string, any>) {
  const esc = s => String(s ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  const clean = s => String(s || '').replace(/[\u0000-\u001f]/g, '').replace(/\s+/g, ' ').trim().slice(0, 30);
  const n = clean(name) || 'أمٌّ رائعة';
  const c = clean(child);
  const fit = (s, big) => s.length <= 9 ? big : s.length <= 13 ? Math.round(big * 0.84) : s.length <= 18 ? Math.round(big * 0.68) : Math.round(big * 0.54);
  const W = 1080, H = 1350, cx = W / 2;
  const INK = '#163a2c', MUTED = '#5d6a5f', GOLD = '#b7893a';
  const t = (y, txt, { size = 34, font = fontText, fill = MUTED, weight = 400, x = cx, anchor = 'middle' } = {}) =>
    `<text direction="rtl" x="${x}" y="${y}" text-anchor="${anchor}" font-family="${font}, Amiri" font-weight="${weight}" font-size="${size}" fill="${fill}">${txt}</text>`;
  const dia = (x, y, r = 7) => `<path transform="translate(${x} ${y})" d="M0,-${r} L${r},0 L0,${r} L-${r},0 Z" fill="${GOLD}"/>`;
  const ornament = y => `<rect x="${cx - 150}" y="${y - 0.75}" width="120" height="1.5" fill="${GOLD}"/><rect x="${cx + 30}" y="${y - 0.75}" width="120" height="1.5" fill="${GOLD}"/>${dia(cx, y)}${dia(cx - 160, y, 3.5)}${dia(cx + 160, y, 3.5)}`;
  // Adam: bust bottom sits exactly on the card edge, so he rises from below
  const fw = 410, fh = Math.round(fw * faceH / faceW), fy = H - fh;
  const sunR = 250, sunY = H - fh * 0.56;
  const crest = 96, crestH = Math.round(crest * 275 / 256);
  const lines = c
    ? t(614, 'أتمّت مع صغيرها') +
      t(700, esc(c), { size: fit(c, 84), font: fontName, fill: GOLD, weight: 700 }) +
      t(770, 'سبعَ ليالٍ من الحبّ قبل النوم', { size: 36, fill: INK })
    : t(648, 'أتمّت تحدّي سبع ليالٍ وسبع جمل', { size: 36, fill: INK }) +
      t(708, 'وقالت لصغيرها كلّ ليلةٍ كلمةَ حبٍّ قبل النوم', { size: 32 });
  return `<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">
<defs>
 <radialGradient id="paper" cx="0.5" cy="0.4" r="0.75"><stop offset="0" stop-color="#fcf8ef"/><stop offset="1" stop-color="#efe6d3"/></radialGradient>
 <radialGradient id="sun" cx="0.5" cy="0.45" r="0.5"><stop offset="0" stop-color="#f3dfae"/><stop offset="0.75" stop-color="#e6c787"/><stop offset="1" stop-color="#d9b46b"/></radialGradient>
 <clipPath id="page"><rect x="44" y="44" width="${W - 88}" height="${H - 44}"/></clipPath>
</defs>
<rect width="${W}" height="${H}" fill="url(#paper)"/>
<rect x="30" y="30" width="${W - 60}" height="${H - 60}" fill="none" stroke="${GOLD}" stroke-width="2"/>
<rect x="44" y="44" width="${W - 88}" height="${H - 88}" fill="none" stroke="${GOLD}" stroke-width="0.8" opacity="0.7"/>
${tree ? `<image href="${tree}" xlink:href="${tree}" x="${cx - crest / 2}" y="78" width="${crest}" height="${crestH}"/>` : dia(cx, 120, 14)}
${t(212, 'آدم · ما لا يقوله طفلك', { size: 24, fill: GOLD })}
${t(352, 'أمٌّ تعود', { size: 120, font: fontOld, fill: INK, weight: 700 })}
${ornament(392)}
${t(440, 'تشهد عائلة آدم بكلّ محبّة أنّ', { size: 32 })}
${t(546, esc(n), { size: fit(n, 96), font: fontBlack, fill: INK, weight: 900 })}
${lines}
<g clip-path="url(#page)">
 <circle cx="${cx}" cy="${sunY}" r="${sunR}" fill="url(#sun)"/>
 <circle cx="${cx}" cy="${sunY}" r="${sunR + 22}" fill="none" stroke="${GOLD}" stroke-width="1" opacity="0.55"/>
 ${face ? `<image href="${face}" xlink:href="${face}" x="${cx - fw / 2}" y="${fy}" width="${fw}" height="${fh}" preserveAspectRatio="xMidYMax meet"/>` : ''}
</g>
<g transform="translate(176 1150)">
 <circle r="80" fill="none" stroke="${GOLD}" stroke-width="2"/><circle r="70" fill="none" stroke="${GOLD}" stroke-width="0.8"/>
 <text direction="rtl" x="0" y="14" text-anchor="middle" font-family="${fontBlack}, Amiri" font-weight="900" font-size="64" fill="${INK}">٧</text>
 <text direction="rtl" x="0" y="48" text-anchor="middle" font-family="${fontText}, Amiri" font-size="20" fill="${MUTED}">ليالٍ</text>
</g>
<rect x="${W - 296}" y="1172" width="220" height="1" fill="${GOLD}"/>
${t(1160, 'فريق آدم', { size: 40, font: fontOld, fill: INK, weight: 700, x: W - 186 })}
${t(1208, esc(date), { size: 22, x: W - 186 })}
</svg>`;
}

const json = (b: unknown, s = 200) => new Response(JSON.stringify(b), { status: s, headers: { "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ ok: false, reason: "method" }, 405);
  let b: { name?: string; child?: string; key?: string; date?: string };
  try { b = await req.json(); } catch { return json({ ok: false, reason: "bad_json" }, 400); }
  const key = String(b.key || "");
  if (!/^[a-z0-9._-]{4,80}$/.test(key)) return json({ ok: false, reason: "bad_key" }, 400);
  try {
    const a = await boot();
    const svg = cardSvg({ name: b.name, child: b.child, date: String(b.date || "").slice(0, 30), face: a.face, tree: a.tree });
    const png = new Resvg(svg, { font: { fontBuffers: a.fonts, defaultFontFamily: "Amiri" }, fitTo: { mode: "width", value: 1080 } }).render().asPng();
    const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
    const path = `cards/${key}.png`;
    const { error } = await sb.storage.from("adam-media").upload(path, png, { contentType: "image/png", upsert: true });
    if (error) return json({ ok: false, reason: "storage: " + error.message }, 500);
    return json({ ok: true, public_url: sb.storage.from("adam-media").getPublicUrl(path).data.publicUrl, bytes: png.length });
  } catch (e) {
    return json({ ok: false, reason: String(e instanceof Error ? e.message : e).slice(0, 300) }, 500);
  }
});
