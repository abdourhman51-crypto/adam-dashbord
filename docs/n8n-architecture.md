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

## 7. Telegram sending: HTTP Request, never the Telegram node

**All outbound Telegram messages go through `httpRequest` to the Bot API directly.** The `n8n-nodes-base.telegram` node is banned from this project.

**Why.** The Telegram node appends *"This message was sent automatically with n8n"* to messages. Setting `additionalFields.appendAttribution: false` does not reliably suppress it — verified against this instance. One line of platform boilerplate at the bottom of a Seed would undo the voice work in §0.7 and tell a parent, at the worst possible moment, that they are talking to an automation.

**This is not a workaround.** Every live production workflow already sends via `httpRequest`; the Telegram node was the exception, introduced by workflows built in this session. The convention is now uniform.

| Workflow | Was | Now |
|---|---|---|
| W3 Rhythm Sender | 2 Telegram nodes | 2 HTTP Request nodes |
| W4 Mirror Sender | 1 Telegram node | 1 HTTP Request node |
| Legacy Nightly Checkin | Already HTTP Request | Unchanged |
| W1 Router | `telegramTrigger` + HTTP Request | Unchanged — the trigger appends nothing |

### 7.1 The bot identity, now confirmed

Resolved from a real execution payload rather than guessed: the ADAM bot is **`8840311808`**, display name **ادم**, username **`adam_os_brain_bot`**. The long-standing "which Telegram credential is the ADAM bot" question is closed — and it no longer matters for sending, because the HTTP nodes address the bot directly.

### 7.2 The credential tradeoff, stated honestly

Telegram requires the bot token **in the URL path**, so no n8n credential type can inject it. That leaves three options, and none is clean:

| Option | Verdict |
|---|---|
| Telegram node with a credential | **Rejected** — appends attribution |
| `$env.ADAM_BOT_TOKEN` in the URL | **Correct long-term**, but fails silently if the variable is unset on the instance |
| Token literal in the URL | **What is built** — matches every existing production workflow, and is proven to work here |

**The token is in n8n's workflow JSON and is deliberately kept out of this repository.** It is the same exposure the live workflows already carry, not a new one — but it is still exposure.

> **The right sequence is: rotate the token (week-0 item 1), set it as an instance environment variable, then switch all five URLs to `$env`.** Doing that before rotation would just move an already-compromised secret to a tidier place.

**Supabase HTTP nodes are unaffected** — they use `predefinedCredentialType: supabaseApi`, which works because the key travels in a header.

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
| `situation_catalog` · `commit_situation` · `get_situation_batch` | **Applied and tested** — 6 tests |
| **W3 Rhythm Sender** | **Built, 11 nodes, inactive** — `Vb4ADCkPsevPRWRN` |
| **W2 situation detection** | **Built, 21 nodes, ACTIVE** — `7mTP12nVLS1Taokl` |
| **All Telegram nodes → HTTP Request** | **Done** — §7 |
| **Strain detection** | **Applied and tested** — 8 tests. `set_strain_level` · `commerce_allowed` · `get_strain_batch` |
| **W2 strain branch** | **Built** — W2 now 30 nodes, ACTIVE |
| **W1 Harvest handling** | **Done** — `CK - Update Step Status` now calls `record_harvest_answer()` |
| W4 rework | Partially — Telegram node converted, gender-neutral copy fixed |
| Legacy sender retirement | Blocked on W3 activation |

### 9.4 W1 — a live bug found while wiring the Harvest

`CK - Update Step Status` was doing:

```
PATCH /daily_logs?follower_id=eq.<id>&order=id.desc&limit=1
```

**That targets the newest row by `id`, not today's row.** A parent whose latest row is from a previous day gets *that* row overwritten when they answer tonight — the answer lands on the wrong date, and today's day is left with no result.

This is a strong candidate for why **23 of 25 rows carry no result** while the check-in was demonstrably being delivered. The answers were arriving; they were being written somewhere else.

**Replaced with `record_harvest_answer()`**, which targets `log_date = today in the parent's local timezone` and refuses unless a Seed was actually sent.

**Why this edit was safe on a live 89-node workflow serving parents right now:**

| Risk | Mitigation |
|---|---|
| A "no seed today" case erroring and breaking the reply chain | **Verified**: it returns `{recorded:false, reason:"no_seed_today"}` with HTTP 200, so `CK - Reply Step` still fires and the parent still gets their reply |
| Switching auth and logic together | **Auth deliberately left unchanged.** The node keeps its existing header credentials. Changing two things at once on a live system is how you get an outage you cannot diagnose — credential migration happens for all nodes at once during the week-0 rotation |
| Silent behaviour change | The old path was already failing to record; the new one records correctly or says why |

**Not yet migrated:** `CK - Save Night Result` (handles `ck_gen_*` from the legacy sender) and `CK - Save Hard Moment` carry the same wrong-row pattern. They die with the legacy sender rather than being rewritten, since the rhythm has no general "how was your night" question.

### 9.3 W2 — classification, not invention

The situation is what the entire timing model schedules against, so **the LLM classifies into a closed catalog and never creates one.**

| Layer | Guard |
|---|---|
| Prompt | A closed list of seven tokens, with `none` as a first-class answer |
| `SD - Validate Key` | Drops anything outside the catalog before it reaches the database |
| `commit_situation()` | **Takes the window from the catalog, never from the caller** |

**Three gates for one value, deliberately.** An invented situation would carry an invented window, and a wrong window means asking how bedtime went before bedtime happened — the exact defect §5.4 rule 2 exists to prevent. The database gate is the one that actually holds; the other two just keep bad turns out of the data.

**`none` is not a failure.** The prompt says so explicitly, because a model that feels obliged to answer will guess, and a wrong situation is worse than no situation.

**Promotion needs three independent observations** before a situation moves from `candidate` to `confirmed`. One passing remark should not set a family's daily rhythm.

**Note on the credential warnings.** Validation flags hardcoded Supabase keys in `HW - Get Heart Batch`, `HW - Heart Commit` and `HW - Write Child Name`. Those are pre-existing nodes, not introduced here — they are week-0 item 1, and rewriting them is part of the credential rotation rather than this change.

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
