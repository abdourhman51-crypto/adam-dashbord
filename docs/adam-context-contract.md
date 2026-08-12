# ADAM — Context Design Review, and the Context Contract

**Written:** 2026-08-12. **Review and design only. Nothing here has been built,
deployed, or applied to any prompt, function, workflow, or production object.**
Supersedes `docs/adam-context-engineering.md`'s tier map with per-field,
per-token justification — this document applies the stricter test the founder
asked for: *every token must prove it adds real decision or reply value, or it
is cut.* All measurements below are either read directly from production
(`aajqbmjasnbwwyvgrlzy`, read-only) or computed with a real tokenizer against
real repo/production strings — never guessed. Where a number could not be
verified without touching the live n8n node, that gap is named, not papered
over (same discipline as `fix-paid-memory-contamination.md`).

**Token-counting method:** `gpt-tokenizer` (cl100k_base), run locally, no
network, no production. This is a **proxy**, not a proof of the exact count the
live model (OpenRouter-routed) would see — different tokenizers vary ±20-30%
on Arabic — but it is a real, measured, reproducible number, not an estimate
from character count, and it is consistent enough to compare tiers against each
other, which is what the budget decisions below actually need.

**One scale-setting fact before anything else:** the static system prompt
(`docs/prompts/adam-conversation-agent.md`'s prompt block) measures
**~2,538 tokens**. Every dynamic-context number in this document should be read
against that — the richest realistic dynamic context this document proposes
(~1,000-1,600 tokens) is still smaller than the fixed prompt paid on *every*
call. That prompt is out of scope here (it was reviewed and lightly edited in
the Constitution pass already approved), but the ratio matters: the biggest
token line item in every single call is not the thing this review is about.
Named once, not re-litigated.

---

# PART A — The Review

## Q1 — The smallest context that makes ADAM useful and accurate, per knowledge level

Two things are level-**invariant** (present regardless of level 0-4) and three
are level-**gated** (only appear once their evidence threshold is met). Measured,
real-shaped composition per level:

| Level | Invariant floor | Level-gated addition | Measured tokens (structured, excl. buffer) |
|---|---|---|---|
| **0** | framing header (22) + "لا شيء مسجّل بعد" (10) + permission (47) | — | **~79** |
| **1** | framing header (22) + CHILDREN name-only (6) + permission (38) | — | **~66** |
| **2** | framing header (22) + CHILDREN w/ attrs (18) + permission (51) | — | **~91** |
| **3** | level 2's floor | + PATTERNS, 1 pattern (21) | **~112** |
| **4** | level 3's floor | + nothing new structurally — permission text changes (22) to license naming a goal | **~112** |

Add the **buffer** (Tier 2, session-recent-turns — present at every level once a
prior turn exists) and the **current message** (~18-30 tokens), and the honest
floor for a real turn is:

- **First-ever message, any level:** current message only, no buffer, no
  structured tier but the empty-form header → **~110 tokens total.**
- **A returning free/paid user mid-conversation, level 0-2:** ~90-250 tokens
  structured + one buffer pair (~130 tokens) per prior turn.

**The answer, stated plainly:** at levels 0-2 (91% of real users, Part 0.2 of
the prior doc), the smallest sufficient context is **under 300 tokens of
structure** — the rest of what ADAM "knows" at that point is legitimately just
the last few real turns, which is not memory, it is *conversation*. Levels 3-4
add barely anything structurally (~20-30 tokens) — the value at those levels is
almost entirely in what the *snapshot* (Tier 3, paid-only, Q4) can hold that a
one-line pattern cannot: the arc, not just the fact.

## Q2 — Always-visible vs. only-when-needed, with two cuts the stricter test forces

**Always (every turn, every user):** the framing header, the permission line,
the current message, and the buffer if any prior turn exists. These four are
the ones that are true at every level by construction — nothing else clears the
bar unconditionally.

**Only when needed — and two blocks that do NOT clear the bar even when their
data exists:**

1. **CHILDREN, PATTERNS, JOURNEY** — genuinely conditional, correctly gated on
   real evidence existing (a named child / a confirmed pattern / a live stage).
   No change from the prior design.

2. **KEY_MOMENTS — cut.** Measured cost: **72 tokens for 3 events** (real
   production shape). Real prevalence: **14 events total across 324
   followers** — this block fires for a tiny fraction of turns, and every time
   it does, it duplicates a fact that either (a) belongs in the compressed
   snapshot's narrative (paid), where it already gets rewritten with context
   and trajectory, or (b) for a free user with no snapshot, is a bare, dateless
   one-liner ("[الأب] كسر شاشة التلفزيون") with no narrative frame — which
   risks being read by the model as an ongoing pattern rather than a single
   past incident, precisely the specificity-without-evidence failure the
   Constitution's gate exists to catch. **Recommendation: delete this as a
   separate context block.** Its raw source (`memory_events`) stays as
   *source material* for the snapshot writer, per the "raw tables are source,
   not context" principle — it does not need its own direct pipe to the model.

3. **The snapshot's own "الأنماط النشطة" restatement — cut.** Measured cost:
   **19 tokens** (397→341 chars once removed) on every paid snapshot. Small
   alone, but the real reason to cut it is **duplicate-source-of-truth risk**:
   `child_patterns` (Tier 4, structured, deterministic) already sends the
   confirmed pattern. The snapshot's version is an LLM paraphrase produced at
   write time, which can drift from the structured table by the time it's read
   (freshness, Q5). **One fact, one representation** — Tier 4 owns "what
   pattern," the snapshot owns "what changed and what we agreed," and the two
   must not restate each other.

**Conditional but not urgent — named, not acted on:** a family with more than
one child gets every child listed every turn regardless of which child the
conversation is about. Real prevalence is low enough (69 named children /
324 followers ≈ mostly 0-1 per family) that this is not worth building against
now; named as a trigger point — revisit if multi-child families become common.

## Q3 — The exact free/paid context difference, without withholding help

**Not gated by payment: CHILDREN, PATTERNS, the permission line, the buffer,
the current message.** A confirmed pattern is *earned by evidence*, not
*purchased* — gating it by payment would mean two families with identical
logged nights get different acknowledgment based on who paid, which is
withholding help the product already knows, forbidden by the Constitution's
own non-selling principle. This is unchanged from the prior design, restated
here because the stricter test was applied to it and it survives: every field
in it earns its place for both free and paid alike.

**Gated by payment, and here is exactly why each one is a legitimate
purchase, not information rationing:**

- **The snapshot (Tier 3)** is not "more facts" — free already gets every fact
  the DB holds via CHILDREN/PATTERNS. It is **continuity across sessions**: the
  arc of "was frustrated, now calmer," the thing that cannot be reconstructed
  from a fresh read of structured tables because it is about *change over
  time*, and free conversations do not persist a cross-week narrative by
  design (Tier 2's buffer is per-session, not per-relationship). What is being
  sold is *being known over time*, not *being told more*.
- **The journey (Tier 5)** is not context in the ordinary sense — it is a
  **structural commitment**: an agreed objective, a planned cadence, and phase
  discipline (observe/build/hold) that only exists because a payment relationship
  was entered into. A free parent has no agreed objective to reference because
  there is no agreement — there is nothing to withhold, there is simply nothing
  there yet.

**The product-level answer:** paid does not unlock better *answers*. Every
level-appropriate answer a paid parent gets, a free parent at the same
knowledge level gets too. Paid unlocks **being remembered across weeks** and
**a structured, disciplined plan with a beginning, middle, and deliberate end**.
Both of those are, literally, what "مرافقة" means as a product — the payment is
for the relationship's shape over time, not for unlocking help that was being
held back.

## Q4 — Is the snapshot worth activating now? Field by field.

The four real snapshots (`docs/adam-context-engineering.md` Part 7) decompose
into four fields. Measured cost of the redacted 396-char example, with the
patterns line already cut per Q2:

| Field | Example (redacted) | Value | When used | Measured cost |
|---|---|---|---|---|
| **Child + core challenge** | "[الطفل] (ذكر) يواجه تحدي الخوف من السباحة…" | Anchors every reply to the actual standing issue, not a generic one | Every turn | ~35 tokens |
| **Parent's emotional trajectory** | "…لكنها الآن مطمئنة ومتفائلة بعد أن فهمت…" | The single highest-value field for warmth calibration — tells ADAM the parent's *current* emotional register without re-deriving it from the live buffer alone | Every turn (tone-setting) | ~35 tokens |
| **The agreed direction** | "تم الاتفاق على جعل تجربة السباحة تدريجية…" | Prevents ADAM contradicting a plan already agreed — this is the field with the highest hallucination-prevention value per token in the whole context | Whenever the moment touches the plan | ~30 tokens |
| ~~Active patterns restatement~~ | ~~"الأنماط النشطة: …"~~ | **Cut per Q2** — duplicate of Tier 4 | — | ~19 tokens saved |

**Total after the cut: ~123 tokens per turn, paid users only.**

**Is it worth activating now?** Split the question, because "activating the
read side" and "activating the write side" are different costs entirely:

- **Read cost (what reaches ADAM):** ~123 tokens/turn. Negligible, and — with
  **zero paid users today** — currently zero total cost, because nobody would
  receive it.
- **Write cost (what regenerates it):** an LLM call per update, currently
  produced by the dormant W2 writer. **This is the actual cost the founder is
  controlling by keeping W2 off**, and it was previously running for **all 324
  followers**, including the 253 who are level 0 and the ~320 who are free —
  i.e., the write cost was being spent on a tier that Q3 establishes should
  never reach a free user in the first place.

**Recommendation: do not revive W2 broadly. If this is activated, scope the
snapshot writer to run only for followers with an active paid subscription** —
which today is zero, so the real-world cost of building this scoped and ready
is **$0 until the first real paid signup**, at which point the cost is
self-funding (one paid user justifies one snapshot-writer run). This directly
resolves the cost question the prior document left open: the answer is not
"turn it on" or "leave it off," it is "build it scoped so its cost only exists
when its value does."

## Q5 — Ensuring context itself is not a source of hallucination or staleness

Two separate risks, requiring two separate rules:

**1. Structural tiers (0, 1, 2, 4, 5) are inherently fresh** — each is
recomputed live from current tables on every single turn (`get_agent_context`
is `stable`, called per-request, never cached). No staleness rule is needed
for them; they cannot go stale by construction.

**2. The snapshot (Tier 3) is the one tier that is a cache by design** — it is
written once, read many times, until the next W2 cycle. Two different kinds of
claim live inside it, and they age at different rates:

- **Durable facts** (the core challenge, the agreed direction) — change slowly,
  safe to trust for weeks.
- **State facts** (the parent's *current* emotional register — "الآن مطمئنة") —
  can be stale within days. A parent who was calm three weeks ago may not be
  calm today, and the live buffer (Tier 2, always fresh) is a better source for
  *right now* than a snapshot written weeks earlier.

**Rule: the snapshot writer must carry `updated_at`, and the emotional-register
field must be treated as advisory, superseded by anything the live buffer
shows this session.** This is not a new mechanism — it only requires the
snapshot's emotional language to be phrased as a **trend** ("كانت محبطة، وتحسّنت
بعد الاتفاق") rather than a bare present-tense claim, so it reads correctly even
if the "now" part has since moved on.

**3. Single source of truth per fact** — the two Q2 cuts (KEY_MOMENTS,
patterns-restatement) exist specifically to prevent two independently-generated
representations of the same fact from silently disagreeing. This is now a
standing rule, not a one-time fix: any future context field must be checked
against this before being added — *does something else already assert this
fact?*

**4. Absence stated, never implied** — carried over unchanged from the prior
design; still the primary defense against the model filling a blank.

**5. Compression Fidelity as an ongoing audit** — periodically diff snapshot
claims against source tables (unchanged from the prior design's Part 9). Not a
runtime gate; a periodic check, because the writer runs on a cycle, not per-turn.

---

# PART B — The Context Contract

One table, one list, one number per section. This is the enforceable
specification — everything in Part A is the reasoning behind it.

### 1. Input that reaches ADAM, every turn
- The parent's current message, verbatim.
- The assembled context bundle (below), as one framed block, never as raw
  table dumps.

### 2. Memory ADAM needs
- **Session memory** (Tier 2): the recent real conversation, parent's own
  words + ADAM's own prior replies, for continuity within a conversation.
  Needed by everyone, free or paid.
- **Relationship memory** (Tier 3): the compressed, evolving snapshot, for
  continuity *across* sessions and weeks. Needed only where that continuity
  is the product being provided — paid only (Q3).
- Nothing else is "memory" — structured facts (child, pattern, journey) are
  not memory, they are the current, live state of the record, re-read fresh
  every turn.

### 3. What gets compressed
- The relationship's history → the snapshot (≤450 chars / ~150 tokens),
  written by an LLM from source tables, holding: child + core challenge,
  emotional trajectory (phrased as trend, not a present-tense claim), agreed
  direction. **Not** a restatement of confirmed patterns (§Q2/Q4) — those stay
  single-sourced from `child_patterns`.

### 4. What gets deleted (never sent as a separate context block, regardless of
   whether the underlying data exists)
- `KEY_MOMENTS` / raw `memory_events` (§Q2) — folds into the snapshot's
  narrative for paid; simply absent for free.
- The snapshot's patterns restatement (§Q2/Q4).
- Full-table dumps of any kind (`daily_logs` beyond the last 3; full chat
  history beyond the windowed buffer).

### 5. What is conditional (present only when its evidence threshold is met —
   absent, never emitted empty)
| Tier | Condition |
|---|---|
| CHILDREN | ≥1 named child (not `الطفل`/`الطفلة`) |
| PATTERNS | ≥1 pattern with `status='confirmed'` |
| RECENT_DAYS | ≥1 `daily_logs` row |
| Snapshot (Tier 3) | paid **and** a snapshot exists |
| JOURNEY (Tier 5) | paid **and** a live `stage` exists |
| Buffer (Tier 2) | ≥1 prior turn in this session |

### 6. Free vs. Paid — the whole difference, exhaustively
**Identical for both:** framing header, permission line, CHILDREN, PATTERNS,
buffer, current message, voice, response discipline, reply quality at the same
knowledge level.
**Paid only:** the snapshot (Tier 3) and the journey (Tier 5) — because both
are, respectively, cross-session continuity and a structural commitment that
literally do not exist without a paid relationship (§Q3). Never a difference in
tone, warmth, length, or willingness to fully answer.

### 7. Freshness rules
- Tiers 0, 1, 2, 4, 5: always fresh — recomputed from live tables every turn,
  no caching, no staleness possible by construction.
- Tier 3 (snapshot): a cache, by design. Durable-fact language trusted
  indefinitely; state/emotional language treated as advisory and superseded by
  the live buffer. Carries `updated_at` for audit.
- Single source of truth per fact, enforced at design time (§Q2/Q5) — no field
  is ever added if an existing tier already asserts the same fact.

### 8. Maximum context budget (structured tiers + buffer; excludes the fixed
   ~2,538-token static prompt, out of scope here)
| Component | Target ceiling | Measured basis |
|---|---|---|
| Structured tiers combined (0,1,4,5,perm,snapshot) | **≤350 tokens** typical, **≤450** richest real case | Measured: ~91 (level 2 floor) to ~309 (paid/build, snapshot+journey+pattern) |
| Buffer (Tier 2) | **≤800 tokens** (recommend capping around 5-6 exchanges) | Measured: one real {human,ai} pair ≈ 130 tokens; today's `contextWindowLength: 10` may mean up to ~1,300 tokens if it maps to 10 pairs — **exact mapping not verifiable without the live n8n node, flagged as an open verification item, not assumed** |
| **Total dynamic context** | **≤1,200 tokens** | Well under half the static prompt's measured 2,538 |

**The buffer, not the structured facts, is where the real budget is spent** —
consistent with Part 0.4's earlier finding, now with real token numbers behind
it. If the exact `contextWindowLength` mapping is confirmed at ≥10 pairs, the
concrete recommendation is to **reduce it**, because the measured cost is
dominated by ADAM's own prior replies (112 tokens each, real average) rather
than the parent's words (18 tokens each) — a shorter window loses mostly
ADAM's own archived phrasing, which the snapshot (paid) or nothing (free, by
design) already covers, not the parent's actual recent words.

