// WhatsApp connection check. Alerts at most once every 2 hours while it stays down, and once when it comes back.
const r = $input.first().json || {};
const st = (r.body && r.body.status) || '';
const up = r.ok && st === 'connected';
const s = $getWorkflowStaticData('global');
const now = Date.now();
const out = [];
if (!up) {
  if (!s.downSince) s.downSince = now;
  if (!s.lastAlert || now - s.lastAlert > 2 * 3600e3) {
    s.lastAlert = now;
    const why = { qr: 'يحتاج مسح رمز QR من جديد', pairing: 'في انتظار الربط', disconnected: 'انقطع الاتصال', logged_out: 'خرج الرقم من وابيتو', banned: 'الرقم محظور من واتساب' }[st] || (r.error_code || ('HTTP ' + r.status));
    out.push({ json: { op: 'telegram', text: `🔴 <b>واتساب نور لا يعمل</b>\n${why}\nالنشر والردود متوقفة حتى يعود. افتح لوحة وابيتو.` } });
  }
} else if (s.downSince) {
  const mins = Math.round((now - s.downSince) / 60e3);
  s.downSince = null; s.lastAlert = null;
  out.push({ json: { op: 'telegram', text: `🟢 عاد واتساب نور للعمل بعد ${mins} دقيقة.` } });
}
return out;
