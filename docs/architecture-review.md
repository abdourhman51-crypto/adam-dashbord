# ADAM — Pre-Implementation Architecture Review
**Date:** 2026-07-29
**Question:** Are there unresolved contradictions, missing systems, edge cases, or architectural risks that would force a redesign after implementation?
**Answer:** **Yes — twelve.** Eleven are resolved below. One remains a founder decision and is a hard gate.

---

## Verdict

| | |
|---|---|
| **Architecture-breaking issues found** | 12 |
| **Resolved in this document** | 11 |
| **Requiring founder decision** | 1 (D1 — human escalation routing) |
| **Scaling risks flagged, not blocking** | 3 |
| **Safe to implement after these fixes?** | **Yes, to pilot scale.** Not beyond, until D1 is settled |

Two of the twelve (**A1** the unbounded guarantee, **A4** the free/paid boundary) would have surfaced only after real customers were on the system, and would have forced a pricing-and-promise redesign with paying users already in flight. Those are the expensive kind.

---

# Part 1 — Contradictions that would have forced a redesign

## A1 🔴 The guarantee is unbounded, and it creates an incentive to lie

**What I specified:** *"إن لم نصل للهدف في اليوم الرابع عشر، أكمل معكِ بلا مقابل حتى نصل"* — I keep going free until we reach the objective.

**Three failures stacked on top of each other:**

1. **Unbounded liability on an unvalidated number.** Stage durations (14/21/30/45) are my reasoning, not your data — you have **21 `daily_logs` rows in total**. If my durations are optimistic, a large share of stages overrun, each one consuming daily LLM calls at zero revenue, with no defined end.
2. **No exit if she stops logging.** The objective is measured from her taps. A parent who drifts away mid-stage never "reaches" the objective, so the stage never closes. It just hangs open forever.
3. **It reintroduces the exact incentive I removed elsewhere.** I deliberately made the North Star count *logging*, not *calm nights*, so no parent feels pressure to misreport. Then I tied a free extension to reported outcome — handing her a reason to report hard nights, and handing a parent who likes ADAM a reason to report calm ones to please him.

### Fix — a bounded, automatic, honest promise

```
Stage ends, objective not met
   └─► ONE automatic extension: half the stage length, free
       Never requested. Never negotiated. ADAM computes and announces it.
          │
          └─► Still not met at the end of the extension
              ├─► ADAM says so plainly. No third extension.
              ├─► Full refund, offered automatically, unprompted
              ├─► Review flag raised (see A9)
              └─► No new paid stage proposed to this parent for 30 days
```

**Why automatic-and-unrequested kills the misreporting incentive:** she never has to claim anything, so there is nothing to game. Both the extension and the refund arrive on their own. Reporting a hard night gains her nothing she wasn't already going to receive.

**Countering the opposite distortion** (reporting calm to please ADAM): the stage report presents *logged* data explicitly framed as logged — never as clinical measurement — and ADAM's response to a hard night must stay as warm as his response to a calm one. That rule already exists (P3) and is now load-bearing for data integrity, not just kindness.

---

## A2 🔴 The stage clock was never defined, and three systems depend on it

The guarantee, the phase transitions, and the refund all depend on "day 14." I never said what a day is. Every one of these breaks it:

| Scenario | Undefined behaviour |
|---|---|
| Crisis on day 6 — stage pauses | Does the clock keep running? She loses 7 paid days |
| Travel, illness, Ramadan | Same |
| She logs 4 nights out of 14 calendar days | Is that a completed stage? |
| Payment confirmed 3 days after she paid | Did the stage start at claim or confirmation? |

### Fix — the clock counts logged days, not calendar days

**A 14-day stage means 14 days on which she logged.** This single change resolves the entire class:

- **Crisis:** clock stops automatically (no log is taken). Rescue continues. No special-casing needed.
- **Travel / illness / Ramadan:** self-handling. No pause feature required for short gaps.
- **Explicit pause** («أوقف مؤقتاً»): clock stops, all proactive messages stop, chat stays open. Max 60 days, then the stage auto-closes with a partial report of where she reached.
- **Payment:** the stage starts at **operator confirmation**, not at claim. Between the two she gets a holding message. **If confirmation exceeds 72h, the stage starts anyway** — she has paid and waiting is our failure, not hers.

