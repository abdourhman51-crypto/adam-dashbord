# ADAM — Context Engineering as Product Architecture

**Written:** 2026-08-12. **Design and analysis only. Nothing here has been built,
deployed, or applied to any prompt, function, workflow, or production object.**
Every number in Part 0 was measured directly against production
(`aajqbmjasnbwwyvgrlzy`) read-only on the date of writing; every quoted memory
excerpt has personal names redacted (`[الطفل]`, `[الأم]`).

The premise this document is written under, in the founder's own words: **the
core of ADAM is not the LLM or the prompt — it is the system of context we
choose to deliver, when, what we withhold, and how it changes as the
relationship deepens. The goal is not maximum context. It is the *least*
context that is *most* useful: accurate, compressed, fresh, staged by the user's
phase, and clearly different between free and paid. Do not assume the answer is
more context. The answer may be deleting 80% of it.**

This document tests that premise against what is actually true today, and it
largely confirms it — with one correction the data forces (Part 0.4).

---

# PART 0 — The measured reality (not remembered — measured)

Before designing, the actual state, because the design that follows only makes
sense against these numbers.

## 0.1 The population

| Measure | Value |
|---|---|
| Followers | 324 |
| Named children | 69 (2 still placeholder `الطفل`) |
| Followers with any `daily_log` | 45 |
| Avg logs per active follower | 1.6 (max 4) |
| `daily_logs` with a `night_result` | **3** (of 70) |
| `daily_logs` with a `step_status` | **1** |
| `child_patterns` total / confirmed / evidence≥3 | 6 / **0** / 1 |
| `memory_events` | 14 |
| `memory_snapshots` non-empty | **4** |
| `stages` (live journeys) | **0** |
| Active paid subscriptions | **0** |
| Followers with an `agreed_objective` | **0** |
| Chat rows | 4,762 across 211 distinct sessions |

## 0.2 The knowledge-level distribution — the whole product, today

`knowledge_depth()` across all 324 followers:

| Level | Meaning | Count | Share |
|---|---|---|---|
| 0 | Nothing / no named child | 253 | **78%** |
| 1 | Child's name only | 43 | 13% |
| 2 | Name + a confirmed situation | 28 | 9% |
| 3 | A confirmed, evidenced pattern | **0** | 0% |
| 4 | A month of outcomes | **0** | 0% |

**No real user has ever reached level 3 or 4.** The entire pattern-aware and
goal-aware half of the context apparatus has fired zero times in production.

## 0.3 The weight of the structured context ADAM actually receives

`length(get_agent_context(follower))` across all followers:

| Statistic | Characters |
|---|---|
| Median | **12** |
| Average | 45 |
| 90th percentile | 86 |
| Max (one outlier) | 2,430 |
| Followers with ≤ 40 chars | 276 of 324 (85%) |

For the median user, the structured context — after `get_agent_bundle` strips
`DAYS_LEFT` — is essentially empty. The 2,430-char maximum is a single
rich outlier.

## 0.4 The correction the data forces

The founder's instinct — "the answer may be deleting 80% of the context" — is
**directionally right but aimed at the wrong layer.** You cannot delete 80% of
the structured context, because **four of its six blocks already produce
near-zero bytes for ~100% of users:**

- `SUMMARY` — 4 followers have one.
- `PATTERNS` — 0 confirmed, 1 with evidence.
- `KEY_MOMENTS` — 14 events across 324 followers.
- `RECENT_DAYS` — 3 logs carry a real `night_result`.
- `JOURNEY` — 0 live stages.
- `CHILDREN` — the one block that fires: 69 real names.

The real context ADAM runs on today is **not** the structured block. It is the
**10-message conversation buffer** (`Postgres Memory Paid`), which — at avg 62
chars per parent turn and 358 per ADAM reply — is on the order of **~2,000–3,600
characters**, i.e. **~95% of the total context budget**, and is the *contaminated*
one (see `fix-paid-memory-contamination.md`).

**So "delete 80%" applies precisely, but to the conversation buffer, not the
structured facts.** The structured facts are not bloated — they are *dormant*,
waiting for writers that are switched off. The correct design therefore has two
independent moves, not one:

