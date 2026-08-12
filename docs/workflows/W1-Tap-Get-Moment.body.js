// Node: Tap - Get Moment (httpRequest jsonBody) | ADAM - Machine 1+2
// Calls rpc/get_moment_after_tap. Normal taps pass callback_data as the key.
// A country_answer routed here from M2 has no callback_data; the guarded
// reference to M2 - Classify Track (try/catch, because M2 does not run on the
// ordinary tap path) turns it into the capture key with the typed text.
={{ (() => {
  const r = $('Router').first().json;
  const raw = $('Tap - Get Parent').first().json;
  const p = Array.isArray(raw) ? (raw[0] || {}) : (raw || {});
  let cb = r.callback_data || 'rescue';
  let country = r.country_code || null;
  try {
    const cls = $('M2 - Classify Track').first().json;
    if (cls && cls.track === 'country_answer') { cb = 'menu_capture_country'; country = (cls.message_text || ''); }
  } catch (e) {}
  return JSON.stringify({ p_key: cb, p_parent_id: p.id || null, p_country_code: country });
})() }}
