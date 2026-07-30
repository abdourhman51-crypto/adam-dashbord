# ADAM — n8n Architecture

**Layer 4 of 12** in the build order (`docs/adam-architecture.md` §1.5).
**Governing constraint:** *n8n is the nervous system — it moves and schedules, it does not decide what is true.*

---

## 1. The rule that determines everything below

> **Every decision lives in SQL. n8n carries messages and obeys.**

An n8n Code node that decides *who* gets a message, *whether* they are eligible, or *what* the rules are is a second source of truth — and this project already paid for that: four workflows each maintaining their own view of a parent's state is how `message_count` sat frozen at 0 while parents were actively conversing.

**The test for any logic before it goes into a workflow:**

| Question | If yes |
|---|---|
| Would two workflows need this same logic? | **SQL.** Duplicated logic diverges |
| Must it give the same answer twice? | **SQL.** §2.2 tier 1 |
| Does it decide eligibility, timing, or suppression? | **SQL.** These are truths, not transport |
| Is it formatting, HTTP, or retry? | **n8n.** That is transport |

---

## 2. Target topology — four workflows

| # | Workflow | Engine | Trigger | Owns |
|---|---|---|---|---|
| **W1** | **Router** *(Machine 1+2, evolved)* | Conversation | Telegram webhook | Every inbound: text, voice, button callbacks |
| **W2** | **Knowledge Writer** *(Heart Writer, evolved)* | Knowledge | Every 2h | Extracting child, situations, patterns from conversation |
| **W3** | **Rhythm Sender** *(new)* | Journey | Hourly | Seed and Harvest delivery |
| **W4** | **Mirror Sender** *(rework)* | Journey | Daily | The Mirror when three results exist |

**Four workflows doing more than the current five.** Fewer moving parts is the point: every workflow is a place where a rule can drift from the schema.

### 2.1 Growth Engine has no workflow, deliberately

Every other engine appears above. Growth does not, and that absence is a structural guarantee rather than an omission.

> **There is no scheduled job that can send a commercial message, because none exists to be misconfigured.**

Growth owns **surfaces** — the menu, the pinned message, the changing item — which are read when the parent opens them, and **stage 4 of the review session**, which is delivered by W1 in response to a journey ending. Nothing in Growth runs on a clock.

**This is what makes "ADAM never pushes" enforceable rather than aspirational.** The old model's Silent Seller, Judge and Renewal Guard were all scheduled jobs. Removing the category removes the failure mode.

---

## 3. Why the Seed and the Harvest are one workflow, not two

They run at different hours and say different things, so two workflows looks natural. It is wrong.

Both need: the parent's true local time · the situation's window · strain level · quiet hours · paused state · cadence. **Splitting them puts that logic in two places, and two copies of a rule are one divergence waiting to happen.**

**Resolution:** the shared logic goes to SQL as a single function that returns *who is due and for what*:

```
get_rhythm_due()  →  rows of { parent_id, action: 'seed' | 'harvest', … }
```

W3 then does no deciding at all — it branches on a column and sends. **The decision is one function; the delivery is one workflow.**

---

## 4. What each workflow may and may not do

### W1 — Router

**May:** receive updates · route by callback prefix · call the agent · render replies · call SQL to record.
**May not:** decide eligibility · compute timing · hold conversation state outside Knowledge · **speak a price** (P17).

The Telegram bot holds exactly one webhook, so all inbound traffic must land here. That is a platform constraint, not a design choice, and it is why W1 is the largest workflow.

### W2 — Knowledge Writer

**May:** read recent conversation · extract structured facts · write via Knowledge functions.
**May not:** write anything a parent disclosed into the memory that feeds proactive messages (§2.8, provenance rule) · invent a child's name · store crisis content.

**Extended beyond today's Heart Writer** to also detect **situations** — the recurring moment with its window — which the timing model cannot work without.

### W3 — Rhythm Sender

**May:** call `get_rhythm_due()` · compose from the returned grounding · send · record.
**May not:** decide who is due · pick a time · send when `can_ground` is false.

> **If the Knowledge gate returns false, W3 sends nothing.** Silence is the correct output, and it is recorded as such so principled silence stays distinguishable from a broken scheduler.

### W4 — Mirror Sender

**May:** find parents owed a Mirror · generate from their own data · send.
**May not:** attach any price or offer — already enforced by database constraint, so the workflow cannot violate it even if edited carelessly.

---

## 5. Migration from what is running now

