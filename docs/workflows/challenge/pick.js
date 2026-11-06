// Picks posts to send now: approved and due, or failed once (one automatic retry after 10 min), or stuck in 'sending'.
// Each post gets a fixed small jitter (-7..+8 min) so times never look robotic.
const ctl = Object.fromEntries($('Read Control').all().map(i => [i.json.key, i.json.value]));
if (String(ctl.paused) === 'true') return [];
const now = Date.now();
const jitter = k => { let h = 0; for (const c of String(k)) h = (h * 31 + c.charCodeAt(0)) >>> 0; return ((h % 16) - 7) * 60e3; };
// Parts a post needs; a retried post whose parts all went out already is simply marked sent.
const parts = r => { const k = String(r.kind || 'text'); if (k === 'poll') return ['poll']; const p = []; if (r.media_url) p.push('media'); if (k.includes('voice') && r.voice_url) p.push('voice'); if (k.includes('text')) p.push('text'); return p; };
const complete = r => { const s = new Set(String(r.message_id || '').split(' ').map(x => x.split(':')[0])); return parts(r).every(x => s.has(x)); };
const due = [];
for (const r of $('Read Plan').all().map(i => i.json)) {
  if (!r.post_at || !r.row_key) continue;
  const at = new Date(r.post_at).getTime() + jitter(r.row_key);
  if (at > now) continue;
  const late = now - at > 3 * 3600e3; // more than 3h late: a stale message is never posted
  const touched = new Date(r.updatedAt || r.sent_at || 0).getTime();
  if (r.status === 'approved') due.push({ json: { ...r, _late: late, _retry: false } });
  else if (r.status === 'failed' && !String(r.error || '').includes('[retry]') && now - touched > 10 * 60e3) due.push({ json: { ...r, _late: late, _retry: true, _complete: complete(r) } });
  else if (r.status === 'sending' && now - touched > 20 * 60e3) due.push({ json: { ...r, _late: late, _retry: true, _complete: complete(r) } });
}
due.sort((a, b) => new Date(a.json.post_at) - new Date(b.json.post_at));
return due.slice(0, 2);
