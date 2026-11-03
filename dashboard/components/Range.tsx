import Link from "next/link";

export const pickDays = (v: string | string[] | undefined) => {
  const d = Number(Array.isArray(v) ? v[0] : v);
  return [7, 14, 30, 90].includes(d) ? d : 14;
};

export default function Range({ days, path }: { days: number; path: string }) {
  return (
    <div className="flex gap-1 text-xs">
      {[7, 14, 30, 90].map((d) => (
        <Link key={d} href={`${path}?days=${d}`} className={`chip ${d === days ? "chip-on" : ""}`}>
          {d} يوم
        </Link>
      ))}
    </div>
  );
}
