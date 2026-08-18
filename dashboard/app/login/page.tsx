import type { Metadata } from "next";
import LoginForm from "./LoginForm";

export const metadata: Metadata = { title: "تسجيل الدخول" };

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ next?: string }>;
}) {
  const { next } = await searchParams;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-[color:var(--bg)] px-4">
      <div className="rise-in w-full max-w-sm rounded-2xl border border-[color:var(--border)] bg-[color:var(--surface)] p-8 shadow-[var(--shadow-pop)]">
        <div className="mb-8 flex flex-col items-center gap-2 text-center">
          <div className="flex h-12 w-12 items-center justify-center rounded-full bg-[color:var(--primary-soft)] text-xl font-bold text-[color:var(--primary)]">
            آ
          </div>
          <h1 className="text-lg font-bold text-[color:var(--text)]">مركز قيادة آدم</h1>
          <p className="text-sm text-[color:var(--text-muted)]">دخول داخلي — لمعز فقط</p>
        </div>
        <LoginForm next={next ?? "/"} />
      </div>
    </div>
  );
}
