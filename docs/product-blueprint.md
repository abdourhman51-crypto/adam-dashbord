# ADAM — Product Blueprint v2

**Date:** 2026-07-30
**Status:** Specification for review. **No implementation. Awaiting approval.**
**Supersedes:** v1 (2026-07-29), preserved in git history as `product-blueprint-v1.md`.

**Rule for this document:** every feature carries *why it exists*, *the user evidence*, *the problem it solves*, and *how success is measured*. Anything that cannot answer all four was cut. Nothing is inherited from the current build because it exists.

**Rule for this revision:** the eleven decisions in §0 override anything that contradicts them, anywhere in this document. Where v1 conflicted, v1 is wrong.

---

## 0. What changed in v2, and why

| # | Decision | Overrides |
|---|---|---|
| **D-A** | **ADAM serves both parents**, not mothers only. All copy becomes gender-neutral | Every Arabic string in v1 §11 was feminine; Persona A was "The Exhausted Mother" |
| **D-B** | **"الاحتواء" is internal team vocabulary only.** Never reaches a user | v1 used "containment mode" inside user-facing flow specs |
| **D-C** | **Memory is the heart of the product** and must be used to the maximum, naturally | v1 treated memory as one feature (F8) among thirteen |
| **D-D** | **New free retention system: a daily rhythm of Seed (morning) + Harvest (evening)**, always linked | v1 assumed the parent arrives only at the moment of trouble |
| **D-E** | **Timing must follow the event.** Never ask about sleep at the start of the night, or about school after school ended | v1 fixed everything at 21:00 local |
| **D-F** | **Memory is derived from real signal**, never from a static content library | v1 did not forbid template content for proactive messages |
| **D-G** | **Free is never deliberately degraded.** The free/paid difference is the *level of companionship*, never the quantity of memory or information | v1 §14 implied tiering by mechanism access |
| **D-H** | **Paid value is expressed as outcome, never as technology.** No selling memory, reports, initiative, plans, or tracking | v1 §11.5 was literally a four-bullet feature list — the exact error v1 §4 diagnosed and then committed |
| **D-I** | **Full-companionship discovery is deferred.** No discovery or gradual-selling system is designed now. TODO, no invention | v1 specified a "persistent quiet affordance" mechanism (F9) |
| **D-J** | **Telegram First.** Every interaction is audited for fewer taps: buttons, quick replies, pinned messages, menus, voice | v1 had the principle (P4) but no systematic audit |
| **D-K** | **No implementation until this version is approved** | — |

**Section-by-section change log is at §31.**

---

## Table of contents

0. What changed in v2, and why
1. Product vision
2. Product principles
3. Positioning, voice, and the two lexicons
4. Value proposition
5. Customer transformation
6. User personas
7. Jobs To Be Done
8. Information architecture
9. Complete user journey
10. Every user state
11. Conversation flows
12. The memory model
13. The timing model
14. Telegram-first interaction audit
15. Feature map
16. Value ladder
17. Activation strategy
18. Habit loop
19. Growth loop
20. Referral loop
21. Monetization strategy
22. Pricing strategy
23. Success metrics
24. North Star Metric
25. Product analytics events
26. Experiment roadmap
27. Product roadmap
28. Risks and assumptions
29. Features to remove / keep / build
30. Decisions challenged and rejected
31. Change log v1 → v2
32. Open decisions requiring founder input

---

## 1. Product vision

**Ten-year vision**

> Every Arab parent who wants to break a cycle of shouting has someone with them in the moment it matters — and proof, in their own hands, that they are changing.

**Three-year vision**

> ADAM is the default companion for Arabic-speaking parents in the hardest moments of raising a child: present in seconds, free to anyone, and trusted enough that parents tell it what they hide from their own families.

**One-year vision**

> A parent anywhere in the Arab world wakes up to one small thing worth trying with their own child, is asked that evening how it went, and after a month lives in a noticeably quieter home.

**Note on the one-year vision (D-H).** v1 read *"…and after thirty days hold a report that shows exactly how much calmer their home became."* A report is machinery. The parent does not want a report; they want the quieter home. The report is how we prove it, never what we sell.

**What we are not building:** a parenting course, a content library, a diagnosis tool, a therapist replacement, or a child-behaviour tracker. Each was considered and rejected in §30.

---

## 2. Product principles

Decision rules. When a build decision is ambiguous, these resolve it — in order.

| # | Principle | Rule in practice | Evidence |
|---|---|---|---|
| **P1** | **The crisis is never monetised** | No paywall, cap, or upsell may ever appear in a conversation where a parent is distressed | *"انت طلعت بفلوس اخص عليك"* — observed reaction to a paywall inside an emotional relationship |
| **P2** | **Never ask before you give** | No profiling question may precede the first useful answer | 94.1% onboarding abandonment (271/289 stuck at step 0) |
| **P3** | **They are tired, not guilty** | No output may attribute blame to the parent, even when factually true | Already encoded; 73 guilt messages in the corpus |
| **P4** | **Fewest taps wins** | Any recurring interaction must be answerable with a tap. Typing is the fallback, never the requirement | Avg human message = 53 chars; parents are dysregulated when they write |
| **P5** | **Show memory, never announce it** | Never say "I see in your file". Demonstrate continuity by using it | Announcing memory reads as surveillance |
| **P6** | **Value per effort** | Every reply is 2–3 lines: one cause, one step, one measure | Matches an exhausted reader |
| **P7** | **Honest limits** | Never promise a guaranteed child outcome | Protects trust, which is the moat |
| **P8** | **Free forever, everywhere** | Geography may gate payment. It may never gate help | 140/289 signups blocked; 23,697 unserved audience |
| **P9** | **Silence over harm** | When memory could reopen a wound, store nothing | *"الذاكرة الناقصة أرحم ألف مرة من الذاكرة التي تجرح"* |
| **P10** | **No scarcity, ever** | No countdowns, limited seats, expiring offers | Incompatible with P1 and P3 |
| **P11** | **Memory is the product** *(new, D-C)* | No proactive message may be generic. If ADAM cannot ground it in something it actually knows about *this* child, it does not send it | The one durable advantage; a generic tip is available free everywhere |
| **P12** | **Written for both parents** *(new, D-A)* | Default to constructions that carry no gender. Where gender is known, render it. Never assume mother | 18.5% of the audience is male; 4 of 18 declared users are fathers |
| **P13** | **A daily rhythm, not a crisis line** *(new, D-D)* | The free tier has a heartbeat: one small thing in the morning, one question in the evening, linked | Waiting for trouble means being remembered only as the trouble |
| **P14** | **Timing follows the event** *(new, D-E)* | Every message is scheduled relative to the moment it concerns — never to a global clock | Asking about bedtime at 21:00 asks about a thing that has not happened |
| **P15** | **Free is never crippled** *(new, D-G)* | No feature may be degraded solely to create a reason to pay | A deliberately worsened free tier is a trust cost with no product benefit |
| **P16** | **Sell the destination, not the machinery** *(new, D-H)* | Every commercial sentence answers "what will my life be like in a month?" — never "what is included?" | *"لا أحد يشتري ذاكرة"* — our own prompt already concedes this |

**P1, P2, P8 and P15 override commercial considerations.** If a growth tactic conflicts with them, the tactic is wrong.

---

## 3. Positioning, voice, and the two lexicons

### 3.1 Positioning statement

> **For** exhausted Arabic-speaking parents who already know what good parenting looks like but cannot reach it when they are angry,
> **ADAM is** a companion present in the moment itself
> **that** knows your child by name, offers one small thing each morning, asks how it went each evening, and month by month makes the house quieter.
> **Unlike** parenting content, courses, or general AI assistants,
> **ADAM** is already in the middle of your family's story and never needs catching up.

### 3.2 The category shift

| | From (current) | To (proposed) |
|---|---|---|
| **Hero** | The child | The parent |
| **Promise** | Understand what your child doesn't say | A quieter house, and you steadier in it |
| **Proof** | ADAM explains | ADAM shows change that already happened |
| **Category** | AI parenting advice | The companion who knows your family |
| **Moment of use** | Whenever curious | Every morning, every evening, and the moment of losing control |

Note the last row. v1 said only *"the moment of losing control."* Under D-D, use is now daily and expected, not incident-driven.

### 3.3 Brand continuity — a deliberate constraint

**Keep the name, handle, and visual identity.** "آدم | ما لا يقوله طفلك" carries ~41,100 followers and a 525,682-reach proof point. The promise evolves; the brand does not reset. Tagline shifts over one quarter, not overnight.

### 3.4 Voice attributes

| Attribute | Do | Don't |
|---|---|---|
| **Warm without excess** | "أنا هنا" | "حبيبتي", "قلبي", any pet name |
| **Never blaming** | "الخوف صار ضيفاً ثقيلاً في البيت" | "أنتِ أخفتِها", "بسببك" |
| **Short** | 2–3 lines, phone-readable | Walls of text, numbered essays |
| **Practical** | One cause, one step, one measure | Theory, philosophy, citations |
| **Honest** | "أمشي معكم ولا أعِد بطفلٍ مثالي" | "سيتوقف", "مضمون" |
| **Plain Arabic** | Simplified MSA, light dialect touch | Foreign words, ornate metaphor, poetry |
| **Specific to this family** *(new)* | "تجربة التنبيه مع يوسف" | "جرّب التنبيه المسبق مع طفلك" |

**Absolute bans:** scarcity, urgency, expiring offers, intimate pet names, guilt attribution, guaranteed child outcomes, claiming to remember something never said, any link or phone number inside emotional messages, and — new under P11 — **any proactive message that would read identically to a different family.**

### 3.5 Writing for both parents (D-A) — the actual technique

Arabic has no neutral second-person imperative. "أخبريني" and "أخبرني" are both gendered; there is no third option. Neutrality is therefore achieved **structurally, not lexically**.

**Every user-facing string is authored in three forms:** masculine, feminine, and a **gender-free default** used whenever gender is unknown. The gender-free default is the primary form; the gendered variants are refinements.

**Four techniques that produce genuinely gender-free Arabic:**

| Technique | Instead of | Write |
|---|---|---|
| **Nominal sentence** | "أخبريني كيف كانت" | "والليلة: كيف كانت؟" |
| **First-person plural for shared action** | "جرّبتِ وما نجحت" | "جرّبناها وما نجحت" |
| **Button instead of imperative** | "اكتبي لي ما حدث" | `[ما حدث الليلة]` |
| **Impersonal / passive** | "ستعرفين أنها نجحت إذا…" | "علامة النجاح: أن ينام دون نداء" |
| **Respectful plural** | "أمشي معكِ" | "أمشي معكم" |

**The first-person plural is a genuine upgrade, not a workaround.** "جرّبناها" ("we tried it") is warmer and more collaborative than "جرّبتِها" ("you tried it"), and it quietly removes the implication that success or failure belongs to the parent alone. The constraint improved the copy.

**An honest limit — and why the three-form system is mandatory, not optional.**

The four structural techniques cover most copy, but **not all of it.** Some sentences genuinely require second person, and Arabic offers no truly neutral singular form. The masculine singular is often used as a generic default — and it is **not acceptable here**, because 57.6% of this audience is women and "أنت تعرف" addressed to a mother is exactly the defect D-A exists to remove, only pointing the other way.

This was caught while drafting §11.8, §11.9 and §20 of this very document: all three had slipped into masculine second person under the label "gender-free". They were rewritten nominally. The lesson is structural, not editorial:

> **Where a string cannot be written without second person, structural neutrality has failed and the three-form system is doing the work.** In that case the *unknown-gender* form must use the respectful plural, never the masculine singular.

Ranked preference for any new string:

