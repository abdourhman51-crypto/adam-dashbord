// One cheap AI call: is each applicant clearly a woman, clearly a man, or unclear? Only the name is available.
const apps = $('Build Lookups').all().map(i => i.json).filter(x => x._app);
const looks = $input.all().map(i => i.json);
const people = apps.map((a, i) => {
  const c = (looks[i] && looks[i].ok && looks[i].body) || {};
  return { pid: a._app.id, phone: a._app.phone || c.phone || '', name: [a._app.name, c.name, c.push_name].filter(Boolean)[0] || '' };
});
if (!people.length) return [];
const sys = 'تصنيف أسماء طالبي الانضمام إلى مجموعة واتساب للأمهات فقط. لكل اسم: F إذا كان اسم امرأة بوضوح (مثل: فاطمة، أم محمد، Sara، Amina)، M إذا كان اسم رجل بوضوح (مثل: محمد، أبو أحمد، Ahmed)، U إذا كان غير واضح (اسم مشترك، رموز، اسم متجر، فارغ). عند أي شك: U. أجيبي بـ JSON فقط: {"r":[{"pid":"…","g":"F|M|U"}]}';
return [{ json: { op: 'llm', model: 'google/gemini-2.5-flash', temperature: 0, max_tokens: 800, messages: [{ role: 'system', content: sys }, { role: 'user', content: JSON.stringify(people.map(p => ({ pid: p.pid, name: p.name }))) }], _people: people } }];
