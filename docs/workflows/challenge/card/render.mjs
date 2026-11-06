import { Resvg } from '@resvg/resvg-js';
import { cardSvg } from './card.mjs';
import fs from 'fs';
const F = 'node_modules/@expo-google-fonts/';
const fontFiles = [F + 'amiri/400Regular/Amiri_400Regular.ttf', F + 'amiri/700Bold/Amiri_700Bold.ttf', F + 'aref-ruqaa/700Bold/ArefRuqaa_700Bold.ttf'];
const uri = f => 'data:image/png;base64,' + fs.readFileSync(f).toString('base64');
const face = uri('thumb0.png'), tree = uri('thumb1.png');
for (const [i, [name, child]] of [['فاطمة الزهراء', 'مالك'], ['أم محمد', ''], ['أمل', 'عبد الرحمن يوسف']].entries()) {
  const svg = cardSvg({ name, child, date: 'نوفمبر 2026', face, tree, faceW: 213, faceH: 269 });
  const png = new Resvg(svg, { font: { fontFiles, loadSystemFonts: false, defaultFontFamily: 'Amiri' }, fitTo: { mode: 'width', value: 540 } }).render().asPng();
  fs.writeFileSync(`v2_${i}.png`, png); console.log(`v2_${i}.png`, png.length);
}
