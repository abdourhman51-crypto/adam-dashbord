"use client";

import { useEffect, useState } from "react";
import { Calendar, CalendarDays, Waves, ClipboardList, Gift, Shield, Gem, Phone, type LucideIcon } from "lucide-react";
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

export default function WizardPage() {
  const [catalog, setCatalog] = useState<CatalogResponse | null | "error" | "outside">(null);
  const [step, setStep] = useState<Step>("problem");
  const [problemKey, setProblemKey] = useState<string | null>(null);
  const [frequencyKey, setFrequencyKey] = useState<string | null>(null);
  const [outcomes, setOutcomes] = useState<OutcomesResponse | null>(null);
  const [outcomeText, setOutcomeText] = useState<string | null>(null);
  const [loadingOutcomes, setLoadingOutcomes] = useState(false);

  useEffect(() => {
    fetchScreen<CatalogResponse>("/api/wizard/catalog").then((r) => {
      if (r.state === "ok") setCatalog(r.data);
      else if (r.state === "outside_telegram") setCatalog("outside");
      else setCatalog("error");
    });
  }, []);

  if (catalog === null) return <LoadingState />;
  if (catalog === "outside") return <OutsideTelegramState />;
  if (catalog === "error") return <ErrorState message="تعذّر تحميل الاستمارة الآن." />;

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
    const r = await fetchScreen<OutcomesResponse>(`/api/wizard/outcomes?problem=${encodeURIComponent(problemKey)}`);
    if (r.state === "ok") setOutcomes(r.data);
    setLoadingOutcomes(false);
  }

  function selectOutcome(text: string) {
    haptic("medium");
    setOutcomeText(text);
    setStep("confirm");
  }

  return (
    <ScreenShell>
      <AdamIntro text="نبني خطتكم أنتم — نصف دقيقة، بلا أي التزام." />

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
  onEnter,
  onSelect,
}: {
  who: string;
  outcomes: OutcomesResponse | null;
  loading: boolean;
  onEnter: () => void;
  onSelect: (text: string) => void;
}) {
  useEffect(() => {
    if (!outcomes && !loading) onEnter();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <>
      <StepHeader step={3} title="ولو تغيّر أمر واحد فقط خلال 29 يوماً، ماذا تحبّون أن يحدث؟" />
      {loading || !outcomes ? (
        <div className="mx-auto mt-6">
          <TreeLoader />
        </div>
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
              <p className="font-display mb-2 text-[14px] text-gold-strong">وما الذي يتغيّر فعلاً مع {who}</p>
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
          خطتكم جاهزة:
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
          نُفعّل الخطة مع فريق آدم
        </button>
      ) : (
        <p className="text-center text-sm text-text-muted">تواصلوا مع آدم على تيليغرام لتفعيل الخطة.</p>
      )}
    </>
  );
}
