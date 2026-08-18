import type { ReactNode } from "react";
import { EmptyState } from "./EmptyState";

export interface TableColumn<T> {
  key: string;
  header: string;
  render: (row: T) => ReactNode;
  /** يُستبعد من عرض البطاقات على الهاتف (مثلاً عمود إجراءات مكرر) */
  hideOnMobile?: boolean;
  align?: "start" | "end" | "center";
  className?: string;
}

export function Table<T>({
  columns,
  rows,
  rowKey,
  emptyTitle = "لا توجد بيانات",
  emptyBody,
  onRowClick,
}: {
  columns: TableColumn<T>[];
  rows: T[];
  rowKey: (row: T) => string;
  emptyTitle?: string;
  emptyBody?: ReactNode;
  onRowClick?: (row: T) => void;
}) {
  if (rows.length === 0) {
    return <EmptyState title={emptyTitle} body={emptyBody} />;
  }

  return (
    <>
      {/* سطح المكتب: جدول حقيقي بتمرير أفقي داخلي فقط عند الحاجة */}
      <div className="hidden overflow-x-auto md:block">
        <table className="w-full min-w-max border-collapse text-sm">
          <thead>
            <tr className="border-b border-[color:var(--border)] text-xs text-[color:var(--text-muted)]">
              {columns.map((col) => (
                <th
                  key={col.key}
                  className={`whitespace-nowrap px-3 py-2.5 font-medium ${
                    col.align === "end" ? "text-left" : col.align === "center" ? "text-center" : "text-right"
                  }`}
                >
                  {col.header}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {rows.map((row) => (
              <tr
                key={rowKey(row)}
                onClick={onRowClick ? () => onRowClick(row) : undefined}
                className={`border-b border-[color:var(--border)] last:border-0 ${
                  onRowClick ? "cursor-pointer hover:bg-[color:var(--surface-2)]" : ""
                }`}
              >
                {columns.map((col) => (
                  <td
                    key={col.key}
                    className={`px-3 py-3 align-middle ${
                      col.align === "end" ? "text-left" : col.align === "center" ? "text-center" : "text-right"
                    } ${col.className ?? ""}`}
                  >
                    {col.render(row)}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* الهاتف: كل صف يتحوّل لبطاقة */}
      <div className="flex flex-col gap-3 md:hidden">
        {rows.map((row) => (
          <div
            key={rowKey(row)}
            onClick={onRowClick ? () => onRowClick(row) : undefined}
            className={`rounded-xl border border-[color:var(--border)] bg-[color:var(--surface-2)] p-4 ${
              onRowClick ? "cursor-pointer active:opacity-80" : ""
            }`}
          >
            <div className="flex flex-col gap-2">
              {columns
                .filter((c) => !c.hideOnMobile)
                .map((col) => (
                  <div key={col.key} className="flex items-center justify-between gap-3 text-sm">
                    <span className="shrink-0 text-xs text-[color:var(--text-muted)]">{col.header}</span>
                    <span className="text-left">{col.render(row)}</span>
                  </div>
                ))}
            </div>
          </div>
        ))}
      </div>
    </>
  );
}