### 9. What must never reach the LLM, under any condition
- Any raw ID: `telegram_id`, `platform_user_id`, `follower_id`, or any table's
  `uuid` primary/foreign key.
- `DAYS_LEFT`, `subscription_expires_at`, any billing date or amount.
- `country`, `funnel_stage`, or any routing/administrative field — these drive
  routing and commerce, not conversation (unchanged from the prior design).
- `parent_gender` — **never, even where populated.** Not because it is
  unused today, but structurally: handing a gender-neutrality-mandated model
  the parent's gender is handing it the one fact that could unconsciously erode
  that mandate. Omission enforces the rule; instruction alone does not.
- Internal engine/table/field vocabulary as literal strings — `seed`,
  `harvest`, `journey`, `tier`, `snapshot`, `machine_N`, `W1/W2/W3`, or any
  other implementation name (already prompt-forbidden as output vocabulary;
  restated here as a context-composition rule so it is never even present to
  be tempted by).
- Any other family's data — enforced structurally by per-follower-parameterized
  queries; restated here as an absolute, not a hope.
- The model's own prior system-role scaffolding replayed as if it were the
  parent's words (the memory-contamination fix, unchanged, still not deployed).
- `reply_gate_log` or any internal moderation/audit record.
- Raw `memory_events` beyond what the snapshot narrates (§4).

---

*Review and design only. Nothing here has been applied to a prompt, a function,
a workflow, or production. Open items before implementation: (1) confirm the
`contextWindowLength`→buffer-size mapping against n8n's actual node behavior —
not assumed here; (2) the founder's cost decision on scoping a paid-only
snapshot writer (§Q4) — a decision, not a build, until made.*
