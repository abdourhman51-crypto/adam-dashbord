import { NextResponse } from "next/server";
import { verifyInitData } from "@/lib/telegram/verify";
import { supabaseAdmin } from "@/lib/supabase/admin";

export const dynamic = "force-dynamic";

const VALID_EVENT_TYPES = new Set(["screen_view", "screen_time", "click", "session_start"]);

interface TrackBody {
  event_type?: string;
  screen?: string;
  element?: string;
  meta?: Record<string, unknown>;
  session_id?: string;
}

/**
 * تتبّع لا يمكن أن يعتمد على ترويسة x-telegram-init-data وحدها: عند إغلاق
 * التطبيق أو تبديل الشاشة نستخدم navigator.sendBeacon لضمان وصول آخر حدث،
 * وBeacon لا يسمح بترويسات مخصّصة — فقط رابط وجسم. لهذا يصل initData هنا عبر
 * معامل الرابط ?d= بدل الترويسة، وهذا المسار وحده يقبله بهذه الطريقة.
 *
 * وهذا المسار لا يفشل بصوت مرتفع أبداً: خطأ في التتبّع لا يجب أن يظهر
 * للوالد بأي شكل — يعيد 200 دائماً، نجح التسجيل أو لم ينجح.
 */
export async function POST(request: Request) {
  const url = new URL(request.url);
  const initData = url.searchParams.get("d");
  const verified = verifyInitData(initData);
  if (!verified.ok) {
    return NextResponse.json({ ok: false });
  }

  let body: TrackBody;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ ok: false });
  }

  if (!body.event_type || !VALID_EVENT_TYPES.has(body.event_type) || !body.session_id) {
    return NextResponse.json({ ok: false });
  }

  const platformUserId = String(verified.user.id);
  const { data: follower } = await supabaseAdmin()
    .from("followers")
    .select("id")
    .eq("platform", "telegram")
    .eq("platform_user_id", platformUserId)
    .maybeSingle();

  if (!follower) {
    return NextResponse.json({ ok: false });
  }

  await supabaseAdmin()
    .from("miniapp_events")
    .insert({
      follower_id: follower.id as string,
      session_id: body.session_id,
      event_type: body.event_type,
      screen: body.screen ?? null,
      element: body.element ?? null,
      meta: body.meta ?? {},
    });

  return NextResponse.json({ ok: true });
}