1. Nominal, impersonal, or first-person plural — **no gendered form needed at all**
2. Respectful plural — acceptable for the unknown-gender form
3. Three explicit forms with masculine/feminine rendered from `Parent.gender` — required whenever 1 and 2 are impossible
4. **Masculine singular as a generic — never**

**Gender of ADAM:** ADAM always refers to himself in the masculine. That is a name, not an assumption about the user.

**Where gender is known** — declared, or confidently inferred from the parent's own grammar — render the gendered variant. **Never infer gender from the child's gender, and never guess from a name.**

### 3.6 The two lexicons (D-B)

Some of our most useful words are **diagnostic vocabulary for the team** and would be alienating or clinical if a parent saw them.

| Internal term | Never shown as | What the parent experiences instead |
|---|---|---|
| **الاحتواء** (containment) | — | ADAM simply stays, listens, and does not rush to advise |
| Seed / Harvest | — | A morning thought and an evening question — no names, no labels |
| Situation / flashpoint | — | The situation named plainly: "عند النوم" |
| Chapter / Journey | *(pending §32 D8)* | Something with a beginning and an end, described in outcomes |
| Mirror | — | ADAM noticing something |
| Crisis state / X1 | — | Nothing. The parent must never sense a mode change |
| Tier, free, paid, upgrade | — | *(see D-H and §21)* |

**Hard rule:** these words appear in specifications, code, dashboards and team conversation. They appear in a user-facing string **never**. A user-facing string containing one is a defect, not a wording preference.

**Why this matters more than it sounds.** "الاحتواء" is a therapeutic term. A parent who reads it learns they are being handled according to a protocol — the exact opposite of the feeling the protocol exists to create.

---

## 4. Value proposition

**Primary — gender-free, outcome-led**

> **آدم يعرف طفلك بالاسم، ويمشي معك يوماً بيوم حتى يهدأ البيت.**
> *ADAM knows your child by name, and walks with you day by day until the house is calmer.*

v1's primary line was *"آدم معكِ في اللحظة الصعبة — ويريكِ بعد ثلاثين يوماً كم تغيّرتِ"* — feminine, and its second half sells a demonstration rather than a destination.

**Layered by audience temperature**

| Audience state | Message | Where used |
|---|---|---|
| Cold (content viewer) | "طفلك لا يحتاج صراخاً أكثر — يحتاج بيتاً يشعر فيه بالأمان" | Instagram (proven, 525k reach) |
| Warm (in the moment) | "ما الذي حدث الآن؟ أنا هنا." | Bot first contact |
| In the rhythm | "تجربة صغيرة اليوم مع يوسف…" | Morning Seed |
| Engaged (3+ evenings) | "ثلاث ليالٍ من خمس كانت أهدأ. هذا ما بنيتموه." | First Mirror |
| Considering | *(deferred — see D-I and §11.8)* | — |
| Completed | "هنا كانت البداية. وهنا الآن." | End of month |

**What we never say again:** "remembers every situation", "knows your child by name" *as a feature bullet*, or any feature list as the lead. Note the distinction: "knows your child by name" is excellent as a **demonstrated fact inside a message** and forbidden as a **claim inside an offer**.

---

## 5. Customer transformation

The product exists to move a parent along one axis.

```
BEFORE                                          AFTER
─────────────────────────────────────────────────────────────
"I shout, then I hate myself."          →   "I caught myself, and I know it."
"I have no idea why he does this."      →   "I know what sets him off."
"I read a lot and change nothing."      →   "I did one small thing and it worked."
"I'm alone in this."                    →   "Someone is with me, every day."
"I might be a bad parent."              →   "The house is quieter, and I did that."
```

