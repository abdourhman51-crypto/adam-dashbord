// «أمٌّ تعود» certificate as SVG (1080x1350). Pure function: runs in Node (local test) and Deno (adam-card edge function).
// face / tree = image hrefs (data URIs in production). Fonts: "thmanyah serif display" (names), "thmanyah serif text" (body),
// "Aref Ruqaa" (classic title + quote), "Amiri" (fallback).
export function cardSvg({ name, child = '', date = '', face = '', tree = '', faceW = 700, faceH = 883 }) {
  const esc = s => String(s ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  const clean = s => String(s || '').replace(/[\u0000-\u001f]/g, '').trim().slice(0, 30);
  const n = clean(name) || 'أمٌّ رائعة';
  const c = clean(child);
  const fit = (s, big) => s.length <= 8 ? big : s.length <= 14 ? Math.round(big * 0.8) : s.length <= 20 ? Math.round(big * 0.64) : Math.round(big * 0.52);
  const W = 1080, H = 1350, cx = W / 2;
  const DISP = "'thmanyah serif display', Amiri", TEXT = "'thmanyah serif text', Amiri", OLD = "'Aref Ruqaa', Amiri";
  const t = (y, txt, { size = 36, font = TEXT, fill = '#efe6d2', weight = 400, op = 1 } = {}) =>
    `<text direction="rtl" x="${cx}" y="${y}" text-anchor="middle" font-family="${font}" font-weight="${weight}" font-size="${size}" fill="${fill}"${op < 1 ? ` opacity="${op}"` : ''}>${txt}</text>`;
  const stars = Array.from({ length: 7 }, (_, i) => {
    const x = cx - 150 + i * 50, y = 72 + (i % 2 ? 8 : 0);
    return `<path transform="translate(${x} ${y}) scale(${i === 3 ? 1.1 : 0.8})" d="M0,-12 L3,-3 L12,0 L3,3 L0,12 L-3,3 L-12,0 L-3,-3 Z" fill="url(#gold)"/>`;
  }).join('');
  const corner = (x, y, r) => `<g transform="translate(${x} ${y}) rotate(${r})"><path d="M0,0 L120,0 M0,0 L0,120" stroke="url(#gold)" stroke-width="3"/><path d="M16,16 L60,16 M16,16 L16,60" stroke="url(#gold)" stroke-width="1.5"/><path transform="translate(16 16)" d="M0,-8 L8,0 L0,8 L-8,0 Z" fill="url(#gold)"/></g>`;
  const rule = y => `<path d="M${cx - 200},${y} L${cx - 26},${y} M${cx + 26},${y} L${cx + 200},${y}" stroke="url(#gold)" stroke-width="1.6"/><path transform="translate(${cx} ${y})" d="M0,-8 L8,0 L0,8 L-8,0 Z" fill="url(#gold)"/>`;
  // face rises from the bottom edge: bottom of the image sits exactly on the card edge
  const fw = 430, fh = Math.round(fw * faceH / faceW), fy = H - fh;
  const treeW = 980, treeH = Math.round(treeW * 275 / 256);
  return `<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">
<defs>
 <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0c1524"/><stop offset="0.5" stop-color="#15233a"/><stop offset="1" stop-color="#0a111d"/></linearGradient>
 <linearGradient id="gold" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#f6e3a8"/><stop offset="0.45" stop-color="#d4a94f"/><stop offset="0.7" stop-color="#b8862f"/><stop offset="1" stop-color="#f1d58a"/></linearGradient>
 <radialGradient id="glow" cx="0.5" cy="0.38" r="0.6"><stop offset="0" stop-color="#2a3c5a" stop-opacity="0.85"/><stop offset="1" stop-color="#0c1524" stop-opacity="0"/></radialGradient>
 <radialGradient id="halo" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#d4a94f" stop-opacity="0.38"/><stop offset="0.6" stop-color="#d4a94f" stop-opacity="0.10"/><stop offset="1" stop-color="#d4a94f" stop-opacity="0"/></radialGradient>
</defs>
<rect width="${W}" height="${H}" fill="url(#bg)"/>
${tree ? `<image href="${tree}" xlink:href="${tree}" x="${cx - treeW / 2}" y="${150}" width="${treeW}" height="${treeH}" opacity="0.10" preserveAspectRatio="xMidYMid meet"/>` : ''}
<rect width="${W}" height="${H}" fill="url(#glow)"/>
<rect x="40" y="40" width="${W - 80}" height="${H - 80}" fill="none" stroke="url(#gold)" stroke-width="2.5"/>
<rect x="56" y="56" width="${W - 112}" height="${H - 112}" fill="none" stroke="url(#gold)" stroke-width="1" opacity="0.55"/>
${corner(56, 56, 0)}${corner(W - 56, 56, 90)}${corner(W - 56, H - 56, 180)}${corner(56, H - 56, 270)}
${stars}
${t(205, 'أمٌّ تعود', { size: 110, font: OLD, fill: 'url(#gold)', weight: 700 })}
${t(285, 'يشهد فريق آدم بكلّ محبّة أنّ', { size: 34, op: 0.9 })}
${t(395, esc(n), { size: fit(n, 96), font: DISP, fill: 'url(#gold)', weight: 700 })}
${rule(438)}
${t(500, 'أتمّت تحدّي سبع ليالٍ وسبع جمل', { size: 38 })}
${t(560, c ? 'وفي كلّ ليلةٍ قالت لصغيرها' : 'وفي كلّ ليلةٍ قالت لصغيرها كلمةَ حبٍّ قبل النوم', { size: 33, op: 0.85 })}
${c ? t(645, esc(c), { size: fit(c, 78), font: DISP, fill: 'url(#gold)', weight: 700 }) + t(700, 'كلمةَ حبٍّ قبل النوم', { size: 33, op: 0.85 }) : ''}
${t(c ? 790 : 680, '«مهما حدث، سأبقى أمّك… وسأبقى أحبّك»', { size: 44, font: OLD, fill: 'url(#gold)', weight: 700 })}
<ellipse cx="${cx}" cy="${H - fh * 0.55}" rx="${fw * 0.75}" ry="${fh * 0.62}" fill="url(#halo)"/>
${face ? `<image href="${face}" xlink:href="${face}" x="${cx - fw / 2}" y="${fy}" width="${fw}" height="${fh}" preserveAspectRatio="xMidYMax meet"/>` : ''}
<text direction="rtl" x="${W - 190}" y="${H - 150}" text-anchor="middle" font-family="${OLD}" font-weight="700" font-size="50" fill="url(#gold)">آدم</text>
<text direction="rtl" x="${W - 190}" y="${H - 105}" text-anchor="middle" font-family="${TEXT}" font-size="25" fill="#efe6d2" opacity="0.75">ما لا يقوله طفلك</text>
${date ? `<text direction="rtl" x="190" y="${H - 120}" text-anchor="middle" font-family="${TEXT}" font-size="27" fill="#efe6d2" opacity="0.75">${esc(date)}</text>` : ''}
</svg>`;
}
