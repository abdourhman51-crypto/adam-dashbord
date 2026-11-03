const fs = require('fs');
const AsyncFn = Object.getPrototypeOf(async function(){}).constructor;
let fails = 0; const check = (n, c, i) => { console.log((c ? 'PASS ' : 'FAIL ') + n + (c ? '' : '  -> ' + i)); if (!c) fails++; };
const params = {
  'Cancel DM Job': { headerParameters: { parameters: [{ name: 'x-noor-token', value: 'TOK' }] } },
  'Send DM Reply': { headerParameters: { parameters: [{ name: 'Authorization', value: 'Bearer Z' }] } },
  'Telegram Alert': { url: 'https://api.telegram.org/botX/sendMessage' },
};
const T = '3db81696-dda4-4bf3-931c-ac08290966e9';
async function runPay(query, rpcReply, opts = {}) {
  const calls = []; const sd = { convs: { conv1: { history: [], meta: { stage: 'ready' } } } };
  const helpers = { httpRequest: async req => {
    calls.push(req);
    if (req.url.includes('noor-inbox-rpc')) return req.body.action === 'approval_decide' ? rpcReply : { ok: true };
    if (req.url.includes('zernio')) { if (opts.fileFail && req.body.attachmentType) throw new Error('400 bad file'); if (opts.textFail && req.body.message) throw new Error('500'); return { ok: true }; }
    return { ok: true };
  } };
  const fn = new AsyncFn('$input', '$', '$getWorkflowStaticData', fs.readFileSync(__dirname + '/Pay-Process.js', 'utf8'));
  const res = await fn.call({ helpers }, { first: () => ({ json: { query } }) }, n => ({ params: params[n] }), () => sd);
  return { j: res[0].json, calls, sd };
}
const appr = plat => ({ ok: true, approval: { external_conversation_id: 'conv1', account_id: 'acc', platform: plat, contact_name: 'مي' } });
(async () => {
  let x = await runPay({ t: 'nope', d: 'a', p: 'hodn' }, null);
  check('bad token -> invalid, no calls', x.j.step === 'invalid' && x.calls.length === 0, x.j.step);
  x = await runPay({ t: T, d: 'a' }, null);
  check('approve without product -> invalid', x.j.step === 'invalid', x.j.step);
  x = await runPay({ t: T, d: 'a', p: 'hodn' }, null);
  check('first tap -> confirm page, no calls', x.j.step === 'confirm' && x.calls.length === 0 && x.j.html.includes('&amp;c=1'), x.j.step);
  x = await runPay({ t: T, d: 'a', p: 'hodn', c: '1' }, appr('facebook'));
  const z = x.calls.filter(c => c.url.includes('zernio'));
  check('facebook: file then text', z.length === 2 && z[0].body.attachmentType === 'file' && z[0].body.attachmentUrl.endsWith('hodn-e0cff222f3d884097ee95095.pdf') && z[1].body.message.includes('ملفاً فوق'), JSON.stringify(z.map(c => c.body)));
  check('zernio url + auth', z[0].url === 'https://zernio.com/api/v1/inbox/conversations/conv1/messages' && z[0].headers.Authorization === 'Bearer Z', z[0].url);
  check('link on own line', z[1].body.message.includes('\n\n👉 https://hodn.adamvoices.site/d/hodn-e0cff222f3d884097ee95095.pdf\n\n'), z[1].body.message);
  check('decide payload', JSON.stringify(x.calls[0].body) === JSON.stringify({ action: 'approval_decide', payload: { p_token: T, p_decision: 'approved', p_product: 'hodn' } }) && x.calls[0].headers['x-noor-token'] === 'TOK', JSON.stringify(x.calls[0]));
  check('delivered marked ok', x.calls.some(c => c.body.action === 'approval_delivered' && c.body.payload.p_error === null), '');
  check('static memory: customer + no follow-up', x.sd.convs.conv1.meta.customer && x.sd.convs.conv1.meta.followedUp && x.sd.convs.conv1.history.length === 1, JSON.stringify(x.sd.convs.conv1.meta));
  check('telegram confirm', x.calls.some(c => c.url.includes('telegram') && c.body.text.startsWith('✅')), '');
  check('step delivered', x.j.step === 'delivered', x.j.step);
  x = await runPay({ t: T, d: 'a', p: 'cards', c: '1' }, appr('instagram'));
  const zi = x.calls.filter(c => c.url.includes('zernio'));
  check('instagram: link only', zi.length === 1 && zi[0].body.message.includes('adam-emotion-cards') && !zi[0].body.message.includes('ملفاً فوق'), JSON.stringify(zi.map(c => c.body)));
  x = await runPay({ t: T, d: 'a', p: 'inad', c: '1' }, appr('facebook'), { fileFail: true });
  const zf = x.calls.filter(c => c.url.includes('zernio'));
  check('fb file fails -> text still sent, no false claim', x.j.step === 'delivered' && zf.length === 2 && !zf[1].body.message.includes('ملفاً فوق'), JSON.stringify(x.j));
  check('partial error recorded', x.calls.some(c => c.body.action === 'approval_delivered' && /file: 400/.test(c.body.payload.p_error)), '');
  x = await runPay({ t: T, d: 'a', p: 'inad', c: '1' }, appr('instagram'), { textFail: true });
  check('all sends fail -> send_failed, memory untouched', x.j.step === 'send_failed' && !x.sd.convs.conv1.meta.customer && x.calls.some(c => c.url.includes('telegram') && c.body.text.startsWith('⚠️')), x.j.step);
  x = await runPay({ t: T, d: 'a', p: 'hodn', c: '1' }, { ok: false, already: true, status: 'approved', product: 'hodn' });
  check('second tap -> already, no send', x.j.step === 'already' && !x.calls.some(c => c.url.includes('zernio')), x.j.step);
  x = await runPay({ t: T, d: 'r', c: '1' }, appr('facebook'));
  check('reject -> nothing to her, telegram note', x.j.step === 'rejected' && !x.calls.some(c => c.url.includes('zernio')) && x.calls.some(c => c.url.includes('telegram')), x.j.step);
  check('reject payload product null', x.calls[0].body.payload.p_product === null, '');

  // pay_alert
  const alert = fs.readFileSync(__dirname + '/Pay-Alert-Build.js', 'utf8');
  const runAlert = (tok, prof, insight) => new Function('$input', '$', alert)(
    { first: () => ({ json: { ok: true, token: tok } }) },
    n => ({ first: () => ({ json: n === 'Parse & Remember' ? { alertText: '💰 وصل دفع', insight: insight || {} } : { profile: prof } }) }));
  let a = runAlert(T, { products_offered: ['inad', 'hodn'] })[0].json.tg;
  check('alert: 3 product buttons + reject', a.reply_markup.inline_keyboard[0].length === 3 && a.reply_markup.inline_keyboard[1][0].url.endsWith('&d=r'), JSON.stringify(a.reply_markup));
  check('alert: star on last offered (hodn)', a.reply_markup.inline_keyboard[0][0].text.startsWith('⭐') && !a.reply_markup.inline_keyboard[0][1].text.startsWith('⭐'), JSON.stringify(a.reply_markup.inline_keyboard[0]));
  check('alert: button url', a.reply_markup.inline_keyboard[0][1].url === 'https://adam-voices-n8n.hawiyat.cloud/webhook/nour-pay?t=' + T + '&d=a&p=inad', a.reply_markup.inline_keyboard[0][1].url);
  a = runAlert(undefined, null)[0].json.tg;
  check('alert: no token -> no buttons, manual note', !a.reply_markup && a.text.includes('يدوياً'), '');
  a = runAlert(T, null, { product_offered: 'cards' })[0].json.tg;
  check('alert: fallback star from insight', a.reply_markup.inline_keyboard[0][2].text.startsWith('⭐'), '');
  console.log(fails ? fails + ' FAILED' : 'ALL PASSED'); process.exit(fails ? 1 : 0);
})();
