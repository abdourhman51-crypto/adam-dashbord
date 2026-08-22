"use client";

import { getInitDataRaw } from "@/lib/telegram/client";

export type ScreenFetchResult<T> =
  | { state: "ok"; data: T }
  | { state: "outside_telegram" }
  | { state: "not_found" }
  | { state: "error"; message: string };

async function readServerError(res: Response, fallback: string): Promise<string> {
  try {
    const body = (await res.json()) as { error?: string };
    return body?.error ? `${body.error} (${res.status})` : `${fallback} (${res.status})`;
  } catch {
    return `${fallback} (${res.status})`;
  }
}

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
    return { state: "error", message: await readServerError(res, "حدث خطأ غير متوقع") };
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
    return { state: "error", message: await readServerError(res, "تعذّر تسجيل الإجابة") };
  }

  const data = (await res.json()) as T;
  return { state: "ok", data };
}
