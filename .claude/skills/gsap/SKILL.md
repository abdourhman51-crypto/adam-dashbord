---
name: gsap
description: Use when building animations with GSAP (greensock/GSAP) — tweens, timelines, ScrollTrigger scroll-driven motion, scrubbing/pinning, React integration (useGSAP/gsap.context), easing, performance, and plugin usage (SplitText, Draggable, MorphSVG, etc.).
---

# GSAP — GreenSock Animation Platform

Professional-grade JS animation. Repo: https://github.com/greensock/GSAP · Docs: https://gsap.com/docs

Since the Webflow acquisition, **GSAP and ALL its plugins (SplitText, MorphSVG, DrawSVG, ScrollSmoother, …) are 100% free**, including commercial use. Install everything from the public npm package.

## Install

```bash
npm install gsap
```

```js
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
gsap.registerPlugin(ScrollTrigger); // register every plugin you import
```

## Core API

```js
gsap.to(".box",   { x: 200, opacity: 1, duration: 1, ease: "power3.out" });
gsap.from(".box", { y: 60, opacity: 0 });
gsap.fromTo(".box", { y: 60 }, { y: 0, stagger: 0.1 });
gsap.set(".box", { transformOrigin: "center bottom" }); // no animation

const tl = gsap.timeline({ defaults: { ease: "power2.out" } });
tl.to(".a", { x: 100 })
  .to(".b", { y: 50 }, "-=0.3")   // overlap 0.3s
  .to(".c", { rotate: 45 }, 0.5); // absolute position
```

- Prefer transforms (`x`, `y`, `scale`, `rotate`) and `opacity` — GPU-friendly.
- `stagger: 0.1` or `stagger: { each: 0.1, from: "center" }`.
- Percent-based transforms: `xPercent`, `yPercent` (relative to element size).

## ScrollTrigger essentials

```js
gsap.to(".panel", {
  xPercent: -100,
  scrollTrigger: {
    trigger: ".section",
    start: "top top",      // trigger-edge viewport-edge
    end: "+=200%",
    scrub: true,            // tie progress to scrollbar (number = smoothing secs)
    pin: true,              // pin trigger while active
    anticipatePin: 1,
    invalidateOnRefresh: true,
    onUpdate: (self) => paint(self.progress), // e.g. canvas frame scrubbing
  },
});
```

- Scrubbed timelines: `ease: "none"` on tweens; position everything with absolute timeline coordinates.
- Canvas image-sequence scrubbing: map `self.progress` → frame index, repaint only when the index changes.
- Recalculate after layout shifts: `ScrollTrigger.refresh()`.
- Responsive/conditional setups: `gsap.matchMedia()`.

## React integration

```jsx
import { useGSAP } from "@gsap/react"; // or gsap.context in useLayoutEffect
useGSAP(() => {
  gsap.from(".card", { y: 40, opacity: 0, stagger: 0.1 });
}, { scope: containerRef }); // selectors scoped; auto-cleanup
```

Manual pattern: `const ctx = gsap.context(() => {...}, rootEl); return () => ctx.revert();`

## Smooth scrolling pairing (Lenis)

```js
lenis.on("scroll", ScrollTrigger.update);
gsap.ticker.add((t) => lenis.raf(t * 1000));
gsap.ticker.lagSmoothing(0);
```

## Gotchas

- Never animate the same property of the same element from two competing tweens; use `overwrite: "auto"` or timelines.
- SSR: guard with `typeof window !== "undefined"`; run in effects only.
- Respect `prefers-reduced-motion` — branch with `gsap.matchMedia()`.
- Kill on unmount: `ctx.revert()` / `st.kill()` to avoid leaked pins.
