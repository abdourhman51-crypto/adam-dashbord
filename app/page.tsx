import { Users, UserCheck, Crown, MessagesSquare, Percent, HeartHandshake } from "lucide-react";
import { Card, KpiCard } from "@/components/ui";
import { AreaTrend, FunnelSteps, Donut } from "@/components/charts";
import InsightsPanel from "@/components/InsightsPanel";
import { computeInsights } from "@/lib/insights";
import { getChatStats, getFollowers, getPlanSessions } from "@/lib/queries";
import { formatNumber, formatPercent, FUNNEL_LABELS, relativeTime } from "@/lib/format";
import Link from "next/link";

export const revalidate = 60;

const DAY = 24 * 60 * 60 * 1000;

export default async function OverviewPage() {
  const [followers, plans, chats] = await Promise.all([
    getFollowers(),
    getPlanSessions(),
    getChatStats(),
  ]);

  const now = Date.now();
  const total = followers.length;
  const active7 = followers.filter((f) => f.last_active && now - +new Date(f.last_active) < 7 * DAY).length;
  const paid = followers.filter((f) => f.payment_status === "paid").length;
  const offersSent = followers.filter((f) => f.offer_status !== "none").length;
  const conversion = total > 0 ? paid / total : 0;
  const breakthroughs = plans.filter((p) => p.has_breakthrough).length;

  /* نمو يومي منذ الإطلاق */
  const byDay = new Map<string, number>();
  for (const f of followers) {
    if (!f.first_seen) continue;
    const d = f.first_seen.slice(0, 10);
    byDay.set(d, (byDay.get(d) ?? 0) + 1);
  }
  const growthDaily = [...byDay.entries()]
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([date, count]) => ({
      date: new Intl.DateTimeFormat("ar", { numberingSystem: "latn", day: "numeric", month: "short" }).format(new Date(date)),
      count,
    }));

  /* توزيع مراحل القمع */
  const stageCounts = new Map<string, number>();
  for (const f of followers) {
    const s = f.funnel_stage ?? "free_conversation";
    stageCounts.set(s, (stageCounts.get(s) ?? 0) + 1);
  }
  const stageData = [...stageCounts.entries()].map(([name, value]) => ({
    name: FUNNEL_LABELS[name] ?? name,
    value,
  }));

  const funnelSteps = [
    { label: "إجمالي المتابعين", value: total, tone: "green" as const },
    { label: "استلموا العرض", value: offersSent, tone: "gold" as const },
    { label: "مشتركون فعليون", value: paid, tone: "success" as const },
  ];

  const insights = computeInsights(followers, plans);
  const latest = [...followers]
    .filter((f) => f.first_seen)
    .sort((a, b) => +new Date(b.first_seen!) - +new Date(a.first_seen!))
    .slice(0, 6);

  return (
    <div className="space-y-6">
      {/* مؤشرات رئيسية */}
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 xl:grid-cols-6">
        <KpiCard label="إجمالي المتابعين" value={formatNumber(total)} icon={<Users size={20} />} />
        <KpiCard label="نشطون آخر 7 أيام" value={formatNumber(active7)} hint={formatPercent(total ? active7 / total : 0) + " من الإجمالي"} icon={<UserCheck size={20} />} tone="info" />
        <KpiCard label="مشتركون نشطون" value={formatNumber(paid)} icon={<Crown size={20} />} tone="gold" />
        <KpiCard label="معدل التحويل الكلي" value={formatPercent(conversion)} hint={`من ${formatNumber(offersSent)} عرضاً`} icon={<Percent size={20} />} tone="success" />
        <KpiCard label="إجمالي الرسائل" value={formatNumber(chats.total)} hint={`${formatNumber(chats.sessions.length)} جلسة`} icon={<MessagesSquare size={20} />} tone="info" />
        <KpiCard label="اختراقات تربوية" value={formatNumber(breakthroughs)} hint="لحظات تحوّل موثَّقة" icon={<HeartHandshake size={20} />} tone="warning" />
      </div>

      {/* الرؤى الذكية */}
      <InsightsPanel insights={insights} />

      <div className="grid gap-4 lg:grid-cols-3">
        <Card title="نمو المتابعين يومياً" subtitle="منذ الإطلاق — حسب تاريخ أول ظهور" className="lg:col-span-2">
          <AreaTrend data={growthDaily} xKey="date" yKey="count" label="متابعون جدد" />
        </Card>
        <Card title="توزيع مراحل القمع" subtitle="أين يقف متابعوك الآن">
          <Donut data={stageData} label="توزيع مراحل القمع" />
        </Card>
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <Card title="قمع التحويل" subtitle="من المحادثة الأولى إلى الاشتراك">
          <FunnelSteps steps={funnelSteps} />
        </Card>
        <Card title="أحدث المنضمّين" subtitle="آخر 6 متابعين" action={<Link href="/followers" className="text-xs font-medium text-[color:var(--primary)] hover:underline">عرض الكل ←</Link>}>
          <ul className="divide-y">
            {latest.map((f) => (
              <li key={f.id} className="flex items-center justify-between gap-3 py-2.5">
                <Link href={`/followers/${f.id}`} className="min-w-0">
                  <div className="truncate text-sm font-medium hover:text-[color:var(--primary)]">
                    {f.first_name || f.username || `مستخدم ${f.platform_user_id.slice(-4)}`}
                  </div>
                  <div className="text-xs text-[color:var(--text-muted)]">
                    {FUNNEL_LABELS[f.funnel_stage ?? ""] ?? f.funnel_stage}
                  </div>
                </Link>
                <span className="shrink-0 text-xs text-[color:var(--text-muted)]">{relativeTime(f.first_seen)}</span>
              </li>
            ))}
          </ul>
        </Card>
      </div>
    </div>
  );
}
