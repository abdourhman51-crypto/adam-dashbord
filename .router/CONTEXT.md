# CONTEXT — ADAM WhatsApp challenge system

## Services
- Wapito API `https://api.wapito.com/v1` (Bearer, n8n credential `wapito` HMTwt7llrkGw00AA). sandbox cannot reach wapito.com; read docs via temp n8n Code node.
  - send: POST /messages/text {to,body,quoted?,mentions[],typing_time 0-15}; /messages/poll {to,title<=255,options 2-12,multiple}; /messages/voice|audio|image (MessageMedia); POST /messages/{id}/react {emoji}.
  - read: GET /messages/list/{chat_id}?count&offset&from_me&time_from&time_to (engine store, since connect).
  - webhooks: events messages, polls (in groups voter = group id, NO individual), groups.participants. Envelope {id evt_, event, data, timestamp, channel_id}. Headers x-wapito-delivery, x-wapito-signature.
  - newsletters: post = send to `...@newsletter` id; GET /newsletters lists.
  - 60 req/min. No send idempotency key -> dedupe in workflow.
- n8n `https://adam-voices-n8n.hawiyat.cloud`, project personal 8cbhsoL5OciL7E06. MCP cannot bind credentials: user picks in UI.
  - wf anDsaXXmBU9EZUbJ "Wapito - WhatsApp Group Integration" (manual; modes list_groups/read_messages/send kind text|poll; locked).
  - wf HVhsXj0qsVw2DLir "Wapito - Poll Votes Capture" (active) webhook /webhook/wapito-polls-7f3k9q2xv8 -> table D8ZfSYKpaKrj4qOJ wapito_poll_votes (one row per event).
  - table MJvxnD8BdbtBgAFG wapito_send_log.
  - creds: OpenRouter 3KNFveMOsC15T8bv, Telegram (Adam Hodn Bot. jan9wz2w3mlaNx9e, + 3 others), adam Supabase, whop api full 5f1gZLxKW8kDagjI.
  - DO NOT touch: Nour wf gzFzs1tBI1XIjc3E, voice wf VNXOhormwK6DwBrH (stays off), W2/W3/W4 paused.
- ElevenLabs: MCP only (in session). Nour voice_id jAAHNNqlbAX9iWjJPEtE, model v3 + emotion tags. Not callable from n8n -> pre-generate all audio.
- Dashboard: Next 15 on Vercel prj_R0gjW4uq9bOdivgMGJin9DBGNa5s (dashboard/). Candidate host for certificate PNG route.

## Group
- «أمهات الحضن | تحديات آدم» 120363409699660920@g.us, 222 members. Test group 120363425945143466@g.us (2).
- Linked number 213672471891 = Nour DM.
- Challenge announced: «7 ليالٍ، 7 جمل», starts Sunday 2026-11-08; morning sentence, said at bedtime, reply ✅; Friday sharing; 7/7 -> card «أمٌّ تعود» + gift.
- Poll "hardest evening time": screen 9, bedtime 8, bath 2, dinner 1; homework mentioned 3x.
- Time poll sent 2026-11-06 12:03 msg true_120363409699660920@g.us_3EB081BA7809FAF132E78B_213672471891@s.whatsapp.net.
- Mothers from DZ, EG, Levant -> relative times; text in Fusha; mothers' quotes verbatim; consent before quoting (Amal: «أمل ومالك ♥️♥️» approved).

## Rules
- Arabic-only replies to user. No secrets in chat/code/logs. No real message without approval. No invented endpoints.

## Channel (newsletter)
- «آدم | ما لا يقوله طفلك🧒» 120363425915331218@newsletter, role owner, invite https://whatsapp.com/channel/0029VbDBdtz4o7qHR40TWC0L
- Description promise: 🎥 short video from Adam · 💡 idea · 🧰 free tool · DM Nour.
- Webhook now subscribed to ALL events (user choice). DMs to 213672471891 also arrive (chat_id @lid / @s.whatsapp.net) -> moderator must ignore anything not the group. Group msgs: verify `participant` field on first group message.
- ElevenLabs MCP: "Free generations are busy" twice on 2026-11-06 13:00 -> retry later / plan limits.

## Decisions 2026-11-06 (founder)
- Finisher gift: card + chapter 1 free + 48h price: 4$ (Whop card) / 900 DZD (CCP). Egypt 3$, Lebanon 4$ (proposal).
- Countries where card payment fails: Nour apologises, explains, offers priority waitlist (honest scarcity, no fake claims).
- Channel: use Adam short clips (cut from long videos). State clearly: group = mothers only, no men.
- Join rule: nobody joins mid-challenge. Join window opens only before each challenge (Sat). Requests wait = scarcity.
- Join requests: approve women only (name check). Uncertain -> stay pending.
## Group facts (GET /groups/{id})
- settings: info_admin_only true, messages_admin_only false, member_add_mode all_member_add (members can add directly = bypass), membership_approval true.
- invite_code null => linked number is NOT admin. Owner 131452339523686@lid. Approve/reject/settings need admin.
- Docs: GET /groups/{id}/applications, POST .../applications/{pid}/approve, DELETE .../applications/{pid}, PATCH /groups/{id}/settings, GET|DELETE /groups/{id}/invite. groups.participants event action join_request. No API to edit newsletter description.
## Media facts
- Group msgs carry `participant` = sender LID (e.g. 242777958940894@lid) -> ✅ tracking key.
- POST /media (multipart or JSON data: URI) -> med_ id, link expires 7 days. Sends: /messages/voice|video|image {to, media: url|med_id|base64, caption?}. Voice: MP3 ok, converted to opus.
- ElevenLabs CDN (elevenlabsusercontent.com) blocked from sandbox; signed URLs expire ~3h -> rehost permanently (plan: Supabase edge fn fetch -> public storage bucket).
- ElevenLabs flow C3nYZsrrN4FzD5F1CCuO; v1 = gen tkSj8BRJSG0xT9c6Ss79 (24.6s, 306 credits, eleven_v4). Voice name: "Sara – Premium Humanlike Arabic".
