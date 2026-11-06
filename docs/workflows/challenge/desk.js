// Card desk in DM: «بطاقتي» + her name + her child's name -> check she finished (6+ nights) -> make the card -> send it with the gift.
// Missing names are asked for: both at once («فاطمة - مالك»), or the child's name alone when only hers came.
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
const ASK_BOTH = 'اكتبي اسمكِ واسم صغيركِ كما تريدينهما على البطاقة، هكذا:\nفاطمة - مالك';
const tidy = s => String(s || '').replace(/https?:\/\/\S+/g, '').replace(/[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}\u{200D}]/gu, '').replace(/[«»"*_~]/g, '').replace(/\s+/g, ' ').trim();
const MOM = /^(?:اسمي|إسمي|انا|أنا|الأم|الام)\s*[:：]?\s*/;
const KIDW = '(?:ابني|ابنتي|إبني|إبنتي|بنتي|ولدي|طفلي|طفلتي|صغيري|صغيرتي|الطفل|الطفلة|اسمه|اسمها|إسمه|إسمها)';
const KID = new RegExp('^(?:و\\s*)?(?:اسم\\s*)?' + KIDW + '\\s*[:：]?\\s*');
const okName = s => !!s && s.length <= 30 && s.split(' ').length <= 5 && !/\d{3,}/.test(s);
// «بطاقتي فاطمة - مالك» / «فاطمة، مالك» / «اسمي فاطمة واسم ابني مالك» -> { mom, kid }
function parse(raw) {
  const s = tidy(raw).replace(/^بطاق(?:تي|تى|ة)\s*[:：،,\-–]?\s*/, '');
  if (!s) return { mom: '', kid: '' };
  // «فاطمة ومالك»: و may start a name (وفاء، وليد), so do not guess; ask for the dash form
  if (/^[^\s\-–—|\/،,؛;+]+ و[^\s]+$/.test(s) && !/^(أم|ام)\s/.test(s)) return { mom: '', kid: '', unsure: true };
  const m = s.match(new RegExp('^(.*?)\\s+و\\s*(?:اسم\\s*)?' + KIDW + '\\s*[:：]?\\s*(.+)$'));
  const parts = m ? [m[1], m[2]] : s.split(/\s*(?:[\-–—|\/\n،,؛;+]|\s&\s)\s*/).map(x => x.trim()).filter(Boolean);
  const mom = String(parts[0] || '').replace(MOM, '').trim();
  const kids = parts.slice(1).map(x => x.replace(KID, '').trim()).filter(Boolean);
  return { mom, kid: kids.join(' و') };
}
const keyOf = wk => `${wk}-${m.chat_id.replace(/[^0-9]/g, '').slice(-12)}`;
const makeCard = (wk, nights, mom, kid) => {
  out.card = { name: mom, child: kid, key: keyOf(wk) };
  out.cardRow = { chat_id: m.chat_id, phone, week: wk, name: mom, child: kid, nights };
};
const stateRow = (wk, state, name, nights) => ({ chat_id: m.chat_id, phone, week: wk, state, name, child: '', nights, updated: now });
// what she wrote -> card now, or ask what is missing
function take(p, wk, nights) {
  if (okName(p.mom) && okName(p.kid)) return makeCard(wk, nights, p.mom, p.kid);
  if (okName(p.mom) && !p.kid) {
    out.calls.push(say(`جميل 🤍 واسم صغيركِ؟ اكتبيه كما تريدينه على البطاقة.`));
    out.save = stateRow(wk, 'awaiting_child', p.mom, nights);
    return;
  }
  out.calls.push(say(p.unsure ? 'حتى لا أخطئ في الاسمين 🤍 ' + ASK_BOTH : p.mom || p.kid ? 'الاسمان طويلان قليلاً 🤍 ' + ASK_BOTH : ASK_BOTH));
  out.save = stateRow(wk, 'awaiting_name', '', nights);
}

if (req && req.state === 'awaiting_child' && !wantsCard) {
  const p = parse(text);
  if (p.kid) take(p, req.week, req.nights);
  else if (/^(لا|بدون|بلا|لا شيء|لاشيء|ما نحبش|مانحبش|لا أريد|لا اريد)(?:\s|$)/.test(tidy(text))) makeCard(req.week, req.nights, req.name, '');
  else {
    const kid = tidy(text).replace(KID, '').trim();
    if (okName(kid)) makeCard(req.week, req.nights, req.name, kid);
    else out.calls.push(say('اكتبي اسم صغيركِ فقط، في كلمة أو كلمتين 🤍'));
  }
} else if (req && req.state === 'awaiting_name' && !wantsCard) {
  take(parse(text), req.week, req.nights);
} else if (wantsCard) {
  const p = parse(text);
  if (!finished) {
    const ended = Date.now() > Date.parse((ctl.challenge_end || '2000-01-01') + 'T23:59:00Z');
    out.calls.push(say(ended
      ? `سجّلنا لكِ ${nightsNow} ${nightsNow === 1 ? 'ليلة' : 'ليالٍ'} هذا الأسبوع 🤍 البطاقة لمن أكملت 6 ليالٍ على الأقل. التحدّي القادم فرصة جديدة، وأنتِ معنا.`
      : `ما زال التحدّي مستمراً 🌙 سجّلنا لكِ حتى الآن ${nightsNow} ${nightsNow === 1 ? 'ليلة' : 'ليالٍ'}. أكملي، والبطاقة لمن تصل إلى 6 ليالٍ أو أكثر.`));
  } else if (req && req.state === 'done' && req.week === finished && !p.mom && !p.unsure) {
    out.calls.push(say('بطاقتكِ وصلتكِ أعلاه 🤍 وإن أردتِ تغيير الاسمين، اكتبي مثلاً:\nبطاقتي فاطمة - مالك'));
  } else if (!p.mom && !p.unsure) {
    out.calls.push(say('مبروك! 🏅 أكملتِ التحدّي، وبطاقتكِ جاهزة للكتابة.\n' + ASK_BOTH));
    out.save = stateRow(finished, 'awaiting_name', '', byWeek[finished].size);
  } else {
    take(p, finished, byWeek[finished].size);
  }
} else if (wantsBook && req && req.state === 'done' && Date.now() - new Date(req.updated).getTime() < 48 * 3600e3) {
  out.calls.push(say('تمام 🤍 سيتواصل معكِ فريق آدم هنا لإتمام الطلب بالسعر الخاص.'));
  out.calls.push({ op: 'telegram', text: `🛒 <b>طلب الكتاب بالسعر الخاص</b>\n${String(req.name || '').replace(/[<>&]/g, '')} ${phone ? '+' + phone : m.chat_id}\nالسعر: ${price} (48 ساعة بعد البطاقة)\nردّ عليها من واتساب نور.` });
}
return [{ json: { ...out, chat_id: m.chat_id, phone, price } }];
