// Card desk in DM: «بطاقتي» -> check she finished (6+ nights) -> ask the name -> make the card -> send it with the gift.
// Also: «أريد الكتاب» within 48h of the card -> tell the founder (until Nour answers WhatsApp DMs herself).
const m = $('Called').first().json;
const ctl = Object.fromEntries($('Read Control').all().map(i => [i.json.key, i.json.value]));
const chk = $('Read Checkins').all().map(i => i.json).filter(c => c.participant);
const req = $('Read Requests').all().map(i => i.json).find(r => r.chat_id === m.chat_id) || null;
const text = String(m.text || '').trim();
const ids = new Set([m.chat_id, m.from_lid, m.from ? m.from + '@s.whatsapp.net' : ''].filter(Boolean));
const byWeek = {};
for (const c of chk) if (ids.has(c.participant)) (byWeek[c.week] = byWeek[c.week] || new Set()).add(Number(c.night));
const weeks = Object.keys(byWeek).sort();
const finished = weeks.filter(w => byWeek[w].size >= 6).pop() || null;
const nightsNow = (byWeek[ctl.active_week] || new Set()).size;
const phone = String(m.from || '').replace(/\D/g, '');
const price = phone.startsWith('213') ? '900 دج' : phone.startsWith('20') ? '3$' : '4$';
const say = (body, extra = {}) => ({ op: 'wapito', method: 'POST', path: '/messages/text', body: { to: m.chat_id, body, typing_time: 4, ...extra } });
const out = { calls: [], save: null };
const now = new Date().toISOString();
const wantsCard = /بطاق(تي|تى|ة)/.test(text);
const wantsBook = /(أريد|اريد|ابغى|نحب|بغيت|عايزة|بدي)\s*(ال)?كتاب|الكتاب كامل/.test(text);

if (req && req.state === 'awaiting_name' && !wantsCard) {
  const name = text.replace(/https?:\/\/\S+/g, '').replace(/[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]/gu, '').replace(/\s+/g, ' ').trim();
  if (!name || name.length > 36 || name.split(' ').length > 5) {
    out.calls.push(say('اكتبي الاسم فقط كما تريدينه على البطاقة، في كلمات قليلة 🤍'));
  } else {
    out.card = { name, key: `${req.week}-${m.chat_id.replace(/[^0-9]/g, '').slice(-12)}` };
    out.cardRow = { chat_id: m.chat_id, phone, week: req.week, name, nights: req.nights };
  }
} else if (wantsCard) {
  if (req && req.state === 'done' && req.week === finished) {
    out.calls.push(say('بطاقتكِ وصلتكِ أعلاه 🤍 وإن أردتِ تغيير الاسم، اكتبي «بطاقتي» ثم الاسم الجديد.'));
    out.save = { chat_id: m.chat_id, phone, week: finished, state: 'awaiting_name', name: req.name, nights: req.nights, updated: now };
  } else if (finished) {
    out.calls.push(say('مبروك! 🏅 أكملتِ التحدّي، وبطاقتكِ جاهزة للكتابة.\nبأي اسم نكتبها؟ اكتبي الاسم كما تريدينه أن يظهر (مثلاً: «أم يوسف» أو اسمكِ).'));
    out.save = { chat_id: m.chat_id, phone, week: finished, state: 'awaiting_name', name: '', nights: byWeek[finished].size, updated: now };
  } else {
    const ended = Date.now() > Date.parse((ctl.challenge_end || '2000-01-01') + 'T23:59:00Z');
    out.calls.push(say(ended
      ? `سجّلنا لكِ ${nightsNow} ${nightsNow === 1 ? 'ليلة' : 'ليالٍ'} هذا الأسبوع 🤍 البطاقة لمن أكملت 6 ليالٍ على الأقل. التحدّي القادم فرصة جديدة، وأنتِ معنا.`
      : `ما زال التحدّي مستمراً 🌙 سجّلنا لكِ حتى الآن ${nightsNow} ${nightsNow === 1 ? 'ليلة' : 'ليالٍ'}. أكملي، والبطاقة لمن تصل إلى 6 ليالٍ أو أكثر.`));
  }
} else if (wantsBook && req && req.state === 'done' && Date.now() - new Date(req.updated).getTime() < 48 * 3600e3) {
  out.calls.push(say('تمام 🤍 سيتواصل معكِ فريق آدم هنا لإتمام الطلب بالسعر الخاص.'));
  out.calls.push({ op: 'telegram', text: `🛒 <b>طلب الكتاب بالسعر الخاص</b>\n${String(req.name || '').replace(/[<>&]/g, '')} ${phone ? '+' + phone : m.chat_id}\nالسعر: ${price} (48 ساعة بعد البطاقة)\nردّ عليها من واتساب نور.` });
}
return [{ json: { ...out, chat_id: m.chat_id, phone, price } }];
