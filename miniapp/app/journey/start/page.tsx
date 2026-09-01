"use client";

import { useEffect, useState } from "react";
import { Calendar, CalendarDays, Waves, ClipboardList, Gift, Shield, Gem, Phone, Target, type LucideIcon } from "lucide-react";
import Link from "next/link";
import { ScreenShell } from "@/components/ScreenShell";
import { AdamIntro } from "@/components/AdamIntro";
import { GlassCard } from "@/components/GlassCard";
import { TreeLoader } from "@/components/TreeLoader";
import { LoadingState, OutsideTelegramState, ErrorState } from "@/components/states";
import { fetchScreen } from "@/lib/telegram/fetcher";
import { openLink, haptic } from "@/lib/telegram/client";
import { IconGlyph, IconText } from "@/lib/emojiIcons";

interface CatalogResponse {
  childName: string | null;
  problems: { key: string; emoji: string; label: string }[];
  countrySupported: boolean;
  price: string | null;
  countryName: string | null;
  teamUrl: string | null;
  alreadyInStage: boolean;
  alreadyAgreed: boolean;
  currentObjectiveText: string | null;
}

interface OutcomesResponse {
  outcomes: string[];
  promises: string[];
}

const FREQUENCIES: { key: string; label: string; confirmLabel: string; icon: LucideIcon }[] = [
  { key: "daily", label: "كل يوم تقريباً", confirmLabel: "كل يوم تقريباً", icon: Calendar },
  { key: "weekly", label: "عدة مرات في الأسبوع", confirmLabel: "عدة مرات في الأسبوع", icon: CalendarDays },
  { key: "occasional", label: "بين فترة وأخرى، لكنه يوجع حين يحدث", confirmLabel: "بين فترة وأخرى", icon: Waves },
];

type Step = "problem" | "frequency" | "outcome" | "confirm";

function StepHeader({ step, title }: { step: number; title: string }) {
  return (
    <div className="rise-in">
      <div className="mb-3 h-1.5 w-full overflow-hidden rounded-full bg-glass-bg">
        <div
          className="h-full rounded-full bg-gradient-to-l from-gold to-gold-strong transition-all duration-500"
          style={{ width: `${(step / 4) * 100}%` }}
        />
      </div>
      <p className="text-xs font-medium text-text-muted">خطوة {step} من 4</p>
      <p className="font-display mt-1 text-[19px] leading-relaxed text-text">{title}</p>
    </div>
  );
}

/**
 * والدٌ مشترك، له هدف نشط بالفعل — فتح الاستمارة الفارغة هنا كان منطقياً
 * فقط للوالد الذي لم يختر هدفاً بعد. من غير المنطقي أن يعيد استمارة كاملة
 * ليعدّل هدفاً موجوداً بالفعل، فيصل لصفحة تشرح له وضعه الحالي وتقوده
 * لمكانين حقيقيين: تقدّمه الفعلي، أو فريق آدم إن أراد تغييراً حقيقياً.
 */
function AlreadyInStage({ objectiveText, teamUrl }: { objectiveText: string | null; teamUrl: string | null }) {
  return (
    <ScreenShell>
      <AdamIntro text="عندكم هدف نشط بالفعل — الاستمارة هذي لمن لم يبدأ بعد." />
      <GlassCard variant="gold" className="rise-in">
        <p className="text-xs font-medium text-text-muted">هدفكم الحالي</p>
        <p className="font-display mt-2 text-[19px] leading-relaxed text-text">
          {objectiveText ?? "قيد المتابعة"}
        </p>
      </GlassCard>
      <Link
        href="/journey"
        className="pressable-gold flex items-center justify-center gap-2 px-5 py-3.5 text-sm font-semibold"
      >
        <Target size={17} strokeWidth={2.2} />
        أشوف تقدّمي
      </Link>
      {teamUrl && (
        <button
          type="button"
          onClick={() => {
            haptic("light");
            openLink(teamUrl);
          }}
          className="pressable flex items-center justify-center gap-2 px-5 py-3.5 text-sm font-medium text-text-muted"
        >
          <Phone size={16} strokeWidth={2.2} />
          أريد تغيير الهدف — أتحدّث مع فريق آدم
        </button>
      )}
    </ScreenShell>
  );
}

