# ADAM — Full Product Context Audit

**Written:** 2026-08-12. **Read-only. Nothing built, modified, or deployed to
produce this document.** Every claim below is tagged `[CONFIRMED]` (verified
directly — a file quote with line reference, or a live query run this session),
`[INFERRED]` (a reasonable conclusion from confirmed evidence, not itself
directly stated anywhere), or `[UNKNOWN]` (genuinely not established by
anything read). Production evidence was queried live against
`aajqbmjasnbwwyvgrlzy` at the time of writing (2026-08-12, ~16:50–17:00 UTC).
Documentation evidence was gathered by three parallel read-only research
passes over 25 previously-unread or partially-read docs, each returning
file:line-quoted extracts, which this report synthesizes alongside this
session's own direct SQL/code work.

**The single most important finding, stated up front so it isn't buried:**
this audit surfaced a document — `docs/adam-architecture.md` v4, dated
2026-07-30, self-declared "Single Source of Truth" — that **this session's own
prior work never read or cross-checked against**, despite that work (the
Constitution, the context contract, the journey/baseline SQL deployed today)
overlapping substantially with what that document specifies. Where they agree,
this is reassuring but coincidental, not verified alignment. Where they might
disagree, this audit could not always tell, and says so explicitly.

---

# 1. PRODUCT END STATE

**What ADAM is.** *"ADAM is an operating system for personal parenting
companionship. The conversation is not the product. The outcome is."*
(`adam-architecture.md:74-76`) `[CONFIRMED — but from a document this session
never previously read]`. Not a course, content library, diagnosis tool,
therapist replacement, or "chatbot that is impressive to talk to"
(`adam-architecture.md:84`) `[CONFIRMED]`.

**Who it is for.** Primary persona: an exhausted parent, 25–44, Arab world,
1–3 children aged 2–11; 57.6% women / 18.5% men in the stated persona split
(`adam-architecture.md §0.8`) `[CONFIRMED]`. Job-to-be-done, quoted exactly:
*"When my child does something I can't handle and I feel myself losing
control, I want to not become the parent I'm ashamed of, so that my child
remembers a home that was safe."* (`adam-architecture.md:244-247`)
`[CONFIRMED]`.

**What problem it solves.** Not a child-behavior problem — a parent
self-regulation / identity problem. `product-proposal-2026-07.md:88`: *"a
state-access gap,"* not an information gap `[CONFIRMED]`. Corroborated by
`product-research-2026-07.md:231`: *"the parent is hiring ADAM to change
their own identity."* `[CONFIRMED]`. The "enemy," per the brand documents:
*"That the family lives the same story, over and over, without anything
changing"* (`adam-promise.md:406-408`) `[CONFIRMED]`.

**What the parent experiences, and why they'd return.** Free: unlimited
conversation, full intelligence, no cap on quality, a nightly rhythm once
enough is known. Paid: the same voice, plus a named, falsifiable goal driven
daily. Repeat use is explicitly framed as *not* habit-loop retention but
earned trust: `adam-brand-bible.md:225`: *"ADAM is the one who stays after
everyone else has left"* `[CONFIRMED]`.

**What makes ADAM different (stated repeatedly, near-verbatim, across three
independent documents — the strongest point of cross-document agreement found
in this whole audit):**
&gt; *"Free is knowledge; paid is labour."* / *"المجاني: أن تكون القصة أخفّ.
&gt; المرافقة: ألّا تتكرّر القصة."* (`adam-architecture.md §0.5/§3.8`,
&gt; `adam-brand-bible.md:333-334`, `adam-brand-experience.md:39`)
&gt; `[CONFIRMED]`

**What the parent is actually paying for.** *"Not better answers. It's a
duration of commitment."* (`adam-brand-bible.md:336`) `[CONFIRMED]`. Free is
explicitly stated to be **not** crippled: *"full intelligence, full memory, a
step every day"* (`adam-brand-bible.md:336`) `[CONFIRMED]`. What's sold is an
**attempt at an outcome**, ending "by arrival or by admission [of failure] —
not by cancellation" (`adam-brand-bible.md:337`) `[CONFIRMED]`.

**Why the paid tier has legitimate value, without free being artificially
worsened.** This is the product's own explicit design constraint, not just a
nice property: P15 "Free is never crippled," P17 "ADAM never sells," the
"removal test" (§0.4: if removing all mention of price/payment leaves nothing,
the message is "advertising disguised as conversation") `[CONFIRMED,
`adam-architecture.md §0.3-0.4`]`. This session's own `adam-context-contract.md`
§Q3 independently arrived at the same conclusion (continuity + structural
commitment, not information rationing) without having read this source
document — convergent, not verified-against-source `[INFERRED — the
convergence is real, but was not cross-checked at the time]`.

**First interaction.** Canonical current text
(`telegram-logic.md:270-281`, superseding two earlier draft versions found in
`founder-review-2026-07-31.md` and `telegram-ux.md`):
```
السلام عليكم 🌿
أنا آدم — أرافق الأهل مع أطفالهم، يوماً بيوم.
احكِ لي ما حدث اليوم مع طفلك، بكلماتك.
```
`[CONFIRMED]`. No form, no menu tap required first — typing is the only
action `[CONFIRMED]`.

**Following days.** Free rhythm: nightly check-in once enough is known, no
pressure. Once 3 outcomes exist, the Mirror fires. Once a recurring situation
+ enough evidence exist, the agreement moment becomes reachable
`[CONFIRMED, multiple docs, and directly matches this session's own SQL
(`knowledge_depth`, `suggest_objective`, `the-agreement-moment.md`)]`.

**Across the paid journey — THE "Day 30" QUESTION, answered precisely because
this audit found the exact document where it changed:**

This is genuinely unresolved across the document set, and — critically — this
audit found that **two entirely different "30 days" exist in this product's
history, and conflating them would be a real error**:

1. **The subscription billing window — real, currently live, confirmed by
   production data today.** `activate_subscription`'s live signature defaults
   `p_days := 30` `[CONFIRMED, read directly from the live function body,
   2026-08-12]`. All 4 real historical payments (see Part 11) ran exactly a
   30-calendar-day `subscription_started_at`→`subscription_expires_at` window
   `[CONFIRMED, queried live]`. This 30 is a **billing** concept.
