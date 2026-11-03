const fs = require('fs');
const dir = __dirname;
const load = f => fs.readFileSync(dir + '/' + f, 'utf8');
const run = (code, inputJson, extra = {}) => {
  const sd = extra.sd || {};
  const fn = new Function('$input', '$getWorkflowStaticData', '$', code);
  const items = [{ json: inputJson }];
  return fn(
    { first: () => items[0], all: () => items },
    () => sd,
    extra.$ || (() => ({ first: () => ({ json: {} }) }))
  );
};
let fails = 0;
const check = (name, cond, info) => { console.log((cond ? 'PASS ' : 'FAIL ') + name + (cond ? '' : '  -> ' + info)); if (!cond) fails++; };

// ---------- prep_agent ----------
const prep = load('Prep-Agent-Input-DM.js');
const sys0 = '# من أنت\n...\n# الأسعار وطرق الدفع\n- سطر سعر\n- بعد التحويل: x\n\n# سياق\n- المنصة: facebook';
const mk = (text, history = []) => ({ senderName: 'رزاز', payload: { messages: [{ role: 'system', content: sys0 }, ...history, { role: 'user', content: text }] } });
const P = t => run(prep, mk(t))[0].json.prompt;
const PH = (t, h) => run(prep, mk(t, h))[0].json.prompt;
const hist = [{ role: 'user', content: 'سلام' }, { role: 'assistant', content: 'أهلاً أختي' }];

check('first DM "ميزان" -> boil promise', P('ميزان').includes('tools/boil') && P('ميزان').includes('كلمة مفتاحية'), P('ميزان'));
check('first DM "6" -> boil', P('6').includes('tools/boil'), P('6'));
check('"عناد" -> مترجم لا', P('عناد').includes('tools/no'), P('عناد'));
check('"عنيد سعر" -> inad book', P('عنيد سعر').includes('inad.adamvoices.site'), P('عنيد سعر'));
check('"حضن" -> hodn', P('حضن').includes('hodn.adamvoices.site'), P('حضن'));
check('"بطاقات" -> cards', P('بطاقات').includes('/cards'), '');
check('"21" -> waitlist', P('21').includes('/21'), '');
check('"بابا" -> father', P('بابا').includes('tools/father'), '');
check('"مرآة" -> mirror', P('مرآة').includes('tools/mirror') && P('مرآة').includes('كلمة مفتاحية'), P('مرآة'));
check('"ابعثلي الرابط" first -> asks which video', P('ابعثلي الرابط').includes('من أي فيديو'), P('ابعثلي الرابط'));
check('mid-conversation short keyword still detected', PH('ميزان', hist).includes('tools/boil'), '');
check('mid-conversation "ابعثلي الرابط" no generic note', !PH('ابعثلي الرابط', hist).includes('من أي فيديو'), '');
const story = 'عندي ولد عنيد عمره خمس سنوات يضرب أخته الصغيرة كل يوم ولا يسمع الكلام أبداً';
check('long first story with عنيد NOT treated as keyword', !P(story).includes('كلمة مفتاحية'), P(story));
check('greeting "السلام عليكم" no note', !P('السلام عليكم').includes('⚠️'), P('السلام عليكم'));
check('plain question no note', !PH('كيف أتعامل مع نومه؟', hist).includes('⚠️'), '');
const s = run(prep, mk('ميزان'))[0].json.system;
check('committed stage now offers product', s.includes('أكثر متابعة مستعدّة') && !s.includes('هذه أولويتكِ. ادعيها'), '');

const dina = [{ role: 'user', content: 'هنا هلاقي' }, { role: 'assistant', content: 'أيوه يا دينا، هتلاقي التفاصيل في الرابط' }, { role: 'assistant', content: 'حبيت أطمئن إن رابط الدفتر فتح معكِ تمام؟' }];
const dOut = run(prep, mk('فتح', dina))[0].json;
check('follow-up question reaches the agent (Dina case)', dOut.system.includes('نور: حبيت أطمئن إن رابط الدفتر فتح معكِ تمام؟'), dOut.system.slice(-300));
check('history kept out of prompt (memory stays small)', !dOut.prompt.includes('آخر المحادثة'), '');
check('no history block on first contact', !run(prep, mk('سلام'))[0].json.system.includes('آخر المحادثة'), '');

const ph = 'هي: كم السعر؟\nالفريق (إنسان): 1900 دج عبر CCP\nنور: تمام';
const pOut = run(prep, mk('وين نبعث الوصل؟', hist), { $: () => ({ first: () => ({ json: { platformHistory: ph } }) }) })[0].json;
check('platform history (with team lines) preferred over stored history', pOut.system.includes('الفريق (إنسان): 1900 دج عبر CCP') && !pOut.system.includes('نور: أهلاً أختي'), pOut.system.slice(-400));
check('team-lines rule added when founder spoke', pOut.system.includes('لا تناقضيها'), '');
check('no team rule without founder lines', !run(prep, mk('فتح', dina))[0].json.system.includes('لا تناقضيها'), '');

