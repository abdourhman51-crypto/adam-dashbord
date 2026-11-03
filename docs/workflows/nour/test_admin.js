const fs = require('fs'); let fails = 0;
const check = (n, c, i) => { console.log((c ? 'PASS ' : 'FAIL ') + n + (c ? '' : '  -> ' + i)); if (!c) fails++; };
const AsyncFn = Object.getPrototypeOf(async function(){}).constructor;
const params = { 'Cancel DM Job': { headerParameters: { parameters: [{ name: 'x-noor-token', value: 'TOK' }] } }, 'Send DM Reply': { headerParameters: { parameters: [{ name: 'Authorization', value: 'Bearer Z' }] } } };
async function run(claimed, zfail) {
  const calls = []; const sd = { convs: { ext1: { history: [], meta: {} } } };
  const helpers = { httpRequest: async r => { calls.push(r); if (r.body && r.body.action === 'commands_claim') return claimed; if (r.url.includes('zernio')) { if (zfail) throw new Error('400 window closed'); return { ok: true }; } return { ok: true }; } };
  const res = await new AsyncFn('$', '$getWorkflowStaticData', fs.readFileSync(__dirname + '/Dashboard-Run-Commands.js', 'utf8')).call({ helpers }, n => ({ params: params[n] }), () => sd);
  return { res: res.map(x => x.json), calls, sd };
}
(async () => {
  let x = await run([]);
  check('nothing pending -> no sends', x.res[0].claimed === 0 && !x.calls.some(c => c.url.includes('zernio')), JSON.stringify(x.res));
  x = await run([{ id: 7, kind: 'send_dm', text: 'سلام', external_conversation_id: 'ext1', channel: 'instagram' }]);
  const z = x.calls.find(c => c.url.includes('zernio'));
  check('sends with IG account', z && z.body.accountId === '6ad4f3c0fff6142041afeecd' && z.body.message === 'سلام' && z.url.endsWith('/conversations/ext1/messages'), JSON.stringify(z));
  check('finish ok', x.calls.some(c => c.body && c.body.action === 'command_finish' && c.body.payload.p_id === 7 && c.body.payload.p_ok === true), '');
  check('memory updated', x.sd.convs.ext1.history[0].content === '[الفريق] سلام' && x.sd.convs.ext1.meta.humanAt, JSON.stringify(x.sd.convs.ext1));
  x = await run([{ id: 8, kind: 'send_dm', text: 'x', external_conversation_id: 'ext1', channel: 'facebook' }], true);
  check('zernio failure -> finish failed with reason', x.calls.some(c => c.body && c.body.action === 'command_finish' && c.body.payload.p_ok === false && /window closed/.test(c.body.payload.p_result)), JSON.stringify(x.res));
  x = await run([{ id: 9, kind: 'send_dm', text: 'x', external_conversation_id: 'e', channel: 'whatsapp' }]);
  check('unknown channel -> failed, no send', !x.calls.some(c => c.url.includes('zernio')) && x.res[0].ok === false, JSON.stringify(x.res));
  // takeover pause
  const tk = fs.readFileSync(__dirname + '/Takeover-Human-Active.js', 'utf8');
  const T = prof => new Function('$', '$input', '$getWorkflowStaticData', tk)(n => ({ first: () => ({ json: n === 'Prepare Claimed DM' ? { conversationId: 'c1' } : { messages: [] } }) }), { first: () => ({ json: { ok: true, profile: prof } }) }, () => ({}))[0].json;
  check('paused profile -> humanActive', T({ nour_paused_until: new Date(Date.now() + 3600e3).toISOString() }).humanActive === true, '');
  check('expired pause -> active Nour', T({ nour_paused_until: new Date(Date.now() - 60e3).toISOString() }).humanActive === false, '');
  check('no profile -> active Nour', T(null).humanActive === false, '');
  console.log(fails ? fails + ' FAILED' : 'ALL PASSED'); process.exit(fails ? 1 : 0);
})();
