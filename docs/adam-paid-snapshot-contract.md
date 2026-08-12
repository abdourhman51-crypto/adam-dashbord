# The Paid Snapshot — ADAM's memory across time

**Written:** 2026-08-12. **Design and analysis only. Nothing here has been
built, deployed, or applied to any prompt, function, workflow, or production
object.** Builds on `docs/adam-context-contract.md` §Q4/§Q5, which established
the snapshot's budget (~123-150 tokens) and freshness principle (durable vs.
state facts) at the block level. This document goes one level deeper, as asked:
**not a chat summary — a memory model**, with an explicit epistemic structure,
an update algorithm, decay rules, and the one test that decides whether it
ships at all.

**Zero real paid journeys exist** (`stages` count = 0, confirmed again this
pass). Every example below is **constructed**, built from real schema and real
computed values the engine already produces (`stage_state()`, `child_patterns`,
`daily_logs`) — never invented content, but not observed content either. Marked
CONSTRUCTED throughout, same discipline as `adam-constitution.md` Case F.

---

## The core design decision, stated first

A memory that blends fact, trend, and hunch into one undifferentiated paragraph
— which is what the four real July examples do — is *readable* but not
*trustworthy*: nothing in the text tells the model, or an auditor, which clause
is proven and which is a guess. The design below fixes this with **three
explicit, separately-sourced clauses inside the one text field**, each tagged
with the same bracket convention the codebase already uses for `[ما نعرفه عن هذا
البيت]`/`[الرحلة]`:

```
[مؤكد]        <a fact from a row already marked confirmed>
[اتجاه]        <a direction, computed by comparing two real time windows>
[قيد التجربة]  <a single-occurrence attempt, explicitly marked unproven — absent if none>
```

The load-bearing property this buys: **each clause has exactly one legitimate
source, and that source is a table already read elsewhere in the system.** The
writer's job stops being "summarise the relationship" (open-ended, invention-
prone) and becomes "render three already-true facts into one sentence each"
(closed, mechanical). This is the direct answer to "how do we guarantee it
doesn't invent" — not a rule told to the writer, a constraint on what it is
given to work with.

---

## 1 — What it must contain

| Clause | Content | Source (already exists, already tested) |
|---|---|---|
| `[مؤكد]` | The core challenge, and any pattern that has actually reached `status='confirmed'` | `child_patterns` where `status='confirmed'`, `situations` where `status='confirmed'` |
| `[اتجاه]` | A direction — behavioral or emotional — computed from two real time windows, never asserted from impression | `stage_state()`'s `objective_current`/`window_filled` (behavioral), or `daily_logs.guardian_mood` compared oldest-vs-newest logged (emotional) |
| `[قيد التجربة]` | The most recent tactic tried, explicitly marked as not yet proven — **absent entirely if nothing is currently being tried** (see phase-awareness, §7) | `daily_logs.step_given` with `step_completed` still null, or only one occurrence so far |

Nothing else. No raw event list, no full log dump, no free-text "notes" field —
each of the three clauses is written by rendering one already-computed fact,
not by the writer deciding what seems important.

## 2 — What it must never contain

- **Anything not traceable to one of the three sources above.** If the writer
  cannot cite which row a clause comes from, the clause does not get written —
  this is the actual anti-invention mechanism, restated as a hard constraint,
  not a style guideline.
- **A restated confirmed pattern list** (cut already, `adam-context-contract.md`
  §Q2/§Q4) — `[مؤكد]` names the *current* core challenge, once, not an
  enumeration; the structured `PATTERNS` tier still owns the full list.
- **Raw counts, dates, or IDs** — `[اتجاه]` says "من رفض تام إلى قبول جزئي," not
  "objective_current=3, window_filled=7" — the number is the *source* of the
  sentence, not something copied verbatim into it (verbatim numbers invite the
  exact "day N of M" framing the Constitution already forbids ADAM from saying
  aloud; the snapshot must not hand the model that phrasing pre-built).
