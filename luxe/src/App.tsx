import { useEffect, useState } from "react";
import { initSmoothScroll } from "@/lib/smooth-scroll";
import { Header } from "@/components/layout/Header";
import { SideMenu } from "@/components/layout/SideMenu";
import { Footer } from "@/components/layout/Footer";
import { CinematicHero } from "@/components/hero/CinematicHero";
import { Manifesto } from "@/components/shared/Manifesto";
import { ProductStage } from "@/components/products/ProductStage";
import { CollectionIndex } from "@/components/collection/CollectionIndex";
import { heroProducts } from "@/data/products";

export default function App() {
  const [menuOpen, setMenuOpen] = useState(false);

  useEffect(() => initSmoothScroll(), []);

  return (
    <>
      <Header onOpenMenu={() => setMenuOpen(true)} />
      <SideMenu open={menuOpen} onClose={() => setMenuOpen(false)} />

      <main>
        <CinematicHero />
        <Manifesto />
        {heroProducts.map((product, i) => (
          <ProductStage key={product.id} product={product} flip={i % 2 === 1} />
        ))}
        <CollectionIndex />
      </main>

      <Footer />

      <div className="vignette" aria-hidden="true" />
      <div className="grain" aria-hidden="true" />
    </>
  );
}
