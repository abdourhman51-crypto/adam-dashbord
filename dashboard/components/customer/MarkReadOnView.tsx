"use client";

import { useEffect } from "react";
import { markConversationReadAction } from "@/lib/actions/inbox-actions";

/** يُسجَّل أن هذه المحادثة فُتحت فور عرض الصفحة — بلا أي تفاعل من المستخدم. */
export function MarkReadOnView({ followerId }: { followerId: string }) {
  useEffect(() => {
    markConversationReadAction(followerId).catch(() => {});
  }, [followerId]);

  return null;
}
