// Applies the AI's choices under hard limits, then lists every Wapito/Telegram call to make.
const p = $('Build Prompt').first().json;
const r = $input.first().json || {};
const ctl = Object.fromEntries($('Read Control').all().map(i => [i.json.key, i.json.value]));
const inbox = Object.fromEntries($('Read Inbox').all().map(i => [i.json.msg_id, i.json]));
const calls = [], log = [], alerts = [];
if (!r.ok || !r.result) {
  return [{ json: { calls: [{ op: 'telegram', text: '⚠️ نور لم تستطع قراءة رسائل المجموعة هذه الدورة (' + String(r.status || '') + '). ستعيد المحاولة بعد ساعتين.' }], log: [], mark: [], checkins: [] } }];
}
let left = p._left;
const dmSeen = new Set(p._dm);
const clean = s => String(s || '').replace(/\s+\n/g, '\n').trim().slice(0, 700);
const seen = new Set();
const done = new Set($('Read Actions').all().map(i => i.json).filter(a => ['reply', 'dm', 'alert'].includes(a.kind)).map(a => a.ref));
// Hard guards: a reply that breaks a rule is never sent; the founder gets it instead.
const bad = s => /(https?:\/\/(?!wa\.me\/213672471891))|(\$|دولار|دينار|دج\b)|(ذكاء اصطناعي|روبوت|\bبوت\b|\bAI\b|ChatGPT|نموذج لغوي)/i.test(s);
const nightOf = iso => { const l = new Date(new Date(iso).getTime() + 3600e3); if (l.getUTCHours() < 12) l.setUTCDate(l.getUTCDate() - 1); return Math.round((Date.parse(l.toISOString().slice(0, 10) + 'T00:00:00Z') - Date.parse((ctl.challenge_start || '2099-01-01') + 'T00:00:00Z')) / 864e5) + 1; };
const checkins = [];
for (const a of (r.result.actions || [])) {
  const m = inbox[a.msg_id]; if (!m || seen.has(a.msg_id)) continue; seen.add(a.msg_id);
  if (a.checkin === true) { const n = nightOf(m.at); if (n >= 1 && n <= 7) checkins.push({ week: ctl.active_week, participant: m.participant, name: m.name || '', night: n, msg_id: m.msg_id, at: m.at }); }
  if (done.has(a.msg_id)) continue;
  let doIt = String(a.do || 'skip');
  if ((doIt === 'reply' || doIt === 'dm') && bad(String(a.text || ''))) { a.why = 'ردّ محجوب (خالف القواعد): ' + String(a.text).slice(0, 150); a.text = ''; doIt = 'alert'; }
  if ((doIt === 'reply' || doIt === 'dm') && clean(a.text) && left > 0 && !(doIt === 'dm' && dmSeen.has(m.participant))) {
    left--; if (doIt === 'dm') dmSeen.add(m.participant);
    calls.push({ op: 'wapito', method: 'POST', path: '/messages/text', body: { to: ctl.group_id, body: clean(a.text), quoted: a.msg_id, typing_time: 5 } });
    log.push({ ref: a.msg_id, kind: doIt, target: m.participant, result: clean(a.text).slice(0, 200) });
  } else if (doIt === 'react') {
    calls.push({ op: 'wapito', method: 'POST', path: '/messages/' + encodeURIComponent(a.msg_id) + '/react', body: { emoji: (a.emoji && a.emoji.length <= 4) ? a.emoji : '🤍' } });
    log.push({ ref: a.msg_id, kind: 'react', target: m.participant, result: a.emoji || '🤍' });
  } else if (doIt === 'alert') {
    alerts.push(`• ${String(m.text || '').slice(0, 200)} — ${a.why || ''}`);
    log.push({ ref: a.msg_id, kind: 'alert', target: m.participant, result: String(a.why || '').slice(0, 200) });
    if (clean(a.text) && left > 0) { left--; calls.push({ op: 'wapito', method: 'POST', path: '/messages/text', body: { to: ctl.group_id, body: clean(a.text), quoted: a.msg_id, typing_time: 5 } }); }
  }
}
const post = r.result.post;
if (post && post.text && !p._posted) {
  calls.push({ op: 'wapito', method: 'POST', path: '/messages/text', body: { to: ctl.group_id, body: clean(post.text), typing_time: 6 } });
  log.push({ ref: 'post', kind: 'post', target: 'group', result: clean(post.text).slice(0, 200) });
}
if (alerts.length || r.result.note) {
  const esc = s => String(s).replace(/[<>&]/g, '');
  calls.push({ op: 'telegram', text: ('👀 <b>من مجموعة التحدّي</b>\n' + esc(alerts.join('\n')) + (r.result.note ? '\n\n' + esc(r.result.note) : '')).slice(0, 3900) });
}
const acted = Object.fromEntries(log.map(l => [l.ref, l.kind]));
const mark = p._ids.map(id => ({ msg_id: id, action: acted[id] || 'skip' }));
return [{ json: { calls, log: log.map(l => ({ ...l, at: new Date().toISOString() })), mark, checkins } }];
