# What is missing, most important first

**Written:** 2026-08-06. Founder's decision: ADAM is stopped, nobody is being messaged,
and the build is to be finished **before** any launch. Nothing here assumes live users.

Every claim below was checked against production or the live workflows on the day of
writing. Where something is "built and unwired", that is stated as a fact, not a guess.

---

## The one-paragraph answer

The **free** product is nearly complete but two of its three engines are switched off, so
it behaves like a good chatbot with no memory of anything. The **paid** product is about
a quarter built: it has a schema, a gate, and a progress view — and **no way to start,
run, or finish a journey**. Everything the offer sells is currently unbacked by code.

---

## 0. Fixed the day it was found: anyone could grant themselves a journey

Found on 2026-08-07 while proving the rebuild. Four SECURITY DEFINER functions
were executable in production **with the public anon key**:

| Function | What the holder of a public key could do |
|---|---|
| `activate_subscription(…10 args)` | **grant paid access and start a journey**, for any follower id |
| `get_conversation_for(text)` | read any parent's entire conversation history |
| `heart_commit(text, jsonb)` | overwrite what ADAM remembers about any family |
| `write_child_name(text, text)` | write a child's name for any parent |

Two causes, neither a mistake in the security model — both side effects of
ordinary work:

1. The ten-argument `activate_subscription` is an **overload**, created when the
   journey engine gained its start parameters. A new function is born with
   EXECUTE granted to PUBLIC, and week 0 had revoked the five-argument one *by
   exact signature*. A signature protects one function; it does not protect a
   capability.
2. Week 0 wrote `REVOKE … ON FUNCTION public.get_heart_batch()`. That function
   takes `p_limit integer default 40`, so the signature matched nothing, the
   statement raised, and the two revocations written **after** it — `heart_commit`
   and `write_child_name` — never ran. One wrong signature silently cancelled the
   rest of the list, twelve days before anyone looked.

A third, found only by verifying the fix on a bare cluster: `REVOKE … FROM anon`
does not remove a privilege `anon` holds through **PUBLIC**. Supabase happens to
revoke PUBLIC and grant `anon` explicitly, so week 0's revoke worked there and
would have been a no-op anywhere else.

Closed in `20260807160000_nobody_grants_themselves_a_journey.sql`, **applied to
production** and verified: `anon` has EXECUTE on none of them, `service_role`
still has every one of them. Revocation is now by function *name* so every present and
future overload is covered, and `alter default privileges` closes the door the
next new function would otherwise walk through.

Nothing in the product lost access — n8n authenticates as `service_role`.

---

## Where a parent's life actually stops

| # | Stage of the relationship | State |
|---|---|---|
| 1 | First contact, menu, free conversation | ✅ live |
| 2 | ADAM learns the family (name, situation, memory) | ⛔ W2 paused — nothing extracts anything |
| 3 | Daily rhythm: the step in the morning, the question at night | ⛔ W3 paused — and it is the only writer of outcomes |
| 4 | Evidence accumulates, knowledge level rises | ⛔ blocked by 2 and 3 — 0 parents above level 2 |
| 5 | The Mirror — the first time ADAM shows them something they did not know | ⛔ W4 archived; `generate_first_mirror` ready, nothing renders it |
| 6 | The offer moment, when they have earned it | ✅ built — can never fire while 3 and 4 are blocked |
| 7 | **Payment becomes a journey** | ❌ **does not exist** |
| 8 | The journey runs: a step a day, phases, progress | ❌ does not exist |
| 9 | Reaching it — or the free extension | ❌ does not exist |
| 10 | After arrival | ❌ not designed |

---

## 1. ~~The journey engine has no write side~~ — BUILT 2026-08-07

`suggest_objective`, `start_stage`, `stage_state` and `close_stage` exist, with a
36-assertion suite walking two families through a whole journey
(`supabase/tests/journey_engine_test.sql`). What follows is why it was needed, and one
thing that is still true.

**Also fixed, later the same day:** `activate_subscription` briefly had two overloads, and
the five-argument one — the one the dashboard calls — was not merely the old path, it was
*uncallable*: two candidates matched and Postgres refused to choose. See §3. There is now
one function, and a five-argument call records the payment and returns
`journey.started = false, reason = objective_required`.

### The original entry

`stages` exists. `v_stage_progress` derives phase, days remaining and whether the
objective was met. `can_propose_stage` decides when it may be offered.

There is **no function that creates a stage, advances it, extends it, or completes it.**
The full list of journey functions in production is: `can_propose_stage`. That is all.

So today, end to end:

```
parent pays  →  فريق آدم confirms  →  activate_subscription()
             →  funnel_stage = 'paid_active', 30 CALENDAR days
             →  no stage row, no objective, no target, no window,
                no phases, no measurement, no extension
```

The offer promises «نتّفق على هدف واضح ترونه بأعينكم» and «أُكمل معكم نصف المدّة مجاناً
إن لم نصل». Neither sentence has an object in the database to attach to, because there is
no «نصل» and no «المدّة» — only an access clock counting down.

**What has to exist:**

| Function | Job |
|---|---|
| `start_stage(parent, problem_key, objective_text, metric, target, window)` | one live stage per parent, enforced by the index that already exists |
| `stage_state(parent)` | the live stage plus its derived phase and progress, for the conversation and for `/progress` |
| `close_stage(stage)` | met → `completed`; clock exhausted and not met → grant the half-length extension once, `extended`; exhausted again → `failed` |
| `activate_subscription` rewritten | to call `start_stage`, or to be deleted in favour of it |

This is buildable now, with no users and no risk. It is pure database work with an
offline test suite, exactly like everything else this month.

## 2. ~~There is no way to prove the engine works without messaging anyone~~ — BUILT 2026-08-07

`supabase/tests/lifecycle_test.sql` walks one synthetic family from stranger to finished
journey in seconds, every row written by the production writers. See
`supabase/tests/README.md`. What follows is why it was needed.

This is the gap the founder's decision creates, and it is the one that unblocks
everything else.

The knowledge engine, the rhythm, the offer moment and the journey are all **time and
evidence machines**: they need 3 attempts, 2 calm nights, a month of outcomes. With
nobody being messaged, none of that data will ever appear, so none of these paths can be
seen working — only unit-tested in pieces.

**What has to exist: a simulation harness.** A synthetic family, and a function that
walks it through N days — seed sent, answer recorded, outcome logged — so the whole
lifecycle can be run in seconds, offline, and asserted:

- knowledge_depth rises 0 → 4 in the right order, for the right reasons
- `offer_ready` becomes true on exactly the night it should, and not before
- a stage started, run, missed, extended, then met
- `can_send` refuses at the right moments (strain, crisis, improving trend)

Without this, "the product is complete" is an opinion. With it, it is a test run.

## 3. Two of everything — the legacy layer, half deleted 2026-08-07

The offer/engine mismatch in §1 is not an isolated accident. It is the pattern. What
follows is what has gone, what stayed and why, and what is left.

### Done — and one thing §3 got wrong

| Deleted | Superseded by |
|---|---|
| `get_checkin_batch()` | `get_rhythm_due()` |
| `record_checkin_sent()` | `record_seed_sent()` / `record_harvest_sent()` |
| `record_checkin_response()` | `record_harvest_answer()` |
| `ensure_checkin_state()` | `set_checkin_hour()` / `get_moment_after_tap()` |
| `followers.checkin_opt_in`, `checkin_opted_at`, `last_checkin_sent_date` | the tap system — archived to `archive.followers_checkin_20260807` (15 rows) first |
| `activate_subscription(uuid,int,numeric,text,text)` | the ten-argument one — see below |

**`checkin_state` was on this list and should not have been.** The table was never
replaced; the rhythm *adopted* it. Five live functions depend on it right now —
`get_rhythm_due` (skips a stopped cadence), `get_telegram_surface` (shows a paused parent
«كيف نعود؟»), `record_harvest_answer` (resets the streak), `get_moment_after_tap`
(pause/resume/stop taps) and `set_checkin_hour` (her chosen evening hour). Dropping it
would have deleted every means a parent has of controlling when ADAM speaks. It stays, and
`supabase/tests/consent_decay_test.sql` now asserts that it stays. So does
`daily_logs.checkin_sent_at`, which the live `CK - Save Night Result` node still writes.

This is the entry that justifies doing the deletion slowly. The list was written from what
the objects were *named*, not from what still *reads* them.

### `activate_subscription` was not duplicated — it was broken

Deleting the old overload was not tidying. Production was returning:

```
ERROR: 42725: function public.activate_subscription(uuid, integer, numeric, text, text)
       is not unique
```

`CREATE OR REPLACE FUNCTION` with a longer parameter list does not replace — it creates an
overload, and because arguments six to ten all had defaults, a five-argument call matched
both candidates and Postgres refused to choose. **Every dashboard activation had failed
since 2026-08-07.** Nobody noticed because nobody has been paying. The first sale would
have found it. Fixed in `20260807170000_one_way_to_activate_a_subscription.sql`: one
function, and a five-argument call now records the payment and returns
`journey.started = false, reason = objective_required`.