/**
 * والدٌ اتّفق على هدفه بالفعل في المحادثة (لحظة الاتفاق) قبل أن يدفع —
 * agreed_objective موجود، لكن لا رحلة نشطة بعد. فتح استمارة فارغة هنا يعني
 * سؤاله عمّا أجاب عنه بالفعل قبل قليل؛ الأصحّ أن يرى اتفاقه ويُفعّله مباشرة،
 * تماماً كما تعرضه نفس اللحظة في المحادثة.
 */
function AlreadyAgreed({
  objectiveText,
  teamUrl,
  onRestart,
}: {
  objectiveText: string | null;
  teamUrl: string | null;
  onRestart: () => void;
}) {
  return (
    <ScreenShell>
      <AdamIntro text="🎉 هذا اتّفاقكم — اتّفقنا عليه في المحادثة، ولم يبقَ إلا تفعيله." />
      <GlassCard variant="gold" className="rise-in">
        <p className="text-xs font-medium text-text-muted">هدفكم المتّفق عليه</p>
        <p className="font-display mt-2 text-[19px] leading-relaxed text-text">
          {objectiveText ?? "قيد المتابعة"}
        </p>
      </GlassCard>
      {teamUrl ? (
        <button
          type="button"
          onClick={() => {
            haptic("medium");
            openLink(teamUrl);
          }}
          className="pressable-gold flex w-full items-center justify-center gap-2 px-5 py-3.5 text-sm font-semibold"
        >
          <Phone size={16} strokeWidth={2.2} />
          نُفعّل الاتفاق مع فريق آدم
        </button>
      ) : (
        <p className="text-center text-sm text-text-muted">تواصلوا مع آدم على تيليغرام لتفعيل الاتفاق.</p>
      )}
      <button
        type="button"
        onClick={() => {
          haptic("light");
          onRestart();
        }}
        className="pressable flex items-center justify-center gap-2 px-5 py-3.5 text-sm font-medium text-text-muted"
      >
        أُعيد الاستمارة من جديد
      </button>
    </ScreenShell>
  );
}

