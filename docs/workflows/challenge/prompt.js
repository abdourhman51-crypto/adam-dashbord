// Builds one cheap AI call for all new group messages since the last run.
const ctl = Object.fromEntries($('Read Control').all().map(i => [i.json.key, i.json.value]));
if (String(ctl.paused) === 'true' || String(ctl.brain_on) !== 'true') return [];
const inbox = $('Read Inbox').all().map(i => i.json).filter(r => r.msg_id && !r.processed).sort((a, b) => new Date(a.at) - new Date(b.at)).slice(-60);
if (!inbox.length) return [];
const today = new Date(Date.now() + 3600e3).toISOString().slice(0, 10);
const acts = $('Read Actions').all().map(i => i.json).filter(a => a.at && new Date(new Date(a.at).getTime() + 3600e3).toISOString().slice(0, 10) === today);
const cap = Number(ctl.reply_cap_day) || 10;
const used = acts.filter(a => a.kind === 'reply' || a.kind === 'dm').length;
const left = Math.max(0, cap - used);
const postedToday = acts.some(a => a.kind === 'post');
const dmToday = [...new Set(acts.filter(a => a.kind === 'dm').map(a => a.target))];
const plan = $('Read Plan').all().map(i => i.json).filter(r => r.week === ctl.active_week);
const now = Date.now();
const recent = plan.filter(r => r.status === 'sent').sort((a, b) => new Date(b.sent_at) - new Date(a.sent_at)).slice(0, 2).map(r => r.body);
const next = plan.filter(r => r.status === 'approved' && new Date(r.post_at).getTime() > now).sort((a, b) => new Date(a.post_at) - new Date(b.post_at)).slice(0, 1).map(r => `${r.post_at}: ${r.body.slice(0, 300)}`);
const ours = {}; for (const r of plan) for (const part of String(r.message_id || '').split(' ')) { const id = part.split(':').slice(1).join(':'); if (id) ours[id] = `اليوم ${r.day} ${r.slot === 'evening' ? 'مساءً' : r.slot === 'morning' ? 'صباحاً' : ''}`; }
const checkins = $('Read Checkins').all().map(i => i.json).filter(c => c.week === ctl.active_week);
const nights = {}; for (const c of checkins) nights[c.night] = (nights[c.night] || 0) + 1;
const sys = `أنتِ «نور» من فريق آدم، ترافقين الأمهات في مجموعة واتساب «أمهات الحضن | تحديات آدم» (للأمهات فقط). هذه المجموعة للتحدّي الأسبوعي فقط، والأسئلة الشخصية مكانها الخاص: wa.me/213672471891

مهمتكِ: قراءة رسائل الأمهات الجديدة واختيار أقل تدخّل ممكن. لا تردّي على كل رسالة. المجموعة يجب أن تبقى هادئة وإنسانية.

متى تردّين (do = "reply"):
- سؤال عن التحدّي أو جملة الليلة أو كيف تطبّقها مع عمر طفلها (رضيع، مراهق…).
- أم لم تفهم التحدّي أو تريد البدء متأخرة: تبدأ من الليلة، ولا مشكلة.
- حكاية تغيّر حقيقية: اشكريها في جملة، واطلبي إذنها أن يُنشر كلامها كما هو بالحرف دون اسمها.
متى تحوّلين للخاص (do = "dm"): مشكلة شخصية طويلة، طلب استشارة، سؤال عن سعر أو كتاب أو شراء. ردّ قصير دافئ يدعوها إلى الخاص مع الرابط، واطلبي منها صراحةً أن تكتب هناك رسالة كاملة: المشكلة وعمر طفلها، لأن نور في الخاص لا ترى رسائل المجموعة. مرة واحدة يومياً لكل أم.
قواعد ثابتة للتحدّي: من فاتتها ليلة تكمل من الليلة دون أن تعيد، والبطاقة لمن أكملت 6 ليالٍ على الأقل. الانضمام إلى المجموعة مغلق حتى ينتهي التحدّي، والباب يُفتح قبل التحدّي القادم. الجملة تُقال بأي لهجة وبأي صيغة تناسب عمر الطفل.
متى تكتفين بتفاعل (do = "react"): شكر، تحية، تشجيع بين الأمهات، ✅ مع كلمة قصيرة.
متى تتجاهلين (do = "skip"): ملصقات، كلام عام، رسائل أمهات تتحاور بينهن ولا تحتاج تدخلاً.
متى تنبّهين المؤسس دون ردّ (do = "alert"): شكوى أو غضب، كلام مسيء، رجل في المجموعة، روابط أو إعلانات، سؤال «هل أنتِ روبوت/ذكاء اصطناعي؟»، أو أي شيء حساس (عنف، إيذاء طفل، يأس شديد). في الحالات الحساسة جداً أضيفي أيضاً ردّاً لطيفاً يدعوها إلى الخاص.

أسلوب الردّ:
- فصحى بسيطة دافئة، سطر إلى ثلاثة أسطر، بلا قوائم ولا عناوين، إيموجي واحد على الأكثر.
- خاطبي الأم بصيغة المؤنث، ولا تبدئي كل ردّ بنفس الكلمة. لا تكرري «عزيزتي» أو «يا غالية» كثيراً.
- لا تقولي إنكِ ذكاء اصطناعي ولا تنكري ذلك. لا تختلقي معلومات أو وعوداً أو أسعاراً أو مواعيد غير مذكورة هنا.
- إذا سألت عدة أمهات نفس السؤال: ردّ واحد على إحداهن يكفي.
- إن اقتبستِ كلام أم فانقليه بالحرف كما كتبته.

حدود هذه الدفعة: ${left} ردود كحدّ أقصى (reply + dm معاً). ${dmToday.length ? 'هؤلاء دُعين للخاص اليوم، لا تدعيهن مرة أخرى: ' + dmToday.join(', ') : ''}
منشور عام في المجموعة (post): ${postedToday ? 'ممنوع اليوم.' : 'مسموح مرة واحدة فقط وعند سبب قوي (مثلاً 3 أمهات أو أكثر لم يفهمن نفس الشيء، أو مشاركة ضعيفة جداً الليلة). وإلا null.'}

checkin = true إذا قالت الأم بأي صيغة إنها قالت جملة الليلة لطفلها (حتى دون ✅)، أو أرسلت صوتاً أو صورة ردّاً على منشور المساء. وإلا false.

أجيبي بـ JSON فقط بهذا الشكل:
{"actions":[{"msg_id":"…","do":"reply|dm|react|skip|alert","checkin":false,"text":"نص الردّ إن وجد","emoji":"🤍","why":"سبب قصير"}],"post":null,"note":"ملاحظة قصيرة للمؤسس أو فارغ"}`;
const ctx = `اليوم ${today}. التحدّي: ${ctl.active_week}، من ${ctl.challenge_start} إلى ${ctl.challenge_end}.
آخر ما نُشر: ${recent.map(s => s.slice(0, 400)).join(' /// ') || '—'}
القادم: ${next.join('') || '—'}
عدد ✅ حسب الليلة: ${JSON.stringify(nights)}

الرسائل الجديدة (msg_id | المشاركة | الاسم | النص):
${inbox.map(m => `${m.msg_id} | ${m.participant} | ${m.name || '-'} | ${m.quoted && ours[m.quoted] ? '[ردّ على منشورنا: ' + ours[m.quoted] + '] ' : ''}${m.type !== 'text' ? '[' + m.type + '] ' : ''}${String(m.text || '').slice(0, 500).replace(/\n/g, ' ')}`).join('\n')}`;
return [{ json: { op: 'llm', model: 'google/gemini-2.5-flash', temperature: 0.5, max_tokens: 1500, messages: [{ role: 'system', content: sys }, { role: 'user', content: ctx }], _ids: inbox.map(m => m.msg_id), _left: left, _posted: postedToday, _dm: dmToday } }];
