import { Eye, Users, UserPlus, MousePointerClick, Clock, LayoutGrid } from "lucide-react";
import { Card } from "@/components/ui/Card";
import { KpiCard } from "@/components/ui/KpiCard";
import { Table } from "@/components/ui/Table";
import { AreaTrend } from "@/components/charts/AreaTrend";
import { Donut } from "@/components/charts/Donut";
import { formatNumber, formatPercent, formatDate } from "@/lib/format";
import {
  getMiniappOverview,
  getMiniappDailyActive,
  getMiniappScreenPerformance,
  getMiniappTopClicks,
  getMiniappRetention,
  screenLabel,
  type MiniappScreenStat,
  type MiniappClickStat,
} from "@/lib/queries/miniapp";

export const dynamic = "force-dynamic";
export const revalidate = 0;

function formatDuration(seconds: number): string {
  if (!seconds || seconds <= 0) return "—";
  if (seconds < 60) return `${Math.round(seconds)} ث`;
  const minutes = Math.floor(seconds / 60);
  const rest = Math.round(seconds % 60);
  return rest > 0 ? `${minutes} د ${rest} ث` : `${minutes} د`;
}

export default async function MiniappAnalyticsPage() {
  const [overview, daily, screens, clicks, retention] = await Promise.all([
    getMiniappOverview(),
    getMiniappDailyActive(30),
    getMiniappScreenPerformance(),
    getMiniappTopClicks(15),
    getMiniappRetention(),
  ]);

  const dailyChartData = daily.map((d) => ({ day: formatDate(d.day), visitors: d.visitors }));
  const hasScreenData = screens.length > 0;
  const hasClickData = clicks.length > 0;
  const totalActiveToday = retention.newToday + retention.returningToday;

  const screenColumns = [
    {
      key: "screen",
      header: "الشاشة",
      render: (r: MiniappScreenStat) => <span className="font-medium">{screenLabel(r.screen)}</span>,
    },
    { key: "views", header: "المشاهدات", render: (r: MiniappScreenStat) => formatNumber(r.views), align: "end" as const },
    {
      key: "visitors",
      header: "زوّار مختلفون",
      render: (r: MiniappScreenStat) => formatNumber(r.uniqueVisitors),
      align: "end" as const,
    },
    {
      key: "avg",
      header: "متوسط الوقت عليها",
      render: (r: MiniappScreenStat) => formatDuration(r.avgSeconds),
      align: "end" as const,
    },
    {
      key: "exit",
      header: "آخر شاشة قبل المغادرة",
      render: (r: MiniappScreenStat) => (
        <span className={r.exitRate > 0.5 ? "font-medium text-[color:var(--warning)]" : ""}>
          {formatPercent(r.exitRate)}
        </span>
      ),
      align: "end" as const,
    },
  ];

  const clickColumns = [
    { key: "element", header: "العنصر", render: (r: MiniappClickStat) => r.element },
    {
      key: "screen",
      header: "في أي شاشة",
      render: (r: MiniappClickStat) => (r.screen ? screenLabel(r.screen) : "—"),
    },
    { key: "clicks", header: "عدد النقرات", render: (r: MiniappClickStat) => formatNumber(r.clicks), align: "end" as const },
  ];

  return (
    <div className="flex flex-col gap-6">
      <p className="max-w-3xl text-sm text-[color:var(--text-muted)]">
        كل الأرقام هنا من التطبيق المصغّر فقط — من فتحه، ما الشاشات التي استُعملت فعلاً، وأين يتوقّف الناس.
      </p>

      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 xl:grid-cols-6">
        <KpiCard label="إجمالي الزوّار" value={formatNumber(overview.totalVisitors)} icon={Users} tone="primary" />
        <KpiCard label="زوّار اليوم" value={formatNumber(overview.visitorsToday)} icon={UserPlus} tone="info" />
        <KpiCard label="زوّار آخر 7 أيام" value={formatNumber(overview.visitors7d)} icon={Users} tone="info" />
        <KpiCard label="جلسات اليوم" value={formatNumber(overview.sessionsToday)} icon={LayoutGrid} tone="default" />
        <KpiCard
          label="متوسط مدة الجلسة"
          value={formatDuration(overview.avgSessionSeconds)}
          icon={Clock}
          tone="gold"
        />
        <KpiCard label="إجمالي مشاهدات الشاشات" value={formatNumber(overview.totalScreenViews)} icon={Eye} tone="success" />
      </div>

      <Card title="الزوّار يوماً بيوم" subtitle="آخر 30 يوماً">
        {daily.every((d) => d.visitors === 0) ? (
          <p className="text-sm text-[color:var(--text-muted)]">لا بيانات كافية بعد.</p>
        ) : (
          <AreaTrend data={dailyChartData} xKey="day" yKey="visitors" label="زائر" />
        )}
      </Card>

      <Card
        title="أداء الشاشات"
        subtitle="مرتّبة حسب الأكثر مشاهدة — عمود المغادرة يقصد: عند كم بالمئة من الجلسات كانت هذه آخر شاشة قبل الإغلاق"
      >
        {!hasScreenData ? (
          <p className="text-sm text-[color:var(--text-muted)]">لا بيانات كافية بعد.</p>
        ) : (
          <Table columns={screenColumns} rows={screens} rowKey={(r) => r.screen} />
        )}
      </Card>

      <div className="grid gap-4 lg:grid-cols-5">
        <Card title="أكثر العناصر نقراً" className="lg:col-span-3">
          {!hasClickData ? (
            <p className="text-sm text-[color:var(--text-muted)]">لا بيانات كافية بعد.</p>
          ) : (
            <Table columns={clickColumns} rows={clicks} rowKey={(r) => `${r.element}-${r.screen ?? ""}`} />
          )}
        </Card>

        <Card title="جديد مقابل عائد" subtitle="زوّار اليوم" className="lg:col-span-2">
          {totalActiveToday === 0 ? (
            <p className="text-sm text-[color:var(--text-muted)]">لا زيارات اليوم بعد.</p>
          ) : (
            <Donut
              data={[
                { name: "زائر جديد", value: retention.newToday },
                { name: "زائر عائد", value: retention.returningToday },
              ]}
              centerLabel="زائر اليوم"
            />
          )}
        </Card>
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <KpiCard
          label="عودة اليوم التالي (D1)"
          value={retention.d1Retention === null ? "—" : formatPercent(retention.d1Retention)}
          hint={
            retention.d1SampleSize === 0
              ? "لا عيّنة كافية بعد"
              : `من ${formatNumber(retention.d1SampleSize)} زائر جديد بالأمس`
          }
          icon={MousePointerClick}
          tone="primary"
        />
        <KpiCard
          label="عودة بعد أسبوع (D7)"
          value={retention.d7Retention === null ? "—" : formatPercent(retention.d7Retention)}
          hint={
            retention.d7SampleSize === 0
              ? "لا عيّنة كافية بعد"
              : `من ${formatNumber(retention.d7SampleSize)} زائر جديد قبل 7 أيام`
          }
          icon={MousePointerClick}
          tone="gold"
        />
      </div>
    </div>
  );
}
