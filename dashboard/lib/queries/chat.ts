import { supabaseAdmin } from "@/lib/supabase/admin";
import type { ChatMessage } from "@/lib/types";

export async function getChatHistory(platformUserId: string): Promise<ChatMessage[]> {
  const { data, error } = await supabaseAdmin().rpc("get_conversation_for", {
    p_platform_user_id: platformUserId,
  });
  if (error) throw new Error(error.message);
  return (data ?? []) as ChatMessage[];
}
