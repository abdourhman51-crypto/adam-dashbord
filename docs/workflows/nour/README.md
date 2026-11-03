# Nour (Adam DM Agent) — mirrored code nodes

Workflow `Adam DM Agent (Nour) - Zernio + GPT-5` (`gzFzs1tBI1XIjc3E`).
Mirrored, not authoritative: n8n is where it runs and has no diff.

| File | Node |
|---|---|
| `Prep-Agent-Input-DM.js` | `Prep Agent Input (DM)`: builds the system prompt, detects a keyword typed in DM, and adds platform history and the durable profile |
| `Extra-Rules-DM.js` | `Extra Rules (DM)`: pricing (has the final say), soft-selling rules, and the `profile` output field |
| `Takeover-Human-Active.js` | `Takeover: Human Active?`: pauses Nour for 30 minutes after the founder replies by hand |
| `Parse-and-Remember.js` | `Parse & Remember`: puts every URL on its own line and builds the `insight` saved to Supabase |
| `test.js`, `test_takeover.js` | offline checks against these files (`node test.js && node test_takeover.js`) |
| `supabase/20261103_follower_profiles.sql` | `follower_profiles`, `conversation_insights`, `noor_save_profile/get_profile/mark_customer` |
| `supabase/noor-inbox-rpc/index.ts` | edge function (adds actions `profile_get`, `profile_save`, `mark_customer`) |

## Flow (DM branch)

Ingest → Wait DM Debounce (40 s, so grouped messages get one reply) → Claim DM Batch →
Takeover: Recent Messages (Zernio, last 15) → Profile: Get → Takeover: Human Active? →
Human Took Over? (yes → cancel the job, stay silent) → … → Nour Agent → Parse & Remember →
Profile: Save + Send.

A founder reply is detected from Zernio as `direction: outgoing` with `sentVia: null`.
Nour's own sends carry `sentVia: "api"`.

## Notes

Pricing lives in `Extra Rules (DM)`. Its `fix()` overwrites the pricing block
built upstream, so a price edited only in `Build DM Prompt` never reaches Nour.

Secrets are redacted in this mirror. The live `Parse & Remember` still holds the
OpenRouter key in plain text, so it should be rotated and moved to an n8n credential.
The edge function reads `NOOR_TOKEN` from the environment here; the deployed copy
still has it inline.

Published 2026-11-03, active version `5cb1d44b` (durable profile).
Rollback: `59d4d3ab` (takeover), then `3513b436`, `0726ed21`, `0a12d0c4`, `fbe48f30`.