const prof = { country: 'الجزائر', children: [{ name: 'يوسف', age: '5' }], main_problem: 'صراخ', products_offered: ['hodn'], last_offer_at: '2026-11-01T10:00:00Z', objections: ['غالي'] };
const prOut = run(prep, mk('سلام', hist), { $: n => ({ first: () => ({ json: n === 'Takeover: Human Active?' ? { profile: prof, platformHistory: '' } : {} }) }) })[0].json;
check('durable profile reaches the prompt', prOut.system.includes('يوسف 5 سنوات') && prOut.system.includes('hodn (آخر عرض 2026-11-01)') && prOut.system.includes('اعتراضات سابقة: غالي'), prOut.system.slice(-500));
check('no profile block when profile empty', !run(prep, mk('سلام', hist))[0].json.system.includes('ملفها الدائم'), '');

// ---------- extra_rules ----------
const extra = load('Extra-Rules-DM.js');
const prepOut = run(prep, mk('سعر الدفتر بالدينار؟', hist))[0].json;
const finalSys = run(extra, prepOut)[0].json.system;
check('final system has CCP + 1,900', finalSys.includes('00799999002824585207') && finalSys.includes('1,900 دج') && finalSys.includes('لغويل عبد المعز'), '');
check('final system no vague "دعيني أتأكد"', !finalSys.includes('دعيني أتأكد لكِ'), '');
check('final system has SALES block', finalSys.includes('# البيع الناعم') && finalSys.includes('## الاعتراضات'), '');
check('link-own-line rule present', finalSys.includes('وحده في سطر مستقل'), '');
check('keyword exception rule present', finalSys.includes('7. استثناء الترتيب'), '');
check('no literal backslash-n left', !/\\n/.test(finalSys), finalSys.match(/.{20}\\n.{20}/));
check('fix() replaced pricing section', finalSys.split('# الأسعار وطرق الدفع').length === 2, finalSys.split('# الأسعار وطرق الدفع').length);

// ---------- parse_remember ----------
const parse = load('Parse-and-Remember.js');
const dmCtx = { conversationId: 'c1', accountId: 'a1', platform: 'facebook', senderName: 'رزاز', userText: 'عناد', images: [], voiceIn: false };
const R = reply => run(parse, { choices: [{ message: { content: JSON.stringify({ reply, stage: 'warm' }) } }] }, { sd: {}, $: () => ({ first: () => ({ json: dmCtx }) }) })[0].json;
const r1 = R('مترجم «لا» يساعدكِ على فهم ما وراء رفضه: https://adamvoices.site/tools/no كم عمره، وما أكثر شيء يرفضه؟');
console.log('---\n' + r1.reply + '\n---');
check('URL on its own line', r1.reply.split('\n').some(l => l === '👉 https://adamvoices.site/tools/no'), JSON.stringify(r1.reply));
check('sendBody matches reply', r1.sendBody.message === r1.reply, '');
check('hasLink + linkBody exact URL', r1.hasLink && r1.linkBody.message === 'https://adamvoices.site/tools/no', r1.linkBody.message);
check('ttsText has no URL', !/https?:/.test(r1.ttsText), r1.ttsText);
const r2 = R('هذه المرآة: https://adamvoices.site/tools/mirror.');
check('trailing dot stripped from URL', r2.reply.endsWith('👉 https://adamvoices.site/tools/mirror'), JSON.stringify(r2.reply));
const r3 = R('جرّبي [ميزان الغليان](https://adamvoices.site/tools/boil) الليلة');
check('markdown link unwrapped to own line', r3.reply.includes('\n👉 https://adamvoices.site/tools/boil\n') && !r3.reply.includes(']('), JSON.stringify(r3.reply));
const r4 = R('أهلاً أختي\n\n👉 https://hodn.adamvoices.site\n\nكم عمره؟');
check('already-formatted link unchanged', r4.reply === 'أهلاً أختي\n\n👉 https://hodn.adamvoices.site\n\nكم عمره؟', JSON.stringify(r4.reply));
const RP = (reply, profile) => run(parse, { choices: [{ message: { content: JSON.stringify({ reply, stage: 'ready', buying_signal: true, country: 'الجزائر', analysis: 'a', profile }) } }] }, { sd: {}, $: () => ({ first: () => ({ json: { ...dmCtx, internalConversationId: 'uuid-1' } }) }) })[0].json;
const i1 = RP('الدفتر هنا https://hodn.adamvoices.site', { child_name: 'يوسف', child_age: 5, problem: 'صراخ', topics: ['صراخ', 'نوم'], objection: '' });
check('insight carries profile facts', i1.insight.child.name === 'يوسف' && i1.insight.child.age === '5' && i1.insight.topics.length === 2 && i1.insight.buying_signal === true, JSON.stringify(i1.insight));
check('product detected from link even if model omits it', i1.insight.product_offered === 'hodn', i1.insight.product_offered);
check('internal conversation id passed for the profile store', i1.internalConversationId === 'uuid-1', '');
const i2 = RP('أهلاً', undefined);
check('missing profile object -> empty insight fields, no child', i2.insight.child === null && i2.insight.topics.length === 0 && i2.insight.product_offered === '', JSON.stringify(i2.insight));
const er = run(extra, prepOut)[0].json.system;
check('profile output rule present', er.includes('أضيفي إلى JSON المفتاح profile') && er.includes('"child_name"'), '');
const r5 = R('🤍');
check('heart-only reply untouched', r5.reply === '🤍', r5.reply);

console.log(fails ? `\n${fails} FAILED` : '\nALL PASSED');
process.exit(fails ? 1 : 0);
