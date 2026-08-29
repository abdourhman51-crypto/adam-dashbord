import { NextResponse } from "next/server";
import { resolveParent } from "@/lib/telegram/parent";
import { supabaseAdmin } from "@/lib/supabase/admin";

export const dynamic = "force-dynamic";

const KINDS = ["held", "erupted"] as const;
const SOURCES = ["panic_button", "evening", "confession"] as const;

/**
 * يسجّل لحظة الوالد نفسه — أوشك فتماسك، أو انفجر. هذا هو الحدث الذي يقيسه
 * المنتج كلّه، لا سلوك الطفل: ٤٩ من ١٨٦ أسرة في المحادثات الحقيقية كتبت عن
 * انفجارها هي، وهي أكبر كتلة في البيانات.
 */
export async function POST(request: Request) {
  const parent = await resolveParent(request);
  if (!parent.ok) {
    return NextResponse.json({ error: parent.message }, { status: parent.status });
  }

  const body = (await request.json().catch(() => null)) as
    | { kind?: string; source?: string; note?: string }
    | null;

  const kind = body?.kind;
  const source = body?.source ?? "evening";

  if (!kind || !(KINDS as readonly string[]).includes(kind)) {
    return NextResponse.json({ error: "نوع غير معروف" }, { status: 400 });
  }
  if (!(SOURCES as readonly string[]).includes(source)) {
    return NextResponse.json({ error: "مصدر غير معروف" }, { status: 400 });
  }

  const { data, error } = await supabaseAdmin().rpc("record_parent_moment", {
    p_parent_id: parent.parentId,
    p_kind: kind,
    p_source: source,
    p_note: body?.note ?? null,
  });

  if (error) {
    return NextResponse.json({ error: "تعذّر التسجيل الآن" }, { status: 500 });
  }

  const result = (data ?? {}) as { recorded?: boolean; reason?: string };
  if (!result.recorded) {
    return NextResponse.json({ error: "تعذّر التسجيل", reason: result.reason }, { status: 400 });
  }

  return NextResponse.json({ recorded: true, kind });
}
