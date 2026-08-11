# HANDOFF — read this first in a new session

One file, so a new session does not replay the old one. Everything below is verified, not remembered.

## Latest — 2026-08-06 (start here)

Where we stopped, newest first. Read this block, then the rest as needed.

- **2026-08-11 — the rhythm routes the journey step** (`get_rhythm_due`,
  `20260811150000`). Built on the live revive_the_rhythm_gate version (14-col
  return, is_first_proactive/footer_ar preserved): when the morning give would be
  a `seed` and the parent has a live stage, it becomes `journey_step`, grounded by
  `compose_journey_step` and gated by its `can_send` (no outcome → silent, not a
  fallback seed). A journey_step is never a first proactive, so those columns come
  back false/null for it. Free parents unaffected. 5 assertions in
  `rhythm_journey_route_test.sql`, zero regression (rhythm_gate still 14).
  **Remaining: W3's journey_step branch** (compose + send + stamp seed_sent_at so
  the evening harvest still fires) — W3 stays paused until launch.
- **2026-08-11 — the daily plan composer is BUILT** (`compose_journey_step`,
  `20260811140000`, 16 assertions). The paid journey's «مخصّص» daily step: a
  facts+posture function (the sibling of `get_harvest_context`) that hands the
  composer tonight's single step from the agreed objective, the phase
  (observe→build→hold from `v_stage_progress`), the child's situation, and last
  night's outcome. observe = change nothing / build = one step on what worked /
  hold = ADAM fades. No fixed plans, no plan-authoring screen; the LLM writes the
  language at send time under the copy law. **Not yet deployed to production**
  (pure new read, zero risk). **Next:** route a live-journey parent to a
  `journey_step` action in `get_rhythm_due` (step 4), then W3's branch — W3 stays
  paused until launch.
- **2026-08-11 — لحظة الاتفاق (the conversion moment) is BUILT.** The free→paid
  hinge. Design: `docs/the-agreement-moment.md` + `docs/the-conversion-seam.md`.
  Build: `supabase/migrations/20260811120000_the_agreement_moment.sql`,
  `supabase/tests/agreement_moment_test.sql` (31 assertions). **Zero n8n change,
  no engine turned on, no data collected** — the whole moment is in the database,
  reached through the existing tap pipeline. When a ready parent taps «نشتغل عليه»
  (or /journey), the door now opens onto the AGREEMENT — mirror + one falsifiable
  goal + «نعم / المشكلة الأكبر شيء آخر» — before any price; «نعم» writes a
  reversible receipt (`followers.agreed_objective`) and then shows the offer.
  Strain, an existing journey, or missing evidence all fall straight through to
  today's offer surface, unchanged. New fns: `should_agree_first`,
  `compose_agreement_moment`, `agree_objective`; `get_moment_after_tap` copied
  verbatim + two branches. `get_conversation_moment` was NOT touched.
  The cashier's read side is built too (`20260811130000`): `activate_subscription`
  called with no goal reads `agreed_objective`, starts the journey from it, and
  consumes the receipt — an explicit goal still wins, and no-goal+no-receipt still
  returns `objective_required`. 38 assertions in `agreement_moment_test.sql`, zero
  regression across all suites.
- **Working branch is now `claude/connect-language-gate-n8n-5cmia3`.** It was
  fast-forwarded to contain everything on `claude/install-product-skills-ayvz5e`
  plus the language-gate wiring. Commit and push there. (The older
  `install-product-skills` branch is its ancestor — same history up to the gate work.)
- **The language gate is wired and published.** `paid aget adam → Gate - Agent
  Reply → FA - Send Reply1`. `Gate - Agent Reply` POSTs to `gate_agent_reply`;
  `FA - Send Reply1` withholds and substitutes the `reply_withheld` copy when
  `blocked === true`, else sends unchanged. Fails open (onError:
  continueRegularOutput). Live in `ADAM - Machine 1+2`, active version `6b851201`.
  Mirrors + full note: `docs/workflows/agent-reply-gate-wire.md`,
  `W1-Gate-Agent-Reply.body.js`, `W1-FA-Send-Reply1.body.js`.
- **The «بلد آخر» typed-country branch is live and confirmed.** Executions
  6173–6178 all succeeded after publish; the old switch error (6172) was
  pre-fix. An `Is Country Answer?` IF node routes `track === 'country_answer'`
  to `Tap - Get Parent` before `M2 - Track Switch` (Switch V1 caps at 4 outputs,
  which was the bug). Built on `capture_country_text` +
  `20260807270000_the_other_country_branch.sql`.
- **W1 is now 63 nodes** (not the 126 the table below still says — a big cleanup
  happened; trust n8n, not the count here).
- **One manual step still open for the founder:** attach the `adam Supabase`
  credential (`EI2e62pg3bxhCSMJ`) to `Gate - Agent Reply` in the n8n UI. Until
  then the gate is present but fails open — no enforcement, no regression. The
  MCP tool cannot bind `supabaseApi` to an httpRequest node (confirmed again).