1. **Shrink and clean the dominant layer** (the buffer) — already designed.
2. **Light up the one dormant tier that actually earns its bytes** (the
   compressed snapshot), and keep the rest dormant — *not* shipping empty
   headers — until their writers produce real data.

---

# PART 1 — The context tiers that already exist, mapped byte by byte

ADAM's context is assembled by two functions and one n8n memory node. Mapped
exactly:

## Tier A — Live structured facts (`get_agent_context` → `get_agent_bundle`)

Recomputed every turn, from Postgres, per follower. Six blocks, in order:

| Block | Source table | Fires when | Real prevalence today |
|---|---|---|---|
| `DAYS_LEFT` | `followers.subscription_expires_at` | always (then **stripped** in bundle) | n/a — never reaches model |
| `SUMMARY` | `memory_snapshots.snapshot_text` | a snapshot exists | 4 / 324 |
| `CHILDREN` | `children` | a child row exists | 69 / 324 |
| `PATTERNS` | `child_patterns` (status≠resolved) | a pattern exists | ~6 / 324 |
| `KEY_MOMENTS` | `memory_events` (weight≥3, top 5) | an event exists | ~14 rows total |
| `RECENT_DAYS` | `daily_logs` (last 3) | a log exists | 45 / 324 |
| `JOURNEY` | `stage_state()` | a live stage exists | **0 / 324** |

`get_agent_bundle` then wraps this with: the framing header (`ملاحظاتنا نحن، لم
يقلها الأهل`), the **permission line** (knowledge level → what may be claimed),
`allowed_moves` as data, and — for a paid parent — the **journey directive**.

## Tier B — Compressed long-term memory (`memory_snapshots`)

One row per follower, `snapshot_text` — a dense prose summary of the whole
relationship. **Written by `writer_commit` (the W2 knowledge writer's commit
path), from an LLM-produced `snapshot_text` field.** The four that exist were
built in July by a process the `built_from` field still labels `machine_3`;
**W2 is currently `active: false` (cost control), so no new snapshots are being
written and the four that exist are frozen.** This is the single highest-value
tier and it is dark.

## Tier C — Short-term conversational memory (`Postgres Memory Paid`)

The last 10 `{human, ai}` turns, replayed as chat history. This is the dominant
real context by weight. Today it stores the *constructed prompt* as the "human"
turn, not the parent's words (Conflict 2). The dominant layer is also the
contaminated layer — which is why fixing it is not cosmetic.

## What this map reveals

The architecture is **correct in shape and over-provisioned in blocks relative
to the data that exists.** It was built for a product with confirmed patterns,
month-long journeys, and running writers. That product's *data* does not exist
yet. Context engineering's job now is to make the context match the data that
is *real*, and to stage each tier to light up exactly when its writer starts
producing truth — never before (an empty `== PATTERNS ==` header is not neutral;
it is a cue to the model that patterns are a thing it should be producing).

---

# PART 2 — The principle, stated so it can be enforced

**Minimum true useful context.** Three words, each a hard filter, in priority
order:

1. **True** before **useful** before **minimum.** A byte that is not currently
   true is deleted regardless of how useful it would be. A byte that is true but
   not useful *this turn* is deferred. Only among true-and-useful bytes do we
   then minimise.
2. **Specificity of context tracks evidence.** This is the same governing rule
   as the Constitution's — *عندما تقلّ الأدلة، تقلّ درجة التحديد* — applied one
   layer earlier: not "how specific may ADAM's reply be" but "how specific may
   the *context we hand it* be." A level-0 context that describes a pattern is a
   lie the model will faithfully repeat.
3. **Absence is stated, never implied.** "لا شيء مسجّل عن هذا البيت بعد" is
   context. A blank is not — a blank invites the model to fill it. Every tier
   that can be empty must have an explicit empty form.

**The value of paying is continuity and depth of context, not the un-withholding
of help.** A free parent is never given a worse *answer*; they are given a
shorter *memory*. This is the load-bearing product decision, and Part 6 makes it
concrete.

---

