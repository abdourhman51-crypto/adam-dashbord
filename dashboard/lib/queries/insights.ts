import {
  getFollowers,
  getChildren,
  getDailyLogs,
  getSituations,
  getChildPatterns,
  getStageProgress,
} from "./shared";
import { safeParseLightMemory, SITUATION_LABELS, PROBLEM_LABELS } from "@/lib/format";

/**
 * كل استعلامات هذه الصفحة مجمّعة بالكامل — لا معرّف/اسم عميل في أي إخراج هنا.
 */

export interface CountItem {
  label: string;
  value: number;
}

function topCounts(map: Map<string, number>, limit = 12): CountItem[] {
  return [...map.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, limit)
    .map(([label, value]) => ({ label, value }));
}

export async function getCountryDistribution(): Promise<CountItem[]> {
  const followers = await getFollowers();
  const map = new Map<string, number>();
  for (const f of followers) {
    const c = f.country?.trim() || "غير محدد";
    map.set(c, (map.get(c) ?? 0) + 1);
  }
  return topCounts(map, 20);
}

export async function getTopSituations(): Promise<CountItem[]> {
  const situations = await getSituations();
  const map = new Map<string, number>();
  for (const s of situations) {
    const label = SITUATION_LABELS[s.key] ?? s.key;
    map.set(label, (map.get(label) ?? 0) + 1);
  }
  return topCounts(map);
}

export async function getTopEmotionalStates(): Promise<CountItem[]> {
  const followers = await getFollowers();
  const map = new Map<string, number>();
  for (const f of followers) {
    const parsed = safeParseLightMemory(f.light_memory);
    const state = parsed?.emotional_state?.trim();
    if (!state) continue;
    map.set(state, (map.get(state) ?? 0) + 1);
  }
  return topCounts(map, 15);
}

export async function getTopPatterns(): Promise<CountItem[]> {
  const patterns = await getChildPatterns();
  const map = new Map<string, number>();
  for (const p of patterns) {
    map.set(p.pattern_label, (map.get(p.pattern_label) ?? 0) + 1);
  }
  return topCounts(map, 15);
}

export interface CrossTabResult {
  rows: string[];
  cols: string[];
  data: Map<string, Map<string, number>>;
}

export async function getProblemByAgeGroup(): Promise<CrossTabResult> {
  const [situations, children] = await Promise.all([getSituations(), getChildren()]);
  const childById = new Map(children.map((c) => [c.id, c]));

  const data = new Map<string, Map<string, number>>();
  const rowSet = new Set<string>();
  const colSet = new Set<string>();

  for (const s of situations) {
    const child = childById.get(s.child_id);
    const age = child?.age_note?.trim() || "غير محدد";
    const problem = SITUATION_LABELS[s.key] ?? s.key;
    rowSet.add(problem);
    colSet.add(age);
    if (!data.has(problem)) data.set(problem, new Map());
    const row = data.get(problem)!;
    row.set(age, (row.get(age) ?? 0) + 1);
  }

  return { rows: [...rowSet], cols: [...colSet].slice(0, 10), data };
}

export interface SuccessRateItem {
  label: string;
  rate: number;
  done: number;
  total: number;
}

export async function getSuccessRateBySituation(): Promise<SuccessRateItem[]> {
  const [dailyLogs, situations] = await Promise.all([getDailyLogs(), getSituations()]);
  const situationById = new Map(situations.map((s) => [s.id, s]));

  const buckets = new Map<string, { done: number; total: number }>();
  for (const log of dailyLogs) {
    if (!log.situation_id || !log.step_status) continue;
    const situation = situationById.get(log.situation_id);
    const label = situation ? SITUATION_LABELS[situation.key] ?? situation.key : "غير محدد";
    const bucket = buckets.get(label) ?? { done: 0, total: 0 };
    bucket.total += 1;
    if (log.step_status === "done") bucket.done += 1;
    buckets.set(label, bucket);
  }

  return [...buckets.entries()]
    .map(([label, { done, total }]) => ({ label, rate: total ? done / total : 0, done, total }))
    .sort((a, b) => b.rate - a.rate);
}

export async function getCountryByProblem(): Promise<CrossTabResult> {
  const [followers, stages] = await Promise.all([getFollowers(), getStageProgress()]);
  const followerById = new Map(followers.map((f) => [f.id, f]));

  const data = new Map<string, Map<string, number>>();
  const rowSet = new Set<string>();
  const colSet = new Set<string>();

  for (const s of stages) {
    const follower = followerById.get(s.parent_id);
    const country = follower?.country?.trim() || "غير محدد";
    const problem = PROBLEM_LABELS[s.problem_key] ?? s.problem_key;
    rowSet.add(country);
    colSet.add(problem);
    if (!data.has(country)) data.set(country, new Map());
    const row = data.get(country)!;
    row.set(problem, (row.get(problem) ?? 0) + 1);
  }

  return { rows: [...rowSet], cols: [...colSet], data };
}

export async function getTopObjectives(): Promise<CountItem[]> {
  const stages = await getStageProgress();
  const map = new Map<string, number>();
  for (const s of stages) {
    const text = s.objective_text?.trim();
    if (!text) continue;
    map.set(text, (map.get(text) ?? 0) + 1);
  }
  return topCounts(map, 12);
}

const CONTINUITY_MILESTONES = [3, 7, 14, 21, 29];

export async function getContinuityDistribution(): Promise<CountItem[]> {
  const dailyLogs = await getDailyLogs();
  const nightsByFollower = new Map<string, Set<string>>();
  for (const log of dailyLogs) {
    if (!log.night_result) continue;
    if (!nightsByFollower.has(log.follower_id)) nightsByFollower.set(log.follower_id, new Set());
    nightsByFollower.get(log.follower_id)!.add(log.log_date);
  }

  const counts = CONTINUITY_MILESTONES.map((m) => ({ label: `${m}+ ليلة`, value: 0 }));
  for (const nights of nightsByFollower.values()) {
    const n = nights.size;
    CONTINUITY_MILESTONES.forEach((m, i) => {
      if (n >= m) counts[i].value += 1;
    });
  }
  return counts;
}

export async function getClarityFromFirstMessage(): Promise<{ clear: number; needsFollowUp: number }> {
  const situations = await getSituations();
  const clear = situations.filter((s) => s.evidence_count <= 1).length;
  const needsFollowUp = situations.filter((s) => s.evidence_count > 1).length;
  return { clear, needsFollowUp };
}

export async function getAvgNightsToFirstCalm(): Promise<{ avgNights: number; sampleSize: number }> {
  const dailyLogs = await getDailyLogs();
  const byFollower = new Map<string, typeof dailyLogs>();
  for (const log of dailyLogs) {
    if (!log.night_result) continue;
    if (!byFollower.has(log.follower_id)) byFollower.set(log.follower_id, []);
    byFollower.get(log.follower_id)!.push(log);
  }

  const nightsToCalm: number[] = [];
  for (const logs of byFollower.values()) {
    const sorted = [...logs].sort((a, b) => a.log_date.localeCompare(b.log_date));
    const firstCalmIndex = sorted.findIndex((l) => l.night_result === "calm");
    if (firstCalmIndex === -1) continue;
    const distinctDates = new Set(sorted.slice(0, firstCalmIndex + 1).map((l) => l.log_date));
    nightsToCalm.push(distinctDates.size);
  }

  const avgNights = nightsToCalm.length
    ? nightsToCalm.reduce((a, b) => a + b, 0) / nightsToCalm.length
    : 0;
  return { avgNights, sampleSize: nightsToCalm.length };
}
