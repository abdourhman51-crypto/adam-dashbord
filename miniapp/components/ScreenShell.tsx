import type { ReactNode } from "react";
import { TreeBackdrop } from "@/components/TreeBackdrop";

export function ScreenShell({ children }: { children: ReactNode }) {
  return (
    <div className="relative min-h-dvh overflow-x-hidden pb-32 pt-8">
      <TreeBackdrop />
      <div className="relative z-10 mx-auto flex max-w-md flex-col gap-5 px-4">{children}</div>
    </div>
  );
}
