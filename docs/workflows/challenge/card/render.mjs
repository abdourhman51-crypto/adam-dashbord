import { Resvg } from '@resvg/resvg-js';
import { cardSvg } from './card.mjs';
import fs from 'fs';
const F = 'node_modules/@expo-google-fonts/';
const fontFiles = ['node_modules/@expo-google-fonts/amiri/700Bold/Amiri_700Bold.ttf', 'fonts/thmanyahsans-Regular.otf', 'fonts/thmanyahsans-Bold.otf', 'fonts/thmanyahsans-Black.otf', 'fonts/thmanyahserifdisplay-Bold.otf', 'fonts/thmanyahserifdisplay-Black.otf', 'fonts/thmanyahseriftext-Regular.otf', 'fonts/thmanyahseriftext-Bold.otf',
  F + 'amiri/400Regular/Amiri_400Regular.ttf', F + 'aref-ruqaa/700Bold/ArefRuqaa_700Bold.ttf'];
const uri = f => 'data:image/png;base64,' + fs.readFileSync(f).toString('base64');
const face = uri('thumb0.png'), tree = uri('thumb1.png');
const cases = [['فاطمة الزهراء', 'مالك'], ['أم محمد', ''], ['أمل', 'عبد الرحمن يوسف']];
for (const [i, [name, child]] of cases.entries()) {
  const svg = cardSvg({ name, child, date: 'نوفمبر 2026', serial: 'W1-4396', face, tree, faceW: 213, faceH: 269 });
  const png = new Resvg(svg, { font: { fontFiles, loadSystemFonts: false, defaultFontFamily: 'Amiri' }, fitTo: { mode: 'width', value: 720 } }).render().asPng();
  fs.writeFileSync(`v3_${i}.png`, png); console.log(`v3_${i}.png`, png.length);
}
