import { cache } from "react";
import { supabaseAdmin, TEST_PLATFORM_USER_IDS } from "@/lib/supabase/admin";
import type { InboxConversation } from "@/lib/types";

const TEST_IDS: readonly string[] = TEST_PLATFORM_USER_IDS;

/**
 * محادثة "جديدة" تعني: آخر رسالة بشرية وصلت بعد آخر مرة فُتحت فيها هذه
 * المحادثة من الداشبورد — لا مجرد أن آدم أرسل شيئاً استباقياً، فذلك لا
 * يحتاج مراجعة من أحد.
 */
export function isUnread(row: InboxConversation): boolean {
  if (!row.last_human_message_at) return false;
  if (!row.viewed_at) return true;
  return new Date(row.last_human_message_at).getTime() > new Date(row.viewed_at).getTime();
}

export const getConversationInbox = cache(async (): Promise<InboxConversation[]> => {
  const { data, error } = await supabaseAdmin().rpc("get_conversation_inbox");
  if (error) throw new Error(error.message);
  const rows = (data ?? []) as InboxConversation[];
  return rows.filter((r) => !TEST_IDS.includes(r.platform_user_id));
});

export async function getUnreadConversationCount(): Promise<number> {
  const rows = await getConversationInbox();
  return rows.filter(isUnread).length;
}
