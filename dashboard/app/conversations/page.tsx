import Link from "next/link";
import { Card } from "@/components/ui/Card";
import { EmptyState } from "@/components/ui/EmptyState";
import { getConversationInbox, isUnread } from "@/lib/queries/inbox";
import { relativeTime, formatNumber } from "@/lib/format";

export const dynamic = "force-dynamic";
export const revalidate = 0;

export default async function ConversationsPage({
  searchParams,
}: {
  searchParams: Promise<{ unread?: string }>;
}) {
  const { unread } = await searchParams;
  const onlyUnread = unread === "1";
  const rows = await getConversationInbox();
  const unreadCount = rows.filter(isUnread).length;
  const visible = onlyUnread ? rows.filter(isUnread) : rows;

  const tabClass = (active: boolean) =>
    `rounded-lg px-3.5 py-2 text-sm font-semibold transition ${
      active
        ? "bg-[color:var(--primary)] text-[color:var(--on-primary)]"
        : "border border-[color:var(--border)] text-[color:var(--text-secondary)] hover:bg-[color:var(--surface-2)]"
    }`;

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h2 className="text-lg font-bold text-[color:var(--text)]">المحادثات</h2>
          <p className="text-sm text-[color:var(--text-muted)]">
            {unreadCount > 0
              ? `${formatNumber(unreadCount)} محادثة فيها رسائل جديدة لم تُراجَع بعد`
              : "لا رسائل جديدة الآن — كل شيء مُراجَع"}
          </p>
        </div>
        <div className="flex gap-2">
          <Link href="/conversations" className={tabClass(!onlyUnread)}>
            الكل ({formatNumber(rows.length)})
          </Link>
          <Link href="/conversations?unread=1" className={tabClass(onlyUnread)}>
            غير المقروءة {unreadCount > 0 ? `(${formatNumber(unreadCount)})` : ""}
          </Link>
        </div>
      </div>

      <Card noPadding>
        {visible.length === 0 ? (
          <div className="p-6">
            <EmptyState
              title={onlyUnread ? "لا رسائل جديدة الآن" : "لا توجد محادثات بعد"}
              body={onlyUnread ? "كل المحادثات مُراجَعة." : undefined}
            />
          </div>
        ) : (
          <ul className="divide-y divide-[color:var(--border)]">
            {visible.map((row) => {
              const unreadRow = isUnread(row);
              const name = row.first_name || row.username || `عميل ${row.platform_user_id.slice(-4)}`;
              return (
                <li key={row.follower_id}>
                  <Link
                    href={`/conversations/${row.follower_id}`}
                    className="flex items-center gap-3 px-5 py-4 transition hover:bg-[color:var(--surface-2)]"
                  >
                    <span
                      className={`h-2.5 w-2.5 shrink-0 rounded-full ${
                        unreadRow ? "bg-[color:var(--primary)]" : "bg-transparent"
                      }`}
                      aria-hidden="true"
                    />
                    <div className="flex min-w-0 flex-1 flex-col gap-0.5">
                      <span
                        className={`text-sm ${
                          unreadRow ? "font-bold text-[color:var(--text)]" : "font-medium text-[color:var(--text-secondary)]"
                        }`}
                      >
                        {name}
                      </span>
                      <span className="truncate text-xs text-[color:var(--text-muted)]">
                        {row.last_message_from === "ai" && <span>آدم: </span>}
                        {row.last_message_preview || "—"}
                      </span>
                    </div>
                    <span className="shrink-0 text-xs text-[color:var(--text-muted)]">
                      {relativeTime(row.last_message_at)}
                    </span>
                  </Link>
                </li>
              );
            })}
          </ul>
        )}
      </Card>
    </div>
  );
}
