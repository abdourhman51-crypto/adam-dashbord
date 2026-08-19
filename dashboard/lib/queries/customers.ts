import { supabaseAdmin } from "@/lib/supabase/admin";
import {
  getFollowers,
  getChildren,
  getStageProgress,
  getParentStrains,
  getCheckinStates,
  getPayments,
} from "./shared";
import type { Follower } from "@/lib/types";

export interface CustomerFilters {
  q?: string;
  country?: string;
  status?: string;
  from?: string;
  to?: string;
}

function matches(f: Follower, filters: CustomerFilters) {
  if (filters.q) {
    const q = filters.q.trim().toLowerCase();
    const hay = `${f.first_name ?? ""} ${f.username ?? ""} ${f.platform_user_id}`.toLowerCase();
    if (!hay.includes(q)) return false;
  }
  if (filters.country && f.country !== filters.country) return false;
  if (filters.status && f.funnel_stage !== filters.status) return false;
  if (filters.from && f.first_seen < filters.from) return false;
  if (filters.to && f.first_seen > filters.to) return false;
  return true;
}

export async function listCustomers(filters: CustomerFilters) {
  const followers = await getFollowers();
  const filtered = followers.filter((f) => matches(f, filters));
  return filtered.sort((a, b) => +new Date(b.first_seen) - +new Date(a.first_seen));
}

export async function listCountries() {
  const followers = await getFollowers();
  const set = new Set(followers.map((f) => f.country).filter((c): c is string => Boolean(c)));
  return [...set].sort();
}

export async function getCustomerDetail(followerId: string) {
  const [followers, children, stages, strains, checkins, payments] = await Promise.all([
    getFollowers(),
    getChildren(),
    getStageProgress(),
    getParentStrains(),
    getCheckinStates(),
    getPayments(),
  ]);

  const follower = followers.find((f) => f.id === followerId);
  if (!follower) return null;

  const myChildren = children.filter((c) => c.follower_id === followerId);
  const myStages = stages.filter((s) => s.parent_id === followerId);
  const strain = strains.find((s) => s.parent_id === followerId) ?? null;
  const checkin = checkins.find((c) => c.parent_id === followerId) ?? null;
  const myPayments = payments
    .filter((p) => p.follower_id === followerId)
    .sort((a, b) => +new Date(b.created_at) - +new Date(a.created_at));

  const { data: erasureRows } = await supabaseAdmin()
    .from("erasure_requests")
    .select("id, status, requested_at")
    .eq("parent_id", followerId)
    .eq("status", "requested")
    .order("requested_at", { ascending: false })
    .limit(1);
  const pendingErasureId = erasureRows?.[0]?.id ?? null;

  const childRecords = await Promise.all(
    myChildren.map(async (child) => {
      const { data, error } = await supabaseAdmin().rpc("get_child_record", {
        p_child_id: child.id,
        p_initiated_by: "operator",
      });
      if (error) return { child, record: null, reason: error.message };
      const row = Array.isArray(data) ? data[0] : data;
      return { child, record: row?.record ?? null, reason: row?.reason ?? null };
    })
  );

  return {
    follower,
    children: myChildren,
    stages: myStages,
    strain,
    checkin,
    payments: myPayments,
    childRecords,
    pendingErasureId,
  };
}
