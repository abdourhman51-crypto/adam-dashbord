"use client";

import { useEffect, useState } from "react";
import { Phone, Target, MessageCircle, ShieldCheck } from "lucide-react";
import Link from "next/link";
import { ScreenShell } from "@/components/ScreenShell";
import { AdamIntro } from "@/components/AdamIntro";
import { GlassCard } from "@/components/GlassCard";
import { LoadingState, OutsideTelegramState, ErrorState } from "@/components/states";
import { fetchScreen, postAction } from "@/lib/telegram/fetcher";
import { openLink, haptic } from "@/lib/telegram/client";
import { returnToAdamChat } from "@/lib/upsell";

interface CatalogResponse {
  childName: string | null;
  countrySupported: boolean;
  price: string | null;
  countryName: string | null;
  teamUrl: string | null;
  alreadyInStage: boolean;
  alreadyAgreed: boolean;
  ready: boolean;
  suggestedObjectiveText: string | null;
  currentObjectiveText: string | null;
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
 * والدٌ اتّفق على هدفه بالفعل — إمّا في المحادثة (لحظة الاتفاق)، أو للتوّ
 * من نفس هذه الشاشة عبر «نعم، هذا اتفاقنا». الحالتان متطابقتان تماماً:
 * agreed_objective موجود، ولا رحلة نشطة بعد.
 */
function AlreadyAgreed({
  objectiveText,
  teamUrl,
}: {
  objectiveText: string | null;
  teamUrl: string | null;
}) {
  return (
    <ScreenShell>
      <AdamIntro text="🎉 هذا اتّفاقكم — لم يبقَ إلا تفعيله." />
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
    </ScreenShell>
  );
}

/**
 * لا دليل كافٍ بعد لهدف حقيقي (suggest_objective.ready = false) — نفس
 * القاعدة التي تحكم لحظة الاتفاق في المحادثة: لا نخترع هدفاً لبيت لم
 * نتعرّف عليه بما يكفي. بدل استمارة تجمع إجابات لن تُستعمل أبداً، نقول
 * الحقيقة ونعيده لمحادثة حقيقية مع آدم — من هناك يُبنى الدليل الذي يجعل
 * هذه الشاشة جاهزة لاحقاً.
 */
function NotReadyYet({ childName }: { childName: string | null }) {
  const who = childName ?? "طفلكم";
  return (
    <ScreenShell>
      <AdamIntro text="لسّا نتعرّف على بيتكم — وهذا طبيعي في البداية." />
      <GlassCard className="rise-in text-center">
        <p className="text-sm leading-relaxed text-text-muted">
          الاتفاق هنا يُبنى على أصعب لحظة عرفها آدم فعلاً مع {who}، لا على اختيار من قائمة.
          احكوا له عنها في المحادثة أولاً — وحين تتوضّح الصورة، هذه الشاشة تفتح على اتفاقكم مباشرة.
        </p>
      </GlassCard>
      <button
        type="button"
        onClick={() => {
          haptic("medium");
          returnToAdamChat();
        }}
        className="pressable-gold flex items-center justify-center gap-2 px-5 py-3.5 text-sm font-semibold"
      >
        <MessageCircle size={17} strokeWidth={2.2} />
        أحكي لآدم الآن
      </button>
    </ScreenShell>
  );
}

/**
 * الدليل جاهز (suggest_objective.ready = true): نعرض نفس الهدف الذي تعرضه
 * لحظة الاتفاق في المحادثة حرفياً، ونؤكّده بنفس الدالة الحقيقية
 * (agree_objective) — فوالدٌ يتّفق من هنا يصبح مطابقاً تماماً لوالدٍ اتّفق
 * في المحادثة، بدل استمارة منفصلة لا تكتب شيئاً.
 */
function ReadyToAgree({
  childName,
  objectiveText,
  price,
  countrySupported,
  onAgreed,
}: {
  childName: string | null;
  objectiveText: string | null;
  price: string | null;
  countrySupported: boolean;
  onAgreed: (objectiveText: string | null) => void;
}) {
  const [working, setWorking] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const who = childName ?? "طفلكم";

  async function confirm() {
    haptic("medium");
    setWorking(true);
    setError(null);
    const r = await postAction<{ agreed: boolean; objectiveText: string | null }>("/api/wizard/agree", {});
    if (r.state === "ok" && r.data.agreed) {
      onAgreed(r.data.objectiveText);
    } else {
      setError(r.state === "error" ? r.message : "تعذّر تسجيل الاتفاق الآن، حاولوا مرة أخرى.");
      setWorking(false);
    }
  }

  return (
    <ScreenShell>
      <AdamIntro text="نبني اتفاقكم أنتم — من ملاحظات آدم الحقيقية معكم." />
      <GlassCard variant="gold" className="rise-in">
        <p className="text-xs font-medium text-text-muted">الهدف خلال 29 يوماً، مع {who}</p>
        <p className="font-display mt-2 text-[19px] leading-relaxed text-text">
          {objectiveText}
        </p>
        <p className="mt-4 flex items-start gap-2 text-sm leading-relaxed text-text-secondary">
          <ShieldCheck size={16} className="mt-0.5 shrink-0 text-gold-strong" strokeWidth={2.2} />
          وباتفاق واضح: إن لم نصل لهذا الهدف بالذات خلال المدة، أُكمل معكم نصف المدة إضافية مجاناً حتى نصل.
        </p>
        {countrySupported && price && (
          <p className="font-display mt-4 text-[15px] text-gold-strong">
            الاستثمار: {price}، لمدّة 29 يوماً — لهذا الهدف بالذات، لا اشتراك عام.
          </p>
        )}
      </GlassCard>

      {error && (
        <GlassCard className="rise-in text-center">
          <p className="text-sm leading-relaxed text-text-muted">{error}</p>
        </GlassCard>
      )}

      <button
        type="button"
        onClick={confirm}
        disabled={working}
        className="pressable-gold flex items-center justify-center gap-2 px-5 py-3.5 text-sm font-semibold disabled:opacity-60"
      >
        <Target size={17} strokeWidth={2.2} />
        {working ? "لحظة…" : "نعم، هذا اتفاقنا"}
      </button>
      <button
        type="button"
        onClick={() => {
          haptic("light");
          returnToAdamChat();
        }}
        className="pressable flex items-center justify-center gap-2 px-5 py-3.5 text-sm font-medium text-text-muted"
      >
        عندي شيء أهمّ أحكي عنه أولاً
      </button>
    </ScreenShell>
  );
}

export default function WizardPage() {
  const [catalog, setCatalog] = useState<CatalogResponse | null | "error" | "outside">(null);
  const [justAgreedText, setJustAgreedText] = useState<string | null>(null);
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

  if (catalog.alreadyAgreed || justAgreedText) {
    return (
      <AlreadyAgreed
        objectiveText={justAgreedText ?? catalog.currentObjectiveText}
        teamUrl={catalog.teamUrl}
      />
    );
  }

  if (!catalog.ready) {
    return <NotReadyYet childName={catalog.childName} />;
  }

  return (
    <ReadyToAgree
      childName={catalog.childName}
      objectiveText={catalog.suggestedObjectiveText}
      price={catalog.price}
      countrySupported={catalog.countrySupported}
      onAgreed={(text) => setJustAgreedText(text ?? catalog.suggestedObjectiveText)}
    />
  );
}
