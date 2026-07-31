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
psql -v ON_ERROR_STOP=1 -f supabase/migrations/20260731090000_telegram_surface_state.sql
psql -v ON_ERROR_STOP=1 -f supabase/migrations/20260731120000_conversation_copy_and_button_law.sql
psql -v ON_ERROR_STOP=1 -f supabase/migrations/20260731150000_knowledge_gate_and_uniqueness.sql
psql -f supabase/tests/telegram_surface_test.sql
psql -f supabase/tests/conversation_law_test.sql
psql -f supabase/tests/knowledge_gate_test.sql
```

Current: **21 + 37 + 25 assertions, zero failures.**

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
