// «أمٌّ تعود» certificate, 1080x1350 SVG. Pure function: runs in Node (local test) and Deno (adam-card edge function).
// Ivory paper, deep green ink (Adam's sweater), gold accents. Adam rises from the bottom edge in front of a gold sun.
// face / tree = image hrefs (data URIs in production). Font families are passed in by the caller.
export function cardSvg({ name, child = '', date = '', face = '', tree = '', faceW = 700, faceH = 883,
  fontBlack = "'thmanyah sans'", fontName = "'thmanyah sans'", fontText = "'thmanyah sans'", fontOld = "'Aref Ruqaa'" }) {
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
