import { NextResponse } from "next/server";
import { resolveParent } from "@/lib/telegram/parent";
import { supabaseAdmin } from "@/lib/supabase/admin";

export const dynamic = "force-dynamic";

interface ProblemRow {
  key: string;
  emoji: string;
  label_ar: string;
}

interface MenuButton {
  label: string;
  cb?: string;
  url?: string;
}

export async function GET(request: Request) {
  const parent = await resolveParent(request);
  if (!parent.ok) {
    return NextResponse.json({ error: parent.message }, { status: parent.status });
  }

  const db = supabaseAdmin();

  const [problemsRes, countryRes, journeyMomentRes, stageRes, followerRes] = await Promise.all([
    db.from("journey_problem_catalog").select("key, emoji, label_ar").order("sort_order"),
    db.rpc("country_state", { p_parent_id: parent.parentId }),
    db.rpc("get_conversation_moment", { p_key: "menu_journey", p_parent_id: parent.parentId }),
    db.rpc("stage_state", { p_parent_id: parent.parentId }),
    db.from("followers").select("agreed_objective").eq("id", parent.parentId).maybeSingle(),
  ]);

  if (problemsRes.error) {
    return NextResponse.json({ error: "تعذّر قراءة قائمة المواقف" }, { status: 500 });
  }

  const problems = (problemsRes.data ?? []) as ProblemRow[];
  const countryState = countryRes.data as { state?: string; price?: string; name_ar?: string } | null;
  const journeyMoment = journeyMomentRes.data as { buttons?: MenuButton[] } | null;
  const teamUrl = journeyMoment?.buttons?.find((b) => b.url)?.url ?? null;
  const stage = stageRes.data as { in_stage?: boolean; objective_text?: string } | null;
  const agreedObjective = followerRes.data?.agreed_objective as { objective_text?: string } | null;

  // ⭐ من غير المنطقي أن يفتح والدٌ مشترك، اختار هدفه بالفعل، استمارة
  // فارغة من جديد. الاستمارة تُعرض له فقط إذا لم يكن في رحلة نشطة الآن.
  const alreadyInStage = parent.isPaid && Boolean(stage?.in_stage);

  // ⭐ نفس المبدأ، لمرحلة أبكر: والدٌ اتّفق على هدفه بالفعل في المحادثة
  // (لحظة الاتفاق) قبل أن يدفع — get_conversation_moment('menu_journey')
  // يعرف هذا ويعرض «🎉 هذا اتفاقكم» بدل العرض التسويقي، لكن الاستمارة هنا
  // كانت تتجاهل agreed_objective تماماً وتعرض له نفس الاستمارة الفارغة
  // التي يراها من لم يبدأ بعد — يُعاد سؤاله عمّا أجاب عنه بالفعل.
  const alreadyAgreed = !alreadyInStage && Boolean(agreedObjective?.objective_text);

  return NextResponse.json({
    childName: parent.childName,
    problems: problems.map((p) => ({ key: p.key, emoji: p.emoji, label: p.label_ar })),
    countrySupported: countryState?.state === "supported",
    price: countryState?.price ?? null,
    countryName: countryState?.name_ar ?? null,
    teamUrl,
    alreadyInStage,
    alreadyAgreed,
    currentObjectiveText: alreadyInStage
      ? (stage?.objective_text ?? null)
      : alreadyAgreed
        ? (agreedObjective?.objective_text ?? null)
        : null,
  });
}
