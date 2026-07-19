import { useLayoutEffect, useRef } from "react";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import type { HeroProduct } from "@/data/products";
import { MagneticButton } from "@/components/shared/MagneticButton";
import "./ProductStage.css";

gsap.registerPlugin(ScrollTrigger);

interface ProductStageProps {
  product: HeroProduct;
  flip?: boolean;
}

/**
 * Each object gets a launch: a pinned scene where scroll turns the
 * piece in hand (angle cutouts scrubbed in sequence), while the
 * dossier — name, matter, price — settles around it.
 */
export function ProductStage({ product, flip = false }: ProductStageProps) {
  const rootRef = useRef<HTMLElement>(null);

  useLayoutEffect(() => {
    const root = rootRef.current;
    if (!root) return;

    const ctx = gsap.context(() => {
      const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
      const angles = gsap.utils.toArray<HTMLElement>(".stage__angle", root);

      if (reduced) {
        gsap.set(root.querySelectorAll(".stage__numeral, .stage__dossier > *, .stage__object"), {
          opacity: 1,
          clearProps: "transform",
        });
        if (angles.length) gsap.set(angles[0], { opacity: 1 });
        return;
      }

      const tl = gsap.timeline({
        defaults: { ease: "none" },
        scrollTrigger: {
          trigger: root,
          start: "top top",
          end: "+=240%",
          pin: ".stage__frame",
          scrub: true,
          anticipatePin: 1,
        },
      });

      /* The numeral rises behind everything, slower than the scroll */
      tl.fromTo(
        ".stage__numeral",
        { yPercent: 40, opacity: 0 },
        { yPercent: -6, opacity: 0.9, duration: 0.5, ease: "power1.out" },
        0,
      )

        /* The object arrives — weighted, floating */
        .fromTo(
          ".stage__object",
          { y: "50vh", rotate: flip ? 9 : -9, opacity: 0 },
          { y: "0vh", rotate: 0, opacity: 1, duration: 0.22, ease: "power1.out" },
          0.04,
        )

        /* Dossier settles in */
        .fromTo(
          ".stage__dossier > *",
          { y: 44, opacity: 0 },
          { y: 0, opacity: 1, duration: 0.14, stagger: 0.028, ease: "power1.out" },
          0.12,
        );

      /* Scroll turns the object — angle cutouts in sequence */
      if (angles.length > 1) {
        const turnStart = 0.34;
        const turnSpan = 0.5;
        const step = turnSpan / angles.length;
        angles.forEach((angle, i) => {
          if (i === 0) return;
          const at = turnStart + step * i;
          tl.to(angles[i - 1], { opacity: 0, scale: 0.985, duration: 0.05 }, at);
          tl.fromTo(
            angle,
            { opacity: 0, scale: 1.015 },
            { opacity: 1, scale: 1, duration: 0.05 },
            at,
          );
        });
        /* a slow drift through the whole turn keeps it alive */
        tl.to(".stage__object", { y: "-4vh", rotate: flip ? -2 : 2, duration: turnSpan + 0.1 }, turnStart);
      } else {
        /* single angle: levitation and a slow lean instead */
        tl.to(".stage__object", { y: "-6vh", rotate: flip ? -4 : 4, duration: 0.55 }, 0.35);
      }

      /* The shadow answers the float */
      tl.fromTo(
        ".stage__shadow",
        { opacity: 0, scaleX: 0.7 },
        { opacity: 1, scaleX: 1, duration: 0.2 },
        0.1,
      ).to(".stage__shadow", { scaleX: 0.82, opacity: 0.55, duration: 0.5 }, 0.4);
    }, root);

    return () => ctx.revert();
  }, [flip, product.angles.length]);

  return (
    <section
      ref={rootRef}
      className={`stage stage--${product.theme}${flip ? " stage--flip" : ""}`}
      aria-label={`${product.name} — ${product.variant}`}
    >
      <div className="stage__frame">
        <span className="stage__numeral display" aria-hidden="true">
          {product.index}
        </span>

        <div className="stage__object">
          {product.angles.map((angle, i) => (
            <img
              key={angle.src}
              className="stage__angle"
              src={angle.src}
              alt={i === 0 ? angle.alt : ""}
              style={{ opacity: i === 0 ? 1 : 0 }}
              loading="lazy"
            />
          ))}
          <span className="stage__shadow" aria-hidden="true" />
        </div>

        <div className="stage__dossier">
          <p className="label stage__kicker">
            N° {product.index} — {product.variant}
          </p>
          <h2 className="stage__name display">{product.name}</h2>
          <p className="stage__narrative">{product.narrative}</p>
          <ul className="stage__details">
            {product.details.map((d) => (
              <li key={d} className="stage__detail">
                {d}
              </li>
            ))}
          </ul>
          <div className="stage__commerce">
            <p className="stage__price">
              <span className="stage__price-now">{product.price}</span>
              <s className="stage__price-was">{product.wasPrice}</s>
            </p>
            <MagneticButton variant={product.theme === "plaster" ? "light" : "dark"} ariaLabel={`Découvrir ${product.name}`}>
              Découvrir
            </MagneticButton>
          </div>
        </div>
      </div>
    </section>
  );
}
