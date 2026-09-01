"use client";

import { useState } from "react";
import { MessageCircle } from "lucide-react";
import { Modal } from "@/components/ui/Modal";
import { ChatThread } from "@/components/customer/ChatThread";
import type { ChatMessage } from "@/lib/types";

export function ChatWindow({ messages }: { messages: ChatMessage[] }) {
  const [open, setOpen] = useState(false);

  return (
    <>
      <button
        onClick={() => setOpen(true)}
        className="flex items-center gap-1.5 rounded-lg border border-[color:var(--border)] px-3.5 py-2 text-xs font-semibold text-[color:var(--text-secondary)] transition hover:bg-[color:var(--surface-2)]"
      >
        <MessageCircle size={14} /> فتح المحادثة ({messages.length})
      </button>

      <Modal open={open} onClose={() => setOpen(false)} title="سجل المحادثة" wide>
        <ChatThread messages={messages} />
      </Modal>
    </>
  );
}
