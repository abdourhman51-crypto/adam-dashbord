import { useRef, type ReactNode, type MouseEvent } from "react";
import { motion, useMotionValue, useSpring } from "framer-motion";
import "./MagneticButton.css";

interface MagneticButtonProps {
  children: ReactNode;
  variant?: "dark" | "light";
  onClick?: () => void;
  ariaLabel?: string;
}

/**
 * A button that leans toward the cursor — restrained, weighted,
 * with a filling backdrop on hover. Micro-interaction only.
 */
export function MagneticButton({ children, variant = "dark", onClick, ariaLabel }: MagneticButtonProps) {
  const ref = useRef<HTMLButtonElement>(null);
  const x = useMotionValue(0);
  const y = useMotionValue(0);
  const sx = useSpring(x, { stiffness: 160, damping: 16, mass: 0.5 });
  const sy = useSpring(y, { stiffness: 160, damping: 16, mass: 0.5 });

  const onMove = (e: MouseEvent) => {
    const el = ref.current;
    if (!el) return;
    const r = el.getBoundingClientRect();
    x.set((e.clientX - (r.left + r.width / 2)) * 0.28);
    y.set((e.clientY - (r.top + r.height / 2)) * 0.28);
  };

  const onLeave = () => {
    x.set(0);
    y.set(0);
  };

  return (
    <motion.button
      ref={ref}
      className={`magnetic-btn magnetic-btn--${variant}`}
      style={{ x: sx, y: sy }}
      onMouseMove={onMove}
      onMouseLeave={onLeave}
      onClick={onClick}
      aria-label={ariaLabel}
      whileTap={{ scale: 0.96 }}
    >
      <span className="magnetic-btn__fill" aria-hidden="true" />
      <span className="magnetic-btn__label label">{children}</span>
    </motion.button>
  );
}
