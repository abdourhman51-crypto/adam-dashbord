import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const EXPECTED_TOKEN = Deno.env.get("NOOR_TOKEN") ?? "__SET_NOOR_TOKEN__";
const PROJECT_URL = Deno.env.get("SUPABASE_URL") ?? "https://vpinaehjfflnrlpfxlko.supabase.co";

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json", "Cache-Control": "no-store" },
  });
}

function getServiceKey() {
  return Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")
    ?? (() => { try { return JSON.parse(Deno.env.get("SUPABASE_SECRET_KEYS") ?? "{}").default; } catch { return undefined; } })();
}

function allowedPayload(action: string, p: Record<string, unknown>) {
  const fields: Record<string, string[]> = {
    ingest: ["p_channel","p_external_conversation_id","p_external_message_id","p_body","p_message_type","p_sender_id","p_contact_name","p_contact_username","p_external_contact_id","p_provider","p_provider_created_at","p_raw_payload","p_metadata","p_debounce_seconds"],
    claim: ["p_conversation_id","p_batch_version"],
    finish: ["p_job_id","p_reply_text","p_provider_reply_id"],
    fail: ["p_job_id","p_error","p_retry"],
    cancel: ["p_job_id","p_reason"],
    profile_get: ["p_conversation_id"],
    profile_save: ["p_conversation_id","p_insight"],
    mark_customer: ["p_conversation_id","p_product"],
    approval_create: ["p"],
    approval_decide: ["p_token","p_decision","p_product"],
    approval_delivered: ["p_token","p_error"],
    commands_claim: ["p_limit"],
    command_finish: ["p_id","p_ok","p_result"],
  };
  const keys = fields[action];
  if (!keys) throw new Error("Unsupported action");
  const out: Record<string, unknown> = {};
  for (const key of keys) if (Object.prototype.hasOwnProperty.call(p, key)) out[key] = p[key];
  const required: Record<string, string[]> = {
    ingest: ["p_channel","p_external_conversation_id","p_external_message_id"],
    claim: ["p_conversation_id","p_batch_version"],
    finish: ["p_job_id","p_reply_text"],
    fail: ["p_job_id","p_error","p_retry"],
    cancel: ["p_job_id"],
    profile_get: ["p_conversation_id"],
    profile_save: ["p_conversation_id","p_insight"],
    mark_customer: ["p_conversation_id"],
    approval_create: ["p"],
    approval_decide: ["p_token","p_decision"],
    approval_delivered: ["p_token"],
    commands_claim: [],
    command_finish: ["p_id","p_ok"],
  };
  for (const key of required[action]) {
    if (out[key] === undefined || out[key] === null || out[key] === "") throw new Error("Missing required field: " + key);
  }
  return out;
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  if (req.headers.get("x-noor-token") !== EXPECTED_TOKEN) return json({ error: "unauthorized" }, 401);

  let input: { action?: string; payload?: Record<string, unknown> };
  try { input = await req.json(); } catch { return json({ error: "invalid_json" }, 400); }

  const action = String(input.action ?? "");
  const key = getServiceKey();
  if (!key) return json({ error: "supabase_service_key_missing" }, 500);

  if (action === "probe") {
    const response = await fetch(PROJECT_URL + "/rest/v1/rpc/noor_claim_reply_job", {
      method: "POST",
      headers: { "apikey": key, "Authorization": "Bearer " + key, "Content-Type": "application/json" },
      body: JSON.stringify({ p_conversation_id: "00000000-0000-0000-0000-000000000000", p_batch_version: 1 }),
    });
    const body = await response.text();
    return json({ probe: response.ok, status: response.status, result: body.slice(0, 500) }, response.ok ? 200 : 502);
  }

  let payload: Record<string, unknown>;
  try { payload = allowedPayload(action, input.payload ?? {}); }
  catch (e) { return json({ error: String(e instanceof Error ? e.message : e) }, 400); }

  const rpc: Record<string, string> = {
    ingest: "noor_ingest_message",
    claim: "noor_claim_reply_job",
    finish: "noor_finish_reply_job",
    fail: "noor_fail_reply_job",
    cancel: "noor_cancel_reply_job",
    profile_get: "noor_get_profile",
    profile_save: "noor_save_profile",
    mark_customer: "noor_mark_customer",
    approval_create: "noor_create_approval",
    approval_decide: "noor_decide_approval",
    approval_delivered: "noor_mark_delivered",
    commands_claim: "noor_claim_commands",
    command_finish: "noor_finish_command",
  };
  const functionName = rpc[action];
  if (!functionName) return json({ error: "unsupported_action" }, 400);

  const response = await fetch(PROJECT_URL + "/rest/v1/rpc/" + functionName, {
    method: "POST",
    headers: { "apikey": key, "Authorization": "Bearer " + key, "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  const body = await response.text();
  return new Response(body, {
    status: response.status,
    headers: { "Content-Type": response.headers.get("Content-Type") ?? "application/json", "Cache-Control": "no-store" },
  });
});
