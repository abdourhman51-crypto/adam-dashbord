export const MAX_LEAVES = 40;

export interface LeafPosition {
  leftPct: number;
  topPct: number;
  rotateDeg: number;
  sizePx: number;
}

/** توزيع ثابت-عشوائي (نفس الفهرس = نفس المكان دائماً) بمنطقة تاج الشجرة العلوي. */
export function leafPosition(index: number): LeafPosition {
  const h = (n: number) => {
    const x = Math.sin(n * 12.9898) * 43758.5453;
    return x - Math.floor(x);
  };
  return {
    leftPct: 12 + h(index * 3.1) * 76,
    topPct: 4 + h(index * 7.7 + 1) * 46,
    rotateDeg: h(index * 5.3 + 2) * 360,
    sizePx: 10 + h(index * 2.1 + 3) * 8,
  };
}
