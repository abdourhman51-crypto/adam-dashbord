// Founder replies typed by hand arrive from Zernio as outgoing with sentVia null; Nour's own sends carry sentVia "api".
const d = $('Prepare Claimed DM').first().json;
const r = (() => { try { return $('Takeover: Recent Messages').first().json || {}; } catch (e) { return {}; } })();
const prof = $input.first().json || {};
const profile = prof && prof.ok && prof.profile ? prof.profile : null;
const list = Array.isArray(r.messages) ? r.messages : [];
const PAUSE_MIN = 30;
const cutoff = Date.now() - PAUSE_MIN * 60 * 1000;
const isHuman = m => m.direction === 'outgoing' && !m.sentVia;
const human = list.find(m => isHuman(m) && new Date(m.createdAt || m.sentAt).getTime() >= cutoff);
// A pause set from the dashboard counts as the founder being in the conversation.
const pausedUntil = profile && profile.nour_paused_until ? new Date(profile.nour_paused_until).getTime() : 0;
const paused = pausedUntil > Date.now();

// Chronological history from the platform itself, founder replies included, minus the batch being answered now.
const chrono = [...list].sort((a, b) => new Date(a.createdAt || a.sentAt) - new Date(b.createdAt || b.sentAt));
while (chrono.length && chrono[chrono.length - 1].direction === 'incoming') chrono.pop();
const label = m => m.direction === 'incoming' ? 'هي: ' : (isHuman(m) ? 'الفريق (إنسان): ' : 'نور: ');
const text = m => (String(m.message || '').trim() || (m.attachments && m.attachments.length ? '[' + (m.attachments[0].type || 'مرفق') + ']' : '')).replace(/\s+/g, ' ').slice(0, 400);
const platformHistory = chrono.filter(m => text(m)).slice(-14).map(m => label(m) + text(m)).join('\n');

// Remember the founder's latest hand reply, so the automatic follow-up never talks over him.
const lastHuman = list.filter(isHuman).map(m => m.createdAt || m.sentAt).sort().pop();
if (lastHuman) {
  try { const sd = $getWorkflowStaticData('global'); const c = sd.convs && sd.convs[d.conversationId]; if (c) c.meta = { ...(c.meta || {}), humanAt: lastHuman }; } catch (e) {}
}

return [{ json: { ...d, humanActive: !!human || paused, pausedUntil: paused ? profile.nour_paused_until : null, humanAt: human ? (human.createdAt || human.sentAt) : null, platformHistory, zernioOk: Array.isArray(r.messages), profile } }];
