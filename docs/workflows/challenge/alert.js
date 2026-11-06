// One Telegram line per post that did not go out: first failure (retry in 10 min) or final failure.
const bad = $('Collect').all().map(i => i.json).filter(x => x.alert);
const late = $('Pick Due').all().map(i => i.json).filter(r => r._late);
if (!bad.length && !late.length) return [];
const esc = s => String(s).replace(/[<>&]/g, '');
const lines = bad.map(b => `• ${b.row_key}: ${b.final ? 'فشل نهائياً' : 'فشل، سأعيد المحاولة بعد 10 دقائق'} — ${esc(b.error)}`)
  .concat(late.map(r => `• ${r.row_key}: لم يُنشر لأنه تأخر أكثر من 3 ساعات`));
return [{ json: { op: 'telegram', text: ('⚠️ <b>منشور لم يُنشر</b>\n' + lines.join('\n') + '\n\nالباقي مستمر كما هو.').slice(0, 3900) } }];
