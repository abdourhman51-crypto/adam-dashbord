# The Paid Snapshot — value test before green light

**Written:** 2026-08-12. **Design and analysis only. Nothing here has been
built, deployed, or applied to any prompt, function, workflow, or production
object.** This is the final review requested before build approval. It does
not re-argue `adam-paid-snapshot-contract.md` — it tests it, against the
specific standard the founder set: **not "does it contain more," but "does it
create real continuity without unnecessary cost or hallucination risk."**

**Result, stated up front so it is not buried:** the test found real,
irreplaceable value — but in less than half of what the prior design proposed.
**Two of the three clauses are cut. What survives is smaller, cheaper, and — for
its main remaining piece — does not need to be rewritten on a cycle at all.**
This is the outcome of applying the review honestly, not a hedge.

---

## The setup: one family, one message, three context conditions

**Constructed** (no real paid journey exists — same honesty marker as the
prior document). One underlying reality, examined under three different
context conditions, exactly as asked:

- Child, confirmed pattern: "نوبة الخوف عند الاقتراب من الماء" (`child_patterns`,
  `status='confirmed'`, `evidence_count=4`) — **this pattern is real and
  confirmed regardless of payment status**, because pattern confirmation is
  never payment-gated (`adam-context-contract.md` §Q3).
- Day ~13 of engagement. Week 1 was total refusal; the family (in the paid
  hypothetical) agreed an objective on day ~3: "خمس ليالٍ هادئة من سبع," now in
  `build` phase, `2 / 7` this window.
- **Today's message, identical in all three conditions:**
  > *"اليوم كانت ليلة صعبة، رجع يرفض حتى الاقتراب من الماء. خفت نكون رجعنا
  > للوراء."*

### A — Free (message + momentary context only)
Context: `CHILDREN` (name known) + `PATTERNS` (the confirmed pattern —
available to free too) + `RECENT_DAYS` (today + 2 prior) + buffer. No
`JOURNEY`, no snapshot — neither exists without a paid agreement.

**Constructed reply:**
> *"نوبة الخوف من الماء نمط عرفناه من قبل معه — ليلة صعبة واحدة مش تراجعاً، هو
> جزء من نفس النمط المعروف. جرّبوا الليلة تبقوا قريبين منه بلا محاولة تقريبه
> للماء، وشوفوا هل يهدأ أسرع."*

### B — Paid, no snapshot (A's context + JOURNEY)
Context: A's context + `JOURNEY` (`objective: خمس ليالٍ هادئة من سبع`,
`phase: build`, `progress: 2/7 window 7`).

**Constructed reply:**
> *"نوبة الخوف من الماء نمط عرفناه من قبل معه — ليلة صعبة واحدة مش تراجعاً عن
> الهدف اللي اتفقنا عليه. جرّبوا الليلة تبقوا قريبين منه بلا محاولة تقريبه
> للماء."*

### C — Paid + snapshot (B's context + the snapshot, original 3-clause design)
Context: B's context + `[مؤكد]` + `[اتجاه]` + `[قيد التجربة]` as specified in
`adam-paid-snapshot-contract.md`.

**Constructed reply:**
> *"ليلة صعبة، لكن قارنوها بالأسبوع الأول: يومها كان رفضاً تاماً للاقتراب من
> الماء أصلاً. الرفض الليلة نفس النمط المعروف، مش تراجعاً عن المسافة اللي
> قطعتوها. جرّبوا الليلة تبقوا قريبين منه بلا محاولة تقريبه للماء."*

**The first honest finding: B and A are nearly identical.** JOURNEY's
existence lets B gesture at "the agreed goal" but does not change the
*substance* of the reassurance, because B has no more evidence than A about
*how far the family has actually come* — JOURNEY carries only the current
window's progress, not the starting point. **Whatever value paid-without-
snapshot adds over free, for this message, is thin.**

---

## Question 1 — What can C say truthfully that A and B cannot?

Exactly one thing, and it is real: **the comparison to where the family
actually started.** *"يومها كان رفضاً تاماً… مش تراجعاً عن المسافة اللي
قطعتوها"* is a claim about distance travelled, and it requires knowing the
starting point — which does not exist in A (free, no history retained across
weeks) or B (JOURNEY only knows the current window, not week 1). This is the
one genuinely new capability, and it is specifically **reassurance grounded in
real evidence of progress**, which is close to the single most valuable thing
ADAM can say to a frightened, discouraged parent — a hedge word plus a real
number would not do this; only a real historical anchor does.

## Question 2 — What actually improves because of the snapshot?

