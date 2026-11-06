// Renders the «أمٌّ تعود» card for one mother and stores it in the public adam-media bucket.
// POST { name, key, date? } -> { ok, public_url }. key = stable file name (e.g. week + participant hash).
import { createClient } from "jsr:@supabase/supabase-js@2";
import { initWasm, Resvg } from "npm:@resvg/resvg-wasm@2.6.2";

const CDN = "https://cdn.jsdelivr.net/npm/";
const FONTS = [
  "@expo-google-fonts/amiri@0.4.1/400Regular/Amiri_400Regular.ttf",
  "@expo-google-fonts/amiri@0.4.1/700Bold/Amiri_700Bold.ttf",
  "@expo-google-fonts/aref-ruqaa@0.4.1/700Bold/ArefRuqaa_700Bold.ttf",
  "@expo-google-fonts/reem-kufi@0.4.2/600SemiBold/ReemKufi_600SemiBold.ttf",
];
let ready: Promise<Uint8Array[]> | null = null;
const boot = () => ready ??= (async () => {
  await initWasm(fetch(CDN + "@resvg/resvg-wasm@2.6.2/index_bg.wasm"));
  return await Promise.all(FONTS.map(async (f) => new Uint8Array(await (await fetch(CDN + f)).arrayBuffer())));
})();

