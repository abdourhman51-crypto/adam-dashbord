// One summary after saving: page for the founder + Telegram note when the week is approved.
const f = $('Review POST').first().json.body || {};
const rows = $('Save Diff').all().map(i => i.json);
if (rows[0] && rows[0]._deny) return [{ json: { html: '<h1 dir="rtl">رابط غير صالح</h1>', code: 403, op: 'none' } }];
const n = rows.filter(r => r.status === 'approved').length, s = rows.filter(r => r.status === 'skipped').length;
const approve = f.action === 'approve';
const msg = approve ? `✅ تمت الموافقة على تحدّي الأسبوع: ${n} منشوراً سيُنشر في وقته${s ? `، و${s} ملغى` : ''}.` : `💾 حُفظت التعديلات (${rows.length} منشوراً). لم تتم الموافقة بعد.`;
const html = `<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><style>body{font:18px/1.8 system-ui,Tahoma,sans-serif;background:#faf7f2;color:#2b2420;padding:24px}@media(prefers-color-scheme:dark){body{background:#171412;color:#f1e9df}}</style></head><body><h2>${msg}</h2><p><a href="javascript:history.back()">رجوع</a></p></body></html>`;
return [{ json: { html, code: 200, op: approve ? 'telegram' : 'none', text: msg } }];
