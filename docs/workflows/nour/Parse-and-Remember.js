// ===== توليد الصوت بنماذج ElevenLabs عبر OpenRouter =====
const OPENROUTER_KEY = '__OPENROUTER_KEY__';

const d = $('Build DM Prompt').first().json;
const res = $input.first().json;
let out = {};
try {
  const txt = res.choices?.[0]?.message?.content ?? '';
  out = JSON.parse(txt.slice(txt.indexOf('{'), txt.lastIndexOf('}') + 1));
} catch (e) {
  out = { reply: 'وصلتني رسالتك 🤍 نرجعلك بعد لحظات.', stage: '', escalate: true, escalate_reason: 'تعذّر فهم رد الذكاء الاصطناعي' };
}
let reply = String(out.reply ?? '').trim().slice(0, 990);
const sd = $getWorkflowStaticData('global');
sd.convs = sd.convs ?? {};
const conv = sd.convs[d.conversationId] ?? { history: [], meta: {} };

const lastBotMsg = [...(conv.history || [])].reverse().find(m => m.role === 'assistant')?.content || '';
if (reply === '🤍' && lastBotMsg.trim() === '🤍') {
  reply = '';
}

// A URL inside an Arabic (RTL) sentence renders scrambled and gets lost; give each URL its own line.
reply = reply
  .replace(/\[([^\]]*)\]\((https?:\/\/[^)\s]+)\)/g, '$1 $2')
  .replace(/[ \t]*(?:👉[ \t]*)?(https?:\/\/[^\s«»"'<>()،؛]+)[ \t]*/gu, (m, u) => '\n👉 ' + u.replace(/[.,!?؟:]+$/, '') + '\n')
  .replace(/[ \t]+\n/g, '\n')
  .replace(/\n{3,}/g, '\n\n')
  .trim();

// Tag our own links with the conversation, so the site visit joins this follower (?src=dm_<code>).
const convCode = String(d.internalConversationId || '').replace(/-/g, '').slice(0, 10);
if (/^[0-9a-f]{10}$/.test(convCode)) {
  reply = reply.replace(/https?:\/\/(?:[a-z0-9-]+\.)*adamvoices\.site[^\s«»"'<>()،؛]*/gi, u => {
    if (/[?&]src=/.test(u)) return u;
    const [base, hash] = u.split('#');
    return base + (base.includes('?') ? '&' : '?') + 'src=dm_' + convCode + (hash ? '#' + hash : '');
  });
}

conv.history.push({ role: 'user', content: d.userText + (d.images.length ? ' [+صورة]' : '') });
if (reply) conv.history.push({ role: 'assistant', content: reply });
conv.history = conv.history.slice(-24);
const nowIso = new Date().toISOString();
conv.meta = {
  ...conv.meta,
  accountId: d.accountId, platform: d.platform, name: d.senderName,
  stage: out.stage || conv.meta.stage || '',
  country: out.country || conv.meta.country || '',
  customer: conv.meta.customer || out.stage === 'customer' || !!out.payment_proof,
  escalated: !!out.escalate || conv.meta.escalated || false,
  lastUserAt: nowIso, lastBotAt: reply ? nowIso : conv.meta.lastBotAt,
  followedUp: false
};
sd.convs[d.conversationId] = conv;
const keys = Object.keys(sd.convs);
if (keys.length > 3000) { keys.sort((a, b) => (sd.convs[a].meta.lastUserAt || '').localeCompare(sd.convs[b].meta.lastUserAt || '')); keys.slice(0, keys.length - 3000).forEach(k => delete sd.convs[k]); }

const sendBody = { accountId: d.accountId, message: reply };

// تجهيز الرد الصوتي: بدون روابط ولا إيموجي، والروابط تُرسل بعده نصاً
const links = reply.match(/https?:\/\/\S+/g) || [];
const ttsText = reply.replace(/https?:\/\/\S+/g, '').replace(/[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}\u{200D}👉]/gu, '').replace(/\s*\n+\s*/g, '، ').replace(/\s{2,}/g, ' ').replace(/^[،\s]+|[،\s]+$/g, '').slice(0, 700);
const voiceOut = !!OPENROUTER_KEY && !!d.voiceIn && !!reply && reply !== '🤍' && ttsText.length > 3;

const pr = (out.profile && typeof out.profile === 'object') ? out.profile : {};
const linkProduct = /inad\.adamvoices\.site/.test(reply) ? 'inad' : /hodn\.adamvoices\.site/.test(reply) ? 'hodn' : /adamvoices\.site\/cards/.test(reply) ? 'cards' : /adamvoices\.site\/21/.test(reply) ? '21' : '';
const insight = {
  user_text: d.userText || '', reply_text: reply, stage: out.stage || '', gender: out.gender || '', country: out.country || '',
  buying_signal: !!out.buying_signal, payment_proof: !!out.payment_proof, escalate: !!out.escalate, escalate_reason: out.escalate_reason || '',
  analysis: out.analysis || '', problem: String(pr.problem || ''), topics: Array.isArray(pr.topics) ? pr.topics.map(String).slice(0, 6) : [],
  objection: String(pr.objection || ''), product_offered: linkProduct || String(pr.product_offered || ''), summary: String(pr.summary || ''),
  child: (pr.child_name || pr.child_age) ? { name: pr.child_name ? String(pr.child_name) : null, age: pr.child_age ? String(pr.child_age) : null } : null
};

const flag = out.payment_proof ? '💰 وصل دفع' : (out.escalate ? '⚠️ تحتاج تدخّلك' : '');
return [{ json: {
  jobId: d.jobId, internalConversationId: d.internalConversationId, insight, conversationId: d.conversationId, accountId: d.accountId, platform: d.platform,
  reply,
  sendBody,
  voiceOut, ttsText, orKey: OPENROUTER_KEY, elevenKey: OPENROUTER_KEY, hasLink: links.length > 0,
  linkBody: { accountId: d.accountId, message: links.join('\n') },
  stage: out.stage ?? '', escalate: !!out.escalate || !!out.payment_proof,
  alertText: flag + ' (' + d.platform + ')' + (d.voiceIn ? ' 🎙' : '') + '\n👤 ' + (d.senderName || '?') + (d.senderUsername ? ' @' + d.senderUsername : '') +
    (out.country ? '\n🌍 ' + out.country : '') +
    '\n📝 السبب: ' + (out.escalate_reason || (out.payment_proof ? 'أرسلت ما يبدو وصل دفع' : '')) +
    '\n💬 رسالتها: ' + (d.userText || '').slice(0, 600) +
    (d.images.length ? '\n🖼 الصور: ' + d.images.join(' ') : '') +
    (d.voiceIn && d.audios && d.audios[0] ? '\n🎙 الصوت: ' + d.audios[0] : '') +
    '\n🤖 ردّ نور: ' + reply.slice(0, 600) +
    '\n\nافتح المحادثة في Zernio أو إنستغرام وكمّل.'
} }];
