// «أمٌّ تعود» certificate, 1080x1350 SVG (rendered larger for sharpness). Pure function: Node (local test) and Deno (adam-card).
// Editorial, quiet-luxury layout on a 12-column grid (margin 96, golden-ratio split at x≈667 / y≈834):
//  - text column right-aligned (RTL) on the right two thirds, Adam rising from the bottom edge on the left third,
//  - large "7" in champagne as a quiet layered numeral, hairline frame, soft ambient glows and shadow.
// face / tree = image hrefs (data URIs in production).
export function cardSvg({ name, child = '', date = '', face = '', tree = '', faceW = 700, faceH = 883,
  fontBlack = "'thmanyah serif display'", fontName = "'thmanyah serif display'", fontText = "'thmanyah serif text'", fontOld = "'Aref Ruqaa'" }) {
  const esc = s => String(s ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  const clean = s => String(s || '').replace(/[\u0000-\u001f]/g, '').replace(/\s+/g, ' ').trim().slice(0, 30);
  const n = clean(name) || 'أمٌّ رائعة';
  const c = clean(child);
  const fit = (s, big) => s.length <= 9 ? big : s.length <= 13 ? Math.round(big * 0.84) : s.length <= 18 ? Math.round(big * 0.68) : Math.round(big * 0.54);
  const W = 1080, H = 1350, R = W - 96;            // right edge of the text column
  const INK = '#1d3a2f', SOFT = '#6b7468', GOLD = '#a8834a';
  const t = (x, y, txt, { size = 30, font = fontText, fill = SOFT, weight = 400, anchor = 'end', dir = 'rtl' } = {}) =>
    `<text direction="${dir}" x="${x}" y="${y}" text-anchor="${anchor}" font-family="${font}, Amiri" font-weight="${weight}" font-size="${size}" fill="${fill}">${txt}</text>`;
  const dia = (x, y, r = 4) => `<path transform="translate(${x} ${y})" d="M0,-${r} L${r},0 L0,${r} L-${r},0 Z" fill="${GOLD}"/>`;
  const rule = (x1, x2, y, op = 1) => `<rect x="${Math.min(x1, x2)}" y="${y}" width="${Math.abs(x2 - x1)}" height="1" fill="${GOLD}" opacity="${op}"/>`;
  // crop-mark ticks at the frame corners (micro detail)
  const tick = (x, y, dx, dy) => `<path d="M${x},${y + dy * 18} L${x},${y} L${x + dx * 18},${y}" fill="none" stroke="${GOLD}" stroke-width="1.2"/>`;
  // wax seal: irregular blob of deep-green wax, pressed ring, gold-leaf tree stamp, soft ambient shadow
  const seal = (cx, cy, r) => {
    const pts = [];
    for (let k = 0; k < 36; k++) {
      const a = k / 36 * Math.PI * 2;
      const rr = r * (1 + 0.045 * Math.sin(a * 5 + 0.7) + 0.03 * Math.sin(a * 9 + 2.1) + 0.02 * Math.sin(a * 14));
      pts.push([cx + rr * Math.cos(a), cy + rr * Math.sin(a)]);
    }
    const mid = (p, q) => [(p[0] + q[0]) / 2, (p[1] + q[1]) / 2];
    let d = `M${mid(pts[35], pts[0]).map(v => v.toFixed(1)).join(',')}`;
    for (let k = 0; k < 36; k++) { const m = mid(pts[k], pts[(k + 1) % 36]); d += ` Q${pts[k][0].toFixed(1)},${pts[k][1].toFixed(1)} ${m[0].toFixed(1)},${m[1].toFixed(1)}`; }
    const dots = Array.from({ length: 28 }, (_, k) => { const a = k / 28 * Math.PI * 2; return `<circle cx="${(cx + r * 0.8 * Math.cos(a)).toFixed(1)}" cy="${(cy + r * 0.8 * Math.sin(a)).toFixed(1)}" r="1.6" fill="#0e2119" opacity="0.55"/>`; }).join('');
    const ts = r * 0.92;
    return `<ellipse cx="${cx + 8}" cy="${cy + 12}" rx="${r * 1.12}" ry="${r * 1.08}" fill="url(#waxShadow)"/>
<path d="${d}" fill="url(#wax)"/>
<path d="${d}" fill="none" stroke="#5c8a70" stroke-width="1" opacity="0.35"/>
<circle cx="${cx}" cy="${cy}" r="${r * 0.7}" fill="url(#waxPress)"/>
<circle cx="${cx}" cy="${cy}" r="${r * 0.7}" fill="none" stroke="#0e2119" stroke-width="2.4" opacity="0.7"/>
<circle cx="${cx + 0.8}" cy="${cy + 1.2}" r="${r * 0.7 + 1.6}" fill="none" stroke="#4f7d64" stroke-width="1" opacity="0.6"/>
${dots}
${tree ? `<image href="${tree}" xlink:href="${tree}" x="${cx - ts / 2}" y="${cy - ts * 0.55}" width="${ts}" height="${ts * 275 / 256}" opacity="0.92"/>` : ''}
<ellipse cx="${cx - r * 0.35}" cy="${cy - r * 0.42}" rx="${r * 0.38}" ry="${r * 0.18}" transform="rotate(-28 ${cx - r * 0.35} ${cy - r * 0.42})" fill="url(#waxGloss)"/>`;
  };
  // Adam on the left third, bottom on the card edge
  const fw = 470, fh = Math.round(fw * faceH / faceW), fx = 70, fy = H - fh;
  const body = c
    ? t(R, 612, 'أتمّت مع صغيرها') +
      t(R, 694, esc(c), { size: fit(c, 76), font: fontName, fill: GOLD, weight: 700 }) +
      t(R, 750, 'سبعَ ليالٍ من الحبّ قبل النوم', { size: 30, fill: INK })
    : t(R, 618, 'أتمّت تحدّي سبع ليالٍ وسبع جمل', { size: 32, fill: INK }) +
      t(R, 670, 'وقالت لصغيرها كلّ ليلةٍ كلمةَ حبٍّ قبل النوم', { size: 28 });
  return `<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">
<defs>
 <linearGradient id="paper" x1="0" y1="0" x2="0.35" y2="1"><stop offset="0" stop-color="#fcf8f0"/><stop offset="0.55" stop-color="#f6eedf"/><stop offset="1" stop-color="#ecdfc6"/></linearGradient>
 <radialGradient id="glowAdam" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#f6e2b6" stop-opacity="0.95"/><stop offset="0.45" stop-color="#f1dcb0" stop-opacity="0.45"/><stop offset="1" stop-color="#f1dcb0" stop-opacity="0"/></radialGradient>
 <radialGradient id="glowTop" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#ffffff" stop-opacity="0.75"/><stop offset="1" stop-color="#ffffff" stop-opacity="0"/></radialGradient>
 <radialGradient id="vignette" cx="0.5" cy="0.45" r="0.75"><stop offset="0.6" stop-color="#c9b38a" stop-opacity="0"/><stop offset="1" stop-color="#b89c6a" stop-opacity="0.28"/></radialGradient>
 <linearGradient id="seven" x1="0" y1="0" x2="0.6" y2="1"><stop offset="0" stop-color="#ecdcb9"/><stop offset="0.6" stop-color="#dcc6a0"/><stop offset="1" stop-color="#c9ab78"/></linearGradient>
 <radialGradient id="wax" cx="0.36" cy="0.32" r="0.75"><stop offset="0" stop-color="#3f6b55"/><stop offset="0.45" stop-color="#244a39"/><stop offset="1" stop-color="#11271d"/></radialGradient>
 <radialGradient id="waxPress" cx="0.6" cy="0.65" r="0.7"><stop offset="0" stop-color="#2c5442"/><stop offset="1" stop-color="#18352a"/></radialGradient>
 <radialGradient id="waxGloss" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#ffffff" stop-opacity="0.16"/><stop offset="1" stop-color="#ffffff" stop-opacity="0"/></radialGradient>
 <radialGradient id="waxShadow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#1d3a2f" stop-opacity="0.35"/><stop offset="0.7" stop-color="#1d3a2f" stop-opacity="0.08"/><stop offset="1" stop-color="#1d3a2f" stop-opacity="0"/></radialGradient>
 <radialGradient id="shade" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#1d3a2f" stop-opacity="0.22"/><stop offset="0.6" stop-color="#1d3a2f" stop-opacity="0.08"/><stop offset="1" stop-color="#1d3a2f" stop-opacity="0"/></radialGradient>
</defs>
<rect width="${W}" height="${H}" fill="url(#paper)"/>
<ellipse cx="${fx + fw / 2}" cy="${H - fh * 0.42}" rx="430" ry="470" fill="url(#glowAdam)"/>
<ellipse cx="${W - 260}" cy="230" rx="520" ry="360" fill="url(#glowTop)"/>
<rect width="${W}" height="${H}" fill="url(#vignette)"/>

<rect x="40.5" y="40.5" width="${W - 81}" height="${H - 81}" fill="none" stroke="${GOLD}" stroke-width="1" opacity="0.45"/>
${tick(40.5, 40.5, 1, 1)}${tick(W - 40.5, 40.5, -1, 1)}${tick(40.5, H - 40.5, 1, -1)}${tick(W - 40.5, H - 40.5, -1, -1)}

${tree ? `<image href="${tree}" xlink:href="${tree}" x="${R - 54}" y="92" width="54" height="${Math.round(54 * 275 / 256)}"/>` : dia(R - 27, 120, 10)}
${t(R - 72, 124, 'آدم', { size: 26, font: fontOld, fill: INK, weight: 700 })}
${t(R - 72, 154, 'ما لا يقوله طفلك', { size: 19 })}
${t(96, 124, esc(date), { size: 19, anchor: 'start' })}
${rule(96, 236, 140, 0.6)}

${t(R, 328, 'أمٌّ تعود', { size: 150, font: fontOld, fill: INK, weight: 700 })}
${rule(R, R - 132, 372)}${dia(R - 142, 372.5, 3.5)}
${t(R, 440, 'تشهد عائلة آدم بكلّ محبّة أنّ', { size: 28 })}
${t(R, 540, esc(n), { size: fit(n, 104), font: fontBlack, fill: INK, weight: 900 })}
${body}

<text x="${R}" y="1168" text-anchor="end" font-family="${fontBlack}, Amiri" font-weight="900" font-size="360" fill="url(#seven)">7</text>
${t(R - 214, 1060, 'ليالٍ', { size: 34, font: fontName, fill: INK, weight: 700 })}
${t(R - 214, 1100, 'وسبع جمل', { size: 22 })}
${rule(R, R - 236, 1212, 0.7)}
${t(R, 1262, 'فريق آدم', { size: 38, font: fontOld, fill: INK, weight: 700 })}
${seal(R - 318, 1232, 60)}

${face ? `<ellipse cx="${fx + fw / 2 + 26}" cy="${H - fh * 0.35}" rx="${fw * 0.52}" ry="${fh * 0.5}" fill="url(#shade)"/>
<image href="${face}" xlink:href="${face}" x="${fx}" y="${fy}" width="${fw}" height="${fh}"/>` : ''}
</svg>`;
}
