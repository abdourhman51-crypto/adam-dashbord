// Saves the review form: new texts/times, skipped posts, and approval. Rows already sent are never touched.
const f = $('Review POST').first().json.body || {};
const ctl = Object.fromEntries($('Read Control').all().map(i => [i.json.key, i.json.value]));
if (!f.t || f.t !== ctl.review_token) return [{ json: { _deny: true, row_key: '__none__' } }];
const approve = f.action === 'approve';
const week = f.w || ctl.active_week;
const fromDz = (s, fallback) => { const m = /^(\d{4}-\d{2}-\d{2})[ T](\d{2}):(\d{2})$/.exec(String(s || '').trim()); if (!m) return fallback; return new Date(Date.parse(`${m[1]}T${m[2]}:${m[3]}:00Z`) - 3600e3).toISOString(); };
const out = [];
for (const r of $('Read Plan').all().map(i => i.json).filter(r => r.week === week)) {
  if (r.status === 'sent') continue;
  const k = r.row_key;
  const body = typeof f['body_' + k] === 'string' ? f['body_' + k].replace(/\r\n/g, '\n').trim() : r.body;
  const skip = f['skip_' + k] === 'on';
  out.push({ json: {
    row_key: k, body,
    post_at: fromDz(f['time_' + k], new Date(r.post_at).toISOString()),
    poll_options: typeof f['poll_' + k] === 'string' ? f['poll_' + k].trim() : (r.poll_options || ''),
    status: skip ? 'skipped' : (approve ? 'approved' : (r.status === 'approved' ? 'approved' : 'draft')),
  } });
}
return out.length ? out : [{ json: { row_key: '__none__', _empty: true } }];