# PART 3 — The ten questions, answered against the data

**1. What must ADAM know at every moment?**
The irreducible minimum, true for 100% of turns: (a) the child's name *if and
only if* it is known; (b) what the parent just said, this turn; (c) the honest
statement of how much is known ("nothing yet" is a valid, complete answer to
this). Everything else is conditional on evidence existing.

**2. What does it not need to know?**
`DAYS_LEFT` (already stripped — correctly). Any block whose writer has produced
nothing for this family: today that is PATTERNS, KEY_MOMENTS, JOURNEY for ~99%
of users, and SUMMARY for 99% of users. Handing the model an empty or absent
version of these is not just wasteful — it is an active hallucination risk
(Part 8). ADAM also does not need the parent's country, gender, or funnel stage
in the reply context — those drive *routing and commerce*, not conversation.

**3. What belongs in long-term memory?**
Exactly one thing, and it already has a home: the **compressed snapshot**
(Tier B) — child + age + core challenge + parent's emotional trajectory + what
has been agreed/tried + confirmed patterns, in ~300–450 chars. The four real
July snapshots prove the format works. Long-term memory is *this one evolving
paragraph*, not the raw event/log/pattern tables — those are its *source
material*, queried to rebuild it, not context in themselves.

**4. What belongs in momentary context only?**
The current turn's message, the last few conversational turns (Tier C, cleaned),
and the live journey phase if any. These are true only *now* and must not be
persisted as fact — a venting message at 11pm is not a pattern.

**5. How do we compress family history into useful memory without losing
meaning?**
The snapshot is a *rewrite*, not a *truncation* — the July examples drop every
raw event and keep the trajectory ("kانت محبطة… لكنها الآن مطمئنة"). Design in
Part 7. The compression discipline: keep the *change over time* and the *one
agreed direction*; drop timestamps, counts, and any single incident that is not
load-bearing.

**6. How does context differ between free and paid?**
Not by block-presence tricks. Same six-block *structure*, but: **free carries no
Tier B snapshot older than the current conversation window** — a free parent
gets full, warm, name-aware help every time, but ADAM does not carry a compressed
memory of who they are across weeks. **Paid carries the evolving snapshot + the
journey tier.** The paid parent is *known over time*; the free parent is *helped
well each time*. Part 6 shows both paths turn by turn. (Note: this is a design
proposal — with 0 paid users, it has never run.)

