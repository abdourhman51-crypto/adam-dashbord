# ADAM — Experience Principles, and a review against them

**Status:** E1–E13 are a proposal. **Part 4 items 1–3 are applied** (2026-07-31); the rest is not. Part 2 is candidate constitution text; Part 3 reviews live behaviour and criticises work shipped hours ago, including my own.

---

# Part 1 — What actually transfers

Ten products were studied. Most of what they teach does **not** transfer, and saying which is the useful half of the research.

## 1.1 The convergent finding

Across ChatGPT, Claude, WhatsApp, Linear, and Telegram itself, one thing recurs and it is not a UI pattern:

> **The best products in this category reduce the interface to a single object and defer everything else to it.**

ChatGPT and Claude ship an empty text field. No tour, no wizard, no feature list — the product's entire surface is the thing you came to do. WhatsApp has no "features" screen; the message list *is* the app. Linear's opinionated defaults exist so you never open settings. Apple's HIG calls this **deference**: the interface recedes so content leads.

**ADAM's single object is the conversation.** Everything else — keyboard, menu, pinned banner — is chrome that must earn its place against that.

## 1.2 What does not transfer, and why

| Product | Tempting to copy | Why it must not be copied |
|---|---|---|
| **Duolingo** | Streaks, XP, hearts, daily goals | Built for a *voluntary* activity where guilt is a usable lever. ADAM's user already feels she is failing. A broken streak on a night her child was ill is a punishment for parenting. **Streaks are banned.** |
| **Discord** | Presence, channels, rich chrome | High-chrome, high-attention, built for people who *want* to be in the app. Direct opposite of an exhausted parent. |
| **Notion** | Configurability, blocks, templates | Power through composition assumes appetite for learning. Our user has none. Notion's transferable idea is **progressive disclosure**, not its surface. |
| **Hooked** | Variable reward | Variable reward is only ethical here when the variance is *real* — a child's night genuinely varies. Manufacturing variance (random praise, surprise rewards) is manipulation. **Reality supplies the variance; we never add any.** |
| **Endowed Progress Effect** | Pre-filled progress to boost completion | Requires showing progress that did not happen. Directly violates P11 (honesty). **Rejected outright**, and named here so nobody proposes it later. |
| **Material Design** | Motion, elevation, ripples | No surface to apply it to. Telegram renders our messages. |

## 1.3 The behavioural science that does apply

**Fogg's B = MAP.** Behaviour needs Motivation × Ability × Prompt. At 23:00 after shouting, **motivation is at its maximum and ability is at its floor**. Every product that fails this user fails by designing for motivation — more features, more options, more to configure. *The entire design budget must go to Ability.*