It also makes the guarantee fair in both directions: we owe her 14 days of work, and she owes us 14 days of participation.

---

## A3 🔴 The metric contradicts the behavioural design — resolved, but only just

**The apparent contradiction:** Phase 3 (Hold) exists so ADAM deliberately fades. The North Star counts logging. Successful fading would therefore look like a metric decline, and any team optimising the NSM would be incentivised to **delete the phase that proves the change was real**.

**On re-reading my own spec, this dissolves** — but it dissolves on a single sentence that was never called out as load-bearing:

> Phase 3 stops the **19:15 prep**. The **21:00 log continues**: *«سأسأل في التاسعة كالعادة»*.

So logging does not drop in phase 3. What fades is ADAM's *initiative*, not her *participation*.

**Fix — promote this from an implementation detail to an architectural invariant:**

> **The nightly log is never removed by any phase, stage, tier, or state, except crisis and explicit pause.** It is the measurement spine of the entire product. No feature may be designed that reduces it.

I nearly shipped a metric that would have paid a team to remove the product's most important phase. Naming the invariant prevents that.

---

## A4 🔴 The free/paid boundary was never actually specified

I wrote "free = present, paid = anticipates" as a slogan and never turned it into a rule. Two contradictions were hiding under it:

1. **v1's principle says never withhold** — *«الوصفة تُعطى كاملة دائماً… الحبس مقابل الدفع هو أكبر قاتل للقيمة»*. So free ADAM answers everything fully.
2. **If free ADAM answers everything fully, what exactly is paid?** A determined free user sets a phone alarm for 19:15, asks "what do I do about bedtime tonight," and gets a full answer.

Without a crisp boundary, this gets decided ad hoc during implementation — by an engineer, in a prompt, differently each time.

### Fix — the boundary is initiative and measurement, never information

| Always free, unlimited, every country | Only during an active stage |
|---|---|
| Any question, any topic, **full answer, never withheld** | ADAM **initiates** before the flashpoint (19:15) |
| Rescue in any crisis | Coaching that **adapts to yesterday's logged outcome** |
| Nightly log (one/day) | **Pattern detection** across the stage |
| First Mirror (once per child, at 3 logged nights) | Mid-stage Mirror |
| The child's record (max 1/week) | Stage report |
| Parent Mirror (after 2+ completed stages) | A stated objective, and the promise behind it |

**Stated honestly:** a motivated free user can approximate the prep message with an alarm clock and a question. She cannot approximate tracking, pattern detection, or proof. **We are not selling information — we are selling initiative and measurement.** Naming the leak prevents a false belief that the free tier is defended; it isn't, and it shouldn't be.

---

## A5 🟠 "One stage at a time" collides with multi-child, which I deferred to "Later"

The record is per-child (*سجل يوسف*). The entity model has `Child` as `1:N`. But multi-child was pushed to "Later" in the roadmap. These cannot both be true — a parent with three children needs three records on day one, or the record is wrong the first time she mentions a second child.

### Fix — separate the data question from the focus question

- **Multi-child data is MVP.** `Child` entity, per-child record, per-child patterns. Not deferrable.
- **One active stage per *parent*** — not per child. The constraint is the parent's attention, which is the scarce resource. *«الانتباه المقسوم لا يغيّر شيئاً»*.
- **Free rescue covers every child, always**, with no stage required.
- ADAM asks which child only when genuinely ambiguous; otherwise infers from the name already in the record.

What moves to "Later" is **simultaneous stages**, and the honest answer is that it moves there *permanently* — it is a therapeutic constraint, not a missing feature.

---

## A6 🟠 ADAM could sell a stage for a problem that is already resolving

She logs three nights free, gets the First Mirror, and the trend is already improving — bedtime is settling on its own. Under the current spec, ADAM proposes a paid stage anyway.

**That is selling someone something they don't need**, by a companion they trusted with their child. It is the single fastest way to destroy the only moat this product has.

### Fix — a refusal rule

> ADAM must not propose a paid stage for any problem whose trailing-7-day trend is improving. He says so instead, and does nothing:
> *«يبدو أن هذا يتحسّن وحده. لا داعي لأن نعمل عليه الآن.»*

Cheap to implement, and it is the highest-trust moment available in the entire product — the companion who tells you *not* to buy.

---

## A7 🟠 The proposal cadence was never bounded

