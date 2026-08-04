---
name: tailwindcss
description: Use when styling with Tailwind CSS (tailwindlabs/tailwindcss) — installing/configuring v4 or v3, utility-first patterns, theme customization (@theme / tailwind.config), responsive and state variants, dark mode, and framework setup (Vite, Next.js, PostCSS).
---

# Tailwind CSS

Utility-first CSS framework. Repo: https://github.com/tailwindlabs/tailwindcss · Docs: https://tailwindcss.com/docs

## Version check first

Look at `package.json` before writing config:

- **v4 (current)** — CSS-first configuration. No `tailwind.config.js` needed; no `content` array (automatic detection); config lives in CSS via `@theme`.
- **v3 (legacy)** — JS config (`tailwind.config.js`) with `content` globs and `theme.extend`.

## Install — v4

Vite:
```bash
npm install tailwindcss @tailwindcss/vite
```
```js
// vite.config.ts
import tailwindcss from "@tailwindcss/vite";
export default { plugins: [tailwindcss()] };
```
```css
/* app.css */
@import "tailwindcss";
```

PostCSS (Next.js etc.):
```bash
npm install tailwindcss @tailwindcss/postcss
```
```js
// postcss.config.mjs
export default { plugins: { "@tailwindcss/postcss": {} } };
```

## Customize — v4 (@theme in CSS)

```css
@import "tailwindcss";

@theme {
  --color-brand: #a8853e;
  --font-display: "Yeseva One", serif;
  --breakpoint-3xl: 1920px;
  --spacing-18: 4.5rem;
}
```
Theme variables generate utilities (`bg-brand`, `font-display`, `3xl:`) and are exposed as native CSS variables. Arbitrary values: `w-[37vw]`, `bg-[color:var(--gold)]`. Custom utilities: `@utility`. Component layer: `@layer components { .btn { @apply px-6 py-3 rounded-full; } }`.

## Customize — v3 (tailwind.config.js)

```js
module.exports = {
  content: ["./src/**/*.{js,ts,jsx,tsx,html}"],
  darkMode: "class",
  theme: { extend: { colors: { brand: "#a8853e" } } },
  plugins: [],
};
```
Entry CSS uses `@tailwind base; @tailwind components; @tailwind utilities;`

## Core conventions

- Mobile-first responsive prefixes: `md:grid-cols-2 lg:gap-8` (min-width). v4 adds `max-md:` ranges.
- State variants: `hover:`, `focus-visible:`, `group-hover:`, `data-[state=open]:`, `aria-expanded:`.
- Dark mode: `dark:` (media by default; class strategy via config/`@custom-variant`).
- Prefer design tokens over arbitrary values; prefer utilities over `@apply`-heavy CSS.
- Class merging in React: use `clsx` + `tailwind-merge` for conditional classes.

## Gotchas

- v3→v4: `@tailwind` directives are replaced by `@import "tailwindcss"`; many scale defaults changed — run `npx @tailwindcss/upgrade`.
- Don't build class names dynamically by string concatenation (`bg-${color}-500` is invisible to the scanner); map to full literal class strings instead.
- A parent repo's PostCSS config can leak into nested apps — give sub-apps their own PostCSS config.
