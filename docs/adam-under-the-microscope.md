# ADAM under the microscope — role, boundaries, and why it hallucinates

**Written:** 2026-08-11. **The analysis below is approved** (founder, 2026-08-11).
**The Contract section is the ratified definition — read it first if you are
building.**

## Build status — 2026-08-11

**Built and offline-tested (31 new assertions, `grounded_reply_test.sql`; zero
regression across all 31 suites). NOT deployed to production — staged for
review.**

| Piece | Migration | What it does |
|---|---|---|
| `gate_grounded_reply(uuid,text)` | `20260811190000` | The guardrail itself: blocks memory-announcement, past-session-reference, and unfounded repetition/count claims. Calibrated against all 2,378 real replies in `n8n_chat_histories` — two real false-positive classes found and designed around (see the migration's own header). |
| `gate_agent_reply` extended | `20260811190000` | Calls `gate_grounded_reply` internally; zero n8n change — same node, same call. Vocabulary/commercial checks untouched. |
| `get_agent_context` extended | `20260811170000` | Adds a `JOURNEY` facts block (objective/phase/progress) for a parent with a live stage, via `stage_state()`. Absent for free parents. |
| `get_agent_bundle` extended | `20260811180000` | `allowed_moves` now returned as data (`knowledge_depth().now_possible`); the permission line names the same violations the gate enforces; a journey directive (silent in `hold`) is appended for a paid parent. |
| Prompt: honest-ignorance clause | `docs/prompts/adam-conversation-agent.md` | Reflect/ask/hold is stated as a *complete* success, not a fallback — reduces the pressure that produces invention. **Not yet pushed to the live node** — see the file's own header. |

**Deployment (SQL to production, prompt text to the live n8n node) is a decision
for the founder, not yet taken.** The gate's guarantee only takes effect once
`gate_agent_reply`'s new body is applied to production — until then, production
still runs the 2026-08-01 version with no grounding check.

The original research and reasoning (unchanged) follow.

## The ADAM Contract — ratified 2026-08-11

> **ADAM is the grounded companion voice of a product that decides elsewhere.**
> It turns what the product already knows about one family into one warm,
> specific, useful thing at a time — and when it knows nothing, it says so
> honestly and still helps, rather than inventing.

This is the binding definition. The eight questions, answered as contract:

**What does it know?** Only what `get_agent_context` hands it: the child's name
(if named), active patterns, key emotional moments, recent nights — plus, for a
parent in a live journey, the agreed objective, phase, and progress
(`JOURNEY_CONTEXT`, built 2026-08-11). Nothing else. It does not know it is "an
AI"; it does not know product mechanics; it does not know anything not in that
payload, ever, including its own past replies beyond what memory the product
chose to keep.

**What can it say?** Only what the knowledge level allows, **as an enforced
move-set** (`knowledge_depth().now_possible`), not a suggestion: `answer_this_moment`
always; `speak_by_name` at level 1+; `aim_a_seed` at level 2+; `notice_a_pattern`
(claim a repetition/count) at level 3+; `name_a_goal` at level 4+. A claim outside
the allowed set is not a style problem — it is rejected before the parent sees it.

**What can it never say?** A price, a sales close, a guaranteed outcome, an
impersonation of فريق آدم, a claimed memory ("أتذكّر", "بحسب ما سجّلته"), a
reference to a past session that isn't in context, a repetition/count claim
without `notice_a_pattern`, a step that contradicts a live journey's phase.

**What does it do when it doesn't know enough?** Reflects what the parent just
said, asks one open question, or — in genuine collapse — holds presence. This
**is** success, not a fallback to apologise for. The gate's `ground_fallback`
moment exists precisely so honesty always has a safe, warm, ready sentence.

**How does it behave free vs paid?** Identical voice, identical warmth. Paid
adds exactly one thing: journey awareness (objective, phase, progress) — enough
to not deflect a paying parent's own question to فريق آدم, and to fall silent on
steps during `hold`, matching `compose_journey_step`'s own discipline. It is not
a second personality.

**How does it behave in crisis?** Unchanged by this work — collapse still gets
pure presence per the existing prompt (§"حين ينهار"). The gap that a
crisis produces **no record and no route** is real and named in the launch
readiness review (P0 there); it is a safeguarding/escalation problem, not a
voice problem, and is out of this contract's scope.

**How does a reply pass through the anti-hallucination system?** Every path:
model composes → `gate_agent_reply` (unchanged: price/sell/impersonation/brand) →
**`gate_grounded_reply`, new, called from inside `gate_agent_reply`** (memory
claims, past-session references, unfounded repetition/count claims — each
checked against real facts, not the model's word) → blocked replies are replaced
whole with `ground_fallback`, never patched, never regenerated (regenerating
risks a second hallucination). One `httpRequest` node, already wired, changes
nothing in n8n.

**What is enforcement, concretely?** Enforcement is the gate, not the prompt.
The prompt is rewritten to *reduce* violations (inject the level and allowed
moves as data; add a JOURNEY block; give "reflect / ask / hold" explicit
success-shaped instructions) — but the **guarantee** that a violation never
reaches a parent is the deterministic, offline-tested SQL gate. A model can
still try to violate the contract; it cannot succeed.

---

## Original research (2026-08-11, unchanged)

Research and analysis only when written. **Nothing was applied at the time.**
No prompt, function, workflow, or production object was changed to produce it.
Every claim is tied to a specific artifact examined directly in the live system,
the repo, or the tests — not recalled, not assumed.

The founder's charge: ADAM's role, limits, and behaviour are not settled enough;
it hallucinates; and the difference between the free and paid experience is not
reflected in how it behaves. This document establishes what is actually true,
then proposes a precise definition and operating rules — **to be reviewed, not
yet built.**

---

## What was examined (the evidence base)

| Artifact | What it is | Where |
|---|---|---|
| `paid aget adam` | The one conversational agent — every parent's reply | live W1, system message byte-identical to `docs/prompts/adam-conversation-agent.md` |
| `get_agent_bundle(uuid,text)` | The only context builder for the agent | `20260806140000`, live |
| `get_agent_context(uuid)` | The family facts, before stripping | `20260807200000`, live |
| `M2 - Build Paid Context` | The n8n node that assembles the agent's input | live W1 code node |
| `M2 - Classify Track` / `M2 - Track Switch` | Free/paid/new/survey/waitlist routing | live W1 |
| `gate_agent_reply(uuid,text)` | The only thing between the model and Telegram | `20260801250000`, live |
| `Compose Seed` (W3) · `HR - Compose` (W3) | The two proactive ADAM voices | live W3 |
| `compose_journey_step` | The paid daily step composer | `20260811140000`, built, **not yet wired** |
| `knowledge_depth` / `can_ground_seed` | The grounding discipline | live |

---

## Finding 1 — There is exactly one ADAM voice for conversation, and it is blind to paid

`M2 - Classify Track` computes a `track` — `free`, `paid`, `new`, `survey`,
`waitlist`, `country_answer`. But `M2 - Track Switch` sends **both `free` and
`paid` to the same output** → `M2 - Get Memory Snapshot` → `BD - Handled?` →
`M2 - Build Paid Context` → `paid aget adam`. There is no second agent, no
paid-specific branch. The node is named "Paid" for legacy reasons; the prompt doc
says it in line 3: *"Serves free and paid alike — the name is legacy."*

And the agent cannot even *tell* which one it is. `get_agent_context` emits a
`DAYS_LEFT:` line (the paid clock) — and `get_agent_bundle` **strips it**
(`where l !~ '^\s*(PLAN_DAY|DAYS_LEFT)\s*:'`) before the agent sees anything.
Nothing about the journey — the agreed objective, the phase, progress,
`paid_active` — is in `get_agent_context` at all. So:

> **The conversational ADAM is byte-for-byte identical for a free stranger and a
> parent 20 days into a paid journey. By construction it cannot know the
> difference, reference the goal, or respect the journey's phase.**

This is not a behaviour that "fails to reflect" the paid state. It is an
architecture that removes the paid state before the model runs.

---

## Finding 2 — Exactly what reaches the agent, and what does not

The agent's input binding is literally:
`family_context + "\n\n[رسالة الأهل الآن]\n" + message_text`.

`family_context` (built in `get_agent_bundle`) is two blocks:

```
[ما نعرفه عن هذا البيت — ملاحظاتنا نحن، لم يقلها الأهل الآن]
<facts: SUMMARY, CHILDREN, PATTERNS, KEY_MOMENTS, RECENT_DAYS — DAYS_LEFT removed>

[ما يُسمح لك أن تدّعي معرفته]
<one permission line, chosen by knowledge_level 0–4>
```

| The agent RECEIVES | The agent does NOT receive |
|---|---|
| Child names, ages, temperament | The raw `knowledge_level` number (only a prose permission line) |
| Active (unresolved) patterns with evidence counts | Whether the parent is free or paid |
| Key emotional moments (weight ≥ 3), last 3 days | The journey: objective, phase, progress, days remaining |
| A permission line gated on knowledge level | A hard "do not speak specifically without grounding" rule |
| The country question, when due (`ask`) | Any grounding *gate* — it always answers |

The permission line is the one real stage-awareness the agent has, and it is
**advisory prose**, e.g. level 0: *«لا تعرف عن هذا البيت شيئاً بعد… ولا تُلمّح إلى
أنك تتذكّر شيئاً.»* It forbids claiming false **memory**. It does **not** forbid
inventing a general parenting **mechanism** and presenting it as insight into this
child — which is the hallucination the product actually fears.

---

## Finding 3 — Why it hallucinates, located precisely

The hallucination is not random model behaviour. It is produced by a conflict the
prompt sets up and nothing resolves. Five mechanisms, each traced to a line:

### A. The output mandate fights the knowledge state
The prompt (lines 106–109) requires, in **every** ordinary message, at least one
of: *an explanation of what is happening and why the child behaves this way* / a
small step / a specific question. At knowledge_level 0–1 there are **no facts** to
explain *why this child* does anything — but the model is required to produce
something substantive and warm. It resolves the conflict the only way it can: it
invents a plausible mechanism. The permission line blocks claimed *memory*, not
invented *mechanism*, so the invention passes its own guardrail.

### B. The success criterion has no honest "I don't know" that counts as success
The stated success (lines 99–101): the parent leaves with something useful **and**
*"feels someone knows their house in particular."* Re-read, and rewrite if they
took nothing. At level 0 that second half is impossible to satisfy honestly —
so the model manufactures specificity to hit the target. The one sanctioned
low-content reply (pure presence) is reserved for **collapse** (lines 163–168),
not for *"I don't know your house yet."* There is no success-shaped move for
honest ignorance.

### C. Silent context loss, still a live class of bug
`M2 - Build Paid Context`'s own comment records that `M2 - Get Memory Snapshot`
carried `responseFormat: text` *"for weeks,"* so `b.context` was undefined on
**every** message and *"the agent ran with no family knowledge at all, silently."*
When context is silently empty, the permission line reads level 0 but the mandate
(A) still fires → invention. This is a fragility of the pipe, not a one-time fix.

### D. The gate cannot see it
`gate_agent_reply` blocks exactly: empty, a grouped-digit/currency **price**, a
sales **close**, **impersonating** فريق آدم, a **guarantee** in the brand's name,
a **superiority** claim. All vocabulary/commercial. **A hallucinated fact — a
wrong name, an invented "third time this week," a fabricated cause — is invisible
to it** and reaches the parent unaltered. The one guardrail between model and
parent does not check truth.

### E. The reactive agent has no grounding gate — unlike every proactive voice
`Compose Seed` refuses to send unless `can_ground_seed` is true (a named child AND
a situation/outcome/pattern). `HR - Compose` refuses unless the reply contains a
measured token (`must_mention_one_of`). The **conversational agent has no
equivalent**: it speaks specifically at knowledge_level 0, on zero grounding,
every time. The product's grounding discipline is rigorous everywhere except the
surface the parent reads most.

> The single sentence: **ADAM is required to be specific and warm on every turn,
> is given no honest way to be non-specific, is not stopped from inventing
> specifics, and its one guardrail checks vocabulary rather than truth.**

---

## Finding 4 — Contradictions between ADAM and the other engines

1. **Journey blindness breaks the phase discipline.** `compose_journey_step`
   enforces observe → build → **hold**, where in *hold* ADAM deliberately gives
   **no** step so the calm is shown to belong to the family. But the same parent
   can message the conversational agent at any time, and that agent knows nothing
   of the phase — it will happily give a step, contradicting the hold and the
   *"ADAM fades"* design. Two ADAM voices, one disciplined, one blind.

2. **The paid parent asking about their own journey.** A parent 15 days in who
   types *"how are we doing on the sleep goal?"* hits the conversational agent,
   which has no objective, no progress, no phase. `is_team_question` may even
   intercept it and reply *"هذا يتولّاه فريق آدم"* — deflecting a paying customer
   to the cashier for something they already bought. The agreement/journey state
   (`stages`, `agreed_objective`) is invisible here.

3. **The grounding gate is bypassed exactly where it matters most.**
   `knowledge_depth` and `can_ground_seed` exist to enforce *"don't speak without
   grounding."* The reactive agent — the highest-volume, most-read surface —
   routes around all of it.

None of these is a bug in a single node. They are the same root: **the
conversational agent is disconnected from the product's state machine.**

---

## Finding 5 — What the free/paid difference actually is today, and what it should be

| | Free ADAM (today) | Paid ADAM (today) | Paid ADAM (what the design implies) |
|---|---|---|---|
| Reply engine | `paid aget adam` | **identical** node | same warmth, plus journey awareness |
| Knows it is paid | no | **no** (DAYS_LEFT stripped) | yes — enough to not deflect a customer |
| Knows the objective | no | **no** | yes — can reference the agreed goal |
| Respects observe/build/hold | n/a | **no** | yes — silent in hold, one step in build |
| Daily proactive | free seed | free seed (journey_step not wired) | `journey_step`, phase-aware |

The free experience is *correct as a companion*. The paid experience is **the free
experience with the paid parts invisible** — which is exactly the founder's
observation, now located: it is not a tuning gap, it is a missing connection
between the agent and `stages`/`agreed_objective`.

---

## The six answers

### 1. What is ADAM's role, exactly?
ADAM is the **companion that speaks** — the daily, in-chat voice of a product
whose *decisions* are made elsewhere. It has two jobs and only two: **(a) make a
tired parent's night lighter with one grounded, specific thing**, and **(b) be the
warm surface of a state machine it does not itself run.** It is not the growth
engine, not the cashier, not the safeguarding officer, not the journey planner. It
renders; it does not decide. Everything it says specifically must be backed by a
fact the product already holds.

### 2. What must it do / must it never do?
**Must:** answer the moment in front of it; be specific only when grounded; use the
child's name when known; give at most one small, falsifiable step; ask at most one
question; hold presence in genuine collapse; hand money/journey questions to فريق
آدم. **Must never:** invent a fact, a cause, a count, or a memory; claim a
capability ("I remember", "I can"); quote a price or sell; impersonate the team;
promise a guarantee; give generic advice that would fit any child; give a step
that contradicts an active journey phase; *pretend to know a house it does not
know.*

### 3. How should free vs paid differ?
Same voice, same warmth, **one added faculty for paid: journey awareness.** Paid
ADAM should receive the agreed objective, the current phase, and progress, so it
can (a) reference the goal instead of deflecting a customer, (b) respect *hold* by
withholding steps, (c) never send the "that's for فريق آدم" line to someone who
already bought. Free ADAM stays exactly as it is. The difference is **one context
block and one behavioural rule**, not a second personality.

### 4. What must it know at each stage?
| Stage | Must know | Must NOT assume |
|---|---|---|
| First contact (`new`) | nothing — it is not even called; a fixed first-contact fires | that it remembers anything |
| Free, level 0 | only the live message; that it knows nothing | any cause specific to this child |
| Free, level 1 | the child's name | what recurs with the child |
| Free, level 2 | name + the usual hard moment | a confirmed pattern it has not earned |
| Free, level 3 | what actually recurs (patterns) | more than one grounded observation per reply |
| Free, level 4 | the house well; may name a goal *if timing fits* | that naming a goal is selling |
| **Paid, in journey** | **the objective, the phase, progress** | that it may free-style steps in *hold* |

Today rows 1–6 are approximated by the permission line; **row 7 does not exist.**

### 5. Why does it hallucinate, and exactly where?
Because it is **required to be specific and warm every turn (prompt 106–109, 99–101),
given no honest low-content success move except collapse, not forbidden from
inventing mechanisms (permission line blocks memory, not invention), fed by a pipe
that has gone silently empty before (`M2 - Build Paid Context` comment), and
guarded by a gate that checks vocabulary, not truth (`gate_agent_reply`).** The
failure point is the seam between *the mandate to speak* and *the absence of a
grounding gate on the reactive path* — the one path, unlike seed and harvest, that
can speak on zero grounding.

### 6. What contracts must bind ADAM to the rest of the product?
1. **Grounding contract.** Specific claims require a backing fact; with none, ADAM
   may only reflect, ask, or hold — and that must count as a *successful* reply,
   not a failure. (Mirror `can_ground_seed`'s discipline onto the reactive path.)
2. **Knowledge-level contract.** The level must gate *what kind of move* is
   allowed, not merely what memory may be claimed — enforced, not advised.
3. **Journey contract.** In a live journey, ADAM receives objective + phase +
   progress and obeys the phase (silent in hold, one step in build); it never
   deflects a paying parent's journey question to the cashier.
4. **Commerce contract.** Unchanged and correct: price/journey-purchase questions
   go to فريق آدم via `is_team_question`; the gate enforces the vocabulary.
5. **Safeguarding contract.** A collapse/▲disclosure must produce a **record and a
   route**, not only a gentle reply — today it produces neither (see
   `docs/what-is-missing.md`; `crisis_flags` has 0 rows over 4,756 messages). ADAM
   the voice cannot own this; it must hand off to something that does.
6. **Truthful-surface contract.** The output gate must, at minimum, be able to
   catch a claimed fact that the context does not support — or the reactive path
   must be grounded enough upstream that it cannot produce one.

---

## Proposed redefinition (NOT applied — for review)

> **ADAM is the grounded companion voice of a product that decides elsewhere.**
> It turns what the product already knows about one family into one warm, specific,
> useful thing at a time — and when it knows nothing, it says so honestly and still
> helps, rather than inventing. It never sells, never claims a capability, never
> contradicts the journey it is part of, and never speaks a fact the product does
> not hold.

**Operating rules (proposed, unbuilt):**
1. **No specific claim without a backing fact.** At level 0–1, reflect / ask /
   hold only. This is a *success*, given its own examples in the prompt, not an
   apology.
2. **The knowledge level gates the move, in the payload** — not as prose the model
   may override. (Inject the level and the allowed move-set explicitly.)
3. **Paid = free + journey context.** Feed objective/phase/progress; obey the
   phase; never deflect a customer to the cashier for what they bought.
4. **The reactive gate must see truth, not only vocabulary** — or the reactive
   context must be strong enough that a fact cannot be invented. At minimum, a
   post-hoc check that a named child / claimed pattern exists in `get_agent_context`.
5. **Collapse produces a record and a route,** not only a presence line.
6. **Keep the 2026-08-04 warmth.** The fix is not to re-add prohibitions (that
   produced the cold replies the founder rejected). It is to give honesty a
   *warm, specific, successful* shape so the model stops needing to invent to feel
   useful.

---

## Problems, ranked

| Rank | Problem | Evidence | Why it matters |
|---|---|---|---|
| **P0** | Reactive agent can invent facts with no grounding gate and no truth check | Findings 3A–E; `gate_agent_reply` vocabulary-only | Direct hit to trust — the product's whole claim is *"knows YOUR house"*; an invented fact disproves it in one line |
| **P0** | Collapse/disclosure yields no record and no route | `crisis_flags` 0 rows / 4,756 msgs; no `insert into crisis_flags` anywhere | Duty of care; also a launch blocker in the readiness review |
| **P1** | Paid ADAM is blind to the journey (objective/phase/progress) | Finding 1; DAYS_LEFT stripped, no stage in `get_agent_context` | Breaks *hold*, deflects paying customers, makes the paid tier feel identical to free |
| **P1** | Knowledge level is advisory prose, not an enforced move-gate | `get_agent_bundle` permission line | The one stage-control the agent has is soft; the model overrides it under the output mandate |
| **P1** | Silent context-empty failures | `M2 - Build Paid Context` comment | When the pipe empties, hallucination is guaranteed by the mandate |
| **P2** | The prompt doc's "cannot do" note is stale | `adam-conversation-agent.md` lines 73–75 vs `get_agent_bundle` | Says depth is not injected; a permission line now is. Doc should be reconciled so the next reader is not misled |
| **P2** | Two proactive voices duplicate anti-templating rules by hand | `Compose Seed`, `HR - Compose` system messages | Maintenance drift risk; not a behaviour bug today |

**Not to touch (verified sound):** the 2026-08-04 warmth rewrite and its worked
examples; the commercial bans and `gate_agent_reply`'s blocking set; `is_team_question`
routing; the seed/harvest grounding discipline; `compose_journey_step` itself (correct,
just unwired). The problem is connection and grounding on the reactive path — not the
personality, and not the engines.

---

*Analysis only. No prompt, function, workflow, or production object was modified.
The redefinition and rules above are proposals for review, not changes.*
