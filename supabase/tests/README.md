# Tests

Runnable against a throwaway local Postgres, with no connection to production and no Supabase connector.

That matters more than it sounds. Every SQL object in this project until now was validated by executing it against the live database and rolling back. That works, but it means the tests cannot run when the connector is unavailable, cannot run in CI, and cannot run before a change is applied — only after.

```bash
PGBIN=$(ls -d /usr/lib/postgresql/*/bin | head -1)
DATA=$(mktemp -d); RUN=$(mktemp -d); chown postgres "$DATA" "$RUN"
su postgres -c "$PGBIN/initdb -D $DATA -U postgres --auth=trust"
su postgres -c "$PGBIN/pg_ctl -D $DATA -o '-k $RUN -p 55432 -c listen_addresses=' -l $DATA/log start"

export PGHOST=$RUN PGPORT=55432 PGUSER=postgres
createdb adam_test; export PGDATABASE=adam_test

# The three platform roles Supabase provides. Everything else comes from git.
psql -q -c "create role service_role; create role authenticated; create role anon"

# The real schema, built from the repository in timestamp order.
for f in $(ls supabase/migrations/*.sql | sort); do
  psql -v ON_ERROR_STOP=1 -q -f "$f" || echo "MIGRATION FAILED: $f"
done

# Prices — business data, which no migration carries.
psql -v ON_ERROR_STOP=1 -q -f supabase/tests/seed_test.sql

for t in supabase/tests/*_test.sql; do psql -q -f "$t"; done
```

Expected: **19 suites, 589 assertions, zero failures**, and zero failed migrations.

Because the suites now run on the schema the migrations build, this is simultaneously
the rebuild check: if a migration cannot apply to an empty database, the tests do not run
at all.

**The order is the whole point.** Each migration replaces functions the earlier
ones defined, so loading a subset tests a schema that has never existed. Run the
list, not a favourite file from it.

That is not a style note. `composed_reply_gate` was missing from this list for
days; adding it *at the end* — where a reader naturally appends — silently
reverted four later migrations and turned 32 green assertions into 24 red ones
that looked exactly like a broken change. Append by timestamp, never by habit.

Current: **21 + 27 + 25 + 35 + 14 + 29 + 71 + 27 + 19 + 32 + 29 + 35 + 18 + 36 + 35 assertions, zero failures.**

`rhythm_gate` reports 5 or 14 depending on the hour in Algiers — the harvest block
only runs when the harvest window is genuinely closed, and the 23:00–07:00 branch
asserts the quiet window instead. Both are green; only the count moves.

### Proving the repo *is* production

Green tests prove the repo is self-consistent, not that it matches the live
database. That check is one query, run on both:

```sql
select md5(string_agg(p.proname || E'\n' || pg_get_functiondef(p.oid) || E'\n', ''
                      order by p.proname))
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.proname in (...);
```

Identical hashes mean identical text, comments included. This caught a real
divergence: a function reconstructed from memory rather than read, which had
lost an argument and a whole `pinned.lines` key while still creating cleanly —
Postgres does not resolve function calls inside a `plpgsql` body at `CREATE`
time, so a wrong call site is a runtime error, not a deploy error.

## ~~`fixture_minimal.sql`~~ — deleted 2026-08-07

It described the schema by hand, because the repository could not build the real one. Every
place its description drifted from production was a place the suites tested the fixture
instead of the product: it produced three failures that looked like product bugs and were
not, and it hid at least six rows production would have refused — including
`daily_logs.situation_id` values that were actually child ids, and a `safe_for_record`
pattern the disclosure safeguard makes impossible to create.

`supabase/migrations/*` builds the real schema now, so there is nothing left to describe.
What replaced it is `seed_test.sql`: four rows of prices, which are business data rather
than schema. `fixture_mirror.sql` went with it — the real `v_child_record` exists.

## `telegram_surface_test.sql`

Twelve parents — the seven states, plus paused, strain L2, unsupported country, dormant, and a parent who does not exist — then two groups of assertions.

**State assertions** check the ladder resolves as designed.

**Hard guarantees** are the constitution as test cases (architecture §1.5):

