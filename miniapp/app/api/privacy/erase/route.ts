import { NextResponse } from "next/server";
import { resolveParent } from "@/lib/telegram/parent";
import { supabaseAdmin } from "@/lib/supabase/admin";

export const dynamic = "force-dynamic";

/**
 * فعل نهائي بلا رجوع — لهذا نطلب حقل confirm صريحاً (لا نكتفي بوصول الطلب
 * نفسه)، ونطابق تماماً نطاق آخر ١٣ طلب محو حقيقي أُنجزت يدوياً قبل هذا:
 * محادثة اللانج تشين الخام، الاستبيانات، وملاحظة الدفع الشخصية — لا أكثر.
 * التفاصيل والتنفيذ في request_data_erasure نفسها، لتبقى نفس الدالة تُستدعى
 * من أي مكان يُتاح منه المحو مستقبلاً.
 */
export async function POST(request: Request) {
  const parent = await resolveParent(request);
  if (!parent.ok) {
    return NextResponse.json({ error: parent.message }, { status: parent.status });
  }

  const body = (await request.json().catch(() => null)) as { confirm?: unknown } | null;
  if (body?.confirm !== true) {
    return NextResponse.json({ error: "التأكيد مطلوب" }, { status: 400 });
  }

  const { data, error } = await supabaseAdmin().rpc("request_data_erasure", {
    p_parent_id: parent.parentId,
  });

  if (error) {
    return NextResponse.json({ error: "تعذّر المحو الآن" }, { status: 500 });
  }

  const result = data as {
    erased: boolean;
    reason?: string;
    chat_deleted?: number;
    surveys_deleted?: number;
    payments_anonymised?: number;
  };

  if (!result.erased) {
    return NextResponse.json({ erased: false, reason: result.reason ?? "unknown" }, { status: 400 });
  }

  return NextResponse.json({
    erased: true,
    chatDeleted: result.chat_deleted ?? 0,
    surveysDeleted: result.surveys_deleted ?? 0,
    paymentsAnonymised: result.payments_anonymised ?? 0,
  });
}
