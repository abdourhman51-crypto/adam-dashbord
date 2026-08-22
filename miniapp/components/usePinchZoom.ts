"use client";

import { useRef, useState, useCallback, type PointerEvent } from "react";

/** تكبير/تحريك بالمس (pinch + drag) بدون أي مكتبة خارجية — pointer events فقط. */
export function usePinchZoom() {
  const [scale, setScale] = useState(1);
  const [pos, setPos] = useState({ x: 0, y: 0 });
  const pointers = useRef(new Map<number, { x: number; y: number }>());
  const lastDist = useRef<number | null>(null);
  const lastSingle = useRef<{ x: number; y: number } | null>(null);

  const onPointerDown = useCallback((e: PointerEvent) => {
    pointers.current.set(e.pointerId, { x: e.clientX, y: e.clientY });
    (e.target as Element).setPointerCapture?.(e.pointerId);
  }, []);

  const onPointerMove = useCallback((e: PointerEvent) => {
    if (!pointers.current.has(e.pointerId)) return;
    pointers.current.set(e.pointerId, { x: e.clientX, y: e.clientY });
    const pts = Array.from(pointers.current.values());

    if (pts.length === 2) {
      const dist = Math.hypot(pts[0].x - pts[1].x, pts[0].y - pts[1].y);
      if (lastDist.current != null) {
        const delta = dist / lastDist.current;
        setScale((s) => Math.min(4, Math.max(1, s * delta)));
      }
      lastDist.current = dist;
    } else if (pts.length === 1) {
      if (lastSingle.current) {
        const dx = pts[0].x - lastSingle.current.x;
        const dy = pts[0].y - lastSingle.current.y;
        setPos((p) => ({ x: p.x + dx, y: p.y + dy }));
      }
      lastSingle.current = pts[0];
    }
  }, []);

  const endPointer = useCallback((e: PointerEvent) => {
    pointers.current.delete(e.pointerId);
    if (pointers.current.size < 2) lastDist.current = null;
    if (pointers.current.size < 1) lastSingle.current = null;
  }, []);

  const toggleDoubleTap = useCallback(() => {
    setScale((s) => (s > 1.3 ? 1 : 2.2));
    setPos({ x: 0, y: 0 });
  }, []);

  const reset = useCallback(() => {
    setScale(1);
    setPos({ x: 0, y: 0 });
  }, []);

  return {
    scale,
    pos,
    onPointerDown,
    onPointerMove,
    onPointerUp: endPointer,
    onPointerCancel: endPointer,
    onDoubleClick: toggleDoubleTap,
    reset,
  };
}