**Cognitive Load Theory (Sweller).** Intrinsic load (her child's problem) is already at capacity. Every button, every choice, every unexplained word is extraneous load competing with the thing she came for. Extraneous load is not "a bit of friction" — it is *displacing* the problem she needs to think about.

**Hick's Law.** Decision time rises with the number of options. Cowan's revision of Miller puts real working-memory capacity near four items, and lower under stress. **Three options is the ceiling; two is better.**

**Peak-End Rule (Kahneman).** An experience is remembered by its most intense moment and its ending — not its average. ADAM's *end* is the evening Harvest reply. That is the most memorable moment of the day.

**Zeigarnik Effect.** Open loops are remembered. The Seed's closing line — *"مساءً نتكلم عنها"* — is a legitimate open loop: it is about her child, not about the product. This is the ethical form.

**Goal Gradient.** Effort rises near a visible goal. Requires showing *movement*, not a static ratio.

**Calm Technology (Weiser & Brown).** Technology should inform from the periphery and move to the centre only when it must. The pinned message is periphery. A notification is centre. **Confusing the two is the most common way a companion becomes a nuisance.**

---

# Part 2 — Adam Experience Principles

Candidate constitution. Each principle carries the evidence it rests on and **the test that would prove it violated** — a principle you cannot fail is decoration.

### E1 — The first screen holds one thing to read and one thing to do
Five seconds is enough for a sentence and a decision, not for a product. *HIG deference; Hick.*
**Fails when:** first contact produces more than one message, or offers more than one action.

### E2 — No affordance appears before it has content
A button that answers "nothing yet" teaches that the button is useless, and she will not press it later when it works. *Progressive disclosure; empty-state theory.*
**Fails when:** any control is visible in a state where tapping it returns an empty or apologetic answer.

### E3 — Design for ability, never for motivation
Her motivation is already maximal; her capacity is not. Every design choice spends from an empty account. *Fogg B=MAP.*
**Fails when:** a change adds a step, a field, or a decision in exchange for better data.

### E4 — Every message carries value or is not sent
A message whose content is its own title is chrome. *Sweller; §3.3 (P22).*
**Fails when:** any message could be deleted without the parent losing information.

### E5 — A notification is earned, not owed
Periphery informs; centre interrupts. Status changes belong to the periphery. *Calm Technology.*
**Fails when:** anything that is not addressed to her personally produces a notification.

### E6 — Presence is shown before an answer is ready
Silence after she has just written the hardest thing in her week reads as abandonment or breakage. *Emotional design, visceral layer; every major chat product.*
**Fails when:** more than ~2s pass between her message and any sign of life.

### E7 — The ending is designed, because the ending is what is remembered
*Peak-End.*
**Fails when:** the last message of a day is identical to the last message of every other day.

### E8 — Open loops are about her child, never about the product
"We'll talk this evening" is legitimate. "Come back to see what you unlocked" is not. *Zeigarnik, ethical subset.*
**Fails when:** a loop's payoff is a product event rather than a fact about her family.

### E9 — Never show progress that did not happen
No head starts, no rounded-up numbers, no streaks. *Endowed Progress rejected; P11.*
**Fails when:** any displayed number is not directly derivable from what she actually logged.

### E10 — The product never explains itself
If she must ask "how does ADAM work?", the design failed. Capability is discovered by being used, not announced. *§2.7, P24.*
**Fails when:** any string describes the product's own mechanics.

### E11 — A good default replaces a setting
*Linear; every settings screen is a decision the designer refused to make.*
**Fails when:** she is asked to choose something ADAM could have inferred or safely assumed.

### E12 — She never senses a mode
Strain levels, tiers, cohorts, funnel stages — none may surface as a perceptible change in ADAM's manner. *§0.7 two lexicons.*
**Fails when:** two parents in different internal states could tell they are being treated differently.

### E13 — Guilt is never a mechanism
Not for retention, not for re-engagement, not for logging. This user arrives already ashamed. *§0.8; the deliberate rejection of Duolingo's core loop.*
**Fails when:** any message would read worse to a parent who has just had a terrible week.

---

# Part 3 — Review of what is live

Walked as a parent seeing ADAM for the first time, against E1–E13.

### F1 — First contact fires three chat events · **violates E1, E4, E5**

`Send First Contact → Send Pinned → Pin It`. She types `/start` and receives a greeting, then a second message that is a status banner, then Telegram's own "message pinned" service event. **Three events, two of them about the product rather than her.**

Worse, the banner at t=0 reads:

```
📌 نبني الصورة معاً
لم نسجّل شيئاً بعد — نبدأ الليلة
```

Her first impression of ADAM is an empty dashboard. The honest empty state is right in principle (P11) and wrong as a *first* impression — it is honest about a relationship that has not started.

**Fix:** `/start` sends the greeting and nothing else. The pinned message is created on the first event that gives it content — a named child or a first logged evening.

### F2 — The reply keyboard is the one part of the surface that is not derived · **violates E2**

`get_telegram_surface()` derives the state, the menu, the changing item, the pinned text, the progress line — and then returns a **hardcoded three-key keyboard** identical in every state. I built the whole function on the argument that the surfaces must agree, and then exempted the keyboard from it.

At `brand_new`, `كيف نتقدّم` answers *"لم نسجّل شيئاً بعد"*. She learns the key is empty, and that lesson persists after it stops being true.

**Fix:** the keyboard grows with state — one key at `brand_new`, two once a child is named, three once anything is logged. Same derivation as everything else.

### F3 — The menu message says nothing · **violates E4**

`Menu - Send` sends the text `القائمة ☰` with five buttons under it. A message whose entire body is its own title, in a product where "every turn must add value."

**Fix:** the menu body *is* the pinned content — child · situation · progress — with the options beneath. Opening the menu then informs before anything is tapped.

### F4 — The pinned message is derived but never refreshed · **violates E9, and it is a live defect**

It is written once, at `/start`. Nothing calls `editMessageText` afterwards. For every parent it will show *"لم نسجّل شيئاً بعد"* permanently, regardless of what they log.

I built the derivation and not the refresh, and the doc claims the pin "cannot go stale" — **it currently always is.** A permanently wrong banner is worse than no banner.

**Fix:** store the pinned `message_id`, and `editMessageText` it after every Harvest answer and every situation confirmation. Silent edit, no re-pin.

### F5 — No typing indicator · **violates E6** · highest value per unit of work in this document

She writes *"انا بضرب"* at 23:00 and gets silence for several seconds while the model composes. Every product she uses daily — WhatsApp, Messenger, ChatGPT — shows presence within milliseconds.

`sendChatAction: typing` is **one API call with no state**, before the agent node. It is the cheapest warmth in the product and it is absent.

### F6 — The end of the day is the most generic text in the product · **violates E7**

Peak-End says the Harvest reply is the most memorable message ADAM sends. It is currently one of three fixed strings, byte-identical every night forever:

```
هذه خطوة حقيقية.
نبني عليها غداً.
```

The nightly peak is a constant. **The one place personalisation is worth its cost is the one place it is absent.**

**Fix:** the Harvest reply is the correct place to spend an LLM call — grounded, and it must pass `passes_uniqueness_test()`. Nights 1 and 7 should not read the same.

### F7 — Telegram's native command menu is empty · **violates E11**

No `setMyCommands`. The ☰ beside the input — the affordance every Telegram user already knows — is blank. A parent who scrolls away has no native way back.

**Fix:** register two commands, no more. `/menu` and `/privacy`.

### F8 — Progress is a ratio, not a gradient · **weakens E7, forgoes Goal Gradient**

`هذا الأسبوع: ٤ من ٦ أهدأ` states a fact and shows no movement. Goal-gradient needs direction. `ليلتان أهدأ من الأسبوع الماضي` is derivable from data we already hold, and is a different sentence emotionally.

Only shown when true, and never inverted into bad news unprompted (E13).

### F9 — «شيء آخر» — the right instinct, argued from the wrong mechanism · **challenges §3.1 / Decision 014**

This is a Constitution rule and a `CHECK` constraint I wrote hours ago, so I am raising it rather than changing it.

The stated reasoning: *"a button set without an escape is an interrogation."* The feeling is real. The mechanism is not — **in Telegram the text input never disappears.** Inline buttons do not block typing. The escape hatch exists structurally, always, whether or not we draw it.

What the button actually costs: one extra option on every set (Hick), and a subtle inversion — it implies the listed options are the expected answers and free text is the exception, which is the opposite of what we want her to believe.

What actually produces the feeling of not being interrogated: ADAM answering off-script text *well*, never using `force_reply`, never removing the keyboard, and asking at most one question at a time.

**Recommendation — founder decision:** keep the constraint where a set could be read as a form (the Harvest's four options), drop it where the message already invites open speech. I am not touching it unilaterally; it is Constitution text.

### What is working, and should not be touched

- **The Seed's closing line** is a textbook ethical Zeigarnik loop — E8 exactly.
- **Refusing to send an ungrounded Seed** is E9 enforced in the database rather than hoped for.
- **`knowledge_depth` computed rather than asserted** is why capability growth reads as honest rather than as a drip-feed.
- **The absence of streaks** is a real decision that will look increasingly correct.
- **Strain gating on commerce** is E12 and E13 made structural.

---

# Part 4 — Recommended order

Sequenced by (parent-felt improvement) ÷ (work), not by severity.

| # | Change | Principle | Effort |
|---|---|---|---|
| 1 | ✅ **Applied** — `Show Typing` fires on the `normal` route before any lookup | E6 | one node |
| 2 | ✅ **Applied** — `/start` is one message. `Send Pinned` / `Pin It` disabled | E1, E4 | rewire |
| 3 | ✅ **Applied** — `Pin - Load → Surface → Exists? → Edit \| Create → Attach → Remember` | E9 | 7 nodes + a column |
| 4 | Keyboard derived from state like everything else | E2 | one function change |
| 5 | Menu body carries the surface content | E4 | one expression |
| 6 | Harvest reply composed and uniqueness-tested | E7 | agent + gate |
| 7 | `setMyCommands` — two commands | E11 | one call, once |
| 8 | Progress shows movement when movement exists | Goal Gradient | one function change |
| 9 | «شيء آخر» — founder decision | §3.1 | — |

**1–3 change what a parent feels this week.** 6 changes what she remembers.

---

## The standard

> *Is this the best experience a parent could have inside Telegram?*

Not yet — and the gap is not features. It is that ADAM currently spends its first three messages talking about itself, then goes silent when she needs presence, then says the same eight words every night at the moment she is most likely to remember. Those three are fixable this week, and none of them requires a new capability.
