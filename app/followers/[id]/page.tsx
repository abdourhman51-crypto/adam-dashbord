import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { ArrowRight } from "lucide-react";
import { Card, Badge, funnelTone, EmptyState, StatRow } from "@/components/ui";
import {
  getFollowerById,
  getPlanSessionByFollower,
  getMemoryEvents,
  getChildPatterns,
  getChildren,
  getDailyLogs,
  getWeeklyPlans,
  getChatSample,
  getSupportedCountries,
  defaultPriceFor,
} from "@/lib/queries";
import ActivateSubscription from "@/components/ActivateSubscription";
import ReturnToFree from "@/components/ReturnToFree";
import {
  FUNNEL_LABELS,
  OFFER_LABELS,
  EVENT_LABELS,
  PATTERN_LABELS,
  formatDate,
  formatDateTime,
  formatNumber,
  relativeTime,
} from "@/lib/format";

export const metadata: Metadata = { title: "ملف المتابع" };
export const revalidate = 60;

const eventTone: Record<string, "success" | "gold" | "error" | "violet" | "info" | "muted"> = {
  win: "success",
  breakthrough: "gold",
  setback: "error",
  disclosure: "violet",
  milestone: "info",
  pattern_change: "info",
  other: "muted",
};

export default async function FollowerProfile({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const follower = await getFollowerById(id);
  if (!follower) notFound();

  const [plan, events, patterns, children, logs, weeklyPlans, chat, countries] = await Promise.all([
    getPlanSessionByFollower(id),
    getMemoryEvents(id),
    getChildPatterns(id),
    getChildren(id),
    getDailyLogs(id),
    getWeeklyPlans(id),
    getChatSample(follower.platform_user_id, 20),
    getSupportedCountries(),
  ]);

  const name = follower.first_name || follower.username || `مستخدم ${follower.platform_user_id.slice(-4)}`;
  const price = defaultPriceFor(countries, follower.country);

  return (
    <div className="space-y-6">
      <Link href="/followers" className="inline-flex items-center gap-1 text-sm text-[color:var(--primary)] hover:underline">
        <ArrowRight size={16} aria-hidden />
        عودة إلى المتابعين
      </Link>

      {/* بطاقة الهوية */}
      <Card>
        <div className="flex flex-wrap items-start justify-between gap-4">
          <div>
            <h2 className="text-xl font-bold">{name}</h2>
            <div className="tabular mt-1 text-xs text-[color:var(--text-muted)]" dir="ltr">
              Telegram · {follower.platform_user_id}
            </div>
          </div>
          <div className="flex flex-col items-end gap-3">
            <div className="flex flex-wrap justify-end gap-2">
              <Badge tone={funnelTone[follower.funnel_stage ?? "free_conversation"] ?? "muted"}>
                {FUNNEL_LABELS[follower.funnel_stage ?? ""] ?? follower.funnel_stage}
              </Badge>
              <Badge tone="muted">{OFFER_LABELS[follower.offer_status] ?? follower.offer_status}</Badge>
              {follower.waitlist && <Badge tone="violet">قائمة انتظار</Badge>}
            </div>
            <div className="flex flex-wrap items-center justify-end gap-2">
              <ActivateSubscription
                followerId={follower.id}
                name={name}
                defaultAmount={price.amount}
                defaultCurrency={price.currency}
                currentStage={follower.funnel_stage}
              />
              {follower.funnel_stage === "paid_active" && (
                <ReturnToFree followerId={follower.id} name={name} />
              )}
            </div>
          </div>
        </div>

        {follower.funnel_stage === "payment_pending_manual" && (
          <div className="mt-4 rounded-xl border border-s-4 border-s-[color:var(--warning)] bg-[color:var(--warning-soft)] p-3 text-xs leading-relaxed text-[color:var(--warning)]">
            هذا المتابع طلب الاشتراك وينتظر تأكيد الدفع
            {follower.payment_pending_at ? ` (منذ ${relativeTime(follower.payment_pending_at)})` : ""}.
            بعد استلام الدفع من وكيل الدفع، اضغط «تأكيد الدفع وتفعيل الاشتراك».
          </div>
        )}
        <div className="mt-4 grid gap-x-8 sm:grid-cols-2 lg:grid-cols-3">
          <StatRow label="أول ظهور" value={formatDate(follower.first_seen)} />
          <StatRow label="آخر نشاط" value={relativeTime(follower.last_active)} />
          <StatRow label="عدد الرسائل" value={formatNumber(follower.message_count)} />
          <StatRow label="الدولة" value={follower.country?.trim() || "غير مسجَّلة"} />
          <StatRow label="بداية الاشتراك" value={formatDate(follower.subscription_started_at)} />
          <StatRow label="نهاية الاشتراك" value={formatDate(follower.subscription_expires_at)} />
        </div>
        {follower.judge_reason && (
          <div className="mt-4 rounded-xl bg-[color:var(--surface-2)] p-3 text-xs leading-relaxed text-[color:var(--text-secondary)]">
            <span className="font-semibold">تقييم آدم الآلي: </span>
            {follower.judge_reason}
          </div>
        )}
      </Card>

      <div className="grid gap-4 lg:grid-cols-2">
        {/* البرنامج التربوي */}
        <Card title="رحلة البرنامج" subtitle="جلسة الخطة المرتبطة بهذا المتابع">
          {!plan ? (
            <EmptyState title="لا توجد خطة بعد" body="تُنشأ الخطة عند دخول المتابع البرنامج التربوي." />
          ) : (
            <div>
              <StatRow label="الأسبوع الحالي" value={`الأسبوع ${formatNumber(plan.current_week)} · اليوم ${formatNumber(plan.current_day)}`} />
              <StatRow label="اسم الطفل" value={plan.child_name || follower.offer_child_name || "—"} />
              <StatRow label="عمر الطفل" value={plan.child_age || "—"} />
              <StatRow label="صلة المربّي" value={plan.relation_to_child || "—"} />
              <StatRow label="عدد الجلسات" value={formatNumber(plan.session_count)} />
              <StatRow label="اكتملت التهيئة" value={plan.onboarding_complete ? "نعم" : "لا"} />
              <StatRow label="اختراق تربوي" value={plan.has_breakthrough ? "نعم ✨" : "ليس بعد"} />
              {plan.main_challenge && (
                <div className="mt-3 rounded-xl bg-[color:var(--gold-soft)] p-3 text-xs leading-relaxed">
                  <span className="font-semibold text-[color:var(--gold-strong)]">التحدي الرئيسي: </span>
                  {plan.main_challenge}
                </div>
              )}
              {plan.next_step && (
                <div className="mt-2 rounded-xl bg-[color:var(--primary-soft)] p-3 text-xs leading-relaxed">
                  <span className="font-semibold text-[color:var(--primary)]">الخطوة التالية: </span>
                  {plan.next_step}
                </div>
              )}
            </div>
          )}
        </Card>

        {/* الأطفال والأنماط */}
        <Card title="الأطفال والأنماط السلوكية" subtitle="ما تعلّمه آدم عن أسرة هذا المتابع">
          {children.length === 0 && patterns.length === 0 ? (
            <EmptyState title="لا توجد بيانات أطفال بعد" />
          ) : (
            <div className="space-y-4">
              {children.map((c) => (
                <div key={c.id} className="rounded-xl border p-3">
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-semibold">{c.name}</span>
                    {c.is_primary && <Badge tone="gold">الطفل الأساسي</Badge>}
                  </div>
                  <div className="mt-1 text-xs text-[color:var(--text-muted)]">
                    {[c.gender, c.birth_year ? `مواليد ${c.birth_year}` : c.age_note, c.temperament]
                      .filter(Boolean)
                      .join(" · ") || "لا تفاصيل إضافية"}
                  </div>
                </div>
              ))}
              {patterns.map((p) => (
                <div key={p.id} className="rounded-xl border p-3">
                  <div className="flex items-center justify-between gap-2">
                    <span className="text-sm font-medium">{p.pattern_label}</span>
                    <Badge tone={p.status === "improving" ? "success" : p.status === "resolved" ? "info" : "warning"}>
                      {PATTERN_LABELS[p.status] ?? p.status}
                    </Badge>
                  </div>
                  {p.description && <p className="mt-1 text-xs leading-relaxed text-[color:var(--text-secondary)]">{p.description}</p>}
                  <div className="mt-1 text-xs text-[color:var(--text-muted)]">
                    شواهد: {formatNumber(p.evidence_count)} · آخر رصد {relativeTime(p.last_observed)}
                  </div>
                </div>
              ))}
            </div>
          )}
        </Card>
      </div>

      {/* الخط الزمني للذاكرة */}
      <Card title="الخط الزمني للأحداث" subtitle="أحداث الذاكرة الموثَّقة — إنجازات، اختراقات، مصارحات">
        {events.length === 0 ? (
          <EmptyState title="لا أحداث موثَّقة بعد" />
        ) : (
          <ol className="relative space-y-4 border-s-2 border-[color:var(--border)] ps-5">
            {events.map((e) => (
              <li key={e.id} className="relative">
                <span className="absolute -start-6.75 top-1.5 h-3 w-3 rounded-full bg-[color:var(--gold)]" aria-hidden />
                <div className="flex flex-wrap items-center gap-2">
                  <Badge tone={eventTone[e.event_type] ?? "muted"}>{EVENT_LABELS[e.event_type] ?? e.event_type}</Badge>
                  <span className="text-xs text-[color:var(--text-muted)]">{formatDateTime(e.occurred_at)}</span>
                  <span className="text-xs text-[color:var(--gold-strong)]">{"★".repeat(e.emotional_weight)}</span>
                </div>
                <h3 className="mt-1 text-sm font-semibold">{e.title}</h3>
                {e.summary && <p className="mt-0.5 text-xs leading-relaxed text-[color:var(--text-secondary)]">{e.summary}</p>}
              </li>
            ))}
          </ol>
        )}
      </Card>

      <div className="grid gap-4 lg:grid-cols-2">
        {/* السجل اليومي والخطط الأسبوعية */}
        <Card title="السجل اليومي والخطط" subtitle="متابعة الخطوات اليومية والأسابيع">
          {logs.length === 0 && weeklyPlans.length === 0 ? (
            <EmptyState title="لا سجلات يومية بعد" />
          ) : (
            <div className="space-y-3">
              {weeklyPlans.map((w) => (
                <div key={w.id} className="rounded-xl border p-3">
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-semibold">الأسبوع {formatNumber(w.week_number)}</span>
                    <Badge tone={w.status === "done" ? "success" : w.status === "active" ? "gold" : "muted"}>
                      {w.status === "done" ? "مكتمل" : w.status === "active" ? "جارٍ" : w.status === "skipped" ? "متجاوَز" : "مخطَّط"}
                    </Badge>
                  </div>
                  {w.focus && <p className="mt-1 text-xs text-[color:var(--text-secondary)]">{w.focus}</p>}
                </div>
              ))}
              {logs.map((l) => (
                <div key={l.id} className="rounded-xl border p-3">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-semibold">{formatDate(l.log_date)}</span>
                    {l.step_completed !== null && (
                      <Badge tone={l.step_completed ? "success" : "warning"}>
                        {l.step_completed ? "أُنجزت الخطوة" : "لم تُنجز"}
                      </Badge>
                    )}
                  </div>
                  {l.summary && <p className="mt-1 text-xs leading-relaxed text-[color:var(--text-secondary)]">{l.summary}</p>}
                  {l.step_given && (
                    <p className="mt-1 text-xs text-[color:var(--text-muted)]">الخطوة: {l.step_given}</p>
                  )}
                </div>
              ))}
            </div>
          )}
        </Card>

        {/* آخر المحادثة */}
        <Card title="آخر المحادثة" subtitle="آخر 20 رسالة بين المتابع وآدم">
          {chat.length === 0 ? (
            <EmptyState title="لا تتوفر محادثات لهذا المعرّف" />
          ) : (
            <div className="max-h-120 space-y-2 overflow-y-auto pe-1">
              {chat.map((m) => (
                <div
                  key={m.id}
                  className={`max-w-[85%] rounded-2xl px-3.5 py-2 text-xs leading-relaxed ${
                    m.type === "human"
                      ? "me-auto bg-[color:var(--surface-2)] text-[color:var(--text)]"
                      : "ms-auto bg-[color:var(--primary-soft)] text-[color:var(--text)]"
                  }`}
                >
                  <span className="mb-0.5 block text-[10px] font-semibold text-[color:var(--text-muted)]">
                    {m.type === "human" ? "المتابع" : "آدم"}
                  </span>
                  {(m.content ?? "").slice(0, 500)}
                </div>
              ))}
            </div>
          )}
        </Card>
      </div>
    </div>
  );
}
