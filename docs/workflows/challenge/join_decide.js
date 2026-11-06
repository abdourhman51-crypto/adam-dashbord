// Women: approved only while the join window is open (between challenges). Men: declined. Unclear: left for the founder.
const ctl = Object.fromEntries($('Read Control').all().map(i => [i.json.key, i.json.value]));
const people = $('Ask Names').first().json._people || [];
const r = $input.first().json || {};
const g = {}; for (const x of ((r.result && r.result.r) || [])) g[x.pid] = x.g;
const now = Date.now();
const day = s => Date.parse(s + 'T00:00:00Z');
// Closed from the eve of the challenge (20:00 UTC the day before) until the morning after the last night (08:00 UTC).
const closeAt = day(ctl.challenge_start || '2099-01-01') - 4 * 3600e3;
const openAt = day(ctl.challenge_end || '2099-01-01') + 864e5 + 8 * 3600e3;
const mode = String(ctl.join_window || 'auto');
const open = mode === 'open' || (mode === 'auto' && !(now >= closeAt && now < openAt));
const known = Object.fromEntries($('Read Queue').all().map(i => [i.json.pid, i.json]));
const GROUP = encodeURIComponent(ctl.group_id);
const calls = [], rows = [], unclear = [];
for (const p of people) {
  const v = r.ok ? (g[p.pid] || 'U') : 'U';
  let status = 'pending';
  if (v === 'M') { status = 'declined'; calls.push({ op: 'wapito', method: 'DELETE', path: `/groups/${GROUP}/applications/${encodeURIComponent(p.pid)}`, _pid: p.pid }); }
  else if (v === 'F' && open) { status = 'approved'; calls.push({ op: 'wapito', method: 'POST', path: `/groups/${GROUP}/applications/${encodeURIComponent(p.pid)}/approve`, _pid: p.pid }); }
  else if (v === 'U' && !(known[p.pid] && known[p.pid].verdict === 'U')) unclear.push(p);
  rows.push({ pid: p.pid, phone: p.phone, name: p.name, verdict: v, status });
}
if (unclear.length) calls.push({ op: 'telegram', text: ('👤 <b>طلبات انضمام لم أستطع الحكم عليها</b> (تبقى معلّقة):\n' + unclear.map(p => `• ${String(p.name || 'بلا اسم').replace(/[<>&]/g, '')} ${p.phone ? '+' + p.phone : ''}`).join('\n') + '\nاقبلها أو ارفضها من واتساب إن أردت.').slice(0, 3900) });
const approved = rows.filter(x => x.status === 'approved').length, declined = rows.filter(x => x.status === 'declined').length;
return [{ json: { calls, rows, approved, declined, open } }];
