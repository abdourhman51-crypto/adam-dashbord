import { navigation } from "@/data/products";
import { scrollToTop } from "@/lib/smooth-scroll";
import { Medallion } from "@/components/shared/Medallion";
import "./Footer.css";

export function Footer() {
  return (
    <footer className="footer">
      <div className="footer__body shell">
        <div className="footer__brand-block">
          <Medallion className="footer__seal" size="clamp(72px, 9vw, 104px)" />
          <p className="footer__wordmark">
            LUXELS<span className="footer__tm">™</span>
          </p>
          <p className="footer__motto display-italic">Look different.</p>
        </div>

        <nav className="footer__nav" aria-label="Navigation pied de page">
          <p className="label footer__col-title">La Maison</p>
          <ul className="footer__list">
            {navigation.slice(0, 4).map((n) => (
              <li key={n.label}>
                <a href="#" className="footer__link" onClick={(e) => e.preventDefault()}>
                  {n.label}
                </a>
              </li>
            ))}
          </ul>
        </nav>

        <div className="footer__nav">
          <p className="label footer__col-title">Services</p>
          <ul className="footer__list">
            {navigation.slice(4).map((n) => (
              <li key={n.label}>
                <a href="#" className="footer__link" onClick={(e) => e.preventDefault()}>
                  {n.label}
                </a>
              </li>
            ))}
          </ul>
        </div>

        <div className="footer__nav">
          <p className="label footer__col-title">Contact</p>
          <ul className="footer__list">
            <li><span className="footer__link footer__link--static">Alger, Algérie</span></li>
            <li><span className="footer__link footer__link--static">Livraison — 58 wilayas</span></li>
            <li><span className="footer__link footer__link--static">luxels.co</span></li>
          </ul>
        </div>
      </div>

      <div className="footer__base shell">
        <p className="label footer__legal">© {new Date().getFullYear()} Luxels — Prototype de présentation</p>
        <button className="footer__top label" onClick={scrollToTop}>
          Revenir en haut ↑
        </button>
      </div>
    </footer>
  );
}
