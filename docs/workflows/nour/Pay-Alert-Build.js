// Payment receipt -> Telegram alert with one-tap approval buttons (URL buttons open the n8n confirm page).
const d = $('Parse & Remember').first().json;
const r = $input.first().json || {};
const tok = /^[0-9a-f-]{36}$/i.test(String(r.token || '')) ? r.token : '';
const BASE = 'https://adam-voices-n8n.hawiyat.cloud/webhook/nour-pay';
let sug = '';
try { const p = $('Takeover: Human Active?').first().json.profile; const o = (p && p.products_offered) || []; sug = o.length ? o[o.length - 1] : ''; } catch (e) {}
if (!sug) sug = (d.insight && d.insight.product_offered) || '';
const P = [['hodn', 'الحضن 9$'], ['inad', 'العناد 12$'], ['cards', 'البطاقات 7$']];
const u = (dec, p) => BASE + '?t=' + tok + '&d=' + dec + (p ? '&p=' + p : '');
const kb = tok ? { inline_keyboard: [P.map(([k, l]) => ({ text: (k === sug ? '⭐ ' : '✅ ') + l, url: u('a', k) })), [{ text: '❌ الوصل غير صحيح', url: u('r') }]] } : null;
const text = String(d.alertText || '') + (tok
  ? '\n\nاضغط المنتج الذي دفعت ثمنه ليصلها تلقائياً، أو ❌ إن لم يكن الوصل صحيحاً.' + (sug && P.some(x => x[0] === sug) ? '\n⭐ = آخر منتج عُرض عليها.' : '')
  : '\n\n(تعذّر تجهيز أزرار الموافقة، أرسل الملف يدوياً.)');
const tg = { chat_id: '7377091520', text: text.slice(0, 4000), disable_web_page_preview: true };
if (kb) tg.reply_markup = kb;
return [{ json: { tg } }];
