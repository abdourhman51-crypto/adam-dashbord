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

const IMG = "https://d8j0ntlcm91z4.cloudfront.net/user_3CPnImgjiKIeQIfolIn0s2fo89h/";
const HERO_IMG = IMG + "hf_20260826_195441_ef4d18ad-2bb1-4901-9602-900c25be3472.png";
const CHAT_IMG = IMG + "hf_20260826_195441_a01c8864-60c4-4802-8f3c-e1529967386b.png";
const PROBLEM_IMG = IMG + "hf_20260826_195441_eab1d960-c1e7-45bd-aacd-866f17b038c5.png";
const PROMISE_IMG = IMG + "hf_20260826_195441_8866ab2a-97a7-415f-a895-1c224a4a723c.png";
const HOW_IMG = IMG + "hf_20260826_195441_dd4eba69-0e9d-469f-97a0-3c3bb303ad3e.png";
const PERSONAL_IMG = IMG + "hf_20260826_195441_4ce5ebbc-bacd-4363-9e89-3e9a5635a7d6.png";
const TREE_IMG = IMG + "hf_20260826_195441_2f102c35-7bd2-437a-b194-ddc5a5e8892f.png";
const COMPARE_IMG = IMG + "hf_20260826_195441_46176e5e-4aad-43e5-8bc9-4ea7f5c14497.png";
const TRUST_IMG = IMG + "hf_20260826_195441_db2f866a-cc88-49a3-8c08-c6c704584188.png";
const FINAL_IMG = IMG + "hf_20260826_195441_a0c5dba9-274e-480c-b680-3c0b3a3df1cf.png";
const FAQ_IMG = IMG + "hf_20260826_195848_2aca5801-233d-48cb-bed2-cd9723498d88.png";
const PRICING_IMG = "https://d8j0ntlcm91z4.cloudfront.net/user_3CPnImgjiKIeQIfolIn0s2fo89h/hf_20260826_172134_40a4e29b-9362-48c7-89ad-5cd38e32e0d8.png";

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

/**
 * كل صورة خلفية في الصفحة تذوب في نفس اللون الداكن أعلاها وأسفلها (طبقة
 * التلاشي المشتركة)، بحيث تلتقي حافة صورة مع حافة التالية في نفس التدرّج
 * بدل قطع حاد بينهما — هذا ما يجعل الصفحة تبدو صورة واحدة متصلة لا سلسلة
 * صور منفصلة بخطوط فاصلة.
 */
function SectionImage({
  src,
  alt,
  align = "center",
  focus = "bottom",
  minH = "640px",
  children,
}: {
  src: string;
  alt: string;
  align?: "top" | "center" | "bottom";
  focus?: "top" | "bottom" | "center" | "full";
  minH?: string;
  children: React.ReactNode;
}) {
  const focusBg =
    focus === "top"
      ? "linear-gradient(180deg, rgba(8,14,10,0.5) 0%, transparent 55%)"
      : focus === "bottom"
      ? "linear-gradient(0deg, rgba(8,14,10,0.5) 0%, transparent 55%)"
      : focus === "center"
      ? "radial-gradient(60% 60% at 50% 50%, rgba(8,14,10,0.12) 0%, rgba(8,14,10,0.52) 100%)"
      : "rgba(8,14,10,0.4)";
  const alignClass = align === "top" ? "justify-start pt-20" : align === "bottom" ? "justify-end pb-20" : "justify-center";

  return (
    <section className="relative w-full overflow-hidden" style={{ minHeight: minH }}>
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img src={src} alt={alt} className="absolute inset-0 h-full w-full object-cover" />
      <div
        className="absolute inset-0"
        style={{ background: "linear-gradient(180deg, rgba(8,14,10,0.95) 0%, transparent 14%, transparent 86%, rgba(8,14,10,0.95) 100%)" }}
        aria-hidden="true"
      />
      <div className="absolute inset-0" style={{ background: focusBg }} aria-hidden="true" />
      <div className={`relative z-10 mx-auto flex h-full max-w-2xl flex-col ${alignClass} gap-5 px-6 py-16 text-center`}>
        {children}
      </div>
    </section>
  );
}

