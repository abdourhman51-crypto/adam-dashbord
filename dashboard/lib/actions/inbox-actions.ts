"use server";

import { revalidatePath } from "next/cache";
import { supabaseAdmin } from "@/lib/supabase/admin";

export async function markConversationReadAction(followerId: string) {
  const { error } = await supabaseAdmin().rpc("mark_conversation_read", { p_follower_id: followerId });
  if (error) throw new Error(error.message);
  revalidatePath("/conversations");
  revalidatePath("/");
}
