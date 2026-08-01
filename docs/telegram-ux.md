# ADAM — Telegram UX

**The UX layer** in the build order (`docs/adam-architecture.md` §1.5) — settled after the Engines, before Conversation.
**Derived from:** architecture §4 (Telegram Experience Engine), §4.5 (empty states), §4.7 (country), §6.5 (Value Ladder).

**Status:** applied to production 2026-07-31. Tested against a local fixture (12/12 + 9/9).

---

## 1. The rule this layer follows

> **The surface is derived, never stored.**

A parent's Telegram surface is four things at once — the pinned message, the five-item menu with its one changing entry, the three-key reply keyboard, and the progress line. Each is a statement about what ADAM currently knows.

They are computed **together, in one function**, because they must agree. A pinned message reading `نعمل على: النوم` above a menu item reading `ما الذي يمكن أن نعمل عليه؟` is not a cosmetic mismatch — it is the product contradicting itself about whether it knows this family.

This is the same argument that put `commerce_allowed()` in a single function. Five engines rendering the surface independently is five chances to disagree about it.

**Nothing is stored.** A stored pinned message is a second truth, and it goes stale in exactly the situation where being wrong hurts most: a parent returning after three weeks to a banner about last month.

---

## 2. The correction this layer makes to §4.5

Architecture §4.5 lists eight empty states in a flat table. A flat table reads as if a parent occupies exactly one of them. **Real parents do not.** A parent can be paused *and* still gathering. She can be in an unsupported country *and* mid-journey. She can be dormant *and* have a named child and a confirmed situation.

So the eight split into two kinds, and this split is the architectural content of the layer:

### State — exclusive, resolved by a ladder

What ADAM **knows**. Exactly one is true at a time.

| # | State | Condition | Meaning |
|---|---|---|---|
| 1 | `brand_new` | No child, ≤1 human message | Nothing is known |
| 2 | `no_child_name` | Messages exist, no child name | A relationship, no subject |
| 3 | `journey_active` | A live `stages` row | A named goal, being driven |
| 4 | `no_situation` | Child named, no situation | Known, but no recurring moment found |
| 5 | `gathering` | Situation known, <3 nights with a result | The picture is forming |
| 6 | `journey_ended_no_next` | A finished journey, none live | Between goals |
| 7 | `rhythm` | ≥3 nights with a result, never a journey | **Rung 2 complete** — free and fully known |

**`journey_active` is checked before `no_situation` and `gathering` on purpose.** A parent inside a paid journey has a named goal; telling her "نجمع الصورة" would be false, and false in a way she has paid not to hear.

### Modifiers — orthogonal, any combination

The parent's **circumstances**. Independent of state and of each other.

| Modifier | Source |
|---|---|
| `paused` | `checkin_state.paused_until` / `cadence = 'stopped'` |
| `dormant` | No message in 21+ days |
| `strain_level` | `parent_strain.level` — 1 / 2 / 3 (AD-2) |
| `commerce_allowed` | `commerce_allowed()` — the single answer |
| `country_state` | `country_state()` — `supported` / `unsupported` / `unknown` |
| `country_supported` | derived: `country_state = 'supported'`. Kept for one release only. |

**Unsupported country is a modifier, not a state.** §4.7 says the free experience is *"full, identical"*. A state would replace the others and make that sentence false. It changes exactly one thing: the changing menu item.

**And "we do not know" is not "we do not sell here."** The offer is live in exactly three countries — الجزائر، مصر، المغرب — but 59 of 301 parents carried `'ZZ'` or an empty country, and a boolean forced them into the unsupported answer. ADAM was stating a fact he did not have (P11). The third state asks instead, and the same answer also gives the daily rhythm a local clock, without which those families could never be written to at an honest hour.

---

## 3. The changing menu item

Four items are fixed forever. One moves. Stability is what makes the menu trustworthy; the single moving item is what makes ADAM feel like it is moving with the family (009).

**Modifiers outrank state**, because a paused or strained parent must not be offered a goal no matter how much ADAM knows about her child.

| Precedence | Condition | Label | `meaning` |
|---|---|---|---|
| 1 | `paused` | `كيف نعود؟` | `resume` |
| 2 | `commerce_allowed = false` | `أن نخفّف الحمل قليلاً` | `lighten_load` |
| 3 | Unsupported country, and state would name a goal | `أخبروني حين يصل آدم إلى بلدي` | `waitlist` |
| 4a | `journey_active` | `كيف تسير رحلة النوم؟` | `journey_progress` |
| 4b | `journey_ended_no_next` | `ما بعد النوم؟` | `next_goal` |
| 4c | everything else | `ما الذي يمكن أن نعمل عليه؟` | `open_question` |

**Precedence 2 is the one that matters.** A parent at strain level 2 — drowning but not in danger — previously received a menu inviting her to buy. Now she is offered relief, in a phrase that is not a task and not a purchase.

