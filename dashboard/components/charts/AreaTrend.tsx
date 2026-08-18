"use client";

import { AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from "recharts";
import { formatNumber } from "@/lib/format";

export function AreaTrend({
  data,
  xKey,
  yKey,
  label,
}: {
  data: Array<Record<string, string | number>>;
  xKey: string;
  yKey: string;
  label: string;
}) {
  return (
    <div className="h-72 w-full">
      <ResponsiveContainer width="100%" height="100%">
        <AreaChart data={data} margin={{ top: 8, right: 8, left: -18, bottom: 0 }}>
          <defs>
            <linearGradient id="areaTrendFill" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="var(--primary)" stopOpacity={0.28} />
              <stop offset="100%" stopColor="var(--primary)" stopOpacity={0} />
            </linearGradient>
          </defs>
          <CartesianGrid stroke="var(--grid-line)" vertical={false} />
          <XAxis
            dataKey={xKey}
            tick={{ fill: "var(--text-muted)", fontSize: 11 }}
            axisLine={{ stroke: "var(--grid-line)" }}
            tickLine={false}
          />
          <YAxis
            allowDecimals={false}
            tick={{ fill: "var(--text-muted)", fontSize: 11 }}
            axisLine={false}
            tickLine={false}
            width={32}
          />
          <Tooltip
            cursor={{ stroke: "var(--primary)", strokeWidth: 1, strokeDasharray: "3 3" }}
            contentStyle={{
              background: "var(--surface)",
              border: "1px solid var(--border)",
              borderRadius: 10,
              fontSize: 12,
              direction: "rtl",
            }}
            labelStyle={{ color: "var(--text)", fontWeight: 600, marginBottom: 4 }}
            formatter={(value: number) => [formatNumber(value), label]}
          />
          <Area
            type="monotone"
            dataKey={yKey}
            stroke="var(--primary)"
            strokeWidth={2}
            fill="url(#areaTrendFill)"
            activeDot={{ r: 4, fill: "var(--primary)" }}
          />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  );
}
