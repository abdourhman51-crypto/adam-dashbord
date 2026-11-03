
const sd = $getWorkflowStaticData('global');
const convs = sd.convs ?? {};
const now = Date.now();
const out = [];
for (const [id, c] of Object.entries(convs)) {
  const m = c.meta || {};
  if (m.followedUp || m.customer || m.escalated || m.stage === 'closed' || m.stage === 'freebie' || m.stage === 'customer') continue;
  // The founder replied by hand recently: he owns this conversation, no automatic follow-up.
  if (m.humanAt && now - Date.parse(m.humanAt) < 48 * 3600000) continue;
  if (!m.lastUserAt || !m.lastBotAt) continue;
  const sinceUser = (now - Date.parse(m.lastUserAt)) / 3600000;
  if (sinceUser < 20 || sinceUser > 23.3) continue;
  if (Date.parse(m.lastBotAt) < Date.parse(m.lastUserAt)) continue;
  m.followedUp = true;
  const said = (c.history || []).filter(h => h.role === 'assistant').map(h => typeof h.content === 'string' ? h.content : JSON.stringify(h.content)).join('\n');
  const offered = /inad\.adamvoices\.site/.test(said) ? 'inad' : /hodn\.adamvoices\.site/.test(said) ? 'hodn' : /adamvoices\.site\/cards/.test(said) ? 'cards' : '';
  out.push({ json: { conversationId: id, accountId: m.accountId, platform: m.platform, name: m.name || '', stage: m.stage || '', country: m.country || '', offered, history: (c.history || []).slice(-12) } });
}
return out;

