import { NextResponse } from "next/server";
import { resolveParent } from "@/lib/telegram/parent";
import { supabaseAdmin } from "@/lib/supabase/admin";

export const dynamic = "force-dynamic";

/**
 * الاستثناء الوحيد لقاعدة "قراءة فقط" بكامل التطبيق. نفس صرامة initData
 * قبل أي شيء (resolveParent)، ثم قائمة مقفلة من ثلاث قيم فقط — بلا أي حقل
 * نص حر. تكتب فقط على سجل اليوم الذي أُرسل له سؤال مساء ولم يُجَب عليه بعد،
 * تماماً كما تسمح record_harvest_answer نفسها.
 */
const ALLOWED_OUTCOMES = ["succeeded", "tried_failed", "no_chance"] as const;
type Outcome = (typeof ALLOWED_OUTCOMES)[number];

export async function POST(request: Request) {
  const parent = await resolveParent(request);
  if (!parent.ok) {
    return NextResponse.json({ error: parent.message }, { status: parent.status });
  }

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "طلب غير صالح" }, { status: 400 });
  }

  const outcome = (body as { outcome?: unknown })?.outcome;
  if (typeof outcome !== "string" || !ALLOWED_OUTCOMES.includes(outcome as Outcome)) {
    return NextResponse.json({ error: "قيمة غير مسموحة" }, { status: 400 });
  }

  const { data, error } = await supabaseAdmin().rpc("record_harvest_answer", {
    p_parent_id: parent.parentId,
    p_outcome: outcome,
  });

  if (error) {
    return NextResponse.json({ error: "تعذّر تسجيل الإجابة" }, { status: 500 });
  }

  const result = data as { recorded: boolean; reason?: string } | null;
  if (!result?.recorded) {
    return NextResponse.json({ recorded: false, reason: result?.reason ?? "unknown" }, { status: 409 });
  }

  return NextResponse.json({ recorded: true });
}
