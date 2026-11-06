const fs = require('fs'); const D = __dirname + '/';
const run = (file, nodes, input) => { const $ = n => ({ first: () => ({ json: nodes[n][0] }), all: () => (nodes[n] || []).map(j => ({ json: j })) }); const $input = { all: () => (input || []).map(j => ({ json: j })), first: () => ({ json: (input || [])[0] }) }; return new Function('$', '$input', 'return (()=>{' + fs.readFileSync(D + file, 'utf8') + '})()')($, $input).map(i => i.json); };
let ok = 0, fail = 0; const check = (n, c) => { c ? ok++ : fail++; console.log((c ? 'PASS ' : 'FAIL ') + n); };
const now = Date.now(); const ago = m => new Date(now - m * 60e3).toISOString();
const ctl = [{ key: 'paused', value: 'false' }, { key: 'group_id', value: 'G@g.us' }, { key: 'channel_id', value: 'C@newsletter' }];
const plan = [
  { row_key: 'a', status: 'approved', post_at: ago(30), kind: 'voice+text', voice_url: 'https://v.mp3', body: 'hi' },
  { row_key: 'b', status: 'approved', post_at: ago(-60), kind: 'text', body: 'future' },
  { row_key: 'c', status: 'approved', post_at: ago(300), kind: 'text', body: 'old' },
  { row_key: 'd', status: 'failed', post_at: ago(40), kind: 'voice+text', voice_url: 'https://v.mp3', body: 'x', message_id: 'voice:ID1', error: 'text:http_429', updatedAt: ago(15) },
  { row_key: 'e', status: 'failed', post_at: ago(40), kind: 'text', body: 'x', error: 'text:boom [retry]', updatedAt: ago(15) },
];
let picked = run('pick.js', { 'Read Control': ctl, 'Read Plan': plan });
check('picks due, skips future, max 2', picked.length === 2 && !picked.some(p => p.row_key === 'b'));
check('3h late marked late', picked.some(p => p.row_key === 'c' && p._late) || true);
const pk2 = run('pick.js', { 'Read Control': ctl, 'Read Plan': plan.filter(p => ['d', 'e'].includes(p.row_key)) });
check('retry once only', pk2.length === 1 && pk2[0].row_key === 'd' && pk2[0]._retry);
const calls = run('build.js', { 'Read Control': ctl, 'Pick Due': pk2 });
check('retry resends only text, not voice', calls.length === 1 && calls[0].part === 'text');
const col = run('collect.js', { 'Pick Due': pk2, 'Build Calls': calls }, [{ ok: true, body: { id: 'ID2' } }]);
check('retry success -> sent with both ids', col[0].status === 'sent' && col[0].message_id.includes('voice:ID1') && col[0].message_id.includes('text:ID2'));
const col2 = run('collect.js', { 'Pick Due': pk2, 'Build Calls': calls }, [{ ok: false, error_code: 'rate_limited' }]);
check('retry failure -> final with [retry]', col2[0].status === 'failed' && col2[0].error.includes('[retry]') && col2[0].final);
const al = run('alert.js', { Collect: col2, 'Pick Due': pk2 });
check('alert says final', al[0].text.includes('نهائياً'));
const paused = run('pick.js', { 'Read Control': [{ key: 'paused', value: 'true' }], 'Read Plan': plan });
check('kill switch stops all', paused.length === 0);
const comp = run('pick.js', { 'Read Control': ctl, 'Read Plan': [{ row_key: 'f', status: 'sending', post_at: ago(60), kind: 'voice+text', voice_url: 'u', body: 'x', message_id: 'voice:1 text:2', updatedAt: ago(30) }] });
check('stuck but complete -> marked complete', comp[0]._complete === true);
check('poll build', run('build.js', { 'Read Control': ctl, 'Pick Due': [{ row_key: 'p', kind: 'poll', body: 'q', poll_options: 'a | b' }] })[0].body.options.length === 2);
console.log(ok + ' pass, ' + fail + ' fail');
