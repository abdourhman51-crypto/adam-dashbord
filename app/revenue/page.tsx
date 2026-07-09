import type { Metadata } from "next";
import Link from "next/link";
import { Wallet, Crown, CalendarClock, Landmark } from "lucide-react";
import { Card, KpiCard, Badge, EmptyState, StatRow } from "@/components/ui";
import { getFollowers, getPayments, getSupportedCountries } from "@/lib/queries";
import { formatNumber, formatCurrency, formatDate, formatPercent } from "@/lib/format";

export const metadata: Metadata = { title: "الإيرادات" };
export const revalidate = 60;

const DAY = 24 * 60 * 60 * 1000;

export default async function RevenuePage() {
  const [followers, payments, countries] = await Promise.all([
    getFollowers(),
    getPayments(),
    getSupportedCountries(),
  ]);

  const now = Date.now();
  const paid = followers.filter((f) => f.payment_status === "paid");
  const activeSubs = followers.filter(
    (f) => f.subscription_expires_at && +new Date(f.subscription_expires_at) > now
  );
  const expiring7 = activeSubs.filter(
    (f) => +new Date(f.subscription_expires_at!) - now < 7 * DAY
  );

  /* تقدير الإيراد: لا توجد سجلات دفع، فنقدّر من عدد المشتركين × سعر الجزائر
     (الدولة غير مسجَّلة لمعظم المتابعين — التقدير مشروح بشفافية أدناه) */
  const dzPrice = countries.find((c) => c.code === "DZ");
  const estimatedRevenue = dzPrice ? paid.length * Number(dzPrice.price_subscription) : 0;

  const confirmedPayments = payments.filter((p) => p.status !== "pending");

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-2 gap-3 xl:grid-cols-4">
        <KpiCard label="مشتركون دافعون" value={formatNumber(paid.length)} icon={<Crown size={20} />} tone="gold" />
        <KpiCard label="اشتراكات سارية" value={formatNumber(activeSubs.length)} icon={<Wallet size={20} />} tone="success" />
        <KpiCard label="تنتهي خلال 7 أيام" value={formatNumber(expiring7.length)} icon={<CalendarClock size={20} />} tone={expiring7.length > 0 ? "warning" : "default"} />
        <KpiCard
          label="إيراد تقديري"
          value={dzPrice ? formatCurrency(estimatedRevenue, "DZD") : "—"}
          hint="تقدير: المشتركون × سعر الجزائر"
          icon={<Landmark size={20} />}
          tone="info"
        />
      </div>

      <div className="rounded-xl border border-s-4 border-s-[color:var(--warning)] bg-[color:var(--warning-soft)] p-4 text-xs leading-relaxed">
        <strong>شفافية الأرقام:</strong> جدول payments فارغ حالياً رغم وجود {formatNumber(paid.length)} مشتركين دافعين،
        ودولة المتابع غير مسجَّلة لمعظم الحسابات. لذلك «الإيراد التقديري» أعلاه حساب استدلالي (عدد المشتركين × سعر الاشتراك الجزائري 2300 دج)
        وليس مجموع مدفوعات فعلية. التوصية: تسجيل صف في payments عند كل تأكيد دفع يدوي لتصبح هذه الصفحة محاسبية دقيقة.
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <Card title="المشتركون الحاليون" subtitle="تواريخ البداية والانتهاء لكل اشتراك">
          {activeSubs.length === 0 ? (
            <EmptyState title="لا اشتراكات سارية" />
          ) : (
            <div className="overflow-x-auto rounded-xl border">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b bg-[color:var(--surface-2)]">
                    <th className="px-4 py-3 text-start text-xs font-semibold text-[color:var(--text-muted)]">المشترك</th>
                    <th className="px-4 py-3 text-start text-xs font-semibold text-[color:var(--text-muted)]">بدأ</th>
                    <th className="px-4 py-3 text-start text-xs font-semibold text-[color:var(--text-muted)]">ينتهي</th>
                    <th className="px-4 py-3 text-start text-xs font-semibold text-[color:var(--text-muted)]">المتبقي</th>
                  </tr>
                </thead>
                <tbody>
                  {activeSubs
                    .sort((a, b) => +new Date(a.subscription_expires_at!) - +new Date(b.subscription_expires_at!))
                    .map((f) => {
                      const daysLeft = Math.ceil((+new Date(f.subscription_expires_at!) - now) / DAY);
                      return (
                        <tr key={f.id} className="border-b last:border-b-0 hover:bg-[color:var(--surface-2)]">
                          <td className="px-4 py-3">
                            <Link href={`/followers/${f.id}`} className="font-medium text-[color:var(--primary)] hover:underline">
                              {f.first_name || f.username || `مستخدم ${f.platform_user_id.slice(-4)}`}
                            </Link>
                          </td>
                          <td className="px-4 py-3 text-xs">{formatDate(f.subscription_started_at)}</td>
                          <td className="px-4 py-3 text-xs">{formatDate(f.subscription_expires_at)}</td>
                          <td className="px-4 py-3">
                            <Badge tone={daysLeft <= 7 ? "error" : daysLeft <= 14 ? "warning" : "success"}>
                              {formatNumber(daysLeft)} يوماً
                            </Badge>
                          </td>
                        </tr>
                      );
                    })}
                </tbody>
              </table>
            </div>
          )}
        </Card>

        <Card title="التسعير حسب الدولة" subtitle="الأسواق المدعومة وأسعارها (supported_countries)">
          {countries.length === 0 && (
            <EmptyState
              title="جدول التسعير غير متاح لمفتاح anon"
              body="دور anon محروم من القراءة على supported_countries. أضف SUPABASE_SERVICE_ROLE_KEY في .env.local أو نفّذ: GRANT SELECT ON public.supported_countries TO anon;"
            />
          )}
          <div className="space-y-4">
            {countries.map((c) => (
              <div key={c.code} className="rounded-xl border p-4">
                <div className="flex items-center justify-between">
                  <span className="text-sm font-bold">{c.name_ar ?? c.code}</span>
                  <Badge tone={c.is_active ? "success" : "muted"}>{c.is_active ? "سوق نشط" : "موقوف"}</Badge>
                </div>
                <div className="mt-2">
                  <StatRow label="سعر الاشتراك" value={formatCurrency(Number(c.price_subscription), c.currency)} />
                  <StatRow label="سعر العودة (comeback)" value={formatCurrency(Number(c.price_comeback), c.currency)} />
                  <StatRow
                    label="هامش سعر العودة"
                    value={formatPercent(
                      (Number(c.price_comeback) - Number(c.price_subscription)) / Number(c.price_subscription)
                    )}
                  />
                </div>
              </div>
            ))}
          </div>
        </Card>
      </div>

      <Card title="سجل المدفوعات" subtitle="جدول payments — المصدر المحاسبي الرسمي">
        {confirmedPayments.length === 0 && payments.length === 0 ? (
          <EmptyState
            title="لا توجد سجلات دفع بعد"
            body="المدفوعات تُؤكَّد يدوياً حالياً دون تسجيلها هنا. عند اعتماد التسجيل، ستتحول هذه الصفحة تلقائياً إلى تقرير مالي فعلي."
          />
        ) : (
          <div className="overflow-x-auto rounded-xl border">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b bg-[color:var(--surface-2)]">
                  <th className="px-4 py-3 text-start text-xs font-semibold text-[color:var(--text-muted)]">المبلغ</th>
                  <th className="px-4 py-3 text-start text-xs font-semibold text-[color:var(--text-muted)]">الحالة</th>
                  <th className="px-4 py-3 text-start text-xs font-semibold text-[color:var(--text-muted)]">التاريخ</th>
                </tr>
              </thead>
              <tbody>
                {payments.map((p) => (
                  <tr key={p.id} className="border-b last:border-b-0">
                    <td className="tabular px-4 py-3">{formatCurrency(Number(p.amount), p.currency)}</td>
                    <td className="px-4 py-3">
                      <Badge tone={p.status === "confirmed" ? "success" : "warning"}>{p.status}</Badge>
                    </td>
                    <td className="px-4 py-3 text-xs">{formatDate(p.created_at)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>
    </div>
  );
}
