# Nour (Adam DM Agent) — mirrored code nodes

Workflow `Adam DM Agent (Nour) - Zernio + GPT-5` (`gzFzs1tBI1XIjc3E`).
Mirrored, not authoritative: n8n is where it runs and has no diff.

| File | Node |
|---|---|
| `Prep-Agent-Input-DM.js` | `Prep Agent Input (DM)` — system prompt + keyword-in-DM detection |
| `Extra-Rules-DM.js` | `Extra Rules (DM)` — pricing (final say), soft-selling rules, reminders |
| `Parse-and-Remember.js` | `Parse & Remember` — puts every URL on its own line before sending |
| `test.js` | `node test.js` — 34 offline checks against these three files |

Pricing lives in `Extra Rules (DM)`: its `fix()` overwrites the pricing block
built upstream, so a price edited only in `Build DM Prompt` never reaches Nour.

`Parse-and-Remember.js` has the OpenRouter key redacted here. The live node
still holds it in plain text (and copies it into every execution's data as
`orKey`/`elevenKey`) — it should be rotated and moved to an n8n credential.

Published 2026-11-03, active version `0726ed21` (adds stored history to the
agent's system prompt). Rollback: `0a12d0c4`, then `fbe48f30`.