- **A prediction or a plan for what ADAM should say** — the snapshot describes
  *what is true*, never *what to do*. "يحتاج تشجيعاً أكبر" is an instruction in
  disguise; "لا يزال يرفض الاقتراب" is a fact. Only the second belongs here —
  deciding what to do with it stays the reply's job, per the Constitution's
  own separation between context (facts) and directive (permission line).
- **Anything about payment, price, or the subscription itself.**
- **The parent's or child's raw emotional quote** verbatim from a message —
  the trend is *derived from* `guardian_mood`/logged outcomes, not a copy-paste
  of something painful the parent typed once. Compression means the writer
  never needs to touch the raw conversation text at all; it reads structured
  rows only.

## 3 — Confirmed fact vs. trend vs. unproven experiment — how it tells them apart

Not by the writer's judgment call. By which table the clause is drawn from,
mechanically:

| Epistemic status | Definition | How it is detected | How it reads |
|---|---|---|---|
| **Confirmed** | A `child_patterns`/`situations` row has *already* crossed the product's own confirmation bar (`status='confirmed'`, the same bar `knowledge_depth()` uses for level 2-3) | A `select` against that table, nothing inferred | Definite, no hedge: "التحدي الرئيسي: …" |
| **Trend** | A comparison across ≥2 real time windows shows a consistent direction, but no single row has been marked `confirmed` *for the trend itself* (the trend is a pattern-of-patterns, not yet a named pattern) | `stage_state()`'s window progress, or oldest-vs-newest `guardian_mood`/`night_result` | Explicitly comparative: "من X إلى Y" — never a bare present-tense state |
| **Unproven / tried** | Exactly one occurrence exists — a step was given, outcome not yet known, or tried once | `daily_logs.step_given` with `step_completed is null`, or a single matching row | Explicitly marked: "…جُرِّبت مرة واحدة، لم نرَ نتيجة بعد" — the hedge is mandatory, not optional |

This is the same discipline the Constitution already requires of ADAM's *reply*
voice (confidence calibrated to evidence) applied one layer earlier, to what
gets *written into memory* — consistent with the whole system's one governing
rule, not a separate invention for this document.

## 4 — How it changes when new information appears