**Emotional accuracy under a setback, specifically.** The moment this matters
is not routine turns — it is exactly turns shaped like this one: a report of
failure or relapse-fear, where the honest, useful thing to say requires
history B does not have. On an ordinary "vents" or "reports success" turn with
no relapse-fear framing, C's baseline sentence would often go unused —
consistent with the Context Utilization criterion already defined
(`adam-context-engineering.md` Part 9): **the value is real but conditional on
the message shape, not a constant per-turn improvement.**

## Question 3 — Can the snapshot make the reply worse?

**Yes, concretely, if it goes stale.** Construct the failure: the snapshot was
written on day ~13 and never refreshed. By day ~24, the family has actually had
a real regression — three consecutive hard nights, `RECENT_DAYS` shows it
plainly. A snapshot still asserting "2/7, building steadily" would produce:

> *"ليلة صعبة، لكن أنتم في مسار بناء واضح — 2 من 7 هذا الأسبوع."* (constructed,
> the FAILURE case)

This is **actively harmful** — false reassurance during a real regression,
worse than saying nothing, because it dismisses a parent's accurate read of a
worsening situation with outdated confidence. This is a stronger failure mode
than the prior document's abstract "stale trend" warning — it is a concrete
case where the *live* data (`RECENT_DAYS`, always fresh) and the *cached*
snapshot directly disagree.

**The fix this forces, added to the design, not previously stated as sharply:**
**a conflict-resolution rule — when `RECENT_DAYS` contradicts the snapshot's
directional claim, the live signal wins and the snapshot clause is suppressed
that turn**, not blended with it. This is mechanical (comparable to how
`gate_grounded_reply` re-derives `knowledge_depth` fresh rather than trusting
what the prompt claims): before rendering `[اتجاه]`/its replacement, check
whether the most recent 2-3 `RECENT_DAYS` entries move in the *opposite*
direction from the cached claim; if so, omit the clause that turn rather than
assert something the live data just contradicted. Cheap to compute (both
values are already being read), and it is the difference between a memory that
helps and a memory that lies confidently.

## Question 4 — Does the snapshot duplicate information already in the live context?

**Yes — and this is the finding that cuts the design down.** Checked clause by
clause against what A and B already carry:

- **`[مؤكد]` duplicates `PATTERNS`, entirely.** `PATTERNS` already sends "نوبة
  الخوف عند الاقتراب من الماء" to *both* A and B, structurally, live, every
  turn, more reliably than a cached rewrite of the same fact. `[مؤكد]` was
  designed to be sourced *from* `child_patterns.confirmed` — which means it is,
  by construction, always restating something the model was already just told
  by a fresher, more authoritative tier. **No scenario exists where deleting
  `[مؤكد]` costs ADAM a fact it otherwise would not have.** Cut.
- **`[اتجاه]` is half-duplicate.** Its second half — "…3 من 7 ليالٍ هذا
  الأسبوع" — restates `JOURNEY`'s own `progress: 2/7` field (a live, more
  precise, always-fresh number). Only its *first* half — the week-1 starting
  point — is genuinely absent from every other tier. **Cut the redundant
  half; keep only the historical-anchor half.**
- **`[قيد التجربة]` mostly duplicates `RECENT_DAYS`.** An experiment tried in
  the last 3 days is already visible there (`step_given`/`step_completed`
  fields). It is non-redundant **only** in the narrow window where the
  relevant attempt is *older* than 3 days and has not yet been repeated or
  promoted — a real but genuinely narrow condition, not a general "unproven
  experiments" tier as originally scoped. **Narrow the inclusion condition
  sharply; do not include it by default.**

## Question 5 — Does each of the three clauses have measurable effect on reply quality? (leave-one-out)

| Clause removed | Effect on the constructed reply above |
|---|---|
| Remove `[مؤكد]` | **No change.** `PATTERNS` already supplied the same fact to the reply; C's reply does not depend on `[مؤكد]` at all in this example. |
| Remove `[اتجاه]`'s redundant half (the current-window number) | **No change** — the reply never needed the repeated number; `JOURNEY` already had it. |
| Remove `[اتجاه]`'s historical-anchor half | **Large change.** C's reply collapses to B's — loses the entire "distance travelled" reassurance, the one thing this whole test found genuinely valuable. |
| Remove `[قيد التجربة]` | **No change**, in this example — nothing in the scenario fell into its narrow non-redundant window. A second constructed scenario (a parent asking "شنو نجرب بالضبط الليلة؟" 6 days after a tried-but-unrepeated tactic) shows real, if occasional, value: without it, ADAM either invents a new tactic or stays silent about one already agreed; with it, ADAM can say "لسّا ننتظر نجرب فكرة الماء الدافئ اللي حكينا عنها" — continuity, not invention. |