I created the rule *"guidance is free and proactive; the transaction is pull-only."* But I never said **how often ADAM may guide**. Propose once and never again, and revenue dies quietly. Propose whenever, and it is the pushing that already produced **8 offers and 0 clicks**.

### Fix — bounded guidance

| Rule | Value |
|---|---|
| First stage may be proposed after | First Mirror **+ 1 further logged day** |
| Never sooner than | 3 logged days after the previous stage's report |
| Frequency cap | **Once per 30 days**, per parent |
| Repeat cap, same problem | **3 lifetime**, then never again for that problem |
| Blocked entirely | 7 days after any crisis flag · 30 days after a failed stage · while the trend is improving (A6) |

---

## A8 🔴 Crisis detection runs on text — but voice is in the MVP

Crisis detection is specified on message content. Voice notes are a core MVP feature *because* distressed parents can't type. So the highest-risk disclosures arrive through the channel where detection is least reliable, and dialect transcription accuracy is already flagged as an open risk (R10).

**A missed crisis flag on a voice note is the most severe failure mode in this product.**

### Fix — fail safe toward containment

1. Crisis detection runs on the **transcript**, after transcription — not on text-only input.
2. Crisis keyword matching uses a **lower confidence threshold than normal routing**. Asymmetric on purpose: a false positive costs a gentle, unnecessary containment message. A false negative costs a child.
3. **If transcription confidence is low AND emotional markers are present, ADAM must not give a parenting step.** He asks her to confirm in her own words, or moves to containment.
4. **No behavioural advice is ever generated from a low-confidence transcript.**

---

## A9 🟠 There was no exit for a stage that simply doesn't work

My own open question Q1, never answered — and it became urgent the moment the guarantee existed. Some problems will not resolve through behavioural coaching, and persistent non-response is itself clinically meaningful information.

### Fix — the honest exit, and a rule against predatory follow-up

1. Objective missed → automatic extension (A1)
2. Missed again → plain statement, automatic refund, stage closed
3. **A review flag is raised** — persistent non-response may indicate a developmental, medical, or family-system issue outside ADAM's scope. Routes to the same human queue as crisis, lower priority
4. **No new paid stage proposed to that parent for 30 days**

Rule 4 matters more than it looks: without it, the natural product behaviour after a failure is to sell the next thing. That pattern is predatory and would be indefensible.

---

## A10 🟠 The record could expose exactly what the safety rule protects

The Heart Writer rule correctly refuses to store trauma — *«الذاكرة الناقصة أرحم ألف مرة من الذاكرة التي تجرح»*. But I then specified a retrievable document showing "what ADAM knows about your child," without ever saying what it may contain.

Worse: it is retrievable by **anyone holding the unlocked phone**. In a household where a parent has disclosed domestic violence, a document detailing her private conversations about her children is a genuine safety hazard.

### Fix

- **The record is a derived view, computed at request time** — never a stored document. Redaction rules therefore always apply, and can never drift or leak a stale copy.
- **It may contain only:** child behavioural patterns, what works, what triggers, stages completed, outcomes.
- **It may never contain:** anything in a crisis category, the parent's own disclosed violence, third-party abuse, bereavement detail, or any content the safety rule excluded.
- It is delivered **as a chat message, never a downloadable file**, and ADAM never sends it unprompted.
- It carries one line stating it is a behavioural record, not a health or family record.

---

## A11 🔴 There is no data erasure path anywhere in the architecture

Four documents, and not one specifies how a parent deletes her data. For a product holding intimate disclosures about identifiable children, this is both an ethical gap and — in several of your markets and for any future EU-resident user — a legal one.

### Fix

- Command **«احذف كل شيء»**, available always, free.
- ADAM confirms once, plainly, with no retention attempt and no guilt.
- Erasure covers: conversations, logs, patterns, records, child entities, stage history.
- Retained: a minimal anonymised payment record where legally required, and nothing else.
- **An active paid stage is refunded pro-rata on erasure**, automatically.

---

## A12 🟠 The nightly rhythm was specified as running forever

"Nothing pauses between stages" is right for continuity — but taken literally it means a parent who never buys another stage receives a message every night indefinitely. That will breach the block/mute guardrail (<2%) and, more importantly, it makes ADAM the thing she mutes.

### Fix — consent decay, never guilt

