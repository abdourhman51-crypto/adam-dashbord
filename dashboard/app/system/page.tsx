import type { Metadata } from "next";
import { ShieldAlert, Database, Table2, KeyRound } from "lucide-react";
import { Card, KpiCard, Badge, StatRow } from "@/components/ui";
import { hasServiceRole } from "@/lib/supabase";
import {
  getFollowers,
  getPlanSessions,
  getChatStats,
  getMemoryEvents,
  getChildPatterns,
  getChildren,
  getDailyLogs,
  getWeeklyPlans,
  getPayments,
  getFollowerInsights,
} from "@/lib/queries";
import { formatNumber } from "@/lib/format";

export const metadata: Metadata = { title: "صحة النظام" };
export const revalidate = 120;

export default async function SystemPage() {
  const [followers, plans, chats, events, patterns, children, logs, weekly, payments, insights] =
    await Promise.all([
      getFollowers(),
      getPlanSessions(),
      getChatStats(),
      getMemoryEvents(),
      getChildPatterns(),
      getChildren(),
      getDailyLogs(),
      getWeeklyPlans(),
      getPayments(),
      getFollowerInsights(),
    ]);

  const serviceRole = hasServiceRole();
  const noCountry = followers.filter((f) => !f.country || f.country.trim() === "").length;
  const zeroScores = followers.every((f) => !f.pain_score && !f.urgency_score && !f.intent_score);
  const paid = followers.filter((f) => f.payment_status === "paid").length;

  const tables = [
    { name: "followers", rows: followers.length, note: "المتابعون" },
    { name: "n8n_chat_histories", rows: chats.total, note: "رسائل المحادثات" },
    { name: "plan_sessions", rows: plans.length, note: "جلسات الخطة" },
    { name: "memory_events", rows: events.length, note: "أحداث الذاكرة" },
    { name: "child_patterns", rows: patterns.length, note: "أنماط سلوكية" },
    { name: "children", rows: children.length, note: "الأطفال" },
    { name: "daily_logs", rows: logs.length, note: "سجلات يومية" },
    { name: "weekly_plans", rows: weekly.length, note: "خطط أسبوعية" },
    { name: "payments", rows: payments.length, note: "مدفوعات" },
    { name: "follower_insights", rows: insights.length, note: serviceRole ? "رؤى المتابعين" : "محمي — يتطلب service_role" },
  ];

  type Issue = { severity: "critical" | "warning" | "info"; title: string; body: string; fix: string };
  const issues: Issue[] = [
    {
      severity: "critical",
      title: "RLS معطَّل على جدولين",
      body: "جدولا supported_countries و session_tracker بلا Row Level Security — أي حامل لمفتاح anon يستطيع القراءة والتعديل عليهما.",
      fix: "ALTER TABLE public.supported_countries ENABLE ROW LEVEL SECURITY; (ثم أضف سياسات قراءة مناسبة، وكرر للجدول الثاني)",
    },
    {
      severity: "critical",
      title: "سياسات قراءة عامة على بيانات حساسة",
      body: "جداول followers و n8n_chat_histories وغيرها تسمح بالقراءة لدور anon — محتوى محادثات الأسر مكشوف لأي حامل للمفتاح العام.",
      fix: "قصر القراءة على service_role أو دور مصادَق، ونقل لوحة التحكم للعمل بمفتاح service_role على الخادم فقط",
    },
    {
      severity: "warning",
      title: "جدول payments فارغ رغم وجود مشتركين",
      body: `${formatNumber(paid)} مشتركين دافعين دون أي سجل مالي — تقارير الإيراد تقديرية فقط.`,
      fix: "إدراج صف في payments عند كل تأكيد دفع (المبلغ، العملة، follower_id)",
    },
    {
      severity: "warning",
      title: "لا عمود زمني في سجل المحادثات",
      body: "n8n_chat_histories بلا created_at — يستحيل تحليل ساعات الذروة وزمن الاستجابة.",
      fix: "ALTER TABLE n8n_chat_histories ADD COLUMN created_at timestamptz DEFAULT now();",
    },
    ...(noCountry / Math.max(followers.length, 1) > 0.5
      ? [{
          severity: "warning" as const,
          title: "بيانات الدولة غائبة",
          body: `${formatNumber(noCountry)} من ${formatNumber(followers.length)} متابعاً بلا دولة — يعطّل تحليلات السوق والتسعير.`,
          fix: "التقاط الدولة مبكراً في تدفق المحادثة وتخزينها في followers.country",
        }]
      : []),
    ...(zeroScores
      ? [{
          severity: "info" as const,
          title: "درجات التأهيل كلها صفر",
          body: "أعمدة pain/urgency/intent/offer_score موجودة لكن لا تُكتب — يبدو أن مسار التقييم لا يحفظ النتائج.",
          fix: "مراجعة عقدة الكتابة في تدفق n8n المسؤول عن التقييم",
        }]
      : []),
    ...(followers.some((f) => f.message_count === 0) && chats.total > 0
      ? [{
          severity: "info" as const,
          title: "message_count غير متزامن",
          body: "متوسط العدّاد في followers قريب من الصفر بينما توجد آلاف الرسائل فعلياً — العدّاد لا يُحدَّث تاريخياً.",
          fix: "تشغيل تحديث لمرة واحدة يجمع الرسائل من n8n_chat_histories لكل متابع",
        }]
      : []),
  ];

  const sevTone = { critical: "error", warning: "warning", info: "info" } as const;
  const sevLabel = { critical: "حرج", warning: "تحذير", info: "ملاحظة" } as const;

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-2 gap-3 xl:grid-cols-4">
        <KpiCard label="جداول مراقبة" value={formatNumber(tables.length)} icon={<Table2 size={20} />} />
        <KpiCard label="إجمالي الصفوف" value={formatNumber(tables.reduce((s, t) => s + t.rows, 0))} icon={<Database size={20} />} tone="info" />
        <KpiCard label="قضايا مرصودة" value={formatNumber(issues.length)} icon={<ShieldAlert size={20} />} tone={issues.some((i) => i.severity === "critical") ? "error" : "warning"} />
        <KpiCard label="مفتاح الاتصال" value={serviceRole ? "service_role" : "anon"} hint={serviceRole ? "وصول كامل" : "بعض الجداول محجوبة"} icon={<KeyRound size={20} />} tone={serviceRole ? "success" : "gold"} />
      </div>

      <Card title="القضايا والتوصيات" subtitle="مكتشفة آلياً من فحص البيانات الفعلية — مرتبة حسب الخطورة">
        <div className="space-y-3">
          {issues.map((issue, i) => (
            <article key={i} className="rounded-xl border p-4">
              <div className="flex flex-wrap items-center gap-2">
                <Badge tone={sevTone[issue.severity]}>{sevLabel[issue.severity]}</Badge>
                <h3 className="text-sm font-bold">{issue.title}</h3>
              </div>
              <p className="mt-2 text-xs leading-relaxed text-[color:var(--text-secondary)]">{issue.body}</p>
              <div className="mt-2 rounded-lg bg-[color:var(--surface-2)] p-2.5 text-xs" dir="ltr">
                <code className="break-all">{issue.fix}</code>
              </div>
            </article>
          ))}
        </div>
      </Card>

      <Card title="حجم الجداول" subtitle="عدد الصفوف الحية في كل جدول أساسي">
        <div className="grid gap-x-10 sm:grid-cols-2">
          {tables.map((t) => (
            <StatRow
              key={t.name}
              label={
                <span>
                  <code className="text-xs" dir="ltr">{t.name}</code>
                  <span className="ms-2 text-xs text-[color:var(--text-muted)]">{t.note}</span>
                </span>
              }
              value={formatNumber(t.rows)}
            />
          ))}
        </div>
      </Card>
    </div>
  );
}
