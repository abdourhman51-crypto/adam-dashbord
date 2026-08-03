# Tests

Runnable against a throwaway local Postgres, with no connection to production and no Supabase connector.

That matters more than it sounds. Every SQL object in this project until now was validated by executing it against the live database and rolling back. That works, but it means the tests cannot run when the connector is unavailable, cannot run in CI, and cannot run before a change is applied — only after.

```bash
PGBIN=$(ls -d /usr/lib/postgresql/*/bin | head -1)
DATA=$(mktemp -d); RUN=$(mktemp -d); chown postgres "$DATA" "$RUN"
su postgres -c "$PGBIN/initdb -D $DATA -U postgres --auth=trust"
su postgres -c "$PGBIN/pg_ctl -D $DATA -o '-k $RUN -p 55432 -c listen_addresses=' -l $DATA/log start"

export PGHOST=$RUN PGPORT=55432 PGUSER=postgres
psql -v ON_ERROR_STOP=1 -f supabase/tests/fixture_minimal.sql
for m in 20260731090000_telegram_surface_state \
         20260731120000_conversation_copy_and_button_law \
         20260731150000_knowledge_gate_and_uniqueness \
         20260801095000_moments_missing_from_repo \
         20260801100000_one_moment_one_send \
         20260801120000_rescue_floor_and_silent_journey \
         20260801130000_the_enemy_is_not_a_time_of_day \
         20260801150000_revive_the_rhythm_gate \
         20260801170000_give_before_asking \
         20260801190000_the_exit_is_owed_until_shown \
         20260801200000_situation_other_is_not_grounding \
         20260801220000_three_countries_and_the_unknown \
         20260801230000_ask_the_59 \
         20260801240000_claim_the_country_ask \
         20260801250000_the_agent_speaks_under_law \
         20260803120000_one_call_per_node ; do
  psql -v ON_ERROR_STOP=1 -q -f supabase/migrations/$m.sql || break
done

for t in telegram_surface conversation_law knowledge_gate one_send \
         rhythm_gate give_before_asking country_state \
         agent_gate agent_bundle ; do
  psql -q -f supabase/tests/${t}_test.sql
done
```

**The order is the whole point.** Each migration replaces functions the earlier
ones defined, so loading a subset tests a schema that has never existed. Run the
list, not a favourite file from it.

Current: **21 + 27 + 25 + 34 + 14 + 29 + 71 + 27 + 19 assertions, zero failures.**

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

## `fixture_minimal.sql`

The columns `get_telegram_surface()` actually reads, and nothing else. Names and types are copied from the real migrations rather than invented, so a rename in production shows up here as a failure instead of passing quietly.

**It is deliberately not the full schema.** A fixture that tries to mirror everything drifts silently and then lies. This one covers one function, and its scope is checkable by reading it.

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
