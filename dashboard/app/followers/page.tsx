import type { Metadata } from "next";
import FollowersTable from "@/components/FollowersTable";
import PendingPaymentsQueue from "@/components/PendingPaymentsQueue";
import { Card } from "@/components/ui";
import { getFollowers, getPendingPayments, getSupportedCountries } from "@/lib/queries";

export const metadata: Metadata = { title: "المتابعون" };
export const revalidate = 60;

export default async function FollowersPage() {
  const [followers, pending, countries] = await Promise.all([
    getFollowers(),
    getPendingPayments(),
    getSupportedCountries(),
  ]);

  return (
    <div className="space-y-6">
      <PendingPaymentsQueue pending={pending} countries={countries} />

      <Card
        title="سجلّ المتابعين"
        subtitle="كل من تحدّث مع آدم — ابحث، صفِّ، رتّب، وافتح أي ملف للتعمق"
      >
        <FollowersTable followers={followers} />
      </Card>
    </div>
  );
}
