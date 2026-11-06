// Turns one Wapito event into at most one group item: a message (with check-in detection) or a join request.
const ctl = Object.fromEntries($('Read Control').all().map(i => [i.json.key, i.json.value]));
const GROUP = ctl.group_id;
const b = $('Wapito Events').first().json.body || {};
const d = b.data || {};
if (b.event === 'groups.participants' && d.group_id === GROUP && d.action === 'join_request') {
  return (d.participants || []).map(p => ({ json: { kind: 'join', pid: p.id, phone: p.phone || '', name: '', requested_at: new Date(Number(b.timestamp) || Date.now()).toISOString(), verdict: 'pending', status: 'pending' } }));
}
// A private message to Nour's number (text only): handed to the card desk.
if (b.event === 'messages' && !d.from_me && d.chat_id && d.chat_id !== GROUP && !/@g\.us$|@newsletter$|broadcast/.test(d.chat_id) && d.type === 'text') {
  return [{ json: { kind: 'dm', chat_id: d.chat_id, from: d.from || '', from_lid: d.from_lid || '', name: d.from_name || '', msg_id: d.id, text: String((d.text && d.text.body) || '').slice(0, 500) } }];
}
if (b.event !== 'messages' || d.chat_id !== GROUP) return [];
// The founder answered by hand from the phone: the message they replied to is handled, Nour stays out of it.
if (d.from_me) {
  const q = d.context && d.context.quoted_id;
  return (d.source === 'app' && q) ? [{ json: { kind: 'founder', msg_id: q } }] : [];
}
const text = (d.text && d.text.body) || (d[d.type] && d[d.type].caption) || '';
const at = Number(d.timestamp) || Number(b.timestamp) || Date.now();
// Night of the challenge: Algeria local time (UTC+1); anything before noon belongs to the night before.
const local = new Date(at + 3600e3);
if (local.getUTCHours() < 12) local.setUTCDate(local.getUTCDate() - 1);
const nightDate = local.toISOString().slice(0, 10);
const start = Date.parse((ctl.challenge_start || '2099-01-01') + 'T00:00:00Z');
const night = Math.round((Date.parse(nightDate + 'T00:00:00Z') - start) / 864e5) + 1;
const mark = /[✅✔☑✓]/.test(text) || /^\s*(تم|تمت|قلتها|قلتها له|قلتها لها|done)\s*[.!🤍❤️💪👍]*\s*$/i.test(text);
const checkin = mark && night >= 1 && night <= 7 && text.length <= 400;
return [{ json: {
  kind: 'msg', msg_id: d.id, participant: d.participant || d.from_lid || d.from || '', name: d.from_name || '',
  type: d.type, text: String(text).slice(0, 2000), quoted: (d.context && d.context.quoted_id) || '',
  at: new Date(at).toISOString(), checkin, night, week: ctl.active_week || 'w1', processed: checkin && text.replace(/[✅✔☑✓\s]/g, '').length < 3,
} }];