*(v1's final row read "I might be a bad mother" → "I have proof I'm becoming calmer." Both halves revised: the first for D-A, the second for D-H — "proof" is machinery; the quieter house is the outcome.)*

**The transformation is measured, not claimed.** Measurement is how we know and how we show. It is not the thing being sold.

**Transformation milestones — the product must make each one legible:**

| # | Milestone | Trigger | Parent feels |
|---|---|---|---|
| **T1** | First relief | First usable step received | "Someone is here." |
| **T2** | First win | First Harvest answered positively | "It actually worked." |
| **T3** | First recognition | First Mirror at 3+ logged evenings | "It knows my child." |
| **T4** | Named pattern | Recurring situation identified and confirmed | "I understand what's happening." |
| **T5** | Identity shift | End of month | "My house is calmer, and I did that." |

---

## 6. User personas

### Persona A — والد منهك · "The Exhausted Parent" (primary)

| | |
|---|---|
| **Who** | Parent, 25–44, DZ/EG/MA/IQ/SY and the wider Arab world, 1–3 children aged 2–11 |
| **Size** | The core of the audience. Gender split: 57.6% women, 18.5% men, remainder undeclared |
| **Trigger moment** | Late evening, after shouting or hitting, alone, flooded with shame |
| **Current alternative** | Instagram reels, family advice, the bathroom door |
| **Job** | Stop being the angry parent; be seen without judgement |
| **Evidence** | *"بنتي عمرها ٤ سنوات حاسة اني فاشله ف التربية"* · *"بس اريد اكون ام اسلوبها هادئ"* · *"انا بضرب"* |
| **Blocker** | Cannot pay by card; may be in an unsupported country |
| **Design implication** | Voice input, one-tap logging, zero forms, free rescue, **gender-free default copy** |

**Two sub-variants — same job, different framing emphasis:**

| Sub-variant | Share | What differs |
|---|---|---|
| **A1 — الأم** | 57.6% of audience | Shame and self-judgement more often named explicitly |
| **A2 — الأب** | 18.5% of audience | Authority and discipline framing appears alongside connection; less likely to name shame directly |

**These are not separate personas.** v1 made the father a separate persona (C), and that is precisely what produced a mother-default product with a father exception. The job is identical; only emphasis shifts. One product, gender-free by default.

### Persona B — والد على القائمة · "The Waitlisted Parent" (largest untapped)

| | |
|---|---|
| **Who** | Identical job to A, in IQ/SY/SA/JO/YE/OM/Gulf |
| **Size** | 48.4% of signups (140/289); 57.6% of audience (23,697) |
| **Distinguishing fact** | Gulf sub-segment (~5,749) has materially higher ability to pay than all three current markets |
| **Evidence** | Country distribution in `followers` + Instagram audience data — two independent sources agreeing |
| **Design implication** | **Serve free immediately. Gate only payment.** Collect proven demand for a future rail |

### Persona C — والد في أزمة · "The Crisis Parent" (small, highest stakes)

| | |
|---|---|
| **Who** | Parent disclosing third-party abuse, bereavement, adolescent substance use, or their own violence |
| **Size** | Small but present across 2,086 messages |
| **Evidence** | *"حذرنا المعتدي سابقا"* · *"اكتشفت أنه يدخن ويتعاطى"* · *"فقدنا أمنا منذ عام"* · *"انا بضرب"* |
| **Design implication** | Detection + human escalation. Never automated advice. **The daily rhythm suspends entirely.** §11.9, §32 |

**Explicitly not a persona:** the "curious browser." No evidence of a meaningful non-distressed segment. Do not design for them.

---

## 7. Jobs To Be Done

### Primary job

> **When** my child does something I can't handle and I feel myself losing control,
> **I want to** not become the parent I'm ashamed of,
> **so that** my child remembers a home that was safe.

### Job dimensions — all four must be served

| Dimension | Job | Served by | Evidence |
|---|---|---|---|
| **Functional** | Interrupt escalation; give me one action now | The Moment | 168 "how do I" messages; 53-char avg |
| **Emotional** | Stop feeling like a failure; be seen without judgement | Voice + no-blame discipline | *"عايزه حد يشوفنى حلوه من جوه من غير احكام"* |
| **Social** | Be a parent whose children remember warmth | The Mirror + end of month | *"عندما يكبرون لا يذكرون الا الصراخ والتوبيخ"* |
| **Relational** *(new, D-C/D-D)* | Have someone in this with me who doesn't need re-explaining | The daily Seed→Harvest rhythm + memory | *"خسارة انك لا تذكرني"* — an explicit complaint about discontinuity |

That last quote is the clearest single justification for D-C and D-D together. **A parent told us the discontinuity hurt.**

### Secondary jobs

| Job | Evidence | Served in |
|---|---|---|
| Interrupt intergenerational trauma | *"لا أريد أن تنتقل لهم الصدمات"* | Positioning + end of month |
| Not be alone | 20,991 shares on one post | Later (peer presence) — not MVP |
| Understand a specific worry (speech/development) | 98 messages — #3 theme | NEXT (§27) |

### Forces of Progress — the design brief

| Force | State | What the blueprint does about it |
|---|---|---|
| **Push** | 🟢 Very strong | Nothing needed — 73 guilt + 28 exhaustion messages |
| **Pull** | 🟢 Strong | Preserve conversation quality; add the Mirror |
| **Anxiety** | 🔴 Unaddressed | Permanent free guarantee; no recurring commitment; 30-day guarantee |
| **Habit** | 🔴 Unaddressed → **now the Seed/Harvest rhythm** | v1 had no habit answer beyond a single evening ping. D-D makes the rhythm the answer |

**Every feature in §15 exists to reduce Anxiety or Habit.** Adding more Pull is not the constraint.

---

## 8. Information architecture

A conversational product has no navigation tree. Its IA is: **entity model + state machine + interruption points.**

### 8.1 Entity model

```
Parent ─┬─ 1:N ─ Child ─┬─ 1:N ─ Situation      (the recurring hard moment)
        │               └─ 1:N ─ Pattern
        ├─ 0:1 ─ Knowledge                      (what ADAM knows — derived)
        ├─ 1:N ─ Moment                         (a rescue event)
        ├─ 1:N ─ Day ─┬─ 1:1 ─ Seed             (morning)
        │             └─ 0:1 ─ Harvest          (evening)
        ├─ 1:N ─ Mirror
        ├─ 0:1 ─ Chapter ─ 1:N ─ Payment
        ├─ 1:N ─ Message
        └─ 0:N ─ CrisisFlag
```

| Entity | Purpose | Why it exists |
|---|---|---|
| **Parent** | The customer | Identity, state routing, **gender when known** |
| **Child** | Who this is about | Name is the strongest continuity signal we have |
| **Situation** | The recurring hard moment, with **a time-of-day window** | The unit of work. The window is what makes D-E possible |
| **Knowledge** | Derived: what ADAM actually knows about this family | **New in v2.** Makes P11 enforceable — a Seed cannot be generated without reading it |
| **Moment** | A rescue event | Measures the highest-value interaction |
| **Day** | One Seed and its Harvest, as a single unit | **New in v2.** They are two halves of one thing (D-D) and must not be separable rows |
| **Seed** | The morning suggestion, grounded in Knowledge | Records what it was derived from, so an ungrounded Seed is detectable |
| **Harvest** | The evening answer to *that* Seed | Never a generic "how was your day" |
| **Pattern** | Derived insight | What makes ADAM feel like it knows the child |
| **Mirror** | A generated reflection | Must be a first-class object, not a message |
| **Chapter** | The paid container | *(naming and duration pending §32 D8)* |
| **Payment** | A transaction | Manual reconciliation |
| **Message** | Conversation history | Memory + analysis corpus |
| **CrisisFlag** | Safeguarding | Duty of care |

**Renamed from v1:** `Flashpoint` → `Situation` (internal-lexicon hygiene per D-B: "flashpoint" has no natural Arabic rendering and kept leaking into draft copy). `Night` → `Day`, carrying an explicit Seed/Harvest pair. `Journey` → `Chapter`, pending D8.

**Deleted:** `main_pain` as a fixed 8-value enum — it forced a taxonomy that missed the #3 theme (speech/development, 98 messages). Situation is free text with a derived label.

**Correction to v1.** v1 §8.1 listed `weekly_plans` and `survey_responses` as deletable. The 2026-07-29 dependency audit found live writers for both. They are retained and marked deprecated in the database. **v1 was wrong because it predated the audit.**

### 8.2 Data integrity rules (non-negotiable)

| Rule | Why |
|---|---|
| Every conversation must resolve to a Parent row before the first reply | Otherwise the user is invisible to every downstream system |
| Engagement counters must be derived, never incremented by a workflow | Incrementers silently fail — `message_count` sat frozen at 0 while parents actively conversed |
| Agent context must never be persisted into stored user messages | Pollutes memory, inflates cost |
| Every generated message must have a hard length ceiling | One stored message reached 169,230 chars |
| Price must be injected from configuration, never inferred | The agent invented "150 EGP" against a real 490 |
| **A Seed must record the Knowledge it was derived from** *(new)* | The only way to enforce P11 mechanically rather than by hoping the prompt behaves |
| **A Harvest must reference its Seed** *(new)* | Enforces D-D's linkage structurally, so a generic evening question is impossible to send |
| **Every user-facing string must exist in all three gender forms** *(new)* | Enforces D-A at the content layer, not per-message improvisation |

The last three follow the pattern this project has learned to trust: **make the rule an invariant of the data, not a convention in a prompt.**

### 8.3 Surfaces

| Surface | Role | Notes |
|---|---|---|
| **Telegram chat** | The whole product | Text + voice notes + inline buttons + pinned message + bot menu |
| **Instagram/Facebook** | Acquisition only | Never the product surface |
| **Operator console** | Manual payment confirmation + crisis queue | Minimal internal tool |

**No mobile app. No web dashboard. No email.**

---

## 9. Complete user journey

```
┌─ ACQUISITION ────────────────────────────────────────────────┐
│  Instagram content — reach 150k–525k (already working)       │
│  CTA reframed from product to moment                         │
└──────────────────────────┬───────────────────────────────────┘
                           ▼
┌─ FIRST CONTACT ──────────────────────────────────────────────┐
│  /start → NO country gate. NO form. NO questions.            │
│  TARGET: usable step in < 60 seconds           [T1 relief]   │
└──────────────────────────┬───────────────────────────────────┘
                           ▼
┌─ THE MOMENT (free, forever, everywhere) ─────────────────────┐
│  One cause · one small thing for tonight · one way to know   │
└──────────────────────────┬───────────────────────────────────┘
                           ▼
┌─ THE DAILY RHYTHM (free — the retention engine, D-D) ────────┐
│                                                              │
│   MORNING · Seed          →         EVENING · Harvest        │
│   one small thing,                  how did *that* go?       │
│   grounded in this child            one tap                  │
│      └───────────── always the same subject ──────────┘      │
│                                                              │
│  Timed relative to the situation, never to a global clock    │
│                                                   [T2 win]   │
└──────────────────────────┬───────────────────────────────────┘
                           ▼
┌─ THE FIRST MIRROR (free — the recognition moment) ───────────┐
│  Fires at 3 logged evenings. Data-gated, never day-gated.    │
│  Carries no price and no offer, by constraint.      [T3]     │
└──────────────────────────┬───────────────────────────────────┘
                           ▼
┌─ ??? DISCOVERY OF FULL COMPANIONSHIP ────────────────────────┐
│                                                              │
│   ███  TODO — DELIBERATELY UNDESIGNED (D-I)  ███             │
│                                                              │
│  How a parent learns full companionship exists is NOT        │
│  specified. No trigger, no timing, no surfacing mechanism.   │
│  If asked directly, ADAM answers (§11.8). Nothing initiates. │
│  See §32 D7. No invention permitted here.                    │
└──────────────────────────┬───────────────────────────────────┘
                           ▼
┌─ FULL COMPANIONSHIP (paid) ──────────────────────────────────┐
│  Described in outcomes only (D-H). See §16.1 and §21.1.      │
│  Manual payment → operator confirms → begins                 │
└──────────────────────────┬───────────────────────────────────┘
                           ▼
┌─ WEEKLY MIRRORS ─────────────────────────────────────────────┐
│  What changed, what's working, what's next                   │
└──────────────────────────┬───────────────────────────────────┘
                           ▼
┌─ END OF MONTH ───────────────────────────────────────────────┐
│  "هنا كانت البداية. وهنا الآن."                 [T5 identity] │
└──────────────────────────┬───────────────────────────────────┘
                           ▼
      Continue  ·  Or return to the free rhythm, fully intact
                  (nothing is taken away — P1, P15)
```

**The structural change from v1.** v1's free tier was a **corridor**: rescue → nightly ping → Mirror → ask. A parent whose day went fine had no reason to open Telegram. v2's free tier is a **loop that runs whether or not anything went wrong**, and the Mirror emerges from it rather than terminating it.

---

## 10. Every user state

States are mutually exclusive except where marked orthogonal.

### 10.1 Primary lifecycle states

| # | State | Entry condition | Exit condition | System behaviour |
|---|---|---|---|---|
| **S0** | `new` | `/start` received | First user message | Greet; invite the moment; no questions |
| **S1** | `first_moment` | First substantive message | First step delivered | Full attention; no logging prompts |
| **S2** | `helped` | First step delivered | **Enough known to ground a Seed** | Enrol in the rhythm from the next morning |
| **S3** | `in_rhythm` | First Seed sent | 3 Harvests logged | **Daily Seed + Harvest.** Learning the situation |
| **S4** | `recognised` | First Mirror delivered | — | Rhythm continues; weekly cadence |
| **S5** | *(discovery)* | **TODO — undesigned (D-I)** | — | **No system enters this state. §32 D7** |
| **S6** | `payment_claimed` | Parent states they paid | Operator confirms or 72h timeout | Warm acknowledgement; **rhythm uninterrupted** |
| **S7** | `chapter_active` | Payment confirmed | Objective met, or month of logged days complete | Full companionship |
| **S8** | `chapter_complete` | End-of-month delivered | — | Returns to S4 rhythm, fully intact |
| **S9** | `dormant` | 14 days no interaction | Any message received | Rhythm decays then stops. One reactivation, per lifetime |
| **S10** | `returned` | Message after dormancy | Resolves within 1 turn | Acknowledge continuity, never guilt the absence |

**S2's exit condition changed (D-C, P11).** v1 entered the loop the moment a step was delivered. v2 requires *enough known to ground a Seed* — at minimum the child's name or the recurring situation. **A Seed that could be sent to anyone violates P11, so the state machine refuses to start the rhythm until it can be personal.**

### 10.2 Orthogonal states

| State | Entry | Effect | Priority |
|---|---|---|---|
| **X1** `in_crisis` | Crisis category detected | All commercial messaging suppressed. **Seed and Harvest suspended entirely.** Human queue | **Overrides everything** |
| **X2** `payment_blocked` | Country has no payment rail | Free rhythm fully available; no offer surfaced | Never blocks help (P8) |
| **X3** `voice_preferred` | ≥2 voice notes sent | Voice-friendly cadence; shorter text | Cosmetic |
| **X4** `paused` | Parent asks for silence | All proactive messages stop; conversation remains | Honoured indefinitely |

**X1 now suspends the rhythm.** A cheerful morning suggestion the day after a parent disclosed violence is worse than silence. v1 suppressed only *commercial* messaging in X1; that was insufficient.

### 10.3 State transition rules

1. **No transition may skip S1→S2.** Value before any other behaviour. (P2)
2. **Nothing may enter S5.** The discovery mechanism is undesigned. Any implementation that surfaces, hints at, or times an offer is out of scope until §32 D7 is answered. (D-I)
3. **X1 suppresses S6–S8 messaging and the daily rhythm** for the duration plus 7 days.
4. **X2 never blocks S0–S4.** Payment geography gates S6 onward only. (P8)
5. **S9 permits exactly one reactivation message per parent lifetime** — not one per dormancy.
6. **S8 returns to S4 with nothing removed.** (P15)

---

## 11. Conversation flows

Scripts are specification, not suggestion. **All strings below are the gender-free default form** (§3.5); masculine and feminine variants are required at build time.

### 11.1 First contact (S0 → S1)

```
ADAM: السلام عليكم 🌿
      أنا آدم.
      ماذا حدث؟ الكتابة أو التسجيل الصوتي — كلاهما يصل.
```

**Rules:** no name request, no country question, no age question, no menu. One line of identity, one invitation. Voice offered explicitly at first contact because that is when the parent is least able to type.

*(v1: "احكيلي شنو صار — اكتبي، أو سجّلي صوتاً إذا كان أسهل" — two feminine imperatives. Rewritten nominally.)*

### 11.2 The Moment — core response shape (S1 → S2)

```
[one line: the cause, without blame]
[one line: the small thing, specific to tonight]
[one line: how it will be recognisable]
```

**Worked example:**
```
ADAM: الرفض عند النوم غالباً ليس عناداً — هو خوف من الانفصال في الظلام.

      الليلة، قبل النوم بعشر دقائق: الجلوس معه، والباب مفتوح شبراً.
      بلا شرح — الجلوس وحده.

      علامة النجاح: أن ينام دون نداء أكثر من مرة.
```

**Constraints:** max 3 content lines. Never withhold detail — a direct "how exactly?" gets a full answer (P6). Never mention payment unless asked first (P1).

**No closing hook.** v1 ended this message with *"أخبريني الليلة كيف كانت"* — a feminine imperative, and now redundant: the Harvest arrives on its own (§11.4), timed to the situation. One fewer promise for the copy to keep.

### 11.3 The Seed — morning (D-D) · **NEW**

One message. One small thing. Grounded in this child.

```
ADAM: صباح الخير 🌿

      تجربة صغيرة اليوم مع يوسف:
      تنبيه قبل الانتقال بخمس دقائق — قبل الخروج، وقبل النوم.

      مساءً نتكلم عنها.
```

**Hard constraints:**

| Rule | Why |
|---|---|
| Must name the child | The single strongest continuity signal (P11) |
| Must derive from Knowledge (§12) — a recurring situation, a prior outcome, or an observed pattern | A generic tip is free everywhere; ours must not be (P11) |
| Must be **one** thing | Two suggestions halve the chance either is tried, and make the Harvest ambiguous |
| Must be small enough to do on a bad day | The parent is tired; ambition is the enemy of measurement |
| Must be answerable in the evening | It sets up its own Harvest (D-D) |
| **Never sent if Knowledge is insufficient** | Silence beats a generic message. See fallback below |
| Never sent in X1 | §10.2 |
| Timed per §13 | Not a global morning hour (D-E, P14) |

**If Knowledge is insufficient**, no Seed is sent. Instead, one question — asked once, never repeated daily:
```
ADAM: صباح الخير 🌿
      حتى تكون التجربة على مقاس ابنك: ما اسمه، وكم عمره؟
```
This is the one place a question precedes value, and it is permitted because value was already delivered in §11.2. P2 is satisfied.

**Explicitly banned:** a rotating library of parenting tips. **A Seed that could be sent to a different family is a defect** (P11, D-F).

### 11.4 The Harvest — evening (D-D) · **NEW, replaces v1's nightly check-in**

The Harvest asks about **the Seed** — never about the day in general.

```
ADAM: كيف كانت تجربة التنبيه مع يوسف اليوم؟

      [نجحت]  [جرّبناها وما نجحت]  [ما صارت الفرصة]
```

**The linkage is the whole point.** "كيف كان يومك؟" is a message from a stranger. "كيف كانت تجربة التنبيه مع يوسف؟" is a message from someone who was already in the room this morning.

**Replies — never neutral, never effusive:**

| Answer | ADAM replies |
|---|---|
| نجحت | "هذه خطوة حقيقية. نبني عليها غداً." |
| جرّبناها وما نجحت | "المحاولة نفسها تغيّر شيئاً. غداً زاوية أخرى." |
| ما صارت الفرصة | "لا بأس. ليس كل يوم يحتمل تجربة." |

**If nothing was tried, or the day was hard** — one optional follow-up, a tap, never a text box:
```
ADAM: وأصعب لحظة اليوم؟

      [عند النوم] [عند الأكل] [عند الخروج]
      [وقت الشاشة] [عند الدراسة] [موقف آخر]
```

**Critical:** "ما صارت الفرصة" must never carry disappointment. A parent who feels judged for not trying stops answering, and the Harvest is the entire proof engine.

**No Seed, no Harvest.** If no Seed was sent, no Harvest is sent. The pair is atomic (§8.1). A standalone evening question is exactly the generic "how was your day" that D-D exists to abolish.

### 11.5 The Mirror (S3 → S4)

Fires when three Harvests carry a result. Data-gated, never day-gated.

```
ADAM: لاحظتُ شيئاً في أيام يوسف 🌿

      من ثلاث ليالٍ مسجّلة: ليلتان أهدأ، وواحدة صعبة.
      والليلة الصعبة الوحيدة كانت في يوم بلا قيلولة.

      ليست قاعدة مؤكدة بعد — لكنها تستحق المراقبة أياماً أخرى.
```

**Why this lands where a feature list does not:** it is evidence about *this family*, from *their* data, that they could not have assembled alone.

**Carries no price and no offer** — enforced by database constraint, not by wording discipline.

**Deliberately under-claims.** Three nights prove nothing; over-claiming loses trust the moment night four contradicts it.

### 11.6 Weekly Mirror

```
ADAM: أسبوع آخر اكتمل.

      أربع ليالٍ أهدأ من سبع — كانت اثنتين الأسبوع الماضي.

      وشيء آخر، بعيد عن يوسف:
      ليلتان فيهما صراخ هذا الأسبوع. كانت خمساً.
```

**The last line is the parent's own change — placed last, stated quietly.** It is the real outcome, but it is not what they came for; leading with it reads as blame (P3).

**Regression is shown too.** A mirror that only reflects progress is not a mirror, and hiding a bad week retroactively discredits every good one.

### 11.7 End of month

```
ADAM: الشهر اكتمل.

      هنا كانت البداية:  ▓░░░░░░░░░   ليلة واحدة هادئة من عشر
      وهنا الآن:        ▓▓▓▓▓▓▓░░░   سبع من عشر

      الموقف الذي كان يهزم البيت: عند النوم
      اليوم: ست ليالٍ متتالية دون معركة

      وما عرفناه عن يوسف: يحتاج تنبيهاً قبل الانتقال، لا أوامر مباشرة.
```

**Continuation, if any, is a separate message — never the same one.** Achievement and commerce do not share a bubble (P1).

### 11.8 If asked about full companionship (D-H, D-I)

**Nothing in the system initiates this.** No trigger, no timing, no hint, no button, no pinned mention. See §32 D7.

**If the parent asks directly**, ADAM answers — in outcomes, never in contents:

```
ADAM: المساحة التي نحن فيها الآن تبقى كما هي، دائماً، بلا مقابل.

      والمرافقة الكاملة شهر نمشيه معاً نحو حالة واحدة:
      بيت تنتهي فيه الليلة دون معركة، ومعرفة ما يهدّئ يوسف قبل أن يبدأ.

      {price} — مرة واحدة، لشهر.
      وإن لم يتغيّر شيء ملموس، الشهر التالي عليّ.
```

**Compare with what v1 specified:**

> أعرف طبع {child} وما يفجّر الموقف ومايهدّئه
> خطوة كل يوم مفصّلة عليه هو
> وفي نهاية الشهر، تقرير يريكِ بالضبط كم تغيّرتِ

Three bullets: memory, a plan, a report. **That is a feature list — the precise error v1 §4 identified and then committed forty lines later.** No parent wants a report. They want the night to end without a fight.

**The test every commercial sentence must pass (P16):** does it answer *"what will my life be like in a month?"* — or *"what is included?"* If the second, it is rewritten or deleted.

**"ليس الآن" response:**
```
ADAM: لا شيء يتغيّر بيننا. أنا هنا كل صباح ومساء كما كنت. 🌿
```
Then never raised again unprompted, ever.

**Price is injected from configuration, never generated** (§8.2).

### 11.9 Crisis path (X1) — overrides everything

**Detection categories:** self-harm or suicidal ideation · domestic violence · child physical/sexual abuse by a third party · parent's own escalating violence · bereavement · substance use in a minor.

**Behaviour on detection:**

1. Suppress all commercial messaging — this conversation + 7 days
2. **Suspend Seed and Harvest entirely** for the same window
3. Suppress memory write for the sensitive content (P9)
4. Stay, and do not advise:
```
ADAM: أنا هنا.
      هذا الحِمل أثقل من أن يُحمل وحده.
      [line specific to the category]
      أنا هنا. ولا شيء مطلوب الآن.
```
5. Raise CrisisFlag → human queue
6. Never give clinical, legal, or safeguarding instructions

**On vocabulary (D-B).** The internal name for step 4 is **الاحتواء**. The parent must never see that word, never sense a mode change, and never be told they have been categorised. What they experience is that ADAM went quiet, stayed, and stopped suggesting things.

**This is the one area where the product must not act autonomously.** The escalation destination is a founder decision — §32 D1.

---

## 12. The memory model (D-C, D-F) · **NEW SECTION**

Memory is not a feature. It is the reason a proactive message is welcome rather than spam. This section exists because v1 gave memory one row in a feature table and then wrote proactive messages that did not use it.

### 12.1 What Knowledge is built from

Derived only from real signal — **never from a static content library** (D-F):

| Source | Contributes |
|---|---|
| **Conversations** | The presenting problem, the parent's own words, emotional state |
| **Child's name** | Named in every proactive message |
| **Child's age** | Calibrates what is developmentally reasonable to suggest |
| **Recurring situations** | Which moment of the day keeps failing, and its time window |
| **Prior outcomes** | Which suggestions worked and which did not — for *this* child |
| **Logged evenings** | The calm/hard series over time |
| **Detected patterns** | Correlations the parent has not noticed |

### 12.2 What each message type must read before sending

| Message | Must read | Refuses to send if |
|---|---|---|
| **Seed** | Child name + (recurring situation OR prior outcome OR pattern) | Any missing → no Seed; ask once instead (§11.3) |
| **Harvest** | The Seed it belongs to | No Seed today → no Harvest |
| **Mirror** | ≥3 results + situation labels | Fewer than 3 → does not fire |
| **The Moment** | Whatever exists; may be nothing | **Never refuses — the rescue is unconditional** |

**Only the rescue is unconditional.** Everything proactive must earn the right to interrupt by being specific.

### 12.3 How memory is used — the discipline

**Show, never announce (P5).** The difference is total:

| Wrong — announces | Right — demonstrates |
|---|---|
| "أتذكّر أنك أخبرتني عن يوسف" | "كيف كانت تجربة التنبيه مع يوسف اليوم؟" |
| "بحسب سجلّك، ثلاث ليالٍ صعبة" | "الليلة الصعبة الوحيدة كانت في يوم بلا قيلولة" |
| "لدي معلومات عن طفلك" | *(nothing — just use them)* |

The left column reads as a system with a file. The right reads as someone who was there.

### 12.4 The test for any proactive message

> **Could this exact message be sent to a different family?**
>
> If yes, it does not send.

This is P11 made checkable. It applies to the Seed above all, because the Seed is the message with the greatest temptation to become a tip library.

### 12.5 What is deliberately not remembered

Per P9, and validated against live data: content touching separation, violence, bereavement, or abuse is **not** written to the memory that feeds proactive messages. Two live rows settled this — a child-assault disclosure and a pattern label revealing family separation — neither distinguishable from a safe label by pattern matching.

**Therefore the rule is provenance, not content filtering:** proactive messages draw only on what ADAM authored or measured, never on what the parent disclosed. Already enforced in the database.

---

## 13. The timing model (D-E, P14) · **NEW SECTION**

v1 sent everything at 21:00 local. That is wrong in both directions: it asks about bedtime before bedtime, and about school long after school.

### 13.1 The rule

> Every message arrives **relative to the situation it concerns** — the Seed before it, the Harvest after it.

### 13.2 Situation time windows

Each Situation carries a window. Seed and Harvest are scheduled from it:

| Situation | Typically occurs | Seed arrives | Harvest arrives |
|---|---|---|---|
| **النوم** | 20:00–22:00 | Late afternoon — while there is still time to change the evening | After the window closes, ~22:30 |
| **المدرسة / الدراسة** | 07:00–08:00 and 16:00–18:00 | The evening *before*, or early morning | After homework time, early evening |
| **الأكل** | Mealtimes | ~1h before the main meal | After it |
| **الخروج / الانتقالات** | Variable | Morning, general | Evening |
| **وقت الشاشة** | Late afternoon–evening | Early afternoon | Evening |
| **Unknown** | — | Mid-morning default | ~21:00 local default |

The final row is the honest fallback: with no known situation there is no better answer than a sensible default. But it is a fallback, **not the design**.

### 13.3 Hard timing rules

1. **A Seed must arrive with time to act.** A bedtime Seed at 21:30 is useless — the window has closed.
2. **A Harvest must arrive after the window closes.** Asking at 20:00 how bedtime went asks about a thing that has not happened. This is the specific defect D-E names.
3. **All times are the parent's true local time**, via IANA zones. The legacy hardcoded map had Egypt at +2 when the real offset is +3, so every Egyptian parent — the largest market — was messaged an hour early, every night, for months.
4. **Never more than one Seed and one Harvest per day.** Two proactive messages is the ceiling for the free rhythm.
5. **Where local evening is unknown, send nothing** and surface the parent for resolution. 56 parents currently have no resolvable timezone. Guessing an hour is how ADAM becomes the thing they mute.
6. **Quiet hours are absolute:** nothing proactive between 23:00 and 07:00 local.

---

## 14. Telegram-first interaction audit (D-J) · **NEW SECTION**

Every interaction, audited against: *can this be a tap instead of typing?*

| Interaction | v1 | v2 | Effort saved |
|---|---|---|---|
| First contact | Type freely | Unchanged — **must** stay open text | 0, correctly |
| Describe a moment | Type or voice | Unchanged + voice promoted at first contact | Voice removes typing entirely |
| **Harvest answer** | 3 inline buttons | Unchanged — already optimal | — |
| **Hard-moment tag** | 6 inline buttons | Unchanged | — |
| **View progress** | Type `/تقدمي` | **Bot menu command + pinned message** | Typing → 1 tap |
| **Ask about companionship** | Type a question | **Bot menu entry** *(surfacing still TODO — D-I)* | Typing → 1 tap |
| **Claim payment** | Type + send image | **Send image only**; caption optional | 1 step removed |
| **Pause messages** | Type `/إيقاف` | **Bot menu + a button on any proactive message** | Typing → 1 tap |
| **Resume** | Any message | Unchanged | — |
| **Give the child's name** | Type | Type *(unavoidable — it is a name)* | 0, correctly |

### 14.1 Telegram capabilities to use

| Capability | Use | Why |
|---|---|---|
| **Inline keyboards** | Every recurring answer | Already the backbone (P4) |
| **Bot menu (command list)** | Progress, pause, ask, help | Discoverable without memorising slash commands |
| **Pinned message** | The child's current situation + progress at a glance | Persistent state without a dashboard |
| **Voice notes in** | Primary input at distress | 53-char avg messages, heavy dialect |
| **Voice notes out** | *Candidate, not committed* | May carry warmth text cannot — but unproven, and a synthetic voice can unsettle. Test before adopting |
| **Message reactions** | Lightest possible acknowledgement of a Mirror | Zero-tap feedback signal |
| **Reply-to-message** | Harvest replies to the Seed message | Makes the Seed→Harvest link visible in the UI itself |

**The reply-to-message point is the neatest win here.** Threading the Harvest as a reply to the morning Seed makes D-D's linkage visible in Telegram's own UI, with no extra copy at all.

### 14.2 What we will not use

| Capability | Why not |
|---|---|
| Persistent reply keyboard | Occupies the input area permanently; makes free text feel discouraged |
| Web app / mini app | A new surface with no evidenced job |
| Polls / quizzes | Reads as engagement mechanics; incompatible with the tone |
| Stickers, animations | Wrong register for a parent at 23:00 |
| Groups / channels | Community is deferred (§30) |

---

## 15. Feature map

Every feature answers four questions.

### F1 — The Moment (free, core)

| | |
|---|---|
| **Why** | The highest-value, zero-coverage need: help *during* escalation |
| **Evidence** | 132 hitting / 78 anger / 42 screaming messages |
| **Problem** | They know what to do and cannot reach it while dysregulated |
| **Measure** | Time-to-first-step < 60s (p50); Moment → rhythm entry ≥ 40% |

### F2 — The Seed (free, **NEW**, D-D)

| | |
|---|---|
| **Why** | Gives the free tier a heartbeat, so ADAM is not remembered only as the emergency |
| **Evidence** | *"خسارة انك لا تذكرني"* — discontinuity named as a loss by a parent |
| **Problem** | A companion who only appears at disasters becomes associated with disasters |
| **Measure** | Seeds grounded in child-specific Knowledge: **hard floor 100%** — an ungrounded Seed is a defect, not a miss. Seed→Harvest ≥50% |

### F3 — The Harvest (free, **NEW**, replaces v1's nightly check-in)

| | |
|---|---|
| **Why** | Closes the loop on the morning's suggestion and generates all proof data |
| **Evidence** | Button interaction already works; 53-char avg messages |
| **Problem** | "How was your day?" is a stranger's question and produces no measurable answer |
| **Measure** | ≥50% of parents in rhythm complete ≥3 Seed→Harvest pairs in the first 7 days |

### F4 — Voice input (free)

| | |
|---|---|
| **Why** | Removes the effort tax at peak distress; handles dialect |
| **Evidence** | 53-char avg; heavy dialect/typos (*"مبعرف"*, *"شو العمل😭"*) |
| **Problem** | Typing is hard when shaking with anger; MSA-biased input mis-serves dialect |
| **Measure** | ≥25% of first messages are voice within 30d |

### F5 — The First Mirror (free)

| | |
|---|---|
| **Why** | Makes recognition visible — ADAM demonstrably knows this child |
| **Evidence** | Built, data-gated at 3+, **fired zero times in production** |
| **Problem** | Memory is invisible and unsellable; recognition is felt immediately |
| **Measure** | Reaction rate; **retention of Mirror recipients vs non-recipients at day 14** |

**Measure changed (D-I).** v1 measured the Mirror by *"≥30% open the Journey ask"* — which presumes the discovery mechanism D-I defers, and quietly turns the Mirror into a sales instrument. It is measured by retention now.

### F6 — Memory / Knowledge layer (free, **elevated**, D-C)

| | |
|---|---|
| **Why** | The precondition for every proactive message. Without it, P11 forbids sending |
| **Evidence** | `light_memory` already populated for 129 parents; child name already extracted without asking |
| **Problem** | Generic advice is a commodity; a message about *يوسف* is not |
| **Measure** | ≥70% of parents in rhythm have a child name captured **without being asked**; 0 ungrounded proactive messages |

*(v1 had this as F8 "Child identity", scoped to name + age. D-C makes it the substrate of the product.)*

### F7 — Timing engine (free, **NEW**, D-E)

| | |
|---|---|
| **Why** | A correctly-worded message at the wrong hour is still wrong |
| **Evidence** | Legacy map put Egypt at +2 against a real +3 — the largest market messaged an hour early, nightly |
| **Problem** | Asking about bedtime before bedtime |
| **Measure** | 0 Harvests sent before their situation window closes; 0 sends in quiet hours |

### F8 — Situation learning (free → deepens paid)

| | |
|---|---|
| **Why** | Turns scattered complaints into one named, trackable problem with a time window |
| **Evidence** | `hard_moment` taxonomy validated; top themes are all situational |
| **Problem** | "My child is difficult" is unsolvable; "bedtime transitions" is solvable |
| **Measure** | ≥60% of S4 parents have a confirmed situation **with a time window** |

### F9 — Weekly Mirror (paid)

| | |
|---|---|
| **Why** | Sustains felt value between purchase and end of month |
| **Evidence** | Continuity explicitly wanted |
| **Problem** | A month-long purchase with no mid-point proof feels like a gamble |
| **Measure** | ≥70% of paid parents still answering Harvests at day 21 |

### F10 — End-of-month reflection (paid)

| | |
|---|---|
| **Why** | Delivers T5 and is the repurchase trigger |
| **Evidence** | Transformation milestones §5 |
| **Problem** | Repurchase needs evidence of change, not a calendar reminder |
| **Measure** | ≥25% continuation |

### F11 — Manual payment + operator console

| | |
|---|---|
| **Why** | The only rail available; founder confirms it is sufficient to start |
| **Evidence** | One confirmed payment (490 EGP) came through exactly this path |
| **Problem** | No card infrastructure in target markets |
| **Measure** | Claim→confirm < 6h (p50); zero unconfirmed >72h |

### F12 — Crisis detection + human escalation

| | |
|---|---|
| **Why** | Duty of care |
| **Evidence** | Abuse, bereavement, substance use, parental violence present in corpus |
| **Problem** | An AI advising into a violence situation is a real harm risk |
| **Measure** | 100% of flagged conversations reach human review < 24h; 0 commercial messages and **0 Seeds** sent in X1 |

### F13 — Free-everywhere access

| | |
|---|---|
| **Why** | Half of demand is discarded for no benefit |
| **Evidence** | 140/289 blocked; 23,697 unserved |
| **Problem** | Gating *usage* by geography costs the audience, the data, and the word-of-mouth |
| **Measure** | Unserved-country signups ≥40% of new |

### F14 — Content→product bridge

| | |
|---|---|
| **Why** | Highest-ROI hour available in the business |
| **Evidence** | 525,682 reach vs 445–770; ~0.7% audience→bot |
| **Problem** | Enormous audience, almost no door |
| **Measure** | 0.7% → ≥2% on bridged posts |

### F15 — Gender-neutral content system (**NEW**, D-A)

| | |
|---|---|
| **Why** | 18.5% of the audience is male and the product currently addresses them in the feminine |
| **Evidence** | Audience gender split; the Heart Writer prompt hardcodes *"أمٍّ"* |
| **Problem** | A father addressed as a mother learns in one message that the product was not built for him |
| **Measure** | 100% of user-facing strings exist in three forms; 0 gendered strings sent to unknown-gender parents |

### ~~F16 — Discovery of full companionship~~

> ### ███ TODO — NOT DESIGNED (D-I) ███
>
> No trigger. No timing. No surfacing mechanism. No "quiet affordance."
>
> v1 specified F9 as *"a persistent, quiet affordance, never pushed"* with a target of *"≥10% of S4 parents open it unprompted."* That is a designed discovery mechanism carrying a conversion target, and it is now out of scope.
>
> **In scope:** if a parent asks directly, ADAM answers (§11.8).
> **Out of scope:** anything that causes a parent to think to ask.
>
> See §32 D7. **No invention permitted.**

---

## 16. Value ladder

| Rung | Offer | Price | Gate |
|---|---|---|---|
| **0** | Instagram content | Free | None |
| **1** | **The Moment** — unlimited conversation, voice, crisis presence | **Free forever, every country** | None |
| **2** | **The daily rhythm** — Seed + Harvest, full memory, the First Mirror | **Free forever** | Enough known to be personal (§10, S2) |
| **3** | **Full companionship** — described in outcomes (§21.1) | **$10 equivalent** | Parent-initiated + a payment rail |
| **4** | **Continuation** | **~$6–7 equivalent** | Completed a month |
| **5** | *(Later)* Peer presence | TBD | Not in scope |

### 16.1 The difference between rung 2 and rung 3 (D-G)

**It is not the amount of memory. It is not the number of features. It is the level of companionship.**

| | Free (rungs 1–2) | Paid (rung 3) |
|---|---|---|
| **Memory** | **Full. Identical.** ADAM knows the child equally well | **Full. Identical.** |
| **Help when asked** | **Unlimited** | Unlimited |
| **Daily rhythm** | Seed + Harvest, every day | Seed + Harvest, every day |
| **Nature of the relationship** | Present, responsive, remembers | **Directed at one agreed outcome, with someone watching whether it happens** |
| **What the parent is buying** | — | **A month aimed at a specific change, and the accountability that it arrives** |

**Explicitly banned framings (D-G):**

| Never | Why |
|---|---|
| "Free remembers one day / seven days" | Deliberately crippling memory to manufacture a reason to pay (P15). Also self-defeating: shallow memory makes the free Seed generic, which breaks P11 |
| "Free gets 3 messages a day" | Rationing help (P1, P8) |
| "Unlock full memory" | Memory is not a product; it is the precondition for the product being any good |
| "Paid gets more features" | Nobody wants more features. They want the house quieter (P16) |

**The ladder's load-bearing choice:** rung 2 is free **and complete**. The recognition moment is given away, and the memory behind it is not throttled. What is sold is not access — it is **direction**.

---

## 17. Activation strategy

### Definitions

| Term | Definition | Why this threshold |
|---|---|---|
| **First Value** | Received a usable step in the first session | The relief moment (T1) |
| **In rhythm** | Received a personalised Seed | Proves Knowledge is sufficient to be personal |
| **Activated** | Completed **3 Seed→Harvest pairs** | The proof moment (T3) and the Mirror gate |
| **Habituated** | ≥8 Harvests in the first 14 days | The loop has become automatic |

*(v1 defined Activated as "3 nights logged AND received First Mirror". v2 requires the linked pair, since an unlinked evening log no longer exists.)*

### Activation funnel with targets

| Step | Target | Current baseline |
|---|---|---|
| `/start` → first message | ≥80% | 62.6% (understated — counter bug) |
| First message → First Value | ≥90% | Not measured |
| First Value → in rhythm | ≥70% | **New — does not exist yet** |
| In rhythm → 1 Harvest | ≥60% | Not measured |
| 1 → 3 pairs (**Activated**) | ≥50% | Not measured |

### The activation interventions

1. **Delete the onboarding form.** 94.1% abandonment. Fields are inferred from conversation.
2. **Delete the country gate on usage.** 48.4% blocked at the door (P8).
3. **Fire the First Mirror.** Built, data-gated, fired zero times.
4. **Start the daily rhythm** *(new)*. The only item requiring genuine new product — and the one that addresses Habit, the force v1 left unanswered.

---

## 18. Habit loop

Two linked triggers per day, not one.

```
┌─ MORNING ─────────────────────────────────────────────────┐
│  TRIGGER   Seed arrives, timed before the situation       │
│  ACTION    Read. Optionally try one small thing.          │
│  REWARD    Being known — it names the child and the       │
│            actual problem, not parenting in general       │
└──────────────────────────┬────────────────────────────────┘
                           │  the same subject, all day
                           ▼
┌─ EVENING ─────────────────────────────────────────────────┐
│  TRIGGER   Harvest arrives, after the window closes       │
│  ACTION    One tap                                        │
│  REWARD    Variable:                                      │
│              • recognition ("هذه خطوة حقيقية")             │
│              • a new angle for tomorrow                   │
│              • a pattern noticed                          │
│              • occasionally the Mirror — the jackpot      │
└──────────────────────────┬────────────────────────────────┘
                           ▼
┌─ INVESTMENT ──────────────────────────────────────────────┐
│  Each answered Harvest sharpens tomorrow's Seed.          │
│  The parent is training something about their own child.  │
│  → loads tomorrow's trigger                               │
└───────────────────────────────────────────────────────────┘
```

**Why the two-trigger structure is stronger than v1's one.** A single evening ping asks for effort and returns acknowledgement. The pair **gives first** (a suggestion, in the morning) and asks second (how did it go). The morning message earns the evening tap. v1 asked without giving, once a day, and called it a habit loop.

**Why investment is the strategic core:** answered Harvests are not telemetry — they are the parent's accumulating knowledge of their own child. Leaving costs them something real, which is honest rather than manipulative.

**Anti-patterns explicitly banned:** streak-shaming, guilt-based re-engagement, notification escalation, "you haven't logged in 3 days!", and — new — **sending a Seed when there is nothing personal to say**, which converts the loop into noise and is the fastest way to lose it.

---

## 19. Growth loop

```
   Content naming a parenting pain  (525,682 reach, 20,991 shares)
                    │
                    ▼
   Moment-framed CTA  (the bridge — currently 0.7%)
                    │
                    ▼
   Value in < 60 seconds
                    │
                    ▼
   Daily rhythm → recognition → retention
                    │
                    ▼
   Parent tells another parent
   AND generates new content raw material
                    │
                    └──► feeds content ──┘
```

**The compounding asset:** every conversation teaches which pains are most common in which countries, which informs the next post. The product feeds the content engine that feeds the product. That is a genuine loop, not a funnel.

**Current break point:** the bridge. 0.7% of the audience has reached the bot. Fixing it is a copy change on existing high-performing posts.

---

## 20. Referral loop

### The constraint discovered in the evidence

The obvious mechanic — "share your progress" — is **wrong for this audience.** Sharing "3 of 5 nights calm" also discloses two hard nights. In a shame-loaded context that is a disincentive.

**But** parents already share at enormous volume: 20,991 shares on one post. They share **the insight, not themselves.**

### The mechanic — share the insight, never the scorecard

```
┌──────────────────────────────┐
│  الرفض عند النوم              │
│  ليس عناداً —                 │
│  هو خوف من الانفصال في الظلام.│
│                              │
│              آدم 🌿           │
└──────────────────────────────┘
```

Shared because it makes the parent look insightful, not because it exposes their struggle.

**Second mechanic — the direct pass:**
```
ADAM: أحدٌ قريب يمرّ بهذا الآن؟
      هذا له. سأكون معه كما كنت هنا. [مشاركة]
```

**No incentive, no reward, no referral code.** Paying for referrals in a trust-based, shame-adjacent product corrupts the motive. Offered once, at a moment of pride, never repeated.

**Success measure:** ≥15% of month-completers share; referred share of new signups ≥10% by month 3.

---

## 21. Monetization strategy

### Model: **Free companionship + Paid direction**

| Layer | What it is | Price | Available |
|---|---|---|---|
| **Free** | Unlimited conversation, voice, the Moment, the daily rhythm, full memory, the First Mirror, crisis presence | **Free forever** | **Every country** |
| **Paid** | A month aimed at one agreed change, with someone watching whether it happens | **$10 equivalent** | Where a rail exists |
| **Continuation** | The next month | **~$6–7 equivalent** | After a completed month |

**Note the shape (D-G).** The free row is longer than the paid row. That is correct and deliberate: **free is where the features are; paid is where the direction is.**

### 21.1 How the paid layer is described (D-H)

**Never in terms of contents. Always in terms of the state the parent arrives at.**

| Never say | Say |
|---|---|
| "ذاكرة كاملة عن طفلك" | "تعرف ما يهدّئ يوسف قبل أن يبدأ" |
| "تقرير في نهاية الشهر" | "بيت تنتهي فيه الليلة دون معركة" |
| "خطة يومية مفصّلة" | "لم تعد تخترع حلاً كل ليلة" |
| "متابعة وتتبّع للتقدّم" | "تعرف أن ما تفعله يعمل" |
| "مبادرة من آدم" | "لست وحدك في هذا" |

Left column: five technologies. Right column: five ways a life is different. **The left column is what v1 shipped.**

### 21.2 Why one-time, not subscription

1. **It matches the actual rail.** Payment is collected manually. A "subscription" collected by manual bank transfer is a one-time purchase in a costume — and an entire workflow existed solely to manage that costume. It has been deleted.
2. **It removes renewal anxiety** — directly attacks the unaddressed Anxiety force (§7).
3. **It makes the end-of-month reflection the moment of decision**, triggered by demonstrated change rather than a calendar date.
4. **It resolves the betrayal.** When the month ends, nothing is confiscated; the free rhythm continues identically. Directly answers *"انت طلعت بفلوس اخص عليك"*.

**Evidence that reason 1 is not theoretical.** The renewal machinery was found still running on 2026-07-29. That morning it had sent a real parent — last active a month earlier — a request for 2,300 DZD to a personal bank account, quoting Algerian pricing because her country field was empty, and asserting a "real turning point" assembled from empty fields. **That is the subscription costume failing in production.**

### 21.3 What is never monetised

- The moment of crisis (P1)
- Any conversation in X1 (P1, F12)
- Access to ADAM at all, in any country (P8)
- Memory, or its depth (P15, D-G)
- Emotional availability

---

## 22. Pricing strategy

| Offer | Price | Basis |
|---|---|---|
| **First month** | $10 equivalent — 490 EGP / 110 MAD / DZD **pending confirmation** | The only real datapoint is a completed 490 EGP payment |
| **Continuation** | ~$6–7 equivalent | Rewards demonstrated progress |
| **Free** | Free, permanently | Ethical floor + acquisition engine |

**On the DZD figure.** Legacy code used 2,300 DZD, materially above $10 at the official rate. Since the pricing table is now the single sanctioned source, the intended figure needs confirming rather than inheriting. Flagged as §32 D9.

### Pricing rules (non-negotiable)

1. **Price is injected from configuration.** The agent must never generate a number. *(It invented "150 EGP" against a real 490 — a broken promise, trivially preventable.)*
2. **One published price per market.** Never improvised, never negotiated in conversation.
3. **Keep the 30-day guarantee.** Strongest available Anxiety-reducer, near-zero cost at these volumes.
4. **Never discount to a parent in distress.** Blurring this teaches parents to negotiate while suffering, which is corrosive for both sides.

### On the affordability objection

*"صراحة ما بقدر على الاشتراك"* is real and will not go away. **The answer is not a lower price — it is that nobody ever needs to pay to be helped tonight, or to be accompanied daily.** Under D-G the free tier answers affordability completely. The paid month is for parents ready to aim at one change, and that will always be a minority. It only needs to be a viable minority.

---

## 23. Success metrics

```
NORTH STAR: Accompanied Parents
(parents who completed ≥3 Seed→Harvest pairs in the trailing 7 days)
   │
   ├── ACQUISITION
   │     Audience→bot conversion        ≥2%    (now 0.7%)
   │     Unserved-country share         ≥40%
   │
   ├── ACTIVATION
   │     /start → first message         ≥80%
   │     First message → First Value    ≥90%
   │     First Value → in rhythm        ≥70%
   │     1 → 3 pairs                    ≥50%
   │
   ├── THE RHYTHM  (new — the retention engine)
   │     Seed→Harvest completion        ≥50%
   │     Seeds grounded in Knowledge     100%  (hard floor)
   │     Pairs / parent / week          ≥4
   │     Harvest-ignored streaks        watch
   │
   ├── TRANSFORMATION  (the real output)
   │     Calm ratio, week 1 → week 4
   │     Situation identified           ≥60% of S4
   │     Step-success rate trend
   │
   ├── MONETIZATION
   │     (discovery metrics deliberately absent — D-I)
   │     Claim → confirmed              ≥95%
   │     Month completion               ≥70%
   │     Continuation                   ≥25%
   │
   └── TRUST  (guardrails)
         Crisis flags → human < 24h     100%
         Commercial messages in X1      0     (hard zero)
         Seeds sent in X1               0     (hard zero)
         Ungrounded Seeds               0     (hard zero)
         Gendered strings to unknown    0     (hard zero)
         Block/mute rate                <2%
         Hallucinated price incidents   0     (hard zero)
```

**Note on the MONETIZATION branch.** v1 had `Mirror → ask opened ≥30%` and `Ask → payment claimed ≥20%`. Both presume the discovery mechanism D-I defers. They are **removed rather than retargeted**, because a metric for an undesigned system is an invitation to design it.

### Guardrail metrics — a breach halts the roadmap

| Guardrail | Threshold | Rationale |
|---|---|---|
| Commercial message during crisis | **0, always** | P1 |
| Seed or Harvest sent during crisis | **0, always** | §10.2 |
| Ungrounded proactive message | **0** | P11 |
| Gendered string to unknown-gender parent | **0** | P12 |
| Crisis flag unreviewed > 24h | **0** | Duty of care |
| Hallucinated price | **0** | Trust is the moat |
| Block/mute rate | **< 2%** | Early signal of over-messaging |
| Median reply latency | **< 15s** | The moment doesn't wait |

---

## 24. North Star Metric

> ## Accompanied Parents
> **The number of parents who completed ≥3 Seed→Harvest pairs in the trailing 7 days.**

### Why this metric

| Criterion | Assessment |
|---|---|
| **Reflects delivered value** | ✅ A completed pair means ADAM said something specific enough to act on, and the parent came back to close it |
| **Leads revenue** | ✅ 3 pairs is the Mirror gate, and the Mirror is what makes ADAM feel like it knows the child |
| **Team can move it** | ✅ Directly improved by Seed quality, timing correctness, and memory depth |
| **Hard to game without real value** | ✅ Requires ADAM to be specific *and* the parent to return voluntarily |
| **Honest** | ✅ Rises only if the rhythm is genuinely wanted |

**Why the pair and not the night.** v1's *Tracked Parents* counted logged nights. A logged night can be produced by a generic ping — it measures the parent's compliance. A completed **pair** measures both sides: it cannot rise unless ADAM's morning message was worth answering. **It is the only metric here that holds us accountable rather than the parent.**

### Rejected alternatives

| Candidate | Why rejected |
|---|---|
| Total messages | Rewards verbosity; AI verbosity is already 363 vs 53 chars |
| Weekly active users | Doesn't distinguish a passer-by from a parent doing the work |
| Revenue | Lags too far; n=1 payment gives no signal |
| Calm-night ratio | An *outcome* we must not incentivise gaming — no parent should feel pressure to report calm |
| Nights logged (v1) | Measures compliance, not whether we were worth answering |
| Seeds sent | Pure output. Trivially gamed by sending more |

**Guardrail:** counts *participation*, deliberately not *calm nights*. Optimising for reported calm would pressure parents to misreport, corrupting the data and the trust.

---

## 25. Product analytics events

Every event carries `parent_id`, `timestamp`, `state`, `country`, `tier`, **`gender_form_used`**.

### Lifecycle
| Event | Properties |
|---|---|
| `parent_started` | source, campaign |
| `parent_state_changed` | from, to, reason |
| `parent_dormant` | days_inactive, last_state |
| `parent_returned` | days_away |

### Conversation
| Event | Properties |
|---|---|
| `message_received` | channel(text/voice), char_count, is_first |
| `first_value_delivered` | seconds_since_start |
| `crisis_detected` | category, confidence |
| `crisis_reviewed` | hours_to_review, outcome |

### The rhythm (**new**)
| Event | Properties | Answers |
|---|---|---|
| `seed_sent` | situation, knowledge_sources[], scheduled_offset, local_hour | Is it grounded, and on time? |
| `seed_skipped` | reason(no_knowledge / crisis / paused / quiet_hours) | **Why are we silent?** |
| `harvest_sent` | seed_id, local_hour, after_window | Timed correctly? |
| `harvest_answered` | seed_id, outcome, seconds_to_answer | Feeds the North Star |
| `harvest_ignored` | consecutive_count | Over-messaging? |
| `pair_completed` | day_index | **The North Star event** |
| `situation_identified` | label, time_window, days_to_identify | How fast do we get useful? |

**`seed_skipped` matters as much as `seed_sent`.** Under P11, silence is correct behaviour when there is nothing personal to say — so we must be able to distinguish *principled silence* from *a broken scheduler*.

### Proof
| Event | Properties |
|---|---|
| `mirror_generated` | kind, pairs_included, calm_ratio |
| `mirror_delivered` | kind |
| `mirror_reacted` | reaction_type |

### Commerce
| Event | Properties |
|---|---|
| `companionship_asked_about` | trigger(**user_initiated only**) |
| `payment_claimed` | amount, currency, method |
| `payment_confirmed` | hours_to_confirm |
| `month_started` / `month_completed` | pairs_completed, calm_delta |
| `continuation_purchased` | — |
| `payment_blocked_country` | country |

### Quality guardrails (**new**)
| Event | Properties | Answers |
|---|---|---|
| `ungrounded_send_blocked` | message_type, missing_knowledge | Is P11 holding? |
| `gender_form_fallback` | string_id | Which strings lack all three forms? |

**Explicitly not tracked:** message content, anything from an X1 conversation, any field letting an operator browse disclosures casually. Analytics gets counts and categories, never intimate text.

---

## 26. Experiment roadmap

Ordered by information value per day of effort.

| # | Experiment | Hypothesis | Kill signal | Effort |
|---|---|---|---|---|
| **E1** | **Seed grounding test** | A memory-grounded Seed outperforms a generic tip | Grounded ≤ generic on Harvest rate | Low — same pipeline, two arms |
| **E2** | **Fire the First Mirror** | Recognition drives retention | No retention lift at day 14 | Switch-on |
| **E3** | **Delete onboarding** | The form is pure loss | Extraction materially worse | Deletion |
| **E4** | **Free-everywhere** | Serving all countries grows more than it costs | Cost outruns signal | Deletion |
| **E5** | **Content bridge** | Moment-framed CTA beats product CTA | No lift over 0.7% | Copy only |
| **E6** | **Timing test** | Situation-relative beats fixed-hour | No difference in Harvest rate | Config |
| **E7** | **Gulf concierge test** | Waitlisted high-ATP parents will pay | 0/10 pay | Days, no engineering |
| **E8** | **Voice input** | Voice increases depth and activation | No lift | Medium |
| **E9** | **Price test** | $10 is right for EG | Both arms <2% | Config |

**E1 is the most important experiment in this document.** The entire v2 thesis is that a *grounded* Seed is categorically different from a parenting tip. If a generic tip performs equally well, then P11 and D-C are wrong, memory is not the heart of the product, and the free rhythm is a content channel rather than a relationship. **That is worth knowing before building the memory layer F6 assumes.**

**E6 is nearly free and tests D-E directly** — fixed-hour vs situation-relative, same content.

**Removed from v1:** *"E8 Pride vs guilt copy at the ask"* — the ask is deferred (D-I), so there is nothing to split-test.

---

## 27. Product roadmap

### NOW — weeks 0–4

**Week 0 — nothing ships until these are done**
1. Rotate exposed credentials *(service-role key and bot tokens sit in plaintext in workflow JSON)*
2. Restore the dashboard source *(`lib/` and `components/` were never committed; the dashboard cannot build)*
3. Confirm the pricing table, DZD included (§32 D9)

**Weeks 1–2 — deletions and switch-ons (no new product)**
4. Remove the country gate on usage (F13)
5. Remove the onboarding form (§17)
6. Activate the timezone-correct sender (F7); retire the legacy one
7. Fire the First Mirror (F5)
8. Content→product bridge on the top 3 posts (F14)
9. **Gender-neutral rewrite of every existing user-facing string** (F15) — including the Heart Writer prompt that hardcodes *"أمٍّ"*

**Weeks 3–4 — the new core**
10. The Knowledge layer (F6) — the precondition for everything below
11. The Seed (F2), grounded, with `seed_skipped` instrumented from day one
12. The Harvest (F3), linked to its Seed
13. The timing engine (F7) with situation windows
14. Voice input (F4)
15. Crisis detection + human queue (F12) — **gated on §32 D1**
16. **E1 runs from the first day the Seed exists**

**Decision gate at week 4:** grounded Seeds beat generic on Harvest rate, **and** ≥50% of parents in rhythm complete 3 pairs → proceed. If grounded is not better, stop and revisit §1 — because the memory thesis *is* the product thesis.

### NEXT — months 2–3

| Item | Rationale |
|---|---|
| Weekly Mirror + end of month (F9, F10) | Completes the paid experience |
| **Answer §32 D7, then design discovery** | The paid tier is unreachable until this exists |
| Situation depth (F8) | Multi-week pattern tracking |
| Continuation offer | Real retention test |
| Speech/development track | #3 theme (98 messages), entirely unserved |
| Referral: shareable insight cards (§20) | Growth loop closes |
| Operator console v1 | Founder is currently the bottleneck |
| Global payment rail | Unlocks 23,697 |

### LATER — months 4+

| Item | Precondition |
|---|---|
| Peer presence / community | Only after retention is proven; large build, moderation risk |
| Multi-child support | Only when data shows demand — currently 3 children rows |
| Collective intelligence | A genuine long-term moat; needs privacy design first |
| Additional markets | Requires a rail; E7 evidence justifies |
| Voice output | Only if tested and it does not unsettle (§14.1) |

---

## 28. Risks and assumptions

### Assumptions requiring validation, ranked by damage-if-wrong

| # | Assumption | Test | Damage if wrong |
|---|---|---|---|
| **A1** | **A grounded Seed is categorically better than a generic tip** | E1 | **Fatal** — the v2 thesis, and the reason memory is the product |
| **A2** | **Parents want a daily rhythm rather than an on-call helper** | E1 + Harvest rates | **Fatal** — D-D would be wrong |
| **A3** | Parents pay for direction, not access | Continuation rate | **Fatal** — the business model |
| **A4** | Situation-relative timing beats a fixed hour | E6 | Medium — recoverable by config |
| **A5** | Waitlisted (Gulf) parents will pay | E7 | High — the growth thesis |
| **A6** | Free-everywhere costs less than it returns | E4 | High — unit economics |
| **A7** | $10 is right for this audience | E9 | Medium — recoverable |
| **A8** | Voice materially lifts engagement | E8 | Low |
| **A9** | Removing onboarding doesn't degrade personalisation | E3 | Low — reversible |

**A1 and A2 are new and both fatal.** v1's fatal assumption was that visible progress converts better than memory. v2's is stronger and cheaper to test: that **specificity** is what makes a proactive message welcome. E1 tests it directly.

### Risk register

| # | Risk | Severity | Mitigation |
|---|---|---|---|
| **R1** | **Safeguarding** — parents disclose abuse and their own violence with no escalation path | 🔴 Critical | F12 + human protocol **before scale**. §32 D1 |
| **R2** | **The Seed becomes a tip library** — the path of least resistance whenever Knowledge is thin | 🔴 Critical | P11 as a hard block, `ungrounded_send_blocked` metric, 100% floor. **Prefer silence** |
| **R3** | **Two proactive messages a day is too many** | 🟠 High | Ceiling of 2 (§13.3); `harvest_ignored` streaks; decay to weekly then stop |
| **R4** | **Exposed credentials** — plaintext service-role key and bot tokens in workflow JSON | 🟠 High | Week 0, item 1 |
| **R5** | **The paid tier is unreachable** — no discovery mechanism exists, by design | 🟠 High | Accepted deliberately. **Revenue stays ~0 until D7 is answered. This is a choice, not an oversight** |
| **R6** | **Free-everywhere burns cash** | 🟠 High | Weekly cost/parent monitoring; generous but finite fair-use |
| **R7** | **Founder is the payment rail** | 🟠 High | Fine now; binding at ~50 customers |
| **R8** | **Advice quality in violence-adjacent situations** | 🟠 High | Weekly human review sample; hardened refusals |
| **R9** | **Gendered copy leaks to fathers** | 🟡 Medium | Three-form requirement (§8.2); `gender_form_fallback` metric |
| **R10** | **Retention unproven** — oldest cohort ~4 weeks | 🟡 Medium | The rhythm *is* the test |
| **R11** | **Trust collapse from one bad interaction** in a shame-loaded context | 🟡 Medium | The no-blame discipline is excellent — protect it absolutely |
| **R12** | **Voice transcription fails on dialect** | 🟡 Medium | Confidence threshold + text fallback |

**R2 is the risk most likely to actually happen.** When Knowledge is thin, generating a plausible generic tip is easy and sending nothing feels like failure. It is not: under P11, silence is correct. That is why the floor is a hard 100% and why `seed_skipped` carries reasons.

**R5 is worth reading twice.** Deferring discovery means revenue stays near zero. That is the direct consequence of D-I, accepted knowingly.

---

## 29. Features to remove / keep / build

### REMOVE

| Feature | Why |
|---|---|
| Country gate on **usage** | Discards half of demand for zero gain |
| 6-step onboarding form | Asks before giving; 94.1% abandonment |
| The Judge, Silent Seller, Renewal Guard | Scoring and pushing an unwanted pitch. 8 offers → 0 clicks. *Already archived 2026-07-29* |
| "Subscription" framing | Doesn't match a manual rail |
| Selling memory / reports / tracking as the benefit | D-H. Nobody buys machinery |
| **Feature-list ask copy** *(new)* | v1 §11.5 was a four-bullet list — the error v1 itself diagnosed |
| **The fixed 21:00 send hour** *(new)* | D-E. Asks about bedtime before bedtime |
| **The mother-only default** *(new)* | D-A. 18.5% of the audience is male |
| **The word الاحتواء in any user-facing string** *(new)* | D-B |
| **Any "quiet affordance" offer mechanism** *(new)* | D-I. Deferred, not redesigned |
| `main_pain` fixed 8-value enum | Missed the #3 theme (98 messages) |
| Uncapped reactivation | Re-engaging someone who left is how you get muted |
| Hardcoded credentials in nodes | Bypasses RLS on intimate data |

### KEEP (and protect)

| Feature | Why it must not be touched |
|---|---|
| **The no-blame prompt discipline** | *"هي متعبة لا مذنبة"* — this is the moat |
| **Heart Writer safety rule** | *"الذاكرة الناقصة أرحم ألف مرة من الذاكرة التي تجرح"* — exemplary |
| **2–3 line response constraint** | Correctly matched to an exhausted reader |
| **Full prescription, never withheld** | *"الحبس مقابل الدفع هو أكبر قاتل للقيمة"* |
| **One-tap answering** | The habit engine |
| **Show-don't-announce memory** | Announcing memory reads as surveillance |
| **Ban on scarcity and urgency** | Incompatible with the trust position |
| **The Mirror's structural ban on prices** | Enforced by constraint, not wording |
| **Provenance-based memory redaction** | The only safe rule for Arabic free text |
| **Brand name and identity** | 41,100 followers; 525k-reach proof |

### BUILD

| Feature | Priority | Ref |
|---|---|---|
| Gender-neutral content system | **NOW** | F15 |
| Knowledge layer | **NOW** | F6 |
| The Seed | **NOW** | F2 |
| The Harvest | **NOW** | F3 |
| Timing engine | **NOW** | F7 |
| First Mirror **firing** | NOW | F5 |
| Voice input | NOW | F4 |
| Crisis detection + queue | NOW *(gated on D1)* | F12 |
| Free-everywhere | NOW | F13 |
| Content bridge | NOW | F14 |
| Weekly Mirror | NEXT | F9 |
| End-of-month | NEXT | F10 |
| Situation depth | NEXT | F8 |
| Operator console | NEXT | F11 |
| **Discovery of full companionship** | **BLOCKED** | §32 D7 |

---

## 30. Decisions challenged and rejected

| Considered | Rejected because |
|---|---|
| **Keep the subscription model** | Manual collection makes every renewal a friction event. The machine built to fight that friction was found dunning a dormant parent |
| **Lower the price to ~$3** | The only real datapoint is a completed $10-equivalent payment. Free answers affordability; discounting forfeits the one proof |
| **Freemium with message caps** | Paywalls the crisis. Violates P1 |
| **Tier memory depth (free = 7 days)** *(new)* | **Deliberately crippling the product to create a reason to pay.** Violates P15 and D-G. Also self-defeating: shallow memory makes the free Seed generic, which breaks P11 |
| **Send a generic tip when memory is thin** *(new)* | Converts the rhythm into a content channel and destroys the only differentiator (P11). Silence is correct |
| **Ask gender at onboarding** *(new)* | Violates P2. Gender is inferable from the parent's own grammar; the neutral default costs nothing while unknown |
| **Design discovery now anyway** *(new)* | Explicitly deferred (D-I). Inventing a mechanism the founder has not decided on is how v1 ended up with a "quiet affordance" nobody asked for |
| **Build a mobile app** | Adds a surface with no evidenced job |
| **Sell a course** | Competes with our own free content; serves *knowing*, which is not the gap |
| **Ads** | Destroys the no-judgement trust that is the moat |
| **B2B / schools / clinics** | Almost no evidence in 2,086 messages |
| **Community in MVP** | Real job, large build, moderation risk in a shame-loaded context |
| **Gamified streaks** | Streak-shaming a parent after a hard night violates P3 catastrophically |
| **Incentivised referral** | Corrupts the motive in a trust-based product |
| **Child-behaviour tracking as the hero** | Points the product at the child; the job is the parent's |
| **Rename the brand** | 41,100 followers and a 525k-reach proof point |

---

## 31. Change log v1 → v2

Every section that changed, what changed, and which decision drove it.

| § | Section | What changed | Driver |
|---|---|---|---|
| **0** | *What changed* | **New.** The eleven decisions, stated as overrides | D-K |
| **1** | Product vision | One-year vision no longer promises "a report" — it promises a quieter home | D-H |
| **2** | Principles | **Six new: P11 memory is the product · P12 both parents · P13 daily rhythm · P14 timing follows the event · P15 free never crippled · P16 sell the destination.** P4 broadened to "fewest taps". P3 de-gendered | D-A, C, D, E, G, H, J |
| **3** | Positioning + voice | **New §3.5** the gender-free Arabic technique (nominal sentences, first-person plural, buttons, impersonal). **New §3.6** the two lexicons — الاحتواء and six other internal terms banned from user strings. Voice table gains "specific to this family". Moment-of-use is now daily | D-A, D-B, D-C |
| **4** | Value proposition | Primary line rewritten gender-free and outcome-led. Audience table gains "in the rhythm"; "considering" row emptied and marked deferred | D-A, D-H, D-I |
| **5** | Transformation | "bad mother" → "bad parent"; "I have proof I'm becoming calmer" → "the house is quieter, and I did that". T3 renamed *First recognition* | D-A, D-H |
| **6** | Personas | **Persona A is now "The Exhausted Parent"** with mother/father as sub-variants A1/A2. v1's separate father persona deleted — a separate persona is exactly what produced a mother-default product with a father exception | D-A |
| **7** | JTBD | **New fourth dimension: Relational** — "someone in this with me who doesn't need re-explaining", evidenced by *"خسارة انك لا تذكرني"*. The Habit force is now answered by the rhythm | D-C, D-D |
| **8** | Information architecture | **New entities `Knowledge` and `Day` (Seed+Harvest as one atomic unit).** `Flashpoint`→`Situation` with a time window; `Night`→`Day`; `Journey`→`Chapter`. **Three new integrity rules** making P11, D-D and D-A enforceable in data rather than prompts. Corrected v1's claim that `weekly_plans`/`survey_responses` were dead | D-C, D-D, D-E, D-A |
| **9** | User journey | Redrawn. The free tier is now a **loop that runs whether or not anything went wrong**, not a corridor. Discovery step replaced by an explicit TODO block | D-D, D-I |
| **10** | User states | S3 `logging`→`in_rhythm`. **S2's exit now requires enough Knowledge to ground a Seed.** S5 emptied — nothing may enter it. **X1 now suspends the rhythm**, not just commercial messaging | D-C, D-D, D-I |
| **11** | Conversation flows | **Every Arabic string rewritten gender-free.** **New §11.3 The Seed** and **§11.4 The Harvest**, replacing v1's nightly check-in. §11.8 the ask **completely rewritten in outcome language**, with v1's four-bullet feature list quoted as the error. §11.2 loses its feminine closing hook. §11.9 notes الاحتواء is internal-only | D-A, D-B, D-D, D-H, D-I |
| **12** | **The memory model** | **New section.** What Knowledge is built from; what each message type must read before sending; the show-don't-announce table; **the test — could this exact message go to another family? If yes, it does not send** | D-C, D-F |
| **13** | **The timing model** | **New section.** Situation time windows, Seed before / Harvest after, six hard rules including quiet hours and the two-message ceiling | D-E |
| **14** | **Telegram-first audit** | **New section.** Every interaction audited for effort saved; capability inventory (menu, pinned message, reactions, reply-threading); explicit list of capabilities refused | D-J |
| **15** | Feature map | **F2 Seed, F3 Harvest, F7 timing engine, F15 gender-neutral content — all new.** F6 memory elevated from "child identity" to the substrate. F5 Mirror measured by **retention, not ask-opens**. **F16 discovery struck through as TODO** | D-C, D-D, D-E, D-A, D-I |
| **16** | Value ladder | **New §16.1: the free/paid difference is the level of companionship, not the amount of memory.** Table shows memory as *identical* in both tiers. Four framings explicitly banned | D-G |
| **17** | Activation | "Activated" = 3 **pairs**, not 3 nights. New funnel step "First Value → in rhythm". Fourth intervention: start the rhythm | D-D |
| **18** | Habit loop | Rebuilt around **two linked triggers** — morning gives, evening asks — instead of one evening ping. New anti-pattern: sending a Seed with nothing personal to say | D-D, D-C |
| **20** | Referral | Direct-pass copy de-gendered | D-A |
| **21** | Monetization | Model renamed **Free companionship + Paid direction**. **New §21.1: a five-row never-say/say table.** Adds the live evidence of the renewal machinery dunning a dormant parent | D-G, D-H |
| **22** | Pricing | DZD figure flagged as needing confirmation rather than inherited from 2,300 | — |
| **23** | Metrics | **New RHYTHM branch.** Monetization discovery metrics **removed, not retargeted**. Four new hard-zero guardrails: Seeds in crisis, ungrounded Seeds, gendered strings, plus existing | D-D, D-I, D-A, D-C |
| **24** | North Star | **Tracked Parents → Accompanied Parents** (≥3 completed pairs). Rationale: a logged night measures the parent's compliance; a completed pair measures whether *we* were worth answering | D-D |
| **25** | Analytics events | **New rhythm block** including `seed_skipped` with reasons — so principled silence is distinguishable from a broken scheduler. New quality-guardrail events. All events carry `gender_form_used` | D-C, D-D, D-A |
| **26** | Experiments | **E1 is now Seed grounding — the most important experiment in the document.** New E6 timing test. v1's "pride vs guilt at the ask" removed, since the ask is deferred | D-C, D-E, D-I |
| **27** | Roadmap | Week 0 adds restoring the dashboard source and confirming pricing. Weeks 1–2 add the gender-neutral rewrite. Weeks 3–4 are Knowledge → Seed → Harvest → timing. **Decision gate is now: do grounded Seeds beat generic?** | D-A, D-C, D-D, D-E |
| **28** | Risks | **A1/A2 new, both fatal.** **R2 (the Seed becomes a tip library) is the most likely risk to materialise.** **R5 states plainly that revenue stays ~0 until D7 is answered** | D-C, D-D, D-I |
| **29** | Remove/keep/build | Five new removals: feature-list copy, the fixed 21:00 hour, the mother-only default, الاحتواء in user strings, any quiet-affordance mechanism | D-A, B, E, H, I |
| **30** | Rejected | **Four new rejections**, including *tier memory depth* and *send a generic tip when memory is thin* — the two shortcuts most likely to be proposed later | D-F, D-G, D-I |
| **32** | Open decisions | **Three new: D7 discovery, D8 month-vs-chapter, D9 the DZD figure** | D-I |

**Sections unchanged in substance:** §19 growth loop.

---

## 32. Open decisions requiring founder input

These are **not** product decisions and I have deliberately not made them.

| # | Decision | Why it's yours | Blocking |
|---|---|---|---|
| **D1** | **Crisis escalation destination.** When a parent discloses abuse, suicidal ideation, or their own violence — what happens? A human replies? A referral to a named local service? A stated boundary? | Duty of care, legal exposure, your capacity. No defensible automated answer exists | **Blocks F12 and therefore scale** |
| **D2** | **Who staffs the crisis queue, within what SLA?** | Depends on your team and hours | Blocks F12 |
| **D3** | **Fair-use ceiling for the free tier.** Unlimited is the principle; some finite ceiling is the reality | Depends on your cost tolerance | Blocks F13 rollout |
| **D4** | **Which market to open first** if E7 succeeds — Saudi (highest ATP) or Iraq (largest volume) | Depends on access to a payment agent | Blocks post-E7 planning |
| **D5** | **What happens to the existing 291 parents and 4,212 conversations** on migration — carry memory forward, or fresh start with continuity messaging? | Relationship decision, not technical | Blocks week 1 |
| **D6** | **Whether ADAM ever says it is an AI.** One parent asked directly: *"هل انت ذكاء اصطناعي مجاني ام مدفوع"* | Positioning and ethics call | Should be settled before scale |
| **D7** | **How a parent ever learns full companionship exists.** *(new — D-I)* No hint, no button, no timing, no mechanism is designed. Today only a direct question reaches it | You deferred this deliberately. Any mechanism I invent would be me deciding your commercial posture | **Blocks all revenue.** See R5 |
| **D8** | **Is the paid unit a month, or a chapter with an objective?** *(new)* The architecture describes a chapter with a measured objective and an ending. The price is quoted monthly. A month implies a renewing subscription; a chapter implies a result | It determines what is being promised, which is a positioning decision | Blocks §11.8 copy and §16 naming |
| **D9** | **Confirm the DZD price.** *(new)* Legacy code used 2,300 DZD, materially above $10 at the official rate | Pricing decision | Blocks week 0 |

**D1 remains the true blocker for scale. D7 is the true blocker for revenue.** They are different kinds of blocked: D1 is a duty-of-care limit on how far the product may grow; D7 is a deliberate choice to have no sales mechanism until you decide what it should be.

Everything else can proceed in parallel.

---

**End of blueprint v2. No implementation has begun. Awaiting your approval.**
