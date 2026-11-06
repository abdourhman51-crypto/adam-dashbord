const fs = require('fs');
const code = fs.readFileSync(__dirname + '/decide.js', 'utf8');
function run(nodes, input) {
  const $ = n => ({ first: () => ({ json: nodes[n][0] }), all: () => nodes[n].map(j => ({ json: j })) });
  const $input = { first: () => ({ json: input }) };
  return new Function('$', '$input', 'return (()=>{' + code + '})()')($, $input)[0].json;
}
const base = {
  'Build Prompt': [{ _left: 2, _posted: false, _dm: ['lidB'], _ids: ['m1', 'm2', 'm3', 'm4', 'm5', 'm6'] }],
  'Read Control': [{ key: 'group_id', value: 'G@g.us' }, { key: 'active_week', value: 'w1' }, { key: 'challenge_start', value: '2026-11-08' }],
  'Read Inbox': ['m1', 'm2', 'm3', 'm4', 'm5', 'm6'].map((id, i) => ({ msg_id: id, participant: 'lid' + 'ABCDEF'[i], text: 'x', at: '2026-11-09T21:00:00Z' })),
  'Read Actions': [{ ref: 'm6', kind: 'reply' }],
};
let ok = 0, fail = 0; const check = (n, c) => { c ? ok++ : fail++; console.log((c ? 'PASS ' : 'FAIL ') + n); };
let o = run(base, { ok: true, result: { actions: [
  { msg_id: 'm1', do: 'reply', text: 'سؤال جميل، قوليها بصوت هادئ 🤍', checkin: true },
  { msg_id: 'm2', do: 'dm', text: 'اكتبي لنور في الخاص' },
  { msg_id: 'm3', do: 'reply', text: 'الكتاب بـ 4 دولار' },
  { msg_id: 'm4', do: 'reply', text: 'رد ثالث' },
  { msg_id: 'm5', do: 'react', emoji: '❤️' },
  { msg_id: 'm6', do: 'reply', text: 'تكرار' },
  { msg_id: 'zz', do: 'reply', text: 'غريب' } ], post: null, note: '' } });
const texts = o.calls.filter(c => c.path === '/messages/text');
check('reply sent once for m1', texts.some(c => c.body.quoted === 'm1'));
check('dm blocked for mother already invited today', !texts.some(c => c.body.quoted === 'm2'));
check('price reply blocked -> alert', !texts.some(c => c.body.quoted === 'm3') && o.log.some(l => l.ref === 'm3' && l.kind === 'alert'));
check('cap respected (2 left)', texts.length <= 2);
check('react kept', o.calls.some(c => c.path.includes('/react')));
check('already answered m6 skipped', !texts.some(c => c.body.quoted === 'm6'));
check('unknown msg ignored', !o.calls.some(c => c.body && c.body.quoted === 'zz'));
check('checkin from AI night 2', o.checkins.length === 1 && o.checkins[0].night === 2);
check('all ids marked', o.mark.length === 6);
check('telegram alert present', o.calls.some(c => c.op === 'telegram'));
o = run(base, { ok: false, status: 500 });
check('AI failure -> telegram, nothing marked', o.calls[0].op === 'telegram' && o.mark.length === 0);
console.log(ok + ' pass, ' + fail + ' fail');
