import Link from "next/link";
import { Card } from "@/components/ui/Card";
import { Badge, funnelTone } from "@/components/ui/Badge";
import { Table, type TableColumn } from "@/components/ui/Table";
import { listCustomers, listCountries } from "@/lib/queries/customers";
import { FUNNEL_STAGE_LABELS, formatDate, formatNumber } from "@/lib/format";
import type { Follower } from "@/lib/types";

export const dynamic = "force-dynamic";
export const revalidate = 0;

export default async function CustomersPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; country?: string; status?: string; from?: string; to?: string; includeTest?: string }>;
}) {
  const raw = await searchParams;
  const includeTest = raw.includeTest === "1";
  const filters = { ...raw, includeTest };
  const [customers, countries] = await Promise.all([listCustomers(filters), listCountries()]);

  const columns: TableColumn<Follower>[] = [
    {
      key: "name",
      header: "العميل",
      render: (f) => (
        <Link href={`/customers/${f.id}`} className="font-medium text-[color:var(--text)] hover:text-[color:var(--primary)]">
          {f.first_name || f.username || `عميل ${f.platform_user_id.slice(-4)}`}
        </Link>
      ),
    },
    { key: "country", header: "البلد", render: (f) => f.country ?? "—" },
    {
      key: "status",
      header: "الحالة",
      render: (f) => <Badge tone={funnelTone(f.funnel_stage)}>{FUNNEL_STAGE_LABELS[f.funnel_stage] ?? f.funnel_stage}</Badge>,
    },
    { key: "joined", header: "تاريخ الانضمام", render: (f) => formatDate(f.first_seen) },
  ];

  return (
    <div className="flex flex-col gap-6">
      <Card noPadding>
        <form className="grid grid-cols-1 gap-3 p-5 sm:grid-cols-2 lg:grid-cols-5">
          <input
            name="q"
            defaultValue={filters.q}
            placeholder="ابحث بالاسم أو المعرّف…"
            className="rounded-lg border border-[color:var(--border)] bg-[color:var(--surface)] px-3 py-2 text-sm outline-none focus:border-[color:var(--primary)] lg:col-span-2"
          />
          <select
            name="country"
            defaultValue={filters.country ?? ""}
            className="rounded-lg border border-[color:var(--border)] bg-[color:var(--surface)] px-3 py-2 text-sm outline-none focus:border-[color:var(--primary)]"
          >
            <option value="">كل البلدان</option>
            {countries.map((c) => (
              <option key={c} value={c}>
                {c}
              </option>
            ))}
          </select>
          <select
            name="status"
            defaultValue={filters.status ?? ""}
            className="rounded-lg border border-[color:var(--border)] bg-[color:var(--surface)] px-3 py-2 text-sm outline-none focus:border-[color:var(--primary)]"
          >
            <option value="">كل الحالات</option>
            {Object.entries(FUNNEL_STAGE_LABELS).map(([key, label]) => (
              <option key={key} value={key}>
                {label}
              </option>
            ))}
          </select>
          <button
            type="submit"
            className="rounded-lg bg-[color:var(--primary)] px-4 py-2 text-sm font-semibold text-[color:var(--on-primary)] transition hover:bg-[color:var(--primary-strong)]"
          >
            تصفية
          </button>
          <label className="flex items-center gap-2 text-sm text-[color:var(--text-muted)] lg:col-span-5">
            <input type="checkbox" name="includeTest" value="1" defaultChecked={includeTest} className="h-4 w-4" />
            إظهار حسابي الاختبار (مستبعَدان افتراضياً من كل القوائم والإحصائيات)
          </label>
        </form>
      </Card>

      <Card title="العملاء" subtitle={`${formatNumber(customers.length)} نتيجة`}>
        <Table
          columns={columns}
          rows={customers}
          rowKey={(f) => f.id}
          emptyTitle="لا نتائج مطابقة"
          emptyBody="جرّب تعديل الفلاتر."
        />
      </Card>
    </div>
  );
}
