# PLAN — 7-day challenge autopilot

## Goal
The founder approves the whole week once (Telegram, with edit). Then the system runs alone for 7 days: posts on time, reads the group, replies as Nour only when needed, tracks ✅ per mother, makes a named certificate for each finisher, delivers the gift in DM, and alerts the founder only on real problems.

## Non-goals
Changing Nour DM wf, the old voice wf, W2-W4. Per-name voice (ElevenLabs is MCP-only; no API key in n8n).

## Acceptance
A1 week plan (21 rows) in table, every row approved, audio URLs reachable.
A2 scheduler posts each row once (dedupe), within jitter window, logs it; dry-run on test group passes.
A3 moderator: batch every 2h in waking hours; rule layer (react to ✅, no LLM) + LLM only for flagged messages; <= N replies/day; never replies twice to same msg.
A4 ✅ tracker: per participant per night; finishers = 7 (or 6 + grace) by Saturday.
A5 certificate PNG with correct Arabic shaping for any name; sent in DM with gift.
A6 health: Wapito down / send failed / quota -> Telegram alert; kill switch row `paused=true`.

## Contracts
- table challenge_plan: id, week, day(1-7), slot(morning|evening|extra), kind(text|voice|poll|image), body, audio_url, poll_options, post_at(ISO), jitter_min, target(group|channel), status(draft|approved|sent|failed|skipped), message_id.
- table challenge_checkins: participant, name, night(1-7), msg_id, at.
- table challenge_replies: msg_id, reply_id, reason, at (dedupe + daily cap).
- table challenge_control: key, value (paused, daily_reply_cap, posting_time, week_start).
- certificate: GET /api/card?name=..&t=token -> image/png (dashboard on Vercel, @napi-rs/canvas, Arabic font).

## Tasks
T1 H verify: messages webhook gives participant + name in group (add `messages` event to subscription) 
T2 H decide time from poll + write week content (7 sentences + mini-challenges + evening reminders + Tue poll + Fri story post), Fusha.
T3 N generate 7+ voice notes via ElevenLabs MCP (v3 tags), host files, get URLs.
T4 N tables + Telegram approval wf (whole week, edit per row by reply).
T5 H scheduler wf (cron every 10 min, picks due approved rows, jitter, dedupe, posts, logs, alerts).
T6 H moderator wf (webhook messages -> store; batch 2h -> rules + LLM via OpenRouter cheap model -> reply/react/DM-redirect; caps).
T7 N ✅ tracker inside T6 store step.
T8 H certificate route (luxury design, Arabic test names) + deploy.
T9 N finisher wf (Saturday: list finishers -> card -> DM with gift; group congrats post).
T10 H edge cases + dry run on test group + review.

## Track B — channel + community flywheel (added 2026-11-06)
Loop: channel (reach) -> group challenge (trust) -> Nour DM (sale) -> stories with consent -> channel (proof).
T11 H channel weekly plan: 1 post/day, mix 🎥 Adam video (repurpose from Zernio/IG) · 💡 idea tied to week theme · 🧰 free tool · Sunday "join the challenge" (group invite link) · Thu proof story (verbatim, consented) · Sat soft product post matching theme.
T12 N same scheduler (target=channel row) — no new wf.
T13 N group invite link via GET /groups/{id}/invite (verify doc) for channel CTA.
