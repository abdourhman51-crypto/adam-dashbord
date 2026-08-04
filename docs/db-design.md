# ADAM — Database Design

**Layer 3 of 12** in the build order (`docs/adam-architecture.md` §1.5).
**Derived from:** the architecture. Nothing here is invented; every table exists because a specific engine needs it to do something the architecture requires.

**Status:** core schema applied. Remaining layers not started.

---

## 1. The rule this layer follows

> **The schema is derived from what the conversation must be able to say.**

Building the database first forces the product to fit the schema. So each table below is justified by a sentence ADAM must be able to produce, or an invariant the architecture declares.

**Everything is enforced in the data where it can be.** The project has learned this the hard way twice: `message_count` sat frozen at 0 because a counter was a convention rather than a derivation, and `safe_for_record` needed a transaction-bound audit row because a prompt-level rule is not a rule.

---

## 2. Where the existing schema already fits

The production database is not replaced. It is evolved, because it is serving parents right now — 4,306 conversations, 296 parents, and three live workflows writing to it.

| Architecture entity | Existing table | Verdict |
|---|---|---|
| **Parent** | `followers` | **Keep the physical name.** Three live workflows write to it. New tables reference it as `parent_id`, which is already the convention in `stages`, `mirrors`, `checkin_state` |
| **Child** | `children` | Fits as-is |
| **Pattern** | `child_patterns` | Fits, with the `safe_for_record` operator-only invariant intact |
| **Journey** | `stages` | Fits — `objective_text`, `objective_metric`, `objective_target`, `objective_window` are exactly the falsifiable-goal shape §0.6 requires |
| **Mirror** | `mirrors` | Fits |
| **Day** | `daily_logs` | **Evolves** — see §3 |
| Pricing | `supported_countries` | Fits |
| Timezones | `country_timezone` | Fits — 30 countries, IANA |

**No renames.** A rename of a live table buys vocabulary and costs an outage.

---

## 3. `daily_logs` becomes the Day

### Why evolve rather than replace

`daily_logs` already carries `UNIQUE (follower_id, log_date)` — which is exactly the *one Day per parent per local date* shape the architecture needs. It also holds the only real measurement history that exists.

### What that history actually contains

| Rows | Content |
|---|---|
| **23** | **No result at all** — no `night_result`, no `hard_moment`, no `step_status` |
| 1 | `normal` / `tried_failed` |
| 1 | `hard` / `other` / `done` |

> **The measurement spine has two real data points in its entire history.** The Seed→Harvest pair is not replacing something that works. It is replacing something that has never worked, and the schema should say why: there was no structural link between what ADAM suggested and what it later asked about, so most evenings produced a message and no answer.

### The shape added

| Column | Purpose |
|---|---|
| `source` | `legacy` \| `rhythm` — legacy rows predate the pair and are exempt from its invariants |
| `journey_id` | Null for free days. Set when the day serves a goal |
| `situation_id` | Which recurring situation this day aims at |
| `seed_text` | What was suggested this morning |
| `seed_grounded_on` | **The Knowledge it was derived from.** Not decorative — see below |
| `seed_scheduled_for` / `seed_sent_at` | Timing per §5.4 |
| `harvest_sent_at` / `harvest_answered_at` | The evening half |

### The three invariants, enforced in the table

| Invariant | Mechanism | Architecture |
|---|---|---|
| **A Seed records the Knowledge it came from** | `chk_seed_grounded` — a sent rhythm Seed must have a non-empty `seed_grounded_on` | §8.2, P11 |
| **No Harvest without a Seed** | `chk_harvest_needs_seed` — a rhythm row may not carry an outcome unless a Seed was sent | §5.3 |
| **One Seed and one Harvest per day** | The pre-existing `UNIQUE (follower_id, log_date)` | §5.4 rule 4 |

**`seed_grounded_on` is the enforcement point for P11.** An ungrounded Seed cannot be recorded, so "the Seed became a tip library" (risk R2) becomes a constraint violation rather than a thing we notice later in a sample.

**Legacy rows are exempt by `source`**, not by weakening the constraint. The live workflow keeps writing as it does; nothing breaks.

---

## 4. New tables

### `situations` — the recurring hard moment, with its window

**Required by:** §5.4, which schedules the Seed *before* the situation and the Harvest *after* it. That is impossible without knowing when the situation happens.

`child_patterns` is not this. A pattern is a correlation ADAM noticed; a situation is a recurring moment in the day with a clock. The timing model needs the second.

Seeded with the six known situations from the live `hard_moment` taxonomy, each with the window from §5.4.

### `aha_moments` — the conversion signal, instrumented

**Required by:** §3.8.9 and experiments E10–E12, which test whether understanding drives revenue. Without a row per moment there is nothing to correlate and §0.2 stays an opinion.

| Field | Why |
|---|---|
| `kind` | `A1`–`A6` |
| `moment_class` | `free_value` \| `hinge` \| `premium` — the three classes predict **different** outcomes (§6.4) |
| `first_occurrence` | The first is the moment; the rest are the standard (§3.8.6) |

**`uq_aha_first_per_kind`** — a partial unique index guaranteeing at most one first occurrence per parent per kind. The distinction between creating a feeling and sustaining it is structural, not a reporting convention.

**`moment_class` is derived from `kind` by a trigger**, not passed in. A caller cannot mislabel A5 as `free_value` and quietly move the free/paid boundary.

### `parent_strain` — three levels with a graded return

**Required by:** AD-2 and §8. L2 is the level that matters: a parent drowning but not in danger previously received cheerful morning suggestions and a menu inviting them to buy.

`return_eligible_at` makes the graded return a stored fact rather than something each engine recomputes. **Five engines each deciding independently when a parent has recovered is five chances to get it wrong.**

---

## 5. The Knowledge gate

**Required by:** §2.5 — the Seed refuses to send unless it can be grounded.

`can_ground_seed(parent_id)` returns what is known, what is missing, and whether a Seed may be composed. It is **tier-1 SQL** per §2.2: the decision is deterministic and must give the same answer twice, so it is not an LLM's to make.

```
{ "can_ground": true,
  "child_id": "…", "child_name": "يوسف",
  "basis": ["situation", "prior_outcome"],
  "missing": [] }
```

**Grounding requires:** a child name **and** at least one of a situation, a prior outcome, or a pattern.

When it returns false the correct behaviour is **silence, not a generic Seed** — which is why the function returns `missing`, so the caller can ask the one question that would unblock it (§9.3) rather than guessing.

---

## 6. What is deliberately not built yet

| Not built | Why |
|---|---|
| Gender three-form message variants | Content, not schema. Belongs to the Conversation Engine layer (layer 5) |
| Journey generation state | Belongs to the Journey Engine layer; `stages` already holds the goal shape |
| Review-session records | Derived from journey + days at read time. Storing it would create a second truth |
| Aha delivery mechanics | Layer 5. This layer only provides the ledger |

**Nothing here anticipates a layer that has not started.** Speculative columns are how schemas rot.

---

## 7. Migrations in this layer

| File | Contents |
|---|---|
| `…_db_core_day_situation.sql` | `situations`, the Day evolution, the three invariants |
| `…_db_knowledge_gate.sql` | `can_ground_seed()` |
| `…_db_aha_and_strain.sql` | `aha_moments`, `parent_strain`, class-derivation trigger |

All new tables are RLS-enabled and service-role only from birth — no repeat of the Week-0 exposure, where 17 permissive policies left 4,174 parent conversations readable by the anon key.
