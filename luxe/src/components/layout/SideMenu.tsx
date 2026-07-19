import { useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { navigation } from "@/data/products";
import { stopScroll, startScroll } from "@/lib/smooth-scroll";
import "./SideMenu.css";

interface SideMenuProps {
  open: boolean;
  onClose: () => void;
}

const panelVariants = {
  closed: { x: "100%" },
  open: { x: "0%" },
};

const itemVariants = {
  closed: { y: "120%", opacity: 0 },
  open: (i: number) => ({
    y: "0%",
    opacity: 1,
    transition: { delay: 0.28 + i * 0.06, duration: 0.9, ease: [0.22, 1, 0.36, 1] },
  }),
};

/**
 * Fullscreen side navigation. Structure inherited from the maison's
 * site; everything else redesigned — oversized serif, indexed rows,
 * italic swap on hover.
 */
export function SideMenu({ open, onClose }: SideMenuProps) {
  useEffect(() => {
    if (open) stopScroll();
    else startScroll();
  }, [open]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);

  return (
    <AnimatePresence>
      {open && (
        <>
          <motion.div
            className="menu-veil"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.6 }}
            onClick={onClose}
          />
          <motion.nav
            className="menu-panel"
            variants={panelVariants}
            initial="closed"
            animate="open"
            exit="closed"
            transition={{ duration: 0.85, ease: [0.22, 1, 0.36, 1] }}
            aria-label="Navigation principale"
          >
            <div className="menu-panel__head">
              <span className="label menu-panel__kicker">Navigation</span>
              <button className="menu-panel__close" onClick={onClose} aria-label="Fermer le menu">
                <span className="label">Fermer</span>
                <span className="menu-panel__close-x" aria-hidden="true" />
              </button>
            </div>

            <ol className="menu-panel__list">
              {navigation.map((item, i) => (
                <li key={item.label} className="menu-panel__row">
                  <div className="menu-panel__clip">
                    <motion.a
                      href="#"
                      className="menu-panel__link"
                      custom={i}
                      variants={itemVariants}
                      initial="closed"
                      animate="open"
                      exit="closed"
                      onClick={(e) => {
                        e.preventDefault();
                        onClose();
                      }}
                    >
                      <span className="menu-panel__num label">{String(i + 1).padStart(2, "0")}</span>
                      <span className="menu-panel__word display">{item.label}</span>
                      <span className="menu-panel__word menu-panel__word--italic display-italic" aria-hidden="true">
                        {item.label}
                      </span>
                    </motion.a>
                  </div>
                  {item.sub && (
                    <motion.div
                      className="menu-panel__sub"
                      custom={i + 0.5}
                      variants={itemVariants}
                      initial="closed"
                      animate="open"
                      exit="closed"
                    >
                      {item.sub.map((s) => (
                        <a key={s} href="#" className="menu-panel__sub-link label" onClick={(e) => e.preventDefault()}>
                          {s}
                        </a>
                      ))}
                    </motion.div>
                  )}
                </li>
              ))}
            </ol>

            <motion.footer
              className="menu-panel__foot"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1, transition: { delay: 0.8, duration: 0.8 } }}
              exit={{ opacity: 0 }}
            >
              <span className="label">Alger — Livraison 58 wilayas</span>
              <span className="label menu-panel__foot-mark">Look Different</span>
            </motion.footer>
          </motion.nav>
        </>
      )}
    </AnimatePresence>
  );
}
