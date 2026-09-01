import { NextResponse } from "next/server";
import { resolveParent } from "@/lib/telegram/parent";
import { supabaseAdmin } from "@/lib/supabase/admin";

export const dynamic = "force-dynamic";

const MAX_LEN = 600;

/**
 * رافعة التحويل لمن لا دليل كافياً بعد: بدل أن يُرفض بلا بديل حتى يحكي في
 * المحادثة، يكتب وضعه بكلماته هنا مباشرة، فيصل لفريق آدم لا فارغ اليدين
 * بل بنفس ما كتبه — عبر capture_journey_form_answer نفسها التي يكتب بها
 * جدول journey_form_state الذي يقرأه الفريق أصلاً من لوحة التحكم، بدل
 * اختراع مسار موازٍ. لا اتفاق يُبنى تلقائياً هنا؛ فريق آدم من يبنيه معه.
 */
export async function POST(request: Request) {
  const parent = await resolveParent(request);
  if (!parent.ok) {
    return NextResponse.json({ error: parent.message }, { status: parent.status });
  }

  const body = (await request.json().catch(() => null)) as { text?: unknown } | null;
  const text = typeof body?.text === "string" ? body.text.trim() : "";
  if (!text) {
    return NextResponse.json({ error: "اكتبوا وضعكم أولاً" }, { status: 400 });
  }

  const { data, error } = await supabaseAdmin().rpc("capture_journey_form_answer", {
    p_parent_id: parent.parentId,
    p_field: "problem_text",
    p_value: text.slice(0, MAX_LEN),
  });

  if (error) {
    return NextResponse.json({ error: "تعذّر الحفظ الآن" }, { status: 500 });
  }

  const result = data as { ok?: boolean } | null;
  if (!result?.ok) {
    return NextResponse.json({ captured: false }, { status: 500 });
  }

  return NextResponse.json({ captured: true });
}
