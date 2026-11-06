// «بطاقة تهنئة» — academic congratulation certificate for mothers who finished «أمٌّ تعود». 1080x1350 SVG.
// Pure function: runs in Node (local test) and Deno (adam-card edge function).
// Classic, symmetric, institutional: patterned double border, guilloche rosette watermark, Adam inside a gold
// medallion crowned by laurels, large title, formal wording, two signature lines, deep-green wax seal with ribbons.
// face / tree = image hrefs (data URIs in production). serial = short certificate number (Western digits).
export function cardSvg({ name, child = '', date = '', serial = '', face = '', tree = '', faceW = 700, faceH = 883,
  fontBlack = "'thmanyah serif display'", fontName = "'thmanyah serif display'", fontText = "'thmanyah serif text'", fontOld = "'Aref Ruqaa'", fontTitle = "'Amiri'" }) {
  const esc = s => String(s ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  const clean = s => String(s || '').replace(/[\u0000-\u001f]/g, '').replace(/\s+/g, ' ').trim().slice(0, 30);
  const n = clean(name) || 'أمٌّ رائعة';
  const c = clean(child);
  const fit = (s, big) => s.length <= 9 ? big : s.length <= 13 ? Math.round(big * 0.84) : s.length <= 18 ? Math.round(big * 0.68) : Math.round(big * 0.54);
  const W = 1080, H = 1350, cx = W / 2;
  const INK = '#1b3a2e', SOFT = '#5f6b60', GOLD = '#a8834a';
  const f = v => Number(v).toFixed(1);
  const t = (x, y, txt, { size = 28, font = fontText, fill = SOFT, weight = 400, anchor = 'middle', dir = 'rtl' } = {}) =>
    `<text direction="${dir}" x="${x}" y="${y}" text-anchor="${anchor}" font-family="${font}, Amiri" font-weight="${weight}" font-size="${size}" fill="${fill}">${txt}</text>`;
  const dia = (x, y, r = 5, fill = GOLD) => `<path transform="translate(${f(x)} ${f(y)})" d="M0,-${r} L${r},0 L0,${r} L-${r},0 Z" fill="${fill}"/>`;
  // centred ornament rule: hairlines, centre diamond, two small diamonds
  const ornament = (y, half = 150) => `<rect x="${cx - half}" y="${y - 0.5}" width="${half - 16}" height="1" fill="${GOLD}"/><rect x="${cx + 16}" y="${y - 0.5}" width="${half - 16}" height="1" fill="${GOLD}"/>${dia(cx, y, 6)}${dia(cx - half - 8, y, 3)}${dia(cx + half + 8, y, 3)}`;

  // gilded lettering: soft champagne glow, a thin gold edge under the letters, then the gradient ink on top
  const gilt = (y, txt, { size, font, weight = 700, fill = 'url(#ink)', edge = 'url(#giltEdge)', glow = true, dy = 2 }) =>
    (glow ? `<ellipse cx="${cx}" cy="${f(y - size * 0.32)}" rx="${f(size * 2.7)}" ry="${f(size * 0.85)}" fill="url(#textGlow)"/>` : '') +
    `<text direction="rtl" x="${cx}" y="${y + dy}" text-anchor="middle" font-family="${font}, Amiri" font-weight="${weight}" font-size="${size}" fill="${edge}">${txt}</text>` +
    `<text direction="rtl" x="${cx}" y="${y}" text-anchor="middle" font-family="${font}, Amiri" font-weight="${weight}" font-size="${size}" fill="${fill}">${txt}</text>`;

  // guilloche rosette watermark (security-paper feel)
  const rosette = (rx, ry, x, y, k, op) => Array.from({ length: k }, (_, i) =>
    `<ellipse cx="${x}" cy="${y}" rx="${rx}" ry="${ry}" transform="rotate(${f(i * 180 / k)} ${x} ${y})" fill="none" stroke="${GOLD}" stroke-width="0.7" opacity="${op}"/>`).join('');

  // laurel branch along an arc around the medallion (side = -1 left, +1 right)
  const laurel = (x, y, R, side) => {
    let out = '';
    for (let i = 0; i < 11; i++) {
      const deg = 98 + i * 11.5;                               // from bottom up the side
      const th = (side < 0 ? deg : 180 - deg) * Math.PI / 180;
      const px = x + R * Math.cos(th), py = y + R * Math.sin(th);
      const tang = Math.atan2(Math.cos(th), -Math.sin(th)) * 180 / Math.PI * (side < 0 ? 1 : -1);
      const len = 15 - i * 0.55;
      for (const o of [-1, 1]) {
        const ang = (side < 0 ? th * 180 / Math.PI + 90 : th * 180 / Math.PI - 90) + o * 38;
        out += `<ellipse cx="${f(px)}" cy="${f(py)}" rx="${f(len)}" ry="${f(len * 0.36)}" transform="rotate(${f(ang)} ${f(px)} ${f(py)}) translate(${f(len * 0.9)} 0)" fill="url(#leaf)"/>`;
      }
      void tang;
    }
    const a0 = 98 * Math.PI / 180, a1 = (98 + 10 * 11.5) * Math.PI / 180;
    const sx = v => side < 0 ? v : Math.PI - v;
    return `<path d="M${f(x + R * Math.cos(sx(a0)))},${f(y + R * Math.sin(sx(a0)))} A${R},${R} 0 0 ${side < 0 ? 1 : 0} ${f(x + R * Math.cos(sx(a1)))},${f(y + R * Math.sin(sx(a1)))}" fill="none" stroke="${GOLD}" stroke-width="1.6"/>` + out;
  };

  // wax seal with ribbon tails
  const seal = (x, y, r) => {
    const pts = [];
    for (let k = 0; k < 36; k++) {
      const a = k / 36 * Math.PI * 2;
      const rr = r * (1 + 0.045 * Math.sin(a * 5 + 0.7) + 0.03 * Math.sin(a * 9 + 2.1) + 0.02 * Math.sin(a * 14));
      pts.push([x + rr * Math.cos(a), y + rr * Math.sin(a)]);
    }
    const mid = (p, q) => [(p[0] + q[0]) / 2, (p[1] + q[1]) / 2];
    let d = `M${mid(pts[35], pts[0]).map(f).join(',')}`;
    for (let k = 0; k < 36; k++) { const m = mid(pts[k], pts[(k + 1) % 36]); d += ` Q${f(pts[k][0])},${f(pts[k][1])} ${f(m[0])},${f(m[1])}`; }
    const dots = Array.from({ length: 30 }, (_, k) => { const a = k / 30 * Math.PI * 2; return `<circle cx="${f(x + r * 0.8 * Math.cos(a))}" cy="${f(y + r * 0.8 * Math.sin(a))}" r="1.6" fill="#0e2119" opacity="0.55"/>`; }).join('');
    const ribbon = (dx) => `<path d="M${x + dx * 0.25 * r},${y + r * 0.2} L${x + dx * 0.95 * r},${y + r * 2.0} L${x + dx * 0.7 * r},${y + r * 1.78} L${x + dx * 0.5 * r},${y + r * 2.1} L${x - dx * 0.2 * r},${y + r * 0.35} Z" fill="url(#ribbon)"/>`;
    const ts = r * 0.95;
    return `<ellipse cx="${x + 6}" cy="${y + r * 1.15}" rx="${r * 1.3}" ry="${r * 0.9}" fill="url(#softShadow)"/>
${ribbon(-1)}${ribbon(1)}
<ellipse cx="${x + 6}" cy="${y + 10}" rx="${r * 1.12}" ry="${r * 1.08}" fill="url(#softShadow)"/>
<path d="${d}" fill="url(#wax)"/>
<path d="${d}" fill="none" stroke="#5c8a70" stroke-width="1" opacity="0.35"/>
<circle cx="${x}" cy="${y}" r="${r * 0.7}" fill="url(#waxPress)"/>
<circle cx="${x}" cy="${y}" r="${r * 0.7}" fill="none" stroke="#0e2119" stroke-width="2.4" opacity="0.7"/>
<circle cx="${x + 0.8}" cy="${y + 1.2}" r="${r * 0.7 + 1.6}" fill="none" stroke="#4f7d64" stroke-width="1" opacity="0.6"/>
${dots}
${tree ? `<image href="${tree}" xlink:href="${tree}" x="${f(x - ts / 2)}" y="${f(y - ts * 0.55)}" width="${f(ts)}" height="${f(ts * 275 / 256)}" opacity="0.92"/>` : ''}
<ellipse cx="${f(x - r * 0.35)}" cy="${f(y - r * 0.42)}" rx="${f(r * 0.38)}" ry="${f(r * 0.18)}" transform="rotate(-28 ${f(x - r * 0.35)} ${f(y - r * 0.42)})" fill="url(#gloss)"/>`;
  };

  // medallion with Adam (clipped portrait) — the institution's crest
  const mx = cx, my = 196, mr = 84;
  const pw = mr * 2.35, ph = pw * faceH / faceW;
  const medallion = `<circle cx="${mx}" cy="${my + 6}" r="${mr + 18}" fill="url(#softShadow)"/>
<circle cx="${mx}" cy="${my}" r="${mr + 12}" fill="url(#goldRing)"/>
<circle cx="${mx}" cy="${my}" r="${mr + 12}" fill="none" stroke="#7d5f2e" stroke-width="1" opacity="0.6"/>
<circle cx="${mx}" cy="${my}" r="${mr + 3}" fill="none" stroke="#f3e2b8" stroke-width="1" opacity="0.8"/>
<circle cx="${mx}" cy="${my}" r="${mr}" fill="url(#medal)"/>
${face ? `<image href="${face}" xlink:href="${face}" x="${f(mx - pw / 2)}" y="${f(my - ph * 0.36)}" width="${f(pw)}" height="${f(ph)}" clip-path="url(#medalClip)"/>` : ''}
<circle cx="${mx}" cy="${my}" r="${mr}" fill="none" stroke="#7d5f2e" stroke-width="1.2"/>`;

  const body = c
    ? t(cx, 872, 'تقديراً لإتمامها مع صغيرها') +
      gilt(948, esc(c), { size: fit(c, 66), font: fontName, weight: 700, fill: 'url(#goldText)', edge: '#6d5126', glow: false, dy: 1.2 }) +
      t(cx, 1002, 'سبعَ ليالٍ وسبعَ جملٍ من الحبّ قبل النوم', { size: 27, fill: 'url(#inkSoft)' })
    : t(cx, 868, 'تقديراً لإتمامها سبعَ ليالٍ وسبعَ جملٍ', { size: 30, fill: INK }) +
      t(cx, 918, 'من الحبّ والحضن قبل النوم مع صغيرها', { size: 27 });

  const no = String(serial || '').replace(/[^A-Za-z0-9-]/g, '').slice(0, 16);
  return `<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">
<defs>
 <linearGradient id="paper" x1="0" y1="0" x2="0.3" y2="1"><stop offset="0" stop-color="#fcf8ef"/><stop offset="0.55" stop-color="#f7efdf"/><stop offset="1" stop-color="#eee2c9"/></linearGradient>
 <radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#ffffff" stop-opacity="0.85"/><stop offset="1" stop-color="#ffffff" stop-opacity="0"/></radialGradient>
 <radialGradient id="warm" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#f3dfb2" stop-opacity="0.55"/><stop offset="1" stop-color="#f3dfb2" stop-opacity="0"/></radialGradient>
 <radialGradient id="vignette" cx="0.5" cy="0.48" r="0.72"><stop offset="0.62" stop-color="#c9b38a" stop-opacity="0"/><stop offset="1" stop-color="#a88b58" stop-opacity="0.3"/></radialGradient>
 <linearGradient id="ink" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2f6049"/><stop offset="0.55" stop-color="#1b3a2e"/><stop offset="1" stop-color="#0f2219"/></linearGradient>
 <linearGradient id="inkSoft" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3a6450"/><stop offset="1" stop-color="#1f3d31"/></linearGradient>
 <linearGradient id="giltEdge" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#9a743a"/><stop offset="0.5" stop-color="#e6cd93"/><stop offset="1" stop-color="#9a743a"/></linearGradient>
 <linearGradient id="goldText" x1="0" y1="0" x2="1" y2="0.3"><stop offset="0" stop-color="#8a6630"/><stop offset="0.5" stop-color="#c8a25f"/><stop offset="1" stop-color="#8a6630"/></linearGradient>
 <radialGradient id="textGlow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#f6e4b8" stop-opacity="0.85"/><stop offset="1" stop-color="#f6e4b8" stop-opacity="0"/></radialGradient>
 <linearGradient id="goldRing" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#f2dfae"/><stop offset="0.35" stop-color="#c9a160"/><stop offset="0.65" stop-color="#a47b3d"/><stop offset="1" stop-color="#e8cf96"/></linearGradient>
 <linearGradient id="leaf" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#b48b4c"/><stop offset="1" stop-color="#d9bb80"/></linearGradient>
 <radialGradient id="medal" cx="0.5" cy="0.4" r="0.6"><stop offset="0" stop-color="#2f5b47"/><stop offset="1" stop-color="#16302a"/></radialGradient>
 <clipPath id="medalClip"><circle cx="${mx}" cy="${my}" r="${mr}"/></clipPath>
 <radialGradient id="wax" cx="0.36" cy="0.32" r="0.75"><stop offset="0" stop-color="#3f6b55"/><stop offset="0.45" stop-color="#244a39"/><stop offset="1" stop-color="#11271d"/></radialGradient>
 <radialGradient id="waxPress" cx="0.6" cy="0.65" r="0.7"><stop offset="0" stop-color="#2c5442"/><stop offset="1" stop-color="#18352a"/></radialGradient>
 <radialGradient id="gloss" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#ffffff" stop-opacity="0.16"/><stop offset="1" stop-color="#ffffff" stop-opacity="0"/></radialGradient>
 <radialGradient id="softShadow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#1b3a2e" stop-opacity="0.3"/><stop offset="0.7" stop-color="#1b3a2e" stop-opacity="0.07"/><stop offset="1" stop-color="#1b3a2e" stop-opacity="0"/></radialGradient>
 <linearGradient id="ribbon" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#2a4f3f"/><stop offset="1" stop-color="#132a20"/></linearGradient>
 <pattern id="band" x="0" y="0" width="22" height="22" patternUnits="userSpaceOnUse">
  <path d="M11,3 L19,11 L11,19 L3,11 Z" fill="none" stroke="${GOLD}" stroke-width="0.9" opacity="0.75"/>
  <circle cx="11" cy="11" r="1.6" fill="${GOLD}" opacity="0.8"/>
 </pattern>
</defs>
<rect width="${W}" height="${H}" fill="url(#paper)"/>
<ellipse cx="${cx}" cy="560" rx="560" ry="520" fill="url(#glow)"/>
<ellipse cx="${cx}" cy="230" rx="300" ry="230" fill="url(#warm)"/>
${rosette(330, 118, cx, 800, 24, 0.075)}${rosette(200, 70, cx, 800, 18, 0.06)}
<rect width="${W}" height="${H}" fill="url(#vignette)"/>

<!-- border: hairline, patterned band, double inner hairline, corner rosettes -->
<rect x="28.5" y="28.5" width="${W - 57}" height="${H - 57}" fill="none" stroke="${GOLD}" stroke-width="1.2"/>
<path fill-rule="evenodd" d="M34,34 H${W - 34} V${H - 34} H34 Z M56,56 V${H - 56} H${W - 56} V56 Z" fill="url(#band)"/>
<rect x="34.5" y="34.5" width="${W - 69}" height="${H - 69}" fill="none" stroke="${GOLD}" stroke-width="0.8"/>
<rect x="56.5" y="56.5" width="${W - 113}" height="${H - 113}" fill="none" stroke="${GOLD}" stroke-width="1.4"/>
<rect x="64.5" y="64.5" width="${W - 129}" height="${H - 129}" fill="none" stroke="${GOLD}" stroke-width="0.6" opacity="0.7"/>
${[[45, 45], [W - 45, 45], [45, H - 45], [W - 45, H - 45]].map(([x, y]) => `<rect x="${x - 15}" y="${y - 15}" width="30" height="30" fill="#f7efdf"/><rect x="${x - 15.5}" y="${y - 15.5}" width="31" height="31" fill="none" stroke="${GOLD}" stroke-width="1"/>${dia(x, y, 9)}<circle cx="${x}" cy="${y}" r="2.4" fill="#f7efdf"/>`).join('')}

${laurel(mx, my, mr + 34, -1)}${laurel(mx, my, mr + 34, 1)}
${medallion}

${t(cx, 372, 'آدم · ما لا يقوله طفلك', { size: 22, fill: 'url(#goldText)' })}
${gilt(486, 'بطاقة تهنئة', { size: 148, font: fontTitle })}
${ornament(546)}
${t(cx, 594, 'تحدّي «أمٌّ تعود» — سبع ليالٍ وسبع جمل', { size: 27, fill: 'url(#goldText)' })}

${t(cx, 672, 'تتشرّف عائلة آدم بأن تمنح هذه البطاقة إلى', { size: 28 })}
${gilt(776, esc(n), { size: fit(n, 98), font: fontBlack, weight: 900, dy: 1.6 })}
<rect x="${cx - 230}" y="810" width="460" height="1" fill="${GOLD}" opacity="0.8"/>${dia(cx, 810.5, 4)}
${body}

<!-- signatures -->
${t(820, 1128, 'نور', { size: 40, font: fontOld, fill: 'url(#ink)', weight: 700 })}
<rect x="700" y="1146" width="240" height="1" fill="${INK}" opacity="0.55"/>
${t(820, 1178, 'مرافِقة التحدّي', { size: 20 })}
${t(260, 1128, 'فريق آدم', { size: 40, font: fontOld, fill: 'url(#ink)', weight: 700 })}
<rect x="140" y="1146" width="240" height="1" fill="${INK}" opacity="0.55"/>
${t(260, 1178, 'الإشراف التربوي', { size: 20 })}

${seal(cx, 1125, 62)}

${t(150, 1262, esc(date), { size: 19, anchor: 'middle' })}
${no ? `<text direction="ltr" x="930" y="1262" text-anchor="middle" font-family="${fontText}, Amiri" font-size="19" fill="${SOFT}">No. ${esc(no)}</text>` : ''}
</svg>`;
}