- **Still deliberately paused:** W2/W3/W4. Do not re-activate without asking.
  No data collection until launch — founder's standing rule.
- **Full remaining pre-launch checklist:** `docs/what-is-missing.md`. The
  running build record: `docs/IMPLEMENTATION_LOG.md`.
- **Offline tests need no DB.** See the "Tests" section below; the test suite
  now includes `country_branch_test.sql`, `after_arrival_test.sql`,
  `adam_reading_test.sql`, `waitlist_test.sql`, `agent_gate_test.sql`.

## What ADAM is

Read in this order, and only as far as you need:

| File | What it settles |
|---|---|
| `docs/adam-architecture.md` | **Single source of truth.** Part 0 is the Business Constitution — founder-only |
| `docs/adam-experience-principles.md` | E1–E13 + a review of the live surface. **Proposal, not applied** |
| `docs/telegram-ux.md` · `conversation-engine.md` · `knowledge-engine.md` | The three layers, all applied to production |
| `docs/w1-review-and-redesign.md` | W1 review + execution log |
| `docs/batch5-child-name.md` | The name-capture bug and its fix |

## Live system

| | |
|---|---|
| Supabase | `aajqbmjasnbwwyvgrlzy` (Adam OS), Postgres 17.6 |
| n8n | `adam-voices-n8n.hawiyat.cloud` |
| **W1** Router + Agents | `42loY0bgUSwYmHFV` — 126 nodes, active |
| **W2** Knowledge Writer | `7mTP12nVLS1Taokl` — 30 nodes, every 2h. **Paused** (`active:false`, `activeVersionId:null`) — founder-deliberate, to control cost pre-launch (2026-08-04). Do not re-activate without asking. |
| **W3** Rhythm Sender | `Vb4ADCkPsevPRWRN` — 11 nodes, hourly. **Paused**, same reason as W2. No seed/harvest is currently being sent to anyone — the intention ask and offer fork (§10.4/5) are wired and correct but have nothing to trigger them until this is turned back on. |
| **W4** First Mirror | `pj19WNHEqU4xDDjy` — **archived**. `generate_first_mirror`'s payload is ready (including `has_intention`, 2026-08-04) but there is no live workflow to render/send it. |
| **Bot Commands** | `Wlc3VSq3YYmZZdZj` — 3 nodes, manual trigger, never scheduled. Writes the Telegram command list (`setMyCommands`) with its emoji. Run it by hand after changing the menu wording; the list lives in this workflow, not in the database. |

## State as of 2026-07-31

Numbers verified against production, not recalled:

```
parents 299 · children 71 · parents with a named child 69
knowledge_depth >= 1: 70 · get_situation_batch returns 70
```

W1 batches 1–3 applied: free conversation uncapped, ADAM no longer sells (فريق آدم referral behind the strain gate), the six-step funnel replaced by §9.1 first contact, menu + taps wired.

## Tests — run these before trusting anything

They need **no** database connection. That is the point.

```bash
PGBIN=$(ls -d /usr/lib/postgresql/*/bin | head -1)
DATA=$(mktemp -d); RUN=$(mktemp -d); chown postgres "$DATA" "$RUN"
su postgres -c "$PGBIN/initdb -D $DATA -U postgres --auth=trust"
su postgres -c "$PGBIN/pg_ctl -D $DATA -o '-k $RUN -p 55432 -c listen_addresses=' -l $DATA/log start"
export PGHOST=$RUN PGPORT=55432 PGUSER=postgres
psql -q -f supabase/tests/fixture_minimal.sql
for m in 20260731090000_telegram_surface_state 20260731120000_conversation_copy_and_button_law \
         20260731150000_knowledge_gate_and_uniqueness 20260731170000_child_name_capture; do
  psql -q -f supabase/migrations/$m.sql; done
for t in telegram_surface conversation_law knowledge_gate child_name; do
  psql -q -f supabase/tests/${t}_test.sql | tail -3; done
```

Expected: **21 + 37 + 25 + 29, zero failures.**

## Known traps

