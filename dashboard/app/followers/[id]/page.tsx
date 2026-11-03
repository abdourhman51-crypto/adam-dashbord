import Link from "next/link";
import { notFound } from "next/navigation";
import { contactAction } from "@/app/actions";
import { Card, Pill, Problem } from "@/components/ui";
import { getContact, PRODUCTS, STAGES, STAGE_ORDER, type TimelineItem } from "@/lib/noor";
import { pageName } from "@/lib/site";
import { ago } from "@/lib/fmt";

export const dynamic = "force-dynamic";
export const metadata = { title: "متابعة" };

const KIND: Record<TimelineItem["kind"], { label: string; cls: string }> = {
  in: { label: "هي", cls: "border-[var(--border)]" },
  nour: { label: "نور", cls: "border-[var(--primary)] bg-[var(--track)]/40" },
  cmd: { label: "أنت", cls: "border-[var(--gold)]" },
  note: { label: "ملاحظة", cls: "border-dashed border-[var(--gold)]" },
  payment: { label: "وصل دفع", cls: "border-[var(--good)]" },
  site: { label: "الموقع", cls: "border-[var(--info)]" },
};
const SITE_EVENTS: Record<string, string> = { view_buy: "رأت السعر", cta_click: "ضغطت الشراء", whop_link: "ضغطت الشراء", purchase: "اشترت", tool_start: "بدأت الأداة", tool_done: "أكملت الأداة", page_view: "فتحت الصفحة" };

const btn = "rounded-full border border-[var(--border)] px-3 py-1.5 text-sm hover:border-[var(--gold)]";
const input = "w-full rounded-xl border border-[var(--border)] bg-[var(--bg)] px-3 py-2 text-sm";

