import { supabaseAdmin } from "@/lib/supabase/admin";
import { EmptyState } from "@/components/ui/EmptyState";
import { PatternReviewCard } from "@/components/patterns/PatternReviewCard";
import type { PatternPendingReview } from "@/lib/types";

export const dynamic = "force-dynamic";
export const revalidate = 0;

export default async function PatternsPage() {
  const { data, error } = await supabaseAdmin().rpc("get_patterns_pending_review", { p_limit: 50 });
  if (error) throw new Error(error.message);
  const patterns = (data ?? []) as PatternPendingReview[];

  return (
    <div className="flex flex-col gap-4">
      <p className="text-sm text-[color:var(--text-muted)]">
        أنماط اكتشفها آدم من كلام الوالدين ولم تُعتمد بعد للعرض عليهم — راجع كل نمط قبل السماح بظهوره.
      </p>

      {patterns.length === 0 ? (
        <EmptyState title="لا توجد أنماط بانتظار المراجعة" body="كل شيء تمت مراجعته حتى الآن." />
      ) : (
        <div className="grid gap-4 md:grid-cols-2">
          {patterns.map((p) => (
            <PatternReviewCard key={p.pattern_id} pattern={p} />
          ))}
        </div>
      )}
    </div>
  );
}
