import { Bars, Card, Funnel, Kpi, Problem } from "@/components/ui";
import { Columns, LineSeries } from "@/components/charts";
import Range, { pickDays } from "@/components/Range";
import { getNoor, PRODUCTS, STAGES, STAGE_ORDER } from "@/lib/noor";
import { getSite } from "@/lib/site";
import { ago, day, n, pct, secs } from "@/lib/fmt";

export const revalidate = 60;

export default async function Overview({ searchParams }: { searchParams: Promise<Record<string, string | string[] | undefined>> }) {
  const days = pickDays((await searchParams).days);
  const [{ data, error }, site] = await Promise.all([getNoor(days), getSite(days)]);
  if (!data) return <Problem error={error ?? "?"} />;
  const t = data.totals;
  const a = data.approvals;
  const ccpSales = a.approved;
  const whopSales = site.data ? Math.max(site.data.funnel.paid, site.data.funnel.buyers) : null;
  const peak = [...data.hours].sort((x, y) => y.n - x.n)[0];

  // Plain rules, each tied to an action. No guesswork: a rule fires only on real counts.
  const notes: { tone: "warn" | "gold" | "good"; text: string }[] = [];
  if (a.pending) notes.push({ tone: "warn", text: `${a.pending} وصل دفع ينتظر موافقتك في تلغرام.` });
  if (a.undelivered) notes.push({ tone: "warn", text: `${a.undelivered} موافقة لم يصل ملفها. راجع صفحة المدفوعات وأرسله يدوياً.` });
  if (t.replies_failed) notes.push({ tone: "warn", text: `${t.replies_failed} رد فشل إرساله في هذه الفترة (غالباً قيود ميتا على المحادثة).` });
  if (t.offered_not_bought) notes.push({ tone: "gold", text: `${t.offered_not_bought} متابعة عُرض عليها منتج ولم تشترِ. نور تتابعهن مرة واحدة بلا ضغط بعد ~20 ساعة.` });
  if (peak?.n) notes.push({ tone: "good", text: `أكثر ساعة رسائل: ${peak.h}:00 بتوقيت الجزائر. أفضل وقت للنشر قبلها بساعة.` });
  if (t.profiles < 20) notes.push({ tone: "gold", text: "ملفات المتابعات بدأت في 3 نوفمبر 2026، فالمراحل والمشاكل ستمتلئ مع الأيام." });

  const daily = data.daily.map((x) => ({ ...x, label: day(x.d) }));

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-xl font-bold">نظرة عامة</h1>
        <div className="flex items-center gap-3">
          <span className="text-xs text-[var(--muted)]">حُدّث {ago(data.generated_at)}</span>
          <Range days={days} path="/" />
        </div>
      </div>

      <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
        <Kpi label="رسائل واردة" value={n(t.inbound)} sub={`${n(t.active_conversations)} محادثة نشطة`} />
        <Kpi label="ردود نور" value={n(t.replies_sent)} sub={`${n(t.grouped_messages)} رسالة جُمعت في رد واحد`} />
        <Kpi label="زمن الرد (الوسيط)" value={secs(t.reply_seconds_median)} sub="بعد انتظار 40 ث لتجميع الرسائل" />
        <Kpi label="محادثات جديدة" value={n(t.conversations_new)} sub={`المجموع ${n(t.conversations_all)}`} />
        <Kpi label="إشارات شراء" value={n(t.buying_signals)} tone="gold" sub={`${n(t.escalations)} تحويل لك`} />
        <Kpi label="عُرض عليهن منتج" value={n(t.offered)} sub={`${n(t.offered_not_bought)} لم يشترين بعد`} />
        <Kpi label="وصولات تنتظر" value={n(a.pending)} tone={a.pending ? "warn" : "default"} sub={`${n(t.payment_proofs)} وصل في الفترة`} />
        <Kpi
          label="مبيعات"
          value={n(ccpSales + (whopSales ?? 0))}
          tone="good"
          sub={`CCP ${n(ccpSales)} · بطاقة ${whopSales == null ? "—" : n(whopSales)}`}
        />
      </div>

      {notes.length > 0 && (
        <Card title="ما يحتاج انتباهك">
          <ul className="space-y-2 text-sm">
            {notes.map((x, i) => (
              <li key={i} className="flex gap-2">
                <span className={`mt-1.5 h-2 w-2 shrink-0 rounded-full ${x.tone === "warn" ? "bg-[var(--warn)]" : x.tone === "gold" ? "bg-[var(--gold)]" : "bg-[var(--good)]"}`} />
                <span>{x.text}</span>
              </li>
            ))}
          </ul>
        </Card>
      )}

      <div className="grid gap-4 lg:grid-cols-3">
        <Card title="الرسائل يومياً" hint={`آخر ${days} يوم`} className="lg:col-span-2">
          <LineSeries
            data={daily}
            x="label"
            series={[
              { key: "inbound", name: "رسائل واردة", color: "var(--primary)" },
              { key: "replies", name: "ردود نور", color: "var(--gold)" },
              { key: "new", name: "محادثات جديدة", color: "var(--info)" },
            ]}
          />
        </Card>
        <Card title="قمع نور" hint="من الملفات">
          <Funnel
            steps={[
              { label: "متابعات لها ملف", n: t.profiles },
              { label: "أظهرن نية شراء", n: data.followers.filter((f) => f.signals > 0).length },
              { label: "عُرض عليهن منتج", n: t.offered },
              { label: "اشترين", n: t.customers },
            ]}
          />
          <p className="mt-3 text-xs text-[var(--muted)]">تحويل العرض إلى شراء: {pct(t.customers, t.offered)}</p>
        </Card>
      </div>

      <div className="grid gap-4 lg:grid-cols-3">
        <Card title="ساعات الرسائل" hint="بتوقيت الجزائر" className="lg:col-span-2">
          <Columns data={data.hours.map((h) => ({ ...h, label: `${h.h}` }))} x="label" y="n" name="رسائل" />
        </Card>
        <Card title="المراحل">
          <Bars
            items={STAGE_ORDER.filter((s) => data.stages[s]).map((s) => ({ k: STAGES[s]?.label ?? s, n: data.stages[s] }))}
          />
        </Card>
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        <Card title="أكثر المشاكل" hint="مادة للمحتوى والمنتجات">
          <Bars items={data.problems} />
        </Card>
        <Card title="المواضيع">
          <Bars items={data.topics} />
        </Card>
        <Card title="الاعتراضات" hint="لماذا لم تشترِ">
          <Bars items={data.objections} empty="لم تُسجَّل اعتراضات بعد" />
        </Card>
        <Card title="المنتجات" hint="عُرض ← اشترت">
          <Bars
            items={Object.entries(data.products)
              .filter(([, v]) => v.offered || v.bought)
              .map(([k, v]) => ({ k: PRODUCTS[k]?.name ?? k, n: v.offered, extra: `اشترت ${v.bought}` }))}
            empty="لم يُعرض منتج بعد"
          />
        </Card>
        <Card title="الدول">
          <Bars items={data.countries} />
        </Card>
        <Card title="المنصات" hint="كل المحادثات">
          <Bars items={Object.entries(data.channels).map(([k, v]) => ({ k: k === "facebook" ? "مسنجر" : k === "instagram" ? "إنستغرام" : k, n: v }))} />
        </Card>
      </div>
    </div>
  );
}
