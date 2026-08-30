"use client";

import { useEffect, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  Menu,
  X,
  ChevronLeft,
  ArrowRight,
  Sparkles,
  Cog,
  Gem,
  Users,
  Settings,
  ShieldCheck,
  type LucideIcon,
} from "lucide-react";
import { GlassCard } from "@/components/GlassCard";
import { TreeLoader } from "@/components/TreeLoader";
import { TreeLightbox } from "@/components/TreeLightbox";
import { IconText } from "@/lib/emojiIcons";
import { fetchScreen } from "@/lib/telegram/fetcher";
import { getInitDataRaw, openLink, haptic } from "@/lib/telegram/client";
import { returnToAdamChat } from "@/lib/upsell";
import { formatNumber } from "@/lib/format";

interface MenuButton {
  label: string;
  cb?: string;
  url?: string;
}

interface MenuMoment {
  body: string;
  buttons: MenuButton[];
}

const ENTRIES: { key: string; label: string; icon: LucideIcon; group: "about" | "settings" }[] = [
  { key: "menu_faq", label: "تعرّف على آدم", icon: Sparkles, group: "about" },
  { key: "menu_how", label: "كيف يشتغل؟", icon: Cog, group: "about" },
  { key: "menu_why", label: "وما الذي يميّزه؟", icon: Gem, group: "about" },
  { key: "menu_pricing_diff", label: "المجاني مقابل المرافقة الكاملة", icon: Gem, group: "about" },
  { key: "menu_family", label: "عائلة آدم", icon: Users, group: "about" },
  { key: "menu_settings", label: "إعدادات الرسائل", icon: Settings, group: "settings" },
  { key: "menu_privacy", label: "الخصوصية وحذف البيانات", icon: ShieldCheck, group: "settings" },
];

const GROUP_LABELS: Record<"about" | "settings", string> = {
  about: "عن آدم",
  settings: "الإعدادات",
};

/**
 * بعض أزرار المحتوى القادم من get_conversation_moment (مثل "🎯 أشوف
 * المرافقة الكاملة" بمفتاح menu_journey، الظاهر داخل menu_pricing_diff و
 * menu_why) لا يقابلها موضوع نصي داخل ENTRIES — هي أصلاً بوابة تجارية تقود
 * لواجهة التخصيص الحقيقية، لا بطاقة نص. أي مفتاح هنا يُفتح كصفحة Next.js
 * حقيقية بدل محاولة تحميله كموضوع من /api/menu (الذي سيفشل بصمت لأنه غير
 * معرّف أصلاً بجدول conversation_moments كموضوع مستقل ذي محتوى).
 */
const ROUTE_TARGETS: Record<string, string> = {
  menu_journey: "/journey/start",
};

/**
 * الشريط العلوي الدائم للمنصة: شعار آدم + اسمه (يفتحان الشجرة الحيّة)، وزر
 * القائمة، وزر ذهبي دائم يقود لواجهة التخصيص المدفوعة — كلها في شريط واحد
 * واضح لا يغطي محتوى الشاشة (المحتوى يُزاح تحته دائماً، انظر ScreenShell).
 */
