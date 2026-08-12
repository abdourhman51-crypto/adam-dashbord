# PRODUCT BUILD AUDIT — against the 2026-08-12 Final Product Design &amp; Build Contract

**Written:** 2026-08-12. Read-only. Nothing built, modified, or deployed to
produce this document. This audit measures the current code/database/n8n
state **against the contract the founder just issued**, which is now the
reference — not against older docs. Where an older doc disagreed with the
contract, the contract wins; those disagreements are not re-litigated here.

All findings are verified directly against live production (`aajqbmjasnbwwyvgrlzy`)
and the repo, queried again for this audit, not recalled from earlier in the
session.

---

## A. What is complete (matches the contract, already live and tested)

| Contract section | What it asks for | State |
|---|---|---|
| §3, §14 — the journey structure | `stages`/`objective_metric`/`objective_target`/`objective_window`, ~29 planned logged days | **Live, unchanged.** `suggest_objective()` defaults `objective_target=5, objective_window=7, planned_logged_days=29` — matches the contract's own worked example exactly. |
| §4 — the guarantee | Miss the goal → automatic free extension = half the original length | **Live, exact match.** Read `close_stage()` directly: on `clock_exhausted` with `objective_met=false` and no prior extension, it grants `greatest(1, planned_logged_days / 2)` — for 29 days that is **14**, automatically, once, goal unchanged. A second miss closes the stage as `failed`, never a second extension — matches "لا نبيع تمديدًا إضافيًا كوسيلة ضغط." |
| §13 — observe/build/hold | Phase-gated behavior, ADAM fades in hold | **Live**, deployed and smoke-tested today (`stage_state()`, journey directive in `get_agent_bundle`). |
| §8 — absent means absent | Never send an empty/labeled-empty block | **Live**, deployed today across `get_agent_context`'s JOURNEY/baseline lines. |
| §11–12 — Paid Baseline | One-time starting-point sentence; current data always outranks it | **Live, exact match**, deployed and smoke-tested against real production today (`capture_stage_baseline`, `stage_state`'s strict-inequality suppression rule). |
| §16 — grounding | No "أتذكر أنك قلت"/"الأسبوع الماضي" claims unless truly grounded | **Live** (`gate_grounded_reply`, merged into `gate_agent_reply`, deployed today). Lexical/category-based, not fact-verifying — a known, accepted limit, not a gap. |
| §19 — `parent_gender` never reaches the LLM | Structural exclusion | **Confirmed by omission** — `followers.parent_gender` exists as a column but neither `get_agent_context` nor `get_agent_bundle` reference it anywhere in their bodies (re-read in full for this audit). |
| §2, §17 — free/paid same quality | Paid adds continuity, not a better answer | **Live** — `CHILDREN`/`PATTERNS`/`RECENT_DAYS`/permission line are identical for free and paid; only `JOURNEY`+baseline are paid-gated. |
| §15 — evidence-first | No incident→pattern, no suggestion→goal without confirmation | **Live** — `knowledge_depth()`'s 5 levels gate every escalation; `situations`/`child_patterns` both require repeated, independent confirmation before "confirmed" status. |
| §18 — the 18 named tables | Preserve, don't redesign | **Confirmed, all 18 exist**, re-checked this audit: `followers, children, daily_logs, memory_events, child_patterns, memory_snapshots, stages, stage_proposals, situations, aha_moments, parent_strain, mirrors, crisis_flags, checkin_state, conversation_moments, reply_gate_log, erasure_requests, child_record_requests`. |
| §3 — لحظة الاتفاق → payment → journey | One coherent bridge | **Live** — `activate_subscription()` unconditionally calls `start_stage()`, reading `followers.agreed_objective` when the parent has already agreed one. Read directly this audit. |

---

## B. What is missing

| Gap | Contract section it violates | Detail |
|---|---|---|
| **Buffer contamination not fixed** | §9 — "يجب أن يحتوي على كلام الوالد الحقيقي، وليس summaries مولدة من النظام" | The live `Postgres Memory Paid` node still stores the full constructed prompt (system scaffolding + parent's message) as the "human" turn, not the parent's raw words. Root-caused, fixed design proven with an executed test against the real library (13/13), **not deployed**. This is a direct, named contradiction of §9 as it stands right now, for the one real conversation currently active in production. |
| **W3's `journey_step` send path is unwired** | §3, §13, §25 items 7-8 | The SQL side (`compose_journey_step`, `get_rhythm_due` routing) is live and tested. The four n8n nodes needed to actually compose and send a daily paid step do not exist in the workflow graph (`docs/workflows/w3-journey-step-branch.md`: "SPECIFIED, not wired," re-confirmed this audit — no node changes since). W3 itself remains `active: false` (re-confirmed live this audit). **A paying parent today would get a stage in the database and grounded reactive replies, but no proactive daily message different from a free parent's.** |
| **CONTINUATION (§5) is essentially undesigned in build terms** | §5 | `close_stage()` returning `'completed'` is the only piece that exists. The report, the "what changed since the start" comparison, and the optional paid-continuation offer described in §5 have no function, no moment, and no test. The contract itself marks this section as partial/open, so this is not a surprise — flagged here as the concrete gap it is, not as an oversight. |
| **Live system prompt lags the repo** | §16, §17 (voice/behavior consistency) | The repo's prompt carries 2026-08-11/12 clauses (honest-silence-is-success, no-diagnosis, single-topic-per-reply, binding `[الرحلة]` directives) that the live n8n node does not. Last confirmed byte-identical: 2026-08-06. |
| **`KEY_MOMENTS` context block is known-duplicative and still live** | §6, §7 — "لا ترسل البيانات لمجرد أنها موجودة" | Already identified and reasoned through this session (`adam-snapshot-value-test.md`-adjacent review); never acted on because it was out of the approved v1 scope. Small, but a literal instance of the rule the contract just restated. |
| **12 unauthenticated n8n nodes (from `telegram-logic.md`)** | §20 — the Telegram experience the parent actually sees | Flagged in an earlier doc as breaking `/start`, all ☰ commands, waitlist, the pin, and the harvest reply. No later document or this session's own work confirms this was fixed. **Not independently re-verified in this audit** — flagged as inherited, unconfirmed risk, not as newly discovered. |

---

## C. What is contradictory

- **`KEY_MOMENTS` staying live vs. §6/§7/§8's own logic.** Internally inconsistent with the contract's own stated principle, not with another document — a small, named contradiction between what's deployed and what §6-8 ask for.
- **The old "Day 30" ambiguity is now resolved, not contradictory — but the repo still contains prior design docs that describe the superseded models** (a fixed calendar 30-day journey with a repurchase report, and before that a monthly-subscription-with-dunning model). Per this contract's own instruction, those are no longer authoritative; flagged only so a future reader doesn't quote them as current.
- **§10's "الذاكرة المدفوعة يجب أن توفر الاستمرارية التي لا يستطيع buffer الحالي توفيرها" vs. what actually shipped.** The Paid Baseline (§11) is a *single historical sentence*, not general continuity. This was a deliberate scope cut, made and justified in this session's own A/B/C value test (two of three originally-designed clauses measured zero effect and were cut). It satisfies §11-12 exactly. Whether it fully satisfies the broader continuity language in §10 is worth the founder's own read — flagged as a **possible narrower-than-intended reading**, not asserted as a violation.

---

## D. What exists, works, and should not be touched

- The 18 tables in §18, and every function this session did not modify:
  `knowledge_depth`, `suggest_objective`, `start_stage`, `close_stage`,
  `record_seed_sent`/`record_harvest_sent`/`record_harvest_answer`,
  `copy_violations`/the vocabulary half of `gate_agent_reply` (price, sales-close,
  impersonation, brand-guarantee/superiority, internal-Latin-term checks —
  untouched, still live, still correct).
- `الاتفاق` → `activate_subscription` → `start_stage` bridge — live, correct,
  unified (§3, §14).
- W1 (`ADAM - Machine 1+2 - Reception, Gates &amp; AI Agents`) — the only
  active n8n workflow, carrying real live traffic (122 messages / 7 days,
  re-confirmed this audit's window is close to that measured earlier today).
- The free experience end to end — stable, unchanged, matches §2 as written.
- Everything this session deployed earlier today (JOURNEY context, `allowed_moves`,
  the grounding gate, the Paid Baseline v1) — live, smoke-tested against real
  production twice today, matches the contract precisely per section A above.

---

## E. The single biggest gap standing between today and a launch-ready product

**The paid product exists as a correct, tested database promise with almost no
delivered daily experience.** Everything reactive (what ADAM says when a paid
parent writes in) is now grounded, phase-aware, and baseline-aware — deployed
and verified today. But nothing proactive exists yet: no daily step is ever
sent, because W3 is off and its `journey_step` branch was never built past a
specification. A parent who pays today gets a `stages` row, a correctly
phase-gated reactive voice, and silence otherwise — not the "رحلة ADAM يتابعها
يوميًا" the contract's own §25 describes as the finished product. Layered on
top of that: the one real, currently-active conversation in production is
still running through the contaminated buffer, so even the reactive layer is
not yet clean for the traffic that exists right now.

**In one line:** the promise is fully specified and the reactive half is
built; the proactive half — the thing that makes a paid journey actually feel
like a journey — is not.

---

## F. The single next step proposed

**Fix the buffer contamination (§9).** Reasons, weighed against the
alternatives:

- It is the only remaining gap that is **fully designed, fully proven** (13/13
  executed checks against the real library, this session), and requires
  **no new engine, no W2/W3/W4 activation** — those stay exactly where the
  founder has them.
- It directly serves a contract clause (§9) word-for-word, not an inference.
- It improves the **one real, currently-active** production conversation
  immediately — not a hypothetical future paid user.
- It is two parameter edits to one already-live n8n node — the smallest
  possible unit of the STEP 1→6 cycle §22 asks for, and a clean way to
  exercise that cycle (audit → design already done → build → test → review →
  deploy, with the build/publish distinction in §22 honored explicitly) before
  attempting the larger W3 wiring work.

**Explicitly not proposed as the next step, and why:** wiring W3's
`journey_step` send path is the more product-critical gap (Part E), but it
means turning on a paused, cost-relevant engine — a decision this session has
treated as founder-reserved throughout, and §24 asks that anything touching
"طبيعة الرحلة" or engine activation stop for a decision rather than proceed
silently. Recommend that as the step **after** this one, with its own STEP
1-6 pass and an explicit go-ahead first.

---

*Read-only audit. Nothing built, modified, or deployed. Stopping here per
instruction — awaiting review before STEP 1 begins.*
