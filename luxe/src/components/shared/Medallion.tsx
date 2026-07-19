import "./Medallion.css";

interface MedallionProps {
  /** diameter, any CSS length */
  size?: string;
  className?: string;
}

/**
 * The brand seal — the official medallion logotype rebuilt in
 * live type on a polished stone disc, so it stays crisp at any
 * size and belongs to the same material world as the page.
 */
export function Medallion({ size = "96px", className = "" }: MedallionProps) {
  return (
    <span
      className={`medallion medallion--component ${className}`}
      style={{ width: size, ["--medallion-size" as string]: size }}
      role="img"
      aria-label="Luxels — sceau de la maison"
    >
      <span className="medallion__word">LUXELS</span>
    </span>
  );
}
