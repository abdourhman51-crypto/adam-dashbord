import { NextResponse } from "next/server";
import { resolveParent } from "@/lib/telegram/parent";
import { supabaseAdmin } from "@/lib/supabase/admin";

export const dynamic = "force-dynamic";

/**
 * الاستثناء الثالث والأخير المصرَّح به لقاعدة "قراءة فقط" — بلا أي حقل
 * إدخال، مجرد تأكيد التزام بخطوة اليوم الموجودة فعلاً. نفس صرامة initData.
 */
export async function POST(request: Request) {
  const parent = await resolveParent(request);
  if (!parent.ok) {
    return NextResponse.json({ error: parent.message }, { status: parent.status });
  }

  const { data, error } = await supabaseAdmin().rpc("commit_chat_step", {
    p_parent_id: parent.parentId,
  });

  if (error) {
    return NextResponse.json({ error: "تعذّر تسجيل الالتزام" }, { status: 500 });
  }

  const result = data as { committed: boolean; reason?: string; step?: string } | null;
  if (!result?.committed) {
    return NextResponse.json({ committed: false, reason: result?.reason ?? "unknown" }, { status: 409 });
  }

  return NextResponse.json({ committed: true, step: result.step ?? null });
}