export default function LandingPage() {
  return (
    <>
      {/* ===== شريط علوي بسيط ===== */}
      <header className="glass fixed inset-x-0 top-0 z-30 flex items-center justify-between px-5 py-4">
        <div className="flex items-center gap-2.5">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src="/brand/tree-emblem.webp" alt="" className="h-8 w-8 object-contain" />
          <span className="font-display text-lg font-extrabold text-gold-strong">آدم</span>
        </div>
        <div className="hidden sm:block">
          <CTA label="جرّبوا آدم" />
        </div>
      </header>

      {/* ===== 1. Hero — الصورة كاملة، النصوص فوقها ===== */}
      <SectionImage src={HERO_IMG} alt="آدم في لحظة هادئة داخل غرفته" align="top" focus="top" minH="100dvh">
        <Eyebrow>
          <Sparkles size={13} strokeWidth={2.4} />
          مرافق التربية الذكي
        </Eyebrow>
        <h1 className="font-display text-on-image text-[2.1rem] font-extrabold leading-[1.25] sm:text-[2.6rem]">
          في اللحظة التي تشعرون فيها أنكم على وشك
          <span className="text-gold-strong"> الانفجار</span>… يعرف آدم ماذا يُقال.
        </h1>
        <p className="text-on-image mx-auto max-w-lg text-lg leading-relaxed text-[color:var(--text-secondary)]">
          مرافق تربية ذكي يساعدكم على التعامل مع أصعب لحظات التربية، خطوة بخطوة، انطلاقًا من معرفته الدقيقة بطفلكم.
        </p>
        <div className="flex flex-col items-center gap-3">
          <CTA />
          <p className="text-on-image text-sm text-muted">دون بطاقة بنكية، ويبدأ في أقل من دقيقة</p>
        </div>
      </SectionImage>

      {/* ===== 2. Show, don't tell ===== */}
      <SectionImage src={CHAT_IMG} alt="محادثة دافئة مع آدم في الليل" align="center" focus="center">
        <div className="glass rise-in mx-auto flex w-full max-w-md flex-col gap-4 p-6 text-right sm:p-8">
          <div className="flex justify-end">
            <div className="glass-gold max-w-[85%] rounded-2xl rounded-tl-md px-5 py-3.5 text-[15px] leading-relaxed">
              يوسف يبكي بشدة، ولا يريد أن ينام.
            </div>
          </div>
          <div className="flex justify-start">
            <div className="flex max-w-[85%] items-start gap-3 rounded-2xl rounded-tr-md border border-[color:var(--glass-border)] bg-[color:var(--surface)] px-5 py-3.5 text-[15px] leading-relaxed">
              <span>
                البكاء قبل النوم غالبًا نتيجة تعب متراكم، وليس عنادًا. الليلة، اجلسوا بجانبه دقائق بهدوء قبل محاولته النوم، دون كلام كثير.
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
        <p className="text-on-image text-center text-sm text-muted">محادثة حقيقية من آدم، دون شرح طويل ودون عشرين صفحة من النصائح.</p>
        <CTA label="جرّبوا محادثة مثلها" />
      </SectionImage>

      {/* ===== 3. المشكلة ===== */}
      <SectionImage src={PROBLEM_IMG} alt="غرفة طفل هادئة ليلاً" align="top" focus="top">
        <h2 className="font-display text-on-image text-[1.7rem] font-bold sm:text-3xl">
          المشكلة ليست أنكم لا تعرفون كيف تربّون.
        </h2>
        <p className="text-on-image mx-auto max-w-xl text-lg text-[color:var(--text-secondary)]">
          المشكلة أنكم تحتاجون إلى مساعدة في اللحظة نفسها، لا بعد يوم، ولا في كتاب تقرؤونه حين يهدأ البيت.
        </p>
        <div className="text-on-image mx-auto mt-1 flex max-w-sm flex-col gap-3 text-[15px] text-[color:var(--text-secondary)]">
          {["وقت النوم يتحوّل إلى معركة.", "طفلكم يرفض كل شيء.", "أعصابكم تصل إلى حدّها الأخير."].map((t) => (
            <p key={t} className="flex items-center justify-center gap-2.5">
              <span className="h-1.5 w-1.5 shrink-0 rounded-full bg-[color:var(--gold-strong)]" aria-hidden="true" />
              {t}
            </p>
          ))}
        </div>
        <CTA label="لا نريد هذا بعد اليوم" />
      </SectionImage>

      {/* ===== 4. الوعد الكبير ===== */}
      <SectionImage src={PROMISE_IMG} alt="ضوء الصباح الدافئ في المنزل" align="bottom" focus="bottom" minH="800px">
        <h2 className="font-display text-on-image text-[1.7rem] font-bold sm:text-3xl">آدم لا يمنحكم نصائح أكثر.</h2>
        <p className="text-on-image text-lg text-gold-strong">بل يساعدكم على الهدوء في المواقف التي كانت تُنهك أعصابكم.</p>
        <div className="panel-group panel-group-row glass mt-1 grid sm:grid-cols-3">
          {[
            { icon: Sparkles, title: "خطوة واحدة الآن", body: "بدلًا من عشرين صفحة من النصائح، أمر واحد صغير تجرّبونه اليوم." },
            { icon: Repeat, title: "آدم يتذكر", body: "يتعلّم من المواقف السابقة، ويفهم طفلكم أكثر مع الوقت." },
            { icon: LineChart, title: "تشاهدون التغيير", body: "تتحوّل رحلتكم إلى دليل حقيقي على تطوّركم، لا مجرد أرقام." },
          ].map((b) => (
            <div key={b.title} className="flex flex-col items-center gap-2 p-6 text-center">
              <b.icon size={22} strokeWidth={2} className="text-gold-strong" />
              <h3 className="font-display text-base font-bold">{b.title}</h3>
              <p className="text-xs leading-relaxed text-[color:var(--text-secondary)]">{b.body}</p>
            </div>
          ))}
        </div>
        <CTA label="جرّبوا هذا معكم" />
      </SectionImage>

      {/* ===== 5. كيف يعمل + لحظة مع آدم (فيديو، بنفس تدفّق الصور) ===== */}
      <SectionImage src={HOW_IMG} alt="طريق مضيء نحو الهدوء" align="center" focus="full" minH="760px">
        <h2 className="font-display text-on-image text-center text-[1.7rem] font-bold sm:text-3xl">كيف يعمل؟</h2>
        <div className="mt-1 grid gap-8 sm:grid-cols-3">
          {[
            { n: "01", title: "احكوا لآدم", body: "أخبروه بما يحدث بكلامكم الخاص، دون استمارة." },
            { n: "02", title: "خذوا خطوة", body: "يمنحكم آدم التدخّل المناسب لهذه اللحظة تحديدًا." },
            { n: "03", title: "شاهدوا التغيير", body: "مع الوقت، يبدأ في فهم طفلكم، وتبدأون في ملاحظة الفرق." },
          ].map((s) => (
            <div key={s.n} className="flex flex-col items-center gap-2 text-center">
              <div className="glass-gold flex h-12 w-12 items-center justify-center rounded-full font-display text-lg font-bold text-gold-strong">
                {s.n}
              </div>
              <h3 className="font-display text-on-image text-base font-bold">{s.title}</h3>
              <p className="text-on-image max-w-[22ch] text-xs leading-relaxed text-[color:var(--text-secondary)]">{s.body}</p>
            </div>
          ))}
        </div>
        <CTA label="ابدأوا الخطوة الأولى" />
      </SectionImage>

      <section className="relative w-full overflow-hidden" style={{ minHeight: "760px" }}>
        <video
          src="/brand/adam-moment.mp4"
          autoPlay
          muted
          loop
          playsInline
          preload="none"
          aria-hidden="true"
          className="absolute inset-0 h-full w-full object-cover"
        />
        <div
          className="absolute inset-0"
          style={{ background: "linear-gradient(180deg, rgba(8,14,10,0.95) 0%, transparent 16%, transparent 55%, rgba(8,14,10,0.9) 100%)" }}
          aria-hidden="true"
        />
        <div className="relative z-10 mx-auto flex h-full max-w-2xl flex-col items-center justify-end gap-3 px-6 pb-20 text-center">
          <p className="font-display text-on-image text-[1.35rem] font-bold text-text">هذا آدم — بصوته، بشخصيته.</p>
          <p className="text-on-image max-w-[26ch] text-sm leading-relaxed text-[color:var(--text-secondary)]">
            ليس أيقونة، وليس روبوتاً باردًا؛ رفيق حقيقي يعرف طفلكم.
          </p>
          <CTA label="اسمعوا آدم بنفسكم" />
        </div>
      </section>

      {/* ===== 6. Personalization ===== */}
      <SectionImage src={PERSONAL_IMG} alt="آدم يستمع بانتباه" align="bottom" focus="bottom" minH="800px">
        <Eyebrow>يعرف طفلكم تحديداً</Eyebrow>
        <h2 className="font-display text-on-image text-[1.7rem] font-bold sm:text-3xl">لا يمنح آدم النصيحة نفسها لكل بيت.</h2>
        <ul className="text-on-image mx-auto flex max-w-xs flex-col gap-2 text-[15px] text-[color:var(--text-secondary)]">
          {["عمر طفلكم", "المواقف التي تتكرر معه", "ما الذي نفع سابقًا", "وما الذي لم ينفع", "الأنماط التي يلاحظها آدم"].map((li) => (
            <li key={li} className="flex items-center justify-center gap-2.5">
              <Check size={16} strokeWidth={2.6} className="shrink-0 text-gold-strong" />
              {li}
            </li>
          ))}
        </ul>
        <div className="glass-gold mx-auto max-w-md p-6">
          <p className="font-display text-base leading-loose text-text">
            «ألاحظ أنّ يوسف يتوتّر غالبًا عند الانتقال من اللعب إلى النوم؛ جرّبوا إخباره بالخطوة القادمة قبلها بخمس دقائق.»
          </p>
          <p className="mt-3 text-sm text-muted">هذا بالضبط ما يقوله آدم حين يعرف طفلكم فعلًا.</p>
        </div>
        <CTA label="خصّصوا آدم لطفلكم" />
      </SectionImage>

      {/* ===== 7. الرحلة / الشجرة ===== */}
      <SectionImage src={TREE_IMG} alt="شجرة آدم الذهبية" align="bottom" focus="bottom" minH="760px">
        <h2 className="font-display text-on-image text-[1.7rem] font-bold sm:text-3xl">في كل مرة تختارون فيها الهدوء… تبنون شيئًا.</h2>
        <p className="text-on-image mx-auto max-w-lg text-lg leading-relaxed text-[color:var(--text-secondary)]">
          ليست نقاطًا، وليست لعبة؛ إنها لحظات حقيقية تغيّرت فيها طريقة تعاملكم، تتراكم في شجرة واحدة، ورقة بعد ورقة.
        </p>
        <CTA label="ابدأوا شجرتكم" />
      </SectionImage>

      {/* ===== 8. لماذا آدم ===== */}
      <SectionImage src={COMPARE_IMG} alt="خلفية هادئة" align="center" focus="full" minH="720px">
        <h2 className="font-display text-on-image text-center text-[1.7rem] font-bold sm:text-3xl">لماذا آدم، لا بحث Google؟</h2>
        <div className="glass overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full min-w-[380px] text-right text-sm">
              <thead>
                <tr className="border-b border-[color:var(--glass-border)] text-muted">
                  <th className="p-4 font-medium">&nbsp;</th>
                  <th className="p-4 font-display font-bold text-gold-strong">آدم</th>
                  <th className="p-4 font-medium">بحث Google</th>
                  <th className="p-4 font-medium">نصائح عامة</th>
                </tr>
              </thead>
              <tbody>
                {["يعرف طفلكم", "يتذكّر السياق", "يساعدكم في اللحظة", "يتطوّر معكم"].map((row) => (
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
        <CTA label="جرّبوا الفرق بنفسكم" />
      </SectionImage>

      {/* ===== 9. الخصوصية والثقة ===== */}
      <SectionImage src={TRUST_IMG} alt="خزانة ذهبية رمز للثقة" align="center" focus="center" minH="720px">
        <h2 className="font-display text-on-image text-[1.7rem] font-bold sm:text-3xl">خصوصيتكم أولاً.</h2>
        <div className="panel-group panel-group-row glass grid sm:grid-cols-3">
          {[
            { icon: Lock, title: "بياناتكم ملككم", body: "يمكنكم طلب محوها كاملة في أي وقت، بضغطة واحدة." },
            { icon: ShieldCheck, title: "حدود واضحة", body: "يقولها آدم بصراحة حين يحتاج الموقف إلى مختص حقيقي." },
            { icon: UserCheck, title: "لا انتحال صفة", body: "آدم لا يتحدّث باسم فريقنا ولا يعرض شيئاً لم نتّفق عليه." },
          ].map((t) => (
            <div key={t.title} className="flex flex-col items-center gap-2 p-6 text-center">
              <t.icon size={22} strokeWidth={2} className="text-gold-strong" />
              <h3 className="font-display text-sm font-bold">{t.title}</h3>
              <p className="text-xs leading-relaxed text-[color:var(--text-secondary)]">{t.body}</p>
            </div>
          ))}
        </div>
        <CTA label="ابدأوا بثقة" />
      </SectionImage>

      {/* ===== 10. المرافقة الكاملة (بلا سعر موحّد، نتيجة أولاً) ===== */}
      <SectionImage src={PRICING_IMG} alt="خلفية ذهبية فاخرة" align="center" focus="full" minH="820px">
        <Eyebrow>المرافقة الكاملة</Eyebrow>
        <h2 className="font-display text-on-image text-[1.6rem] font-bold sm:text-2xl">29 يومًا حتى تشاهدوا فرقًا حقيقيًا</h2>
        <ul className="text-on-image mx-auto flex max-w-sm flex-col gap-2.5 text-[15px] text-[color:var(--text-secondary)]">
          {[
            "هدف واحد واضح، تشاهدون تحقّقه بأعينكم",
            "خطوة يومية مبنية على طفلكم تحديدًا",
            "ذاكرة تتراكم معكم، فلا تكرّرون الحديث من جديد",
            "وصول كامل إلى آدم دون حدود",
          ].map((li) => (
            <li key={li} className="flex items-center justify-center gap-2.5">
              <Check size={16} strokeWidth={2.6} className="shrink-0 text-gold-strong" />
              {li}
            </li>
          ))}
        </ul>
        <p className="text-on-image mx-auto max-w-sm text-sm text-muted">
          يختلف السعر حسب بلدكم، ويظهر لكم بعملتكم المحلية مباشرة داخل المحادثة مع آدم.
        </p>
        <div className="glass-gold mx-auto flex max-w-sm items-start gap-2.5 p-4 text-right text-sm leading-relaxed text-[color:var(--text-secondary)]">
          <ShieldCheck size={18} strokeWidth={2} className="mt-0.5 shrink-0 text-gold-strong" />
          <span>
            <span className="font-semibold text-gold-strong">ضماننا: </span>
            إن لم تشعروا بأثر واضح، نمدّد لكم نصف مدة الرحلة مجانًا.
          </span>
        </div>
        <CTA label="ابدأوا رحلتكم مع آدم" />
      </SectionImage>

      {/* ===== 11. أسئلة شائعة ===== */}
      <SectionImage src={FAQ_IMG} alt="خلفية هادئة" align="center" focus="full" minH="820px">
        <h2 className="font-display text-on-image text-center text-[1.7rem] font-bold sm:text-3xl">أسئلة شائعة</h2>
        <div className="glass panel-group flex flex-col text-right">
          {[
            ["هل آدم بديل عن أخصائي؟", "لا. يرافقكم آدم يوميًا في اللحظات العادية، وإن احتاج الموقف إلى مختص حقيقي، يخبركم بذلك بصراحة."],
            ["كيف يعرف آدم طفلي؟", "من خلال حديثكم معه يومًا بعد يوم، دون استمارات طويلة أو أسئلة مكررة."],
            ["ماذا لو لم أشعر بأثر واضح؟", "نمدّد لكم نصف مدة الرحلة مجانًا، حتى تشعروا بالفرق فعلًا."],
            ["هل بياناتي آمنة؟", "نعم، ويمكنكم طلب محوها بالكامل في أي وقت."],
            ["هل يمكنني تجربته مجانًا؟", "نعم، المحادثة الأساسية مع آدم مجانية دائمًا."],
            ["كم السعر؟", "يختلف حسب بلدكم، ويظهر لكم بعملتكم المحلية مباشرة داخل المحادثة."],
            ["كيف ألغي المرافقة الكاملة؟", "برسالة واحدة إلى آدم، دون شروط أو التزام."],
          ].map(([q, a]) => (
            <details key={q} className="group p-5">
              <summary className="flex cursor-pointer list-none items-center justify-between font-display text-[15px] font-bold">
                {q}
                <span className="text-gold-strong transition-transform group-open:rotate-45">+</span>
              </summary>
              <p className="mt-3 text-sm leading-relaxed text-[color:var(--text-secondary)]">{a}</p>
            </details>
          ))}
        </div>
        <CTA label="لا تزال لديكم أسئلة؟ جرّبوه مباشرة" />
      </SectionImage>

      {/* ===== 12. Final CTA ===== */}
      <SectionImage src={FINAL_IMG} alt="باب مفتوح على ضوء دافئ" align="center" focus="full" minH="640px">
        <h2 className="font-display text-on-image text-[1.8rem] font-bold sm:text-3xl">لستم بحاجة إلى أن تكونوا آباءً مثاليين.</h2>
        <p className="text-on-image text-lg text-gold-strong">تحتاجون فقط إلى معرفة ما تفعلونه في اللحظة القادمة.</p>
        <div className="flex flex-col items-center gap-3">
          <CTA label="ابدأوا مع آدم مجاناً" />
          <p className="text-on-image text-sm text-muted">يبدأ في أقل من دقيقة.</p>
        </div>
      </SectionImage>

      <footer className="border-t border-[color:var(--glass-border)] px-5 py-8 text-center text-sm text-muted">
        <p>© آدم — مرافق التربية الذكي</p>
      </footer>
    </>
  );
}
