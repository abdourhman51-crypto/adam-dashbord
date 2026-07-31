# ADAM — Knowledge

**The Knowledge layer** in the build order (`docs/adam-architecture.md` §1.5) — settled after Conversation, before Database.
**Derived from:** architecture §2 in full.

**Status:** designed, written, tested against a local fixture — **25/25**. `20260731150000_knowledge_gate_and_uniqueness.sql` is **not yet applied to production**.

---

## 1. Why this layer carries the most weight

§0.2 names it plainly:

> **This is the conversion engine.** Not Growth, which only makes a next step visible. **If revenue is weak, this is where the work is.**

Three things in §2 were prose until now. One of them — §2.6 — is the test the architecture names for *every* proactive message, and it had never been implemented. **A test nobody runs is a paragraph.**

---

## 2. §2.6 made mechanical

> **Could this exact message be sent to a different family? If yes, it does not send.**

`passes_uniqueness_test(parent_id, body)` answers it by asking whether the message contains anything only true of this family. `family_tokens()` supplies those facts in **two classes**, and the distinction is the whole point:

| Class | What it is | Earned? |
|---|---|---|
| `identity` | The child's name | No — supplied |
| `measured` | A situation ADAM detected · a step that worked **for this child** · a pattern cleared for the record | Yes |

**A proactive message must carry at least one `measured` token. The name alone is never enough.**

That rule exists because of a specific failure mode. A generic parenting tip with a name substituted into it passes a naive uniqueness check and fails the real one — it is risk **R2**, *"the Seed became a tip library"*. So the function reports it distinctly:

```
passes_uniqueness_test(p, 'الأطفال يحتاجون روتيناً ثابتاً قبل النوم.')
  → {"passes": false, "reason": "generic"}

passes_uniqueness_test(p, 'يوسف يحتاج روتيناً ثابتاً قبل النوم.')
  → {"passes": false, "reason": "identity_only"}          ← R2, caught

passes_uniqueness_test(p, 'تجربة التنبيه قبل الانتقال نجحت مع يوسف — نبني عليها.')
  → {"passes": true, "matched_measured": ["تنبيه قبل الانتقال"]}
```

**It returns why, not just whether.** A caller that gets `false` with no reason logs a mystery.

### Tested across two families, because that is what the test says

Cases 24–25 build a second family and send family A's message to family B:

| | |
|---|---|
| Family A's message, family A | passes |
| **The same message, family B** | **fails** |

That is §2.6 stated exactly, and it is the only way to test it — a single-family test cannot express a cross-family rule.

---

## 3. §2.8 — provenance, not content filtering

> Proactive messages draw only on what ADAM **authored or measured** — never on what the parent **disclosed**.

`family_tokens()` never reads `n8n_chat_histories` or `memory_events`. Not "filters them" — **never reads them**. Filtering Arabic free text cannot be done safely, and two live rows settled the argument: a child-assault disclosure, and the pattern label `التنقل بين ثلاث عائلات`, which reveals family separation. Neither is distinguishable from a safe label by pattern matching.

The tests use that exact live label:

| Case | Result |
|---|---|
| The disclosure never becomes a family token | 16 ✓ |
| A message quoting it does not send | 17 ✓ |
| The same label **does** count once `safe_for_record` is explicitly set | 18 ✓ |

Case 18 is the one worth keeping. `safe_for_record` is the only thing that changes between 16 and 18 — which is what makes it a gate rather than decoration.

---

## 4. §2.4 — capability grows, and the constraint is real

`knowledge_depth(parent_id)` computes what is known and what that makes possible.

| Level | Known | Now possible |
|---|---|---|
| 0 | Nothing | Answer this moment, fully and well |
| 1 | The child's name | Speak about *يوسف*, not "your child" |
| 2 | A recurring situation | Aim a Seed at what keeps failing |
| 3 | Three logged evenings | Notice a pattern the parent had not seen |
| 4 | A month of outcomes | **Name a goal worth pursuing** |

> **This is the honest reason a journey becomes possible only later.** Not a gate, not a trial expiring: ADAM genuinely could not have named a real goal in week one.

**It is computed rather than asserted, which is what keeps it honest.** If level 4 were a flag someone could set, the constraint would stop being real and would start reading as a tactic. Tests 1–11 walk one family from level 0 to level 4 fact by fact and watch it rise.

**The parent never sees this table and is never told what is locked** (§2.4). It exists so the composer knows what it may attempt.

---

## 5. §2.5 — the send gate, five kinds, one answer

`can_ground_seed()` already covered the Seed. The other four rows lived in whichever workflow remembered them — the same shape of bug as five engines each deciding when a parent has recovered.

| Kind | Refuses when |
|---|---|
| `seed` | Not grounded (delegates to `can_ground_seed`) |
| `harvest` | No Seed today, or a Harvest already went out |
| `mirror` | Fewer than three results |
| `journey_step` | No live journey, no objective, or no outcome yet — the journey **pauses and the parent is told plainly** |
| `rescue` | **Never** |

**The rescue returns `true` before anything else is read** — no strain check, no knowledge check, no pause check. Everything proactive earns the right to interrupt by being specific; the rescue does not have to earn anything.

**An unknown kind refuses** (case 23) rather than defaulting open. A gate whose default is "yes" for anything it does not recognise is not a gate.

---

## 6. What is deliberately not built here

| Not built | Why |
|---|---|
| Tier-1 context assembly for injection | The tokens and depth exist; the injection payload is shaped by what the composer needs, and that is the n8n layer's to specify |
| An `is_disclosure()` classifier | §2.8 is provenance by design. Adding a content classifier would reintroduce exactly the approach two live rows proved unsafe |
| Automatic `safe_for_record` promotion | The migration comment is explicit: never default it true, and never let an LLM set it |
| Age-aware knowledge | `children.age_note` is free text on live rows; normalising it is a data-quality task, not a schema one |

---

## 7. A note on the fixture

`fixture_minimal.sql` now reimplements `can_ground_seed()` rather than loading the real migration, because the real one lives in a file this fixture does not load. **The reimplementation follows the same contract** — a child name AND one of situation / prior outcome / pattern — and is marked as a reimplementation in the file.

This is a real limitation, and it is worth naming: if production's `can_ground_seed()` drifts from that contract, these tests will not notice. It is the same class of gap as §8 of `docs/telegram-ux.md`, and it closes the same way — by backfilling the three stub migrations once the Supabase connector is available.

---

## 8. Running the tests

```bash
psql -f supabase/tests/fixture_minimal.sql
psql -f supabase/migrations/20260731150000_knowledge_gate_and_uniqueness.sql
psql -f supabase/tests/knowledge_gate_test.sql
```

25 cases: one family walked from knowing nothing to a month of outcomes, then the uniqueness test, the provenance rule, and the five send gates — plus a second family, because §2.6 is a cross-family rule and cannot be tested with one.
