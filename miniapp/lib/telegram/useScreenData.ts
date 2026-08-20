"use client";

import { useEffect, useState } from "react";
import { fetchScreen, type ScreenFetchResult } from "@/lib/telegram/fetcher";
import { initWebApp } from "@/lib/telegram/client";

export function useScreenData<T>(url: string) {
  const [result, setResult] = useState<ScreenFetchResult<T> | { state: "loading" }>({
    state: "loading",
  });

  useEffect(() => {
    initWebApp();
    let cancelled = false;
    fetchScreen<T>(url).then((r) => {
      if (!cancelled) setResult(r);
    });
    return () => {
      cancelled = true;
    };
  }, [url]);

  return result;
}
