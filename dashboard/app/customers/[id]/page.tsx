import { notFound } from "next/navigation";
import Link from "next/link";
import { ArrowRight } from "lucide-react";
import { Card } from "@/components/ui/Card";
import { Badge, funnelTone } from "@/components/ui/Badge";
import { StatRow } from "@/components/ui/StatRow";
import { getCustomerDetail } from "@/lib/queries/customers";
import { getChatHistory } from "@/lib/queries/chat";
import {
  FUNNEL_STAGE_LABELS,
  STAGE_STATUS_LABELS,
  PROBLEM_LABELS,
  formatDate,
  formatDateTime,
  formatNumber,
  formatCurrency,
} from "@/lib/format";
import { LightMemoryCard } from "@/components/customer/LightMemoryCard";
import { StrainBadge } from "@/components/customer/StrainBadge";
import { ActionBar } from "@/components/customer/ActionBar";
import { ChatWindow } from "@/components/customer/ChatWindow";

export const dynamic = "force-dynamic";
export const revalidate = 0;

export default async function CustomerDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const detail = await getCustomerDetail(id);
  if (!detail) notFound();

  const { follower, children, stages, strain, checkin, payments, childRecords, pendingErasureId } = detail;
  const messages = await getChatHistory(follower.platform_user_id);
  const activeStage = stages.find((s) => s.status === "active" || s.status === "extended") ?? null;
  const hasAnyStage = stages.length > 0;

  return (
    <div className="flex flex-col gap-6">
      <Link href="/customers" className="flex w-fit items-center gap-1.5 text-sm text-[color:var(--text-muted)] hover:text-[color:var(--primary)]">
        <ArrowRight size={15} /> العودة لقائمة العملاء
      </Link>

      <Card>
        <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
          <div className="flex flex-col gap-2">
            <div className="flex flex-wrap items-center gap-2">
              <h2 className="text-lg font-bold text-[color:var(--text)]">
                {follower.first_name || follower.username || `عميل ${follower.platform_user_id.slice(-4)}`}
              </h2>
              <Badge tone={funnelTone(follower.funnel_stage)}>{FUNNEL_STAGE_LABELS[follower.funnel_stage] ?? follower.funnel_stage}</Badge>
            </div>
            <div className="flex flex-wrap gap-x-5 gap-y-1 text-xs text-[color:var(--text-muted)]">
              <span>البلد: {follower.country ?? "—"}</span>
              <span>انضم: {formatDate(follower.first_seen)}</span>
              <span>آخر نشاط: {formatDateTime(follower.last_active)}</span>
              <span>معرّف المنصة: {follower.platform_user_id}</span>
            </div>
            {follower.intention_text && (
              <p className="rounded-lg bg-[color:var(--gold-soft)] px-3 py-2 text-sm text-[color:var(--gold-strong)]">
                نيّته: {follower.intention_text}
              </p>
            )}
          </div>
          <div className="flex flex-col items-start gap-2 sm:items-end">
            <span className="text-xs text-[color:var(--text-muted)]">مستوى الضغط</span>
            <StrainBadge strain={strain} />
          </div>
        </div>
      </Card>

      <Card title="إجراءات">
        <div className="flex flex-wrap items-center gap-2">
          <ActionBar
            followerId={follower.id}
            followerName={follower.first_name || follower.username || follower.platform_user_id}
            hasActiveStage={hasAnyStage}
            agreedObjective={follower.agreed_objective}
            pendingErasureId={pendingErasureId}
          />
          <ChatWindow messages={messages} />
        </div>
      </Card>

      <div className="grid gap-4 lg:grid-cols-2">
        <Card title="الرحلة الحالية">
          {activeStage ? (
            <div className="flex flex-col gap-2 text-sm">
              <StatRow label="المشكلة" value={PROBLEM_LABELS[activeStage.problem_key] ?? activeStage.problem_key} />
              <StatRow label="الحالة" value={<Badge tone="primary">{STAGE_STATUS_LABELS[activeStage.status]}</Badge>} />
              <StatRow label="الهدف" value={activeStage.objective_text} />
              <StatRow
                label="الأيام المسجَّلة"
                value={`${formatNumber(activeStage.logged_days)} / ${formatNumber(activeStage.allowed_days)}`}
              />
              <StatRow label="تحقق الهدف؟" value={activeStage.objective_met ? "نعم" : "ليس بعد"} />
            </div>
          ) : (
            <p className="text-sm text-[color:var(--text-muted)]">لا توجد رحلة نشطة حالياً.</p>
          )}
        </Card>

        <Card title="متابعة الإيقاع (checkin)">
          {checkin ? (
            <div className="flex flex-col gap-2 text-sm">
              <StatRow label="الوتيرة" value={checkin.cadence} />
              <StatRow label="ساعة الإرسال المحلية" value={`${checkin.local_hour}:00`} />
              <StatRow label="تجاهُل متتالٍ" value={formatNumber(checkin.consecutive_ignored)} />
              <StatRow label="آخر رد" value={formatDateTime(checkin.last_responded_at)} />
            </div>
          ) : (
            <p className="text-sm text-[color:var(--text-muted)]">لا توجد بيانات متابعة بعد.</p>
          )}
        </Card>
      </div>

      <Card title="الأطفال">
        {children.length === 0 ? (
          <p className="text-sm text-[color:var(--text-muted)]">لم يُسجَّل اسم طفل بعد.</p>
        ) : (
          <div className="grid gap-4 sm:grid-cols-2">
            {children.map((child) => {
              const rec = childRecords.find((r) => r.child.id === child.id);
              return (
                <div key={child.id} className="rounded-xl border border-[color:var(--border)] p-4">
                  <div className="flex items-center gap-2">
                    <h3 className="font-semibold text-[color:var(--text)]">{child.name ?? "بلا اسم"}</h3>
                    {child.is_primary && <Badge tone="gold">أساسي</Badge>}
                  </div>
                  <p className="mt-1 text-xs text-[color:var(--text-muted)]">
                    {child.age_note ?? "—"} {child.gender ? `· ${child.gender}` : ""}
                  </p>
                  {rec?.record ? (
                    <div className="mt-3 flex flex-col gap-2 text-xs">
                      {Array.isArray((rec.record as { what_calms?: unknown[] }).what_calms) &&
                        (rec.record as { what_calms: { step: string; worked: number }[] }).what_calms.length > 0 && (
                          <div>
                            <span className="font-medium text-[color:var(--text-secondary)]">ما يهدّئه: </span>
                            {(rec.record as { what_calms: { step: string }[] }).what_calms
                              .slice(0, 3)
                              .map((w) => w.step)
                              .join("، ")}
                          </div>
                        )}
                      {Array.isArray((rec.record as { what_triggers?: unknown[] }).what_triggers) &&
                        (rec.record as { what_triggers: { label: string }[] }).what_triggers.length > 0 && (
                          <div>
                            <span className="font-medium text-[color:var(--text-secondary)]">مثيرات متكررة: </span>
                            {(rec.record as { what_triggers: { label: string }[] }).what_triggers
                              .slice(0, 3)
                              .map((w) => w.label)
                              .join("، ")}
                          </div>
                        )}
                    </div>
                  ) : (
                    <p className="mt-3 text-xs text-[color:var(--text-muted)]">{rec?.reason === "rate_limited_7d" ? "السجل مُقيَّد مؤقتاً." : "لا سجل كافٍ بعد."}</p>
                  )}
                </div>
              );
            })}
          </div>
        )}
      </Card>

      <LightMemoryCard raw={follower.light_memory} updatedAt={follower.light_memory_updated_at} />

      <Card title="سجل المدفوعات">
        {payments.length === 0 ? (
          <p className="text-sm text-[color:var(--text-muted)]">لا مدفوعات مسجَّلة بعد.</p>
        ) : (
          <div className="flex flex-col divide-y divide-[color:var(--border)]">
            {payments.map((p) => (
              <div key={p.id} className="flex items-center justify-between gap-3 py-2.5 text-sm">
                <div>
                  <span className="font-medium">{formatCurrency(p.amount, p.currency)}</span>
                  <span className="mr-2 text-xs text-[color:var(--text-muted)]">{p.plan_type}</span>
                </div>
                <div className="flex items-center gap-2 text-xs text-[color:var(--text-muted)]">
                  <Badge tone={p.status === "confirmed" ? "success" : "muted"}>{p.status}</Badge>
                  {formatDate(p.created_at)}
                </div>
              </div>
            ))}
          </div>
        )}
      </Card>

      {stages.length > 1 && (
        <Card title="سجل الرحلات السابقة">
          <div className="flex flex-col divide-y divide-[color:var(--border)]">
            {stages
              .filter((s) => s.stage_id !== activeStage?.stage_id)
              .map((s) => (
                <div key={s.stage_id} className="flex items-center justify-between gap-3 py-2.5 text-sm">
                  <span>{PROBLEM_LABELS[s.problem_key] ?? s.problem_key}</span>
                  <Badge tone={s.status === "completed" ? "success" : s.status === "failed" ? "error" : "muted"}>
                    {STAGE_STATUS_LABELS[s.status]}
                  </Badge>
                </div>
              ))}
          </div>
        </Card>
      )}
    </div>
  );
}