**7. How does context change across days inside a paid journey?**
The `JOURNEY` block's `phase` (observe→build→hold) already encodes this, and the
snapshot deepens: observe-phase context is thin and factual ("we are still
watching"); build-phase context carries what worked yesterday; hold-phase
context deliberately *thins again* (ADAM fades — the snapshot stops adding steps
and starts naming the parent's own competence). Context volume is not monotonic
— it rises then intentionally falls.

**8. How do we ensure context never makes ADAM hallucinate or infer things that
aren't there?**
Three structural guarantees, none of them a regex: (a) every tier has an
explicit empty form so absence is never a blank to fill; (b) context specificity
is gated by `knowledge_depth` exactly as replies are — a level-1 context
physically cannot contain a pattern sentence; (c) the permission line names, in
the same words the gate enforces, what this level of context does *not* license.
Part 8 details each.

**9. How do we measure whether the context we gave actually improved the
experience?**
A context-level rubric (Part 9), scored on real sampled turns: Context
Groundedness (every context byte traces to a real row), Context Utilization (did
the reply *use* what was given, or ignore it), Absence Honesty (was empty stated,
not implied), Compression Fidelity (does the snapshot still match the raw
source), and Freshness (does context reflect the latest real state). The null
test: strip Tier B for a sample and measure whether reply quality drops — if it
doesn't, the snapshot is not earning its bytes for that segment.

**10. What is the minimum context ADAM needs to be *very* useful?**
Measured answer, for the 91% of users at levels 0–1: **the child's name (when
known) + a clean conversation buffer + the honest empty-state line.** That is
~2,000 chars, almost all of it the (cleaned) buffer. Everything else is
additive value for the small, deepening segment — and should be *absent*, not
empty, until it is real.

---

# PART 4 — The tiered context contract

The design, as an enforceable table. Each tier: its source, its size budget, its
refresh cadence, its free/paid scope, and — critically — the condition under
which it appears *at all* (absent, not empty, otherwise).

| Tier | Content | Source | Budget | Refresh | Free | Paid | Appears only when |
|---|---|---|---|---|---|---|---|
| **0 — Identity** | Child name, or explicit "no name yet" | `children` | ~1 line | every turn | ✅ | ✅ | always (empty form if no name) |
| **1 — This turn** | Parent's current message | live | — | every turn | ✅ | ✅ | always |
| **2 — Recent talk** | Last ≤10 turns, parent's raw words only | `n8n_chat_histories` (cleaned) | ~2,000 ch | every turn | ✅ | ✅ | ≥1 prior turn exists |
| **3 — Compressed memory** | The evolving snapshot | `memory_snapshots` | ≤450 ch | on W2 write | ⛔ (see 6) | ✅ | a snapshot exists |
| **4 — Confirmed patterns** | Named recurrences | `child_patterns` (confirmed) | ~2 lines | on W2 write | ✅ if exists | ✅ | ≥1 *confirmed* pattern |
| **5 — Journey** | Objective, phase, progress | `stage_state()` | ~4 lines | every turn | ⛔ | ✅ | a live stage exists |
| **Permission** | What this level may claim | `knowledge_depth` | ~1 line | every turn | ✅ | ✅ | always |

Two rules govern the table:

- **Absent-not-empty.** A tier whose source is empty does not emit a header. The
  model never sees `== PATTERNS ==` followed by nothing — it sees no pattern
  block at all, and the permission line tells it patterns are not yet knowable.
- **Free/paid is a Tier-3/5 difference only.** Tiers 0,1,2,4,Permission are
  identical. The paid parent differs by carrying the *cross-week compressed
  memory* (Tier 3) and the *journey* (Tier 5). Nothing about the *voice* or the
  *helpfulness* of Tiers 0–2 changes. This is the product decision from Part 2
  made mechanical.

Note Tier 4 is available to free users *if a confirmed pattern exists* — because
withholding a true, earned pattern would be withholding help, which Part 2
forbids. What free does not get is the *compressed narrative memory* (Tier 3)
that makes ADAM feel like it has known you for weeks. That continuity is the
paid value.

---

# PART 5 — A real free-user path (redacted, from production)

Reconstructed from a real level-progression, names redacted. Shows exactly what
context each turn carries under this design.

**Turn 1 — first message.** Parent: *"[الطفل] عندو 3 سنين ويعيط برشا في الليل."*
- Tier 0: no name yet on file → `لا شيء مسجّل عن هذا البيت بعد`
- Tier 1: the message
- Tiers 2–5: **absent** (no history, no snapshot, no pattern, no journey)
- Permission: level 0 → "لا تعرف عن هذا البيت شيئاً بعد."
- **Total context ≈ 90 chars.** ADAM answers the moment, may ask one grounding
  question. It cannot invent a pattern because the context physically contains
  none and the permission line forbids it.

**Turn 4 — name now known, one situation confirmed.** Parent has mentioned the
child's name and that bedtime is the hard point.
- Tier 0: the name
- Tier 2: last 3 turns, parent's raw words (post-fix — not the scaffolding)
- Tier 4: **absent** (situation is confirmed but not yet an evidenced *pattern*
  — 1 confirmed situation ≠ 3 nights logged)
- Permission: level 2 → "تعرف الاسم وما يُتعب عادةً… ممنوع قول «المرة الثالثة»."
- **Total ≈ 700 chars.** ADAM may aim one step at bedtime. It may not say "this
  keeps happening" — level 2, no pattern in context.

**Turn N — free, weeks later, new conversation.** Parent returns after 3 weeks.
- Tier 2: only the *current* session's turns (the buffer is per-session)
- Tier 3: **absent — this is the free ceiling.** ADAM does not carry a compressed
  memory of the earlier weeks. It re-meets the family warmly, uses the name
  (Tier 0 persists — the child row is permanent), helps fully — but does not say
  "last time we…" because it genuinely does not have that, and Part 8 forbids
  implying it.
- **This is the felt difference of not paying:** not worse help, shorter memory.

---

# PART 6 — A paid-user path (design; 0 paid users exist, so this is constructed)

**Stated honestly: zero paid journeys have ever run. This path is designed from
the tested engine logic (`compose_journey_step`, `stage_state`), not observed.**

Same family as Part 5, now inside a paid journey with an agreed objective ("خمس
ليالٍ هادئة من سبع").

**Day 1–2 — observe phase.**
- Tier 3 (snapshot): the compressed memory now *persists across sessions* — "[الطفل]
  3 سنين، الصعوبة وقت النوم، الأم متعبة، اتّفقنا نراقب قبل ما نغيّر."
- Tier 5 (journey): objective + phase=observe + progress 0/5
- Journey directive: "لا تقترح خطوة جديدة — الهدف أن تُلاحَظ اللحظة."
- Context *deliberately thin*. ADAM watches, does not prescribe. The paid parent
  is not getting *more instructions* than a free one — they are getting a
  *disciplined* one.

**Day ~10 — build phase.**
- Tier 3 has deepened: "…جرّبنا تهدئة الغرفة قبل النوم بساعة، الليالي الهادئة
  زادت." — the snapshot now carries *what worked*, its highest-value state.
- Tier 5: phase=build, progress 3/5
- ADAM may reference the objective and build on yesterday. This is the moment
  the compressed memory earns its entire existence: continuity a free re-meeting
  cannot have.

**Day ~24 — hold phase.**
- Tier 5: phase=hold. Directive: "ممنوع اقتراح أي خطوة… دورك تسأل عن الليلة بلا
  اقتراح، ليُرى الهدوء أنه ملكهم."
- Tier 3 *stops adding steps* and starts naming the parent's competence.
- **Context volume falls on purpose.** The paid experience ends with ADAM
  fading, not intensifying — and the context design is what makes that possible,
  because the journey tier tells it to withhold.

The paid difference, across the whole path: **the same warm voice, carrying a
memory that persists and a phase that disciplines it.** Not more help per turn —
*continuous* help across time.

---

# PART 7 — Compression: turning history into a 450-char memory

The four real July snapshots are the proof of format. Anatomy of one (redacted):

> *"[الطفل] (ذكر) يواجه تحدي الخوف من السباحة، حيث يترجم التشجيع الزائد كضغط…
> [الأم] تحاول ممارسة دور 'مرساة الأمان' عبر الاحتواء الصامت… التحدي الرئيسي هو
> التنسيق مع [الأب] الذي يميل للدفع المباشر… تم الاتفاق على جعل تجربة السباحة
> تدريجية. الأنماط النشطة: التمركز حول الذات، والتجمد عند الصعوبة."* (396 ch)

What it keeps, and why:
- **The child + the one core challenge** — the anchor.
- **The parent's emotional trajectory** ("kانت… لكنها الآن…") — the single most
  useful thing for warmth, and impossible to reconstruct from raw tables.
- **The one agreed direction** — so ADAM never contradicts it.
- **Confirmed patterns as a short list** — not events, patterns.

What it drops: every timestamp, every raw event, every count, every incident
that is not load-bearing. **It is a rewrite of meaning, not a truncation of
log.** This is why it must be produced by a *model* (the W2 writer), not a SQL
`string_agg` — and why the raw tables (events, logs) are *source*, not context.

**The compression contract:** the snapshot must be *reconstructible* — a
`built_from.last_history_id` marks how far it has read, so it can be rebuilt
incrementally and audited against source (Part 9's Compression Fidelity). It
must never contain a fact absent from the source tables — the writer summarises,
it does not invent. This is the one place the free/paid line is drawn, so its
integrity is the product's integrity.

---

# PART 8 — Anti-hallucination, at the context layer

The Constitution addresses hallucination at role/prompt/gate. This addresses it
one layer earlier — at what the context *contains* — which is more powerful
because the model cannot repeat a fact it was never given:

1. **Absence is a value, not a blank.** Every tier has an explicit empty form.
   The model is never handed `== PATTERNS ==\n` with nothing under it (a cue to
   produce patterns); it is handed no pattern block and a permission line saying
   patterns are not yet knowable.
2. **Context specificity is knowledge-gated, structurally.** `get_agent_bundle`
   already gates the permission line by level; this design extends the same gate
   to *tier inclusion* — Tier 3/4/5 cannot appear below their evidence
   threshold, so a low-evidence context is *physically incapable* of carrying a
   high-specificity claim.
3. **The buffer carries the parent's words, never ours.** The contamination fix
   (separate doc) is a context-engineering fix: it stops the system's own
   scaffolding from re-entering as "what the parent said," which is the purest
   form of context-induced hallucination — the model treating its own notes as
   the family's history.
4. **Compression never invents.** The snapshot writer is constrained to
   summarise source rows; Compression Fidelity (Part 9) audits this on a sample.
   A snapshot that says "الأب يدفع مباشرة" when no source row mentions a father
   is a context-layer hallucination and is caught by comparison to source, not
   by reading the reply.

---

# PART 9 — Measuring whether context helped

Context-level rubric, scored on a real sampled turn, independent of reply
quality (a good reply despite bad context, or vice versa, is diagnostic):

| Criterion | Definition | Fails when |
|---|---|---|
| **Context Groundedness** | Every context byte traces to a real source row | A context sentence has no backing row |
| **Context Utilization** | The reply demonstrably used a context fact it was given | Rich context, generic reply that ignored it |
| **Absence Honesty** | Empty tiers stated explicitly, never blank or implied | A blank the model then filled |
| **Compression Fidelity** | The snapshot matches its source tables | Snapshot asserts a fact absent from source |
| **Freshness** | Context reflects the latest real state | Snapshot/patterns stale vs newer logs |
| **Budget Discipline** | Total context ≤ the tier budgets | Context bloated with dormant/empty structure |

**The decisive experiment — the null test.** For a sample of paid-eligible
turns, strip Tier 3 and re-score reply quality. If quality does not drop, the
snapshot is not earning its bytes for that segment and the design is wrong for
them. This is how "did context help" becomes falsifiable rather than asserted —
the same discipline the copy gate used (measure before trusting), applied to
context.

---

# PART 10 — What to delete, defer, and light up

The founder's "delete 80%" instinct, made precise against the data:

**Delete now (true waste):**
- The **contamination** in Tier C — ~50% of the buffer's bytes on a level-2
  turn are the re-injected scaffolding. This is the real 80%-of-the-wrong-layer.
- Any **empty structural header** — ship absent-not-empty, removing the dormant
  `PATTERNS`/`KEY_MOMENTS`/`JOURNEY` scaffolding for the ~99% who have no data.

**Defer (real, but not yet):**
- Tiers 4/5 for the population — they are correctly built and correctly *absent*
  until their writers (W2, the journey engine) run and produce real rows. Do not
  delete the machinery; keep it dark.

**Light up (the one high-value dormant tier):**
- **Tier 3, the compressed snapshot** — the single highest ratio of usefulness
  to bytes in the whole system, proven by the four July examples, currently
  frozen because W2 is off. Turning on *only the snapshot-writing path* (not the
  whole W2/W3 apparatus, not the cost the founder is controlling) is the one
  additive context move the data actually justifies. **This is a proposal to be
  evaluated, not built here** — including its cost, which is the reason W2 is
  off and must be weighed before anything runs.

**The net:** context does not get bigger. The dominant layer gets *smaller and
cleaner*; the structured layers get *honestly absent* instead of emptily present;
and exactly one dormant tier — the one that carries weeks of meaning in 450
chars — is proposed for revival. Least context, most useful.

---

*Design and analysis only. Nothing here has been applied to a prompt, a
function, a workflow, or production. The next step, if approved, is to decide
which of Part 10's three buckets to act on and in what order — not to build any
of them yet. The one item with a real ongoing cost (reviving the snapshot
writer) is flagged explicitly for the founder's cost decision before any
implementation.*
