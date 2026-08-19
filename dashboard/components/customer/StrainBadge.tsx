"use client";

import { Badge, strainTone } from "@/components/ui/Badge";
import { Reveal } from "@/components/ui/Reveal";
import { STRAIN_LEVEL_LABELS } from "@/lib/format";
import type { ParentStrain } from "@/lib/types";

export function StrainBadge({ strain }: { strain: ParentStrain | null }) {
  if (!strain) return <Badge tone="success">{STRAIN_LEVEL_LABELS[1]}</Badge>;

  return (
    <div className="flex flex-col gap-1.5">
      <Badge tone={strainTone(strain.level)}>{STRAIN_LEVEL_LABELS[strain.level] ?? `مستوى ${strain.level}`}</Badge>
      {strain.reason && (
        <Reveal label="إظهار السبب">
          <p className="text-xs text-[color:var(--text-secondary)]">{strain.reason}</p>
        </Reveal>
      )}
    </div>
  );
}
