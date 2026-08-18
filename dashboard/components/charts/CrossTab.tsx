/**
 * جدول تقاطع (بلد × مشكلة...) بتظليل أحادي اللون حسب القيمة (تدرّج تسلسلي آمن)
 * — كل خلية تحمل رقمها كنص دائماً.
 */
export function CrossTab({
  rowLabels,
  colLabels,
  cell,
}: {
  rowLabels: string[];
  colLabels: string[];
  cell: (row: string, col: string) => number;
}) {
  const max = Math.max(1, ...rowLabels.flatMap((r) => colLabels.map((c) => cell(r, c))));

  return (
    <div className="overflow-x-auto">
      <table className="w-full min-w-max border-collapse text-xs">
        <thead>
          <tr>
            <th className="sticky right-0 bg-[color:var(--surface)] px-3 py-2 text-right text-[color:var(--text-muted)]" />
            {colLabels.map((c) => (
              <th key={c} className="whitespace-nowrap px-3 py-2 text-center font-medium text-[color:var(--text-muted)]">
                {c}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rowLabels.map((r) => (
            <tr key={r}>
              <td className="sticky right-0 whitespace-nowrap bg-[color:var(--surface)] px-3 py-2 font-medium text-[color:var(--text-secondary)]">
                {r}
              </td>
              {colLabels.map((c) => {
                const v = cell(r, c);
                const alpha = v === 0 ? 0 : 0.12 + 0.68 * (v / max);
                return (
                  <td
                    key={c}
                    className="tabular whitespace-nowrap px-3 py-2 text-center"
                    style={{
                      backgroundColor: v ? `color-mix(in srgb, var(--primary) ${alpha * 100}%, transparent)` : undefined,
                      color: v ? "var(--text)" : "var(--text-muted)",
                    }}
                  >
                    {v || "—"}
                  </td>
                );
              })}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
