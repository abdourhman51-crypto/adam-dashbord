import { useLayoutEffect, useRef } from "react";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import "./Manifesto.css";

gsap.registerPlugin(ScrollTrigger);

const LINES = ["Un objet.", "Une lumière.", "Un regard."];

/** Editorial interlude — three lines, revealed as the reader arrives. */
export function Manifesto() {
  const rootRef = useRef<HTMLElement>(null);

  useLayoutEffect(() => {
    const root = rootRef.current;
    if (!root) return;

    const ctx = gsap.context(() => {
      gsap.fromTo(
        ".manifesto__line i",
        { yPercent: 115, rotate: 2 },
        {
          yPercent: 0,
          rotate: 0,
          duration: 1.3,
          stagger: 0.14,
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
    <section ref={rootRef} className="manifesto shell">
      <h2 className="manifesto__title">
        {LINES.map((line, i) => (
          <span key={line} className={`manifesto__line display${i === 1 ? " manifesto__line--accent" : ""}`}>
            <i>{line}</i>
          </span>
        ))}
      </h2>
      <p className="manifesto__note">
        Chaque monture est pensée comme une pièce unique — un équilibre entre la matière,
        la lumière et le visage qui la porte. Rien de plus. Rien de moins.
      </p>
    </section>
  );
}
