import { Card } from "@/components/ui/Card";
import { Reveal } from "@/components/ui/Reveal";
import { safeParseLightMemory, formatDateTime } from "@/lib/format";

const FIELD_LABELS: Record<string, string> = {
  core_pain: "الوجع الأعمق",
  emotional_state: "الحالة الشعورية",
  life_context: "السياق الحياتي",
  continuity: "استكمال الحديث",
  child_insight: "ملاحظة عن الطفل",
  last_win: "آخر انتصار",
};

export function LightMemoryCard({ raw, updatedAt }: { raw: string | null; updatedAt: string | null }) {
  const parsed = safeParseLightMemory(raw);
  const entries = parsed
    ? Object.entries(FIELD_LABELS)
        .map(([key, label]) => [label, parsed[key]] as const)
        .filter(([, value]) => value && value.trim() !== "")
    : [];

  return (
    <Card title="ذاكرة القلب" subtitle={updatedAt ? `آخر تحديث ${formatDateTime(updatedAt)}` : undefined}>
      {entries.length === 0 ? (
        <p className="text-sm text-[color:var(--text-muted)]">لا توجد ذاكرة مسجَّلة بعد.</p>
      ) : (
        <div className="flex flex-col gap-3">
          {entries.map(([label, value]) => (
            <div key={label} className="flex flex-col gap-1.5">
              <span className="text-xs font-medium text-[color:var(--text-muted)]">{label}</span>
              <Reveal>
                <p className="text-sm leading-relaxed text-[color:var(--text-secondary)]">{value}</p>
              </Reveal>
            </div>
          ))}
        </div>
      )}
    </Card>
  );
}
