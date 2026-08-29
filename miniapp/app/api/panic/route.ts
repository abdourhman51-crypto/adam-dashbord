import { NextResponse } from "next/server";
import { resolveParent } from "@/lib/telegram/parent";
import { supabaseAdmin } from "@/lib/supabase/admin";

export const dynamic = "force-dynamic";

type Kind = "demand" | "flood";

const KIND_TAG: Record<Kind, string> = {
  demand: "لسّا يطلب منكم",
  flood: "دخل في انهيار",
};

/** الاسم دائماً أول كلمة — لا ضمير غائب بلا مرجع في أول الفقرة. */
const KIND_LINE1: Record<Kind, (child: string) => string> = {
  demand: (child) => `${child} ما زال معكم، وهذا يعني أنه يطلب — لا ينهار.`,
  flood: (child) => `${child} جسده أكبر منه الآن، والكلام لا يصله.`,
};

const KIND_FALLBACK_PRINCIPLE: Record<Kind, string> = {
  demand: "الثبات الهادئ على الحدّ نفسه. جملة واحدة قصيرة تُقال مرة، ثم صمت — بلا تفاوض وبلا درس أثناءها.",
  flood: "تقليل كل شيء: كلمات أقل، صوت أخفض، ضوء وحركة أقل، وقرب بلا لمس مفروض. لا تعليم الآن — لا يصل.",
};

interface FrameKind {
  key: string;
  response_ar: string;
}
interface FrameDriver {
  key: string;
  label_ar: string;
  prevent_ar: string;
}
interface Frame {
  ready: boolean;
  child_name?: string;
  age?: { normal_ar: string } | null;
  kinds?: FrameKind[];
  drivers?: FrameDriver[];
  recent?: { kind: string | null; driver: string | null }[];
}

/** الدافع الأكثر تكراراً بين مواقف هذه الأسرة من نفس النوع — التخصيص الحقيقي الوحيد المكتسب، لا المفترض. */
function topDriver(recent: Frame["recent"], kind: Kind): string | null {
  const counts = new Map<string, number>();
  for (const r of recent ?? []) {
    if (r.kind !== kind || !r.driver) continue;
    counts.set(r.driver, (counts.get(r.driver) ?? 0) + 1);
  }
  let best: string | null = null;
  let bestCount = 0;
  for (const [driver, count] of counts) {
    if (count > bestCount) {
      best = driver;
      bestCount = count;
    }
  }
  return best;
}

export async function POST(request: Request) {
  const parent = await resolveParent(request);
  if (!parent.ok) {
    return NextResponse.json({ error: parent.message }, { status: parent.status });
  }

  const body = (await request.json().catch(() => null)) as { kind?: string } | null;
  const kind = body?.kind;
  if (kind !== "demand" && kind !== "flood") {
    return NextResponse.json({ error: "نوع غير معروف" }, { status: 400 });
  }

  const db = supabaseAdmin();
  const { data: frameData } = await db.rpc("get_tantrum_frame", { p_parent_id: parent.parentId });
  const frame = (frameData ?? { ready: false }) as Frame;

  const child = (frame.ready ? frame.child_name : null) ?? parent.childName ?? "طفلكم";

  const kindEntry = frame.kinds?.find((k) => k.key === kind);
  const principle = kindEntry?.response_ar ?? KIND_FALLBACK_PRINCIPLE[kind];

  const lines: string[] = [KIND_LINE1[kind](child), principle];
  let personalized = false;

  if (frame.ready) {
    const driverKey = topDriver(frame.recent, kind);
    const driverEntry = driverKey ? frame.drivers?.find((d) => d.key === driverKey) : null;
    if (driverEntry) {
      lines.push(`عادة عند ${child} السبب ${driverEntry.label_ar} — ${driverEntry.prevent_ar}`);
      personalized = true;
    } else if (frame.age?.normal_ar) {
      lines.push(frame.age.normal_ar);
    }

    // تسجيل بأفضل جهد — يبني تاريخاً لهذه الأسرة يخصّص الردّ القادم أكثر.
    // فشله لا يمنع وصول الردّ أعلاه، وهو محكوم بنفس قانون النسخ عند commit_incident.
    try {
      await db.rpc("commit_incident", {
        p_parent_id: parent.parentId,
        p_raw_text: "استُخدم زرّ النجدة داخل التطبيق.",
        p_source: "text",
        p_kind: kind,
        p_driver: null,
        p_phase: null,
        p_reading: lines.join(" "),
      });
    } catch {
      // أفضل جهد فقط — الردّ أعلاه وصل بالفعل
    }
  }

  return NextResponse.json({ childName: child, tag: KIND_TAG[kind], lines, personalized });
}
