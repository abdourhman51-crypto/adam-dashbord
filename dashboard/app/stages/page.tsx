import Link from "next/link";
import { AlertTriangle } from "lucide-react";
import { Card } from "@/components/ui/Card";
import { Badge } from "@/components/ui/Badge";
import { Table, type TableColumn } from "@/components/ui/Table";
import { getFollowers, getChildren, getStageProgress } from "@/lib/queries/shared";
import { PROBLEM_LABELS, STAGE_STATUS_LABELS, STAGE_PHASE_LABELS, formatNumber } from "@/lib/format";
import type { StageProgress } from "@/lib/types";

export const dynamic = "force-dynamic";
export const revalidate = 0;

function stageStatusTone(status: StageProgress["status"]) {
  if (status === "completed") return "success" as const;
  if (status === "active" || status === "extended") return "primary" as const;
  if (status === "failed" || status === "cancelled") return "error" as const;
  return "muted" as const;
}

export default async function StagesPage() {
  const [stages, followers, children] = await Promise.all([getStageProgress(), getFollowers(), getChildren()]);

  const followerById = new Map(followers.map((f) => [f.id, f]));
  const childById = new Map(children.map((c) => [c.id, c]));

  const rows = stages
    .map((s) => ({
      ...s,
      followerName:
        followerById.get(s.parent_id)?.first_name ||
        followerById.get(s.parent_id)?.username ||
        "والد غير معروف",
      childName: s.child_id ? childById.get(s.child_id)?.name ?? "—" : "—",
      atRisk:
        (s.status === "active" || s.status === "extended") &&
        !s.objective_met &&
        s.days_remaining <= 3,
    }))
    .sort((a, b) => Number(b.atRisk) - Number(a.atRisk) || a.days_remaining - b.days_remaining);

  const atRiskCount = rows.filter((r) => r.atRisk).length;
  const activeCount = rows.filter((r) => r.status === "active" || r.status === "extended").length;

  const columns: TableColumn<(typeof rows)[number]>[] = [
    {
      key: "family",
      header: "العائلة",
      render: (r) => (
        <Link href={`/customers/${r.parent_id}`} className="font-medium text-[color:var(--text)] hover:text-[color:var(--primary)]">
          {r.followerName}
          {r.childName !== "—" && <span className="text-[color:var(--text-muted)]"> · {r.childName}</span>}
        </Link>
      ),
    },
    {
      key: "problem",
      header: "المشكلة",
      render: (r) => PROBLEM_LABELS[r.problem_key] ?? r.problem_key,
    },
    {
      key: "status",
      header: "الحالة",
      render: (r) => (
        <div className="flex items-center gap-1.5">
          <Badge tone={stageStatusTone(r.status)}>{STAGE_STATUS_LABELS[r.status] ?? r.status}</Badge>
          {r.atRisk && (
            <span title="يقترب من نهاية المدة بلا تحقيق الهدف">
              <AlertTriangle size={14} className="text-[color:var(--error)]" />
            </span>
          )}
        </div>
      ),
    },
    { key: "objective", header: "الهدف", render: (r) => <span className="text-xs">{r.objective_text}</span> },
    {
      key: "progress",
      header: "الأيام المسجَّلة",
      render: (r) => (
        <span className="tabular">
          {formatNumber(r.logged_days)} / {formatNumber(r.allowed_days)}
        </span>
      ),
    },
    {
      key: "phase",
      header: "المرحلة",
      render: (r) => STAGE_PHASE_LABELS[r.phase] ?? r.phase,
      hideOnMobile: true,
    },
    {
      key: "remaining",
      header: "الأيام المتبقية",
      render: (r) => (
        <span className={`tabular ${r.atRisk ? "font-semibold text-[color:var(--error)]" : ""}`}>
          {formatNumber(r.days_remaining)}
        </span>
      ),
    },
  ];

  return (
    <div className="flex flex-col gap-6">
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
        <div className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-5">
          <p className="text-xs text-[color:var(--text-muted)]">رحلات نشطة</p>
          <p className="tabular mt-1 text-2xl font-bold">{formatNumber(activeCount)}</p>
        </div>
        <div className="rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-5">
          <p className="text-xs text-[color:var(--text-muted)]">إجمالي الرحلات</p>
          <p className="tabular mt-1 text-2xl font-bold">{formatNumber(rows.length)}</p>
        </div>
        <div className="rounded-2xl border border-[color:var(--error-soft)] bg-[color:var(--error-soft)] p-5">
          <p className="text-xs text-[color:var(--error)]">قريبة من انتهاء المدة بلا هدف</p>
          <p className="tabular mt-1 text-2xl font-bold text-[color:var(--error)]">{formatNumber(atRiskCount)}</p>
        </div>
      </div>

      <Card title="كل الرحلات المدفوعة" subtitle="مرتّبة حسب الأقرب لانتهاء المدة">
        <Table
          columns={columns}
          rows={rows}
          rowKey={(r) => r.stage_id}
          emptyTitle="لا توجد رحلات مدفوعة بعد"
          emptyBody="ستظهر هنا فور بدء أول رحلة عبر تفعيل اشتراك من صفحة عميل."
        />
      </Card>
    </div>
  );
}
