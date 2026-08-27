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
const HERO_IMG = IMG + "hf_20260827_095242_03a87048-5ee8-4ad1-a874-6bd849459c6e.png";
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

/** كتلة نص تجلس فوق صورة — إطار زجاجي بعمق خفيف يبقي النص واضحًا فوق أي صورة تحته */
function TextPanel({ children, className = "" }: { children: React.ReactNode; className?: string }) {
  return <div className={`glass mx-auto flex w-full flex-col items-center gap-3 p-6 text-center sm:p-7 ${className}`}>{children}</div>;
}

/**
 * كل صورة أو فيديو خلفية يحصل على طبقة مموّهة (blur) في نفس منطقة التغميق
 * (focus) — لا حواف حادة بين صورة وأخرى، بل تلاشٍ ضبابي أنيق يجعل الصفحة
 * كلها تبدو متصلة. النص يتموضع فوق هذه المنطقة المموّهة بالذات (عبر
 * textAlign)، والزر (cta) دائمًا في أسفل القسم منفصلاً عن النص.
 * object-top يمنع اقتصاص أعلى الصورة (كالرأس) عند التحجيم بـobject-cover.
 */
function maskForFocus(focus: "top" | "bottom" | "center" | "full") {
  if (focus === "top") return "linear-gradient(180deg, black 0%, black 42%, transparent 62%)";
  if (focus === "bottom") return "linear-gradient(0deg, black 0%, black 42%, transparent 62%)";
  if (focus === "center") return "radial-gradient(55% 55% at 50% 50%, transparent 0%, black 100%)";
  return "black";
}

function SectionImage({
  src,
  alt,
  isVideo = false,
  textAlign = "center",
  focus = "bottom",
  minH = "640px",
  content,
  cta,
}: {
  src: string;
  alt: string;
  isVideo?: boolean;
  textAlign?: "top" | "center" | "bottom";
  focus?: "top" | "bottom" | "center" | "full";
  minH?: string;
  content: React.ReactNode;
  cta?: React.ReactNode;
}) {
  const focusBg =
    focus === "top"
      ? "linear-gradient(180deg, rgba(8,14,10,0.55) 0%, transparent 55%)"
      : focus === "bottom"
      ? "linear-gradient(0deg, rgba(8,14,10,0.55) 0%, transparent 55%)"
      : focus === "center"
      ? "radial-gradient(60% 60% at 50% 50%, rgba(8,14,10,0.1) 0%, rgba(8,14,10,0.5) 100%)"
      : "rgba(8,14,10,0.4)";
  const mask = maskForFocus(focus);
  const contentAlignClass = textAlign === "top" ? "justify-start pt-20" : textAlign === "bottom" ? "justify-end" : "justify-center";

  const mediaProps = { className: "absolute inset-0 h-full w-full object-cover object-top" };

  return (
    <section className="relative w-full overflow-hidden" style={{ minHeight: minH }}>
      {isVideo ? (
        <video src={src} autoPlay muted loop playsInline preload="none" aria-hidden="true" {...mediaProps} />
      ) : (
        /* eslint-disable-next-line @next/next/no-img-element */
        <img src={src} alt={alt} {...mediaProps} />
      )}
      {isVideo ? (
        <video
          src={src}
          autoPlay
          muted
          loop
          playsInline
          preload="none"
          aria-hidden="true"
          {...mediaProps}
          style={{ filter: "blur(28px)", WebkitMaskImage: mask, maskImage: mask }}
        />
      ) : (
        /* eslint-disable-next-line @next/next/no-img-element */
        <img src={src} alt="" aria-hidden="true" {...mediaProps} style={{ filter: "blur(28px)", WebkitMaskImage: mask, maskImage: mask }} />
      )}
      <div
        className="absolute inset-0"
        style={{ background: "linear-gradient(180deg, rgba(8,14,10,0.97) 0%, transparent 24%, transparent 76%, rgba(8,14,10,0.97) 100%)" }}
        aria-hidden="true"
      />
      <div className="absolute inset-0" style={{ background: focusBg }} aria-hidden="true" />
      <div className="relative z-10 mx-auto flex h-full max-w-2xl flex-col px-6 py-14 text-center">
        <div className={`flex flex-1 flex-col ${contentAlignClass} gap-5`}>{content}</div>
        {cta && <div className="flex flex-col items-center gap-2 pb-2 pt-6">{cta}</div>}
      </div>
    </section>
  );
}