**Only one piece survives contact with a real leave-one-out test as
consistently load-bearing: the historical-anchor half of `[اتجاه]`.** The
tactical-continuity piece survives too, but conditionally and rarely.
Everything else measured zero marginal effect in the constructed cases and is
structurally guaranteed to measure zero, because it duplicates a fresher tier
by design, not by bad luck in this particular example.

## Question 6 — The smallest snapshot that keeps the real value

**One clause, not three — and it does not need to be regenerated on a cycle.**

The surviving value — "what did the starting point look like" — is a fact
about **the beginning of the journey**, which does not change once the journey
has begun. It does not need a recurring LLM rewrite; it needs to be **written
once**, when there is enough `observe`-phase data to characterize it (end of
observe, or day 3-5), and then **read unchanged for the rest of the stage's
life**. This removes the entire "update cycle" question for this piece: no
promotion/demotion machinery, no per-cycle write cost, no staleness risk for
*this* fact, because it is explicitly a historical snapshot of the past, never
a claim about now.

```
[نقطة البداية] في الأسبوع الأول: رفض تام للاقتراب من الماء، حتى مشاهدته من
بعيد كانت صعبة.
```
**Measured: 30 tokens** (`gpt-tokenizer`, cl100k_base) — vs. **89 tokens** for
the original three-clause design. A **66% reduction**, and per Question 5, the
66% that was cut was the 66% that measured zero effect.

**The tactical-continuity piece is optional and deferred, not shipped in v1:**
```
[تجربة سابقة لم تتكرر بعد] جرّبنا الوقوف على حافة الماء قبل 5 أيام، لم نعِد
المحاولة منذ ذلك الحين.
```
**Measured: 37 tokens**, included **only** when a real attempt exists that is
older than 3 days and unrepeated — genuinely rare given real production
logging density (`adam-context-engineering.md` Part 0: avg 1.6 logs per active
follower). **Recommendation: do not build this piece in v1.** Ship the
one-time baseline only; revisit this piece only if real paid-user data later
shows the 3-10-day continuity gap actually occurs often enough to matter — the
same "prove it with real data before building it" discipline this whole
review chain has followed, now applied to the snapshot's own second clause.

---

## The revised architecture this forces

Not "a snapshot that regenerates every W2 cycle." **A single field, written
once per stage, at the point `observe` phase has enough data to characterize
the starting point** (mirrors `notice_a_pattern`'s own evidence bar — do not
invent a new threshold). No ongoing write cost beyond that one call per paid
journey started. No decay/freshness machinery needed for it (it is
permanently and correctly a past-tense fact). The **conflict-resolution rule**
from Question 3 is the only new runtime logic: suppress the baseline clause on
any turn where `RECENT_DAYS` directly contradicts its direction.

This also resolves `adam-context-contract.md` §Q4's cost question more cleanly
than "scope W2 to paid users" did: **there is no recurring writer to scope at
all for the piece that survived.** One LLM call per paid journey, once, at
observe's end — not a per-cycle recurring cost, paid-scoped or not.

---

## Success criterion — when this is worth building

Falsifiable, not asserted:

1. **Utilization threshold.** In a real sample of paid-user turns shaped like
   "reports a setback" / "reports success" / "reports relapse fear" (the
   shapes Question 2 identified as where it matters), the baseline clause is
   actually referenced in the reply in **at least half** of the turns where it
   is present. Below that, it is decorative context, not used context, and
   should be cut regardless of how reasonable it looks on paper.
2. **Zero silent contradictions.** In that same sample, **zero** turns where
   the reply asserts something the baseline clause implies while
   `RECENT_DAYS` shows the opposite, uncaught. One such case is a bug in the
   conflict-resolution rule, not an acceptable error rate.
3. **Cost stays where Question 6 puts it.** One write per paid journey
   (not per cycle), ≤30 tokens read per turn for the surviving piece. If
   either grows because the "optional, deferred" tactical clause gets added
   back in without new evidence justifying it, the design has regressed to
   what this review just cut.

**If (1) fails on real data, the answer is not "make the clause more
prominent" — it is delete it and accept that the deletion test from the prior
document was answered too optimistically before real data existed to check
it.** This review's own conclusion is provisional on exactly the same
standard it applied to the design: prove it, or cut it.

---

*Design and analysis only. Nothing here has been applied to a prompt, a
function, a workflow, or production. This supersedes
`adam-paid-snapshot-contract.md`'s three-clause structure with the one-clause
(plus rarely-used second clause) design above — the prior document's reasoning
about epistemic tiers and anti-invention sourcing still holds and is not
re-argued, only its conclusion is narrowed by this test. Ready for the
founder's build decision.*
