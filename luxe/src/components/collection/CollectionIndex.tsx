import { useLayoutEffect, useRef } from "react";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import { catalog } from "@/data/products";
import "./CollectionIndex.css";

gsap.registerPlugin(ScrollTrigger);

/**
 * The index — the maison's clip-on catalogue as an editorial
 * horizontal traverse. Vertical scroll drives lateral motion;
 * the eye reads it like a contact sheet.
 */
export function CollectionIndex() {
  const rootRef = useRef<HTMLElement>(null);

  useLayoutEffect(() => {
    const root = rootRef.current;
    if (!root) return;

    const ctx = gsap.context(() => {
      const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
      if (reduced) return;

      const track = root.querySelector<HTMLElement>(".index__track");
      if (!track) return;

      const distance = () => -(track.scrollWidth - window.innerWidth);

      gsap.to(track, {
        x: distance,
        ease: "none",
        scrollTrigger: {
          trigger: root,
          start: "top top",
          end: () => `+=${track.scrollWidth - window.innerWidth}`,
          pin: true,
          scrub: true,
          anticipatePin: 1,
          invalidateOnRefresh: true,
        },
      });
    }, root);

    return () => ctx.revert();
  }, []);

  return (
    <section ref={rootRef} className="index" aria-label="L'index de la collection">
      <div className="index__track">
        <header className="index__intro">
          <p className="label index__kicker">L'Index</p>
          <h2 className="index__title display">
            Lunettes <em>avec</em> applique
          </h2>
          <p className="index__note">
            Vingt références, quatre montures, une écriture. Catalogue importé de la maison —
            édition actuellement épuisée.
          </p>
          <p className="label index__hint" aria-hidden="true">
            Faites défiler —
          </p>
        </header>

        {catalog.map((item, i) => (
          <article key={item.name} className="index__card">
            <div className="index__frame">
              <img className="index__photo" src={item.image} alt={item.name} loading="lazy" />
              {item.soldOut && <span className="index__tag label">Épuisé</span>}
            </div>
            <div className="index__meta">
              <span className="index__num label">{String(i + 1).padStart(2, "0")}</span>
              <div>
                <h3 className="index__name">
                  {item.ref} <span className="index__colorway">{item.colorway}</span>
                </h3>
                <p className="index__price">
                  {item.price} <s>{item.wasPrice}</s>
                </p>
              </div>
            </div>
          </article>
        ))}

        <footer className="index__outro">
          <p className="index__outro-line display-italic">La suite s'écrit bientôt.</p>
          <p className="label index__outro-kicker">Collection 2026 — à venir</p>
        </footer>
      </div>
    </section>
  );
}
