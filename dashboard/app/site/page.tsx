import { Bars, Card, Funnel, Kpi, Problem } from "@/components/ui";
import { LineSeries } from "@/components/charts";
import Range, { pickDays } from "@/components/Range";
import { getSite } from "@/lib/site";
import { COUNTRY, day, n, pct } from "@/lib/fmt";

export const revalidate = 300;
export const metadata = { title: "الموقع" };

export default async function Site({ searchParams }: { searchParams: Promise<Record<string, string | string[] | undefined>> }) {
  const days = pickDays((await searchParams).days);
  const { data, error } = await getSite(days);
  if (!data) return <Problem error={error ?? "?"} />;
  const f = data.funnel;
  const sales = Math.max(f.paid, f.buyers);

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-xl font-bold">الموقع وصفحات البيع</h1>
        <Range days={days} path="/site" />
      </div>

      <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
        <Kpi label="زوار" value={n(f.visitors)} sub={`تفاعل ${pct(f.engaged, f.visitors)}`} />
        <Kpi label="وصلوا للسعر" value={n(f.price)} sub={pct(f.price, f.visitors) + " من الزوار"} />
        <Kpi label="ضغطوا زر الشراء" value={n(f.checkout)} tone="gold" />
        <Kpi label="مبيعات بالبطاقة" value={n(sales)} tone="good" sub={`تحويل ${pct(sales, f.visitors)}`} />
      </div>

      <div className="grid gap-4 lg:grid-cols-3">
        <Card title="يومياً" className="lg:col-span-2">
          <LineSeries
            data={data.days.map((d) => ({ ...d, label: day(d.d), sales: Math.max(d.paid, d.buyers) }))}
            x="label"
            series={[
              { key: "visitors", name: "زوار", color: "var(--primary)" },
              { key: "checkout", name: "ضغطوا الشراء", color: "var(--gold)" },
              { key: "sales", name: "مبيعات", color: "var(--good)" },
            ]}
          />
        </Card>
        <Card title="القمع">
          <Funnel
            steps={[
              { label: "دخلوا", n: f.visitors },
              { label: "تفاعلوا", n: f.engaged },
              { label: "وصلوا للسعر", n: f.price },
              { label: "ضغطوا الشراء", n: f.checkout },
              { label: "اشتروا", n: sales },
            ]}
          />
        </Card>
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        <Card title="من أين جاؤوا" hint="زوار · مشترون">
          <Bars items={data.sources.map((s) => ({ k: s.k, n: s.visitors, extra: `${s.buyers} اشترى` }))} />
        </Card>
        <Card title="الأدوات" hint="بدأوا · أكملوا">
          <Bars items={data.tools.map((t) => ({ k: t.k, n: t.started, extra: `أكمل ${pct(t.done, t.started)}` }))} empty="لم تُستعمل أداة في الفترة" />
        </Card>
        <Card title="الدول">
          <Bars items={data.countries.map((c) => ({ k: COUNTRY[c.k] ?? c.k, n: c.n }))} />
        </Card>
        <Card title="الأجهزة">
          <Bars items={data.devices} />
        </Card>
        <Card title="خطوات أخرى">
          <ul className="space-y-2 text-sm">
            <li className="flex justify-between"><span>حمّلوا اليوم المجاني</span><b>{n(data.freeDownloads)}</b></li>
            <li className="flex justify-between"><span>ضغطوا على واتساب</span><b>{n(data.waClicks)}</b></li>
            <li className="flex justify-between"><span>دفعات Whop المؤكدة</span><b>{n(f.paid)}</b></li>
          </ul>
        </Card>
      </div>
      <p className="text-xs text-[var(--muted)]">المصدر: أحداث الموقع في n8n (hodn_events). الزيارات التجريبية مستبعدة. يتحدّث كل 5 دقائق.</p>
    </div>
  );
}
