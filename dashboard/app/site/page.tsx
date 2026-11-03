import { Bars, Card, Funnel, Kpi, Problem } from "@/components/ui";
import { LineSeries } from "@/components/charts";
import Range, { pickDays } from "@/components/Range";
import { getSite, pageName, TOOL_NAMES, type Step } from "@/lib/site";
import { COUNTRY, ago, day, n, pct } from "@/lib/fmt";

export const revalidate = 120;
export const metadata = { title: "الموقع" };

// One row per source or page: the same five steps, so channels and pages compare side by side.
function StepTable({ rows, label }: { rows: (Step & { k: string })[]; label: (k: string) => string }) {
  if (!rows.length) return <p className="text-sm text-[var(--muted)]">لا بيانات في الفترة.</p>;
  return (
    <div className="overflow-x-auto">
      <table>
        <thead>
          <tr><th></th><th>زوار</th><th>تفاعل</th><th>السعر</th><th>زر الشراء</th><th>شراء</th></tr>
        </thead>
        <tbody>
          {rows.map((r) => (
            <tr key={r.k}>
              <td className="min-w-32 font-medium">{label(r.k)}</td>
              <td className="tabular-nums">{n(r.visitors)}</td>
              <td className="tabular-nums">{pct(r.engaged, r.visitors)}</td>
              <td className="tabular-nums">{pct(r.price, r.visitors)}</td>
              <td className="tabular-nums">{n(r.checkout)}</td>
              <td className={`tabular-nums ${r.buyers ? "font-bold text-[var(--good)]" : ""}`}>{n(r.buyers)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default async function Site({ searchParams }: { searchParams: Promise<Record<string, string | string[] | undefined>> }) {
  const days = pickDays((await searchParams).days);
  const { data, error } = await getSite(days);
  if (!data) return <Problem error={error ?? "?"} />;
  const f = data.funnel;
  const sales = Math.max(f.paid, f.buyers);

  // Rules that point at an action, from the numbers on this page only.
  const notes: string[] = [];
  const ads = data.sources.find((s) => s.k === "إعلانات إنستغرام");
  const best = [...data.sources].filter((s) => s.visitors >= 30).sort((a, b) => b.price / b.visitors - a.price / a.visitors)[0];
  if (ads && ads.visitors >= 50 && best && best.k !== ads.k)
    notes.push(`زوار الإعلانات يصلون للسعر بنسبة ${pct(ads.price, ads.visitors)} مقابل ${pct(best.price, best.visitors)} من «${best.k}». المشكلة غالباً في أول شاشة بعد الإعلان، لا في السعر.`);
  if (f.price >= 30 && f.checkout / f.price < 0.3)
    notes.push(`${n(f.price)} وصلوا للسعر و${n(f.checkout)} فقط ضغطوا زر الشراء. راجعوا قسم السعر وطرق الدفع.`);
  if (f.checkout >= 10 && sales / f.checkout < 0.1)
    notes.push(`${n(f.checkout)} ضغطوا زر الشراء و${n(sales)} أكملوا. نموذج الدفع هو أكبر تسرّب الآن.`);

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-xl font-bold">الموقع وصفحات الهبوط</h1>
        <div className="flex items-center gap-3">
          {data.last_event_at && <span className="text-xs text-[var(--muted)]">آخر زيارة {ago(data.last_event_at)}</span>}
          <Range days={days} path="/site" />
        </div>
      </div>

      <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
        <Kpi label="زوار" value={n(f.visitors)} sub={`تفاعل ${pct(f.engaged, f.visitors)}`} />
        <Kpi label="وصلوا للسعر" value={n(f.price)} sub={pct(f.price, f.visitors) + " من الزوار"} />
        <Kpi label="ضغطوا زر الشراء" value={n(f.checkout)} tone="gold" sub={pct(f.checkout, f.price) + " ممن رأوا السعر"} />
        <Kpi label="مبيعات بالبطاقة" value={n(sales)} tone="good" sub={`تحويل ${pct(sales, f.visitors)}`} />
      </div>

      {notes.length > 0 && (
        <Card title="أين يتسرّب القمع">
          <ul className="space-y-2 text-sm">
            {notes.map((x) => <li key={x} className="flex gap-2"><span className="mt-1.5 h-2 w-2 shrink-0 rounded-full bg-[var(--warn)]" />{x}</li>)}
          </ul>
        </Card>
      )}

      <div className="grid gap-4 lg:grid-cols-3">
        <Card title="يومياً" className="lg:col-span-2">
          <LineSeries
            data={data.days.map((d) => ({ ...d, label: day(d.d), sales: Math.max(d.paid, d.buyers) }))}
            x="label"
            series={[
              { key: "visitors", name: "زوار", color: "var(--primary)" },
              { key: "price", name: "وصلوا للسعر", color: "var(--info)" },
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

      <Card title="حسب المصدر" hint="من أين جاء الزائر">
        <StepTable rows={data.sources} label={(k) => k} />
      </Card>

      <Card title="أداء صفحات الهبوط" hint="زوار كل صفحة وماذا فعلوا بعدها">
        <StepTable rows={data.pages} label={pageName} />
      </Card>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <Card title="الأدوات" hint="بدأوا · أكملوا">
          <Bars items={data.tools.map((t) => ({ k: TOOL_NAMES[t.k] ?? t.k, n: t.started, extra: `أكمل ${pct(t.done, t.started)}` }))} empty="لم تُستعمل أداة في الفترة" />
        </Card>
        <Card title="الدول">
          <Bars items={data.countries.map((c) => ({ k: COUNTRY[c.k] ?? c.k, n: c.n }))} />
        </Card>
        <Card title="الأجهزة">
          <Bars items={data.devices.map((d) => ({ k: d.k.replace("ig-app", "تطبيق إنستغرام ·"), n: d.n }))} />
        </Card>
        <Card title="خطوات أخرى">
          <ul className="space-y-2 text-sm">
            <li className="flex justify-between gap-2"><span>جاؤوا من روابط نور</span><b>{n(data.fromNour)}</b></li>
            <li className="flex justify-between gap-2"><span>حمّلوا اليوم المجاني</span><b>{n(data.freeDownloads)}</b></li>
            <li className="flex justify-between gap-2"><span>ضغطوا منتجاً من صفحات الأدوات</span><b>{n(data.productClicks)}</b></li>
            <li className="flex justify-between gap-2"><span>ضغطوا واتساب</span><b>{n(data.waClicks)}</b></li>
            <li className="flex justify-between gap-2"><span>دفعات Whop المؤكدة</span><b>{n(f.paid)}</b></li>
          </ul>
        </Card>
      </div>
      <p className="text-xs text-[var(--muted)]">المصدر: أحداث الموقع في Supabase ({n(data.events_total)} حدث). الزيارات التجريبية مستبعدة.</p>
    </div>
  );
}
