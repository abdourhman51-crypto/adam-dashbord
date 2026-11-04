import Link from "next/link";

export const pickDays = (v: string | string[] | undefined) => {
  const d = Number(Array.isArray(v) ? v[0] : v);
  return v != null && v !== "" && [0, 7, 14, 30, 90].includes(d) ? d : 0;
};

export default function Range({ days, path }: { days: number; path: string }) {
  return (
    <div className="flex gap-1 text-xs">
      {[0, 7, 14, 30, 90].map((d) => (
        <Link key={d} href={`${path}?days=${d}`} className={`chip ${d === days ? "chip-on" : ""}`}>
          {d === 0 ? "آخر 24 سا" : `${d} يوم`}
        </Link>
      ))}
    </div>
  );
}
