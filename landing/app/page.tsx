import Image from "next/image";
import Link from "next/link";
import {
  CheckCircle2,
  MessageCircle,
  Sparkles,
  Repeat,
  LineChart,
  ShieldCheck,
  Lock,
  UserCheck,
  Check,
  Minus,
} from "lucide-react";

const BOT_LINK = "https://t.me/adam_os_brain_bot";

function CTA({ label = "جرّبوا آدم مجاناً", variant = "gold" }: { label?: string; variant?: "gold" | "outline" }) {
  return (
    <Link href={BOT_LINK} className={variant === "gold" ? "btn-gold" : "btn-outline"}>
      <MessageCircle size={18} strokeWidth={2.3} />
      {label}
    </Link>
  );
}

function Eyebrow({ children }: { children: React.ReactNode }) {
  return (
    <span className="glass-gold inline-flex items-center gap-2 rounded-full px-4 py-1.5 text-xs font-semibold text-gold-strong">
      {children}
    </span>
  );
}

export default function LandingPage() {
  return (
    <>
      {/* ===== شريط علوي بسيط ===== */}
      <header className="relative z-20 mx-auto flex max-w-6xl items-center justify-between px-5 py-6">
        <div className="flex items-center gap-2.5">
          <Image src="/brand/tree-emblem.png" alt="" width={36} height={36} className="h-9 w-9 object-contain" />
          <span className="font-display text-xl font-extrabold text-gold-strong">آدم</span>
        </div>
        <div className="hidden sm:block">
          <CTA label="جرّبوا آدم" />
        </div>
      </header>

      {/* ===== 1. Hero ===== */}
      <section className="relative overflow-hidden px-5 pb-20 pt-6 sm:pb-28">
        <div
          className="pointer-events-none absolute inset-x-0 -top-24 -z-10 h-[560px]"
          style={{ background: "radial-gradient(60% 60% at 50% 0%, var(--bg-glow) 0%, transparent 70%)" }}
          aria-hidden="true"
        />
        <div className="mx-auto grid max-w-6xl items-center gap-12 lg:grid-cols-2">
          <div className="rise-in flex flex-col items-start gap-6 text-right">
            <Eyebrow>
              <Sparkles size={13} strokeWidth={2.4} />
              مرافق التربية الذكي
            </Eyebrow>
            <h1 className="font-display text-[2.1rem] font-extrabold leading-[1.25] sm:text-[2.6rem]">
              في اللحظة اللي تحسّون فيها إنّكم راح
              <span className="text-gold-strong"> تنفجروا</span>… آدم يعرف شنو يُقال.
            </h1>
            <p className="max-w-lg text-lg leading-relaxed text-[color:var(--text-secondary)]">
              مرافق تربية ذكي يساعدكم تتعاملوا مع أصعب لحظات التربية، خطوة بخطوة — مبنية على طفلكم أنتم بالذات، لا نصيحة عامة تصلح لأي بيت.
            </p>
            <div className="flex flex-col items-start gap-3">
              <CTA />
              <p className="text-sm text-muted">بلا بطاقة بنكية · يبدأ خلال أقل من دقيقة</p>
            </div>
          </div>
          <div className="rise-in relative mx-auto w-full max-w-sm" style={{ animationDelay: "120ms" }}>
            <div
              className="absolute inset-0 -z-10 rounded-full opacity-70 blur-3xl"
              style={{ background: "radial-gradient(circle, var(--gold-soft) 0%, transparent 70%)" }}
              aria-hidden="true"
            />
            <Image
              src="/brand/adam-character.png"
              alt="آدم"
              width={800}
              height={1000}
              className="h-auto w-full object-contain drop-shadow-[0_20px_60px_rgba(227,178,60,0.25)]"
              priority
            />
          </div>
        </div>
      </section>

      {/* ===== 2. Show, don't tell ===== */}
      <section className="px-5 pb-24">
        <div className="mx-auto max-w-2xl">
          <div className="glass rise-in flex flex-col gap-4 p-6 sm:p-8">
            <div className="flex justify-end">
              <div className="glass-gold max-w-[85%] rounded-2xl rounded-tl-md px-5 py-3.5 text-[15px] leading-relaxed">
                يوسف راه يصرخ وما حبش يرقد.
              </div>
            </div>
            <div className="flex justify-start">
              <div className="flex max-w-[85%] items-start gap-3 rounded-2xl rounded-tr-md border border-[color:var(--glass-border)] bg-[color:var(--surface)] px-5 py-3.5 text-[15px] leading-relaxed">
                <span>
                  الصراخ قبل النوم غالباً من تعب متراكم، لا عناد. الليلة: اجلسوا بجانبه دقائق بهدوء قبل ما يحاول ينام، بلا كلام كثير.
                </span>
              </div>
            </div>
            <div className="flex justify-start">
              <div className="flex items-center gap-2 rounded-full border border-[color:var(--emerald-strong)] px-4 py-2 text-sm font-semibold text-[color:var(--emerald-strong)]">
                <CheckCircle2 size={16} strokeWidth={2.3} />
                طُبّقت الخطوة
              </div>
            </div>
          </div>
          <p className="mt-5 text-center text-sm text-muted">محادثة حقيقية من آدم — بلا شرح طويل، بلا 20 صفحة نصائح.</p>
        </div>
      </section>

      {/* ===== 3. المشكلة ===== */}
      <section className="px-5 pb-24">
        <div className="mx-auto max-w-4xl text-center">
          <h2 className="font-display rise-in text-[1.7rem] font-bold sm:text-3xl">
            المشكلة مو إنّكم ما تعرفوش تربّوا.
          </h2>
          <p className="rise-in mx-auto mt-4 max-w-xl text-lg text-[color:var(--text-secondary)]" style={{ animationDelay: "80ms" }}>
            المشكلة إنّكم تحتاجوا مساعدة في اللحظة نفسها — لا بعدها بيوم، ولا في كتاب تقروه لمّا يهدأ البيت.
          </p>
          <div className="mt-10 grid gap-4 sm:grid-cols-3">
            {[
              "وقت النوم يتحوّل لمعركة.",
              "طفلكم يرفض كل شيء.",
              "أعصابكم توصل للحدّ الأخير.",
            ].map((t, i) => (
              <div key={t} className="glass rise-in p-6 text-right" style={{ animationDelay: `${i * 90}ms` }}>
                <p className="text-[15px] leading-relaxed text-[color:var(--text-secondary)]">{t}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ===== 4. الوعد الكبير ===== */}
      <section className="px-5 pb-24">
        <div className="mx-auto max-w-5xl">
          <div className="text-center">
            <h2 className="font-display rise-in text-[1.7rem] font-bold sm:text-3xl">آدم ما يعطيكم نصائح أكثر.</h2>
            <p className="rise-in mt-3 text-lg text-gold-strong" style={{ animationDelay: "80ms" }}>
              يساعدكم تهدأوا في المواقف اللي كانت تكسر أعصابكم.
            </p>
          </div>
          <div className="mt-10 grid gap-5 sm:grid-cols-3">
            {[
              { icon: Sparkles, title: "خطوة وحدة الآن", body: "بدل عشرين صفحة نصائح — شي واحد صغير تجرّبوه اليوم." },
              { icon: Repeat, title: "آدم يتذكر", body: "يتعلّم من المواقف السابقة، ويفهم طفلكم أكثر مع الوقت." },
              { icon: LineChart, title: "تشوفوا التغيير", body: "رحلتكم تتحوّل لدليل حقيقي على تطوّركم، لا مجرد أرقام." },
            ].map((b, i) => (
              <div key={b.title} className="glass rise-in flex flex-col gap-3 p-7" style={{ animationDelay: `${i * 100}ms` }}>
                <b.icon size={26} strokeWidth={2} className="text-gold-strong" />
                <h3 className="font-display text-lg font-bold">{b.title}</h3>
                <p className="text-sm leading-relaxed text-[color:var(--text-secondary)]">{b.body}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ===== 5. كيف يعمل ===== */}
      <section className="px-5 pb-24">
        <div className="mx-auto max-w-5xl">
          <h2 className="font-display rise-in text-center text-[1.7rem] font-bold sm:text-3xl">كيف يعمل؟</h2>
          <div className="relative mt-12 grid gap-8 sm:grid-cols-3">
            <div
              className="absolute inset-x-0 top-6 hidden h-px sm:block"
              style={{ background: "linear-gradient(90deg, transparent, var(--glass-border-gold), transparent)" }}
              aria-hidden="true"
            />
            {[
              { n: "01", title: "احكوا لآدم", body: "قولوا له شنو راه صاير — بكلامكم أنتم، بلا استمارة." },
              { n: "02", title: "خذوا خطوة", body: "آدم يعطيكم التدخّل المناسب لهذي اللحظة بالذات." },
              { n: "03", title: "شاهدوا التغيير", body: "مع الوقت، يبدأ يفهم طفلكم وتبدأوا تشوفوا الفرق." },
            ].map((s, i) => (
              <div key={s.n} className="rise-in relative flex flex-col items-center gap-3 text-center" style={{ animationDelay: `${i * 110}ms` }}>
                <div className="glass-gold flex h-12 w-12 items-center justify-center rounded-full font-display text-lg font-bold text-gold-strong">
                  {s.n}
                </div>
                <h3 className="font-display text-lg font-bold">{s.title}</h3>
                <p className="max-w-[22ch] text-sm leading-relaxed text-[color:var(--text-secondary)]">{s.body}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ===== 6. Personalization ===== */}
      <section className="px-5 pb-24">
        <div className="mx-auto grid max-w-5xl items-center gap-10 lg:grid-cols-2">
          <div className="rise-in flex flex-col gap-5 text-right">
            <Eyebrow>يعرف طفلكم تحديداً</Eyebrow>
            <h2 className="font-display text-[1.7rem] font-bold sm:text-3xl">
              آدم ما يعطيش نفس النصيحة لكل بيت.
            </h2>
            <ul className="flex flex-col gap-3 text-[15px] leading-relaxed text-[color:var(--text-secondary)]">
              {["عمر طفلكم", "المواقف اللي تتكرر معه", "شنو نفع سابقاً", "شنو ما نفعش", "الأنماط اللي يلاحظها آدم"].map((li) => (
                <li key={li} className="flex items-center gap-2.5">
                  <Check size={16} strokeWidth={2.6} className="shrink-0 text-gold-strong" />
                  {li}
                </li>
              ))}
            </ul>
          </div>
          <div className="glass-gold rise-in p-7" style={{ animationDelay: "100ms" }}>
            <p className="font-display text-lg leading-loose text-text">
              «أعرف إنّ يوسف غالباً يتوتّر عند الانتقال من اللعب للنوم — جرّبوا تخبروه بالخطوة الجاية قبلها بخمس دقائق.»
            </p>
            <p className="mt-4 text-sm text-muted">هذا مو مثال عام — هذا بالضبط شنو يقوله آدم لمّا يعرف طفلكم فعلاً.</p>
          </div>
        </div>
      </section>

      {/* ===== 7. الرحلة / الشجرة ===== */}
      <section className="px-5 pb-24">
        <div className="mx-auto grid max-w-5xl items-center gap-10 lg:grid-cols-2">
          <div className="rise-in relative order-2 mx-auto w-full max-w-xs lg:order-1">
            <Image
              src="/brand/tree-embroidery-macro.png"
              alt="شجرة آدم"
              width={600}
              height={600}
              className="w-full rounded-[28px] object-cover shadow-[0_20px_60px_rgba(0,0,0,0.5)]"
            />
          </div>
          <div className="order-1 flex flex-col gap-5 text-right lg:order-2">
            <h2 className="font-display rise-in text-[1.7rem] font-bold sm:text-3xl">
              كل مرّة تختاروا فيها الهدوء… تبنوا شيئاً.
            </h2>
            <p className="rise-in text-lg leading-relaxed text-[color:var(--text-secondary)]" style={{ animationDelay: "80ms" }}>
              ليست نقاطاً. ليست لعبة. هي لحظات حقيقية تغيّرت فيها طريقة تعاملكم — تتراكم شجرة واحدة، ورقة بعد ورقة.
            </p>
          </div>
        </div>
      </section>

      {/* ===== 8. لماذا آدم ===== */}
      <section className="px-5 pb-24">
        <div className="mx-auto max-w-3xl">
          <h2 className="font-display rise-in text-center text-[1.7rem] font-bold sm:text-3xl">علاش آدم، مو بحث Google؟</h2>
          <div className="glass rise-in mt-8 overflow-x-auto" style={{ animationDelay: "80ms" }}>
            <table className="w-full min-w-[420px] text-right text-sm">
              <thead>
                <tr className="border-b border-[color:var(--glass-border)] text-muted">
                  <th className="p-4 font-medium">&nbsp;</th>
                  <th className="p-4 font-display font-bold text-gold-strong">آدم</th>
                  <th className="p-4 font-medium">بحث Google</th>
                  <th className="p-4 font-medium">نصائح عامة</th>
                </tr>
              </thead>
              <tbody>
                {[
                  "يعرف طفلكم",
                  "يتذكّر السياق",
                  "يساعدكم في اللحظة",
                  "يتطوّر معكم",
                ].map((row) => (
                  <tr key={row} className="border-b border-[color:var(--glass-border)] last:border-0">
                    <td className="p-4 text-[color:var(--text-secondary)]">{row}</td>
                    <td className="p-4">
                      <Check size={18} strokeWidth={2.6} className="text-gold-strong" />
                    </td>
                    <td className="p-4">
                      <Minus size={16} className="text-muted" />
                    </td>
                    <td className="p-4">
                      <Minus size={16} className="text-muted" />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </section>

      {/* ===== 9. الخصوصية والثقة ===== */}
      <section className="px-5 pb-24">
        <div className="mx-auto max-w-4xl">
          <div className="text-center">
            <h2 className="font-display rise-in text-[1.7rem] font-bold sm:text-3xl">خصوصيتكم أولاً.</h2>
          </div>
          <div className="mt-10 grid gap-5 sm:grid-cols-3">
            {[
              { icon: Lock, title: "بياناتكم ملككم", body: "تقدروا تطلبوا محوها كاملة بأي وقت، بضغطة وحدة." },
              { icon: ShieldCheck, title: "حدود واضحة", body: "آدم يقولها بصراحة لمّا الموقف يحتاج مختصاً حقيقياً، لا يدّعي أنه بديل عنه." },
              { icon: UserCheck, title: "لا انتحال صفة", body: "آدم لا يتحدّث باسم فريقنا ولا يعرض شيئاً لم نتّفق عليه." },
            ].map((t, i) => (
              <div key={t.title} className="glass rise-in flex flex-col items-center gap-3 p-7 text-center" style={{ animationDelay: `${i * 100}ms` }}>
                <t.icon size={24} strokeWidth={2} className="text-gold-strong" />
                <h3 className="font-display text-base font-bold">{t.title}</h3>
                <p className="text-sm leading-relaxed text-[color:var(--text-secondary)]">{t.body}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ===== 10. المرافقة الكاملة (بلا سعر موحّد) ===== */}
      <section className="px-5 pb-24">
        <div className="glass-gold mx-auto max-w-3xl rise-in p-8 text-center sm:p-12">
          <Eyebrow>المرافقة الكاملة</Eyebrow>
          <h2 className="font-display mt-5 text-[1.6rem] font-bold sm:text-2xl">ابدأوا رحلة 30 يوماً مع آدم</h2>
          <ul className="mx-auto mt-6 flex max-w-sm flex-col gap-2.5 text-right text-[15px] text-[color:var(--text-secondary)]">
            {["مرافقة يومية مبنية على طفلكم", "ذاكرة وسياق يتراكمان معكم", "رحلتكم وتقدّمكم، خطوة بخطوة", "وصول كامل لآدم بلا حدود"].map((li) => (
              <li key={li} className="flex items-center gap-2.5">
                <Check size={16} strokeWidth={2.6} className="shrink-0 text-gold-strong" />
                {li}
              </li>
            ))}
          </ul>
          <p className="mx-auto mt-6 max-w-sm text-sm text-muted">
            السعر يختلف حسب بلدكم — يظهر لكم بعملتكم المحلية مباشرة داخل المحادثة مع آدم، لا نعرض رقماً واحداً هنا لأنه ببساطة مو نفسه لكل بلد.
          </p>
          <div className="mt-7">
            <CTA label="ابدأوا رحلتكم مع آدم" />
          </div>
        </div>
      </section>

      {/* ===== 11. أسئلة شائعة ===== */}
      <section className="px-5 pb-24">
        <div className="mx-auto max-w-3xl">
          <h2 className="font-display rise-in text-center text-[1.7rem] font-bold sm:text-3xl">أسئلة شائعة</h2>
          <div className="mt-8 flex flex-col gap-3">
            {[
              ["هل آدم بديل عن أخصائي؟", "لا. آدم يرافقكم يومياً في اللحظات العادية، ولو الموقف يحتاج مختصاً حقيقياً، يقولها لكم بصراحة."],
              ["كيف يعرف آدم طفلي؟", "من حكاياتكم له يوماً بيوم — بلا استمارات طويلة، وبلا أسئلة مكررة."],
              ["هل بياناتي آمنة؟", "نعم، وتقدروا تطلبوا محوها بالكامل في أي وقت."],
              ["هل أقدر أجرّبه مجاناً؟", "نعم، المحادثة الأساسية مع آدم مجانية دائماً."],
              ["كم السعر؟", "يختلف حسب بلدكم — يظهر لكم بعملتكم المحلية مباشرة داخل المحادثة."],
              ["كيف ألغي المرافقة الكاملة؟", "برسالة وحدة لآدم، بلا شروط ولا التزام."],
            ].map(([q, a]) => (
              <details key={q} className="glass group p-5">
                <summary className="flex cursor-pointer list-none items-center justify-between font-display text-[15px] font-bold">
                  {q}
                  <span className="text-gold-strong transition-transform group-open:rotate-45">+</span>
                </summary>
                <p className="mt-3 text-sm leading-relaxed text-[color:var(--text-secondary)]">{a}</p>
              </details>
            ))}
          </div>
        </div>
      </section>

      {/* ===== 12. Final CTA ===== */}
      <section className="px-5 pb-28">
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="font-display rise-in text-[1.8rem] font-bold sm:text-3xl">
            ما تحتاجوش تكونوا أهلاً مثاليين.
          </h2>
          <p className="rise-in mt-3 text-lg text-gold-strong" style={{ animationDelay: "80ms" }}>
            تحتاجوا بس تعرفوا شنو تديروا في اللحظة الجاية.
          </p>
          <div className="rise-in mt-8 flex flex-col items-center gap-3" style={{ animationDelay: "140ms" }}>
            <CTA label="ابدأوا مع آدم مجاناً" />
            <p className="text-sm text-muted">ياخذ أقل من دقيقة يبدأ.</p>
          </div>
        </div>
      </section>

      <footer className="border-t border-[color:var(--glass-border)] px-5 py-8 text-center text-sm text-muted">
        <p>© آدم — مرافق التربية الذكي</p>
      </footer>
    </>
  );
}
