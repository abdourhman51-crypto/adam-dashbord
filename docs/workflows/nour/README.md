# Nour (Adam DM Agent) — mirrored code nodes

Workflow `Adam DM Agent (Nour) - Zernio + GPT-5` (`gzFzs1tBI1XIjc3E`).
Mirrored, not authoritative: n8n is where it runs and has no diff.

| File | Node |
|---|---|
| `Prep-Agent-Input-DM.js` | `Prep Agent Input (DM)`: builds the system prompt, detects a keyword typed in DM, and adds platform history and the durable profile |
| `Extra-Rules-DM.js` | `Extra Rules (DM)`: pricing (has the final say), soft-selling rules, and the `profile` output field |
| `Takeover-Human-Active.js` | `Takeover: Human Active?`: pauses Nour for 30 minutes after the founder replies by hand |
| `Parse-and-Remember.js` | `Parse & Remember`: puts every URL on its own line and builds the `insight` saved to Supabase |
| `Pay-Alert-Build.js` | `Pay Alert Build`: a payment receipt goes to Telegram with ✅ product buttons and a ❌ button |
| `Pay-Process.js` | `Pay: Process` (webhook `GET /webhook/nour-pay`): confirm page, then a one-time decision, delivery through Zernio, and the customer mark |
| `Find-Silent-Chats.js`, `Build-Followup-Prompt.js` | one soft follow-up 20–23h after silence (inside Meta's 24h window); skips customers and chats the founder handled in the last 48h; a dedicated no-pressure scenario for people offered a product who didn't buy |
| `test*.js` | offline checks (`for t in test*.js; do node $t; done`) |
| `supabase/20261103_follower_profiles.sql` | `follower_profiles`, `conversation_insights`, `noor_save_profile/get_profile/mark_customer` |
| `supabase/20261103_payment_approvals.sql` | `payment_approvals`, `noor_create_approval/decide_approval/mark_delivered` |
| `supabase/noor-inbox-rpc/index.ts` | edge function (adds profile and approval actions) |

## Flow (DM branch)

Ingest → Wait DM Debounce (40 s, so grouped messages get one reply) → Claim DM Batch →
Takeover: Recent Messages (Zernio, last 15) → Profile: Get → Takeover: Human Active? →
Human Took Over? (yes → cancel the job, stay silent) → … → Nour Agent → Parse & Remember →
Profile: Save + Send.

A founder reply is detected from Zernio as `direction: outgoing` with `sentVia: null`.
Nour's own sends carry `sentVia: "api"`.

## Payment approval

1. Nour sets `payment_proof`, then `Payment Proof?` → `Approval: Create` (a random one-time token in Supabase) → Telegram with buttons.
2. A button opens a confirm page that changes nothing. The founder taps «نعم، أكّد».
3. `noor_decide_approval` updates only a `pending` row, so a second tap never sends twice. On approve it calls `noor_mark_customer`.
4. Delivery: on Messenger the PDF goes as a file, then the link. Instagram DMs take no PDF files, so they get the link only.
   Nour's static memory marks her `customer` (no follow-up), and Telegram gets a ✅ or ⚠️ report.

## Notes

Pricing lives in `Extra Rules (DM)`. Its `fix()` overwrites the pricing block
built upstream, so a price edited only in `Build DM Prompt` never reaches Nour.

Secrets are redacted in this mirror. The live `Parse & Remember` still holds the
OpenRouter key in plain text, so it should be rotated and moved to an n8n credential.
The edge function reads `NOOR_TOKEN` from the environment here; the deployed copy
still has it inline.

Published 2026-11-03, active version `2b2384b8` (payment approval + follow-up).
Rollback: `5cb1d44b` (durable profile), `59d4d3ab` (takeover), then `3513b436`, `0726ed21`, `0a12d0c4`, `fbe48f30`.