export function TopBar() {
  const router = useRouter();
  const [calmCount, setCalmCount] = useState<number | null>(null);
  const [treeOpen, setTreeOpen] = useState(false);
  // ⭐ والدٌ مشترك وله هدف نشط بالفعل: «بصيص أمل» يقوده لتقدّمه الفعلي،
  // لا لاستمارة فارغة يظنّ أنها ستُبنى من جديد. المستخدم الحر أو المشترك
  // بلا هدف نشط يبقى يذهب للاستمارة كما هو متوقّع.
  const [hopeTarget, setHopeTarget] = useState("/journey/start");

  const [menuOpen, setMenuOpen] = useState(false);
  const [activeKey, setActiveKey] = useState<string | null>(null);
  const [moment, setMoment] = useState<MenuMoment | null>(null);
  const [loading, setLoading] = useState(false);
  const [momentError, setMomentError] = useState<string | null>(null);

  useEffect(() => {
    const initData = getInitDataRaw();
    if (!initData) return;
    let cancelled = false;

    fetch("/api/tree", { headers: { "x-telegram-init-data": initData } })
      .then((res) => (res.ok ? res.json() : null))
      .then((data: { calmCount: number } | null) => {
        if (cancelled || !data) return;
        setCalmCount(data.calmCount);
      })
      .catch(() => {});

    fetch("/api/journey", { headers: { "x-telegram-init-data": initData } })
      .then((res) => (res.ok ? res.json() : null))
      .then((data: { isPaid?: boolean; inStage?: boolean } | null) => {
        if (cancelled || !data) return;
        if (data.isPaid && data.inStage) setHopeTarget("/journey");
      })
      .catch(() => {});

    return () => {
      cancelled = true;
    };
  }, []);

  async function loadKey(key: string) {
    setMenuOpen(false);
    setActiveKey(key);
    setLoading(true);
    setMoment(null);
    setMomentError(null);
    const r = await fetchScreen<MenuMoment>(`/api/menu?key=${encodeURIComponent(key)}`);
    if (r.state === "ok") setMoment(r.data);
    else setMomentError(r.state === "error" ? r.message : "تعذّر تحميل هذي الشاشة الآن.");
    setLoading(false);
  }

  function onButtonPress(b: MenuButton) {
    haptic("light");
    if (b.cb && ROUTE_TARGETS[b.cb]) {
      closeAll();
      // نفس منطق «بصيص أمل»: زر يقود لواجهة الاستمارة يجب أن يقود لتقدّم
      // الوالد الفعلي إن كان له هدف نشط بالفعل، لا استمارة فارغة من جديد.
      router.push(b.cb === "menu_journey" ? hopeTarget : ROUTE_TARGETS[b.cb]);
      return;
    }
    if (b.url) {
      openLink(b.url);
      return;
    }
    if (b.cb === "other") {
      returnToAdamChat();
      return;
    }
    if (b.cb && ENTRIES.some((e) => e.key === b.cb)) {
      loadKey(b.cb);
      return;
    }
    // أي زر آخر غير معروف هنا (مثل menu_privacy_erase_ask أو
    // menu_settings_hours) هو إجراء يحتاج محادثة حقيقية مع البوت — يكتب
    // بيانات، يسأل تأكيداً، يفتح منتقي وقت... التطبيق المصغّر قراءة فقط ولا
    // يقدر يُكمل هذا هنا. أصح رد هو إرجاع الوالد لمحادثته الفعلية ليكمل هناك،
    // لا تجاهل صامت لأي زر — هذا بالضبط الخلل الذي أصلحناه مع menu_journey.
    if (b.cb) {
      returnToAdamChat();
    }
  }

  function backToList() {
    setActiveKey(null);
    setMoment(null);
    setMenuOpen(true);
  }

  function closeAll() {
    setMenuOpen(false);
    setActiveKey(null);
    setMoment(null);
  }

  return (
    <>
      <header className="glass-strong fixed inset-x-0 top-0 z-30 flex items-center justify-between gap-2 !rounded-none border-x-0 border-t-0 px-4 pb-3 pt-[max(env(safe-area-inset-top),14px)]">
        <button
          type="button"
          onClick={() => setTreeOpen(true)}
          className="flex items-center gap-2 border-0 bg-transparent p-0"
          style={{ touchAction: "manipulation" }}
          aria-label="شجرة آدم — افتحوها لتكبيرها"
        >
          <span className="relative flex h-9 w-9 shrink-0 items-center justify-center">
            <Image src="/brand/tree.png" alt="" width={36} height={36} className="h-9 w-9 object-contain" priority />
            {calmCount !== null && calmCount > 0 && (
              <span className="glass-gold absolute -end-1.5 -top-1.5 flex h-4 min-w-4 items-center justify-center rounded-full px-1 text-[9px] font-bold text-gold-strong">
                <span className="tabular">{formatNumber(calmCount)}</span>
              </span>
            )}
          </span>
          <span className="font-display text-[21px] font-extrabold leading-none text-gold-strong">آدم</span>
        </button>

        <div className="flex shrink-0 items-center gap-2">
          <Link
            href={hopeTarget}
            onClick={() => haptic("light")}
            className="pressable flex items-center gap-1.5 whitespace-nowrap !rounded-full px-3.5 py-2.5 text-[13px] font-semibold"
          >
            <Sparkles size={14} strokeWidth={2.4} />
            بصيص أمل
          </Link>
          <button
            type="button"
            onClick={() => setMenuOpen(true)}
            className="pressable flex h-10 w-10 shrink-0 items-center justify-center !rounded-2xl border-[1.5px] border-emerald-strong"
            aria-label="القائمة"
          >
            <Menu size={19} strokeWidth={2.3} />
          </button>
        </div>
      </header>

      {treeOpen && <TreeLightbox leafCount={calmCount ?? 0} onClose={() => setTreeOpen(false)} />}

      {/* قائمة العناوين — درج جانبي */}
      {menuOpen && (
        <div className="fixed inset-0 z-40 flex" role="dialog" aria-modal="true">
          <div className="absolute inset-0 bg-bg-deep/80 backdrop-blur-sm" onClick={closeAll} aria-hidden="true" />
          <div className="glass-strong relative z-10 flex h-full w-[82%] max-w-sm flex-col gap-3 overflow-y-auto !rounded-none border-e border-glass-border p-5 pt-[max(env(safe-area-inset-top),20px)]">
            <div className="mb-2 flex items-center justify-between">
              <p className="font-display text-[19px] text-gold-strong">قائمة آدم</p>
              <button
                type="button"
                onClick={closeAll}
                className="pressable flex h-9 w-9 items-center justify-center !rounded-full border-0"
                aria-label="إغلاق"
              >
                <X size={17} />
              </button>
            </div>
            {(["about", "settings"] as const).map((group) => (
              <div key={group} className="flex flex-col gap-2">
                <p className="mt-1 px-1 text-xs font-semibold text-text-muted">{GROUP_LABELS[group]}</p>
                {ENTRIES.filter((e) => e.group === group).map((e) => (
                  <button
                    key={e.key}
                    type="button"
                    onClick={() => loadKey(e.key)}
                    className="pressable rise-in flex items-center justify-between !rounded-2xl px-4 py-3.5 text-sm font-medium"
                    style={{ animationDelay: `${ENTRIES.indexOf(e) * 45}ms` }}
                  >
                    <span className="flex items-center gap-2.5">
                      <e.icon size={17} className="text-gold-strong" strokeWidth={2.2} />
                      {e.label}
                    </span>
                    <ChevronLeft size={16} />
                  </button>
                ))}
              </div>
            ))}
          </div>
        </div>
      )}

      {/* شاشة كاملة لمحتوى العنصر — منصة، لا نافذة صغيرة */}
      {activeKey && (
        <div className="fixed inset-0 z-50 overflow-y-auto bg-bg-deep">
          <div
            className="absolute inset-0"
            style={{
              background:
                "radial-gradient(120% 60% at 50% -10%, var(--bg-glow) 0%, transparent 60%), linear-gradient(180deg, var(--bg-mid) 0%, var(--bg-deep) 55%, #081009 100%)",
            }}
          />
          <div className="relative z-10 mx-auto flex min-h-full max-w-md flex-col gap-5 px-4 pb-16 pt-[max(env(safe-area-inset-top),20px)]">
            <div className="flex items-center justify-between">
              <button
                type="button"
                onClick={backToList}
                className="pressable flex h-10 w-10 items-center justify-center !rounded-full border-0"
                aria-label="رجوع للقائمة"
              >
                <ArrowRight size={18} />
              </button>
              <button
                type="button"
                onClick={closeAll}
                className="pressable flex h-10 w-10 items-center justify-center !rounded-full border-0"
                aria-label="إغلاق"
              >
                <X size={18} />
              </button>
            </div>

            {loading ? (
              <div className="flex flex-1 items-center justify-center pt-16">
                <TreeLoader size="lg" />
              </div>
            ) : moment ? (
              <>
                <GlassCard variant="strong" className="whitespace-pre-line text-[15px] leading-loose text-text">
                  <IconText text={moment.body} />
                </GlassCard>
                {moment.buttons.length > 0 && (
                  <div className="flex flex-col gap-2.5">
                    {moment.buttons.map((b) => (
                      <button
                        key={b.label}
                        type="button"
                        onClick={() => onButtonPress(b)}
                        className="pressable px-4 py-3.5 text-sm font-medium"
                      >
                        <IconText text={b.label} />
                      </button>
                    ))}
                  </div>
                )}
              </>
            ) : (
              <div className="pt-16 text-center">
                <p className="text-sm text-text-muted">{momentError ?? "تعذّر تحميل هذي الشاشة الآن."}</p>
                <button
                  type="button"
                  onClick={() => loadKey(activeKey)}
                  className="pressable-gold mt-4 px-5 py-2.5 text-sm font-semibold"
                >
                  حاول مرة أخرى
                </button>
              </div>
            )}
          </div>
        </div>
      )}
    </>
  );
}