| Current | Verdict | Why |
|---|---|---|
| `ADAM - Machine 1+2` **(active)** | **Evolve → W1** | It is the product. It holds the only webhook |
| `ADAM - Heart Writer` **(active)** | **Evolve → W2** | Only writer of `children`; `light_memory` covers 129 parents |
| `Adam - Nightly Checkin` **(active)** | **Retire** when W3 ships | Carries the Egypt +2 bug; superseded by the rhythm |
| `ADAM · Check-in Sender v2` **(inactive)** | **Superseded before it ever ran** | See below |
| `ADAM · First Mirror Sender` **(inactive)** | **Rework → W4** | Schema underneath it changed |

### 5.1 Check-in Sender v2 was built for a product that no longer exists

It was written, tested and left inactive pending a credential. Between then and now the model changed: a single nightly check-in became a **Seed in the morning and a Harvest after the situation closes**, timed per situation rather than at a fixed local hour.

**Its timezone work is not wasted** — resolving a parent's true local evening via IANA zones is exactly what `get_rhythm_due()` must do, and that logic moves into SQL where both halves of the rhythm can share it. **The workflow is retired; the correctness it proved is kept.**

*(The bug it was built to fix is still live: the legacy sender hardcodes Egypt at +2 against a real +3, so the largest market is messaged an hour early every night. That ends when W3 ships, not before.)*

---

## 6. Scheduling

| Workflow | Cadence | Why not more often |
|---|---|---|
| W3 Rhythm Sender | **Hourly** | Situation windows are hour-granular. Finer buys nothing and multiplies executions |
| W4 Mirror Sender | **Daily** | The Mirror is data-gated, not time-sensitive |
| W2 Knowledge Writer | **Every 2h** | Extraction is not urgent; conversation is the urgent path |
| W1 Router | **Event** | Webhook |

**Ceiling enforced in SQL, not in the schedule:** one Seed and one Harvest per parent per day (§5.4 rule 4). An hourly trigger that ran twice would still not double-send, because `get_rhythm_due()` excludes anyone already sent today.

---

## 7. Credentials

Every HTTP node uses a stored credential. **No hardcoded tokens.**

The live workflows currently embed the Supabase service-role key and Telegram bot tokens in plaintext inside workflow JSON — which is week-0 item 1 and still open. W3 and W4 are built with credentials from the start; W1 and W2 are cleaned during their evolution.

---

## 8. Build order within this layer

1. `get_rhythm_due()` — **the decision function.** Designing a workflow without knowing what it calls is hand-waving
2. W3 Rhythm Sender against it
3. W1 Router: Harvest response handling
4. W2 Knowledge Writer: situation detection
5. W4 Mirror rework
6. Retire the legacy sender

**Step 1 is done and tested** (§9). The rest follows.

---

## 9. Status

| Item | State |
|---|---|
| `get_rhythm_due()` | **Applied and tested** — 5 tests |
| `record_seed_sent` · `record_harvest_sent` · `record_harvest_answer` | **Applied and tested** — 6 tests |
| **W3 Rhythm Sender** | **Built, 11 nodes, inactive** — `Vb4ADCkPsevPRWRN` |
| W1 Harvest handling | Not built |
| W2 situation detection | Not built |
| W4 rework | Not built |
| Legacy sender retirement | Blocked on W3 activation |

### 9.1 W3 — what shipped

**The workflow decides nothing.** It calls `get_rhythm_due()`, branches on the returned `action`, and delivers. Every rule — timezone, window, strain, quiet hours, the daily ceiling, the Knowledge gate — is in SQL where both halves share it.

**Two details worth recording:**

**`appendAttribution` is explicitly false.** The Telegram node defaults it to *true*, which would append *"This message was sent automatically with n8n"* to every Seed and Harvest. Left at its default it would have undone the voice work in one line.

**The Harvest reuses the existing `ck_step_*` callbacks** rather than introducing new ones. The live router already handles them, so the buttons work the moment W3 activates — no window where a parent taps a dead button while W1 catches up. The pair still closes correctly because the constraint only requires that a Seed was sent. W1's evolution then upgrades the handler to route through `record_harvest_answer()`, which adds the Aha logging and the consent reset.

### 9.2 Before W3 can run

| Step | Owner |
|---|---|
| Attach **adam Supabase** to 3 HTTP nodes: `Who Is Due Now`, `Record Seed Sent`, `Record Harvest Sent` | **Founder** |
| Confirm **Telegram account** is the ADAM bot, not the survey bot | **Founder** |
| Activate, watch one cycle, then deactivate `Adam - Nightly Checkin` | **Founder** |

The MCP refuses to attach `supabaseApi` to an HTTP Request node although n8n supports it — the live legacy sender uses exactly that pattern in production. It is a tool limitation, not an n8n one, and substituting a credential whose contents cannot be verified risks 401s against live data to save three clicks.

**Nothing will send on activation until a situation exists**, because `can_ground_seed()` returns false for every parent today. That is the correct behaviour, and it makes W2's situation detection the next thing that matters.
