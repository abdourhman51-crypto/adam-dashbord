---
name: next-optimized-images
description: Use when optimizing images in a Next.js project — importing, compressing, converting (WebP), resizing, inlining or lazy-loading images. Covers the legacy next-optimized-images plugin (cyrilwanner/next-optimized-images) and when to prefer the built-in next/image instead.
---

# next-optimized-images

Image optimization for Next.js via webpack loaders (mozjpeg, optipng, pngquant, svgo, webp, gif). Repo: https://github.com/cyrilwanner/next-optimized-images

## Important status check first

This package targets the **webpack-based Next.js era (Next ≤ 10)** and is no longer actively developed. Before using it:

- **Next.js 10+**: prefer the built-in `next/image` component (automatic resizing, WebP/AVIF, lazy loading, no extra deps). Only use next-optimized-images when the project already depends on it or needs build-time file emission (e.g. static export pipelines with `?url`, `?inline`, `?include` query params).
- **Turbopack / App Router projects**: do NOT add this package; it is webpack-only.

## Install (legacy usage)

```bash
npm install next-optimized-images
# plus only the optimizers you need:
npm install imagemin-mozjpeg imagemin-optipng imagemin-svgo webp-loader
```

`next.config.js`:

```js
const withOptimizedImages = require('next-optimized-images');
module.exports = withOptimizedImages({
  /* optimizedImages options */
  optimizeImagesInDev: false,
});
```

## Usage patterns

Images are imported/required so webpack processes them:

```jsx
<img src={require('./images/hero.jpg')} />
<img src={require('./images/hero.jpg?webp')} />   // convert to WebP
<img src={require('./images/icon.svg?include')} /> // inline raw SVG
<img src={require('./images/small.png?inline')} /> // data-URI inline
const url = require('./images/photo.jpg?url');      // force URL (no inline)
require('./images/banner.jpg?resize&size=800');     // resize (with responsive-loader)
```

Query params: `?webp`, `?inline`, `?include`, `?url`, `?original`, `?lqip` (low-quality placeholder), `?resize&size=W`, `?trace` (SVG trace placeholder).

## Key config options

- `handleImages: ['jpeg','png','svg','webp','gif']`
- `inlineImageLimit: 8192` — files smaller than this become data-URIs
- `mozjpeg: { quality: 80 }`, `pngquant: {...}`, `optipng: {...}`, `webp: { preset: 'default', quality: 75 }`
- `imagesFolder / imagesName` — output naming
- `optimizeImagesInDev: false` — skip optimization in dev for speed

## Modern equivalent (recommended default)

```jsx
import Image from 'next/image';
<Image src="/hero.jpg" alt="" width={1200} height={800} priority />
```

Use `sharp` in production, `sizes` for responsive, `placeholder="blur"` for LQIP.
