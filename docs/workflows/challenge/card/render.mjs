import { Resvg } from '@resvg/resvg-js';
import { cardSvg } from './card.mjs';
import fs from 'fs';
const F = 'node_modules/@expo-google-fonts/';
const fontFiles = [F + 'amiri/400Regular/Amiri_400Regular.ttf', F + 'amiri/700Bold/Amiri_700Bold.ttf', F + 'aref-ruqaa/700Bold/ArefRuqaa_700Bold.ttf', F + 'reem-kufi/600SemiBold/ReemKufi_600SemiBold.ttf'];
for (const [i, name] of ['فاطمة الزهراء', 'أم محمد', 'أمل ومالك', 'Sara Benali'].entries()) {
  const svg = cardSvg({ name, date: 'نوفمبر 2026' });
  const png = new Resvg(svg, { font: { fontFiles, loadSystemFonts: false, defaultFontFamily: 'Amiri' }, fitTo: { mode: 'width', value: 1080 } }).render().asPng();
  fs.writeFileSync(`card${i}.png`, png); console.log(`card${i}.png`, png.length);
}
