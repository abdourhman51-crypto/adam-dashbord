"use client";

import { getInitDataRaw } from "@/lib/telegram/client";

export type ScreenFetchResult<T> =
  | { state: "ok"; data: T }
  | { state: "outside_telegram" }
  | { state: "not_found" }
  | { state: "error"; message: string };

export async function fetchScreen<T>(url: string): Promise<ScreenFetchResult<T>> {
  const initData = getInitDataRaw();
  if (!initData) return { state: "outside_telegram" };

  let res: Response;
  try {
    res = await fetch(url, { headers: { "x-telegram-init-data": initData } });
  } catch {
    return { state: "error", message: "تعذّر الاتصال. تأكد من اتصالك بالإنترنت." };
  }

  if (res.status === 404) return { state: "not_found" };
  if (!res.ok) {
    return { state: "error", message: "حدث خطأ غير متوقع. حاول مرة أخرى." };
  }

  const data = (await res.json()) as T;
  return { state: "ok", data };
}

export async function postAction<T>(
  url: string,
  body: unknown
): Promise<ScreenFetchResult<T>> {
  const initData = getInitDataRaw();
  if (!initData) return { state: "outside_telegram" };

  let res: Response;
  try {
    res = await fetch(url, {
      method: "POST",
      headers: { "x-telegram-init-data": initData, "content-type": "application/json" },
      body: JSON.stringify(body),
    });
  } catch {
    return { state: "error", message: "تعذّر الاتصال. تأكد من اتصالك بالإنترنت." };
  }

  if (res.status === 404) return { state: "not_found" };
  if (!res.ok) {
    return { state: "error", message: "تعذّر تسجيل الإجابة. حاول مرة أخرى." };
  }

  const data = (await res.json()) as T;
  return { state: "ok", data };
}
