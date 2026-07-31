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
psql -f supabase/tests/telegram_surface_test.sql
```

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

Everything runs inside a transaction and rolls back.
