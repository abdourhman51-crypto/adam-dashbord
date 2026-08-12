const u = $input.first().json;
const out = { ...u };
let route = 'normal';
let chat_id = null, telegram_id = null, first_name = '', username = '', text = '', cbdata = '', cbid = '';
let start_source = '', country_code = '';

const COMMANDS = {
  '/child':    'menu_child',
  '/progress': 'menu_progress',
  '/journey':  'menu_journey',
  '/reading':  'menu_reading',
  '/settings': 'menu_settings',
  '/privacy':  'menu_privacy',
  '/faq':      'menu_faq',
  '/help':     'menu_faq'
};

const TAPS = {
  menu_help:          'menu_faq',
  help_start:         'menu_open_question',
  other:              'menu_open_question',
  how_exactly:        'menu_open_question',
  how_start:          'menu_open_question',
  not_now:            'menu_open_question',
  cta_later:          'menu_open_question',
  cta_ready:          'menu_open_question',
  cta_full_companion: 'menu_journey',
  waitlist_join:      'menu_waitlist_join'
};

// The supported-market list used to be hardcoded here as ['DZ','EG','MA'].
// It is gone: supported_countries.is_active is the single source, country_state()
// reads it, and a market could be switched on in a row without anyone
// remembering to edit this file.

// Telegram announces things that HAPPEN in a chat as ordinary message
// updates: a pin, a join, a title change. They carry no text, so every
// text-shaped check below returns false and the update falls to the
// rescue — which sends a message, which refreshes the pinned banner,
// which makes Telegram announce a pin, which arrives as another service
// message. ADAM talking to himself, forever, through Telegram.
//
// That loop reached a real chat on 2026-08-01 and only stopped when the
// workflow was switched off by hand. Nothing below may run for these.
const SERVICE_FIELDS = [
  'pinned_message', 'new_chat_members', 'left_chat_member', 'new_chat_title',
  'new_chat_photo', 'delete_chat_photo', 'group_chat_created',
  'supergroup_chat_created', 'channel_chat_created', 'migrate_to_chat_id',
  'migrate_from_chat_id', 'message_auto_delete_timer_changed',
  'successful_payment', 'refunded_payment', 'web_app_data', 'users_shared',
  'chat_shared', 'proximity_alert_triggered', 'forum_topic_created',
  'forum_topic_edited', 'forum_topic_closed', 'forum_topic_reopened',
  'general_forum_topic_hidden', 'general_forum_topic_unhidden',
  'giveaway_created', 'giveaway_completed', 'video_chat_scheduled',
  'video_chat_started', 'video_chat_ended', 'video_chat_participants_invited',
  'boost_added', 'chat_background_set', 'write_access_allowed'
];

const m0 = u.message || u.edited_message || null;
const isService = !!(m0 && SERVICE_FIELDS.some((f) => m0[f] !== undefined));
const isFromBot = !!(m0 && m0.from && m0.from.is_bot);

if (isService || isFromBot) {
  out.route = 'ignore';
  out.chat_id = String((m0 && m0.chat && m0.chat.id) || '');
  out.telegram_id = out.chat_id;
  out.first_name = ''; out.username = ''; out.message_text = '';
  out.callback_data = ''; out.callback_query_id = ''; out.start_source = 'organic';
  out.country_code = '';
  out.ignored_because = isFromBot ? 'from_bot' : 'service_message';
  return [{ json: out }];
}

if (u.callback_query) {
  const cq = u.callback_query;
  cbid = cq.id || '';
  cbdata = cq.data || '';
  chat_id = (cq.message && cq.message.chat) ? cq.message.chat.id : cq.from.id;
  telegram_id = cq.from.id;
  first_name = cq.from.first_name || '';
  username = cq.from.username || '';

  if (cbdata.indexOf('set_country_') === 0) {
    // The parent naming their own country. There is no reliable country
    // signal in a Telegram update, so this answer is the only source —
    // and it unblocks the daily rhythm too, which needs a local clock.
    // Every country is recorded, supported or not. This used to throw the code
    // away unless it was one of three, which meant a parent in an unsupported
    // country could tap their own flag and ADAM would still not know where they
    // were — and the waitlist would have collected demand with no address.
    // What we SAY is decided by country_state() in the database, which reads
    // supported_countries; the Router's job is only to report what was tapped.
    const raw = cbdata.replace('set_country_', '').toUpperCase();
    route = 'menu_tap';
    country_code = raw;
    cbdata = 'country_recorded';
  }
  else if (TAPS[cbdata]) { route = 'menu_tap'; cbdata = TAPS[cbdata]; }
  else if (cbdata.indexOf('menu_')    === 0) route = 'menu_tap';
  else if (cbdata.indexOf('ck_mom_')  === 0) route = 'ck_mom';
  else if (cbdata.indexOf('ck_step_') === 0) route = 'ck_step';
  else if (cbdata.indexOf('ck_gen_')  === 0) route = 'ck_gen';
  else { route = 'menu_tap'; cbdata = 'rescue'; }   // E9
} else if (u.message) {
  const m = u.message;
  chat_id = m.chat.id;
  telegram_id = m.from ? m.from.id : m.chat.id;
  first_name = (m.from && m.from.first_name) || m.chat.first_name || '';
  username = (m.from && m.from.username) || '';

  text = (m.text || m.caption || '').trim();

  const heard = !!(m.voice || m.audio || m.video_note);
  const seen  = !!(m.photo || m.video || m.document || m.sticker || m.animation);
  const has = (needle) => text.indexOf(needle) > -1;
  const cmd = text.split(/[\s@]/)[0].toLowerCase();

  if (!text && heard) { route = 'menu_tap'; cbdata = 'voice_unsupported'; }
  else if (!text && seen) { route = 'menu_tap'; cbdata = 'media_unsupported'; }
  else if (cmd === '/start') {
    route = 'start';
    start_source = text.replace('/start', '').trim() || 'organic';
  }
  else if (COMMANDS[cmd]) { route = 'menu_tap'; cbdata = COMMANDS[cmd]; }
  else if (cmd.charAt(0) === '/') { route = 'menu_tap'; cbdata = 'menu_faq'; }
  else if (has('ما هو آدم') || has('القائمة')) { route = 'menu_tap'; cbdata = 'menu_faq'; }
  else if (has('كيف نتقدّم') || has('كيف نتقدم')) { route = 'menu_tap'; cbdata = 'menu_progress'; }
  else if (text) route = 'normal';
  else { route = 'menu_tap'; cbdata = 'rescue'; }   // E9
} else {
  out.route = 'ignore';
  out.chat_id = ''; out.telegram_id = ''; out.first_name = ''; out.username = '';
  out.message_text = ''; out.callback_data = ''; out.callback_query_id = '';
  out.start_source = 'organic'; out.country_code = '';
  out.ignored_because = 'no_message_no_callback';
  return [{ json: out }];
}

out.route = route;
out.chat_id = String(chat_id);
out.telegram_id = String(telegram_id);
out.first_name = first_name;
out.username = username;
out.message_text = text;
out.callback_data = cbdata;
out.callback_query_id = String(cbid);
out.start_source = start_source || 'organic';
out.country_code = country_code;
return [{ json: out }];