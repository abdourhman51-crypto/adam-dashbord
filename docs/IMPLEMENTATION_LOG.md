# ADAM — Implementation Log

Running record of what was built, what it replaced, and what was found wrong along the way.
Newest first. Every entry names the evidence, not the intention.

---

## 2026-08-03 · Wired `gate_agent_reply` into W1

`gate_agent_reply` (commit `35099f1`, `20260801250000_the_agent_speaks_under_law.sql`) was built and
tested but never connected — every reply `paid aget adam` produced still went straight to Telegram
unchecked. Confirmed live against workflow `42loY0bgUSwYmHFV`: no node called it, and `paid aget adam`
connected directly to `FA - Send Reply1`.

**Wired via `update_workflow`'s atomic operations** (not the SDK — this is an existing production
workflow, not a fresh build): added `Gate - Agent Reply` (`httpRequest`, typeVersion 4.4, POST
`/rest/v1/rpc/gate_agent_reply`, `authentication: predefinedCredentialType` / `nodeCredentialType:
supabaseApi`, `onError: continueRegularOutput`) between `paid aget adam` and `FA - Send Reply1`, and
rewrote `FA - Send Reply1`'s body to use the gate's `blocked` result — the fixed `reply_withheld` text
when blocked, the raw reply otherwise, with the existing country-ask-footer logic untouched. On a gate
error the raw reply still sends (fail open, not fail silent-and-broken): `gate.blocked` reads as
`undefined`, not `=== true`.

**The credential-attach trap held exactly as documented.** Setting `node.credentials.supabaseApi` on
`addNode` was rejected outright: `"node type 'n8n-nodes-base.httpRequest' does not accept credential
'supabaseApi'"`. Same limitation `HANDOFF.md` already named for `FA - Country Ask?`. Left as
`authentication: predefinedCredentialType` in `parameters` only — the credential itself needs a manual
UI attach, same as `Pin - Load` / `Pin - Surface` / `Pin - Remember` before it.

**`setNodeParameter`'s `path` is relative to the node's `parameters` object, not the node.** The first
attempt used `path: "/parameters/jsonBody"` — it returned `appliedOperations: 1` with no error, but the
node was unchanged on re-fetch. `path: "/jsonBody"` is what actually lands. Caught by re-fetching the
node after the write rather than trusting the success response, which is now the standing rule for any
`setNodeParameter` call.

Verified the two new expressions offline (normal reply passes through; blocked reply falls back to the
fixed text plus the country-ask footer when owed; a gate error or malformed response both fail open) —
`node`-run, not live, since `test_workflow` pins every `httpRequest` node and so cannot exercise the
real credential resolution. That resolution — the one open question — needs a live message after the
credential is attached.

---

## 2026-07-29 · Pre-launch cleanup
**Full report:** `docs/CLEANUP-2026-07-29.md` · **Status:** n8n 13 → 5 workflows, `public` 32 → 23 tables.

**A live workflow was sending dunning messages.** `Machine 5 (Renewal Guard)` was
**active** on a daily 10:00 schedule. Execution `5057` at 08:00 UTC today delivered a
real Telegram message (`message_id: 10827`) asking a parent for **2,300 DZD to a CCP
account** — a parent who last spoke on 29 June. Her `country` was empty, so the code
fell through to the Algerian default and quoted her an Algerian bank account
regardless of where she lives. The message also asserted *"there was a real turning
point in your journey together"* while `plan_sessions` held nothing for her: the text
is assembled from empty fields. Two more parents were queued for auto-downgrade on
31 July. Deactivated, then archived.

**The dashboard has never been buildable from this repo.** `app/` imports 14 modules
from `@/lib/*` and `@/components/*`; none exist, and `git log --diff-filter=A` shows
none were ever committed. This is missing source, not technical debt — reconstructing
it would mean inventing product. It also bounded the cleanup: with `lib/queries.ts`
unavailable, every view and every function reachable from committed code was kept.

**Deleted** — only what was proven dead against the live workflows, every function
body, and every committed file: the offer/renewal query layer
(`get_offer_candidates`, `get_live_offer_signal`, `get_followup_candidates`,
`get_renewal_actions`, `increment_waitlist_daily`), the broken counter pair, and two
zero-row tables. Full recovery DDL is embedded in the migration.

**Moved, not dropped.** Nine `*_archive_20260708` tables hold 3,694 rows of real
history. They left `public` for a new `archive` schema — PostgREST only serves
`public`, and a snapshot beside live tables is one forgotten GRANT away from
re-opening the Week-0 exposure.

**Refused to delete** three things that looked legacy and were not: `Heart Writer`
(its `write_child_name` is the only writer of `children`, and `light_memory` covers
129 parents), the legacy `Nightly Checkin` (11 opted in, 16 `daily_logs` rows this
week — stopping it before v2 activates costs real parents nothing gained), and
`writer_commit` and friends (an unattributed write on 2026-07-28 10:01 that no n8n
execution explains).

