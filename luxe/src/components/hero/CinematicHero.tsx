import { useLayoutEffect, useRef } from "react";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import "./CinematicHero.css";

gsap.registerPlugin(ScrollTrigger);

/**
 * The hero is a scroll-scrubbed film in two scenes.
 *
 * On load: perfect stillness — the wordmark, one line, nothing moves.
 * Scroll begins the story. Scene one (Elle) lives in warm plaster
 * light; a continuous colour-grade shift carries us into scene two
 * (Lui), in stone and shadow. The scrub is exact: when scrolling
 * stops, the film stops. No autoplay, no loop, no controls.
 */
export function CinematicHero() {
  const rootRef = useRef<HTMLElement>(null);

  useLayoutEffect(() => {
    const root = rootRef.current;
    if (!root) return;

    const ctx = gsap.context(() => {
      const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

      /* — Arrival: one slow fade, then stillness — */
      gsap.fromTo(
        ".hero__opening > *",
        { opacity: 0, y: 26, filter: "blur(6px)" },
        {
          opacity: 1,
          y: 0,
          filter: "blur(0px)",
          duration: reduced ? 0 : 1.6,
          stagger: reduced ? 0 : 0.14,
          ease: "power3.out",
          delay: 0.15,
        },
      );

      if (reduced) {
        gsap.set([".hero__scene--elle", ".hero__scene--lui", ".hero__finale"], { opacity: 1 });
        return;
      }

      /* — The film: one timeline, scrubbed by scroll — */
      const tl = gsap.timeline({
        defaults: { ease: "none" },
        scrollTrigger: {
          trigger: root,
          start: "top top",
          end: "+=420%",
          pin: ".hero__stage",
          scrub: true,
          anticipatePin: 1,
        },
      });

      /* Opening dissolves upward */
      tl.to(".hero__opening", { opacity: 0, y: -80, filter: "blur(8px)", duration: 0.1 }, 0.02)
        .set(".hero__opening", { visibility: "hidden" }, 0.13)

        /* Grade shift: noir → plaster */
        .to(".hero__bg--plaster", { opacity: 1, duration: 0.1 }, 0.08)

        /* Scene one — Elle */
        .fromTo(
          ".hero__scene--elle .hero__word",
          { y: "55%", opacity: 0, filter: "blur(14px)" },
          { y: "0%", opacity: 1, filter: "blur(0px)", duration: 0.12, ease: "power1.out" },
          0.12,
        )
        .fromTo(
          ".hero__scene--elle .hero__chapter",
          { opacity: 0, y: 30 },
          { opacity: 1, y: 0, duration: 0.08 },
          0.16,
        )
        .fromTo(
          ".hero__scene--elle .hero__object",
          { y: "60vh", rotate: -16, opacity: 0 },
          { y: "0vh", rotate: -5, opacity: 1, duration: 0.16, ease: "power1.out" },
          0.14,
        )
        .fromTo(
          ".hero__scene--elle .hero__copy i",
          { yPercent: 110 },
          { yPercent: 0, duration: 0.08, stagger: 0.02, ease: "power1.out" },
          0.2,
        )
        /* Elle breathes — slow drift while the scene holds */
        .to(".hero__scene--elle .hero__object", { rotate: 2, y: "-4vh", duration: 0.18 }, 0.3)
        .to(".hero__scene--elle .hero__word", { xPercent: -4, duration: 0.18 }, 0.3)

        /* Scene one exits upward; the light dies */
        .to(".hero__scene--elle", { y: "-55vh", opacity: 0, filter: "blur(10px)", duration: 0.13, ease: "power1.in" }, 0.5)
        .to(".hero__bg--plaster", { opacity: 0, duration: 0.12 }, 0.52)
        .to(".hero__bg--smoke", { opacity: 1, duration: 0.12 }, 0.54)

        /* Scene two — Lui */
        .fromTo(
          ".hero__scene--lui .hero__word",
          { y: "55%", opacity: 0, filter: "blur(14px)" },
          { y: "0%", opacity: 1, filter: "blur(0px)", duration: 0.12, ease: "power1.out" },
          0.62,
        )
        .fromTo(
          ".hero__scene--lui .hero__chapter",
          { opacity: 0, y: 30 },
          { opacity: 1, y: 0, duration: 0.08 },
          0.66,
        )
        .fromTo(
          ".hero__scene--lui .hero__object",
          { x: "-55vw", rotate: 10, opacity: 0 },
          { x: "0vw", rotate: 0, opacity: 1, duration: 0.16, ease: "power1.out" },
          0.64,
        )
        .fromTo(
          ".hero__scene--lui .hero__copy i",
          { yPercent: 110 },
          { yPercent: 0, duration: 0.08, stagger: 0.02, ease: "power1.out" },
          0.7,
        )
        /* Lui holds, breathing */
        .to(".hero__scene--lui .hero__object", { rotate: -3, y: "-3vh", duration: 0.16 }, 0.8)
        .to(".hero__scene--lui .hero__word", { xPercent: 4, duration: 0.16 }, 0.8)

        /* Finale — invitation to the collection */
        .fromTo(
          ".hero__finale",
          { opacity: 0, y: 40 },
          { opacity: 1, y: 0, duration: 0.1, ease: "power1.out" },
          0.9,
        );
    }, root);

    return () => ctx.revert();
  }, []);

  return (
    <section ref={rootRef} className="hero" aria-label="Introduction cinématique">
      <div className="hero__stage">
        <div className="hero__bg hero__bg--plaster" aria-hidden="true" />
        <div className="hero__bg hero__bg--smoke" aria-hidden="true" />

        {/* — Opening: still, elegant, minimal — */}
        <div className="hero__opening">
          <p className="label hero__eyebrow">Maison de lunetterie — Alger</p>
          <h1 className="hero__wordmark display">
            LUXELS<span className="hero__wordmark-tm">™</span>
          </h1>
          <p className="hero__tagline display-italic">Look different.</p>
          <div className="hero__cue" aria-hidden="true">
            <span className="label">Faites défiler</span>
            <span className="hero__cue-line" />
          </div>
        </div>

        {/* — Scene one : Elle — */}
        <div className="hero__scene hero__scene--elle" aria-hidden="true">
          <p className="hero__chapter label">Scène 01 — La lumière</p>
          <span className="hero__word display-italic">Elle</span>
          <img
            className="hero__object hero__object--elle"
            src="/products/monolithe-quarter.png"
            alt=""
            loading="eager"
          />
          <p className="hero__copy">
            <span><i>La lumière la précède.</i></span>
            <span><i>Le verre ambré réchauffe son regard.</i></span>
          </p>
        </div>

        {/* — Scene two : Lui — */}
        <div className="hero__scene hero__scene--lui" aria-hidden="true">
          <p className="hero__chapter label">Scène 02 — L'ombre</p>
          <span className="hero__word display-italic">Lui</span>
          <img
            className="hero__object hero__object--lui"
            src="/products/ovale-quarter.png"
            alt=""
            loading="eager"
          />
          <p className="hero__copy">
            <span><i>L'ombre le suit.</i></span>
            <span><i>Une courbe noire, absolue.</i></span>
          </p>
        </div>

        {/* — Finale — */}
        <div className="hero__finale">
          <p className="label hero__finale-kicker">Une histoire, trois objets</p>
          <p className="hero__finale-title display">La Collection</p>
        </div>
      </div>
    </section>
  );
}
