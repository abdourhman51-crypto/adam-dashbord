# Weekly challenge autopilot (WhatsApp group + channel)

Mirrored code nodes of the n8n workflows. n8n is the source of truth.

| Workflow | ID | What it does |
|---|---|---|
| ADAM · Gateway (Wapito + Telegram) | `n24t1p7539gVUtyC` | The only node with credentials: Wapito API, Telegram to the founder, OpenRouter (`op` = wapito / telegram / llm) |
| ADAM · Challenge review page | `7A0rTMpcivvZfiyG` | `GET /webhook/adam-review?t=` week on one page; edit, skip, approve. `render.js`, `save.js`, `done.js` |
| ADAM · Challenge scheduler | `XJUnDnn9wsoa17lG` | every 5 min posts approved rows; jitter; one retry of failed parts only; >3h late = missed. `pick.js`, `build.js`, `collect.js`, `alert.js` |
| Wapito - Events | `HVhsXj0qsVw2DLir` | webhook for all Wapito events: poll votes, group inbox, ✅ check-ins + heart, join requests, founder takeover. `route.js` |
| ADAM · Nour group brain | `XAmtgzVVM0wfntpf` | every 2h (day): one AI call over new messages; reply / dm / react / alert under hard caps and guards. `prompt.js`, `decide.js` |
| ADAM · Control switches | `lmbbSSGeegWGznvl` | `GET /webhook/adam-control?t=&k=paused|brain_on|join_window&v=` |
| ADAM · Watchdog + nightly report | `WRXiN8UQw1ayoJrb` | channel health every 30 min; Telegram report 21:50 UTC. `health.js`, `summary.js` |

Tables (n8n data tables): `challenge_plan`, `challenge_control`, `challenge_inbox`, `challenge_checkins`, `challenge_actions`, `join_queue`, `wapito_poll_votes`.

Tests: `node test_decide.js`, `node test_sched.js`.

## Failure handling
- Post fails: one retry after 10 min, only the missing part (voice never sent twice); then Telegram.
- Stuck in `sending` >20 min: resumed the same way.
- Webhook re-delivery: inbox upsert by `msg_id`; brain skips messages it already answered.
- Founder replies by hand (quote from the phone): that message is marked handled, Nour stays out.
- AI answer breaks a rule (foreign link, price, "AI/bot" words): not sent, goes to the founder.
- AI down or bad JSON: nothing marked, retried next cycle, founder told.
- WhatsApp disconnected / banned / QR: Telegram alert (max once per 2h) and on recovery.
- Kill switch: `paused=true` stops posting and replies.
| ADAM · Join gate | `atR7YM8ss6B1wbcs` | every 15 min: pending join requests; AI name check; women approved only between challenges (`join_window=auto`), men declined, unclear -> founder. `join_*.js` |
| ADAM · Card desk | `skiyqO45iL3ccJCS` | DM «بطاقتي» + her name + child's name («بطاقتي فاطمة - مالك»): finisher (6+ nights) -> card (missing names are asked for) (edge fn `adam-card`) + free chapter PDF + 48h price; «أريد الكتاب» -> founder. `desk*.js`, `done_card.js`, `test_desk.js` |

Card: `card/card.mjs` (SVG via resvg: ivory paper, deep green ink, gold; Thmanyah Sans Black/Bold/Regular for names and text, Aref Ruqaa for the classic title and signature; gold tree crest; Adam rising from the bottom edge in front of a gold sun; «٧ ليالٍ» seal), edge function `adam-card` (POST {name,child,key,date} -> public PNG in `adam-media/cards/`; fonts in `adam-media/fonts/`, images in `adam-media/brand/`). `card_requests.child` holds the child's name. Free chapter: `adam-media/docs/hodn-sample.pdf`.
