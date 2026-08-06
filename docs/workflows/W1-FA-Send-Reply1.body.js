// Node: `FA - Send Reply1`  (n8n-nodes-base.httpRequest, typeVersion 4.2)
// Workflow: `ADAM - Machine 1+2` (42loY0bgUSwYmHFV)
// Sends the paid agent's reply to Telegram. Now reads the GATED reply instead of
// the raw model output.
//
// The gate: `Gate - Agent Reply` returns { ok, blocked, violations, ... }. When
// `blocked === true`, the reply is withheld and replaced with the reply_withheld
// copy (hardcoded here rather than a second round trip — the migration's own
// design: "Callers get one round trip, not two"). If the gate call errored,
// `blocked` is undefined — not === true — so the raw reply passes through. Fail
// open, matching the node's onError.
//
// The country-ask footer is untouched: when `M2 - Get Memory Snapshot` says
// ask === true, the ask body and its inline buttons are appended.
//
// jsonBody:
={{ (() => {
  const rawGate = $('Gate - Agent Reply').first().json;
  const gate = Array.isArray(rawGate) ? (rawGate[0] || {}) : (rawGate || {});
  const rawAgent = String($('paid aget adam').first().json.output || '').trim();
  const NL = String.fromCharCode(10);
  const reply = (gate && gate.blocked === true)
    ? ('هذه تستحق جواباً أدقّ ممّا كنت سأقول.' + NL + 'احكوا لي أكثر عمّا حدث، وأنا معكم.')
    : rawAgent;
  let b = $('M2 - Get Memory Snapshot').first().json;
  b = Array.isArray(b) ? (b[0] || {}) : (b || {});
  if (b && typeof b.data === 'string') { try { b = JSON.parse(b.data); } catch (e) { b = {}; } }
  const ask = b && b.ask === true && b.ask_body;
  const body = {
    chat_id: $('Router').first().json.chat_id,
    text: ask ? (reply + NL + NL + b.ask_body) : reply,
    disable_web_page_preview: true
  };
  if (ask) {
    const rows = [];
    for (const x of (b.ask_buttons || [])) { rows.push([{ text: x.label, callback_data: x.cb }]); }
    body.reply_markup = { inline_keyboard: rows };
  } else {
    body.reply_markup = { remove_keyboard: true };
  }
  return JSON.stringify(body);
})() }}
