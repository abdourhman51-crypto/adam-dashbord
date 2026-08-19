import { Users, UserPlus, CalendarDays, Crown, MessagesSquare, Moon } from "lucide-react";
import { Card } from "@/components/ui/Card";
import { KpiCard } from "@/components/ui/KpiCard";
import { Donut } from "@/components/charts/Donut";
import { FunnelSteps } from "@/components/charts/FunnelSteps";
import { getOverviewKpis, getConversionFunnel } from "@/lib/queries/overview";
import { formatNumber } from "@/lib/format";

export const dynamic = "force-dynamic";
export const revalidate = 0;

export default async function OverviewPage() {
  const [kpis, funnel] = await Promise.all([getOverviewKpis(), getConversionFunnel()]);

  return (
    <div className="flex flex-col gap-6">
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 xl:grid-cols-6">
        <KpiCard label="إجمالي العائلات" value={formatNumber(kpis.total)} icon={Users} tone="primary" />
        <KpiCard label="جديد اليوم" value={formatNumber(kpis.newToday)} icon={UserPlus} tone="info" />
        <KpiCard label="جديد هذا الأسبوع" value={formatNumber(kpis.newWeek)} icon={CalendarDays} tone="info" />
        <KpiCard
          label="مشتركون مدفوعون"
          value={formatNumber(kpis.paid)}
          hint={`من ${formatNumber(kpis.total)} إجمالاً`}
          icon={Crown}
          tone="gold"
        />
        <KpiCard label="رسائل اليوم" value={formatNumber(kpis.messagesToday)} icon={MessagesSquare} tone="success" />
        <KpiCard
          label="متابعة ليلية اليوم"
          value={formatNumber(kpis.activeDailyToday)}
          hint="عائلات سجّلت الليلة"
          icon={Moon}
          tone="default"
        />
      </div>

      <div className="grid gap-4 lg:grid-cols-5">
        <Card title="قمع التحويل" subtitle="من أول رسالة إلى الدفع الفعلي" className="lg:col-span-3">
          <FunnelSteps steps={funnel} />
        </Card>
        <Card title="مجاني مقابل مدفوع" subtitle="توزيع كل العائلات الحالية" className="lg:col-span-2">
          <Donut
            data={[
              { name: "مدفوع", value: kpis.paid },
              { name: "مجاني", value: kpis.free },
            ]}
            centerLabel="إجمالي"
          />
        </Card>
      </div>
    </div>
  );
}