- **The n8n MCP refuses to bind `supabaseApi` to `httpRequest`.** n8n supports it; the tool does not. Put `authentication: predefinedCredentialType` in the node's `parameters` and attach the credential in the UI. Never write the key inline.
- **`update_workflow` takes atomic operations**, not SDK code — `addNode` / `addConnection` / `setNodeDisabled`. A whole batch fails or none of it lands. `setNodeParameter` cannot append to an array; replace the whole parameter.
- **A fixture that invents a column tests the fixture.** `is_supported` did not exist, the fixture created it, 21 assertions passed and every production `/start` returned 400. Copy columns from production, never from a migration comment.
- **Reading `$json` across an HTTP node loses it.** That silently discarded 68 extracted child names for months. Reference the upstream node explicitly.
- **`setNodeParameter`'s `path` is relative to the node's `parameters` object.** `/parameters/jsonBody` returns `appliedOperations: 1` with no error and changes nothing. `/jsonBody` is what lands. Re-fetch the node after every `setNodeParameter` call — the success response does not mean the write happened.
- **A bare `\n` in a `setNodeParameter` value becomes a REAL linefeed in the stored expression.** JSON decodes `\n` to LF, and an LF inside a single-quoted JS string literal in an n8n expression is `ExpressionExtensionError: invalid syntax` — the node fails before running. Use `String.fromCharCode(10)` for newlines inside expression string literals, never a literal `\n`. Verify with `cat -A` (a bare `$` mid-string = a real LF is present).
- **`onError: continueErrorOutput` whose error output feeds a "create" node re-fires on benign errors.** `Pin - Edit`'s error output went to `Pin - Create`; Telegram's `400 "message is not modified"` (identical text — the common case) counts as an error, so it re-pinned on every steady-state reply. An error fallback that has a visible side effect must distinguish real failure from a no-op, or not exist.
- **Founder-owned, still open:** rotate the exposed service-role key (plaintext ~116× in W1); attach `adam Supabase` to `HW - Write Child Name` and to the new `Gate - Agent Reply` node (added 2026-08-03, wires `gate_agent_reply` between `paid aget adam` and `FA - Send Reply1` — the credential field on `addNode` was tried and rejected by the MCP tool with "node type 'n8n-nodes-base.httpRequest' does not accept credential 'supabaseApi'", same trap as before); supply the vetted L3 referral directory (§16 D2).

## Next, in order

From `docs/adam-experience-principles.md` Part 4:

1. ✅ done — typing indicator
2. ✅ done — `/start` is one message
3. ✅ done — pin created on the first logged evening, edited in place thereafter
4. Derive the reply keyboard from state like every other surface
5. Menu body carries the surface content
6. Harvest reply composed + uniqueness-tested — the Peak-End moment is currently one fixed string

**1–3 are live. 6 changes what she remembers and is the next one worth doing.**

**Credential still to attach in the n8n UI:** `Pin - Load`, `Pin - Surface`, `Pin - Remember` (plus the earlier fifteen).

Open founder decision: «شيء آخر» on every button set — see Part 3 F9.

## §10 rhythm items (`docs/adam-system.md`) — progress

1. ✅ إحياء البوّابة — live
2. ✅ رسالة المساء تُعطي قبل أن تسأل — `get_harvest_prompt`, live
3. ✅ قلب المقياس إلى الوالد — `parent_effort`, live
4. ✅ عنصر النيّة — `should_ask_intention`/`record_intention_ask` ride the harvest, live (2026-08-04); the parent's typed answer is captured and answered (`capture_intention`, live 2026-08-05). Consumer built: `generate_first_mirror` emits `has_intention` (flag only, never the text — 2026-08-04), but W4 is archived so nothing renders it yet.
5. ✅ لحظة العرض — `offer_ready`/`take_offer_moment` ride the harvest as the fork, live (2026-08-04). Buttons reuse live callbacks (`cta_full_companion` → menu_journey → فريق آدم; `not_now`). Fires once per parent when earned (3 attempts, 2 outcomes, confirmed situation, no strain). 0 parents earned it yet.
6. 🔴 ما بعد الوصول — **not designed**, not just unwired (`docs/adam-system.md` §7/§10). Needs a design pass before any DB/n8n work.

**The intention answer is now captured** (2026-08-05, `capture_intention`). A parent whose ask is stamped and unanswered gets their next typed message read as the answer — if it looks like one. `get_agent_bundle(p_follower_id, p_message)` performs the capture on the call `M2 - Get Memory Snapshot` was already making, and two credential-free nodes (`IN - Kept?`, `IN - Send Kept`) branch to the fixed `intention_kept` reply. Anything that does not look like an answer — a command, a question back, an essay, a message more than 36h late — captures nothing and falls through to the ordinary reply, because the intention is written once and never overwritten.

**Still not wired: the offer fork's «نتركه يتكرّر».** A parent who taps it and then types gets an ordinary reply; nothing records that they chose to let it repeat. Lower value than the intention (the fork is stamped once regardless, and the «نشتغل عليه» side is fully live), and it needs a moment written for it before any wiring.

**Nothing in §10.4/5 is currently reaching anyone.** W3 (which sends the seed/harvest messages this all rides on) is paused — see Live system table. This is deliberate, not a bug: no real users yet, product still has known copywriting/UX gaps the founder is finding by testing manually. Founder's plan: finish the remaining threads, then a comprehensive review pass, testing live and reporting errors one at a time.

## Branch

`claude/connect-language-gate-n8n-5cmia3` (current — see the Latest block at the top).
Commit and push there; never to the default branch. Its ancestor branch
`claude/install-product-skills-ayvz5e` carries the same history up to the gate work.
