import Link from "next/link";
import { Card, Pill, Problem } from "@/components/ui";
import { getNoor, PRODUCTS, STAGES, STAGE_ORDER } from "@/lib/noor";
import { ago } from "@/lib/fmt";

export const revalidate = 60;
export const metadata = { title: "المتابعات" };

type SP = Promise<Record<string, string | string[] | undefined>>;
const one = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v) ?? "";

export default async function Followers({ searchParams }: { searchParams: SP }) {
  const sp = await searchParams;
  const stage = one(sp.stage);
  const q = one(sp.q).trim().toLowerCase();
  const only = one(sp.only);
  const sort = one(sp.sort);
  const { data, error } = await getNoor(30);
  if (!data) return <Problem error={error ?? "?"} />;

  let list = data.followers;
  if (stage) list = list.filter((f) => (f.stage ?? "unknown") === stage);
  if (only === "offered") list = list.filter((f) => (f.offered ?? []).length && !f.customer);
  if (only === "customers") list = list.filter((f) => f.customer);
  if (only === "hot") list = list.filter((f) => !f.customer && (f.score ?? 0) >= 30);
  if (only === "paused") list = list.filter((f) => f.paused);
  if (sort === "score") list = [...list].sort((a, b) => (b.score ?? 0) - (a.score ?? 0));
  if (q) list = list.filter((f) => [f.name, f.username, f.problem, f.summary, f.country, ...(f.topics ?? [])].join(" ").toLowerCase().includes(q));

  const link = (p: Record<string, string>) => {
    const u = new URLSearchParams({ ...(stage && { stage }), ...(q && { q }), ...(only && { only }), ...(sort && { sort }), ...p });
    for (const [k, v] of [...u]) if (!v) u.delete(k);
    return `/followers${u.size ? "?" + u : ""}`;
  };

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-xl font-bold">المتابعات <span className="text-sm font-normal text-[var(--muted)]">{list.length} من {data.followers.length}</span></h1>
        <form className="flex gap-2" action="/followers">
          {stage && <input type="hidden" name="stage" value={stage} />}
          {only && <input type="hidden" name="only" value={only} />}
          <input name="q" defaultValue={q} placeholder="ابحث: اسم، مشكلة، بلد…" className="w-56 rounded-full border border-[var(--border)] bg-[var(--surface)] px-3 py-1.5 text-sm" />
        </form>
      </div>

      <div className="flex flex-wrap gap-1 text-xs">
        <Link href={link({ stage: "", only: "" })} className={`chip ${!stage && !only ? "chip-on" : ""}`}>الكل</Link>
        <Link href={link({ only: "hot", stage: "" })} className={`chip ${only === "hot" ? "chip-on" : ""}`}>🔥 مهتمات الآن</Link>
        <Link href={link({ only: "paused", stage: "" })} className={`chip ${only === "paused" ? "chip-on" : ""}`}>نور متوقفة</Link>
        <Link href={link({ sort: sort === "score" ? "" : "score" })} className={`chip ${sort === "score" ? "chip-on" : ""}`}>رتّب بالنقاط</Link>
        <Link href={link({ only: "offered", stage: "" })} className={`chip ${only === "offered" ? "chip-on" : ""}`}>عُرض عليها ولم تشترِ</Link>
        <Link href={link({ only: "customers", stage: "" })} className={`chip ${only === "customers" ? "chip-on" : ""}`}>المشتريات</Link>
        {STAGE_ORDER.filter((s) => data.stages[s]).map((s) => (
          <Link key={s} href={link({ stage: s, only: "" })} className={`chip ${stage === s ? "chip-on" : ""}`}>
            {STAGES[s].label} {data.stages[s]}
          </Link>
        ))}
      </div>

      <Card>
        {list.length === 0 ? (
          <p className="text-sm text-[var(--muted)]">لا متابعات بهذا الفلتر.</p>
        ) : (
          <div className="overflow-x-auto">
            <table>
              <thead>
                <tr><th>المتابعة</th><th>نقاط</th><th>المرحلة</th><th>المشكلة والملخص</th><th>المنتجات</th><th>آخر نشاط</th></tr>
              </thead>
              <tbody>
                {list.map((f) => {
                  const st = STAGES[f.stage ?? "unknown"] ?? STAGES.unknown;
                  return (
                    <tr key={f.id}>
                      <td className="min-w-36">
                        <Link href={`/followers/${f.id}`} className="font-medium underline-offset-4 hover:underline">{f.name || "بدون اسم"}</Link>
                        {f.paused && <span className="ms-1 text-xs text-[var(--warn)]">⏸</span>}
                        <div className="text-xs text-[var(--muted)]">
                          {f.channel === "instagram" ? "إنستغرام" : "مسنجر"}{f.country ? ` · ${f.country}` : ""}
                          {f.children?.length ? ` · ${f.children.map((c) => [c.name, c.age].filter(Boolean).join(" ")).join("، ")}` : ""}
                        </div>
                      </td>
                      <td className={`tabular-nums font-bold ${(f.score ?? 0) >= 50 ? "text-[var(--gold)]" : (f.score ?? 0) >= 30 ? "" : "text-[var(--muted)]"}`}>{f.score ?? "—"}</td>
                      <td><Pill tone={st.tone}>{st.label}</Pill>{f.signals > 0 && <div className="mt-1 text-xs text-[var(--gold)]">نية شراء ×{f.signals}</div>}</td>
                      <td className="min-w-64 max-w-md">
                        {f.problem && <div className="font-medium">{f.problem}</div>}
                        {f.summary && <div className="text-xs text-[var(--muted)]">{f.summary}</div>}
                        {(f.objections ?? []).length > 0 && <div className="mt-1 text-xs text-[var(--warn)]">اعتراض: {(f.objections ?? []).join("، ")}</div>}
                        {(f.tags ?? []).length > 0 && <div className="mt-1 flex flex-wrap gap-1">{(f.tags ?? []).map((t) => <Pill key={t}>{t}</Pill>)}</div>}
                      </td>
                      <td className="min-w-28 text-xs">
                        {(f.bought ?? []).map((p) => <div key={p} className="text-[var(--good)]">✓ {PRODUCTS[p]?.name ?? p}</div>)}
                        {(f.offered ?? []).filter((p) => !(f.bought ?? []).includes(p)).map((p) => <div key={p} className="text-[var(--muted)]">عُرض: {PRODUCTS[p]?.name ?? p}</div>)}
                      </td>
                      <td className="whitespace-nowrap text-xs text-[var(--muted)]">{ago(f.last_seen)}<div>{f.replies} رد</div></td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </Card>
    </div>
  );
}
