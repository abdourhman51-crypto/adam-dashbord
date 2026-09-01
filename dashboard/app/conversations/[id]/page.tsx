import { notFound } from "next/navigation";
import Link from "next/link";
import { ArrowRight } from "lucide-react";
import { Card } from "@/components/ui/Card";
import { ChatThread } from "@/components/customer/ChatThread";
import { MarkReadOnView } from "@/components/customer/MarkReadOnView";
import { getFollowers } from "@/lib/queries/shared";
import { getChatHistory } from "@/lib/queries/chat";

export const dynamic = "force-dynamic";
export const revalidate = 0;

export default async function ConversationDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const followers = await getFollowers(true);
  const follower = followers.find((f) => f.id === id);
  if (!follower) notFound();

  const messages = await getChatHistory(follower.platform_user_id);
  const name = follower.first_name || follower.username || `عميل ${follower.platform_user_id.slice(-4)}`;

  return (
    <div className="flex flex-col gap-4">
      <MarkReadOnView followerId={follower.id} />

      <Link
        href="/conversations"
        className="flex w-fit items-center gap-1.5 text-sm text-[color:var(--text-muted)] hover:text-[color:var(--primary)]"
      >
        <ArrowRight size={15} /> كل المحادثات
      </Link>

      <Card
        title={name}
        subtitle={`معرّف المنصة: ${follower.platform_user_id}`}
        action={
          <Link
            href={`/customers/${follower.id}`}
            className="text-xs font-medium text-[color:var(--primary)] hover:underline"
          >
            ملف العميل الكامل ←
          </Link>
        }
      >
        <ChatThread messages={messages} />
      </Card>
    </div>
  );
}
