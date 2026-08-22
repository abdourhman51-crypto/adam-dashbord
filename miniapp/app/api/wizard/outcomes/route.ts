import { NextResponse } from "next/server";
import { resolveParent } from "@/lib/telegram/parent";
import { supabaseAdmin } from "@/lib/supabase/admin";

export const dynamic = "force-dynamic";

export async function GET(request: Request) {
  const parent = await resolveParent(request);
  if (!parent.ok) {
    return NextResponse.json({ error: parent.message }, { status: parent.status });
  }

  const problemKey = new URL(request.url).searchParams.get("problem");
  if (!problemKey) {
    return NextResponse.json({ error: "المشكلة غير محددة" }, { status: 400 });
  }

  const db = supabaseAdmin();
  const [outcomesRes, promisesRes] = await Promise.all([
    db.rpc("journey_outcome_options", { p_problem_key: problemKey }),
    db.rpc("journey_completion_promises", { p_problem_key: problemKey }),
  ]);

  if (outcomesRes.error || promisesRes.error) {
    return NextResponse.json({ error: "تعذّر قراءة الخيارات" }, { status: 500 });
  }

  return NextResponse.json({
    outcomes: (outcomesRes.data as string[] | null) ?? [],
    promises: (promisesRes.data as string[] | null) ?? [],
  });
}
