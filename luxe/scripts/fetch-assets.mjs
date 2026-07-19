/**
 * Build-time asset fetch.
 *
 * The MCP file-tree deployment ships source only; the imagery lives
 * in the repository. This script pulls the public assets down before
 * `vite build` so they are bundled into dist/ and served from the
 * deployment's own CDN. Skips files that already exist locally.
 */
import { mkdir, writeFile, access } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const BASE =
  "https://raw.githubusercontent.com/abdourhman51-crypto/adam-dashbord/claude/magicui-install-skill-vxwkll/luxe/public";

const products = [
  "monolithe-front.png",
  "monolithe-quarter.png",
  "monolithe-back.png",
  "ovale-front.png",
  "ovale-quarter.png",
  "bordeaux-quarter.png",
].map((f) => `products/${f}`);

const catalogIds = [
  "2222", "2227", "2236", "2217", "2241", "2175", "2180", "2169", "2212", "2202",
  "2207", "2197", "2192", "2187", "2158", "2153", "2147", "2143", "2164", "2137",
];
const catalog = catalogIds.map((id) => `catalog/img_${id}.jpg`);

const exists = (p) => access(p).then(() => true, () => false);

async function fetchAsset(rel) {
  const dest = join(root, "public", rel);
  if (await exists(dest)) return;
  const res = await fetch(`${BASE}/${rel}`);
  if (!res.ok) throw new Error(`Failed to fetch ${rel}: ${res.status}`);
  await mkdir(dirname(dest), { recursive: true });
  await writeFile(dest, Buffer.from(await res.arrayBuffer()));
  console.log(`fetched ${rel}`);
}

await Promise.all([...products, ...catalog].map(fetchAsset));
console.log("assets ready");