**Full regeneration, never append.** Each write cycle re-reads the three
sources fresh and rebuilds all three clauses from current truth — the old text
is discarded, not edited or extended. This is the only way to guarantee the
snapshot never accumulates stale clauses no one remembers to remove; a diary
that only grows is not a memory, it is a log, and logs are exactly what Tier 3
exists to *not* be (`adam-context-engineering.md` Part 7: "source, not
context").

**Promotion, concretely:**
- `[قيد التجربة]` → `[اتجاه]`: once a second and third real data point appear
  showing the same direction (e.g. the same tactic logged 2-3 times with a
  consistent outcome), the clause moves from "tried once, unproven" language
  into comparative trend language.
- `[اتجاه]` → `[مؤكد]`: only when the *underlying row itself* — `situations` or
  `child_patterns` — is marked `status='confirmed'` by the existing product
  logic (evidence_count reaching its threshold). The snapshot writer does not
  decide this; it only reflects a decision the product already made elsewhere,
  closing the single-source-of-truth loop from `adam-context-contract.md` §Q5.

**Replacement:** if a tried tactic did not repeat (no second data point by the
next cycle), `[قيد التجربة]` is simply overwritten by whatever is being tried
*now* — an abandoned experiment is not memorialised, because it is no longer
true that it is being tried.

## 5 — How it stops itself from holding onto stale information

Per-clause decay, because the three clauses age at different real rates:

- **`[مؤكد]`** — persists as long as the underlying row stays `confirmed`. If
  the product later marks the pattern `resolved`, the clause is **not
  dropped** — it is reframed to the past: "كان التحدي الرئيسي… وتحسّن." A
  resolved challenge is still true relationship history and often the single
  most encouraging thing ADAM can reference. If marked `dormant`, the clause
  **is dropped** — dormant means "not currently relevant," and carrying it
  forward would be stale specificity with nothing behind it right now.
- **`[اتجاه]`** — carries an implicit freshness window: if no new data point
  (no new `daily_logs` row, no `stage_state()` progress change) has landed
  since the *previous* write cycle, the trend clause is **not repeated
  verbatim** — it reverts to a neutral absence ("لا تحديث جديد منذ آخر ملاحظة")
  rather than restating a direction that may no longer hold. A trend is a
  claim about *recent* movement; repeating it after a silent stretch turns it
  into exactly the kind of stale-but-confident claim Part 0.4 warns against.
- **`[قيد التجربة]`** — the shortest shelf life by design: if it is not
  promoted or replaced within the *next* write cycle, it is dropped, not
  carried forward as "still trying X" when nothing happened. An experiment
  that produced no second data point is not memory-worthy; it is noise.

## 6 — How it guarantees it doesn't invent during compression

Answered structurally above (§1's source column), restated as the actual
guarantee: **the writer never reads free conversation text.** Its only inputs
are the three structured queries in §1's source column — already-computed,
already-tested values the rest of the system relies on (`stage_state()` is
live-tested via `journey_step_test.sql`; `child_patterns`/`situations`
confirmation is the same gate `knowledge_depth()` already enforces). A model
asked to phrase a given fact in one sentence has nothing to invent from; a
model asked to "summarise this family's month" does. This is the difference
between a *renderer* and a *summariser*, and it is the whole reason this
document proposes the former.

A secondary, optional check (not required to ship, named for completeness): a
lightweight post-write fidelity pass — does every proper noun / claim in the
generated clause appear in the source rows it was built from — the same
"Compression Fidelity" audit `adam-context-engineering.md` Part 9 already
proposed, now made concrete because the source is now a fixed, small set of
fields rather than an open-ended table scan.

## 7 — Phase-awareness: the snapshot's own shape changes with the journey

Mirrors `compose_journey_step`'s phase discipline (the same single source of
phase truth, `stage_state()`, per `adam-constitution.md` Part 6 item 5 —
not a second, independently-written phase story):

| Phase | `[مؤكد]` | `[اتجاه]` | `[قيد التجربة]` |
|---|---|---|---|
| **Observe** | present if a pre-existing confirmed situation carried over from free | usually **absent** — not enough data yet, stated honestly | present — this is where early experiments live |
| **Build** | present | present — this is where it earns the most | present |
| **Hold** | present, often reframed toward resolution | present — describing stability, not change | **absent, always** — nothing new is being tried in hold by design, so nothing belongs here |

## 8 — Ideal size

**Measured, real (`gpt-tokenizer`, cl100k_base, same method as
`adam-context-contract.md`):**

| Example | Chars | Tokens |
|---|---|---|
| Week 1 (below) | 237 | **92** |
| Week 2 (below) | 257 | **89** |
| Hold-phase (2-clause) | 157 | **60** |

All three land comfortably under the ~150-token budget the prior contract
allotted — the three-clause structure is not more expensive than the
undifferentiated prose it replaces; the July real examples measured 123-142
tokens for less epistemic clarity. **Target: ≤120 tokens typical (2-3
clauses), ≤160 tokens hard ceiling** (a rich build-phase case with all three
clauses at full length).

---

## 9 — CONSTRUCTED example: the same family, week 1 → week 2

Same family as `adam-context-engineering.md` Part 6 (خمس ليالٍ هادئة من سبع,
swimming fear). **Constructed — no real paid journey exists to observe.**

### Week 1 (day ~6, observe→early build)

```
[مؤكد] التحدي الرئيسي: خوف من الاقتراب من حمام السباحة، يترجم أي تشجيع كضغط
يهدد أمانه.
[اتجاه] لا اتجاه واضح بعد — لا زلنا في أول أيام المراقبة.
[قيد التجربة] مشاهدة حمام السباحة من بعيد قبل النزول — جُرِّبت مرة واحدة، لم
نرَ نتيجة بعد.
```
92 tokens. Notice `[اتجاه]` is an **honest absence stated in words**, not
omitted silently — because at this point in the relationship there genuinely
is no direction yet, and §2 forbids inventing one.

### Week 2 (day ~13, build phase, one promotion + one replacement)

```
[مؤكد] نوبة الخوف عند الاقتراب من الماء نمط مؤكد الآن (تكرر 4 مرات). التحدي
الرئيسي لم يتغيّر.
[اتجاه] من رفض تام الأسبوع الأول إلى قبول الوقوف على حافة الماء 3 من 7 ليالٍ
هذا الأسبوع.
[قيد التجربة] الاستعداد لتجربة النزول التدريجي بماء دافئ الأسبوع القادم.
```
89 tokens. What changed and why:
- `[مؤكد]` gained a second sentence — the *situation* (already known week 1)
  produced enough evidence to become a *confirmed pattern* (§4 promotion rule,
  triggered by the product's own `child_patterns` confirmation, not the writer).
- `[اتجاه]` went from an honest null to a real comparative claim — because
  `stage_state()` now has two real windows to compare (§3's mechanical
  detection, not impression).
- `[قيد التجربة]` was **replaced**, not extended — week 1's "watch from a
  distance" either succeeded into the trend above or was abandoned; either way
  it does not linger as still-current (§5's decay rule).

### Hold phase (day ~24, CONSTRUCTED, for completeness)

```
[مؤكد] نوبة الخوف عند الاقتراب من الماء نمط تحسّن ملحوظ، لم يعد التحدي
الرئيسي.
[اتجاه] 5 من 7 ليالٍ هادئة — الهدف المتفق عليه شارف على التحقق دون تدخل جديد.
```
60 tokens. `[قيد التجربة]` is **absent entirely** (§7) — hold proposes nothing
new, so the snapshot carries nothing new either. The shrinking size across the
three examples (92→89→60) is itself the intended shape: the snapshot thins as
the family needs ADAM less, the same arc the Constitution's Journey Awareness
section already describes for the reply voice, now true of the memory feeding
it too.

---

## 10 — The deletion test

**"If we deleted the snapshot entirely, what exactly would ADAM lose?"**
Answered against what the *other* tiers already cover, concretely — not
asserted:

| Already covered elsewhere (snapshot deletion loses nothing here) | Genuinely lost if deleted |
|---|---|
| The confirmed pattern itself — `PATTERNS` tier sends it structurally, every turn | **The emotional/behavioral arc across weeks** — `RECENT_DAYS` covers only the last 3 logged days; a family 20 days in has 17 days of trajectory nowhere else visible |
| The formal agreed objective — `JOURNEY` tier already carries `objective_text` every turn | **The causal narrative connecting events over time** — why a tactic was tried, what it responded to — `PATTERNS`/`RECENT_DAYS` give isolated facts, never the story linking them |
| The current knowledge level and what may be claimed — the permission line, every turn | **Continuity for a parent returning after a gap** — the buffer (Tier 2) is per-session; a parent back after 4 days has an empty buffer and, without the snapshot, ADAM meets them as if for the first time despite 20 days of real history |
| — | **Tactical experiments not yet promoted to a confirmed pattern or the formal objective** — `[قيد التجربة]`-class facts have no other home; `RECENT_DAYS`'s 3-day window drops them the moment they age past 3 days |

**The answer is not "nothing important."** Four specific, real things are lost,
and none of them is reconstructible from the other tiers on demand — they are
each about *time*, which is precisely what a fresh-every-turn structured read
cannot represent no matter how complete it is.

**Do these four things justify the cost?** The cost, concretely: ~89-160
tokens/turn (measured, §8) for **paid users only**, written by an LLM call
scoped to fire only on a paid follower's cycle (`adam-context-contract.md`
§Q4's recommendation — real-world cost is $0 until the first paid signup). Set
against that: these four things are not incidental nice-to-haves — they are,
specifically, **what "continuity across time" means as a product feature**, the
exact thing `adam-context-contract.md` §Q3 already identified as the one
legitimate reason paid context differs from free at all. Deleting the snapshot
would not just shrink context — it would delete the one thing being sold.
**The design passes its own test.**

---

*Design and analysis only. Nothing here has been applied to a prompt, a
function, a workflow, or production. Still open, unchanged from the prior
document: the founder's cost decision on scoping the writer to paid-only
followers, and confirming the buffer-size mapping against the live n8n node.
No new open items were introduced by this pass — this document only sharpens
what Tier 3 contains and how it behaves, not whether or when it is built.*
