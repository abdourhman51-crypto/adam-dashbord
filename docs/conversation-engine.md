# ADAM — Conversation

**The Conversation layer** in the build order (`docs/adam-architecture.md` §1.5) — settled after UX, before Knowledge.
**Derived from:** architecture §3 (Conversation Engine), §9 (flows), §0.7 (voice and the two lexicons), §6.6–6.7.

**Status:** applied to production 2026-07-31. Tested against a local fixture — **27/27**.

---

## 1. The rule this layer follows

> **A style guide that lives only in a document holds until someone is in a hurry.**

§0.7 bans thirteen machinery words and seven promotional verbs from every user-facing string. §3.1 requires `شيء آخر` on every button set. §9.6 requires a crisis message to carry *no* buttons at all. Until this layer, all of that was prose.

This project has twice learned what prose is worth. `message_count` sat frozen at 0 because a counter was a convention rather than a derivation. `safe_for_record` needed a transaction-bound audit row because a prompt-level rule is not a rule.

So the law becomes **CHECK constraints on a table**. The word `اشتراك` in a live message is now a constraint violation at write time, rather than something a parent finds first.

---

## 2. One rule, both tiers

Moments come in two tiers:

| Tier | Who writes it | Examples |
|---|---|---|
| `fixed` | Stored verbatim from §9 | first contact, the three Harvest replies, strain L2/L3, referral, waitlist |
| `composed` | The LLM writes it at send time | rescue, Seed, the goal becoming visible, most menu taps |

**The same function governs both.** `copy_violations()` is called by the CHECK constraint on stored copy *and* by `validate_outgoing()` on whatever the LLM just produced. That is the whole point of it being a function rather than a constraint expression: generated text is held to the standard stored text is held to, and there is exactly one standard.

```
validate_outgoing('rescue', 'افتح الرحلة الآن')
  → {"ok": false, "reason": "vocabulary", "violations": ["promotional:افتح"]}

validate_outgoing('rescue', 'الرحلة بـ 2300 دينار')
  → {"ok": false, "violations": ["price:currency:دينار", "price:digits"]}
```

**A failure is a message not sent** — not a message sent with a warning logged.

---

## 3. What the law actually forbids

| Class | Caught | Constitution |
|---|---|---|
| Machinery | `ذاكرة` `تقارير` `متابعة` `خطة` `ذكاء` `اشتراك` `ميزات` `نظام` `تحليل` `دفتر` `أتمتة` `تتبّع` | §0.7 |
| Promotional register | `افتح` `فعّل` `اشترك` `احصل على` `جرّب الآن` `النسخة الكاملة` `الباقة` | P21 |
| Internal lexicon | `احتواء` `محرّك`, and `seed` `harvest` `engine` `journey` `mirror` `funnel` `tier` `aha` `llm` in Latin | §0.7 hard rule |
| Price | Any 3+ digit run in either numeral system; `دينار` `جنيه` `درهم` `ريال` | P17, §2.1 |

### Two deliberate choices in how matching works

**Substring, not word boundary.** Arabic attaches `ال و ب ل` as prefixes. `\y` would catch `اشتراك` and let `الاشتراك` through — the opposite of useful. Tested: case 6 confirms the prefixed form is still caught.

**`دج` was dropped from the currency list.** It is the Algerian short form, but `دجاج` is a word that will appear in a conversation about dinner. The digit rule catches every real price display anyway, since prices are three digits or more. Tested: case 14.

The bans are also tested for **overreach**, which matters as much as reach — a law that blocks approved copy gets switched off:

| Approved string | Nearly caught by | Result |
|---|---|---|
| `هذه خطوة حقيقية` | `خطة` | survives |
| `كل ما يمكن أن نفعله معاً` | `فعّل` | survives |
| `رفض الدجاج على العشاء` | `دج` | survives |
| `خمس ليالٍ هادئة من سبع` | price digits | survives — approved copy writes small counts as words |

---

## 4. The button law

