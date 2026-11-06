// Pending join requests, plus one profile lookup per applicant so the name check has something to read.
const ctl = Object.fromEntries($('Read Control').all().map(i => [i.json.key, i.json.value]));
if (String(ctl.paused) === 'true') return [];
const r = $input.first().json || {};
if (!r.ok) return [{ json: { op: 'telegram', text: '⚠️ تعذّر قراءة طلبات الانضمام: ' + (r.error_code || r.status), _skip: true } }];
const apps = ((r.body && r.body.participants) || []).slice(0, 25);
return apps.map(p => ({ json: { op: 'wapito', method: 'GET', path: '/contacts/lid/' + encodeURIComponent(p.lid || p.id), _app: p } }));
