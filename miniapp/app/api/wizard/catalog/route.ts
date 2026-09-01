import { NextResponse } from "next/server";
import { resolveParent } from "@/lib/telegram/parent";
import { supabaseAdmin } from "@/lib/supabase/admin";

export const dynamic = "force-dynamic";

interface MenuButton {
  label: string;
  cb?: string;
  url?: string;
}

/**
 * الاستمارة الحرّة (اختر أي مشكلة من ستّ) كانت تتعارض بنيوياً مع محرّك
 * الاتفاق الحقيقي: agree_objective لا يقبل إلا هدفاً مبنياً على دليل أكّده
 * آدم فعلاً (suggest_objective) — فلم يكن ممكناً توصيل اختيار حرّ من الوالد
 * به دون كسر قاعدة "لا نخترع هدفاً أبداً". ولمّا وصلت الاستمارة لخطوة
 * التفعيل، لم تكن تكتب شيئاً أصلاً — لا استدعاء لـ agree_objective، ولا أي
 * أثر في قاعدة البيانات؛ كل ما اختاره الوالد كان يضيع، وينتهي بنفس رابط
 * التواصل العام سواء اتّفق على شيء أو لا.
 *
 * البديل هنا: نفس محرّك المحادثة بالضبط. إن كان الدليل جاهزاً (suggest_objective
 * ready)، نعرض نفس الهدف الذي تعرضه لحظة الاتفاق في المحادثة، ونؤكّده
 * بضغطة واحدة عبر agree_objective الحقيقية — فيصبح والدٌ اتّفق من التطبيق
 * مطابقاً تماماً لوالدٍ اتّفق في المحادثة (alreadyAgreed أعلاه). إن لم يكن
 * الدليل جاهزاً بعد، لا نخترع استمارة بديلة — نقول ذلك بصراحة ونعيده للمحادثة
 * ليحكي لآدم أولاً، بدل جمع إجابات لن تُستعمل أبداً.
 */
export async function GET(request: Request) {
  const parent = await resolveParent(request);
  if (!parent.ok) {
    return NextResponse.json({ error: parent.message }, { status: parent.status });
  }

  const db = supabaseAdmin();

  const [countryRes, journeyMomentRes, stageRes, followerRes, suggestRes] = await Promise.all([
    db.rpc("country_state", { p_parent_id: parent.parentId }),
    db.rpc("get_conversation_moment", { p_key: "menu_journey", p_parent_id: parent.parentId }),
    db.rpc("stage_state", { p_parent_id: parent.parentId }),
    db.from("followers").select("agreed_objective").eq("id", parent.parentId).maybeSingle(),
    db.rpc("suggest_objective", { p_parent_id: parent.parentId }),
  ]);

  const countryState = countryRes.data as { state?: string; price?: string; name_ar?: string } | null;
  const journeyMoment = journeyMomentRes.data as { buttons?: MenuButton[] } | null;
  const teamUrl = journeyMoment?.buttons?.find((b) => b.url)?.url ?? null;
  const stage = stageRes.data as { in_stage?: boolean; objective_text?: string } | null;
  const agreedObjective = followerRes.data?.agreed_objective as { objective_text?: string } | null;
  const suggested = suggestRes.data as { ready?: boolean; objective_text?: string } | null;

  // ⭐ من غير المنطقي أن يفتح والدٌ مشترك، اختار هدفه بالفعل، استمارة
  // فارغة من جديد. الاستمارة تُعرض له فقط إذا لم يكن في رحلة نشطة الآن.
  const alreadyInStage = parent.isPaid && Boolean(stage?.in_stage);

  // ⭐ نفس المبدأ، لمرحلة أبكر: والدٌ اتّفق على هدفه بالفعل في المحادثة
  // (لحظة الاتفاق) قبل أن يدفع.
  const alreadyAgreed = !alreadyInStage && Boolean(agreedObjective?.objective_text);

  return NextResponse.json({
    childName: parent.childName,
    countrySupported: countryState?.state === "supported",
    price: countryState?.price ?? null,
    countryName: countryState?.name_ar ?? null,
    teamUrl,
    alreadyInStage,
    alreadyAgreed,
    ready: !alreadyInStage && !alreadyAgreed && Boolean(suggested?.ready),
    suggestedObjectiveText: suggested?.objective_text ?? null,
    currentObjectiveText: alreadyInStage
      ? (stage?.objective_text ?? null)
      : alreadyAgreed
        ? (agreedObjective?.objective_text ?? null)
        : null,
  });
}
