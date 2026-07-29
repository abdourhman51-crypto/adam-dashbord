/**
 * Content imported from the reference catalogue (luxels.co) —
 * names, pricing and imagery — presented inside an original
 * experience. The three hero objects use studio cutouts shot
 * from multiple angles.
 */

export interface HeroProduct {
  id: string;
  index: string;
  name: string;
  variant: string;
  price: string;
  wasPrice: string;
  narrative: string;
  details: string[];
  /** Ordered viewing angles — scrubbed by scroll to suggest rotation */
  angles: { src: string; alt: string }[];
  theme: "plaster" | "noir" | "oxblood";
}

export const heroProducts: HeroProduct[] = [
  {
    id: "monolithe",
    index: "01",
    name: "Monolithe",
    variant: "Noir · Verre Ambre",
    price: "4 800 د.ج",
    wasPrice: "9 000 د.ج",
    narrative:
      "Une géométrie franche, taillée dans l'acétate noir. Le verre ambré réchauffe tout ce qu'il regarde.",
    details: ["Acétate poli main", "Verre ambre · UV400", "Charnières rivetées", "Ajustement universel"],
    angles: [
      { src: "/products/monolithe-front.png", alt: "Monolithe — vue de face" },
      { src: "/products/monolithe-quarter.png", alt: "Monolithe — vue de trois quarts" },
      { src: "/products/monolithe-back.png", alt: "Monolithe — vue arrière" },
    ],
    theme: "plaster",
  },
  {
    id: "ovale",
    index: "02",
    name: "Ovale",
    variant: "Noir Total",
    price: "4 800 د.ج",
    wasPrice: "9 000 د.ج",
    narrative:
      "Une courbe continue, sculpturale, presque liquide. L'ombre portée comme un vêtement.",
    details: ["Monture galbée une pièce", "Verre fumé neutre", "Surface laquée profonde", "Silhouette enveloppante"],
    angles: [
      { src: "/products/ovale-front.png", alt: "Ovale — vue de face" },
      { src: "/products/ovale-quarter.png", alt: "Ovale — vue de trois quarts" },
    ],
    theme: "noir",
  },
  {
    id: "bordeaux",
    index: "03",
    name: "Bordeaux",
    variant: "Oxblood · Verre Prune",
    price: "4 800 د.ج",
    wasPrice: "9 000 د.ج",
    narrative:
      "L'acétate bordeaux, profond comme un vin de garde. Une pièce de caractère, portée par la lumière du soir.",
    details: ["Acétate oxblood massif", "Verre prune dégradé", "Rivets apparents", "Édition mesurée"],
    angles: [{ src: "/products/bordeaux-quarter.png", alt: "Bordeaux — vue de trois quarts" }],
    theme: "oxblood",
  },
];

export interface CatalogItem {
  name: string;
  ref: string;
  colorway: string;
  price: string;
  wasPrice: string;
  image: string;
  soldOut: boolean;
}

const mk = (ref: string, colorway: string, img: string): CatalogItem => ({
  name: `Lunette Clip-On ${ref} ${colorway}`,
  ref,
  colorway,
  price: "4 800 د.ج",
  wasPrice: "9 000 د.ج",
  image: `/catalog/img_${img}.jpg`,
  soldOut: true,
});

/** Catalogue « Lunettes avec applique » — importé de luxels.co */
export const catalog: CatalogItem[] = [
  mk("AC9091", "C12 Bleu", "2222"),
  mk("AC9091", "C11 Rose", "2227"),
  mk("AC9091", "C4 Transparent", "2236"),
  mk("AC9091", "C3 Gris", "2217"),
  mk("AC9091", "C1 Noir", "2241"),
  mk("AC9095", "C4 Transparent", "2175"),
  mk("AC9095", "C3 Gris", "2180"),
  mk("AC9095", "C2 Léopard", "2169"),
  mk("AC9098", "C12 Bleu", "2212"),
  mk("AC9098", "C11 Rose", "2202"),
  mk("AC9098", "C6 Gris Motif", "2207"),
  mk("AC9098", "C4 Transparent", "2197"),
  mk("AC9098", "C3 Gris", "2192"),
  mk("AC9098", "C1 Noir", "2187"),
  mk("AC9102", "C15 Mauve", "2158"),
  mk("AC9102", "C6 Gris Motif", "2153"),
  mk("AC9102", "C4 Transparent", "2147"),
  mk("AC9102", "C3 Gris", "2143"),
  mk("AC9102", "C2 Léopard", "2164"),
  mk("AC9102", "C1 Noir", "2137"),
];

export interface NavItem {
  label: string;
  sub?: string[];
}

/** Navigation structure inherited from the maison's existing site */
export const navigation: NavItem[] = [
  { label: "Accueil" },
  { label: "Lunettes de soleil", sub: ["Collection Alpha", "Toutes les lunettes de soleil"] },
  { label: "Lunettes avec applique" },
  { label: "Lunettes de vue", sub: ["Anti-lumière bleue", "Montures de vue"] },
  { label: "Bien choisir mes lunettes" },
  { label: "Frais & délais de livraison" },
  { label: "Contact" },
];
