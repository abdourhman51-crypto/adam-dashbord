# HANDOFF — read this first in a new session

One file, so a new session does not replay the old one. Everything below is verified, not remembered.

## Latest — 2026-08-13 (start here)

Where we stopped, newest first. Read this block, then the rest as needed.

- **2026-08-13 — LIVE BUG FIXED on W1 (real traffic, not a STEP): the country-answer lock's escape button didn't actually escape.** Founder reported it with a real screenshot (a real parent stuck answering "🌍 لم أعرف هذا البلد" forever, even after tapping "↩︎ دعونا من هذا"). Root-caused by reading the exact execution (`42loY0bgUSwYmHFV`, execution 6342) live, not guessed:
  - `M2 - Classify Track` (W1, unchanged) routes *any* non-empty typed text into `track='country_answer'` for 36h after `followers.country_asked_at` is set — by design, per its own comment, so the very next reply is heard as the country answer.
  - The bug: `get_moment_after_tap()` never cleared `country_asked_at` when a parent escaped via a **button tap** instead of typing a country. A tap works for exactly one turn (taps carry no `message_text`, so `M2 - Classify Track` doesn't force them into the country track) — but since the DB flag stayed set, the parent's very next *typed* message fell straight back into the lock. Confirmed a second instance of the same root cause: tapping a `set_country_XX` flag button (a **successful** country selection) had the identical gap — it called `record_country()` directly, which also never clears `country_asked_at`, unlike the text path's `capture_country_text()` which does.
  - **Fix, one function, `get_moment_after_tap`:** added a guard at the top — any tap whose key is not itself `menu_capture_country` (i.e., not a text-based country attempt) now clears `country_asked_at` if it's set. This can only ever fire for genuine button taps, never for typed text, because typed text is always forced into `menu_capture_country` upstream — so the designed "keep asking via text" behavior for actual bad-text attempts is untouched.
  - **Verified before deploy**, rolled back against real production, 8/8: bad text still correctly fails and still doesn't clear the lock (regression-safe); tapping the escape button now clears it; the flag-button success path now also clears it; `menu_waitlist_join`'s own separate re-arm of the flag still works unchanged.
  - **Deployed** via `apply_migration` (`fix_country_lock_not_cleared_on_tap_escape`). Re-verified live: the fix marker is present in the deployed function body; the real parent from the screenshot (`platform_user_id 7377091520`) already shows `country='DZ'`, `country_asked_at=null` — resolved.
  - **Regression, real production, rolled back:** grounding gate and a clean reply still correct.
  - **Not touched:** no n8n node changed — this was a pure SQL fix. W3 untouched, still `active: false`. Nothing about STEP 3 built or decided.

- **2026-08-13 — STEP 2.2: one synthetic paid follower's entire journey
  simulated end to end — day 0 through hold phase — against the real W3
  pipeline. 24/24 checks pass. W3 still `active: false`. No SQL, no node,
  no other workflow touched — this was verification only.**
  - **The single continuous story, all real (not offline-simulated):** one
    follower, one child, one stage, driven through `start_stage` → real
    `test_workflow` execution (day 0, zero outcomes) → confirmed `seed`
    fallback fires, not `journey_step`, not silence → real harvest
    execution that evening → `record_harvest_answer` (the real function a
    button-tap would call) logs the first outcome → next real execution:
    `get_rhythm_due` now correctly returns `journey_step`, `observe` phase.
    Advanced through nights via the real writers (`record_seed_sent`/
    `record_harvest_sent`/`record_harvest_answer`, date-shifted to
    simulate elapsed nights — the same technique used throughout this
    session) to the 3rd logged night: `capture_stage_baseline` fired for
    real, phase flipped to `build`. A real `test_workflow` execution at
    `build` produced an actual small step; continued advancing to 20
    logged nights (this journey's `hold` threshold), a real execution
    there produced a no-step, presence-only message — matching each
    phase's directive exactly, every time, with the real model.
  - **Baseline show/hide tested in both directions, live-data-wins
    confirmed both ways:** captured with `baseline_calm_count=1`. Right
    after capture (recent 3 = same 3 nights = 1 calm) — suppressed, not
    strictly better. Two calm nights later (recent 3 = 2 calm > 1) —
    shown. Two hard nights after that (recent 3 back down to 1 calm = 1) —
    **suppressed again**, even though the baseline sentence itself never
    changed. This is the concrete proof that current live data governs
    what's told, not a frozen claim from three weeks ago.
  - **No-repeat confirmed structurally, not assumed:** the same day that
    both `seed` and `harvest` fire, `get_rhythm_due` returns nothing more
    for that follower — checked directly, not inferred.
  - **Free path re-confirmed unaffected**, a third time this build cycle,
    with a fresh isolated follower — real `Compose Seed` call, real
    (harmless) Telegram failure, real `daily_logs` write.
  - **Regression:** grounding/price/clean-reply gates re-checked live,
    rolled back — unaffected, as expected (no SQL changed since STEP 2.1).
  - **Zero residual data** — the one paid follower and the one free
    follower, and everything under them, deleted after; `stages` back to 0.
  - **W3 untouched this round** — no `update_workflow` call was made at
    all in STEP 2.2, only `test_workflow` executions and direct SQL state
    advancement. `active: false`, `activeVersionId: null`, confirmed
    unchanged at the end.

- **2026-08-12 — STEP 2.1: the `Harvest Prompt` bug (flagged in the STEP 2
  entry below) is FIXED, and the credential gap on `Record Journey Step
  Sent` is CLOSED — W3's whole pipeline (seed, harvest, journey_step) now
  runs end to end for real. Still `active: false`.**
  - **The fix, minimal:** `Harvest Prompt` calls `get_harvest_prompt()`
    (returns `text`); PostgREST returns that as a raw string, and the
    node's default `responseFormat: autodetect` tried to JSON-parse it and
    threw. Set `options.response.response.responseFormat = 'text'` and
    `outputPropertyName = 'body'` — nothing else on the node changed. The
    `'body'` name isn't arbitrary: `Send Harvest`'s existing (untouched)
    expression already reads `raw.body` as a fallback path that had
    presumably never actually been exercised — this fix makes that existing
    code the live path instead of adding new logic.
  - **Verified live, real `test_workflow` execution, one isolated synthetic
    follower, cleaned up after:** `Harvest Prompt` now returns
    `{"body":"اليوم جرّبنا مع مالك: خطوة اختبار.\n\nكيف مرّت؟"}` — the real
    measured-first harvest content, unchanged — no parse error. `Send
    Harvest` correctly used it (only failed on the fake `chat_id`, expected).
    `Record Harvest Sent` succeeded for real. Whole execution: `status:
    success`.
  - **Regression, real executions, cleaned up after:** free `seed` action —
    full success end to end. Paid `journey_step` (observe phase) — **also
    fully succeeded this time**, including `Record Journey Step Sent`
    (the founder attached its credential between the STEP 2 report and this
    one) — real `daily_logs` row confirmed written with the exact composed
    text and correct `seed_grounded_on` basis array. This closes the one
    gap the STEP 2 report left open.
  - **Zero residual data** — both synthetic followers and all dependent
    rows deleted; `stages` back to 0.
  - **Not touched:** message content, harvest logic, any other node, any
    other workflow. `active: false`, `activeVersionId: null`, unchanged.

- **2026-08-12 — STEP 2 build: the four `journey_step` nodes exist in W3
  (`Vb4ADCkPsevPRWRN`), tested for real against isolated synthetic data.
  **W3 is still `active: false` — nothing runs, nothing is live.**
  - **Credential redaction resolved:** `get_workflow_details` never shows a
    node's bound `credentials` — that's why earlier checks kept reporting
    "no credential" on the 4 pre-existing HTTP nodes even after the founder
    manually attached `adam Supabase` in the n8n UI. A real `test_workflow`
    execution proved the founder right: the credential shows up in the
    *execution trace* (`"credentials":{"supabaseApi":{...}}`), and
    `Record Seed Sent` actually wrote a real row using it. **Lesson for next
    time: never trust `get_workflow_details` for credential-bound state —
    only a real execution proves it.**
  - **What got built, exactly:** `Seed Or Harvest`'s switch gained a third
    rule (`action equals journey_step`); `Seed Model` now fans its
    `ai_languageModel` output to a new `Compose Journey Step` agent node too
    (no new AI credential); `Compose Journey Step` → `Send Journey Step`
    (Telegram, same bot-token-in-URL pattern as `Send Seed`, `onError:
    continueRegularOutput`) → `Record Journey Step Sent` (reuses
    `record_seed_sent`, same as the original spec) → loops back to `One
    Parent At A Time`. `onError`/`retryOnFail`/`maxTries`/`waitBetweenTries`
    on the two new HTTP nodes now match their siblings exactly (first pass
    silently dropped these — `addNode`'s schema doesn't accept them,
    `setNodeSettings` does; caught by re-reading the node back, not assumed).
  - **One deliberate deviation from `docs/workflows/w3-journey-step-branch.md`
    (2026-08-11), and why:** that spec fed `Compose Journey Step` raw
    `JSON.stringify($json.grounding)`. `docs/adam-context-contract.md`
    (2026-08-12, newer) explicitly forbids internal engine/table vocabulary
    — including the literal word "journey" — ever reaching the model.
    Re-reading `compose_journey_step`'s own prompt, only `phase_directive`
    (already carries the child/situation/working-step baked in) and
    `recent_steps` are actually used. Built instead: a small labeled Arabic
    text block, no JSON, no field names. Verified twice — a standalone
    Node.js simulation against real `compose_journey_step()` output
    (observe/build/hold + a manually-added recent_steps case, 7/7 checks,
    zero forbidden-vocabulary leaks) and, more importantly, the **real n8n
    execution trace**, which shows the exact resolved Human-turn prompt sent
    to the real model — clean natural Arabic, nothing else.
  - **Real end-to-end test executions (`test_workflow`, W3 still inactive),
    against real, isolated, cleaned-up-after synthetic followers — not
    guessed:**
    - `build`-phase journey_step: routed correctly through the new switch
      rule, `Compose Journey Step`'s real resolved prompt was clean, the
      real LLM (Gemini 3.1 Flash Lite) returned a concrete small step tied
      to the child/situation, `Send Journey Step` failed harmlessly on the
      fake `chat_id` (`400 chat not found` — expected, proves `onError`
      works), execution reached `Record Journey Step Sent`.
    - `observe`-phase journey_step: same path; the real model correctly
      produced an observation-only message with **no step suggested** —
      matches `phase_directive` exactly.
    - Free `seed` action: **fully succeeded end to end for real** —
      real `Compose Seed` call, real (harmless) Telegram failure, real
      `Record Seed Sent` write (`daily_logs` row + `A1_first` aha moment) —
      proof the new switch rule and Seed Model fan-out did not disturb the
      existing free path at all.
    - `harvest` action: **found a real, pre-existing bug, untouched by
      tonight's build** — `Harvest Prompt` calls `get_harvest_prompt()`,
      which returns `text`; PostgREST returns that as a raw string, and the
      node's response parser expects JSON, so it throws
      `"Response body is not valid JSON"`. This is the *original,
      founder-approved* node from before this session touched W3 — it has
      never been execution-tested until tonight because W3 has never run.
      **This blocks the harvest message for every parent, free or paid, the
      moment W3 is ever activated — unrelated to journey_step, but a real
      launch blocker for W3 as a whole.** Not fixed — out of STEP 2 scope.
    - No-double-send: a parent whose `seed_sent_at` is already stamped for
      today correctly gets **zero rows** from `get_rhythm_due` — confirmed
      directly in SQL, unchanged behavior.
  - **Still blocking full end-to-end proof:** `Record Journey Step Sent` is
    a *brand-new* node tonight — it has no credential attached yet (separate
    from the 4 pre-existing nodes the founder already bound), so its final
    Supabase write could not be executed for real. Everything upstream of it
    (routing, composition, the real LLM call, the real Telegram attempt) was
    proven live; the write itself was verified only by direct expression
    simulation, matching the already-proven `record_seed_sent` semantics.
    **Founder action needed:** attach `adam Supabase` to `Record Journey
    Step Sent` in the n8n UI, same as the other four.
  - **Regression check, real production, rolled back:** grounding/price/
    clean-reply gates and a full journey (build phase, `== JOURNEY ==`
    block, baseline line, `get_agent_bundle`'s phase directive) all still
    correct — zero SQL was touched tonight (`get_rhythm_due`'s fallback fix
    was the *previous* deploy), this just re-confirms nothing drifted.
  - **Zero residual data:** every synthetic follower (`step2e2e-%` prefix)
    and its children/situations/stages/daily_logs deleted after testing;
    `stages` back to 0, matching pre-test production.
  - **W3's `active` flag never changed — still `false`, `activeVersionId:
    null`.** No production rollout happened or was attempted.

- **2026-08-12 — STEP 2, first sub-piece only: the First-Day Seed Fallback is DEPLOYED to `get_rhythm_due`. W3 itself is still untouched, still `active: false`, still zero new nodes.**
  Context: STEP 2 is "wire W3's daily proactive journey_step path" — approved in principle, but the founder required an audit-before-build pass first (`docs/step2-w3-journey-step-design.md` already covered design/dependencies/cost/failure-modes/Telegram-UX/test-plan). That audit surfaced two blockers the founder had to rule on before any build: (1) four existing W3 HTTP nodes have no credential bound at all — still unresolved, founder action required in the n8n UI, not done yet; (2) a real gap in `get_rhythm_due`'s existing routing — a brand-new journey's very first morning (before any night result is logged) got silently dropped entirely, no message at all, because the router unconditionally reclassified the morning slot as `journey_step` the instant a stage went live, then `can_send('journey_step',…)` rejected it for lacking a logged outcome, with no fallback. Founder chose, explicitly: fall back to the ordinary `seed` message on day 0 instead of silence.
  - **The fix:** one `CASE` condition changed inside `get_rhythm_due`'s `routed` CTE — reroute to `journey_step` only when `compose_journey_step(...).can_send` is actually true; otherwise the row stays `seed` and flows through the pre-existing seed path unchanged. No other line of the function touched.
  - **Verified before deploy:** in a rolled-back transaction against real production, 13/13 checks — including two **deterministic** proofs (a follower in a timezone whose local hour was actually inside the seed window at test time, not a timing-dependent "acceptable if empty" placeholder): a fresh journey with zero outcomes gets a real `seed` row, not silence; the same parent after one real logged outcome (through the real `record_seed_sent`/`record_harvest_sent`/`record_harvest_answer` writers) correctly returns to `journey_step`. Free parents and parents with a `completed` stage confirmed unaffected. One test-harness bug of my own was caught and fixed mid-pass (used yesterday's date for the logged outcome; `record_harvest_answer` only matches today's row, so the outcome silently didn't record) — not a bug in the fix itself.
  - **Deployed** via a single `apply_migration` (`first_day_seed_fallback`) — the live function's body was re-fetched and confirmed to contain the new guard and not the old unconditional line.
  - **Re-verified live, for real, against the deployed function** (not rolled back this time — real inserts, then explicit cleanup): same 4 scenarios, 8/8 pass. All synthetic rows (`platform_user_id like 'rhythm-live-%'`) deleted afterward; confirmed zero leftover rows and `stages` back to 0 (matching pre-test production, which still has zero real live stages).
  - **A real design conflict was found and resolved without stopping, because it was implementation-quality, not product-facing:** `docs/workflows/w3-journey-step-branch.md` (2026-08-11) specifies feeding `Compose Journey Step` raw `JSON.stringify($json.grounding)`; `docs/adam-context-contract.md` (2026-08-12, newer) explicitly forbids internal engine/table vocabulary — including the literal word "journey" — ever reaching the model as context. Re-reading `compose_journey_step`'s own prompt, only `phase_directive` (which already embeds child name, situation, and last-working-step) and `recent_steps` are actually referenced by the instructions — everything else in the JSON blob is either unused or a duplicate representation of what `phase_directive` already states. **Decision, not yet built:** when the four W3 nodes are actually built, `Compose Journey Step`'s input will be a small labeled text block (two fields), not raw JSON — flagged here so it isn't lost before that build happens.
  - **Not touched:** W3 remains exactly as before — `active: false`, `activeVersionId: null` (never activated, ever), same 11 nodes, same missing credential on 4 of them. No new node was added. W1/W2/W4/subscription logic/STEP 1's fix — all untouched.
  - **Still open, blocking the rest of STEP 2:** the credential gap (needs the founder, manually, in the n8n UI — exact steps identified, not yet done) and the actual build of the four new W3 nodes + isolated-copy testing per the STEP 2 design doc's §6 test plan. Neither has started.

- **2026-08-12 — STEP 1 (buffer-contamination fix) is DEPLOYED to n8n. Nothing else touched.**
  Founder approved exactly one thing: the previously-designed, previously-proven
  fix for `docs/workflows/fix-paid-memory-contamination.md`, with an explicit
  7-step sequence and an explicit "no STEP 2, no W2/W3/W4" boundary.
  - **What changed, on the single live LangChain agent node** (named
    `paid aget adam`, `id bca58129-…`, in `42loY0bgUSwYmHFV` — this one node
    is shared by free and paid traffic; only its `family_context` input
    differs by tier): `text` went from
    `family_context + '\n\n[رسالة الأهل الآن]\n' + message_text` to plain
    `message_text`; `options.systemMessage` went from a static string to
    `` `<same static prompt, byte-for-byte>` + (family_context ? '\n\n' + family_context : '') ``
    as a live expression. Net effect: what LangChain's `Postgres Memory Paid`
    node persists and replays as the "human" turn is now the parent's real
    words only — the system-authored scaffolding is still delivered fresh
    every call (via `systemMessage`), it just stops being memorized and
    replayed back mislabeled as something the parent said.
  - **Verified before deploy:** read the live node's exact current
    parameters first (no drift since the fix was designed); rebuilt the
    proven local-Postgres + pinned-LangChain (`@langchain/core@0.3.66`,
    `@langchain/community@0.3.49`, `langchain@0.3.37`) simulation harness;
    pulled 4 real `family_context` strings from production via a
    rolled-back transaction (`free`, `paid_observe`,
    `paid_build_baseline_shown`, `paid_build_baseline_suppressed`); ran
    current vs. proposed `text`/`systemMessage` through the real memory
    classes — **27/27 checks passed**: byte-exact `family_context`
    preserved in the model's prompt every time, stored "human" rows now
    exactly equal the raw parent message, a 3-turn replay carries zero
    scaffolding markers from history. Real token counts
    (`gpt-tokenizer`, cl100k_base): per-turn prompt delta is **−7 tokens**
    (only the now-unneeded `"[رسالة الأهل الآن]"` label) — no information
    loss; the real win is the memorized/replayed row, **91–98% smaller**
    per turn, compounding across the 10-message window. Grounding gate,
    price gate, and a clean reply were re-checked live (rolled back) and
    unaffected — this is an n8n-only change, no SQL touched.
  - **Deployed:** one `update_workflow` `updateNodeParameters` call (draft),
    then a separate, explicit `publish_workflow` call — the draft/publish
    distinction was honored deliberately, per the Contract's own instruction
    not to treat a save as a deploy. Re-fetched the published node
    afterward: `text` and `systemMessage` match byte-for-byte, `active:
    true`, `versionId == activeVersionId`.
  - **Post-deploy verification, honestly reported:** the SQL side (gate/
    grounding/price) was re-confirmed live, rolled back, 0 regressions. The
    n8n side could **not** be confirmed against a real live message during
    this session — zero followers currently have a non-expired subscription,
    and no new `n8n_chat_histories` row landed in the ~minutes after
    publish. The byte-exact deployed-parameter check is a direct fact, not
    an inference, but it is not the same as watching one real reply get
    stored clean. **Next real message through this node — free or paid — is
    the first live confirmation; worth a spot-check the next time someone is
    in here.**
  - **Not touched:** SQL, W2, W3, W4, any other node, any other feature.
    Exactly STEP 1, nothing else.

- **2026-08-12 — the ADAM Contract + Paid Snapshot v1 are DEPLOYED to production.**
  `set_checkin_hour`, `get_agent_context`, `get_agent_bundle`,
  `gate_grounded_reply` (new), `gate_agent_reply`, `stage_state`,
  `capture_stage_baseline` (new), `record_harvest_answer` — five migrations
  (`the_hour_picker_writes_a_real_cadence`,
  `adam_receives_the_journey`,
  `knowledge_level_becomes_an_enforced_moveset`,
  `the_grounding_gate`,
  `the_baseline_is_written_once`), applied in that order, live now. This is
  the same SQL that had been sitting staged since 2026-08-11, plus the new
  Paid Snapshot v1 baseline (`docs/adam-snapshot-value-test.md`) built and
  reviewed on 2026-08-12.
  - **Why this deployed today and not in isolation:** the new baseline
    migration extends `get_agent_context`'s `JOURNEY` block, which did not
    exist on production before today — deploying it alone would have
    silently activated the undeployed 2026-08-11 JOURNEY/knowledge-level/
    grounding-gate set as a side effect, half-paired with nothing. Caught
    before deploying (production's live function bodies were read directly
    and compared, not assumed), the founder chose to bundle and transition-
    test all five together rather than deploy either alone.
  - **Verification before deploy:** all five migrations' DDL, plus a smoke
    suite, were run against real production **inside a transaction that was
    rolled back** (`begin; ... rollback;`) — a full dry-run of the actual
    transition, not an offline copy. 13/13 smoke checks passed; zero
    residual rows confirmed after rollback.
  - **Then deployed for real** via five `apply_migration` calls, and
    **re-verified live** with a second synthetic-parent smoke test against
    the now-actually-updated functions (4/4 passed): price/vocabulary gate
    unchanged, the grounding gate blocks a real memory claim, a real paid
    journey (through `record_seed_sent`/`record_harvest_sent`/
    `record_harvest_answer`) shows `== JOURNEY ==` and the new
    `- baseline:` line in `get_agent_context`, and `get_agent_bundle` carries
    `in_journey`/`allowed_moves`/the phase directive. Zero residual test
    data confirmed again after.
  - **What's now live that wasn't yesterday:** `gate_grounded_reply`
    (memory-claim / past-reference / unfounded-repetition blocking, merged
    into `gate_agent_reply` — zero n8n change needed, W1 already calls
    `gate_agent_reply`); `get_agent_context`'s `JOURNEY` block for paid
    parents in a live stage; `get_agent_bundle`'s `allowed_moves`,
    `in_journey`, and phase directive (silent in `hold`); and the Paid
    Snapshot v1 — one deterministic, no-LLM baseline sentence written once
    per stage, shown only when the live data is strictly better than where
    the stage started.
  - **Not touched:** n8n — no workflow, no node, was created or modified.
    W2/W3/W4 remain exactly as before (W2/W3 `active: false`). The prompt
    file changes and the memory-contamination fix from earlier on
    2026-08-12 are still **not** pushed to the live n8n node — only SQL
    moved today. *(Superseded by the STEP 1 entry above — the memory fix
    was pushed to n8n later the same day.)*
  - **Still zero paid users, zero live stages** in production as of this
    write — the deployed code is exercised the first time a real journey
    starts, not before.

- **2026-08-12 — ADAM built to `docs/adam-constitution.md`, staged, not deployed (superseded above — now live).**
  Three files changed, nothing pushed to production or n8n:
  - `docs/prompts/adam-conversation-agent.md` — five small additive edits inside
    existing sections: the exact governing sentence ("عندما تقلّ الأدلة، تقلّ
    درجة التحديد؛ لا يزيد الاختراع"), `[الرحلة]` directives stated as binding
    (hold-phase refusal holds even under direct pressure; a paid parent's own
    progress question is answered from `[الرحلة]`, never deflected, never a
    day-count), a no-diagnosis line, a no-pretend-action line, a
    single-topic-per-reply line. Still not pushed to the live `paid aget adam`
    node — the file's own header tracks the byte-diff status.
  - `supabase/tests/grounded_reply_test.sql` — extended from 31 to 42
    assertions: knowledge levels 1/2/4 (previously only 0 and 3 were covered),
    and the `build` phase directive (previously only `observe`/`hold`), closing
    the exact gap the Constitution's Knowledge Levels table and Journey
    Awareness section both specify.
  - `docs/workflows/fix-paid-memory-contamination.md` — new. Confirmed by
    reading the live `paid aget adam` node directly (not inferred): its `text`
    parameter concatenates `family_context` into what
    `Postgres Memory Paid` persists as the "human" turn, so the last 10
    messages replay the system's own scaffolding back to the model labelled as
    the parent's voice (Conflict 2, `adam-constitution.md`). The fix is two
    parameter edits to one existing node — `text` becomes `message_text` alone,
    `family_context` moves to a dynamic `systemMessage` expression instead (not
    memorized, still fresh every turn) — fully specified, **not applied**;
    `update_workflow` was never called.
  - Full suite re-run after all changes: **783/783 passed, 0 regressions**
    (30 test files, throwaway local Postgres, all 88 migrations applied in
    order including the three staged 2026-08-11 ADAM-contract migrations,
    unchanged and still undeployed).
  - `gate_grounded_reply` was deliberately **not** touched or widened, per the
    Constitution's Part 3 order-of-defence conclusion — it stays the narrow
    last line, not the primary fix.
- **2026-08-11 — the W3 journey-step branch is SPECIFIED, not wired.**
  `docs/workflows/w3-journey-step-branch.md`. W3 (`Vb4ADCkPsevPRWRN`) stays
  `active: false` — nothing was touched in n8n. Today `Seed Or Harvest`'s switch
  has only two rules (seed/harvest) and no fallback, so an `action='journey_step'`
  row from `get_rhythm_due` is silently dropped — that is the entire remaining
  gap, now precisely specified as four new nodes: a third switch rule, `Compose
  Journey Step` (fans out from the existing `Seed Model` — no new AI credential),
  `Send Journey Step` (clones `Send Seed`'s literal Telegram URL — no credential
  at all), and `Record Journey Step Sent` (reuses `record_seed_sent` — no new SQL
  — with the one real gotcha spelled out: `p_grounded_on` must be a non-empty
  array built from `compose_journey_step`'s object shape, not passed through
  raw, or the call raises `seed_not_grounded`). Applying it needs the same manual
  `adam Supabase` credential attach every other new credentialed node has needed.
  With this applied and W3 turned on, the free→paid→daily-plan flow is complete
  end to end.
- **2026-08-11 — the rhythm routes the journey step** (`get_rhythm_due`,
  `20260811150000`). When the morning give would be a `seed` and the parent has a
  live stage, it becomes `journey_step`, grounded by `compose_journey_step` and
  gated by its `can_send` (no outcome → silent, not a fallback seed). Free parents
  unaffected. **Deployed to production 2026-08-11 and smoke-verified live**
  (free→seed+footer, journey→journey_step, rolled back). A safety check before
  deploy caught a pre-existing repo↔production drift: production's `get_rhythm_due`
  had already moved to the owes_exit model (`followers.proactive_footer_at`, the
  footer carried by the next proactive of any kind — seed OR harvest) but the repo
  never updated the function, only the column. The migration was rebased onto the
  live owes_exit body so deploy did not revert it, which also realigned the repo;
  `rhythm_gate_test` #12 was corrected from the superseded semantics (now 15/15).
  **Remaining: W3's journey_step branch** (compose + send + stamp seed_sent_at so
  the evening harvest still fires) — W3 stays paused until launch. With that, the
  whole free→paid→daily-plan flow is DB-complete and deployed; only the paused
  delivery workflow is left.
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
