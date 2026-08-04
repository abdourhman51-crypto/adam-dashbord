import { useEffect, useRef, useCallback } from "react";

/**
 * Loads a numbered JPEG frame sequence and draws it into a canvas
 * with cover-fit. The scroll timeline asks for a frame by float
 * progress [0..1]; we only repaint when the integer frame changes.
 */
export function useFilmSequence(dir: string, count: number) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const imagesRef = useRef<HTMLImageElement[]>([]);
  const lastDrawn = useRef(-1);
  const readyRef = useRef(false);
  const lastProgress = useRef(0);

  const draw = useCallback((progress: number) => {
    lastProgress.current = progress;
    const canvas = canvasRef.current;
    if (!canvas) return;
    const images = imagesRef.current;
    const idx = Math.min(count - 1, Math.max(0, Math.round(progress * (count - 1))));
    /* fall back to the nearest loaded frame so scrubbing never blanks */
    let img: HTMLImageElement | undefined = images[idx];
    if (!img || !img.complete || img.naturalWidth === 0) {
      for (let d = 1; d < count; d++) {
        const lo = images[idx - d];
        const hi = images[idx + d];
        if (lo?.complete && lo.naturalWidth > 0) { img = lo; break; }
        if (hi?.complete && hi.naturalWidth > 0) { img = hi; break; }
      }
    }
    if (!img || !img.complete || img.naturalWidth === 0) return;
    if (lastDrawn.current === idx && readyRef.current) return;

    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    const cw = canvas.clientWidth * dpr;
    const ch = canvas.clientHeight * dpr;
    if (canvas.width !== cw || canvas.height !== ch) {
      canvas.width = cw;
      canvas.height = ch;
    }

    /* cover fit */
    const scale = Math.max(cw / img.naturalWidth, ch / img.naturalHeight);
    const dw = img.naturalWidth * scale;
    const dh = img.naturalHeight * scale;
    ctx.drawImage(img, (cw - dw) / 2, (ch - dh) / 2, dw, dh);
    lastDrawn.current = idx;
    readyRef.current = true;
  }, [count]);

  useEffect(() => {
    let cancelled = false;
    const images: HTMLImageElement[] = [];
    imagesRef.current = images;

    /* first frame is critical — paint it the moment it lands */
    for (let i = 0; i < count; i++) {
      const img = new Image();
      img.decoding = "async";
      img.src = `${dir}/f_${String(i + 1).padStart(3, "0")}.jpg`;
      if (i === 0) {
        img.onload = () => {
          if (!cancelled) draw(lastProgress.current);
        };
      }
      images.push(img);
    }

    const onResize = () => {
      lastDrawn.current = -1;
      readyRef.current = false;
      draw(lastProgress.current);
    };
    window.addEventListener("resize", onResize);
    return () => {
      cancelled = true;
      window.removeEventListener("resize", onResize);
    };
  }, [dir, count, draw]);

  return { canvasRef, draw };
}
