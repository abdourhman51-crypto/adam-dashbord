// Node: `Gate - Agent Reply`  (n8n-nodes-base.httpRequest, typeVersion 4.4)
// Workflow: `ADAM - Machine 1+2` (42loY0bgUSwYmHFV)
// Sits between `paid aget adam` and `FA - Send Reply1`.
//
// POST https://aajqbmjasnbwwyvgrlzy.supabase.co/rest/v1/rpc/gate_agent_reply
// auth: predefinedCredentialType / nodeCredentialType "supabaseApi"
//        (credential "adam Supabase" EI2e62pg3bxhCSMJ — attached by hand in the
//         n8n UI; the MCP API cannot bind supabaseApi to an httpRequest node)
// onError: continueRegularOutput  — the gate fails OPEN. If the call errors, the
//        raw reply still reaches FA - Send Reply1 and is sent unchanged. A gate
//        outage must never swallow a reply a parent is waiting on.
//
// jsonBody:
={{ (() => {
  const pid = $('M2 - Build Paid Context').first().json.id;
  const reply = String($('paid aget adam').first().json.output || '').trim();
  return JSON.stringify({ p_parent_id: pid, p_body: reply });
})() }}
