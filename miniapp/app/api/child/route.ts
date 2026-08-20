import { NextResponse } from "next/server";
import { resolveParent } from "@/lib/telegram/parent";
import { supabaseAdmin } from "@/lib/supabase/admin";
import { safeParseLightMemory } from "@/lib/format";

export const dynamic = "force-dynamic";

export async function GET(request: Request) {
  const parent = await resolveParent(request);
  if (!parent.ok) {
    return NextResponse.json({ error: parent.message }, { status: parent.status });
  }

  const { data, error } = await supabaseAdmin()
    .from("followers")
    .select("light_memory")
    .eq("id", parent.parentId)
    .maybeSingle();

  if (error) {
    return NextResponse.json({ error: "تعذّر قراءة هذه الشاشة" }, { status: 500 });
  }

  // حصراً child_insight — أي حقل آخر بـ light_memory (core_pain, emotional_state, life_context...) محظور هنا كلياً
  const memory = safeParseLightMemory(data?.light_memory ?? null);

  return NextResponse.json({
    childName: parent.childName,
    insight: memory?.child_insight ?? null,
  });
}
