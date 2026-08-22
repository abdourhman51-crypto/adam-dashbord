import type { ReactNode } from "react";

export function ScreenShell({ children }: { children: ReactNode }) {
  return (
    <div className="relative min-h-dvh overflow-x-hidden pb-32 pt-[calc(env(safe-area-inset-top)+84px)]">
      <div className="relative z-10 mx-auto flex max-w-md flex-col gap-5 px-4">{children}</div>
    </div>
  );
}
