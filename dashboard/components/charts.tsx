"use client";

import { Bar, BarChart, CartesianGrid, Legend, Line, LineChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";

type Series = { key: string; name: string; color: string };

const axis = { fontSize: 11, fill: "var(--muted)" };
const tip = { contentStyle: { background: "var(--surface)", border: "1px solid var(--border)", borderRadius: 10, fontSize: 12, direction: "rtl" as const } };

export function LineSeries({ data, x, series, height = 240 }: { data: Record<string, unknown>[]; x: string; series: Series[]; height?: number }) {
  return (
    <div dir="ltr" style={{ height }}>
      <ResponsiveContainer>
        <LineChart data={data} margin={{ top: 8, right: 8, left: -18, bottom: 0 }}>
          <CartesianGrid stroke="var(--track)" vertical={false} />
          <XAxis dataKey={x} tick={axis} tickLine={false} axisLine={false} interval="preserveStartEnd" />
          <YAxis tick={axis} tickLine={false} axisLine={false} allowDecimals={false} />
          <Tooltip {...tip} />
          <Legend wrapperStyle={{ fontSize: 12, direction: "rtl" }} />
          {series.map((s) => (
            <Line key={s.key} type="monotone" dataKey={s.key} name={s.name} stroke={s.color} strokeWidth={2} dot={false} />
          ))}
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
}

export function Columns({ data, x, y, name, color = "var(--primary)", height = 200 }: { data: Record<string, unknown>[]; x: string; y: string; name: string; color?: string; height?: number }) {
  return (
    <div dir="ltr" style={{ height }}>
      <ResponsiveContainer>
        <BarChart data={data} margin={{ top: 8, right: 8, left: -18, bottom: 0 }}>
          <CartesianGrid stroke="var(--track)" vertical={false} />
          <XAxis dataKey={x} tick={axis} tickLine={false} axisLine={false} interval={2} />
          <YAxis tick={axis} tickLine={false} axisLine={false} allowDecimals={false} />
          <Tooltip {...tip} cursor={{ fill: "var(--track)" }} />
          <Bar dataKey={y} name={name} fill={color} radius={[4, 4, 0, 0]} />
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}
