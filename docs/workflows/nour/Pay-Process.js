// Founder taps a Telegram button -> confirm page -> (c=1) decide once in Supabase -> deliver via Zernio.
const q = ($input.first().json && $input.first().json.query) || {};
const BASE = 'https://adam-voices-n8n.hawiyat.cloud/webhook/nour-pay';
const PRODUCTS = {
  hodn:  { name: 'من الصرخة إلى الحضن', url: 'https://hodn.adamvoices.site/d/hodn-e0cff222f3d884097ee95095.pdf', tip: 'ابدئي بصفحة «رسالة من آدم». صفحة واحدة كل يوم تكفي.' },
  inad:  { name: 'وراء كلّ لا حكاية', url: 'https://inad.adamvoices.site/d/inad-5e762b509326b44e801b.pdf', tip: 'احفظيه في هاتفكِ، وابدئي بخطوة صغيرة واحدة اليوم.' },
  cards: { name: 'بطاقات مشاعر آدم', url: 'https://aajqbmjasnbwwyvgrlzy.supabase.co/storage/v1/object/public/adam-products/cards/d/adam-emotion-cards-422fb61d0c8f75bed18f.pdf', tip: 'ابدئي ببطاقة واحدة في لحظة هادئة، قبل أن تحتاجيها في لحظة صعبة.' },
};
const esc = s => String(s == null ? '' : s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const page = (title, body, extra) => '<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex"><title>' + esc(title) + '</title><style>body{font-family:system-ui,sans-serif;background:#1c2f24;color:#EFE6CF;display:grid;place-items:center;min-height:100vh;margin:0;padding:24px;text-align:center;line-height:1.8;font-size:18px}h1{font-size:26px;color:#F7EFDD}a.b{display:inline-block;margin-top:18px;padding:13px 30px;border-radius:999px;background:#A5854A;color:#1b140b;font-weight:700;text-decoration:none}</style></head><body><div><h1>' + esc(title) + '</h1><p>' + body + '</p>' + (extra || '') + '</div></body></html>';
const out = (html, extra) => [{ json: { html, ...(extra || {}) } }];
const msg = e => String((e && (e.description || e.message)) || e).slice(0, 300);

const t = String(q.t || '');
const dec = q.d === 'a' ? 'approved' : q.d === 'r' ? 'rejected' : '';
const p = PRODUCTS[q.p] ? q.p : '';
if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(t) || !dec || (dec === 'approved' && !p))
  return out(page('رابط غير صالح', 'افتح الرابط من رسالة تلغرام كما هو.'), { step: 'invalid' });

// Step 1 never changes anything: a link preview or an accidental tap only reaches this page.
if (q.c !== '1') {
  const self = BASE + '?t=' + t + '&d=' + q.d + (p ? '&p=' + p : '') + '&c=1';
  const what = dec === 'approved'
    ? 'إرسال «' + esc(PRODUCTS[p].name) + '» لها الآن وتسجيلها مشترية؟'
    : 'تسجيل هذا الوصل غير صحيح؟ لن يُرسل لها شيء، وتكمل معها أنت.';
  return out(page('تأكيد', what, '<a class="b" href="' + esc(self) + '">نعم، أكّد</a>'), { step: 'confirm' });
}

const tokenHdr = $('Cancel DM Job').params.headerParameters.parameters.find(h => h.name === 'x-noor-token').value;
const RPC = 'https://vpinaehjfflnrlpfxlko.supabase.co/functions/v1/noor-inbox-rpc';
const rpc = (action, payload) => this.helpers.httpRequest({ method: 'POST', url: RPC, headers: { 'Content-Type': 'application/json', 'x-noor-token': tokenHdr }, body: { action, payload }, json: true });
const tgUrl = $('Telegram Alert').params.url;
const tg = text => this.helpers.httpRequest({ method: 'POST', url: tgUrl, body: { chat_id: '7377091520', text, disable_web_page_preview: true }, json: true }).catch(() => null);

