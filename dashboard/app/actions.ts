"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { adminCall } from "@/lib/noor";

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const back = (id: string, msg: string) => {
  revalidatePath(`/followers/${id}`);
  redirect(`/followers/${id}?m=${encodeURIComponent(msg)}`);
};

// Every form posts the conversation id and an action; the database checks the rest.
export async function contactAction(form: FormData) {
  const id = String(form.get("id") ?? "");
  const action = String(form.get("action") ?? "");
  if (!UUID.test(id)) throw new Error("bad id");
  let payload: Record<string, unknown> = { conversation_id: id };
  let done = "تم";
  if (action === "pause") { payload.hours = Number(form.get("hours") ?? 24); done = "نور متوقفة مع هذه المتابعة"; }
  else if (action === "resume") done = "نور عادت للرد";
  else if (action === "note") { payload.body = String(form.get("body") ?? ""); done = "أُضيفت الملاحظة"; }
  else if (action === "stage") { payload.stage = String(form.get("stage") ?? ""); done = "تغيّرت المرحلة"; }
  else if (action === "tags") { payload.tags = String(form.get("tags") ?? "").split(/[,،]/).map((t) => t.trim()).filter(Boolean); done = "حُفظت الوسوم"; }
  else if (action === "send_dm") { payload.text = String(form.get("text") ?? ""); done = "الرسالة في الطريق (خلال دقيقة). نور صامتة 30 دقيقة."; }
  else throw new Error("bad action");
  const r = await adminCall(action, payload);
  back(id, r.ok ? done : "لم يتم: " + (r.reason ?? "خطأ"));
}

// Same path as the Telegram buttons: the n8n confirm step with c=1. The approval id is the one-time secret.
export async function paymentAction(form: FormData) {
  const t = String(form.get("t") ?? "");
  const d = String(form.get("d") ?? "");
  const p = String(form.get("p") ?? "");
  if (!UUID.test(t) || !["a", "r"].includes(d) || (d === "a" && !["hodn", "inad", "cards"].includes(p))) throw new Error("bad input");
  const url = `https://adam-voices-n8n.hawiyat.cloud/webhook/nour-pay?t=${t}&d=${d}${d === "a" ? `&p=${p}` : ""}&c=1`;
  let msg = "تم";
  try {
    const html = await (await fetch(url, { cache: "no-store" })).text();
    msg = (html.match(/<h1>([^<]*)<\/h1>/)?.[1] ?? "تم") + " · " + (html.match(/<p>([^<]*)/)?.[1] ?? "");
  } catch {
    msg = "تعذّر الوصول إلى n8n";
  }
  revalidatePath("/payments");
  redirect(`/payments?m=${encodeURIComponent(msg)}`);
}