**Correction to the blueprint.** It listed `weekly_plans` and `survey_responses` as
dead. Both have live references — `write_child_name()` writes one, the live router
writes the other. The blueprint predated the dependency audit.

---

## 2026-07-29 · Integration pass — shipping over infrastructure
**Status:** Two workflows built, tested, **inactive**. Deployment steps in `docs/DEPLOYMENT.md`.

Applied the ship-first filter to my own plan and deferred three things I was about
to build. None of Flashpoint Detection, prep messages, or the Sleep Journey config
increases learning from real parents or unblocks shipping — there are zero paid
parents, and `hard_moment` is already captured by six buttons.

The honest finding: **I had been building infrastructure ahead of integration.**
Everything built so far was dark. Nothing had reached a parent.

**Constraint that shaped the design.** A Telegram bot holds one webhook, and the
live 89-node workflow owns it, so response handling must stay there. Checking what
that router already does: it *already* writes `daily_logs` on check-in responses.
So the blocker was never the router — it was that the **sender** carries the Egypt
timezone bug and the **Mirror has never run**. Both are schedule-triggered, so both
ship without touching the live conversational workflow at all.

**Built**
- `ADAM · Check-in Sender v2` (`xcebVnU05w5Sx4JO`) — hourly, all scheduling logic
  in `get_checkin_batch()`, Telegram credential instead of a hardcoded token
- `ADAM · First Mirror Sender` (`pj19WNHEqU4xDDjy`) — daily, renders the Mirror in
  Arabic-Indic numerals, her own change as one quiet closing line

**Deliberately not done:** swapping the HTTP nodes to a credential whose contents I
cannot verify. The MCP tool refuses to attach `supabaseApi` to an HTTP node even
though n8n supports it and the existing production workflows use exactly that
pattern. Forcing a different credential risked 401s against live data to save five
UI clicks.

**Requires founder action before parents see anything:** credential attach, Telegram
bot verification, deactivating the legacy check-in sender, activation.

---

## 2026-07-29 · Nightly Check-in Engine
**Commits:** `<this>` · **Status:** DB layer complete and tested. Workflow wiring pending.

The nightly log is the measurement spine (review A3) — the stage clock, the Mirror and the
child record are all derived from it.

**Production bug found and fixed.** The live workflow hardcodes `{ DZ: 1, EG: 2, MA: 1 }` as
fixed UTC offsets. Verified against `tzdata`: Egypt's real offset is **+3** (DST reintroduced
2023). Egyptian parents — the largest market and the source of the only real payment — have
been receiving the nightly check-in at **20:00 local, not 21:00**, every night. Replaced with
IANA zones so Postgres handles DST and Ramadan shifts.

**Built**
- `country_timezone` — 30 countries, not just the 3 payment markets (free support is universal, P8)
- `checkin_state` — cadence, consent decay, local hour. A separate table, because `followers`
  already carries 60+ columns
- `get_checkin_batch()` — selects only in the parent's local evening hour; excludes the 7-day
  crisis window, anyone already sent today, and anyone with no resolvable timezone
- `record_checkin_response()` — writes against her **local** date and resolves `child_id`
- `decay_checkin_consent()` — 5 ignored → weekly, 4 more → stopped. Any reply restores everything
- `ensure_checkin_state()` — enrolment on engagement
- `v_checkin_unschedulable` — 56 parents whose local evening is unknown

**Decisions**
- *Local date, never UTC.* At 21:00 in Algiers the UTC date has already rolled over; filing a
  Tuesday evening under Wednesday would silently corrupt the stage clock.
- *No bulk enrolment.* 234 parents are schedulable, 12 are enrolled. Backfilling all 234 was
  tempting and wrong: most last spoke weeks ago, and a nightly message to a dormant stranger is
  how ADAM becomes the thing she mutes. The rhythm is earned by an exchange.
- *Unknown timezone means no message.* Not a guess at UTC+3. Surfaced in a view instead.

**Tests** C1–C12: timezone correctness, batch selection, send idempotency, response logging,
`child_id` linkage, follow-up merge (no duplicate row), crisis suppression, decay to weekly,
decay to stopped, full recovery on reply, enrolment idempotency, unknown-country refusal.

**Resolves** the gap flagged in Child Record: `daily_logs.child_id` was NULL on all 21 rows,
so sibling-parents got an empty record. Now populated on every response.

---

## 2026-07-29 · `safe_for_record` operator-only invariant
**Commit:** `f1c694f`

Two of my own defects were caught by tests and corrected.

**H4 defeated the first design.** It used a transaction-scoped GUC as proof of approval; anyone
able to run SQL could `set_config` and flip the flag with **zero audit rows**. A guessable token
is a convention, not an invariant. Rebuilt so the guard requires a matching approval row written
in the same transaction — flag and justification cannot come apart.

