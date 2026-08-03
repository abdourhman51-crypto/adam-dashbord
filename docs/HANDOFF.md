# HANDOFF — read this first in a new session

One file, so a new session does not replay the old one. Everything below is verified, not remembered.

## What ADAM is

Read in this order, and only as far as you need:

| File | What it settles |
|---|---|
| `docs/adam-architecture.md` | **Single source of truth.** Part 0 is the Business Constitution — founder-only |
| `docs/adam-experience-principles.md` | E1–E13 + a review of the live surface. **Proposal, not applied** |
| `docs/telegram-ux.md` · `conversation-engine.md` · `knowledge-engine.md` | The three layers, all applied to production |
| `docs/w1-review-and-redesign.md` | W1 review + execution log |
| `docs/batch5-child-name.md` | The name-capture bug and its fix |

## Live system

| | |
|---|---|
| Supabase | `aajqbmjasnbwwyvgrlzy` (Adam OS), Postgres 17.6 |
| n8n | `adam-voices-n8n.hawiyat.cloud` |
| **W1** Router + Agents | `42loY0bgUSwYmHFV` — 124 nodes, active |
| **W2** Knowledge Writer | `7mTP12nVLS1Taokl` — 30 nodes, every 2h |
| **W3** Rhythm Sender | `Vb4ADCkPsevPRWRN` — 11 nodes, hourly |
| **W4** First Mirror | `pj19WNHEqU4xDDjy` |

## State as of 2026-07-31

Numbers verified against production, not recalled:

```
parents 299 · children 71 · parents with a named child 69
knowledge_depth >= 1: 70 · get_situation_batch returns 70
```

W1 batches 1–3 applied: free conversation uncapped, ADAM no longer sells (فريق آدم referral behind the strain gate), the six-step funnel replaced by §9.1 first contact, menu + taps wired.

## Tests — run these before trusting anything

They need **no** database connection. That is the point.

```bash
PGBIN=$(ls -d /usr/lib/postgresql/*/bin | head -1)
DATA=$(mktemp -d); RUN=$(mktemp -d); chown postgres "$DATA" "$RUN"
su postgres -c "$PGBIN/initdb -D $DATA -U postgres --auth=trust"
su postgres -c "$PGBIN/pg_ctl -D $DATA -o '-k $RUN -p 55432 -c listen_addresses=' -l $DATA/log start"
export PGHOST=$RUN PGPORT=55432 PGUSER=postgres
psql -q -f supabase/tests/fixture_minimal.sql
for m in 20260731090000_telegram_surface_state 20260731120000_conversation_copy_and_button_law \
         20260731150000_knowledge_gate_and_uniqueness 20260731170000_child_name_capture; do
  psql -q -f supabase/migrations/$m.sql; done
for t in telegram_surface conversation_law knowledge_gate child_name; do
  psql -q -f supabase/tests/${t}_test.sql | tail -3; done
```

Expected: **21 + 37 + 25 + 29, zero failures.**

## Known traps

- **The n8n MCP refuses to bind `supabaseApi` to `httpRequest`.** n8n supports it; the tool does not. Put `authentication: predefinedCredentialType` in the node's `parameters` and attach the credential in the UI. Never write the key inline.
- **`update_workflow` takes atomic operations**, not SDK code — `addNode` / `addConnection` / `setNodeDisabled`. A whole batch fails or none of it lands. `setNodeParameter` cannot append to an array; replace the whole parameter.
- **A fixture that invents a column tests the fixture.** `is_supported` did not exist, the fixture created it, 21 assertions passed and every production `/start` returned 400. Copy columns from production, never from a migration comment.
- **Reading `$json` across an HTTP node loses it.** That silently discarded 68 extracted child names for months. Reference the upstream node explicitly.
- **`setNodeParameter`'s `path` is relative to the node's `parameters` object.** `/parameters/jsonBody` returns `appliedOperations: 1` with no error and changes nothing. `/jsonBody` is what lands. Re-fetch the node after every `setNodeParameter` call — the success response does not mean the write happened.
- **Founder-owned, still open:** rotate the exposed service-role key (plaintext ~116× in W1); attach `adam Supabase` to `HW - Write Child Name` and to the new `Gate - Agent Reply` node (added 2026-08-03, wires `gate_agent_reply` between `paid aget adam` and `FA - Send Reply1` — the credential field on `addNode` was tried and rejected by the MCP tool with "node type 'n8n-nodes-base.httpRequest' does not accept credential 'supabaseApi'", same trap as before); supply the vetted L3 referral directory (§16 D2).

## Next, in order

From `docs/adam-experience-principles.md` Part 4:

1. ✅ done — typing indicator
2. ✅ done — `/start` is one message
3. ✅ done — pin created on the first logged evening, edited in place thereafter
4. Derive the reply keyboard from state like every other surface
5. Menu body carries the surface content
6. Harvest reply composed + uniqueness-tested — the Peak-End moment is currently one fixed string

**1–3 are live. 6 changes what she remembers and is the next one worth doing.**

**Credential still to attach in the n8n UI:** `Pin - Load`, `Pin - Surface`, `Pin - Remember` (plus the earlier fifteen).

Open founder decision: «شيء آخر» on every button set — see Part 3 F9.

## Branch

`claude/install-product-skills-ayvz5e`. Commit and push there; never to the default branch.
