import Image from "next/image";
import { GlassCard } from "@/components/GlassCard";
import { TreeLoader } from "@/components/TreeLoader";

function StateShell({
  title,
  body,
  showAdam = true,
}: {
  title: string;
  body: string;
  showAdam?: boolean;
}) {
  return (
    <div
      className="flex min-h-dvh flex-col items-center justify-center gap-4 px-6 pb-32 pt-[calc(env(safe-area-inset-top)+84px)] text-center"
    >
      {showAdam && (
        <div className="glass-gold h-20 w-20 overflow-hidden !rounded-full p-0">
          <Image
            src="/brand/adam.png"
            alt=""
            width={160}
            height={160}
            className="h-full w-full object-cover object-top"
          />
        </div>
      )}
      <GlassCard>
        <p className="font-display text-lg text-text">{title}</p>
        <p className="mt-2 text-sm leading-relaxed text-text-muted">{body}</p>
      </GlassCard>
    </div>
  );
}

export function LoadingState() {
  return (
    <div className="flex min-h-dvh flex-col items-center justify-center gap-3 pb-32 pt-[calc(env(safe-area-inset-top)+84px)]">
      <TreeLoader size="lg" />
      <p className="text-sm text-text-muted">آدم يجهّز الشاشة…</p>
    </div>
  );
}

export function OutsideTelegramState() {
  return (
    <StateShell
      title="افتح هذه الشاشة من داخل تطبيق تيليغرام"
      body="هذه صفحة آدم الخاصة بكم، ولا تُفتح إلا من داخل بوت آدم على تيليغرام حفاظاً على خصوصيتكم."
    />
  );
}

export function NotFoundState() {
  return (
    <StateShell
      title="ما زلنا نتعرّف عليكم"
      body="لم نبدأ بعد رحلتنا سوياً على تيليغرام. تحدّثوا مع آدم هناك، وارجعوا لهذه الصفحة بعدها."
    />
  );
}

export function ErrorState({ message }: { message: string }) {
  return <StateShell title="تعذّر فتح الشاشة الآن" body={message} showAdam={false} />;
}