### `decay_checkin_consent` was inert, not dead — and that was the worse bug

It looked like part of the checkin engine. It is the consent model: five ignored nights
quieten the rhythm to weekly, nine more stop it, one reply resets the streak. It counted
ignored nights from `checkin_state.last_sent_date`, and the only function that ever wrote
that column was `record_checkin_sent` — replaced by the rhythm on 30 July.

So since 30 July the live product had the *recovery* half working and the *decay* half
counting nothing. It could come back from silence it was structurally unable to notice: it
would have gone on asking nightly, forever, of someone who stopped answering weeks ago. For
a product whose first principle is that it must be possible to be left alone, that is the
worse half to have working.

Rebuilt on the rhythm's own evidence in `20260807190000_silence_is_still_an_answer.sql` —
an ignored night is one where `harvest_sent_at is not null and harvest_answered_at is
null`, so a night the sender never ran is our silence and not hers. Idempotent within a
day via a `last_decayed_on` watermark, and it catches up after a day it did not run.
22 assertions. **It still has no scheduled caller** — see below.

### Left, and why

| Item | State |
|---|---|
| `Adam - Nightly Checkin` workflow (`A2XHImAuFiPA6Yoh`) | paused; its four database functions are gone, so it can only error. Safe to archive in n8n. |
| **`decay_checkin_consent` has no caller** | Nothing runs it. The rule is correct and tested and fires never. It needs a daily schedule — W3, or its own small workflow. |
| ~14 dead `followers` columns | **Blocked, and not by risk of the unknown.** Four dashboard views (`v_funnel_summary`, `v_funnel_weekly`, `v_offers_log`, `v_conversations_list`) read `cohort`, `is_golden`, `offer_score`, `judge_reason`, `offer_text`. Dropping the columns means rewriting the founder's reports, which is a decision about what he wants to see, not a cleanup. |
| W1 orphan nodes | **64 of 126, not 17** — see §3b. |

## 3b. Half the live workflow is unreachable

Measured, not estimated: walking `connections` forward from `Telegram Trigger` (and
backwards along `ai_languageModel` / `ai_memory` edges, which attach a model or memory to
its agent), **62 of 126 nodes are reachable. 64 are not.**

Whole subsystems, all superseded by the moment/tap system:

| Dead subsystem | Nodes |
|---|---|
| `OB - *` — the old button onboarding | 27 |
| `CTA - *` — the old offer flow | 13 |
| the daily cap (`Check daily Cap`, `M2 - Cap Exceeded?`, `M2 - Send Cap Message`, `Mark Cap Reached`) | 4 |
| country (`Parse Country`, `Save Country`, `Send Country Buttons`) | 3 |
| waitlist, referral, pinning, reactivation, misc | 17 |

This also answers §7's «`check_daily_message_cap` runs on nobody» — its node is in a dead
branch, along with the three others that would have enforced the cap.

**Not deleted yet, deliberately.** This is 64 nodes out of a live, active workflow, it is
four times what §3 estimated, and unlike the database half there is no offline suite that
can prove the survivors still work. It wants the founder's go-ahead and a live pass
afterwards.

## 4. The Mirror has no sender

`generate_first_mirror(child_id)` is built, tested (10 assertions), and returns a payload
that deliberately never leaks the parent's own words. W4 is **archived**. Nothing renders
or sends it.

The Mirror is the moment the product is named after — the first time ADAM shows a parent
something they did not already know about their own house. It is the emotional peak of
the free tier and the honest earning of the offer. It currently cannot happen.

## 5. Nothing learns from a conversation while W2 is off

W2 extracts the child's name, classifies the situation from a closed catalog, and writes
emotional memory. Paused. So even if the rhythm were running, `knowledge_depth` would
stay at 1 for almost everyone: 239 of 310 parents are at level 0 today.

W2 and W3 are the two paused engines. They cost money per run, which is why they are off —
but the answer is not "leave them off", it is §2: run them against synthetic families
first, then a small real cohort at launch.

## 6. «ما بعد الوصول» is not designed

§10 item 6. Not unwired — undesigned. What happens the day a family reaches their goal,
and what ADAM becomes afterwards, has no answer yet. It is last on this list because
nothing can reach it until 1–5 exist, but it must be answered before the first paid
journey completes, which is 29 days after the first sale.

## 6b. ~~The repo cannot rebuild production~~ — CLOSED 2026-08-07

**A blank Postgres database now becomes production from this repository alone:
66 migrations, zero failures, 29 tables, 12 views, 88 functions — the same names
production has, checked by set difference, not by counting.**

