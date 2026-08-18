"use client";

import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip } from "recharts";
import { formatNumber, formatPercent } from "@/lib/format";

const SLICE_COLORS = ["var(--primary)", "var(--gold)", "var(--text-muted)"];

export interface DonutSlice {
  name: string;
  value: number;
}

/**
 * مخصص للانقسامات الثنائية (مجاني/مدفوع...) — راجع dataviz skill: الألوان
 * الفرعية للعلامة لا تجتاز فحص فصل الألوان لأكثر من صنفين، لذا أي فئة زائدة
 * تُجمَّع تلقائياً في "أخرى" بلون محايد، مع legend نصي كامل دائماً (لا يعتمد
 * على اللون وحده للتمييز).
 */
export function Donut({ data, centerLabel }: { data: DonutSlice[]; centerLabel?: string }) {
  const total = data.reduce((s, d) => s + d.value, 0);
  const merged =
    data.length > 2
      ? [...data.slice(0, 2), { name: "أخرى", value: data.slice(2).reduce((s, d) => s + d.value, 0) }]
      : data;

  return (
    <div className="flex flex-col items-center gap-4 sm:flex-row sm:items-center sm:justify-center">
      <div className="relative h-44 w-44 shrink-0">
        <ResponsiveContainer width="100%" height="100%">
          <PieChart>
            <Pie data={merged} dataKey="value" nameKey="name" innerRadius={52} outerRadius={78} paddingAngle={2}>
              {merged.map((entry, i) => (
                <Cell key={entry.name} fill={SLICE_COLORS[i % SLICE_COLORS.length]} stroke="var(--surface)" strokeWidth={2} />
              ))}
            </Pie>
            <Tooltip
              contentStyle={{
                background: "var(--surface)",
                border: "1px solid var(--border)",
                borderRadius: 10,
                fontSize: 12,
                direction: "rtl",
              }}
              formatter={(value: number, name: string) => [formatNumber(value), name]}
            />
          </PieChart>
        </ResponsiveContainer>
        {centerLabel && (
          <div className="pointer-events-none absolute inset-0 flex flex-col items-center justify-center">
            <span className="tabular text-lg font-bold text-[color:var(--text)]">{formatNumber(total)}</span>
            <span className="text-[10px] text-[color:var(--text-muted)]">{centerLabel}</span>
          </div>
        )}
      </div>

      <ul className="flex flex-col gap-2">
        {merged.map((entry, i) => (
          <li key={entry.name} className="flex items-center gap-2 text-sm">
            <span
              className="h-2.5 w-2.5 shrink-0 rounded-full"
              style={{ backgroundColor: SLICE_COLORS[i % SLICE_COLORS.length] }}
            />
            <span className="text-[color:var(--text-secondary)]">{entry.name}</span>
            <span className="tabular font-medium text-[color:var(--text)]">{formatNumber(entry.value)}</span>
            <span className="text-xs text-[color:var(--text-muted)]">
              ({formatPercent(total ? entry.value / total : 0)})
            </span>
          </li>
        ))}
      </ul>
    </div>
  );
}
