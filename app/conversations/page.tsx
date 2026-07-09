import type { Metadata } from "next";
import { MessagesSquare, Users, Scale, Radio } from "lucide-react";
import { KpiCard } from "@/components/ui";
import ConversationsExplorer from "@/components/ConversationsExplorer";
import { getConversationList } from "@/lib/queries";
import { formatNumber } from "@/lib/format";

export const metadata: Metadata = { title: "المحادثات" };
export const revalidate = 60;

export default async function ConversationsPage() {
  const conversations = await getConversationList();

  const total = conversations.reduce((s, c) => s + c.count, 0);
  const human = conversations.reduce((s, c) => s + c.humanCount, 0);
  const ai = conversations.reduce((s, c) => s + c.aiCount, 0);
  const avg = conversations.length > 0 ? Math.round(total / conversations.length) : 0;

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-lg font-bold">المحادثات</h1>
        <p className="mt-0.5 text-sm text-[color:var(--text-muted)]">
          كل الحوارات الفعلية بين آدم والمتابعين — مصدرها المباشر قاعدة البيانات
        </p>
      </div>

      <div className="grid grid-cols-2 gap-3 xl:grid-cols-4">
        <KpiCard label="إجمالي الرسائل" value={formatNumber(total)} icon={<MessagesSquare size={20} />} />
        <KpiCard
          label="عدد المحادثات"
          value={formatNumber(conversations.length)}
          icon={<Users size={20} />}
          tone="info"
        />
        <KpiCard label="متوسط الرسائل للمحادثة" value={formatNumber(avg)} icon={<Scale size={20} />} tone="gold" />
        <KpiCard
          label="توازن الحوار"
          value={`${formatNumber(human)} ↔ ${formatNumber(ai)}`}
          hint="رسائل المتابعين ↔ ردود آدم"
          icon={<Radio size={20} />}
          tone="success"
        />
      </div>

      <ConversationsExplorer conversations={conversations} />
    </div>
  );
}