| Signal | ADAM's response |
|---|---|
| 5 consecutive ignored check-ins | Drops to **weekly**, says so once: *«سأخفّف — أسألكِ مرة في الأسبوع بدل كل ليلة. اكتبي لي متى شئتِ.»* |
| 4 consecutive ignored weeklies | **Stops proactive messages entirely**, says so once. Chat remains open forever |
| She writes at any point | Full rhythm resumes immediately, no comment on the absence |

**Never:** "we miss you", streak language, guilt, or any re-engagement sequence. This is the same restraint as the one-reactivation-per-lifetime rule from Blueprint v1.

---

# Part 2 — Entity model corrections

The v1 entity model predates the chapter architecture and is now wrong in three places.

### Add

| Entity | Key fields | Why |
|---|---|---|
| **Stage** | id, parent_id, child_id, problem_label, objective_text, objective_target *(structured)*, planned_logged_days, logged_days_completed, phase, status, started_at, completed_at, refunded_at | The chapter model has no container. `Journey` was the old 30-day object |
| **StageProposal** | id, parent_id, child_id, problem_label, proposed_at, outcome | Required to enforce the A7 cadence caps |
| **ErasureRequest** | id, parent_id, requested_at, completed_at | A11 |

**Stage.status enum:** `proposed · active · extended · completed · failed · paused · refunded`

### Change

- **`Journey` is deleted.** Replaced by `Stage`.
- **The record is a derived view, not a table** (A10) — computed from Child + Pattern + Stage at request time.
- **`Night.logged_day_index`** added — the stage clock counts these, not calendar dates (A2).

### Confirm unchanged

`Parent · Child · Flashpoint · Moment · Night · Step · Pattern · Mirror · Payment · Message · CrisisFlag`

---

# Part 3 — Scaling risks (flagged, not blocking)

These do not require architectural change now. They require a threshold and a watch.

| # | Risk | Bites at | Watch |
|---|---|---|---|
| **S1** | **Cost variance across stage lengths.** A 45-day Food stage and a 14-day Sleep stage cost the same $10, but ~3× the LLM calls — before any A1 extension | ~200 concurrent stages | Cost per completed stage, by problem |
| **S2** | **Founder is the payment rail and the crisis queue.** Both are one person | ~50 customers | Claim→confirm p50; crisis review latency |
| **S3** | **Two parents, one child.** One `platform_user_id` = one parent. 18.5% of the audience is male; co-parenting accounts will conflate data | When it appears in data | Watch for two adults in one conversation |

---

# Part 4 — The one thing still blocking

## D1 🔴 Where does a human escalation actually go?

Unchanged from Blueprint §29, and **now compounded three ways** — this review added two more paths into a queue that does not exist:

| Path | Source |
|---|---|
| Crisis disclosure (violence, self-harm, abuse, bereavement) | Blueprint F11 |
| **Low-confidence voice transcript with emotional markers** | **A8, new** |
| **Persistent stage failure suggesting something clinical** | **A9, new** |

All three route to "a human." That human has no owner, no SLA, no protocol, and no defined action.

**This is not a product decision and I will not invent one.** It carries duty-of-care and legal weight, and depends on your capacity and your markets.

**My recommendation:** implement everything else, run a pilot capped at a number of parents you can personally cover, and treat D1 as the gate on scaling past it. A pilot where you are personally reachable is a legitimate answer to D1. *"We will figure it out later"* is not, once volume exceeds what one person can hold.

---

# Verdict

**The architecture was not stable when you asked. It is now — to pilot scale.**

The eleven fixes above are all specification-level and none require rework of anything already agreed: the hook is still the child problem, the payoff is still the parent's transformation, crisis is still never billed, guidance is still free and the transaction still pull-only, and stages are still chapters in one relationship.

Two of the twelve would have cost real money to discover late. **A1** would have surfaced as unbounded free service and an unclosable stage backlog, with paying customers already in flight. **A4** would have been resolved silently and inconsistently by whoever wrote the prompts, and the free/paid line would have drifted until it meant nothing.

**Implementation can begin, under two conditions:**

1. The Week-0 correctness items from Blueprint §25 ship first — rotate credentials, fix the engagement counter and the 47 orphaned sessions, inject the price, cap message length. Without the counter fix, none of the metrics in this architecture are measurable.
2. **Scale is capped at what you can personally cover for D1** until the escalation path is defined.

---

**End of review. No implementation has begun.**