export default function WizardPage() {
  const [catalog, setCatalog] = useState<CatalogResponse | null | "error" | "outside">(null);
  const [step, setStep] = useState<Step>("problem");
  const [forceForm, setForceForm] = useState(false);
  const [problemKey, setProblemKey] = useState<string | null>(null);
  const [frequencyKey, setFrequencyKey] = useState<string | null>(null);
  const [outcomes, setOutcomes] = useState<OutcomesResponse | null>(null);
  const [outcomeText, setOutcomeText] = useState<string | null>(null);
  const [loadingOutcomes, setLoadingOutcomes] = useState(false);
  const [outcomesError, setOutcomesError] = useState<string | null>(null);
  const [catalogError, setCatalogError] = useState<string | null>(null);

  function loadCatalog() {
    setCatalog(null);
    setCatalogError(null);
    fetchScreen<CatalogResponse>("/api/wizard/catalog").then((r) => {
      if (r.state === "ok") setCatalog(r.data);
      else if (r.state === "outside_telegram") setCatalog("outside");
      else {
        setCatalog("error");
        setCatalogError(r.state === "error" ? r.message : "تعذّر تحميل الاستمارة الآن.");
      }
    });
  }

  useEffect(() => {
    loadCatalog();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  if (catalog === null) return <LoadingState />;
  if (catalog === "outside") return <OutsideTelegramState />;
  if (catalog === "error") {
    return <ErrorState message={catalogError ?? "تعذّر تحميل الاستمارة الآن."} onRetry={loadCatalog} />;
  }
  if (catalog.alreadyInStage) {
    return <AlreadyInStage objectiveText={catalog.currentObjectiveText} teamUrl={catalog.teamUrl} />;
  }

  if (catalog.alreadyAgreed && !forceForm) {
    return (
      <AlreadyAgreed
        objectiveText={catalog.currentObjectiveText}
        teamUrl={catalog.teamUrl}
        onRestart={() => setForceForm(true)}
      />
    );
  }

  const who = catalog.childName ?? "طفلكم";
  const problem = catalog.problems.find((p) => p.key === problemKey);
  const frequency = FREQUENCIES.find((f) => f.key === frequencyKey);

  async function selectProblem(key: string) {
    haptic("light");
    setProblemKey(key);
    setStep("frequency");
  }

  function selectFrequency(key: string) {
    haptic("light");
    setFrequencyKey(key);
    setStep("outcome");
  }

  async function goToOutcome() {
    if (!problemKey) return;
    setLoadingOutcomes(true);
    setOutcomesError(null);
    const r = await fetchScreen<OutcomesResponse>(`/api/wizard/outcomes?problem=${encodeURIComponent(problemKey)}`);
    if (r.state === "ok") setOutcomes(r.data);
    else setOutcomesError(r.state === "error" ? r.message : "تعذّر تحميل الخيارات الآن.");
    setLoadingOutcomes(false);
  }

  function selectOutcome(text: string) {
    haptic("medium");
    setOutcomeText(text);
    setStep("confirm");
  }

  return (
    <ScreenShell>
      <AdamIntro text="نبني اتفاقكم أنتم — نصف دقيقة، بلا أي التزام." />

      {step === "problem" && (
        <>
          <StepHeader step={1} title={`ما الأمر الذي يتعبكم أكثر هذه الأيام مع ${who}؟`} />
          <div className="mt-2 grid grid-cols-2 gap-3">
            {catalog.problems.map((p) => (
              <button
                key={p.key}
                type="button"
                onClick={() => selectProblem(p.key)}
                className="pressable !rounded-2xl px-4 py-5 text-center text-sm font-medium"
              >
                <IconGlyph emoji={p.emoji} size={26} className="mb-2 block text-gold-strong" />
                {p.label}
              </button>
            ))}
          </div>
        </>
      )}

      {step === "frequency" && problem && (
        <>
          <StepHeader step={2} title={`وكم مرة يتكرر «${problem.label}» معكم؟`} />
          <div className="mt-2 flex flex-col gap-2.5">
            {FREQUENCIES.map((f) => (
              <button
                key={f.key}
                type="button"
                onClick={() => selectFrequency(f.key)}
                className="pressable flex items-center gap-3 !rounded-2xl px-5 py-4 text-sm font-medium"
              >
                <f.icon size={18} className="text-gold-strong" strokeWidth={2.2} />
                {f.label}
              </button>
            ))}
          </div>
        </>
      )}

      {step === "outcome" && (
        <OutcomeStep
          who={who}
          outcomes={outcomes}
          loading={loadingOutcomes}
          error={outcomesError}
          onEnter={goToOutcome}
          onSelect={selectOutcome}
        />
      )}

      {step === "confirm" && problem && frequency && outcomeText && (
        <ConfirmStep
          who={who}
          problem={problem}
          frequencyLabel={frequency.confirmLabel}
          outcomeText={outcomeText}
          catalog={catalog}
        />
      )}
    </ScreenShell>
  );
}

function OutcomeStep({
  who,
  outcomes,
  loading,
  error,
  onEnter,
  onSelect,
}: {
  who: string;
  outcomes: OutcomesResponse | null;
  loading: boolean;
  error: string | null;
  onEnter: () => void;
  onSelect: (text: string) => void;
}) {
  useEffect(() => {
    if (!outcomes && !loading && !error) onEnter();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <>
      <StepHeader step={3} title="ولو تغيّر شيء واحد في كيف تتعاملون معه خلال 29 يوماً، ماذا تحبّون أن يتغيّر؟" />
      {loading ? (
        <div className="mx-auto mt-6">
          <TreeLoader />
        </div>
      ) : error || !outcomes ? (
        <GlassCard className="rise-in mt-4 text-center">
          <p className="text-sm leading-relaxed text-text-muted">{error ?? "تعذّر تحميل الخيارات الآن."}</p>
          <button
            type="button"
            onClick={onEnter}
            className="pressable-gold mt-4 px-5 py-2.5 text-sm font-semibold"
          >
            حاول مرة أخرى
          </button>
        </GlassCard>
      ) : (
        <div className="mt-2 flex flex-col gap-2.5">
          {outcomes.outcomes.map((o) => (
            <button
              key={o}
              type="button"
              onClick={() => onSelect(o)}
              className="pressable !rounded-2xl px-5 py-4 text-right text-sm font-medium"
            >
              <IconText text={o} />
            </button>
          ))}

          {outcomes.promises.length > 0 && (
            <GlassCard className="rise-in mt-2">
              <p className="font-display mb-2 text-[14px] text-gold-strong">وما الذي ينتظركم فعلاً</p>
              <div className="flex flex-col gap-1.5">
                {outcomes.promises.map((p) => (
                  <p key={p} className="text-xs leading-relaxed text-text-secondary">
                    <IconText text={p} />
                  </p>
                ))}
              </div>
            </GlassCard>
          )}
        </div>
      )}
    </>
  );
}

function ConfirmStep({
  who,
  problem,
  frequencyLabel,
  outcomeText,
  catalog,
}: {
  who: string;
  problem: { emoji: string; label: string };
  frequencyLabel: string;
  outcomeText: string;
  catalog: CatalogResponse;
}) {
  return (
    <>
      <StepHeader step={4} title="آخر خطوة" />

      <GlassCard variant="gold" className="rise-in">
        <p className="font-display flex items-center gap-2 text-[16px] text-gold-strong">
          <ClipboardList size={18} strokeWidth={2.2} />
          اتّفاقكم جاهز:
        </p>
        <div className="mt-4 flex flex-col gap-3 text-sm leading-relaxed text-text">
          <p className="flex items-start gap-2">
            <IconGlyph emoji={problem.emoji} size={16} className="mt-0.5 shrink-0 text-gold-strong" />
            <span>
              الأمر الذي يتعبكم مع {who}: {problem.label}، {frequencyLabel}
            </span>
          </p>
          <p>الهدف خلال 29 يوماً: {outcomeText}</p>
        </div>

        <p className="mt-4 flex items-start gap-2 text-sm leading-relaxed text-text-secondary">
          <Gift size={16} className="mt-0.5 shrink-0 text-gold-strong" strokeWidth={2.2} />
          ومعها تُفتح بصائر آدم — صفحة تتابعون فيها بالأرقام كل أسبوع: هل تحسّن الوضع فعلاً؟
        </p>
        <p className="mt-3 flex items-start gap-2 text-sm leading-relaxed text-text-secondary">
          <Shield size={16} className="mt-0.5 shrink-0 text-gold-strong" strokeWidth={2.2} />
          وباتفاق واضح: إن لم نصل لهذا الهدف بالذات خلال المدة، أُكمل معكم نصف المدة إضافية مجاناً حتى نصل.
        </p>

        {catalog.countrySupported && catalog.price && (
          <p className="font-display mt-4 flex items-center gap-2 text-[15px] text-gold-strong">
            <Gem size={16} strokeWidth={2.2} />
            الاستثمار: {catalog.price}، لمدّة 29 يوماً — لهذا الهدف بالذات، لا اشتراك عام.
          </p>
        )}
      </GlassCard>

      {catalog.teamUrl ? (
        <button
          type="button"
          onClick={() => {
            haptic("medium");
            openLink(catalog.teamUrl!);
          }}
          className="pressable-gold flex w-full items-center justify-center gap-2 px-5 py-3.5 text-sm font-semibold"
        >
          <Phone size={16} strokeWidth={2.2} />
          نُفعّل الاتفاق مع فريق آدم
        </button>
      ) : (
        <p className="text-center text-sm text-text-muted">تواصلوا مع آدم على تيليغرام لتفعيل الاتفاق.</p>
      )}
    </>
  );
}