That is what this section asked for. What follows is the record of what was
actually wrong, because the first version of it was wrong twice.

### The number was wrong

It said "34 of 88 functions have no source in this repo". That diff was taken
against the **offline test chain** — the migration files the harness loads on top
of `fixture_minimal.sql` — not against the **repository**, which holds 66.
Everything the chain did not load counted as absent when it was merely untested.
Re-checked name by name, **fourteen** functions genuinely had no source:

`writer_commit`, `_ensure_child`, `get_extraction_batch`, `write_child_name`,
`get_heart_batch`, `heart_commit`, `get_conversation_for`,
`get_free_session_state`, `check_daily_message_cap`, `surface_changing_item`,
`return_to_free`, `set_updated_at`, `get_agent_context`, `commerce_allowed`.

Seventeen more were in git the whole time (the child-record and erasure family,
the checkin family, `get_pricing`, both chat-history guards,
`record_mirror_delivered`, `derive_aha_class`, `jsonb_text_values`,
`commit_child_name_by_platform`). Restoring those would have created a *second*
source for each — the disease, not the cure.

### The diagnosis was wrong too

Functions were never the real gap. This migration history begins at
`20260729123012_week0_*`, on a database that already existed and already held 310
families. **Fourteen tables and five views had no DDL in git at all** — including
`followers`, `children`, `daily_logs` and `n8n_chat_histories`. No number of
restored functions would have made a rebuild possible.

Now in the repository, dated before week 0 so a rebuild meets them first:

| File | Carries |
|---|---|
| `20260729000000_baseline_the_tables_that_predate_the_repo.sql` | 14 tables, their constraints, indexes, RLS and policies |
| `20260729000100_baseline_the_functions_that_predate_the_repo.sql` | 13 of the 14 functions |
| `20260729000200_baseline_the_views_that_predate_the_repo.sql` | the 5 dashboard views |
| `20260730183100_commerce_allowed_restored.sql` | the 14th, which belongs with the strain layer |
| `20260807150000_baseline_tail_the_bindings_that_needed_later_objects.sql` | the FKs and triggers that point at objects later migrations create |

### Only running the rebuild found the last four problems

Reading found twelve functions. **Attempting the rebuild** found
`get_agent_context`, `commerce_allowed`, the five views, and three migrations
that could not apply to a fresh database at all:

- **week 0's revocations aborted** on `public.messages` and
  `public.collective_intelligence`, two tables since dropped. An unguarded
  statement in the middle of a security file cancels every revocation after it.
- **week 0's `search_path` pins aborted** on six functions that
  `20260729160000_cleanup_*` deletes an hour later.
- **`20260729160200`'s `COMMENT`** named an `activate_subscription` signature no
  migration creates.

All three are now guarded loops that skip what is absent instead of dying on it.
This is the argument for the rebuild being a routine check rather than a
one-off: it is the only test that cannot be satisfied by a fixture agreeing with
itself.

### And it uncovered a live privilege escalation — see §0

## 7. Smaller, real, and cheap

- **`check_daily_message_cap` runs on nobody** — and §3b now says why: its node is one of
  64 unreachable ones, together with the three others that would have enforced the cap
  (`M2 - Cap Exceeded?`, `M2 - Send Cap Message`, `Mark Cap Reached`). It also does not read
  `funnel_stage` — cap 68 for everyone, 15 for waitlisted. Either wire the branch or delete
  it; leaving a cap that does not cap is worse than either.
- **`decay_checkin_consent` has no scheduled caller.** Rebuilt and tested on 2026-08-07
  (§3), correct, and it fires never. It needs a daily run — a step in W3, or its own small
  workflow. Until then the rhythm still cannot be quietened by silence.
- **The service-role key is in W1 in plaintext ~116 times.** Founder-owned rotation, still
  open, and it should not survive to launch day.
- **~~`fixture_minimal.situations` is looser than production~~ — FIXED 2026-08-07.**
  `parent_id`, `label_ar`, `window_start` and `window_end` are NOT NULL in the fixture now,
  and all 21 raw inserts fill them from `situation_catalog` — the same source
  `commit_situation()` uses. Proven by running the suites against the real migrated schema,
  where every one of those inserts was refused. Two more of the same class went with it:
  `child_patterns.follower_id` (NOT NULL in production, omitted in two suites) and a
  `status` of `'confirmed'`, which `child_patterns_status_check` does not allow at all.
  See §7b for what the same experiment found next.