| Guarantee | Constitution |
|---|---|
| No price in any parent-visible string | §2.1 removal test, P17 |
| `paused` outranks state | §4.5 |
| Strain L2 blocks the commercial item | P1, AD-2 |
| Unsupported country → waitlist item | §6.8 |
| Unsupported country keeps the identical free experience | §4.7 |
| No `طفلك` placeholder when the child has no name | §4.5 |
| Menu is always 5 items with exactly 1 changing | 009 |
| Arabic dual form for two nights | §0.7 |

The price check scans **only parent-visible strings** — pinned text, progress line, menu labels, keyboard. Scanning the whole payload is meaningless: it carries UUIDs, and a digit run inside a UUID is not a price. An earlier version of this test failed for exactly that reason.

## `conversation_law_test.sql`

27 cases. Each one **tries to store something the constitution forbids** and asserts the database refuses it — banned vocabulary, promotional verbs, a leaked price, a button set with no `شيء آخر`, a crisis message carrying buttons, a rescue reply raising its own line budget.

> **A rule you have never seen reject anything is a rule you are hoping for.**

Four cases test the bans for **overreach** rather than reach, which matters just as much: `خطوة` must survive a ban on `خطة`, `نفعله` must survive a ban on `فعّل`, `دجاج` must survive the currency list. A law that blocks approved copy is a law someone switches off.

The file also closes the UX↔Conversation contract: every `meaning` `get_telegram_surface()` can emit must have a matching moment, or a parent taps the menu and ADAM has nothing to say.

## `knowledge_gate_test.sql`

25 cases. One family is built up fact by fact — no name, then a name, then a situation, then three logged evenings, then a month of outcomes — and `knowledge_depth()` is **watched rising** rather than asserted. That is the point: if level 4 were a flag someone could set, the honest reason a journey becomes possible only later would stop being honest.

Then §2.6, the test the architecture names for every proactive message:

| Message | Verdict |
|---|---|
| A generic parenting tip | `generic` — does not send |
| The same tip **with the child's name in it** | `identity_only` — does not send |
| A message built on what actually worked for this child | sends |

The last two cases build a **second family** and send family A's message to family B, which must fail. §2.6 is a cross-family rule and cannot be tested with one family.

The provenance cases use the real live pattern label `التنقل بين ثلاث عائلات`, which reveals family separation. It must never become a family token, and must start counting the moment `safe_for_record` is explicitly set — that single difference is what makes the column a gate rather than decoration.

Everything runs inside a transaction and rolls back.

## `country_state_test.sql`

71 cases. The offer is live in **three** countries — الجزائر، مصر، المغرب — and the whole suite defends two claims at once: that the list is exactly three and enforced in one place, and that *"we do not sell here"* and *"we do not know where you are"* can never again produce the same sentence.

| Input | State |
|---|---|
| `DZ` / `EG` / `MA` | `supported` |
| `SA` — a row, `is_active = false` | `unsupported` |
| `SY` — no row at all | `unsupported` |
| `ZZ` · `''` · `null` · `XX` | `unknown` |

`ZZ` is the one that mattered. It is well-formed, it passes every NOT NULL check, and it means nothing — 33 families held it, and a boolean turned it into a confident answer about a place that does not exist.

One test adds a fourth country as **two rows** and asserts it becomes sellable with no code change. If that ever fails, the price list has leaked out of `supported_countries`.

The suite also proves the country question is not merely cosmetic: a parent with an unknown country is **never returned by `get_rhythm_due`**, because the rhythm joins `country_timezone` and an unknown code joins to nothing. The 59 unknown parents were not just being told something untrue — they were unreachable.

### A trap worth naming

Two assertions failed on first run, and neither was a product bug:

```sql
perform chk('...', public.country_state(pg_temp.parent('QA'))->>'state' = 'supported');
```

`country_state` is `stable`, so inside a single statement it reads that statement's snapshot — taken **before** the volatile insert nested in the same expression ran. Written on one line this fails, and it fails looking exactly like a broken function. The write and the read must be separate statements.

## `agent_gate_test.sql`

27 cases guarding the one voice nobody was checking: the conversational reply, which went from the model to Telegram untouched.

**It is deliberately not `gate_composed_reply`.** That gate enforces a line budget and a uniqueness rule alongside vocabulary, and both of those applied to open conversation push every reply toward the same safe three-line shape — the templated voice the product is trying to escape. This one checks vocabulary and nothing else.

