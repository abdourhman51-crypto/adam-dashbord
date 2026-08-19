"use client";

import { useActionState } from "react";
import { loginAction, type LoginState } from "@/lib/actions/auth-actions";

const initialState: LoginState = { error: null };

export default function LoginForm({ next }: { next: string }) {
  const [state, formAction, pending] = useActionState(loginAction, initialState);

  return (
    <form action={formAction} className="flex flex-col gap-4">
      <input type="hidden" name="next" value={next} />

      <div className="flex flex-col gap-1.5">
        <label htmlFor="email" className="text-sm font-medium text-[color:var(--text-secondary)]">
          البريد الإلكتروني
        </label>
        <input
          id="email"
          name="email"
          type="email"
          autoComplete="email"
          required
          dir="ltr"
          className="w-full rounded-lg border border-[color:var(--border)] bg-[color:var(--surface)] px-3.5 py-2.5 text-sm text-[color:var(--text)] outline-none transition focus:border-[color:var(--primary)] focus:ring-2 focus:ring-[color:var(--primary-soft)]"
          placeholder="you@example.com"
        />
      </div>

      <div className="flex flex-col gap-1.5">
        <label htmlFor="password" className="text-sm font-medium text-[color:var(--text-secondary)]">
          كلمة المرور
        </label>
        <input
          id="password"
          name="password"
          type="password"
          autoComplete="current-password"
          required
          dir="ltr"
          className="w-full rounded-lg border border-[color:var(--border)] bg-[color:var(--surface)] px-3.5 py-2.5 text-sm text-[color:var(--text)] outline-none transition focus:border-[color:var(--primary)] focus:ring-2 focus:ring-[color:var(--primary-soft)]"
          placeholder="••••••••"
        />
      </div>

      {state.error && (
        <p className="rounded-lg bg-[color:var(--error-soft)] px-3.5 py-2.5 text-sm text-[color:var(--error)]">
          {state.error}
        </p>
      )}

      <button
        type="submit"
        disabled={pending}
        className="mt-2 w-full rounded-lg bg-[color:var(--primary)] px-4 py-2.5 text-sm font-semibold text-[color:var(--on-primary)] transition hover:bg-[color:var(--primary-strong)] disabled:opacity-60"
      >
        {pending ? "جارٍ الدخول…" : "تسجيل الدخول"}
      </button>
    </form>
  );
}