- ~~The old wording:~~ `parent_id`, `label_ar`,
  `window_start` and `window_end` are NOT NULL in production; the fixture leaves all four
  nullable and ~25 test inserts omit them. No product behaviour is mistested today — the
  only reader of the windows is `get_rhythm_due`, and that test supplies them — but this
  is the same class of drift that made every `/start` return 400 once. The fix is moving
  those inserts onto `commit_situation()`, production's only writer.
- **`commerce_allowed`'s recovery window is dead code.** The body reads
  `ps.level = 1 and (ps.entered_at < now() - interval '14 days' or ps.level = 1)`. The
  second half of that parenthesis is true whenever the first condition already passed, so
  the fourteen-day settling period after strain steps down never applies: commerce reopens
  the instant a parent returns to level 1. Whether it *should* wait is a decision about how
  soon it is decent to mention money to someone who was drowning last week — the founder's
  call, so the line was restored exactly as it runs
  (`20260730183100_commerce_allowed_restored.sql`) and named here instead of quietly
  changed. Note also that `lifecycle_test.sql` exercises the *fixture's* simplified
  `commerce_allowed`, not this body, which is how it went unnoticed.
- **`get_child_record`, `request_erasure`, `execute_erasure`** — the privacy promise
  («تطلبون محوه فيُمحى كلّه») is wired for erasure via `menu_privacy_erased`, but
  `get_child_record` (the "show me everything you know" side) has no surface.

---

## 7b. The suites still describe a schema production would refuse

Now that the repo can rebuild production (§6b), the offline suites can run against the
**real** migrated schema instead of `fixture_minimal.sql`. That experiment was run on
2026-08-07: **10 of 19 suites pass unchanged. 9 write rows production would reject.**

This is the last of the fixture drift, and it is worth finishing, because a fixture the
tests agree with is not evidence — it is a second opinion from the same source.

| Constraint hit | Suites | What the test does that production forbids |
|---|---|---|
| `supported_countries.currency` / `price_comeback` NOT NULL, and `chk_active_market_has_pricing` | `country_state`, `journey_engine`, `offer_surface`, `team_question` | activates a market without the prices it will be asked for. One shared helper fixes all four. |
| `chk_active_has_expiry` | `restored_functions` | sets `funnel_stage = 'paid_active'` with no `subscription_expires_at` — paid access with no end |
| `daily_logs_night_result_check` | `give_before_asking` | a `night_result` outside `calm` / `hard` / `normal` |
| `daily_logs_situation_id_fkey` | `composed_gate` | a `situation_id` that is not a situation |
| `guard_safe_for_record` | `knowledge_gate` | sets `safe_for_record` directly; production demands an approval row in the same transaction, so the test must go through `set_pattern_record_visibility()` |

The last one is not a schema detail — it is the disclosure safeguard. The test has been
asserting behaviour for a row the product makes impossible to create.

**The finish line is deleting `fixture_minimal.sql`.** Every table it stubs now has real
DDL in git; what remains is these nine suites and a small seed file for
`supported_countries`, which is business data rather than schema.

## The order, and why

| # | Build | Why here |
|---|---|---|
| 1 | The simulation harness (§2) | Nothing after this can be *seen* working without it. Cheapest thing on the list, and it makes every later claim checkable. |
| 2 | The journey write side (§1) | The paid product does not exist without it, and the offer is already selling it. |
| ~~2b~~ | ~~The baseline schema (§6b)~~ — **DONE 2026-08-07** | A blank database now becomes production from this repo: 66 migrations, 0 failures, 29 tables / 12 views / 88 functions matching by name. Step 3 can now delete safely. |
| ~~3~~ | ~~Delete the legacy layer (§3)~~ — **DATABASE HALF DONE 2026-08-07** | Four dead functions and three columns gone (archived first); `activate_subscription` unified, which also fixed a production error nobody had hit yet; `decay_checkin_consent` rebuilt rather than deleted. `checkin_state` kept — §3 was wrong to list it. |
| 3b | The 64 unreachable W1 nodes (§3b), and the ~14 `followers` columns | Both need the founder: the nodes because it is half a live workflow with no offline proof, the columns because four dashboard views read them. |
| 4 | The Mirror sender (§4) | Small — the payload is ready. Restores the free tier's peak. |
| 5 | Turn W2 + W3 on against synthetic families, then verify the whole lifecycle end to end | Needs 1–4 done to be meaningful. |
| 6 | «ما بعد الوصول» (§6) | Design pass, needed before any journey can finish. |
| 7 | The small ones (§7) | Cheap, and the key rotation must land before launch. |

**Steps 1–4 need no users, no sends, and no cost.** They are the whole of "finish the
build". Step 5 is the first moment anything is switched on, and by then every path has
already been proven on synthetic data.
