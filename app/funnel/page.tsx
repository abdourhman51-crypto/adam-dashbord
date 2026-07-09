import type { Metadata } from "next";
import Link from "next/link";
import { Send, ThumbsDown, Clock, BadgeCheck } from "lucide-react";
import { Card, KpiCard, Badge, EmptyState } from "@/components/ui";
import { Donut, FunnelSteps } from "@/components/charts";
import { getFollowers, getRenewalSummary } from "@/lib/queries";
import { formatNumber, formatPercent, formatDate, OFFER_LABELS, relativeTime } from "@/lib/format";

export const metadata: Metadata = { title: "قمع التحويل" };
export const revalidate = 60;

const DAY = 24 * 60 * 60 * 1000;

export default async function FunnelPage() {
  const [followers, renewals] = await Promise.all([getFollowers(), getRenewalSummary()]);
  const now = Date.now();

  const total = followers.length;
  const offersSent = followers.filter((f) => f.offer_status !== "none");
  const declined = followers.filter((f) => f.offer_declined_count > 0);
  const paid = followers.filter((f) => f.payment_status === "paid");
  const offerToPaid = offersSent.length > 0 ? paid.length / offersSent.length : 0;

  const offerCounts = new Map<string, number>();
  for (const f of followers) offerCounts.set(f.offer_status, (offerCounts.get(f.offer_status) ?? 0) + 1);
  const offerData = [...offerCounts.entries()].map(([k, v]) => ({ name: OFFER_LABELS[k] ?? k, value: v }));

  /* عروض تحتاج متابعة: أُرسلت منذ أكثر من يومين بلا متابعة ولا اشتراك */
  const needFollowup = followers.filter(
    (f) =>
      f.offer_status === "sent" &&
      !f.followup_sent_at &&
      f.payment_status !== "paid" &&
      f.offer_sent_at &&
      now - +new Date(f.offer_sent_at) > 2 * DAY
  );

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-2 gap-3 xl:grid-cols-4">
        <KpiCard label="عروض مُرسلة" value={formatNumber(offersSent.length)} hint={formatPercent(total ? offersSent.length / total : 0) + " من المتابعين"} icon={<Send size={20} />} tone="gold" />
        <KpiCard label="تحويل العرض إلى اشتراك" value={formatPercent(offerToPaid)} icon={<BadgeCheck size={20} />} tone="success" />
        <KpiCard label="رفضوا العرض" value={formatNumber(declined.length)} icon={<ThumbsDown size={20} />} tone="error" />
        <KpiCard label="بانتظار المتابعة" value={formatNumber(needFollowup.length)} hint="مرّ يومان على العرض" icon={<Clock size={20} />} tone="warning" />
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <Card title="مسار التحويل الكامل" subtitle="كل خطوة كنسبة من الخطوة السابقة">
          <FunnelSteps
            steps={[
              { label: "متابعون", value: total, tone: "green" },
              { label: "استلموا العرض", value: offersSent.length, tone: "gold" },
              { label: "اشتركوا", value: paid.length, tone: "success" },
            ]}
          />
          <p className="mt-4 text-xs leading-relaxed text-[color:var(--text-muted)]">
            ملاحظة: درجات التأهيل الآلي (ألم/إلحاح/نية) غير مفعَّلة بعد في قاعدة البيانات، لذا لا تظهر مرحلة «مؤهَّل» في القمع.
          </p>
        </Card>
        <Card title="حالات العروض" subtitle="توزيع المتابعين حسب حالة العرض">
          <Donut data={offerData} label="حالات العروض" />
        </Card>
      </div>

      <Card title="عروض تحتاج متابعة الآن" subtitle="أُرسل العرض منذ أكثر من يومين دون متابعة أو اشتراك — رتّبناها حسب الأقدم">
        {needFollowup.length === 0 ? (
          <EmptyState title="لا توجد عروض معلّقة" body="كل العروض المُرسلة تمت متابعتها أو تحوّلت. استمر!" />
        ) : (
          <div className="overflow-x-auto rounded-xl border">
            <table className="w-full min-w-137 text-sm">
              <thead>
                <tr className="border-b bg-[color:var(--surface-2)]">
                  <th className="px-4 py-3 text-start text-xs font-semibold text-[color:var(--text-muted)]">المتابع</th>
                  <th className="px-4 py-3 text-start text-xs font-semibold text-[color:var(--text-muted)]">أُرسل العرض</th>
                  <th className="px-4 py-3 text-start text-xs font-semibold text-[color:var(--text-muted)]">التحدي المذكور</th>
                  <th className="px-4 py-3 text-start text-xs font-semibold text-[color:var(--text-muted)]">آخر نشاط</th>
                </tr>
              </thead>
              <tbody>
                {[...needFollowup]
                  .sort((a, b) => +new Date(a.offer_sent_at!) - +new Date(b.offer_sent_at!))
                  .map((f) => (
                    <tr key={f.id} className="border-b last:border-b-0 hover:bg-[color:var(--surface-2)]">
                      <td className="px-4 py-3">
                        <Link href={`/followers/${f.id}`} className="font-medium text-[color:var(--primary)] hover:underline">
                          {f.first_name || f.username || `مستخدم ${f.platform_user_id.slice(-4)}`}
                        </Link>
                      </td>
                      <td className="px-4 py-3 text-xs text-[color:var(--text-muted)]">{relativeTime(f.offer_sent_at)}</td>
                      <td className="max-w-72 truncate px-4 py-3 text-xs text-[color:var(--text-secondary)]">{f.offer_pain_safe || "—"}</td>
                      <td className="px-4 py-3 text-xs text-[color:var(--text-muted)]">{relativeTime(f.last_active)}</td>
                    </tr>
                  ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      <Card title="ملخّص التجديدات" subtitle="المشتركون الحاليون وحالة تقدمهم قبل انتهاء الاشتراك (من v_renewal_summary)">
        {renewals.length === 0 ? (
          <EmptyState title="لا تتوفر بيانات التجديد" body="عرض v_renewal_summary غير متاح لمفتاح anon — أضف مفتاح service_role في .env.local لعرضه." />
        ) : (
          <div className="overflow-x-auto rounded-xl border">
            <table className="w-full min-w-162 text-sm">
              <thead>
                <tr className="border-b bg-[color:var(--surface-2)]">
                  <th className="px-4 py-3 text-start text-xs font-semibold text-[color:var(--text-muted)]">المشترك</th>
                  <th className="px-4 py-3 text-start text-xs font-semibold text-[color:var(--text-muted)]">ينتهي في</th>
                  <th className="px-4 py-3 text-start text-xs font-semibold text-[color:var(--text-muted)]">أيام متبقية</th>
                  <th className="px-4 py-3 text-start text-xs font-semibold text-[color:var(--text-muted)]">إنجازات</th>
                  <th className="px-4 py-3 text-start text-xs font-semibold text-[color:var(--text-muted)]">خطوات مكتملة</th>
                  <th className="px-4 py-3 text-start text-xs font-semibold text-[color:var(--text-muted)]">اختراق</th>
                </tr>
              </thead>
              <tbody>
                {renewals.map((r) => (
                  <tr key={r.follower_id} className="border-b last:border-b-0 hover:bg-[color:var(--surface-2)]">
                    <td className="px-4 py-3">
                      <Link href={`/followers/${r.follower_id}`} className="font-medium text-[color:var(--primary)] hover:underline">
                        {r.first_name || `مستخدم ${r.platform_user_id.slice(-4)}`}
                      </Link>
                    </td>
                    <td className="px-4 py-3 text-xs">{formatDate(r.subscription_expires_at)}</td>
                    <td className="px-4 py-3">
                      <Badge tone={r.days_left <= 7 ? "error" : r.days_left <= 14 ? "warning" : "success"}>
                        {formatNumber(r.days_left)} يوماً
                      </Badge>
                    </td>
                    <td className="tabular px-4 py-3">{formatNumber(r.win_count)}</td>
                    <td className="tabular px-4 py-3">{formatNumber(r.completed_steps)}</td>
                    <td className="px-4 py-3">{r.has_breakthrough ? <Badge tone="gold">نعم</Badge> : <span className="text-xs text-[color:var(--text-muted)]">لا</span>}</td>
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
