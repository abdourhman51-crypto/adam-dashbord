import { NextResponse } from "next/server";
import { resolveParent } from "@/lib/telegram/parent";
import { supabaseAdmin } from "@/lib/supabase/admin";

export const dynamic = "force-dynamic";

const ALLOWED_KEYS = new Set([
  "menu_faq",
  "menu_how",
  "menu_why",
  "menu_pricing_diff",
  "menu_family",
  "menu_settings",
  "menu_privacy",
]);

interface MomentButton {
  label: string;
  cb?: string;
  url?: string;
}

export async function GET(request: Request) {
  const parent = await resolveParent(request);
  if (!parent.ok) {
    return NextResponse.json({ error: parent.message }, { status: parent.status });
  }

  const key = new URL(request.url).searchParams.get("key");
  if (!key || !ALLOWED_KEYS.has(key)) {
    return NextResponse.json({ error: "شاشة غير معروفة" }, { status: 400 });
  }

  const { data, error } = await supabaseAdmin().rpc("get_conversation_moment", {
    p_key: key,
    p_parent_id: parent.parentId,
  });

  if (error) {
    return NextResponse.json({ error: "تعذّر قراءة هذي الشاشة" }, { status: 500 });
  }

  const moment = data as { found: boolean; body?: string; buttons?: MomentButton[] } | null;
  if (!moment?.found || !moment.body) {
    return NextResponse.json({ error: "المحتوى غير متاح الآن" }, { status: 404 });
  }

  return NextResponse.json({ body: moment.body, buttons: moment.buttons ?? [] });
}
