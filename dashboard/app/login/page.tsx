import type { Metadata } from "next";
import Image from "next/image";
import LoginForm from "./LoginForm";

export const metadata: Metadata = { title: "تسجيل الدخول" };

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ next?: string }>;
}) {
  const { next } = await searchParams;

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto bg-[color:var(--bg)]">
      <div className="mx-auto flex min-h-dvh w-full max-w-4xl flex-col items-center justify-center gap-2 px-4 py-10 lg:flex-row-reverse lg:gap-10">
        {/* آدم — وجه البراند */}
        <div className="relative flex w-full max-w-[220px] shrink-0 justify-center lg:max-w-[280px]">
          <div
            className="absolute inset-0 rounded-full blur-3xl"
            style={{ background: "var(--primary-soft)" }}
            aria-hidden
          />
          <Image
            src="/brand/adam-character.png"
            alt="آدم"
            width={809}
            height={1021}
            priority
            className="relative h-auto w-40 sm:w-48 lg:w-full"
          />
        </div>

        <div className="rise-in w-full max-w-sm rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-8 shadow-[var(--shadow-pop)]">
          <div className="mb-8 flex flex-col items-center gap-2 text-center">
            <div className="flex h-12 w-12 items-center justify-center rounded-full bg-[color:var(--primary-soft)] p-2">
              <Image src="/brand/tree-mark.png" alt="" width={48} height={48} className="h-full w-full object-contain" />
            </div>
            <h1 className="text-lg font-bold text-[color:var(--text)]">مركز قيادة آدم</h1>
            <p className="text-sm text-[color:var(--text-muted)]">دخول داخلي — لمعز فقط</p>
          </div>
          <LoginForm next={next ?? "/"} />
        </div>
      </div>
    </div>
  );
}
