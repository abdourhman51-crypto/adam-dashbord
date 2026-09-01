import { EmptyState } from "@/components/ui/EmptyState";
import { formatDateTime } from "@/lib/format";
import type { ChatMessage } from "@/lib/types";

export function ChatThread({ messages }: { messages: ChatMessage[] }) {
  if (messages.length === 0) return <EmptyState title="لا توجد رسائل بعد" />;

  return (
    <div className="flex flex-col gap-3">
      {messages.map((m) => {
        const isHuman = m.message?.type === "human";
        return (
          <div key={m.id} className={`flex ${isHuman ? "justify-end" : "justify-start"}`}>
            <div
              className={`max-w-[80%] rounded-2xl px-4 py-2.5 text-sm leading-relaxed ${
                isHuman
                  ? "rounded-tl-sm bg-[color:var(--primary)] text-[color:var(--on-primary)]"
                  : "rounded-tr-sm bg-[color:var(--surface-2)] text-[color:var(--text)]"
              }`}
            >
              <p className="whitespace-pre-wrap">{m.message?.content}</p>
              <p
                className={`mt-1 text-left text-[10px] ${
                  isHuman ? "text-[color:var(--on-primary)]/70" : "text-[color:var(--text-muted)]"
                }`}
              >
                {formatDateTime(m.created_at)}
              </p>
            </div>
          </div>
        );
      })}
    </div>
  );
}
