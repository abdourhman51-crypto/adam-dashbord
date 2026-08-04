import { useLayoutEffect, useRef } from "react";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import { useFilmSequence } from "./useFilmSequence";
import { Medallion } from "@/components/shared/Medallion";
import "./CinematicHero.css";

gsap.registerPlugin(ScrollTrigger);

const ELLE_FRAMES = 101;
const LUI_FRAMES = 61;

/* Timeline geography — one scroll, two reels, one story */
const SEG = {
  openingEnd: 0.1,
  elleStart: 0.08,
  elleEnd: 0.5,
  crossStart: 0.5,
  crossEnd: 0.58,
  luiStart: 0.56,
  luiEnd: 0.92,
  finale: 0.9,
};

/**
 * The hero is the campaign film itself, scrubbed by scroll.
 *
 * Both reels are decomposed into frame sequences and painted onto
 * canvases — scroll position IS the playhead. Still on load; the
 * story only moves when the visitor moves. Stop scrolling and the
 * film holds its breath. No autoplay, no loop, no controls.
 */
export function CinematicHero() {
  const rootRef = useRef<HTMLElement>(null);
  const elle = useFilmSequence("/film/elle", ELLE_FRAMES);
  const lui = useFilmSequence("/film/lui", LUI_FRAMES);

  useLayoutEffect(() => {
    const root = rootRef.current;
    if (!root) return;

    const drawElle = elle.draw;
    const drawLui = lui.draw;

    const ctx = gsap.context(() => {
      const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

      /* — Arrival: one slow breath, then stillness — */
      gsap.fromTo(
        ".hero__opening > *",
        { opacity: 0, y: 30, filter: "blur(8px)" },
        {
          opacity: 1,
          y: 0,
          filter: "blur(0px)",
          duration: reduced ? 0 : 1.8,
          stagger: reduced ? 0 : 0.16,
          ease: "power3.out",
          delay: 0.2,
        },
      );
      gsap.fromTo(
        ".hero__cell",
        { opacity: 0, scale: 0.94, filter: "brightness(0.55) blur(6px)" },
        {
          opacity: 1,
          scale: 0.96,
          filter: "brightness(0.62) blur(0px)",
          duration: reduced ? 0 : 2.2,
          ease: "power3.out",
          delay: 0.1,
        },
      );

      if (reduced) {
        gsap.set(".hero__cell", { opacity: 1, scale: 1, filter: "brightness(1)" });
        gsap.set([".hero__scene-type--elle", ".hero__finale"], { opacity: 1 });
        drawElle(0);
        return;
      }

      const scrub = { p: 0 };

      const tl = gsap.timeline({
        defaults: { ease: "none" },
        scrollTrigger: {
          trigger: root,
          start: "top top",
          end: "+=520%",
          pin: ".hero__stage",
          scrub: true,
          anticipatePin: 1,
          onUpdate: (self) => {
            /* scroll is the playhead */
            const p = self.progress;
            if (p <= SEG.crossEnd) {
              const fp = gsap.utils.clamp(0, 1, (p - SEG.elleStart) / (SEG.elleEnd - SEG.elleStart));
              drawElle(fp);
            }
            if (p >= SEG.crossStart) {
              const fp = gsap.utils.clamp(0, 1, (p - SEG.luiStart) / (SEG.luiEnd - SEG.luiStart));
              drawLui(fp);
            }
          },
        },
      });

      tl.to(scrub, { p: 1, duration: 1 }, 0);

      /* Opening type dissolves; the reel wakes into full light */
      tl.to(".hero__opening", { opacity: 0, y: -90, filter: "blur(10px)", duration: 0.08 }, 0.015)
        .set(".hero__opening", { visibility: "hidden" }, SEG.openingEnd)
        .to(
          ".hero__cell",
          { scale: 1, filter: "brightness(1) blur(0px)", duration: 0.09, ease: "power1.inOut" },
          0.02,
        )

        /* Scene one — Elle. The word slides past behind the reel. */
        .fromTo(
          ".hero__word--elle",
          { xPercent: 14, opacity: 0 },
          { xPercent: 8, opacity: 1, duration: 0.08, ease: "power1.out" },
          SEG.elleStart + 0.02,
        )
        .to(".hero__word--elle", { xPercent: -10, duration: SEG.elleEnd - SEG.elleStart - 0.1 }, SEG.elleStart + 0.1)
        .fromTo(
          ".hero__scene-type--elle .hero__chapter",
          { opacity: 0, y: 26 },
          { opacity: 1, y: 0, duration: 0.05 },
          SEG.elleStart + 0.04,
        )
        .fromTo(
          ".hero__scene-type--elle .hero__copy i",
          { yPercent: 115 },
          { yPercent: 0, duration: 0.06, stagger: 0.018, ease: "power1.out" },
          SEG.elleStart + 0.07,
        )
        .to(
          ".hero__scene-type--elle",
          { opacity: 0, y: -40, filter: "blur(6px)", duration: 0.07, ease: "power1.in" },
          SEG.crossStart - 0.04,
        )
        .to(".hero__word--elle", { opacity: 0, duration: 0.06 }, SEG.crossStart - 0.02)

        /* The cut — a held breath between reels */
        .to(
          ".hero__cell",
          { scale: 0.965, filter: "brightness(0.4) blur(8px)", duration: 0.045, ease: "power1.in" },
          SEG.crossStart,
        )
        .to(".hero__canvas--elle", { opacity: 0, duration: 0.04 }, SEG.crossStart + 0.02)
        .to(
          ".hero__cell",
          { scale: 1, filter: "brightness(1) blur(0px)", duration: 0.05, ease: "power1.out" },
          SEG.crossEnd - 0.04,
        )

        /* Scene two — Lui. Counter-direction, heavier shadow. */
        .fromTo(
          ".hero__word--lui",
          { xPercent: -14, opacity: 0 },
          { xPercent: -8, opacity: 1, duration: 0.08, ease: "power1.out" },
          SEG.luiStart + 0.04,
        )
        .to(".hero__word--lui", { xPercent: 10, duration: SEG.luiEnd - SEG.luiStart - 0.12 }, SEG.luiStart + 0.12)
        .fromTo(
          ".hero__scene-type--lui .hero__chapter",
          { opacity: 0, y: 26 },
          { opacity: 1, y: 0, duration: 0.05 },
          SEG.luiStart + 0.06,
        )
        .fromTo(
          ".hero__scene-type--lui .hero__copy i",
          { yPercent: 115 },
          { yPercent: 0, duration: 0.06, stagger: 0.018, ease: "power1.out" },
          SEG.luiStart + 0.09,
        )

        /* Finale — the reel recedes, the invitation rises */
        .to(
          ".hero__cell",
          { scale: 0.94, filter: "brightness(0.5)", duration: 0.08, ease: "power1.inOut" },
          SEG.finale,
        )
        .to(".hero__scene-type--lui", { opacity: 0, y: -30, duration: 0.06 }, SEG.finale)
        .to(".hero__word--lui", { opacity: 0.14, duration: 0.08 }, SEG.finale)
        .fromTo(
          ".hero__finale",
          { opacity: 0, y: 44 },
          { opacity: 1, y: 0, duration: 0.08, ease: "power1.out" },
          SEG.finale + 0.02,
        );
    }, root);

    return () => ctx.revert();
  }, [elle.draw, lui.draw]);

  return (
    <section ref={rootRef} className="hero" aria-label="Le film de la collection">
      <div className="hero__stage marble-surface">
        <div className="hero__ambient hero__ambient--warm" aria-hidden="true" />
        <div className="hero__ambient hero__ambient--floor" aria-hidden="true" />

        {/* — Giant words, moving behind the reel — */}
        <span className="hero__word hero__word--elle" aria-hidden="true">Elle</span>
        <span className="hero__word hero__word--lui" aria-hidden="true">Lui</span>

        {/* — The reel: portrait film cell, scrubbed by scroll — */}
        <figure className="hero__cell" aria-label="Film de campagne — contrôlé par le défilement">
          <canvas ref={elle.canvasRef} className="hero__canvas hero__canvas--elle" />
          <canvas ref={lui.canvasRef} className="hero__canvas hero__canvas--lui" />
          <span className="hero__cell-edge" aria-hidden="true" />
          <span className="hero__cell-glare" aria-hidden="true" />
        </figure>
        <span className="hero__cell-pool" aria-hidden="true" />

        {/* — Opening: still, monumental — */}
        <div className="hero__opening">
          <Medallion className="hero__seal" size="clamp(84px, 13vh, 128px)" />
          <p className="hero__eyebrow">Maison de lunetterie — Alger</p>
          <h1 className="hero__wordmark">
            LUXELS<span className="hero__wordmark-tm">™</span>
          </h1>
          <p className="hero__tagline">Look different.</p>
          <div className="hero__cue" aria-hidden="true">
            <span className="hero__cue-label">Le film commence quand vous défilez</span>
            <span className="hero__cue-line" />
          </div>
        </div>

        {/* — Scene captions — */}
        <div className="hero__scene-type hero__scene-type--elle" aria-hidden="true">
          <p className="hero__chapter">Scène 01 — La lumière</p>
          <p className="hero__copy">
            <span><i>La lumière la précède.</i></span>
            <span><i>Le verre ambré réchauffe son regard.</i></span>
          </p>
        </div>
        <div className="hero__scene-type hero__scene-type--lui" aria-hidden="true">
          <p className="hero__chapter">Scène 02 — L'ombre</p>
          <p className="hero__copy">
            <span><i>L'ombre le suit.</i></span>
            <span><i>Il ne regarde personne. Tout le monde le regarde.</i></span>
          </p>
        </div>

        {/* — Finale — */}
        <div className="hero__finale">
          <p className="hero__finale-kicker">Une histoire, trois objets</p>
          <p className="hero__finale-title">La Collection</p>
        </div>
      </div>
    </section>
  );
}
