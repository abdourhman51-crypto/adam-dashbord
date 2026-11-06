// Makes the card image and sends it with the gift: the free first chapter, and the 48-hour price.
const d = $('Decide').first().json;
if (!d.card) return [];
let r;
try { r = await this.helpers.httpRequest({ method: 'POST', url: 'https://vpinaehjfflnrlpfxlko.supabase.co/functions/v1/adam-card', body: { name: d.card.name, key: d.card.key, date: new Date().toLocaleDateString('ar', { month: 'long', year: 'numeric' }) }, json: true, timeout: 90000, ignoreHttpStatusErrors: true }); } catch (e) { r = { ok: false, reason: String(e.message || e) }; }
if (!r || !r.ok) return [{ json: { op: 'telegram', text: '⚠️ لم أستطع صنع بطاقة لـ ' + String(d.card.name).replace(/[<>&]/g, '') + ': ' + String(r && r.reason || '') } }, { json: { op: 'wapito', method: 'POST', path: '/messages/text', body: { to: d.chat_id, body: 'لحظات… أجهّز بطاقتكِ، وستصلكِ قريباً 🤍' } } }];
const caption = `🏅 ${d.card.name}، هذه بطاقتكِ «أمٌّ تعود».\nسبع ليالٍ من الحب قبل النوم… هذا شيء يبقى في ذاكرة طفلكِ.\n\n🎁 هديتكِ من آدم: الفصل الأول من «من الصرخة إلى الحضن» مجاناً (في الرسالة التالية).\n\nولأنكِ أكملتِ التحدّي: الكتاب كاملاً بسعر خاص ${d.price} لمدة 48 ساعة فقط.\nإن أردتِه، اكتبي هنا: «أريد الكتاب».`;
return [
  { json: { op: 'wapito', method: 'POST', path: '/messages/image', body: { to: d.chat_id, media: r.public_url, caption }, _card_url: r.public_url } },
  { json: { op: 'wapito', method: 'POST', path: '/messages/document', body: { to: d.chat_id, media: { url: 'https://vpinaehjfflnrlpfxlko.supabase.co/storage/v1/object/public/adam-media/docs/hodn-sample.pdf', filename: 'الفصل-الأول-من-الصرخة-إلى-الحضن.pdf' }, caption: 'الفصل الأول، هديتكِ 🤍' } } },
];