| Rule | Constraint | Why |
|---|---|---|
| `شيء آخر` on every button set | `chk_escape_hatch` | A button set without an escape is an interrogation (§3.1) |
| Crisis carries **no** buttons, not even `شيء آخر` | `chk_crisis_has_no_buttons` | §9.6 |
| Button labels obey §0.7 | `chk_buttons_wellformed` | A label is a user-facing string |
| Every button has a label and a callback | `chk_buttons_wellformed` | A button that does nothing is a broken promise |

**`buttons_forbidden` exists so the absence is deliberate.** §9.6 is the single place in the product where a button set is absent, and it is the kind of thing a future contributor helpfully "fixes" to satisfy Decision 014. The column, its constraint, and its comment all say not to. Offering a parent who has just disclosed violence a set of options turns a moment of being heard into a form to complete.

---

## 5. The line budget

P6 allows three content lines. Blank lines are spacing and are not counted — §9's approved messages breathe, and should not be punished for it.

**The exceptions are named, not available.** `chk_line_budget` permits `max_lines > 3` only for `goal`, `review`, and `crisis` — the three places the architecture itself shows a longer message. A rescue reply can never quietly grow into an essay, because raising its own budget is a constraint violation.

---

## 6. The commerce gate

`get_conversation_moment(key, parent_id)` **refuses** a commercial moment the parent may not receive:

```
get_conversation_moment('goal_visible', <parent at strain L2>)
  → {"found": true, "allowed": false, "reason": "commerce_blocked"}
```

It returns a refusal rather than returning the moment and trusting the caller to check. Every engine that forgets a guard is a guard that does not exist — the same argument that made `commerce_allowed()` a single function.

**Crisis is exempt in the other direction**: `chk_crisis_not_commercial` forbids a crisis moment from ever being commerce-gated, so a parent in danger cannot be silenced by a commerce rule.

---

## 7. The UX contract is closed

The UX layer's changing menu item emits a `meaning` string. Every value it can emit now has a moment, and the test asserts it — otherwise a parent taps the menu and ADAM has nothing to say.

| `meaning` | Moment | Tier |
|---|---|---|
| `open_question` | `menu_open_question` | composed |
| `journey_progress` | `menu_journey_progress` | composed |
| `next_goal` | `menu_next_goal` | composed |
| `resume` | `menu_resume` | fixed |
| `lighten_load` | `menu_lighten_load` | composed |
| `waitlist` | `menu_waitlist` | fixed |

Plus the four fixed items: `menu_child`, `menu_progress`, `menu_settings`, `menu_privacy`.

**`menu_lighten_load` is composed on purpose.** What would actually lighten the load depends on what the parent said. A fixed string here would be a stock phrase handed to someone at their worst, and nothing in it may read as a task.

**`menu_resume` is fixed on purpose.** There is no "we miss you" (§4.5), and `نبقى كما نحن` is a first-class answer, so the wording is not something to improvise.

---

## 8. What is deliberately not built here

| Not built | Why |
|---|---|
| The three gender-rendered forms | The gender-free default is primary (§0.7). Rendering masculine/feminine variants needs a known gender, which is Knowledge's to supply |
| Interpolation of child name and experiment | Send-time, in n8n. The moment stores the shape |
| Voice-note transcription handling | Input path, not copy |
| L3 category-specific lines and referral directory | Blocked on §16 D2 — the vetted, country-specific list is founder-owned. **ADAM must never invent a helpline**, so the absence is honest rather than filled |
| Aha moment delivery copy | The ledger exists; the moments are composed inside `rescue`/`goal_visible` and instrumented, not separate strings |

---

## 9. Running the tests

```bash
psql -f supabase/tests/fixture_minimal.sql
psql -f supabase/migrations/20260731090000_telegram_surface_state.sql
psql -f supabase/migrations/20260731120000_conversation_copy_and_button_law.sql
psql -f supabase/tests/conversation_law_test.sql
```

27 cases, each one an attempt to store something the constitution forbids, plus the overreach checks and the contract closure. **A rule you have never seen reject anything is a rule you are hoping for.**
