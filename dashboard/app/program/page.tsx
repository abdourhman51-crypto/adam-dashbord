import type { Metadata } from "next";
import Link from "next/link";
import { Sprout, Sparkles, ClipboardCheck, CalendarDays } from "lucide-react";
import { Card, KpiCard, Badge, EmptyState } from "@/components/ui";
import { Donut } from "@/components/charts";
import { getPlanSessions, getMemoryEvents, getChildPatterns, getFollowers, getDailyLogs } from "@/lib/queries";
import { formatNumber, formatPercent, EVENT_LABELS, PATTERN_LABELS, relativeTime, formatDateTime } from "@/lib/format";

export const metadata: Metadata = { title: "البرنامج التربوي" };
export const revalidate = 60;

export default async function ProgramPage() {
  const [plans, events, patterns, followers, logs] = await Promise.all([
    getPlanSessions(),
    getMemoryEvents(),
    getChildPatterns(),
    getFollowers(),
    getDailyLogs(),
  ]);

  const followerName = new Map(
    followers.map((f) => [f.id, f.first_name || f.username || `مستخدم ${f.platform_user_id.slice(-4)}`])
  );

  const onboarded = plans.filter((p) => p.onboarding_complete).length;
  const breakthroughs = plans.filter((p) => p.has_breakthrough).length;
  const stepsDone = logs.filter((l) => l.step_completed === true).length;

  const eventDist = Object.entries(
    events.reduce<Record<string, number>>((acc, e) => {
      acc[e.event_type] = (acc[e.event_type] ?? 0) + 1;
      return acc;
    }, {})
  ).map(([k, v]) => ({ name: EVENT_LABELS[k] ?? k, value: v }));

  const patternDist = Object.entries(
    patterns.reduce<Record<string, number>>((acc, p) => {
      acc[p.status] = (acc[p.status] ?? 0) + 1;
      return acc;
    }, {})
  ).map(([k, v]) => ({ name: PATTERN_LABELS[k] ?? k, value: v }));

  const challenges = plans
    .filter((p) => p.main_challenge)
    .sort((a, b) => +new Date(b.updated_at ?? 0) - +new Date(a.updated_at ?? 0));

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-2 gap-3 xl:grid-cols-4">
        <KpiCard label="جلسات خطة" value={formatNumber(plans.length)} hint="كلها في الأسبوع الأول حالياً" icon={<Sprout size={20} />} />
        <KpiCard label="أكملوا التهيئة" value={formatNumber(onboarded)} hint={formatPercent(plans.length ? onboarded / plans.length : 0)} icon={<ClipboardCheck size={20} />} tone="info" />
        <KpiCard label="اختراقات تربوية" value={formatNumber(breakthroughs)} hint="لحظات تحوّل موثَّقة" icon={<Sparkles size={20} />} tone="gold" />
        <KpiCard label="خطوات يومية منجَزة" value={formatNumber(stepsDone)} hint={`من ${formatNumber(logs.length)} سجلات`} icon={<CalendarDays size={20} />} tone="success" />
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <Card title="أنواع الأحداث الموثَّقة" subtitle="ذاكرة آدم طويلة المدى — memory_events">
          {eventDist.length === 0 ? <EmptyState title="لا أحداث بعد" /> : <Donut data={eventDist} label="أنواع الأحداث" />}
        </Card>
        <Card title="حالة الأنماط السلوكية" subtitle="أنماط الأطفال المرصودة — child_patterns">
          {patternDist.length === 0 ? <EmptyState title="لا أنماط مرصودة بعد" /> : <Donut data={patternDist} label="حالة الأنماط" />}
        </Card>
      </div>

      <Card
        title="التحديات التربوية الحقيقية"
        subtitle={`ما يشغل بال المربّين فعلاً — ${formatNumber(challenges.length)} تحدياً موثَّقاً بكلمات أصحابه`}
      >
        {challenges.length === 0 ? (
          <EmptyState title="لا تحديات موثَّقة بعد" />
        ) : (
          <ul className="grid gap-3 md:grid-cols-2">
            {challenges.map((p) => (
              <li key={p.id} className="rounded-xl border p-4">
                <p className="text-sm leading-relaxed">{p.main_challenge}</p>
                <div className="mt-2 flex flex-wrap items-center gap-2 text-xs text-[color:var(--text-muted)]">
                  {p.follower_id && followerName.has(p.follower_id) && (
                    <Link href={`/followers/${p.follower_id}`} className="font-medium text-[color:var(--primary)] hover:underline">
                      {followerName.get(p.follower_id)}
                    </Link>
                  )}
                  {p.child_name && <span>· الطفل: {p.child_name}</span>}
                  {p.child_age && <span>· العمر: {p.child_age}</span>}
                  {p.has_breakthrough && <Badge tone="gold">اختراق ✨</Badge>}
                </div>
              </li>
            ))}
          </ul>
        )}
      </Card>

      <Card title="آخر الأحداث عبر كل الأسر" subtitle="الخط الزمني الجامع لأحداث الذاكرة">
        {events.length === 0 ? (
          <EmptyState title="لا أحداث موثَّقة" />
        ) : (
          <ol className="relative space-y-4 border-s-2 border-[color:var(--border)] ps-5">
            {events.slice(0, 12).map((e) => (
              <li key={e.id} className="relative">
                <span className="absolute -start-6.75 top-1.5 h-3 w-3 rounded-full bg-[color:var(--gold)]" aria-hidden />
                <div className="flex flex-wrap items-center gap-2">
                  <Badge tone={e.event_type === "breakthrough" ? "gold" : e.event_type === "setback" ? "error" : "info"}>
                    {EVENT_LABELS[e.event_type] ?? e.event_type}
                  </Badge>
                  {followerName.has(e.follower_id) && (
                    <Link href={`/followers/${e.follower_id}`} className="text-xs font-medium text-[color:var(--primary)] hover:underline">
                      {followerName.get(e.follower_id)}
                    </Link>
                  )}
                  <span className="text-xs text-[color:var(--text-muted)]">{formatDateTime(e.occurred_at)}</span>
                </div>
                <h3 className="mt-1 text-sm font-semibold">{e.title}</h3>
                {e.summary && <p className="mt-0.5 text-xs leading-relaxed text-[color:var(--text-secondary)]">{e.summary}</p>}
              </li>
            ))}
          </ol>
        )}
      </Card>

      <Card title="السجلات اليومية الأخيرة" subtitle="متابعة الخطوات اليومية للمربّين">
        {logs.length === 0 ? (
          <EmptyState title="لا سجلات يومية بعد" />
        ) : (
          <div className="grid gap-3 md:grid-cols-2">
            {logs.slice(0, 8).map((l) => (
              <div key={l.id} className="rounded-xl border p-4">
                <div className="flex items-center justify-between">
                  {l.follower_id && followerName.has(l.follower_id) ? (
                    <Link href={`/followers/${l.follower_id}`} className="text-sm font-semibold text-[color:var(--primary)] hover:underline">
                      {followerName.get(l.follower_id)}
                    </Link>
                  ) : (
                    <span className="text-sm font-semibold">سجل يومي</span>
                  )}
                  {l.step_completed !== null && (
                    <Badge tone={l.step_completed ? "success" : "warning"}>
                      {l.step_completed ? "أُنجزت" : "لم تُنجز"}
                    </Badge>
                  )}
                </div>
                {l.summary && <p className="mt-2 text-xs leading-relaxed text-[color:var(--text-secondary)]">{l.summary}</p>}
                <div className="mt-2 text-xs text-[color:var(--text-muted)]">{relativeTime(l.log_date)}</div>
              </div>
            ))}
          </div>
        )}
      </Card>
    </div>
  );
}