export default async function ContactPage({ params, searchParams }: { params: Promise<{ id: string }>; searchParams: Promise<Record<string, string | undefined>> }) {
  const { id } = await params;
  const { m } = await searchParams;
  if (!/^[0-9a-f-]{36}$/i.test(id)) notFound();
  const { data, error } = await getContact(id);
  if (!data) return <Problem error={error ?? "?"} />;
  const c = data.conversation!;
  const p = data.profile ?? {};
  const stage = (p.manual_stage || p.stage || "unknown") as string;
  const st = STAGES[stage] ?? STAGES.unknown;
  const pausedUntil = p.nour_paused_until && new Date(p.nour_paused_until) > new Date() ? p.nour_paused_until : null;
  const Hidden = ({ action }: { action: string }) => (<><input type="hidden" name="id" value={id} /><input type="hidden" name="action" value={action} /></>);

  return (
    <div className="space-y-4">
      <Link href="/followers" className="text-sm text-[var(--muted)]">→ كل المتابعات</Link>
      {m && <div className="card border-[var(--gold)] text-sm">{m}</div>}

      <div className="card flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-xl font-bold">{c.name || "بدون اسم"}</h1>
          <div className="mt-1 flex flex-wrap items-center gap-2 text-xs text-[var(--muted)]">
            <span>{c.channel === "instagram" ? "إنستغرام" : "مسنجر"}{c.username ? ` · @${c.username}` : ""}</span>
            <Pill tone={st.tone}>{st.label}{p.manual_stage ? " (يدوي)" : ""}</Pill>
            {p.is_customer && <Pill tone="success">مشترية</Pill>}
            {pausedUntil ? <Pill tone="warn">نور متوقفة حتى {new Date(pausedUntil).toLocaleString("ar-DZ-u-nu-latn", { dateStyle: "short", timeStyle: "short" })}</Pill> : <Pill tone="primary">نور تردّ</Pill>}
            {(p.tags ?? []).map((t) => <Pill key={t}>{t}</Pill>)}
          </div>
        </div>
        <div className="text-center">
          <div className="text-3xl font-bold tabular-nums">{data.score}</div>
          <div className="text-xs text-[var(--muted)]">نقاط الاهتمام</div>
        </div>
      </div>

      <div className="grid gap-4 lg:grid-cols-3">
        <div className="space-y-4 lg:col-span-1">
          <Card title="ما نعرفه">
            <dl className="space-y-2 text-sm">
              {p.main_problem && <div><dt className="text-xs text-[var(--muted)]">المشكلة</dt><dd>{p.main_problem}</dd></div>}
              {p.summary && <div><dt className="text-xs text-[var(--muted)]">الملخص</dt><dd>{p.summary}</dd></div>}
              {!!p.children?.length && <div><dt className="text-xs text-[var(--muted)]">الأطفال</dt><dd>{p.children.map((k) => [k.name, k.age].filter(Boolean).join(" ")).join("، ")}</dd></div>}
              {p.country && <div><dt className="text-xs text-[var(--muted)]">البلد</dt><dd>{p.country}</dd></div>}
              {!!p.topics?.length && <div><dt className="text-xs text-[var(--muted)]">المواضيع</dt><dd>{p.topics.join("، ")}</dd></div>}
              {!!p.objections?.length && <div><dt className="text-xs text-[var(--muted)]">الاعتراضات</dt><dd className="text-[var(--warn)]">{p.objections.join("، ")}</dd></div>}
              <div><dt className="text-xs text-[var(--muted)]">المنتجات</dt><dd>
                {(p.products_bought ?? []).map((x) => <div key={x} className="text-[var(--good)]">✓ {PRODUCTS[x]?.name ?? x}</div>)}
                {(p.products_offered ?? []).filter((x) => !(p.products_bought ?? []).includes(x)).map((x) => <div key={x}>عُرض: {PRODUCTS[x]?.name ?? x}</div>)}
                {!(p.products_offered ?? []).length && !(p.products_bought ?? []).length && "لم يُعرض شيء"}
              </dd></div>
              <div><dt className="text-xs text-[var(--muted)]">الموقع (من روابط نور)</dt><dd>
                {data.site.visits ? `${data.site.visits} زيارة${data.site.price ? " · رأت السعر" : ""}${data.site.checkout ? " · ضغطت الشراء" : ""}${data.site.bought ? " · اشترت" : ""}` : "لم تفتح رابطاً بعد"}
              </dd></div>
            </dl>
          </Card>

          <Card title="تحكّم">
            <div className="space-y-4">
              <div className="flex flex-wrap gap-2">
                {pausedUntil ? (
                  <form action={contactAction}><Hidden action="resume" /><button className={btn}>▶ رجّع نور</button></form>
                ) : (
                  <>
                    <form action={contactAction}><Hidden action="pause" /><input type="hidden" name="hours" value="24" /><button className={btn}>⏸ أوقف نور 24 سا</button></form>
                    <form action={contactAction}><Hidden action="pause" /><input type="hidden" name="hours" value="720" /><button className={btn}>⏸ أوقفها 30 يوم</button></form>
                  </>
                )}
              </div>

              <form action={contactAction} className="space-y-2">
                <Hidden action="send_dm" />
                <label className="text-xs text-[var(--muted)]">رسالة منك (تُرسل خلال دقيقة، ونور تصمت 30 دقيقة)</label>
                <textarea name="text" required maxLength={990} rows={3} className={input} placeholder="اكتب رسالتك…" />
                <button className={btn}>إرسال</button>
              </form>

              <form action={contactAction} className="flex gap-2">
                <Hidden action="stage" />
                <select name="stage" defaultValue={p.manual_stage ?? ""} className={input}>
                  <option value="">المرحلة: تلقائية (من نور)</option>
                  {STAGE_ORDER.filter((s) => s !== "unknown").map((s) => <option key={s} value={s}>{STAGES[s].label}</option>)}
                </select>
                <button className={btn}>حفظ</button>
              </form>

              <form action={contactAction} className="flex gap-2">
                <Hidden action="tags" />
                <input name="tags" defaultValue={(p.tags ?? []).join("، ")} placeholder="وسوم: مهتمة، تعود لاحقاً…" className={input} />
                <button className={btn}>حفظ</button>
              </form>

              <form action={contactAction} className="space-y-2">
                <Hidden action="note" />
                <textarea name="body" required maxLength={2000} rows={2} className={input} placeholder="ملاحظة داخلية (لا تصلها)…" />
                <button className={btn}>أضف ملاحظة</button>
              </form>
            </div>
          </Card>
        </div>

        <Card title="كل ما حدث" hint="الأحدث أولاً" className="lg:col-span-2">
          {data.timeline.length === 0 ? <p className="text-sm text-[var(--muted)]">لا شيء بعد.</p> : (
            <ol className="space-y-2">
              {data.timeline.map((t, i) => {
                const k = KIND[t.kind] ?? KIND.in;
                let text = t.text ?? "";
                let extra = t.extra ?? "";
                if (t.kind === "site") { text = pageName(text || "/"); extra = extra.split(",").map((e) => SITE_EVENTS[e]).filter(Boolean).filter((v, j, a) => a.indexOf(v) === j).join(" · "); }
                if (t.kind === "payment") extra = extra.startsWith("approved") ? "موافق ✓" : extra.startsWith("pending") ? "ينتظر موافقتك" : extra.startsWith("rejected") ? "مرفوض" : extra;
                if (t.kind === "cmd") extra = extra === "done" ? "أُرسلت" : extra === "failed" ? "فشل الإرسال" : "في الطريق";
                if (t.kind === "in" && extra && extra !== "text") text = text || `[${extra}]`;
                return (
                  <li key={i} className={`rounded-xl border px-3 py-2 ${k.cls}`}>
                    <div className="flex justify-between gap-2 text-xs text-[var(--muted)]">
                      <span className="font-medium">{k.label}{extra && t.kind !== "in" ? ` · ${extra}` : ""}</span>
                      <span>{ago(t.at)}</span>
                    </div>
                    <div className="mt-1 whitespace-pre-wrap break-words text-sm">{text}</div>
                  </li>
                );
              })}
            </ol>
          )}
        </Card>
      </div>
    </div>
  );
}
