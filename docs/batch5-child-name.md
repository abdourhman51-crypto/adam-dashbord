# Batch 5 — child name capture

**Goal:** the one missing fact that keeps `knowledge_depth()` at 0 and `get_rhythm_due()` silent.

## What was actually wrong

W2 **already had** a child-name path: `HW - Parse Memory → HW - Has Child Name? → HW - Write Child Name → rpc/write_child_name`. It had produced 3 children in the project's lifetime.

The diagnosis is not "the model never finds a name":

| | |
|---|---|
| Parents with `light_memory` | 133 |
| …carrying a `child_name` | **73** |
| …plausible as a name | **68** |
| Rows in `children` | **3** |

**The Heart Agent had been extracting names all along and none were being written.**

### The bug

`HW - Has Child Name?` tested `{{ $json.light_memory.child_name }}`. Its input comes from **`HW - Heart Commit`** — an HTTP node whose *response body* replaced `$json`. `light_memory` was never present, so the condition was always false and the true branch never ran. `HW - Write Child Name` read the same two fields from the same wrong node.

A classic n8n data-flow error: reading `$json` across an HTTP node instead of referencing the upstream parse node explicitly. The SDK reference names this exact case — *"if the current output no longer contains a field extracted earlier, read the earlier node directly."*

## The fix

1. Both nodes now read `$('HW - Parse Memory').item.json` explicitly.
2. `HW - Write Child Name` calls **`commit_child_name_by_platform`** instead of `write_child_name`, and uses the Supabase credential rather than a plaintext key header.
3. Backfilled the 68 names already sitting in `light_memory`.

## New SQL

| Function | Purpose |
|---|---|
| `child_name_plausible(text)` | Shape gate: 1–2 words, 2–24 chars, no digits/punctuation/Latin, not a relation word (`ابني`, `الطفلة`, `زوجي`, …) |
| `commit_child_name(uuid, …)` | The only sanctioned write. Requires `confidence='high'` and a plausible shape, fills a placeholder row rather than duplicating, and **never overwrites an existing plausible name** |
| `commit_child_name_by_platform(text, …)` | Resolver for W2's identifier |
| `get_child_name_batch(int)` | Built before the real cause was found. **Not wired** — the Heart Writer already covers this path. Kept because it is the honest fallback if the Heart branch is ever narrowed |

**Never overwriting is the important rule.** A later low-quality extraction may not replace a name ADAM already speaks back to the parent daily. Correcting a name is a conversation with the parent, not a background job.

`write_child_name` is marked DEPRECATED in its comment — no plausibility gate, no confidence requirement — and left in place so an unmigrated caller does not error.

## Effect, measured

| | before | after |
|---|---|---|
| `children` | 3 | **71** |
| Parents with a plausible name | 1 | **69** |
| `knowledge_depth() ≥ 1` | 1 | **70** |
| `get_situation_batch()` returns | ~1 | **70** |

`get_situation_batch()` only considers parents who already have a named child, so situation detection was starved by the same bug. It now has 70 families of work on W2's next two-hour run, and each confirmed situation makes a parent eligible for `get_rhythm_due()`.

**29/29 tests pass** (`supabase/tests/child_name_test.sql`) — the shape gate including every relation word, the commit rules, and a walk showing `knowledge_depth` move from 0 to 1 the moment a name lands.

## Outstanding

- `HW - Write Child Name` needs the **`adam Supabase`** credential attached in the UI, like the fifteen W1 nodes. The MCP cannot bind `supabaseApi` to `httpRequest`.
- `HW - Get Heart Batch` and `HW - Heart Commit` still carry the plaintext service key.
- `get_heart_batch()` filters `cohort='new' AND funnel_stage='free_conversation'` — 225 of 299 parents. The 63 `legacy` parents are excluded from memory *and* from name capture. Whether that is still wanted is a founder call.