2. **The coaching-journey length — explicitly redesigned away from a fixed 30
   days.** `journey-architecture.md` (2026-07-29) states its own header:
   *"Supersedes: the single-30-day-Journey model in `product-blueprint-v1.md`
   §14, §19"* `[CONFIRMED, `journey-architecture.md:3`]`, replacing it with
   **variable, problem-specific durations (14/21/21/14/30/14/45 logged days)**,
   explicitly flagged by its own author as *"hypotheses, not evidence... the
   current system has 21 `daily_logs` rows total"* `[CONFIRMED,
   `journey-architecture.md:238`]`. `architecture-review.md` (same date)
   refines the unit further: *"the clock counts logged days, not calendar
   days... A 14-day stage means 14 days on which she logged"* `[CONFIRMED,
   `architecture-review.md:67`]`. The live `stages` table's own CHECK
   constraint (`planned_logged_days BETWEEN 7 AND 60`) `[CONFIRMED, read this
   session]` matches this variable-length design, not a fixed 30 — meaning the
   **schema currently deployed already reflects the newer, variable-length
   design**, even though nothing has ever populated it with a real journey.

**What happens at "Day 30" / journey end, per the newest, self-declared
authoritative document:** not a renewal, not an expiry message, not a sales
moment. *"ADAM never sends a renewal, expiry, or payment message. Ever.
Automated dunning is permanently banned."* (`adam-architecture.md:175`)
`[CONFIRMED]` — framed as a hard lesson from a real prior incident: the old
"Renewal Guard" sent a dormant parent a fabricated 2,300 DZD demand to a
personal bank account (`adam-architecture.md:173-175`) `[CONFIRMED]`. Instead:
a 4-stage review session (celebrate, measured against the real start → honest
assessment → next-goal analysis, explicitly "not an offer" → the parent's own
decision, with buttons including "نكمل كما نحن" [we continue as we are] as a
**first-class, cost-free outcome**, and *"No follow-up. No second mention.
Ever"* (`adam-architecture.md:890-1005`) `[CONFIRMED]`.

**What happens after "Day 30" — HONESTLY UNRESOLVED, per the product's own
most recent internal audit.** `adam-system.md`, dated with production data
from **2026-08-01** (the freshest empirical snapshot found in this whole
corpus), explicitly flags: *"بعد الوصول | ؟ | 🔴 غير مصمَّم"* ["After
reaching the goal | ? | 🔴 Not designed"] (`adam-system.md:222`) and *"ما بعد
الوصول غير موجود. انتهت الرحلة — ثم ماذا؟... غير مصمَّمة"* ["What comes
after doesn't exist. The journey ended — then what?... not designed"]
(`adam-system.md:224-226`) `[CONFIRMED]`. A later design pass
(`after-arrival.md`, 2026-08-07) addresses this on paper (arrival moment,
"ماذا الآن" second-goal offer, a 30-day *free* relapse watch — explicitly:
*"It is free, and it must stay free. Charging for the return is charging for
the failure of the thing they already paid for"*, `after-arrival.md:137`
`[CONFIRMED]`) — but `after-arrival.md`'s own build table shows only
`close_stage` returning `completed` as actually built at that time; the
arrival moment, the "ماذا الآن" moment, the reading-state, the relapse watch,
and the relapse message are all listed as **not yet built**
(`after-arrival.md:161-176`) `[CONFIRMED]`. `what-is-missing.md` claims this
whole design was **"BUILT the same day"** (2026-08-07) — a claim its own
sibling document's build table does not support `[CONFIRMED CONTRADICTION —
see Part 16]`.

**Bottom line for this section, stated plainly:** there is no single current
answer to "what happens across 30 days and after." Three incompatible
generations of answer exist in the documented history (monthly-subscription
dunning → one-time-30-day-purchase-with-repurchase-report →
outcome-based/no-fixed-length/no-dunning-ever), the newest is the one this
audit treats as currently intended, and even that one's own post-journey UX
is explicitly logged by the product's own most recent internal audit as
**not designed** `[CONFIRMED]`.

---

# 2. ADAM'S ROLE AND IDENTITY

This section is where this session's own work (the Constitution,
`docs/adam-constitution.md`) is the most directly on-point and most heavily
tested source — it was purpose-built to answer exactly these questions, and
was cross-checked this session against real production replies. Restated here
with tags reflecting how it was actually established:

- **Role:** the one continuous conversational voice; renders what the product
  knows, does not decide it `[CONFIRMED — `adam-constitution.md` Identity/
  Non-responsibilities, itself built by reading the live prompt and real
  replies]`.
- **Boundaries:** does not run the journey, does not author memory, does not
  classify crisis, does not sell `[CONFIRMED, same source]`.
- **Personality/tone:** warm, gender-neutral, plural-imperative Arabic
  (derja-adjacent), no titles, no foreign words, no markdown formatting
  `[CONFIRMED, live prompt text + Constitution Voice section]`.
- **Verbosity/rhythm:** default 2-3 lines, breakable in the parent's favor,
  never padded `[CONFIRMED, live prompt + tested]`.
- **Questions:** at most one per reply, never stacked into a form across turns
  `[CONFIRMED, live prompt + `agent_bundle_test.sql`/`grounded_reply_test.sql`
  assertions]`.
- **Suggestions/steps:** at most one per reply, only when evidence supports
  aiming it `[CONFIRMED]`.
- **Reflection:** a complete, successful move when nothing more specific is
  honestly available — not a fallback `[CONFIRMED, the 2026-08-11 prompt
  addition, still not pushed to the live n8n node — see Part 11]`.
- **Uncertainty:** must be sayable and treated as success, not failure
  `[CONFIRMED, design intent; **partially unverified live** — the prompt
  clause exists in the repo but the live n8n node has not been re-verified
  byte-identical since 2026-08-06, per that file's own header]`.
- **Never pretend to know / never claim to have done something / never
  diagnose / never promise / never sell / never delegate unnecessarily:** all
  explicit Prohibitions in `adam-constitution.md` Part 1, each traced to a
  real historical failure example (e.g., a real 2026-07-10 reply that
  delivered a confident, unhedged psychological diagnosis) `[CONFIRMED]`.
- **Weak evidence → less specificity; strong evidence → more, never
  invented:** *"عندما تقلّ الأدلة، تقلّ درجة التحديد؛ لا يزيد الاختراع"* —
  the founder's own stated governing rule, now present in the live-staged
  prompt text, in `get_agent_bundle`'s permission line (deployed today), and
  enforced independently at `gate_grounded_reply` (also deployed today)
  `[CONFIRMED — this is the one identity element with three independent,
  cross-checked layers, verified this session with real production smoke
  tests]`.

**What this section cannot confirm:** whether this Constitution-level
identity is fully consistent with `adam-architecture.md` v4's five-engine
framing and P1–P24 numbering — **the two were never cross-checked against
each other** `[UNKNOWN — a real gap this audit exists to surface, not
resolved by it]`.

---

# 3. USER EXPERIENCE

| Stage | User's goal | System goal | ADAM knows | ADAM does not know | Context ADAM gets | Decisions/data created | Status |
|---|---|---|---|---|---|---|---|
| **Acquisition** | — | — | — | — | — | — | `[UNKNOWN]` — no doc in this audit's 25-file pass describes an acquisition channel. The only trace is a deferred "Instagram deep-link" item, explicitly not built (`telegram-ux.md:160`) `[CONFIRMED absence]`. |
| **First contact** | Be heard once, without a form | Answer the moment, ask nothing | Nothing (level 0) | Everything | Empty structured context; permission line says so explicitly | `followers` row created | `[CONFIRMED live]` |
| **Onboarding** | — | Name earned "in passing," never as a form | Whatever is volunteered | Most things | Grows turn by turn | `children`, `situations` rows via `commit_child_name`/`commit_situation` | `[CONFIRMED live]` |
| **First conversation** | Feel specifically understood | Full-voice, honest-if-empty reply | Level 0-1 typically (91% of real users per this session's own production measurement) | Patterns, journey | Structured context ~12 chars median (this session's own measurement) | Chat buffer row | `[CONFIRMED]` |
| **Free experience (ongoing)** | Be helped, repeatedly, for nothing | Same voice every time, growing context as evidence grows | Grows with `knowledge_depth` | No journey, no cross-week snapshot | Same tiers as paid minus JOURNEY/snapshot | `child_patterns`, `daily_logs` (rarely — see Part 11) | `[CONFIRMED]` |
| **Transition to paid — لحظة الاتفاق** | Agree a real destination, before any money | Split the hard decision into two easy ones | The confirmed situation only | — | `suggest_objective` gate | `stage_proposals` row, `followers.agreed_objective` | `[CONFIRMED — built and tested 2026-08-11, `the-agreement-moment.md`]` |
| **Paid onboarding (payment confirmed)** | — | Turn a receipt into a journey, exactly once | — | — | — | `activate_subscription` calls `start_stage` **unconditionally**, reading the agreed goal if present `[CONFIRMED — read live function body this session]` | **Live, unified** |
| **Daily interaction (paid)** | A daily nudge toward the goal | Phase-appropriate step, never contradicting the phase | JOURNEY block + (as of today) the baseline sentence | — | `get_agent_context`/`get_agent_bundle`, deployed today | `daily_logs` via `record_seed_sent`/`record_harvest_answer` | **SQL live** `[CONFIRMED, deployed+smoke-tested today]`; **delivery not live** — W3's `journey_step` compose+send branch remains unbuilt in the actual n8n node graph (`docs/workflows/w3-journey-step-branch.md`: "SPECIFIED, not wired") `[CONFIRMED]` |
| **Journey stages (observe/build/hold)** | — | See Part 9 | Phase-appropriate | — | Journey directive, phase-gated | `stages.status`, `daily_logs` | **Never exercised by a real paid user** `[CONFIRMED — 0 stages rows ever, live query today]` |
| **Progress** | See real movement | Never invent it | `stage_state()`'s live-computed numbers | — | JOURNEY block's `progress` line | — | `[CONFIRMED, mechanism live; never populated by real data]` |
| **"Day 30" / journey end** | — | Review session, not expiry | — | — | — | — | **Designed, largely unbuilt** — see Part 1 `[CONFIRMED]` |
| **Post-journey** | — | — | — | — | — | — | `[UNKNOWN/explicitly "🔴 not designed" per the product's own newest audit — `adam-system.md`]` |

---

# 4. FREE VS PAID

**What free ADAM knows:** exactly what the evidence supports — name (if
known), confirmed pattern (if any), recent days. Identical to paid at the
same knowledge level `[CONFIRMED, `adam-context-contract.md` §3/§6, itself
verified this session with real tokenizer measurement and a leave-one-out
test]`.

**What paid ADAM knows, additionally:** the live journey's objective, phase,
progress (`JOURNEY` block), and — as of today — the one-sentence historical
baseline, shown only when current data is strictly better than where the
stage started `[CONFIRMED, deployed and smoke-tested against real production
today]`.

**Memory/continuity:** free carries no memory across sessions beyond the
10-message conversational buffer (currently contaminated — see Part 7) and
whatever `child_patterns`/`children` structurally hold. Paid additionally
carries the one-time baseline sentence, permanently, for the life of the
stage `[CONFIRMED]`.

**What is intentionally NOT restricted from free users:** the full voice,
full length, full detail on request, confirmed patterns, the complete
"recipe" if asked "كيف بالضبط؟" `[CONFIRMED, live prompt text, unchanged
since 2026-07-31 per its own file header]`.

**Why paid has legitimate value without free being artificially worsened:**
this session's own `adam-snapshot-value-test.md` ran the actual A/B/C
comparison and found the honest answer is narrower than first assumed —
paid's real, defensible edge is a single, specific capability (a grounded
"how far you've actually come" comparison), not a general quality
improvement `[CONFIRMED, this session's own value test, Question 1-2]`.

