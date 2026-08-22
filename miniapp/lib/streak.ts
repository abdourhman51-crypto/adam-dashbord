export const STREAK_MILESTONES = [3, 5, 7, 10, 14, 21, 29] as const;

interface StreakNight {
  logDate: string;
  result: "calm" | "hard" | "normal" | null;
}

/**
 * الأيام المتتالية اللي حكى فيها الوالد (أي إجابة تُحسب — الجهد لا النتيجة،
 * بنفس روح parent_effort). nights مرتّبة تنازلياً بالتاريخ (الأحدث أولاً).
 */
export function computeStreak(nights: StreakNight[]): number {
  let streak = 0;
  let expectedDate: number | null = null;

  for (const night of nights) {
    if (!night.result) break;
    const time = new Date(`${night.logDate}T12:00:00`).getTime();
    if (expectedDate !== null && time !== expectedDate) break;
    streak += 1;
    expectedDate = time - 24 * 60 * 60 * 1000;
  }

  return streak;
}

export function isMilestone(streak: number): boolean {
  return (STREAK_MILESTONES as readonly number[]).includes(streak);
}