let r;
try { r = await rpc('approval_decide', { p_token: t, p_decision: dec, p_product: p || null }); }
catch (e) { return out(page('خطأ مؤقت', 'تعذّر الوصول لقاعدة البيانات. أعد المحاولة بعد دقيقة.'), { step: 'rpc_error', error: msg(e) }); }
if (!r || !r.ok) {
  if (r && r.already) return out(page('سُجّل سابقاً', r.status === 'approved' ? 'تمت الموافقة عليه من قبل (' + esc(r.product) + ')، ولم يُرسل شيء مرة ثانية.' : 'سُجّل غير صحيح من قبل.'), { step: 'already' });
  return out(page('غير موجود', 'لم أجد هذا الطلب.'), { step: 'not_found' });
}
const a = r.approval;
const who = a.contact_name || 'المتابعة';

if (dec === 'rejected') {
  await tg('❌ سُجّل وصل ' + who + ' غير صحيح. كمّل معها يدوياً.');
  return out(page('سُجّل', 'لم يُرسل لها شيء. كمّل معها من Zernio أو التطبيق.'), { step: 'rejected' });
}

const P = PRODUCTS[p];
const zAuth = $('Send DM Reply').params.headerParameters.parameters.find(h => h.name === 'Authorization').value;
const zUrl = 'https://zernio.com/api/v1/inbox/conversations/' + encodeURIComponent(a.external_conversation_id) + '/messages';
const send = body => this.helpers.httpRequest({ method: 'POST', url: zUrl, headers: { Authorization: zAuth, 'Content-Type': 'application/json' }, body, json: true });

// Messenger takes a PDF as a file. Instagram DMs accept only image/video/audio, so it gets the link.
let fileSent = false; const errs = [];
if (a.platform === 'facebook') {
  try { await send({ accountId: a.account_id, attachmentUrl: P.url, attachmentType: 'file' }); fileSent = true; }
  catch (e) { errs.push('file: ' + msg(e)); }
}
const text = 'وصل الدفع، شكراً لثقتكِ 🤍\n' + (fileSent ? 'أرسلت لكِ «' + P.name + '» ملفاً فوق، وهذا رابطه أيضاً:' : 'هذا «' + P.name + '»:') +
  '\n\n👉 ' + P.url + '\n\nإن لم يفتح داخل التطبيق: اضغطي ⋯ ثم «فتح في المتصفح».\n' + P.tip;
let textSent = false;
try { await send({ accountId: a.account_id, message: text }); textSent = true; }
catch (e) { errs.push('text: ' + msg(e)); }

const delivered = fileSent || textSent;
try { await rpc('approval_delivered', { p_token: t, p_error: delivered ? (errs.join(' | ') || null) : (errs.join(' | ') || 'not sent') }); } catch (e) {}

// Keep Nour's own memory in line: she is a customer now, so no follow-up, and Nour knows the file was sent.
try {
  const sd = $getWorkflowStaticData('global');
  const c = sd.convs && sd.convs[a.external_conversation_id];
  if (c && delivered) {
    c.meta = { ...(c.meta || {}), customer: true, stage: 'customer', followedUp: true, lastBotAt: new Date().toISOString() };
    c.history = [...(c.history || []), { role: 'assistant', content: text }].slice(-24);
  }
} catch (e) {}

await tg(delivered
  ? '✅ أُرسل «' + P.name + '» إلى ' + who + ' (' + a.platform + (fileSent ? '، ملف + رابط' : '، رابط') + ').' + (errs.length ? '\n⚠️ ' + errs.join(' | ') : '')
  : '⚠️ لم يصل «' + P.name + '» إلى ' + who + '. أرسله يدوياً.\n' + errs.join(' | '));
return out(delivered
  ? page('تم 🤍', 'أُرسل «' + esc(P.name) + '» إلى ' + esc(who) + (fileSent ? ' (ملف + رابط).' : ' (رابط).'))
  : page('لم يُرسل', 'سُجّلت الموافقة لكن الإرسال فشل. أرسل الملف يدوياً.<br><small>' + esc(errs.join(' | ')) + '</small>'),
  { step: delivered ? 'delivered' : 'send_failed', errs });
