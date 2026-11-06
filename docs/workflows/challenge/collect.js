// Matches every Wapito answer to its post and decides the post's final state.
const picked = Object.fromEntries($('Pick Due').all().map(i => [i.json.row_key, i.json]));
const calls = $('Build Calls').all().map(i => i.json);
const res = $input.all().map(i => i.json);
const by = {};
for (const k of Object.keys(picked)) if (!picked[k]._late && !picked[k]._complete) by[k] = { row_key: k, ok: true, ids: String(picked[k].message_id || '').split(' ').filter(Boolean), errs: [] };
calls.forEach((c, i) => {
  if (c.op !== 'wapito' || !by[c.row_key]) return;
  const r = res[i] || {};
  const x = by[c.row_key];
  if (r.ok) x.ids.push(c.part + ':' + ((r.body && r.body.id) || ''));
  else { x.ok = false; x.errs.push(`${c.part}:${r.error_code || r.status}${r.error_message ? ' ' + r.error_message : ''}`); }
});
return Object.values(by).map(x => {
  const retry = !!picked[x.row_key]._retry;
  return { json: {
    row_key: x.row_key,
    status: x.ok ? 'sent' : 'failed',
    message_id: [...new Set(x.ids)].join(' ').slice(0, 900),
    error: x.ok ? '' : (x.errs.join(' | ').slice(0, 850) + (retry ? ' [retry]' : '')),
    sent_at: new Date().toISOString(),
    alert: !x.ok, final: !x.ok && retry,
  } };
});
