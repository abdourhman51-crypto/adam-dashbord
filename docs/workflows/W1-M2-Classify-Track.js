// Node: M2 - Classify Track  |  ADAM - Machine 1+2 (42loY0bgUSwYmHFV)
// Decides which track a message takes. The country_answer branch is the one
// that catches a TYPED country: while country_asked_at is inside its 36h window
// and the message is text, the next turn IS that answer, so it outranks every
// other track and routes (via M2 - Track Switch output 4) into the credentialed
// Tap - Get Moment node — no new credentialed node needed.
const items = $input.all();
const f = items.length > 0 ? items[0].json : {};
const r = $('Router').first().json;

const stage = f.funnel_stage || 'free_conversation';
const followerId = f.id || null;
const isWaitlisted = (f.waitlist === true);
const inSurvey = (f.survey_mode === true);
const expired = f.subscription_expires_at ? (new Date(f.subscription_expires_at) < new Date()) : false;

const askedAt = f.country_asked_at ? new Date(f.country_asked_at) : null;
const awaitingCountry = askedAt && (Date.now() - askedAt.getTime()) < 36*3600*1000;

let track = 'free';
if (!followerId) {
  track = 'new';
} else if (awaitingCountry && (r.message_text || '').trim()) {
  track = 'country_answer';
} else if (inSurvey) {
  track = 'survey';
} else if (isWaitlisted) {
  track = 'waitlist';
} else if (stage === 'paid_active' && !expired) {
  track = 'paid';
}

let childName = '';
try {
  const kids = Array.isArray(f.children) ? f.children : [];
  const primary = kids.find(k => k && k.is_primary) || kids[0];
  if (primary && primary.name) childName = String(primary.name).trim();
} catch (e) {}

return [{ json: {
  id: followerId, chat_id: r.chat_id, telegram_id: r.telegram_id,
  first_name: r.first_name, message_text: r.message_text,
  light_memory: f.light_memory,
  country: (f.country || '').toString().replace(/^=+/, '').trim().toUpperCase(),
  parent_gender: f.parent_gender || '', child_name: childName, track
} }];
