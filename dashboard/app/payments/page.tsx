import { Card, Kpi, Pill, Problem } from "@/components/ui";
import { getNoor, PRODUCTS } from "@/lib/noor";
import { getSite } from "@/lib/site";
import { ago, n } from "@/lib/fmt";

export const revalidate = 60;
export const metadata = { title: "المدفوعات" };

export default async function Payments() {
  const [{ data, error }, site] = await Promise.all([getNoor(30), getSite(30)]);
  if (!data) return <Problem error={error ?? "?"} />;
  const a = data.approvals;
  const dzd = Object.entries(a.by_product).reduce((s, [p, c]) => s + (PRODUCTS[p]?.dzd ?? 0) * c, 0);
  const usdLocal = Object.entries(a.by_product).reduce((s, [p, c]) => s + (PRODUCTS[p]?.dzd ? 0 : (PRODUCTS[p]?.usd ?? 0) * c), 0);

  return (
    <div className="space-y-5">
      <h1 className="text-xl font-bold">المدفوعات</h1>

      <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
        <Kpi label="وصولات تنتظر" value={n(a.pending)} tone={a.pending ? "warn" : "default"} sub="وافق عليها من أزرار تلغرام" />
        <Kpi label="موافق عليها (CCP)" value={n(a.approved)} tone="good" sub={dzd ? `≈ ${n(dzd)} دج${usdLocal ? ` + ${usdLocal}$` : ""}` : "منذ تفعيل الأزرار"} />
        <Kpi label="مرفوضة" value={n(a.rejected)} />
        <Kpi
          label="مبيعات البطاقة (30 يوم)"
          value={site.data ? n(Math.max(site.data.funnel.paid, site.data.funnel.buyers)) : "—"}
          sub={site.data ? `Whop ${n(site.data.funnel.paid)} · صفحة الشكر ${n(site.data.funnel.buyers)}` : site.error ?? ""}
        />
      </div>

      {a.undelivered > 0 && (
        <div className="card border-[var(--warn)] text-sm">⚠️ {a.undelivered} موافقة لم يصل ملفها. أرسله يدوياً من Zernio أو التطبيق.</div>
      )}

      <Card title="آخر الوصولات" hint="آخر 15">
        {a.recent.length === 0 ? (
          <p className="text-sm text-[var(--muted)]">لم يصل وصل بعد منذ تفعيل الموافقة بالأزرار.</p>
        ) : (
          <div className="overflow-x-auto">
            <table>
              <thead><tr><th>المتابعة</th><th>الحالة</th><th>المنتج</th><th>التسليم</th><th>متى</th></tr></thead>
              <tbody>
                {a.recent.map((r) => (
                  <tr key={r.id}>
                    <td>{r.name || "بدون اسم"}<div className="text-xs text-[var(--muted)]">{r.platform === "instagram" ? "إنستغرام" : "مسنجر"}</div></td>
                    <td>
                      <Pill tone={r.status === "approved" ? "success" : r.status === "pending" ? "warn" : "muted"}>
                        {r.status === "approved" ? "موافق" : r.status === "pending" ? "ينتظر" : "مرفوض"}
                      </Pill>
                    </td>
                    <td className="text-xs">{r.product ? PRODUCTS[r.product]?.name ?? r.product : r.suggested ? `مقترح: ${PRODUCTS[r.suggested]?.name ?? r.suggested}` : "—"}</td>
                    <td className="text-xs">
                      {r.status !== "approved" ? "—" : r.delivered ? <span className="text-[var(--good)]">وصلها</span> : <span className="text-[var(--warn)]">لم يصل</span>}
                      {r.error && <div className="text-[var(--muted)]">{r.error.slice(0, 80)}</div>}
                    </td>
                    <td className="whitespace-nowrap text-xs text-[var(--muted)]">{ago(r.at)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      <p className="text-xs text-[var(--muted)]">
        الأسعار: الحضن 9$ أو 1,900 دج (CCP) · العناد 12$ · البطاقات 7$. المبالغ بالدينار تقديرية من عدد الموافقات.
      </p>
    </div>
  );
}
