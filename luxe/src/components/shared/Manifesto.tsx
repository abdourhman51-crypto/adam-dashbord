import { useLayoutEffect, useRef } from "react";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import "./Manifesto.css";

gsap.registerPlugin(ScrollTrigger);

const LINES = ["Un objet.", "Une lumière.", "Un regard."];

/** Editorial interlude — three engraved lines under a gold rule. */
export function Manifesto() {
  const rootRef = useRef<HTMLElement>(null);

  useLayoutEffect(() => {
    const root = rootRef.current;
    if (!root) return;

    const ctx = gsap.context(() => {
      gsap.fromTo(
        ".manifesto__rule",
        { scaleX: 0 },
        {
          scaleX: 1,
          duration: 1.6,
          ease: "power3.out",
          scrollTrigger: { trigger: root, start: "top 76%" },
        },
      );
      gsap.fromTo(
        ".manifesto__line i",
        { yPercent: 118, rotate: 3, filter: "blur(10px)" },
        {
          yPercent: 0,
          rotate: 0,
          filter: "blur(0px)",
          duration: 1.5,
          stagger: 0.16,
          ease: "power3.out",
          scrollTrigger: { trigger: root, start: "top 72%" },
        },
      );
      gsap.fromTo(
        ".manifesto__note",
        { opacity: 0, y: 24 },
        {
          opacity: 1,
          y: 0,
          duration: 1.1,
          delay: 0.5,
          ease: "power2.out",
          scrollTrigger: { trigger: root, start: "top 72%" },
        },
      );
    }, root);

    return () => ctx.revert();
  }, []);

  return (
    <section ref={rootRef} className="manifesto marble-surface">
      <div className="manifesto__inner shell">
        <div className="manifesto__head">
          <span className="label manifesto__kicker">La Maison</span>
          <span className="manifesto__rule" aria-hidden="true" />
        </div>
        <div className="manifesto__grid">
          <h2 className="manifesto__title">
            {LINES.map((line, i) => (
              <span key={line} className={`manifesto__line brand${i === 1 ? " manifesto__line--accent" : ""}`}>
                <i>{line}</i>
              </span>
            ))}
          </h2>
          <p className="manifesto__note">
            Chaque monture est pensée comme une pièce unique — un équilibre entre la matière,
            la lumière et le visage qui la porte. Rien de plus. Rien de moins.
          </p>
        </div>
      </div>
    </section>
  );
}
