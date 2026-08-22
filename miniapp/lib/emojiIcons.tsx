import {
  Flame,
  DoorOpen,
  Smartphone,
  ShieldAlert,
  BookOpen,
  Moon,
  UtensilsCrossed,
  Users,
  Target,
  Shield,
  Gift,
  Gem,
  Phone,
  MessageCircle,
  Lock,
  CheckCircle2,
  Smile,
  Zap,
  Brain,
  TrendingUp,
  BookMarked,
  Sparkles,
  PartyPopper,
  RotateCcw,
  ClipboardList,
  CalendarDays,
  Calendar,
  Waves,
  Check,
  type LucideIcon,
} from "lucide-react";

/** خريطة الرموز المستخدَمة فعلياً بمحتوى Supabase الحي — بديل آدم البصري بدل الإيموجي العام. */
export const EMOJI_ICON_MAP: Record<string, LucideIcon> = {
  "🔥": Flame,
  "🚪": DoorOpen,
  "📱": Smartphone,
  "😤": ShieldAlert,
  "📚": BookOpen,
  "🌙": Moon,
  "🍽️": UtensilsCrossed,
  "👦": Users,
  "🎯": Target,
  "🛡️": Shield,
  "🎁": Gift,
  "💎": Gem,
  "📞": Phone,
  "💬": MessageCircle,
  "🔒": Lock,
  "✅": CheckCircle2,
  "😌": Smile,
  "💪": Zap,
  "🧠": Brain,
  "📈": TrendingUp,
  "📖": BookMarked,
  "✨": Sparkles,
  "🎉": PartyPopper,
  "🔄": RotateCcw,
  "📋": ClipboardList,
  "🗓️": CalendarDays,
  "📅": Calendar,
  "〰️": Waves,
  "✓": Check,
};

export function IconGlyph({ emoji, size = 16, className = "" }: { emoji: string; size?: number; className?: string }) {
  const Icon = EMOJI_ICON_MAP[emoji];
  if (!Icon) return null;
  return <Icon size={size} strokeWidth={2.2} className={className} />;
}

const EMOJI_PATTERN = /\p{Extended_Pictographic}️?/gu;

/** يقسّم نصاً يحتوي رموز إيموجي (من محتوى Supabase) ويستبدلها بأيقونات آدم — بلا لمس المحتوى بقاعدة البيانات نفسها. */
export function IconText({ text, className = "" }: { text: string; className?: string }) {
  const parts: (string | { emoji: string })[] = [];
  let lastIndex = 0;
  for (const match of text.matchAll(EMOJI_PATTERN)) {
    const index = match.index ?? 0;
    if (index > lastIndex) parts.push(text.slice(lastIndex, index));
    parts.push({ emoji: match[0] });
    lastIndex = index + match[0].length;
  }
  if (lastIndex < text.length) parts.push(text.slice(lastIndex));

  return (
    <span className={className}>
      {parts.map((part, i) =>
        typeof part === "string" ? (
          <span key={i}>{part}</span>
        ) : (
          <IconGlyph key={i} emoji={part.emoji} className="mx-1 -mb-0.5 inline text-gold-strong" />
        )
      )}
    </span>
  );
}
