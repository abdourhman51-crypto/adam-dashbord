// Turns each due post into the Wapito calls it needs, in order (media, voice note, then text).
// On a retry, parts that already went out (recorded in message_id) are not sent again.
const ctl = Object.fromEntries($('Read Control').all().map(i => [i.json.key, i.json.value]));
const out = [];
for (const it of $('Pick Due').all()) {
  const r = it.json;
  if (r._late || r._complete) continue; // already final (missed / sent)
  const sent = new Set(String(r.message_id || '').split(' ').map(s => s.split(':')[0]).filter(Boolean));
  const to = r.target === 'channel' ? ctl.channel_id : ctl.group_id;
  const kind = String(r.kind || 'text');
  const add = (part, path, body) => { if (!sent.has(part)) out.push({ json: { op: 'wapito', method: 'POST', path, body, row_key: r.row_key, part } }); };
  if (kind === 'poll') {
    const options = String(r.poll_options || '').split('|').map(s => s.trim()).filter(Boolean).slice(0, 12);
    add('poll', '/messages/poll', { to, title: String(r.body).slice(0, 255), options, multiple: !!r.multiple });
    continue;
  }
  if (r.media_url) add('media', kind.includes('image') ? '/messages/image' : '/messages/video', { to, media: r.media_url, caption: kind.includes('text') ? undefined : r.body });
  if (kind.includes('voice') && r.voice_url) add('voice', '/messages/voice', { to, media: r.voice_url });
  if (kind.includes('text') || kind === 'text') add('text', '/messages/text', { to, body: r.body, typing_time: 4 });
}
return out;