**`meaning` is the contract with Growth.** Telegram renders the label; Growth decides what tapping it does (§1.4, §6.5). The string is the seam between them, so neither has to read the other's code.

**No price appears in this output**, in any state, in any country, at any strain level. The removal test (§2.1): delete every price and the surface still works, because the changing item names a goal and the Menu is the door. If a price were needed here, the design would be wrong.

---

## 4. The progress line

| Condition | Line |
|---|---|
| Nothing logged | `لم نسجّل شيئاً بعد — نبدأ الليلة` |
| 1–2 nights | `نجمع الصورة — ليلتان حتى الآن` |
| Logged, but nothing this week | `الصورة محفوظة — لم نسجّل هذا الأسبوع` |
| Otherwise | `هذا الأسبوع: ٤ من ٧ أهدأ` |

> **The empty state is the honest state.** An empty chart or a 0% bar is the product pretending, and P11 forbids it. `نجمع الصورة — ليلتان حتى الآن` is better than a fake chart *and* truer.

**Arabic counts in four shapes, not two.** `ar_nights()` covers none / singular / dual / paucal (3–10) / plural (11+). `٢ ليالٍ` is the kind of error a parent reads as carelessness about her own week. Numerals are rendered Arabic-Indic by `ar_digits()` — she reads Arabic; the numbers in her pinned message should be Arabic too.

---

## 5. The pinned message

```
📌  يوسف · نعمل على: النوم
    هذا الأسبوع: ٤ من ٧ أهدأ

    القائمة ☰ فيها كل ما يمكن أن نفعله معاً.
```

Three lines, always. Line 1 is identity, line 2 is the progress line, line 3 points at the menu — **never at a price**.

**With no child name there is no placeholder.** The banner reads `📌 نبني الصورة معاً`. A placeholder like `طفلك` tells a parent that ADAM is filling a blank where her child should be.

**Updated silently, never re-pinned as a notification** (§4.4). Re-pinning is a notification the parent did not ask for, dressed as state.

---

## 6. Navigation

Two axes, no deeper nesting (§4.6):

| Axis | Mechanism | Depth |
|---|---|---|
| Doing | Reply keyboard + inline buttons | **Zero** taps from the conversation |
| Understanding | Menu → one screen | **One**, never a submenu inside a submenu |

Reply keyboard, three entries, never more:

```
┌──────────────────┬──────────────────┬──────────────────┐
│   ما حدث الآن     │    كيف نتقدّم     │      القائمة ☰    │
└──────────────────┴──────────────────┴──────────────────┘
```

**Hard rule: no screen is more than one tap from the conversation.** There is no back button in a bot to rescue a parent who feels lost.

---

## 7. What is built, and what is not

| | |
|---|---|
| **Written** | `get_telegram_surface(uuid)`, `ar_digits(text)`, `ar_nights(integer)`, `situation_label_ar(text)` |
| **Tested** | Against a local Postgres 16 fixture — 12 parents covering all 7 states plus paused, strain L2, unsupported country, dormant, and a nonexistent parent. **12/12 state assertions and 9/9 hard guarantees pass.** See `supabase/tests/` |
| **Applied** | Live in production since 2026-07-31 |

**The test caught a real bug.** `text[] || 'literal'` resolves to array concatenation, and Postgres then tries to parse the Arabic literal as an array — every call raised `malformed array literal`. The function would have failed on **every parent, in every state**. An explicit `::text` cast fixes it, and the cast now carries a comment saying why.

That is the argument for the fixture existing at all. Until now every SQL object in this project was validated by running it against the live database and rolling back, which cannot happen before a change is applied — only after, and only when the connector is up.

**Before this is relied on in production:** apply the migration, then re-run the same twelve cases against real parents. Production is Postgres 17.6 against the fixture's 16; nothing used here differs between them, but the run is cheap and the function is `stable` and read-only, so it cannot damage data.

### Deliberately not built here

| Not built | Why |
|---|---|
| The copy for each menu tap | Conversation layer, which comes next |
| Deep-link parameter handling | Needs the Instagram link scheme, a Growth decision |
| Voice-note and reaction handling | Input, not surface. Conversation layer |
| Message-settings and privacy screens | Two fixed menu items whose contents are the Conversation layer's |

---

## 8. Open item this layer surfaced

**Three migrations in the repo are documentation stubs, not SQL.** `20260730175200_rhythm_write_side.sql`, `20260730180000_situation_catalog_and_detection.sql`, and `20260730183000_strain_detection_and_graded_return.sql` contain only header comments — their function bodies were applied directly through the Supabase connector and exist **only in the live database**.

A rebuild from `supabase/migrations/` would produce a database with no `record_seed_sent`, no `commit_situation`, and no `set_strain_level`. The repo is not currently a complete description of the schema.

**Fix:** dump the four function bodies from `pg_get_functiondef` and backfill the three files. This needs the Supabase connector, so it is blocked alongside §7.