export default function LandingPage() {
  return (
    <>
      {/* ===== شريط علوي — على كامل عرض الشاشة، بلا حواف مبتورة ===== */}
      <header className="site-header fixed inset-x-0 top-0 z-30 flex items-center justify-between px-5 py-3.5">
        <div className="flex items-center gap-2.5">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src="/brand/tree-emblem.webp" alt="" className="h-8 w-8 shrink-0 object-contain" />
          <span className="font-display text-lg font-extrabold leading-none text-gold-strong">آدم</span>
        </div>
        <Link href={BOT_LINK} className="btn-gold !px-4 !py-2 !text-sm">
          <MessageCircle size={16} strokeWidth={2.3} />
          جرّبوا آدم
        </Link>
      </header>

      {/* ===== 1. Hero — الفيديو تحت الشريط العلوي مباشرة (لا يغطيه)؛ تلاشٍ ضبابي في الأسفل يحمل النص ===== */}
      <div className="pt-16">
        <SectionImage
          src="/brand/adam-moment.mp4"
          alt="آدم وأمّه"
          isVideo
          textAlign="bottom"
          focus="bottom"
          minH="calc(100dvh - 4rem)"
          content={null}
          cta={
            <>
              <h1 className="font-display text-[1.7rem] font-extrabold leading-[1.3] sm:text-[2.2rem]">
                وراء كل تصرّف من طفلكم سبب.
                <br />
                <span className="text-gold-strong">آدم يكتشفه — لا يخمّنه.</span>
              </h1>
              <p className="max-w-md text-sm leading-relaxed text-[color:var(--text-secondary)]">
                احكوا لآدم بكلامكم عمّا يمرّ به طفلكم، فيمنحكم خطوة اليوم: أمرًا عمليًا واحدًا مبنيًا عليه بالذات — لا نصيحة عامة كتلك التي يقدّمها أي بحث أو روبوت محادثة.
              </p>
              <div className="flex flex-col items-center gap-2 pt-2">
                <CTA />
                <p className="text-sm text-muted">دون بطاقة بنكية، ويبدأ في أقل من دقيقة</p>
              </div>
            </>
          }
        />
      </div>

      {/* ===== 2. Show, don't tell ===== */}
      <SectionImage
        src={CHAT_IMG}
        alt="محادثة دافئة مع آدم في الليل"
        textAlign="center"
        focus="center"
        content={
          <>
            <div className="glass rise-in mx-auto flex w-full max-w-md flex-col gap-4 p-6 text-right sm:p-8">
              <div className="flex justify-end">
                <div className="glass-gold max-w-[85%] rounded-2xl rounded-tl-md px-5 py-3.5 text-[15px] leading-relaxed">
                  يوسف يبكي بشدة، ولا يريد أن ينام.
                </div>
              </div>
              <div className="flex justify-start">
                <div className="flex max-w-[85%] items-start gap-3 rounded-2xl rounded-tr-md border border-[color:var(--glass-border)] bg-[color:var(--surface)] px-5 py-3.5 text-[15px] leading-relaxed">
                  <span>
                    بكاء يوسف قبل النوم غالبًا نتيجة تعب متراكم، وليس عنادًا منه. الليلة، اجلسوا بجانب يوسف دقائق بهدوء قبل محاولته النوم، دون كلام كثير.
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
          </>
        }
        cta={<CTA label="جرّبوا محادثة مثلها" />}
      />

      {/* ===== 3. المشكلة (محاربة العدو: النصائح العامة) ===== */}
      <SectionImage
        src={PROBLEM_IMG}
        alt="غرفة طفل هادئة ليلاً"
        textAlign="top"
        focus="top"
        content={
          <>
            <h2 className="font-display text-on-image text-[1.6rem] font-bold sm:text-3xl">المشكلة ليست نقص النصائح.</h2>
            <TextPanel>
              <p className="max-w-xl text-[15px] leading-relaxed text-[color:var(--text-secondary)]">
                الإنترنت مليء بالنصائح العامة، وأنتم غارقون فيها أصلاً. ما ينقصكم خطوة تخصّ طفلكم تحديدًا، في اللحظة التي تحتاجونها فعلًا.
              </p>
              <div className="mt-1 flex flex-col gap-2.5 text-[15px] text-[color:var(--text-secondary)]">
                {["وقت النوم يتحوّل إلى معركة يوميًا.", "النصائح العامة لا تنجح مع طفلكم بالذات.", "أعصابكم تصل إلى حدّها الأخير، ولا أحد يفهم السبب."].map((t) => (
                  <p key={t} className="flex items-center justify-center gap-2.5">
                    <span className="h-1.5 w-1.5 shrink-0 rounded-full bg-[color:var(--gold-strong)]" aria-hidden="true" />
                    {t}
                  </p>
                ))}
              </div>
            </TextPanel>
          </>
        }
        cta={<CTA label="لا نريد هذا بعد اليوم" />}
      />

      {/* ===== 4. البطل: خطوة اليوم ===== */}
      <SectionImage
        src={PROMISE_IMG}
        alt="ضوء الصباح الدافئ في المنزل"
        textAlign="bottom"
        focus="bottom"
        minH="800px"
        content={
          <>
            <h2 className="font-display text-on-image text-[1.6rem] font-bold sm:text-3xl">آدم لا يمنحكم نصائح أكثر.</h2>
            <p className="text-on-image text-[15px] text-gold-strong">بل يمنحكم خطوة اليوم: الأمر الواحد الذي يناسب طفلكم في هذه المرحلة بالذات.</p>
            <div className="panel-group panel-group-row glass mt-1 grid sm:grid-cols-3">
              {[
                { icon: Sparkles, title: "خطوة واحدة، لا عشرون", body: "ليست صفحة نصائح عامة، بل أمر صغير واحد تجرّبونه اليوم." },
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
          </>
        }
        cta={<CTA label="جرّبوا هذا معكم" />}
      />

      {/* ===== 5. كيف يعمل ===== */}
      <SectionImage
        src={HOW_IMG}
        alt="طريق مضيء نحو الهدوء"
        textAlign="center"
        focus="full"
        minH="760px"
        content={
          <>
            <h2 className="font-display text-on-image text-center text-[1.6rem] font-bold sm:text-3xl">كيف يعمل؟</h2>
            <div className="mt-1 grid gap-8 sm:grid-cols-3">
              {[
                { n: "01", title: "احكوا لآدم", body: "بكلامكم الخاص، دون استمارات معقّدة." },
                { n: "02", title: "يفهم طفلكم تحديدًا", body: "يكتشف ما وراء التصرّف، لا مجرد الأعراض." },
                { n: "03", title: "خطوة اليوم", body: "أمر عملي واحد، يناسب طفلكم الآن بالذات." },
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
          </>
        }
        cta={<CTA label="ابدأوا الخطوة الأولى" />}
      />

      {/* ===== آدم ينظر إليكم مباشرة — الصورة التي كانت الـ Hero، منقولة إلى مكان الفيديو السابق. رأسه كاملاً غير مقطوع (object-top)، والنص فوق التلاشي الضبابي أسفلها ===== */}
      <SectionImage
        src={HERO_IMG}
        alt="آدم ينظر إليكم مباشرة في غرفته"
        textAlign="bottom"
        focus="bottom"
        minH="720px"
        content={null}
        cta={
          <>
            <h2 className="font-display text-[1.3rem] font-bold sm:text-2xl">هذا آدم، بصوته وشخصيته.</h2>
            <p className="max-w-[30ch] text-sm leading-relaxed text-[color:var(--text-secondary)]">
              ليس أيقونة، وليس روبوتاً باردًا؛ رفيق حقيقي يعرف طفلكم.
            </p>
            <CTA label="اسمعوا آدم بنفسكم" />
          </>
        }
      />

      {/* ===== 6. Personalization — النص أعلى الصورة فوق التلاشي الضبابي، ووجه آدم في المنطقة الحادّة الواضحة أسفله ===== */}
      <SectionImage
        src={PERSONAL_IMG}
        alt="آدم يستمع بانتباه"
        textAlign="top"
        focus="top"
        minH="860px"
        content={
          <>
            <h2 className="font-display text-[1.6rem] font-bold sm:text-3xl">لا يمنح آدم النصيحة نفسها لكل بيت.</h2>
            <ul className="flex flex-col gap-2 text-[15px] text-[color:var(--text-secondary)]">
              {["عمر طفلكم", "المواقف التي تتكرر معه", "ما الذي نفع سابقًا وما لم ينفع", "الأنماط التي يلاحظها آدم"].map((li) => (
                <li key={li} className="flex items-center justify-center gap-2.5">
                  <Check size={16} strokeWidth={2.6} className="shrink-0 text-gold-strong" />
                  {li}
                </li>
              ))}
            </ul>
          </>
        }
        cta={
          <>
            <div className="glass-gold mx-auto max-w-md p-6">
              <p className="font-display text-base leading-loose text-text">
                «ألاحظ أنّ يوسف يتوتّر غالبًا عند الانتقال من اللعب إلى النوم؛ جرّبوا إخباره بالخطوة القادمة قبلها بخمس دقائق.»
              </p>
              <p className="mt-3 text-sm text-muted">هذا بالضبط ما يقوله آدم حين يعرف طفلكم فعلًا.</p>
            </div>
            <CTA label="خصّصوا آدم لطفلكم" />
          </>
        }
      />

      {/* ===== 7. الرحلة / الشجرة — النص فوق التلاشي الضبابي أعلى الصورة، والشجرة واضحة حادة في وسط وأسفل الإطار ===== */}
      <SectionImage
        src={TREE_IMG}
        alt="شجرة آدم الذهبية"
        textAlign="top"
        focus="top"
        minH="820px"
        content={
          <>
            <h2 className="font-display text-[1.6rem] font-bold sm:text-3xl">في كل مرة تختارون فيها الهدوء… تبنون شيئًا.</h2>
            <p className="max-w-lg text-[15px] leading-relaxed text-[color:var(--text-secondary)]">
              ليست نقاطًا، وليست لعبة؛ إنها لحظات حقيقية تغيّرت فيها طريقة تعاملكم، تتراكم في شجرة واحدة، ورقة بعد ورقة.
            </p>
          </>
        }
        cta={<CTA label="ابدأوا شجرتكم" />}
      />

      {/* ===== 8. لماذا آدم ===== */}
      <SectionImage
        src={COMPARE_IMG}
        alt="خلفية هادئة"
        textAlign="center"
        focus="full"
        minH="720px"
        content={
          <>
            <h2 className="font-display text-on-image text-center text-[1.6rem] font-bold sm:text-3xl">لماذا آدم، لا Google أو ChatGPT؟</h2>
            <div className="glass overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full min-w-[380px] text-right text-sm">
                  <thead>
                    <tr className="border-b border-[color:var(--glass-border)] text-muted">
                      <th className="p-4 font-medium">&nbsp;</th>
                      <th className="p-4 font-display font-bold text-gold-strong">آدم</th>
                      <th className="p-4 font-medium">Google / ChatGPT</th>
                      <th className="p-4 font-medium">نصائح عامة</th>
                    </tr>
                  </thead>
                  <tbody>
                    {["يعرف طفلكم تحديدًا", "يتذكّر السياق", "يساعدكم في اللحظة", "يتطوّر معكم"].map((row) => (
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
          </>
        }
        cta={<CTA label="جرّبوا الفرق بنفسكم" />}
      />

      {/* ===== 9. الخصوصية والثقة ===== */}
      <SectionImage
        src={TRUST_IMG}
        alt="خزانة ذهبية رمز للثقة"
        textAlign="center"
        focus="center"
        minH="720px"
        content={
          <>
            <h2 className="font-display text-on-image text-[1.6rem] font-bold sm:text-3xl">خصوصيتكم أولاً.</h2>
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
          </>
        }
        cta={<CTA label="ابدأوا بثقة" />}
      />

      {/* ===== 10. المرافقة الكاملة — بطاقة، لا شاشة كاملة ===== */}
      <SectionImage
        src={PRICING_IMG}
        alt="خلفية ذهبية فاخرة"
        textAlign="center"
        focus="center"
        minH="800px"
        content={
          <div className="glass-gold mx-auto flex w-full max-w-[300px] flex-col items-center gap-4 p-6 text-center">
            <span className="font-display text-xs font-semibold text-gold-strong">المرافقة الكاملة</span>
            <h2 className="font-display text-[1.4rem] font-bold sm:text-xl">29 يومًا حتى تشاهدوا فرقًا حقيقيًا</h2>
            <ul className="flex w-full flex-col gap-2 text-sm text-[color:var(--text-secondary)]">
              {[
                "هدف واحد واضح، تشاهدون تحقّقه بأعينكم",
                "خطوة يومية مبنية على طفلكم تحديدًا",
                "ذاكرة تتراكم معكم، فلا تكرّرون الحديث من جديد",
                "وصول كامل إلى آدم دون حدود",
              ].map((li) => (
                <li key={li} className="flex items-center justify-center gap-2 text-center">
                  <Check size={15} strokeWidth={2.6} className="shrink-0 text-gold-strong" />
                  {li}
                </li>
              ))}
            </ul>
            <p className="text-xs text-muted">يختلف السعر حسب بلدكم، ويظهر بعملتكم المحلية داخل المحادثة مع آدم.</p>
            <div className="flex w-full items-start gap-2 rounded-2xl border border-[color:var(--glass-border-gold)] bg-black/15 p-3 text-right text-xs leading-relaxed text-[color:var(--text-secondary)]">
              <ShieldCheck size={16} strokeWidth={2} className="mt-0.5 shrink-0 text-gold-strong" />
              <span>
                <span className="font-semibold text-gold-strong">ضماننا: </span>
                إن لم تشعروا بأثر واضح، نمدّد لكم نصف مدة الرحلة مجانًا.
              </span>
            </div>
            <CTA label="ابدأوا رحلتكم مع آدم" />
          </div>
        }
      />

      {/* ===== 11. أسئلة شائعة ===== */}
      <SectionImage
        src={FAQ_IMG}
        alt="خلفية هادئة"
        textAlign="center"
        focus="full"
        minH="820px"
        content={
          <>
            <h2 className="font-display text-on-image text-center text-[1.6rem] font-bold sm:text-3xl">أسئلة شائعة</h2>
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
          </>
        }
        cta={<CTA label="لا تزال لديكم أسئلة؟ جرّبوه مباشرة" />}
      />

      {/* ===== 12. Final CTA — العنوان في المنطقة الداكنة أعلى الصورة، والزر أسفلها بحيث يظهر الباب كاملاً ===== */}
      <SectionImage
        src={FINAL_IMG}
        alt="باب مفتوح على ضوء دافئ"
        textAlign="top"
        focus="top"
        minH="880px"
        content={
          <TextPanel>
            <h2 className="font-display text-[1.7rem] font-bold sm:text-3xl">لستم بحاجة إلى أن تكونوا آباءً مثاليين.</h2>
            <p className="text-[15px] text-gold-strong">تحتاجون فقط إلى معرفة ما تفعلونه في اللحظة القادمة.</p>
          </TextPanel>
        }
        cta={
          <>
            <CTA label="ابدأوا مع آدم مجاناً" />
            <p className="text-on-image text-sm text-muted">يبدأ في أقل من دقيقة.</p>
          </>
        }
      />

      {/* امتداد أنيق وخفيف من ظل الصورة الأخيرة نفسه — لا حافة فاصلة، بل تلاشٍ فاخر ينتهي بختم العلامة */}
      <footer className="bg-[rgba(8,14,10,0.97)] px-5 py-14 text-center">
        <p className="font-display text-lg font-semibold text-gold-strong">آدم — مرافق التربية الذكي</p>
      </footer>
    </>
  );
}