**The column REVOKE was a silent no-op.** `has_column_privilege` returned `true` afterwards:
PostgreSQL will not let a column-level revoke subtract from a table-level grant. Revoked the
table grant, re-granted per column. The trigger covered the gap throughout, so nothing leaked —
but a defence that is claimed and does not hold invites reliance.

**A design error surfaced while fixing the first:** requiring approval for *any* change made
revocation as hard as granting. Hiding a possible disclosure must never require ceremony.
Revocation is now always permitted and always logged.

9 attack paths tested, all correct.

---

## 2026-07-29 · Child Record
**Commit:** `1d081af`

Derived at request time, never stored, so redaction always applies and no stale copy can leak.

**Governing rule, established from live data:** the record contains what ADAM **authored** and
what was **measured** — never what the parent **disclosed**. An allowlist by provenance, not a
content filter, because filtering Arabic free text cannot be done safely. The live rows that
settled it:

- `memory_events.title` = *"حادثة الاعتداء المؤلمة"* — a child assault disclosure
- `child_patterns.pattern_label` = *"التنقل بين ثلاث عائلات"* — reveals family separation

Neither is distinguishable from a safe label by pattern matching.

**Also added:** the right to erasure, absent from all four design documents. Two-step, removes
conversations via the **normalised** session key (drifted `=`/`_s1` keys would otherwise
survive), de-identifies payments rather than deleting them, and the audit row carries no FK so
it outlives the erasure.

**Defect caught by T5:** `RETURNS TABLE` column `delivered` collided with the table column of
the same name — runtime `42702`. Renamed `was_delivered`.

---

## 2026-07-29 · Journey Engine
**Commit:** `7d914c8`

`stages`, `stage_proposals`, `erasure_requests`, `crisis_flags`. All RLS-enabled and
service-role-only from birth — no repeat of the Week-0 exposure.

- The clock counts **logged days**, not calendar days, so crisis, travel, illness and Ramadan
  need no pause feature and the guarantee stays fair both ways.
- Progress is **derived**, never a stored counter — the exact failure mode that froze
  `message_count`.
- Phase is computed, so the `hold` phase that proves change was real cannot be shortened.
- `objective_met` requires a **full** measurement window: a 5-of-7 target cannot be declared met
  on 4 nights.
- `can_propose_stage()` enforces the cadence caps that stop free guidance becoming the pushing
  that produced 8 offers and 0 clicks.

9 tests, all passing.

---

## 2026-07-29 · Week-0 security and data validity
**Commits:** `d958317`, `6aab790`, `554e1f6`

**Critical exposure closed.** Executing *as the `anon` role* — whose key is public by design and
ships in client bundles — returned **4,174 parent conversations**, 290 follower records, named
children, payments and logs. 17 permissive `USING (true)` policies; three targeting the broader
`public` role. API logs showed a **mobile browser** already reading `n8n_chat_histories`
directly. `activate_subscription` was executable by `anon`: anyone could grant themselves paid
access. All revoked; `service_role` verified unaffected.

**Engagement truth layer.** `message_count` froze at 0 for signups after ~25 July while those
parents were demonstrably conversing. Two causes: a trigger pointed at `public.messages`
(0 rows) and a dropped RPC call. Replaced with a derived view. Reconciles exactly:
2080 attributed + 7 orphaned = 2087.

**Correction to my own research.** I reported "47 orphaned sessions, 25% of conversations
invisible." Wrong — a naive join. 40 were session-key format drift (`=` prefix, `_sN` suffix)
on 10–11 July. Real orphans: **7 sessions, 7 messages** — 0.3%, not 25%.

**Pricing.** The agent quoted a parent 150 EGP against a real price of 490, because its prompt
carries no price data and generated one. `get_pricing()` is now the only sanctioned source;
unknown markets return `is_supported=false` with null prices, leaving nothing to latch onto.

**Chat integrity.** One stored AI message was 169,230 chars against a p99.9 of 1,832. Ceiling
enforced at 12,000. Scaffolding contamination (25 rows) is **detected, not stripped** — regex
surgery on Arabic free text risks corrupting what a parent wrote.

---

## Outstanding

| Item | Owner | Note |
|---|---|---|
| **Restore `lib/` and `components/`** | **Founder** | Never committed. Dashboard cannot build without them |
| Rotate service-role key + Telegram bot tokens | **Founder** | Exposed in workflow JSON |
| Attach `adam Supabase` to 5 HTTP nodes | **Founder** | MCP refuses `supabaseApi` on httpRequest; n8n itself supports it |
| Verify Telegram credential, deactivate legacy sender, activate v2 | **Founder** | Two credentials, cannot tell which is the ADAM bot |
| Dashboard → service key | **Founder** | Anon reads now correctly fail |
| Crisis escalation destination (review D1) | **Founder** | Duty-of-care; gates scale past pilot |
| 56 parents with unknown timezone | Me | Needs a country prompt or inference |
| `country` empty on all 4 paid rows | Me | Caused Renewal Guard to quote Algerian pricing to everyone |
