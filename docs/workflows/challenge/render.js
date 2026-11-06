// Review page: the whole week on one screen. Edit any text/time, skip a post, approve all at once.
const q = $('Review GET').first().json.query || {};
const ctl = Object.fromEntries($('Read Control').all().map(i => [i.json.key, i.json.value]));
const esc = s => String(s ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const page = (body) => `<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>مراجعة التحدّي</title>
<style>:root{--bg:#faf7f2;--card:#fff;--ink:#2b2420;--mut:#8a7f76;--gold:#b08a4a;--ok:#3c7a4f;--warn:#b5562f;--line:#eadfce}
@media(prefers-color-scheme:dark){:root{--bg:#171412;--card:#211d1a;--ink:#f1e9df;--mut:#a59a90;--line:#3a322b}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:16px/1.7 system-ui,"Segoe UI",Tahoma,sans-serif;padding:16px}
h1{font-size:20px;margin:4px 0 2px}.sub{color:var(--mut);font-size:13px;margin-bottom:14px}
.card{background:var(--card);border:1px solid var(--line);border-radius:14px;padding:12px 14px;margin:0 0 12px}
.meta{display:flex;flex-wrap:wrap;gap:6px;align-items:center;font-size:13px;color:var(--mut);margin-bottom:6px}
.pill{border:1px solid var(--line);border-radius:999px;padding:1px 9px}.sent{color:var(--ok);border-color:var(--ok)}.miss{color:var(--warn);border-color:var(--warn)}
textarea{width:100%;min-height:140px;border:1px solid var(--line);border-radius:10px;padding:10px;font:inherit;background:transparent;color:inherit;resize:vertical}
input[type=text]{border:1px solid var(--line);border-radius:8px;padding:4px 8px;font:inherit;background:transparent;color:inherit;width:170px;direction:ltr}
audio{width:100%;margin-top:6px}label{font-size:14px}.bar{position:sticky;bottom:0;background:var(--bg);padding:12px 0;display:flex;gap:10px;flex-wrap:wrap}
button{border:0;border-radius:12px;padding:12px 18px;font:inherit;font-weight:600;cursor:pointer}.save{background:var(--line);color:var(--ink)}.go{background:var(--gold);color:#fff;flex:1}</style></head><body>${body}</body></html>`;
if (!q.t || q.t !== ctl.review_token) return [{ json: { html: page('<h1>رابط غير صالح</h1>'), code: 403 } }];
const week = q.w || ctl.active_week;
const toDz = iso => { const d = new Date(new Date(iso).getTime() + 3600e3); return d.toISOString().slice(0, 16).replace('T', ' '); };
const SL = { morning: 'صباحاً', evening: 'مساءً', extra: 'إضافي' };
const rows = $('Read Plan').all().map(i => i.json).filter(r => r.week === week).sort((a, b) => new Date(a.post_at) - new Date(b.post_at));
const cards = rows.map(r => {
  const sent = r.status === 'sent';
  const needVoice = String(r.kind).includes('voice') && !r.voice_url;
  return `<div class="card"><div class="meta"><span class="pill">${r.target === 'channel' ? 'القناة' : 'المجموعة'}</span><span class="pill">اليوم ${r.day} · ${SL[r.slot] || r.slot}</span><span class="pill">${esc(r.kind)}</span>
<span class="pill ${sent ? 'sent' : ''}">${sent ? 'نُشر' : r.status === 'approved' ? 'موافق' : r.status === 'skipped' ? 'ملغى' : 'مسودة'}</span>${needVoice ? '<span class="pill miss">الصوت لم يُولَّد بعد</span>' : ''}</div>
${sent ? `<div style="white-space:pre-wrap">${esc(r.body)}</div>` : `<textarea name="body_${esc(r.row_key)}">${esc(r.body)}</textarea>
<div class="meta" style="margin-top:6px"><label>الوقت (بتوقيت الجزائر): <input type="text" name="time_${esc(r.row_key)}" value="${toDz(r.post_at)}"></label>
<label><input type="checkbox" name="skip_${esc(r.row_key)}" ${r.status === 'skipped' ? 'checked' : ''}> لا تنشره</label></div>
${r.poll_options ? `<div class="meta">خيارات التصويت (افصلها بـ |):</div><textarea style="min-height:60px" name="poll_${esc(r.row_key)}">${esc(r.poll_options)}</textarea>` : ''}`}
${r.voice_url ? `<audio controls preload="none" src="${esc(r.voice_url)}"></audio>` : ''}</div>`;
}).join('');
const html = page(`<h1>تحدّي الأسبوع · ${esc(week)}</h1><div class="sub">${rows.length} منشوراً. يمكن تعديل أي نص أو وقت، أو إلغاء منشور، ثم الضغط على «موافقة ونشر». الحفظ دون موافقة ممكن أيضاً.</div>
<form method="post" action="https://adam-voices-n8n.hawiyat.cloud/webhook/adam-review-save"><input type="hidden" name="t" value="${esc(q.t)}"><input type="hidden" name="w" value="${esc(week)}">${cards}
<div class="bar"><button class="save" name="action" value="save">حفظ التعديلات فقط</button><button class="go" name="action" value="approve">موافقة ونشر الأسبوع كاملاً ✅</button></div></form>`);
return [{ json: { html, code: 200 } }];