**The blocking list was chosen by replay, not by judgement.** The first draft was pointed at `copy_violations()` and replayed against all 2,233 replies ADAM has ever sent: it blocked 53 — one in 42 — of which roughly 40 were *good answers*. «احتواء» (33 hits) is internal jargon here and ordinary Arabic for holding a child. «وافتحوا أذرعكم» tripped the ban on «افتح». «إلحاحه على الـ 50 ريالاً» is a father discussing pocket money.

The shipped rule blocks 15 of 2,234 — 0.67% — and every one is ADAM selling: a price, a closing line, posing as فريق آدم, a refund guarantee invented in the brand's name, a superiority claim. Both sets are in the suite as literal production strings, so the boundary cannot move by accident.

Machinery words (`خطة`, `نظام`) are **recorded and allowed** in `reply_gate_log`, so the line can move next month on a count instead of an opinion.

## `agent_bundle_test.sql`

19 cases. The agent had no facts about the family: `memory_snapshot` was assembled and never passed to it, so the brand's core claim — *«المرجع ليس كتاباً — المرجع عائلتكم»* — was false in the one place it mattered.

`get_agent_bundle()` carries the context, the knowledge level, and the country question in the single call an already-authenticated node was making anyway. Tests cover the framing (the model must not read our notes as the parent's words), the stripping of `PLAN_DAY`/`DAYS_LEFT`, and the level-0 case where ADAM knows nothing and must not imply otherwise.

`get_moment_after_tap()` writes a tapped country **before** composing the answer — the order is the assertion, because the reverse confirms one country while quoting the price of another.

### Why these are functions and not nodes

n8n's MCP API cannot attach a `supabaseApi` credential to a new `httpRequest` node: `setNodeCredential` and `addNode` both reject the pair. Pre-existing nodes hold their credential server-side and the API omits it from every response, so they *look* bare and work. Three nodes added this way failed at runtime with `Credentials not found` — one of them, `Tap - Record Country`, had been silently discarding every country a parent tapped for two days.

The number of Supabase-authenticated nodes in W1 cannot go up. The workaround — copying the hardcoded `apikey` header the older nodes use — is how the `service_role` key came to appear 116 times in plaintext, so existing calls carry more instead.

## `intention_capture_test.sql`

29 cases. ADAM asked a parent the one question the whole promise hangs on — *«أيّ أب أو أمّ تمنّيتم أن تكونوا له؟»* — and then threw the answer away. `record_intention()` had existed, tested, since `give_before_asking`, called from nowhere.

Most of this file is about **not** capturing. The intention is written once and never overwritten, so a wrong capture is permanent, and every guard gets its own case with its own parent — a captured answer would close the door for every case after it and the suite would pass for the wrong reason:

| The parent types | Verdict |
|---|---|
| `أب هادئ، لا يصرخ في أولاده`, same night | kept |
| the same, four days later | `window_closed` |
| `ok` | `too_short` |
| `/faq` | `command` |
| `كيف يعني؟` · `what do you mean?` | `a_question` |
| a paragraph about tonight | `too_long` |
| four lines about tonight | `not_a_sentence` |
| a second answer, after one was kept | `not_awaiting`, and the first survives |

The pair that matters most is the last group: a **declined message stores nothing**, and the real answer sent right after it still lands. Declining is only safe if it is not also destructive.

Four cases guard the carrier rather than the rule — a captured message must not *also* spend the country ask or build a context for a model that will never run, and an ordinary message must come back with the identical bundle it always did.

## `offer_surface_test.sql`

22 cases on the one screen where a parent decides whether to pay.

Two of them are about markup. Nothing in this product sends with a `parse_mode`, so
`**عنوان**` reached parents as literal asterisks for as long as it was there. The test
asserts no stored moment carries `**`, and then tries to insert one and asserts the
database refuses it.

The rest pin **each promise in the offer to the thing that enforces it**, so the copy
cannot quietly shrink back to the modest version that undersold the product:

| The line | Enforced by |
|---|---|
| «لا حين يمرّ التقويم» | `v_stage_progress.logged_days` |
| «أُكمل معكم نصفها… بلا أن تطلبوا» | `stages.extension_days` |
| «يرجع مالكم» | `stages.refunded_at` |
| «رحلة واحدة في المرّة» | `uq_one_live_stage_per_parent` |
| «إن رأيت الأمور تتحسّن… أصمت» | `can_propose_stage` → `trend_improving` |

> **A promise with no column behind it is a lie with a deadline.**

The call-to-action cases check the button carries a `url` rather than the message body
carrying an address, that its label names the child when we know one — and that it
falls back to a general label when we don't, rather than putting «طفلكم» on a button.

### The `STABLE` snapshot trap, again

Every case here creates its parent in **its own statement**, never nested inside the
call under test:

```sql
p := pg_temp.parent('DZ', 'يوسف');   -- statement 1
j := pg_temp.offer(p);               -- statement 2
```

`country_state()` is `STABLE`, so written on one line it reads the snapshot taken
*before* the insert and every supported-country case fails looking exactly like a
broken function. This is the third time the same trap has cost real debugging; it is
in this README twice now for that reason.

## `team_question_test.sql`

17 cases. A parent asked «اريد ان اعرف بخصوص المرافقة الكاملة» and the model answered
at length, invented «وسيتواصلون معكم قريباً» — nobody was going to — and gave no link.
The prompt already forbade quoting a price; it cannot forbid inventing a follow-up,
because the failure is not vocabulary. It is a model answering a question it has no
facts for.

`is_team_question()` recognises the shape and the reply becomes a fixed moment with the
فريق آدم button on it, so the model never sees the turn.

**Most of the file is the false-positive set**, because the two errors are not
symmetrical. A missed phrasing costs one ordinary reply. A false positive hands a sales
card to a parent telling us their child hit their brother.

| Excluded token | The message it would have broken |
|---|---|
| `بكم` | «أهلاً بكم، سعيدة بوجودكم» |
| `شحال` | «شحال من مرة قلت له لا ينفع» — a count |
| `قداش` | «قداش من ليلة وأنا صاحية معه» |
| `الدفع` | «الدفع بينهم كل يوم صار عادة» — pushing, not paying |
| `رحلة` | «رحلتنا إلى بيت جدّته كانت متعبة» |

Their narrower cousins are kept: `بكام`, `بشحال`, `بقداش`, `طريقة الدفع`,
`المرافقة الكاملة`.

Three cases guard the ordering inside `get_agent_bundle`: the team check runs **before**
`capture_intention`, because «اشتراك» is short, has no question mark and is one line —
the capture would have taken it and written it into that parent's intention permanently,
as who they hoped to be.

## `journey_engine_test.sql`

36 cases, and the first of them could not have been written before this week: until
`20260807090000` the entire journey engine was a schema, a gate and a view, and **nothing
had ever written a row**, so none of it had ever run.

Two families are walked through a whole journey, day by day:

| Family | What happens |
|---|---|
| آدم | 29 hard nights → clock exhausted, objective missed → **extended by 14 in the same call that detected the miss** → 14 more hard nights → `failed` |
| ليان | 3 calm nights (not enough), 6 hard, then a full calm week → `objective_met` → `completed` **before** the clock ran out |

The «3 calm nights is not five of seven» case is the one worth keeping: `objective_met`
requires a **full measurement window**, so a good week cannot be declared a finished
journey. That rule lives in `v_stage_progress` and is asserted here, not restated —
restating a rule is how two versions of it start to disagree.

### The walk is the beginning of the simulation harness

`pg_temp.walk(parent, nights, result)` writes N distinct `log_date` rows, because
`daily_logs` is unique on `(follower_id, log_date)` — the same constraint that makes the
clock count **days** rather than messages. With nobody being messaged in production, this
is currently the only way any time-and-evidence path can be seen working at all.

### What start_stage deliberately does not check

`can_propose_stage` refuses on a 30-day cadence, a lifetime cap per problem, and an
improving trend. Those govern when ADAM may *raise* the subject. `start_stage` ignores
them on purpose and enforces only structural invariants — one live journey, a target
inside its window, a clock of 7..60 logged days.

> **Refusing to start a journey someone has already agreed and paid for is not a
> safeguard. It is a bug that takes money.**

The last two cases cover the half-state this migration exists to remove: paying **with**
an agreed goal starts the journey, and paying **without** one still records the money but
returns `journey.started = false, reason = objective_required` — loudly, in the return
value, instead of leaving a paid parent silently adrift.

## `lifecycle_test.sql` — the simulation harness

35 cases walking **one synthetic family from stranger to finished journey**, in seconds.

This file exists because of a decision, not a preference. ADAM is stopped and nobody is
being messaged until the build is finished — but every engine here is a **time and
evidence machine** (three attempts, two calm nights, fifteen outcomes), so with no
traffic none of them will ever accumulate the data that makes them run. Offline, walking
a synthetic family through time is the only way these paths can be watched working at
all.

**Every row is written by the production function the live product would call:**

```
commit_child_name → commit_situation → record_seed_sent
→ record_harvest_sent → record_harvest_answer → start_stage → close_stage
```

Nothing inserts a `daily_logs` row by hand. That is the difference between a harness and
a fiction: a harness that invents its own rows tests the harness. The one place history
must be aged — `record_harvest_answer` only ever writes today — moves the **date** of a
row the real function produced and never its contents, and one assertion pins the aged
shape to a live one.

What it watches, in order: `knowledge_depth` 0→1→2→3→4 each for its own reason;
`can_send` flipping for seed, harvest and mirror; `offer_ready` becoming true on the
exact night it is earned; strain withdrawing the offer and the recovery window holding it
withdrawn; then the journey started, missed, extended and reached.

### It caught the product three times while being written

| The harness assumed | The product actually does |
|---|---|
| answering a harvest is enough | the harvest is **sent** before it is answered — `record_harvest_sent` sets `harvest_sent_at`, and without it `can_send('harvest')` still says an evening question is owed on a day already answered |
| strain drops the moment a parent recovers | L2 **holds for three days** before it may step to L1. Nobody is declared recovered on one calm sentence |
| the journey clock counts the nights before it | it counts days on or after `started_at` — the free-tier nights before the sale are deliberately not borrowed |

None of those were assertion bugs. All three were the harness being wrong about the
product, which is the whole reason to write one.

### And the STABLE snapshot trap, a fourth time

`set_strain_level` is VOLATILE and `offer_ready` is STABLE. Calling both inside a single
expression makes `offer_ready` read the snapshot from **before** the step-down and report
the offer still withdrawn — a failure that looks exactly like a broken product. The write
and the read must be separate statements. This trap has now cost real debugging in
`country_state`, `offer_surface`, `journey_engine` and here.

---

## `restored_functions_test.sql` — the twelve that lived only in the database

Sixty-five assertions over the functions restored by
`20260807140000_the_repo_can_rebuild_production.sql`. Every one of them had been running
in production for weeks with no source in git, and therefore no test — which is the same
thing as nobody knowing what they do.

The cases do not re-describe the bodies. They assert the promises the bodies make:

- **`_ensure_child`** — the same name twice is one child, a different name is a different
  child, no name resolves to the *primary* child, and a parent with no children at all
  gets exactly one placeholder.
- **`write_child_name`** — a recorded name is never replaced by a new inference; an empty
  one is filled in and the orphan nights back-linked; and with **two** children the orphan
  nights are left orphaned, because a sibling's nights must never be reassigned on a guess.
- **`writer_commit`** — everything it takes is model output, so: the placeholder is
  promoted rather than left beside the real name, blank fields write nothing, an invented
  `event_type` is clamped to `other`, a weight of 99 becomes 5, a second sighting of a
  pattern raises evidence instead of duplicating the row, the read watermark only moves
  forward, and a blank snapshot never erases the one we had.
- **`heart_commit`** — five blank fields write nothing, report `false`, and **do not stamp
  the freshness clock**, so the parent is retried next cycle rather than skipped forever.
- **`get_free_session_state`** — a session is a gap, not a clock; and coming back *twice*
  is what makes a parent golden.
- **`surface_changing_item`** — when commerce is blocked the label is **identical** to the
  ordinary one. A withheld journey is silent, never announced as a thing being withheld.
- **`return_to_free`** — the subscription clock is cleared and the payment row is not
  touched.

### Two failures that were the fixture, not the product

`_ensure_child` orders by `is_primary desc, created_at asc`. In Postgres `DESC` puts NULLs
**first**, and `fixture_minimal.children.is_primary` was nullable while production's is
`NOT NULL DEFAULT false` — so a child with a null flag outranked the actual primary child,
in the fixture and in no other database. The fixture was wrong; the readers were right.
This is the third time a looseness in the fixture has produced a failure that looked like
a product bug (see §`fixture_minimal.sql`), and the answer each time is the same: copy the
column definition from `information_schema`, not from memory.

The other two were `now()`. Inside one transaction `now()` is constant, so a chat row
inserted "after" a memory write ties with it, and a `BEFORE UPDATE` trigger's stamp equals
one taken moments earlier. Both tests now say so explicitly rather than asserting a strict
`>` that only holds in production.

### The Mirror suite had been unrunnable, silently

`mirror_engine_test.sql` (10 assertions) was orphaned from the offline chain. When the
journey engine landed, `fixture_minimal.sql` gained a `crisis_flags` table — and
`fixture_mirror.sql` still created its own stub of the same name. The second `CREATE`
aborted `fixture_mirror.sql` at line 16, taking `v_child_record` with it, and the whole
suite failed on a missing view rather than on anything about the Mirror.

The stub is deleted rather than guarded with `IF NOT EXISTS`: two fixtures owning one
table is exactly how the shapes drift apart. The mirror migrations are now part of the
standard chain, so the suite runs with everything else.

---

## The rebuild check — the one a fixture cannot fake

Since 2026-08-07 the repository can build production from an empty database. That is worth
running as a check, not just claiming once:

```bash
createdb rebuild
psql -d rebuild -c "create role service_role; create role authenticated; create role anon"
for f in $(ls supabase/migrations/*.sql | sort); do
  psql -d rebuild -v ON_ERROR_STOP=1 -q -f "$f" || echo "FAIL $f"
done
```

Expected: **0 failures, 29 tables, 12 views, 88 functions**, matching production by name.

It earns its place because it catches a class of problem the offline suite structurally
cannot. `fixture_minimal.sql` describes the schema the tests need; when it disagrees with
production, the tests still pass — they are agreeing with the fixture. The rebuild has no
fixture to agree with. On its first run it found two functions that reading had missed
(`get_agent_context`, `commerce_allowed`), five views nobody had noticed were sourceless,
three migrations that could not apply to a fresh database, and a live privilege escalation
in production.

**The natural next step is to stop needing the fixture.** Every table it stubs now has real
DDL in git, so the suites could run against the rebuilt schema instead — and the three
places `fixture_minimal.sql` still admits to being looser than production (`situations`,
and its simplified `commerce_allowed` and `can_ground_seed`) would stop being drift and
start being nothing at all.

## The fixture is gone — 19 of 19 on the real schema

The suites run against the schema `supabase/migrations/*` builds. There is no longer a
hand-written description of the database anywhere in this repository.

Getting there took fixing nine suites, and **every one of them was writing rows production
would refuse** — not failing assertions, failing constraints:

| What the tests did | What production says |
|---|---|
| `situations` inserts with no `parent_id`, `label_ar`, `window_start`, `window_end` — **21 sites** | all four NOT NULL. The rhythm's windows had been null in every test and never in production. |
| `daily_logs.situation_id` set to a **child** id — 3 sites | `daily_logs_situation_id_fkey`. Three nights pointed at a situation that did not exist, and every assertion still passed. |
| `child_patterns` with `safe_for_record => true` | `guard_safe_for_record` forces it false on INSERT; only `set_pattern_record_visibility()` can raise it, with an audit row naming who approved it and why. **`/child` had been reading back a row the disclosure safeguard would never release.** |
| `child_patterns.status = 'confirmed'` | `child_patterns_status_check` allows `active`, `improving`, `resolved`, `dormant`. Nothing else. |
| `child_patterns` with no `follower_id` | NOT NULL. |
| `night_result = 'skip'` | `daily_logs_night_result_check` allows `calm`, `hard`, `normal`. The production shape for a night too tired to try is `step_status = 'not_tried'`; `parent_effort` counts identically either way, since it only ever counts calm and hard. |
| `funnel_stage = 'paid_active'` with no `subscription_expires_at` | `chk_active_has_expiry`. Paid access always has an end. |
| activating a market with some prices missing | `chk_active_market_has_pricing`. An active market carries every price it can be asked for. |

None of these were caught by 589 passing assertions, because the fixture agreed with the
tests. A fixture the tests agree with is not evidence — it is a second opinion from the
same source.

