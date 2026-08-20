import { verifyInitData } from "@/lib/telegram/verify";
import { supabaseAdmin } from "@/lib/supabase/admin";

export const INIT_DATA_HEADER = "x-telegram-init-data";

export type ResolveResult =
  | { ok: true; parentId: string; childName: string | null; isPaid: boolean; country: string | null }
  | { ok: false; status: number; message: string };

/**
 * نقطة الدخول الوحيدة لكل route: تتحقق من initData بالتوقيع، ثم تُرجع
 * parent_id الداخلي (followers.id) حصراً — لا قيمة معرّف تُقبل من العميل نفسه.
 * أي فشل بأي خطوة → رفض فوري، صفر استعلامات إضافية.
 */
export async function resolveParent(request: Request): Promise<ResolveResult> {
  const raw = request.headers.get(INIT_DATA_HEADER);
  const verified = verifyInitData(raw);
  if (!verified.ok) {
    return { ok: false, status: 401, message: verified.reason };
  }

  const platformUserId = String(verified.user.id);
  const { data, error } = await supabaseAdmin()
    .from("followers")
    .select("id, funnel_stage, country, children:children(name, is_primary)")
    .eq("platform", "telegram")
    .eq("platform_user_id", platformUserId)
    .maybeSingle();

  if (error) {
    return { ok: false, status: 500, message: "تعذّر قراءة بيانات الوالد" };
  }
  if (!data) {
    return { ok: false, status: 404, message: "لا يوجد سجل لهذا الوالد بعد" };
  }

  const children = (data.children ?? []) as { name: string | null; is_primary: boolean }[];
  const primary =
    children.find((c) => c.is_primary && c.name && !["الطفل", "الطفلة"].includes(c.name)) ??
    children.find((c) => c.name && !["الطفل", "الطفلة"].includes(c.name));

  return {
    ok: true,
    parentId: data.id as string,
    childName: primary?.name ?? null,
    isPaid: data.funnel_stage === "paid_active",
    country: (data.country as string | null) ?? null,
  };
}