**Contradiction found by this audit, not previously known to this session:**
`free-vs-paid-review.md` (2026-08-06) — written by an earlier pass of this
same project, five days before today's deploy — states as fact: *"Same ADAM,
same system prompt, same memory, same rhythm, same (absent) cap... A parent
who pays 110 dirhams today receives the free product, plus a Telegram
conversation with a human"* (`free-vs-paid-review.md:92-95`) `[CONFIRMED
quote]`. **This was true on 2026-08-06 and remained true, for real paying
customers, until the deploys made earlier today (2026-08-12) — meaning the
gap this document describes was real, live, and affected the only 4 real
paying customers this product has ever had** `[CONFIRMED, cross-referenced
against this session's own production query: all 4 real payments predate the
journey-context deploy by roughly six weeks]`.

---

# 5. CONTEXT ENGINEERING

This is the area this session did the most first-hand, tested, measured work
on. Table reflects the state **after today's deploy**, verified live:

| Component | Source | Purpose | Who receives it | Freshness | Approx. size | Evidence | Status |
|---|---|---|---|---|---|---|---|
| System prompt | `docs/prompts/adam-conversation-agent.md`, n8n node `paid aget adam` | Static voice/behavior | Everyone | Static per deploy | ~2,538 tokens (measured, `gpt-tokenizer`) | This session, real tokenizer run | **Repo ahead of live node** — the 2026-08-11/12 clauses (honest-silence, journey-directive-binding, no-diagnosis, etc.) are **not yet pushed** `[CONFIRMED, file's own header]` |
| `DAYS_LEFT` | `followers.subscription_expires_at` | Billing clock | Nobody — stripped in `get_agent_bundle` | Live | ~10 tokens, discarded | Read this session | Deployed, correctly excluded |
| `CHILDREN` | `children` | Name/age/gender/temperament | Everyone with a named child | Live, every turn | ~6-18 tokens | Read this session | Deployed |
| `PATTERNS` | `child_patterns` where `status='confirmed'` | Earned, structural fact | Everyone (not payment-gated) | Live | ~21 tokens | Read this session | Deployed; **0 confirmed patterns exist in production today** `[CONFIRMED, live query]` |
| `KEY_MOMENTS` | `memory_events` | Raw recent events | Everyone | Live | ~72 tokens when present | Read this session | Deployed, but this session's own review flagged it as duplicative and recommended cutting it — **not acted on** (out of scope for the approved build) `[CONFIRMED]` |
| `RECENT_DAYS` | `daily_logs`, last 3 | Recent outcomes | Everyone | Live | ~78 tokens | Read this session | Deployed; **only 3 of 70 `daily_logs` rows in production have a real `night_result`** `[CONFIRMED, live query]` |
| `JOURNEY` | `stage_state()` | Objective/phase/progress | Paid, live stage only | Live, every turn | ~49 tokens | Deployed + smoke-tested today | **Live as of today**; never yet seen by a real paid conversation (0 live stages) `[CONFIRMED]` |
| Journey directive | `get_agent_bundle`, phase-keyed | Behavioral instruction matching `compose_journey_step` | Paid, live stage only | Live | ~46 tokens | Deployed + smoke-tested today | **Live as of today** |
| `allowed_moves` | `knowledge_depth().now_possible` | Enforced move-set, not prose | Everyone | Live | data, not prose | Deployed + smoke-tested today | **Live as of today** |
| Baseline (Paid Snapshot v1) | `stages.baseline_text` | One historical anchor sentence | Paid, only when strictly better than the start | **Written once**, read live, suppressible | ~30 tokens (measured) | Deployed + smoke-tested today | **Live as of today**; 0 stages exist to populate it |
| `memory_snapshots` (SUMMARY) | LLM-written, W2-adjacent ("machine_3") | Cross-week compressed memory | Whoever has one | **Frozen** — writer inactive | ~300-450 chars when present | Read this session (production query) | **4 non-empty rows exist, all from July; writer not currently running** `[CONFIRMED]`. No n8n workflow named "machine_3" exists among the 5 live workflows checked this session `[CONFIRMED — this is a genuine unresolved provenance gap]` |
| Conversation buffer | `Postgres Memory Paid` (n8n, LangChain) | Recent-turn continuity | Everyone with prior turns | Live, ~10-message window | ~650-1,300 tokens (measured; exact window mapping unverified — see Part 7) | This session, `execute_sql` reproduction proof | **Contaminated** — fix designed, proven, **not deployed** |
| `gate_grounded_reply` | new, deterministic | Anti-hallucination backstop | Every reply | Live | n/a (gate, not context) | Deployed + smoke-tested today | **Live as of today** |

**Implemented vs staged vs deployed vs proposed vs deprecated, stated plainly:**
- **Deployed today, verified live:** `JOURNEY`, journey directive, `allowed_moves`,
  `gate_grounded_reply`, the Paid Snapshot v1 baseline.
- **Designed and proven, not deployed:** the memory-contamination fix
  (`docs/workflows/fix-paid-memory-contamination.md`).
- **Repo-ahead-of-live:** the prompt clauses layered on top of the deployed
  SQL (honest-silence, no-diagnosis, journey-binding, single-topic).
- **Frozen/uncertain provenance:** `memory_snapshots` — real data exists, no
  current writer confirmed, and this audit could not locate the "machine_3"
  process that wrote it `[UNKNOWN]`.
- **Never built, explicitly rejected as a v1 scope:** the tactical-experiment
  clause, a periodic snapshot regenerator, restated `PATTERNS`/`RECENT_DAYS`
  inside the snapshot.

---

# 6. CONTEXT BUDGET

Philosophy, as this session actually established and measured it (not
assumed): **prove every token, don't guess.**

- **Every turn:** framing header, permission line, current message, buffer if
  any prior turn exists `[CONFIRMED, `adam-context-contract.md` §2]`.
- **Only when relevant:** `CHILDREN`/`PATTERNS`/`RECENT_DAYS` (evidence-gated),
  `JOURNEY`/baseline (paid + live stage only) `[CONFIRMED]`.
- **Never reach the LLM:** raw IDs, `parent_gender` (even where populated —
  structural protection of the neutrality rule), country/funnel_stage/billing
  fields, internal engine vocabulary as literal strings, other families' data,
  the system's own scaffolding replayed as if human-authored, `reply_gate_log`
  `[CONFIRMED, `adam-context-contract.md` §9, and independently corroborated
  by `conversation-engine.md`'s own banned-lexicon list — same conclusion,
  two independent sources]`.
- **Compressed:** relationship history → one baseline sentence (not a
  regenerating narrative — cut down from an original 3-clause, LLM-written
  design after this session's own A/B/C test found two of three clauses
  measured zero effect) `[CONFIRMED, `adam-snapshot-value-test.md`]`.
- **Calculated, not described:** the baseline's calm/hard ratio, the
  conflict-suppression comparison — both plain counts, zero LLM involvement
  `[CONFIRMED]`.
- **Current measured budget:** structured tiers ≤350 tokens typical, ≤450
  richest real case; buffer ≤800 tokens recommended (current live window size
  **not independently confirmed** — see Part 7); total dynamic context target
  ≤1,200 tokens, against a **measured** ~2,538-token static prompt
  `[CONFIRMED via `gpt-tokenizer`, this session]`.
- **Where unnecessary context is currently injected:** `KEY_MOMENTS` — this
  session's own review found it duplicative and recommended cutting it; it
  remains live, untouched, because doing so was out of the approved scope
  `[CONFIRMED — a known, named, un-acted-upon inefficiency]`.
- **Free/paid difference:** exactly two tiers (`JOURNEY`+baseline), nothing
  else `[CONFIRMED]`.

---

# 7. MEMORY

| | CURRENT PRODUCTION | STAGED | PROPOSED |
|---|---|---|---|
| Short-term (session) | `Postgres Memory Paid`, LangChain, ~10-message window, keyed on `telegram_id` | — | Fix designed (`text` = raw message only; context moves to `systemMessage`) |
| Long-term (cross-week) | `memory_snapshots` — 4 real non-empty rows, writer status/provenance unconfirmed | — | Paid Snapshot v1's baseline (deployed today) is a **narrower**, separate mechanism — a single historical fact, not a regenerating narrative |
| What's actually stored (short-term) | **The full constructed prompt** (`family_context + parent's message`), not the parent's raw words — confirmed by reading the live node's `text` parameter directly, and by an executed reproduction against the real LangChain classes n8n's node wraps | — | Raw parent message only |
| Contamination problem | The model's own system scaffolding gets replayed, for ~10 turns, labeled as if the parent said it | — | Root-caused and proven with a real, executed test (13/13 checks) — not deployed |
| Must never be stored as human content | System framing headers, permission lines, journey directives | — | Enforced by the fix, not yet live |

`[CONFIRMED throughout — this session's own direct read of the live node and
executed reproduction, `docs/workflows/fix-paid-memory-contamination.md` and
`proof-memory-contamination.mjs`]`.

**Genuinely unresolved:** what process wrote the 4 real `memory_snapshots`
rows, and whether it still runs — no n8n workflow with a matching name was
found among the 5 that currently exist `[UNKNOWN]`.

---

# 8. ANTI-HALLUCINATION ARCHITECTURE

| Layer | Prevents | Cannot prevent | Status | Known weakness |
|---|---|---|---|---|
| 1. Role/identity design | The goal-structure that produces invention ("make them feel known" with nothing to know) | A model ignoring its own framing | Designed (`adam-constitution.md`), partially in the live prompt | Not independently testable without a live model call |
| 2. Context design | Handing the model a fact it doesn't have | — | Deployed today (absent-not-empty, evidence-gated tiers) | `KEY_MOMENTS` still duplicative, unfixed |
| 3. Knowledge-depth constraints | Specificity exceeding real evidence | — | Deployed today (`allowed_moves` as data) | Advisory only at this layer — the gate is what actually enforces it |
| 4. Prompt behavior | Treating honest silence as failure | A model that ignores the instruction | Repo-ahead-of-live — not yet pushed to the node | Cannot be verified live until pushed |
| 5. Structured data constraints | A snapshot clause asserting an unconfirmed fact | — | Deployed today (baseline is template-only, no LLM) | N/A — zero invention surface by construction |
| 6. Memory hygiene | The model treating its own scaffolding as the parent's words | — | **Designed, proven, not deployed** | Live and unfixed today |
| 7. Grounding gate (`gate_grounded_reply`) | Explicit memory claims, past-session references, unfounded repetition counts — lexical, high-precision | **Does not verify that any individual factual claim is true** — it is category-based, not fact-checked. Confirmed blind to un-keyworded strong claims like "دائماً ما يحدث هذا معه" (proven via a live probe earlier this session) | Deployed today | By design, deliberately not expanded — last line of defense, not the primary one |
| 8. Testing/evaluation | Regression on everything already tested (813/813 this session) | Anything not yet exercised by a real paid user (all of Part 9) | Offline-tested, one live smoke pass per deploy | Zero real-world paid-journey data exists to test against |

**Stated explicitly, as required:** `gate_grounded_reply` is lexical and
category-based. It does not, and cannot, prove that a specific factual claim
in a reply is individually true — it only catches a narrow, high-confidence
set of *shapes* of unsupported claim. This was demonstrated directly this
session with adversarial probes that passed the gate untouched
`[CONFIRMED]`.

---

# 9. JOURNEY ENGINE

**Phases**, `stage_state()`/`v_stage_progress` (live, unchanged by today's
deploy except for the added baseline field):

| Phase | Trigger | ADAM may | ADAM must not | Verified |
|---|---|---|---|---|
| Observe | `logged_days < 3` | Reflect, watch | Propose a new step | `[CONFIRMED, live SQL + smoke test today]` |
| Build | `3 ≤ logged_days <` hold threshold | Reference the objective, build on what worked | — | `[CONFIRMED, live SQL + smoke test today]` |
| Hold | `logged_days ≥ allowed_days − max(3, allowed_days/3)` | Ask about the night | Propose any step, ever, even if asked directly | `[CONFIRMED, live SQL]` |

**Transitions:** derived, never hand-set, from `daily_logs` counts against a
live view `[CONFIRMED]`. **Evidence for transition:** a real logged night
with a real `night_result` — and only **3 such rows exist in all of
production today** `[CONFIRMED, live query]`.

**How paid differs:** only paid parents in a live stage get `JOURNEY` +
directive + (as of today) the baseline `[CONFIRMED]`.

**How the journey affects context/behavior:** exactly as described in Part 5
— additive, absent-not-empty, phase-gated `[CONFIRMED]`.

**Designed but never validated by a real paid user — the single largest gap
in this whole audit:** every mechanic above — observe/build/hold, the
baseline, the grounding gate's `pattern:unfounded` check, the extension/
refund/cooldown policy (`architecture-review.md` A1/A9), the after-arrival
design — has **zero real executions**. `stages` has had exactly 0 rows in its
entire history `[CONFIRMED, live query, repeated three times across this
session with consistent results]`. `activate_subscription` now calls
`start_stage` unconditionally on every activation `[CONFIRMED, read live
function body]` — so the *next* real payment, whenever it happens, will be
the very first real test of this entire chain, end to end.

---

# 10. PRODUCT DATA MODEL

Focused on structures that affect behavior, not the full schema:

- **`followers`** — the parent. Carries `funnel_stage`
  (`free_conversation`/`offer_presented`/`paid_active` — live distribution:
  313/8/4 `[CONFIRMED]`), `payment_status`, `subscription_started_at`/
  `subscription_expires_at` (the real, wired billing mechanism),
  `agreed_objective`/`agreed_at` (لحظة الاتفاق's receipt).
- **`children`** — 71 rows, 69 real names `[CONFIRMED]`.
- **`situations`** — the recurring-moment-with-a-window entity, distinct from
  `child_patterns` (a correlation) — `situations` has its own confirmation
  bar (3 independent observations) feeding `knowledge_depth`.
- **`daily_logs`** — the measurement spine. 70 rows total, **3 with a real
  `night_result`** `[CONFIRMED, live query, unchanged all session]`.
- **`stages`** — the physical table for "Journey"/"Stage." 0 rows, ever.
  Schema (`planned_logged_days BETWEEN 7 AND 60`) already reflects the
  variable-length redesign, not a fixed 30 `[CONFIRMED]`. Gained
  `baseline_text`/`baseline_calm_count`/`baseline_captured_at` today.
- **`child_patterns`** — 0 rows with `status='confirmed'` in production today
  `[CONFIRMED]`.
- **`memory_snapshots`** — 4 non-empty rows, provenance uncertain (Part 7).
- **`n8n_chat_histories`** — 4,782 rows `[CONFIRMED, live count today]`. Its
  `created_at` column was backfilled by a 2026-07-10 migration — timestamps
  before that date are **not reliable evidence of real send time**
  `[CONFIRMED — discovered this session while investigating the 4 real
  paying customers, whose `first_msg` was identically 2026-07-10 08:51:33
  across all four]`.
- **Functions worth naming specifically:** `knowledge_depth()` (5-level, drives
  `allowed_moves`), `stage_state()` (all journey facts in one call, now
  including the baseline gate), `activate_subscription()` (now unconditionally
  bridges payment → `start_stage`), `capture_stage_baseline()` (new today,
  deterministic, no LLM), `gate_grounded_reply()`/`gate_agent_reply()` (the
  live reply gate).

---

# 11. CURRENT IMPLEMENTATION STATE

| System | Designed | Built | Tested | Deployed | Production-verified | Notes |
|---|---|---|---|---|---|---|
| ADAM system prompt | ✅ | ✅ | ✅ (offline) | Partial | ⚠️ | Repo has 2026-08-11/12 clauses the live node does not; last confirmed byte-identical 2026-08-06 |
| ADAM constitution | ✅ | n/a (doc) | n/a | n/a | n/a | Never cross-checked against `adam-architecture.md` v4 |
| Context engineering (tiered contract) | ✅ | ✅ | ✅ | ✅ | ✅ | Deployed + smoke-tested today |
| JOURNEY context | ✅ | ✅ | ✅ | ✅ **today** | ✅ | 0 real journeys to observe it working on |
| Knowledge levels / `allowed_moves` | ✅ | ✅ | ✅ | ✅ **today** | ✅ | — |
| Grounding gate | ✅ | ✅ | ✅ | ✅ **today** | ✅ | Lexical, not fact-verifying — see Part 8 |
| Baseline (Paid Snapshot v1) | ✅ | ✅ | ✅ | ✅ **today** | ✅ | 0 stages to populate it |
| Full Paid Snapshot (3-clause design) | ✅ then cut to 1 | Partial | ✅ | Superseded by v1 | n/a | Deliberately reduced after A/B/C testing |
| Paid memory (Postgres conversation buffer) | ✅ | ✅ (live, contaminated) | n/a | ✅ (contaminated version) | ✅ | Fix designed+proven, not deployed |
| Memory contamination fix | ✅ | ✅ (design) | ✅ (13/13, reproduced against real library) | ❌ | n/a | Two n8n parameter edits, specified precisely, never applied |
| Free experience | ✅ | ✅ | ✅ | ✅ | ✅ | Stable, largely unchanged all session |
| Paid experience (differentiated daily content) | ✅ | Partial | Partial | Partial | ❌ | SQL side live today; **W3's actual compose+send nodes for `journey_step` remain unwired** (`w3-journey-step-branch.md`: "SPECIFIED, not wired") |
| Journey engine | ✅ | ✅ | ✅ | ✅ | **❌ — never run for a real user** | 0 stages, ever |
| W2 (Knowledge Writer) | ✅ | ✅ | Partial | n8n `active: false` | — | Live-checked this session |
| W3 (Rhythm Sender) | ✅ | ✅ (11 nodes) | Partial | n8n `active: false` | — | Live-checked this session; `journey_step` branch unbuilt regardless of activation |
| W4 (Mirror Sender) | ✅ (design) | "Partially," per `n8n-architecture.md` | `[UNKNOWN]` | **No workflow by this name currently exists** among the 5 live-checked this session | — | `[CONFIRMED absence — a real, previously unflagged gap]` |
| n8n ADAM workflow (W1, live) | ✅ | ✅ | Partial | `active: true` | ✅ (real traffic: 122 msgs/7d) | Only actively running workflow |
| Database functions (this session's scope) | ✅ | ✅ | ✅ (813/813 offline) | ✅ | ✅ (13/13 + 4/4 live smoke) | — |
| Subscription/payment flow | ✅ | ✅ | Partial | ✅ | ✅ (4 real historical payments) | Now unified with `start_stage`, confirmed live today |
| Onboarding | ✅ | ✅ | Partial | ✅ | Partial | 12 unauthenticated n8n nodes flagged in `telegram-logic.md`; **no later document confirms this was fixed** `[UNKNOWN — not re-verified by this audit]` |
| Day-30 / post-journey experience | ✅ (partially, disputed — see Part 1) | Minimal | n/a | ❌ | n/a | Product's own 2026-08-01 audit: "🔴 not designed" |

---

# 12. WHAT THE FINAL PRODUCT SHOULD FEEL LIKE

Behavioral, not architectural, per the sources read:

- **Notices:** what's actually logged and confirmed — never a pattern it
  hasn't earned the right to name.
- **Ignores:** its own internal state, mechanics, and vocabulary entirely —
  never explains itself, never says "seed," "journey," "tier."
- **Speaks:** when there's something true and useful to say, or when
  reflecting is itself the useful thing.
- **Stays quiet:** in genuine collapse (presence only), and, deliberately, in
  the hold phase (never proposes a step, even asked directly).
- **Asks:** once, specifically, only when the answer would actually move
  things forward — never a form.
- **Reflects:** as a complete, successful answer, not an apology.
- **Suggests:** one small thing, sized for the worst day, only when evidence
  supports aiming it.
- **Uses history:** only what it was actually handed this turn — never
  implies memory it doesn't have (this is the entire reason the memory-
  contamination fix exists and matters).
- **Demonstrates progress:** by comparison to a real, computed starting
  point — never a claimed trend without a number behind it (`adam-experience-
  principles.md` E9: *"Never show progress that did not happen. No head
  starts, no rounded-up numbers, no streaks"* `[CONFIRMED]`).
- **Avoids feeling monitored:** `adam-experience-principles.md` E12: *"She
  never senses a mode... Strain levels, tiers, cohorts, funnel stages — none
  may surface as a perceptible change in ADAM's manner"* `[CONFIRMED, and
  this audit found a live, documented instance of this being violated and
  fixed — `founder-review-2-navigation.md`]`.
- **Avoids robotic/therapist/salesperson registers:** gender-neutral plural
  voice, no clinical language, no closing verbs, no urgency — all enforced as
  hard CHECK constraints in the database, not just prompt instructions
  `[CONFIRMED]`.

---

# 13. PRODUCT PRINCIPLES

| Principle | Source | Tag |
|---|---|---|
| Trust over conversion | `adam-architecture.md` P1/P2/P8/P15/P17 override commercial considerations | `[CONFIRMED]` |
| Real parent problems over revenue optimization | Same, "the removal test" | `[CONFIRMED]` |
| Free support remains genuinely useful | "Free is never crippled" (P15), verified live in the current prompt | `[CONFIRMED]` |
| Paid value from continuity, not more/better answers | `adam-brand-bible.md:336`, this session's own A/B/C test independently confirmed it | `[CONFIRMED, convergent from two independent sources]` |
| Simplicity over feature volume | This session's own pattern (cut 2 of 3 snapshot clauses after they measured zero effect) | `[CONFIRMED — a lived instance, not just a stated value]` |
| Privacy and safety | `/privacy` deletes everything, no questions asked (`adam-system.md:147`); crisis exempt from all commerce gates | `[CONFIRMED]` |
| Evidence over assumptions | This entire audit's own methodology, and the founder's repeated instruction across this session | `[CONFIRMED — enforced instruction, not inferred]` |
| Measurable/testable/evolvable | 813/813 offline suite, real production smoke tests, real tokenizer measurements this session | `[CONFIRMED]` |
| ADAM's honesty about not knowing | The governing rule, three enforcement layers deep as of today | `[CONFIRMED]` |
| No renewal/expiry/dunning messaging, ever | `adam-architecture.md:175`, motivated by a real trust incident | `[CONFIRMED]` |
| No guilt-targeting, ever | `adam-brand-bible.md:302`: "a red line with no exception" | `[CONFIRMED]` |

---

# 14. DECISIONS ALREADY MADE

| Decision | Rationale | Evidence | Status | Dependencies |
|---|---|---|---|---|
| Journey length is variable (14-45 logged days), not fixed 30 | Old fixed-30 model risked exactly the dunning failure that already happened once | `journey-architecture.md`, `architecture-review.md`; schema CHECK constraint matches | **Valid, schema-live**; never populated | Real usage to validate the actual durations, explicitly flagged as unvalidated |
| No automated renewal/expiry messaging | Direct response to a real incident | `adam-architecture.md:173-175` | **Valid** | Whatever eventually handles journey-end must honor it |
| Free is never crippled | Core trust principle | Multiple docs, current live prompt | **Valid, live** | — |
| `gate_grounded_reply` stays narrow, not expanded | Explicit founder redirect mid-session: role/context/prompt first, gate as last resort only | This session's own conversation history | **Valid, deployed today accordingly** | — |
| Paid Snapshot v1 = one-time baseline, not a regenerating narrative | A/B/C test found 2 of 3 original clauses measured zero effect | `adam-snapshot-value-test.md` | **Valid, deployed today** | Real paid-turn data to check the stated success criterion (≥50% utilization) |
| Deploy the whole 08-11 ADAM-contract bundle together with the baseline, not the baseline alone | Deploying the baseline alone would have silently activated an undeployed, unpaired feature set | This session's own discovery, mid-deploy, today | **Executed** | — |
| `activate_subscription` unconditionally starts a stage | Unifies the "legacy" and "journey engine" paths that were previously disconnected | Read live function body this session | **Valid, live** — but never yet exercised by a real payment | — |

---

# 15. OPEN QUESTIONS

**A. Critical blockers**
- W3's `journey_step` compose+send branch is unwired — even a real paying
  customer today would receive no differentiated daily content.
- The memory-contamination fix is proven but not deployed — the live buffer
  is contaminated right now, for any real paid conversation.
- 12 unauthenticated n8n nodes were flagged in `telegram-logic.md`
  (`/start`, all ☰ commands, waitlist, pin, harvest reply) — **no later
  document in this audit's pass confirms this was fixed** `[UNKNOWN]`.
- No W4/Mirror-Sender workflow currently exists under that name — status of
  the Mirror mechanism is genuinely unclear.

**B. Important, non-blocking**
- The live system prompt is behind the repo by two rounds of edits.
- `KEY_MOMENTS` context tier is known-duplicative, not yet cut.
- `memory_snapshots`' writer provenance ("machine_3") is unconfirmed to still
  exist or run.

**C. Future optimization**
- The historical baseline's utilization rate against real turns (the success
  criterion this session itself defined) — cannot be measured until real
  paid turns exist.
- Journey-length hypotheses (14/21/30/45 days) explicitly flagged by their
  own author as unvalidated.

**D. Unknown because the product has not yet been validated with real paid
users**
- Everything in Part 9 (the entire journey engine, end to end).
- Whether the after-arrival design (relapse watch, second-goal offer)
  actually works as intended.
- Whether the Constitution's Voice/Prohibitions, tested only against
  historical replies and hand-constructed examples, hold up against a live
  model call under the new prompt.
- Whether `adam-architecture.md` v4's specific numbers (Value Ladder pricing,
  P1-P24 as a complete set) are still the founder's current intent, given
  this session never referenced them and no later document explicitly
  reaffirms the full v4 spec as still current.

---

# 16. CONTRADICTIONS AND RISKS

Found aggressively, as instructed, not softened:

1. **"No implementation has begun" vs. "already applied" — same 2-day
   window.** `adam-architecture.md` (2026-07-30) closes: *"No implementation
   has begun. Awaiting approval."* `adam-experience-principles.md`
   (2026-07-31, one day later) reports specific UI fixes "✅ Applied" in
   production `[CONFIRMED CONTRADICTION]`.
2. **Two documents, both self-declared "highest authority," disagree on the
   product's own core promise.** `adam-promise.md` explicitly cancels an
   older promise; `adam-brand-experience.md` still opens with, and uses, the
   exact cancelled promise `[CONFIRMED CONTRADICTION]`.
3. **Two different canonical taglines**, each presented as *the* central
   message, in two different top-of-hierarchy documents (`adam-brand-bible.md`
   vs `adam-promise.md`) `[CONFIRMED]`.
4. **"Day 30" itself is three incompatible generations of answer** — see
   Part 1 in full `[CONFIRMED]`.
5. **`what-is-missing.md` claims the after-arrival design was "BUILT the same
   day"; `after-arrival.md`'s own build table says otherwise** for every
   piece except one `[CONFIRMED CONTRADICTION]`.
6. **`the-conversion-seam.md`'s own header says "nothing here is wired"; its
   own build table, in the same document, marks four of five steps "done"**
   `[CONFIRMED — an internal, same-document contradiction, not just
   cross-document]`.
7. **This session's own deployed work was never cross-checked against
   `adam-architecture.md` v4.** Where they overlap (journey phases, no-
   dunning, free-is-never-crippled), they happen to agree — but this was
   verified by this audit, not by this session's own process at the time
   `[CONFIRMED risk, stated honestly]`.
8. **The real, live payment mechanism (30-day calendar subscription) and the
   newer, intended journey model (variable, logged-day-based) are two
   different things that share one bridge function** (`activate_subscription`)
   — the bridge is now unified, but the *billing* clock and the *coaching*
   clock remain conceptually distinct, and no document in this audit's pass
   explicitly reconciles what happens if a 30-day paid subscription expires
   before a 45-day Food-type stage completes `[CONFIRMED gap, INFERRED
   consequence]`.
9. **Baseline vs. current evidence:** by design, the baseline is suppressed
   whenever it would contradict live data — but this rule has never been
   exercised against real data, only synthetic tests `[CONFIRMED status,
   real risk untested]`.
10. **Free/paid philosophy vs. actual historical implementation:** the
    stated philosophy ("paid = continuity + structure, not better answers")
    was, for the only 4 real paying customers this product has ever had,
    **not what they received** — they paid before any of this existed
    `[CONFIRMED]`.

---

# 17. WHAT I DO NOT KNOW

Stated precisely, not filled with assumptions:

- Whether `adam-architecture.md` v4's full P1-P24 principle set, Value Ladder
  pricing, and five-engine framing remain the founder's current, endorsed
  intent, or were themselves superseded by something not in this repo's
  `docs/` directory.
- What acquisition channel actually exists or is planned — genuinely absent
  from every document read, not just unconfirmed.
- Whether the 12 unauthenticated n8n nodes (`telegram-logic.md`) were ever
  fixed — no later document says so.
- What process wrote the 4 real `memory_snapshots` rows, or whether anything
  still runs it.
- Whether a W4/Mirror-Sender workflow exists under a different name, was
  deleted, or was never built past the "partially" state `n8n-architecture.md`
  describes.
- What the actual, current founder-facing pricing is (this repo's SQL uses
  2,300 DZD / similar figures consistent across docs, but no document in this
  audit's pass was checked specifically for pricing currency as of today).
- Whether the after-arrival design's remaining unbuilt pieces (arrival
  moment, "ماذا الآن," relapse watch, relapse message) have progressed since
  2026-08-07 — no later document in this audit's pass mentions them again.
- Whether this session's Constitution and context-engineering work, now
  partly deployed, has been reviewed against `adam-architecture.md` v4 by
  anyone — this audit is the first time the two were read side by side.
- What "Instagram" — named explicitly in the user's own audit request — was
  intended to refer to; nothing in 25 documents read connects it to anything
  built or planned beyond one deferred, undecided line.

---

# 18. FINAL CONTEXT SCORE

**Score: 62 / 100.**

Not a confidence feeling — a rollup across the ten dimensions requested,
each scored against how much of it is CONFIRMED-and-consistent vs.
INFERRED/contradictory/UNKNOWN:

| Dimension | Score /10 | Why |
|---|---|---|
| Product vision | 6 | Multiple, sometimes-contradicting top-authority documents; the newest is usable but was never cross-checked by this session until now |
| User journey | 6 | Well-specified end-to-end on paper; genuinely zero real executions to check it against |
| ADAM behavior | 8 | The most tested, most cross-checked area — real production replies, real gate tests, real deploys |
| Context architecture | 8 | Directly measured, tested, and deployed this session — the strongest area |
| Free/paid model | 6 | Philosophy is clear and convergent across sources; historical implementation contradicted it for every real customer so far |
| Journey engine | 5 | Well-designed, SQL live, but literally never run once |
| Memory | 5 | Short-term contamination understood and proven fixable, not fixed; long-term provenance partly unknown |
| Data model | 8 | Directly read, directly queried, high confidence |
| Implementation state | 6 | Now precisely mapped (Part 11), but several items marked "done" in older docs turned out to be overstated |
| Unresolved decisions | 4 | Real, load-bearing gaps: post-Day-30, W4, acquisition, 12 unauthenticated nodes |

**What prevents 100%:** a real product this size has genuine, load-bearing
unknowns that no amount of document-reading resolves — most importantly,
**zero real paid-journey data exists**, so the single largest untested
surface (Parts 9, 15D) cannot be closed by reading more, only by real usage.

**Is there enough context to safely continue implementation?** For anything
scoped like this session's own recent work (small, offline-tested, SQL-first,
one clear piece at a time) — **yes**. For anything that assumes
`adam-architecture.md` v4's full specification as settled — **not yet**;
that document has never been confirmed current against the founder, and this
audit found real, unresolved tension between it and the product's own more
recent internal audits.

**What must be clarified before continuing, if anything:**
1. Whether `adam-architecture.md` v4 is still the intended target, in full,
   or partially superseded.
2. What "after Day 30" should actually be, given the product's own audit
   calls it undesigned.
3. Whether the 12 unauthenticated n8n nodes and the W4 workflow's actual
   current state need investigating before any further paid-journey work.

---

# 19. FINAL EXECUTIVE SUMMARY

## WHAT I KNOW

The context engineering, gate, and journey-context work deployed today is
real, tested, and live — verified with executed smoke tests against actual
production, not assumed. `activate_subscription` already unconditionally
bridges payment to a real journey start. Free is genuinely not crippled, and
this is enforced structurally, not just stated. The grounding gate is
lexical and cannot verify individual facts — it was never claimed to, and
this audit re-confirms that limit explicitly. Zero real paid journeys have
ever run; every claim about journey behavior in production is design
confidence, not field confidence. The product has real, small, ongoing daily
traffic (122 messages/7 days) — it is not dormant.

## WHAT I THINK

The product's documentation has genuine, unresolved authority conflicts at
its highest level — two "top" documents disagree on the core promise, and
the most architecturally complete document (`adam-architecture.md` v4) was
never checked against this session's own deployed work until this audit. The
"Day 30" question in the original ask turned out to have no single answer
because the product itself changed its mind about it at least three times,
and its own most recent internal audit calls the post-journey experience
undesigned. The free/paid philosophy is well-reasoned and consistent across
independent sources, but it was never actually delivered to any of the 4 real
people who paid — a gap this audit surfaces plainly rather than around.

## WHAT I DO NOT KNOW

See Part 17 in full. Most importantly: whether `adam-architecture.md` v4 is
still current; what happens to a paid subscription if its 30-day billing
window ends before a longer coaching stage does; whether the 12
unauthenticated n8n nodes were ever fixed; what, if anything, still writes
`memory_snapshots`; and whether a Mirror-Sender workflow exists anywhere
under any name.

## RECOMMENDATION

Before building anything else journey- or paid-experience-related: get an
explicit founder decision on whether `adam-architecture.md` v4 is still the
target, and treat the post-Day-30 experience as a real, open design question
— not a detail — since the product's own internal audit already flagged it
as undesigned and this one found nothing since that closes the gap.

---

*Read-only audit. Nothing was built, modified, or deployed to produce this
document.*