// «أمٌّ تعود» certificate as SVG (1080x1350). Pure function: same code runs in Node (test) and Deno (edge function).
function cardSvg({ name, week = 'تحدّي سبع ليالٍ وسبع جمل', date = '', quote = 'مهما حدث، سأبقى أمّك… وسأبقى أحبّك' }) {
  const esc = s => String(s ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  const n = String(name || '').trim().slice(0, 36) || 'أمٌّ رائعة';
  const size = n.length <= 10 ? 118 : n.length <= 16 ? 96 : n.length <= 24 ? 76 : 60;
  const W = 1080, H = 1350, cx = W / 2;
  const stars = Array.from({ length: 7 }, (_, i) => {
    const x = cx - 180 + i * 60, y = 330 + (i % 2 ? 10 : 0);
    return `<path transform="translate(${x} ${y}) scale(${i === 3 ? 1.25 : 1})" d="M0,-12 L3,-3 L12,0 L3,3 L0,12 L-3,3 L-12,0 L-3,-3 Z" fill="url(#gold)"/>`;
  }).join('');
  const corner = (x, y, r) => `<g transform="translate(${x} ${y}) rotate(${r})"><path d="M0,0 L140,0 M0,0 L0,140" stroke="url(#gold)" stroke-width="3"/><path d="M18,18 L70,18 M18,18 L18,70" stroke="url(#gold)" stroke-width="1.5"/><path transform="translate(18 18)" d="M0,-9 L9,0 L0,9 L-9,0 Z" fill="url(#gold)"/></g>`;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">
<defs>
 <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0d1626"/><stop offset="0.55" stop-color="#16243b"/><stop offset="1" stop-color="#0b1220"/></linearGradient>
 <linearGradient id="gold" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#f6e3a8"/><stop offset="0.45" stop-color="#d4a94f"/><stop offset="0.7" stop-color="#b8862f"/><stop offset="1" stop-color="#f1d58a"/></linearGradient>
 <radialGradient id="glow" cx="0.5" cy="0.42" r="0.55"><stop offset="0" stop-color="#2b3d5c" stop-opacity="0.9"/><stop offset="1" stop-color="#0d1626" stop-opacity="0"/></radialGradient>
</defs>
<rect width="${W}" height="${H}" fill="url(#bg)"/>
<rect width="${W}" height="${H}" fill="url(#glow)"/>
<rect x="44" y="44" width="${W - 88}" height="${H - 88}" fill="none" stroke="url(#gold)" stroke-width="2.5"/>
<rect x="62" y="62" width="${W - 124}" height="${H - 124}" fill="none" stroke="url(#gold)" stroke-width="1" opacity="0.6"/>
${corner(62, 62, 0)}${corner(W - 62, 62, 90)}${corner(W - 62, H - 62, 180)}${corner(62, H - 62, 270)}
<mask id="moon"><rect x="-80" y="-80" width="160" height="160" fill="#fff"/><circle cx="26" cy="-14" r="58" fill="#000"/></mask><g transform="translate(${cx} 205)"><circle r="62" fill="url(#gold)" mask="url(#moon)"/></g>
${stars}
<text direction="rtl" x="${cx}" y="470" text-anchor="middle" font-family="Aref Ruqaa" font-weight="700" font-size="104" fill="url(#gold)">أمٌّ تعود</text>
<text direction="rtl" x="${cx}" y="560" text-anchor="middle" font-family="Amiri" font-size="38" fill="#e9e1cf" opacity="0.92">يشهد فريق آدم بكلّ محبّة أنّ</text>
<text direction="rtl" x="${cx}" y="${700}" text-anchor="middle" font-family="Aref Ruqaa" font-weight="700" font-size="${size}" fill="url(#gold)">${esc(n)}</text>
<path d="M${cx - 230},752 L${cx - 30},752 M${cx + 30},752 L${cx + 230},752" stroke="url(#gold)" stroke-width="2"/>
<path transform="translate(${cx} 752)" d="M0,-10 L10,0 L0,10 L-10,0 Z" fill="url(#gold)"/>
<text direction="rtl" x="${cx}" y="840" text-anchor="middle" font-family="Amiri" font-size="40" fill="#e9e1cf">أتمّت ${esc(week)}</text>
<text direction="rtl" x="${cx}" y="900" text-anchor="middle" font-family="Amiri" font-size="34" fill="#e9e1cf" opacity="0.85">وفي كلّ ليلة قالت لطفلها كلمةَ حبٍّ قبل النوم</text>
<text direction="rtl" x="${cx}" y="1030" text-anchor="middle" font-family="Amiri" font-weight="700" font-size="44" fill="url(#gold)">«${esc(quote)}»</text>
<text direction="rtl" x="${cx}" y="1175" text-anchor="middle" font-family="Reem Kufi" font-weight="600" font-size="40" fill="url(#gold)">آدم</text>
<text direction="rtl" x="${cx}" y="1222" text-anchor="middle" font-family="Amiri" font-size="28" fill="#e9e1cf" opacity="0.75">ما لا يقوله طفلك${date ? ' · ' + esc(date) : ''}</text>
</svg>`;
}


const json = (b: unknown, s = 200) => new Response(JSON.stringify(b), { status: s, headers: { "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ ok: false, reason: "method" }, 405);
  let b: { name?: string; key?: string; date?: string };
  try { b = await req.json(); } catch { return json({ ok: false, reason: "bad_json" }, 400); }
  const key = String(b.key || "");
  if (!/^[a-z0-9._-]{4,80}$/.test(key)) return json({ ok: false, reason: "bad_key" }, 400);
  const name = String(b.name || "").replace(/[\u0000-\u001f]/g, "").trim().slice(0, 36);
  try {
    const fontBuffers = await boot();
    const svg = cardSvg({ name, date: String(b.date || "").slice(0, 30) });
    const png = new Resvg(svg, { font: { fontBuffers, defaultFontFamily: "Amiri" }, fitTo: { mode: "width", value: 1080 } }).render().asPng();
    const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
    const path = `cards/${key}.png`;
    const { error } = await sb.storage.from("adam-media").upload(path, png, { contentType: "image/png", upsert: true });
    if (error) return json({ ok: false, reason: "storage: " + error.message }, 500);
    return json({ ok: true, public_url: sb.storage.from("adam-media").getPublicUrl(path).data.publicUrl, bytes: png.length });
  } catch (e) {
    return json({ ok: false, reason: String(e instanceof Error ? e.message : e).slice(0, 300) }, 500);
  }
});
