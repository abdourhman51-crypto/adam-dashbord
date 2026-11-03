// Commands queued from the dashboard (Supabase admin_commands). Claimed in Supabase, so each runs once.
const tokenHdr = $('Cancel DM Job').params.headerParameters.parameters.find(h => h.name === 'x-noor-token').value;
const zAuth = $('Send DM Reply').params.headerParameters.parameters.find(h => h.name === 'Authorization').value;
const RPC = 'https://vpinaehjfflnrlpfxlko.supabase.co/functions/v1/noor-inbox-rpc';
const ACCOUNTS = { facebook: '6ad4f3af064cfbdce83e674c', instagram: '6ad4f3c0fff6142041afeecd' };
const rpc = (action, payload) => this.helpers.httpRequest({ method: 'POST', url: RPC, headers: { 'Content-Type': 'application/json', 'x-noor-token': tokenHdr }, body: { action, payload }, json: true });
const msg = e => String((e && (e.description || e.message)) || e).slice(0, 300);

let list = [];
try { list = await rpc('commands_claim', { p_limit: 10 }); } catch (e) { return [{ json: { claimed: 0, error: msg(e) } }]; }
if (!Array.isArray(list) || !list.length) return [{ json: { claimed: 0 } }];

const sd = $getWorkflowStaticData('global');
const out = [];
for (const c of list) {
  let ok = false, result = '';
  try {
    if (c.kind !== 'send_dm') throw new Error('unknown kind ' + c.kind);
    const accountId = ACCOUNTS[c.channel];
    if (!accountId) throw new Error('no account for ' + c.channel);
    await this.helpers.httpRequest({
      method: 'POST', url: 'https://zernio.com/api/v1/inbox/conversations/' + encodeURIComponent(c.external_conversation_id) + '/messages',
      headers: { Authorization: zAuth, 'Content-Type': 'application/json' }, body: { accountId, message: c.text }, json: true,
    });
    ok = true; result = 'sent';
    // Nour's memory sees the founder's message as part of the conversation.
    const conv = sd.convs && sd.convs[c.external_conversation_id];
    if (conv) {
      conv.history = [...(conv.history || []), { role: 'assistant', content: '[الفريق] ' + c.text }].slice(-24);
      conv.meta = { ...(conv.meta || {}), humanAt: new Date().toISOString(), lastBotAt: new Date().toISOString() };
    }
  } catch (e) { result = msg(e); }
  try { await rpc('command_finish', { p_id: c.id, p_ok: ok, p_result: result }); } catch (e) {}
  out.push({ json: { id: c.id, ok, result } });
}
return out;
