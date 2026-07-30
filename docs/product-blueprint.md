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
| **D-I** | ~~Discovery is deferred~~ → **RESOLVED 2026-07-30. The discovery architecture is §33: four doors, no push, no product name, trust measured before conversion** | v1 specified a "persistent quiet affordance" with a conversion target (F9) |
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
33. **The discovery architecture (resolves D7)**

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
┌─ DISCOVERY — four doors, no push (§33) ──────────────────────┐
│                                                              │
│  Door 0  another parent mentions it        (highest trust)    │
│  Door 1  bot menu + pinned line            (she looks)        │
│  Door 2  she asks — about scope, or for    ← PRIMARY PATH     │
│          work the free rhythm doesn't do                     │
│  Door 3  ADAM says its own method isn't    (≤2 per lifetime)  │
│          enough — free option offered first                  │
│                                                              │
│  It has no product name. It is described, never announced.   │
│  Test: remove the price — is the message still worth sending? │
└──────────────────────────┬───────────────────────────────────┘
                           ▼
┌─ A MONTH AIMED AT ONE CHANGE (paid) ─────────────────────────┐
│  Described in outcomes only (D-H). See §16.1 and §21.1.      │
│  Manual payment → operator confirms → begins                 │
│  The daily rhythm never pauses while payment is pending      │
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
| **S5** | `considering` | **A door opened (§33)** — she asked, or Door 3 fired | She asks to proceed, or declines, or says nothing | Answer once, in outcomes. Then silence. **The rhythm continues unchanged** |
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
2. **S5 may be entered only through a door in §33.** Doors 0–2 are parent-initiated. Door 3 is the sole system-initiated path and requires every condition in §33.4 — a scoring model that decides who is "ready" is explicitly banned, because that is what the Judge was. **A decline returns her to her prior state with nothing changed and no second mention, ever.**
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

### 11.8 When a door opens (D-H, and §33 for the architecture)

Four doors exist, and only one of them is ADAM speaking first. Full trigger rules, conditions and bans are in **§33**. This section is the copy.

#### 11.8a — She asks for work the free rhythm does not do · **the primary path**

This is the most valuable moment in the product, and the discipline is absolute: **answer the question completely and for free, first.**

```
PARENT: إزاي أعرف إن الليلة دي هتكون صعبة قبل ما تبدأ؟

ADAM:   من أيامكم: الليالي الصعبة كلها تقريباً كانت في أيام
        بلا قيلولة، أو بعد يوم خارج البيت.

        فعلياً: لو مرّ اليوم بلا نوم بعد الظهر — توقّعي ليلة أطول،
        وابدئي الروتين أبكر بعشرين دقيقة.

        هذا ما أعرفه، وهو لكِ.
```

**Nothing further.** She asked how to know; she now knows. The answer is complete and free.

Only if she then asks for the *doing* — *"تقدر تعمل ده كل يوم؟"* / *"ذكّرني بنفسك قبل الوقت الصعب"* — does ADAM name that the continuous version is a different arrangement:

```
ADAM: هذا ما أفعله في شهر موجَّه: أتكلم قبل الوقت الصعب لا بعده،
      كل يوم، من دون أن تسألي.

      الآن أنا معكِ حين تسألين — وهذا يبقى دائماً.
      {price} للشهر، مرة واحدة.
```

> **The line this depends on: knowing is always free; doing it every day is the paid thing.**
> No information is ever withheld. What costs money is labour, not knowledge. (§33.4)

#### 11.8b — She asks about scope

```
PARENT: آدم مجاني بالكامل؟

ADAM:   ما نحن فيه الآن مجاني ويبقى كذلك — الحديث في أي وقت،
        وفكرة كل صباح، وسؤال كل مساء.

        وهناك شهر موجَّه نحو حالة واحدة: بيت تنتهي فيه الليلة
        دون معركة، ومعرفة ما يهدّئ يوسف قبل أن يبدأ.
        {price} — مرة واحدة، لشهر.
        وإن لم يتغيّر شيء ملموس، الشهر التالي عليّ.
```

Then stop. No follow-up, no second mention.

#### 11.8c — Door 3, the honest limit

Copy and the nine required conditions are in **§33.4**. It fires at most twice in a parent's lifetime, never after a hard night, and always carries a free alternative as the default.

#### 11.8d — v1's version, kept on the page as the error to avoid

v1 specified the offer as this:

> أعرف طبع {child} وما يفجّر الموقف ومايهدّئه
> خطوة كل يوم مفصّلة عليه هو
> وفي نهاية الشهر، تقرير يريكِ بالضبط كم تغيّرتِ

Three bullets: **memory, a plan, a report.** That is a feature list — the precise error v1 §4 identified and then committed forty lines later. No parent wants a report. They want the night to end without a fight.

Two further defects in that copy, both now fixed:

- It named the thing **"المرافقة الكاملة"** — implying what she already has is partial, which contradicts P15. It has no name now (§33.6).
- It was **pushed** by a scoring model. Nothing pushes it now (§33).

**The test every commercial sentence must pass (P16):** does it answer *"what will my life be like in a month?"* — or *"what is included?"* If the second, it is rewritten or deleted.

**Any decline — a tap, a "not now", or silence:**
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
| **Ask whether ADAM can do more** | Type a question | **Bot menu entry, worded as her own question** (Door 1, §33.4) | Typing → 1 tap |
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

### F16 — The discovery architecture (**NEW**, resolves D7)

| | |
|---|---|
| **Why** | The paid layer is unreachable without it, and the old mechanism destroyed trust: 8 offers, 0 clicks, 4 of 8 never returned |
| **Evidence** | *"انت طلعت بفلوس اخص عليك"* — the observed reaction to being surprised by a price inside an emotional relationship |
| **Problem** | In a conversation there is no periphery to explore, so every discovery is an utterance. The problem is not *how to make it passive* but *which utterance a trustworthy companion would make anyway* |
| **Measure** | **Trust first:** block/mute rate after any door ≤ baseline; dormancy after a decline ≤ baseline. **Conversion is observed and never targeted** |

Four doors, specified in **§33**: another parent · the bot menu and pinned line · the parent asking (the primary path) · and, at most twice in a lifetime, ADAM saying its own method is not enough — with the free alternative offered first and set as the default.

**It has no product name** (§33.6), which makes a pricing page impossible to build and forces every description into outcome language.

**v1's F9 carried a conversion target** — *"≥10% of S4 parents open it unprompted."* A target on a discovery mechanism is an instruction to optimise it, and optimising discovery is how a companion becomes a funnel. **There is no conversion target anywhere in §33.**

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
   ├── DISCOVERY  (§33 — observed, never targeted)
   │     Door distribution 0/1/2a/2b/3  observe
   │     Door 2b per 100 in rhythm      observe  (demand signal)
   │     Conversion per door            observe  — ranked LAST, deliberately
   │
   ├── MONETIZATION
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
         Second mention after decline   0     (hard zero)
         Block/mute after any door      ≤ baseline
         Block/mute after Door 3        < 2× baseline, else Door 3 OFF
         Dormancy within 14d of decline ≤ baseline
         Block/mute rate overall        <2%
         Hallucinated price incidents   0     (hard zero)
```

**Note on the DISCOVERY branch (§33.8).** v1 had `Mirror → ask opened ≥30%` and `Ask → payment claimed ≥20%`. Both are **removed rather than retargeted.** Discovery now carries *no conversion target at all* — only observation — because a target on a discovery mechanism is a standing instruction to optimise it, and an optimised discovery mechanism is a funnel. The metrics that *are* targeted here are all counter-metrics: block rate, dormancy after a decline, Harvest rate after a decline. **Trust is the thing under test; conversion is merely reported.**

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
| **E10** | **Door 2b frequency** *(new)* | Parents spontaneously ask for continuous help often enough for Door 2 to carry the model | <2 occurrences per 100 parents in rhythm per month → Doors 0–2 cannot sustain revenue and §33.10's tension is worse than estimated | **Observation only — zero build** |
| **E11** | **Door 3 trust cost** *(new)* | Naming ADAM's own insufficiency does not damage the relationship | Block/mute > 2× baseline, or dormancy-after-decline above baseline → **Door 3 switched off permanently** | Low — instrument before enabling |

**E10 is free and should start the day the rhythm ships.** It requires no build: count how often parents ask for continuous help unprompted. That number determines whether Doors 0–2 can carry a business, and it is knowable *before* Door 3 is built. If it is high, Door 3 may never be needed — which would be the best possible outcome, since Door 3 is the only door that speaks first.

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
| **Discovery Doors 0–2 (§33)** | Menu entry, pinned line, and the Door 2 answers. **No new machinery — Door 2 is answering a question honestly** |
| **Door 3, only after E11 instrumentation** | The single system-initiated path. Built last, enabled last, killable on evidence |
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
| **R5** | **Low conversion by construction.** The better the free rhythm is, the less often a parent hits a wall that makes the fuller arrangement obvious | 🟠 High | **Accepted, not mitigated.** §33.10. Free quality and conversion are in direct tension and the non-negotiables resolve it toward free quality. Size the business for a small paying minority |
| **R13** | **Door 3 reads as "pay to fix your failure"** despite locating the fault in ADAM's method | 🟠 High | Never fires within 3 days of a hard night; free option first and default; E11 measures it; **kill switch at 2× baseline block rate** |
| **R14** | **Door 2b never happens often enough** to carry revenue, leaving Door 3 as the only real path — which is the fragile one | 🟠 High | E10 measures this for free before Door 3 is built. If Door 2b is rare, the honest response is to revisit §16.1's boundary, **not to make Door 3 pushier** |
| **R6** | **Free-everywhere burns cash** | 🟠 High | Weekly cost/parent monitoring; generous but finite fair-use |
| **R7** | **Founder is the payment rail** | 🟠 High | Fine now; binding at ~50 customers |
| **R8** | **Advice quality in violence-adjacent situations** | 🟠 High | Weekly human review sample; hardened refusals |
| **R9** | **Gendered copy leaks to fathers** | 🟡 Medium | Three-form requirement (§8.2); `gender_form_fallback` metric |
| **R10** | **Retention unproven** — oldest cohort ~4 weeks | 🟡 Medium | The rhythm *is* the test |
| **R11** | **Trust collapse from one bad interaction** in a shame-loaded context | 🟡 Medium | The no-blame discipline is excellent — protect it absolutely |
| **R12** | **Voice transcription fails on dialect** | 🟡 Medium | Confidence threshold + text fallback |

**R2 is the risk most likely to actually happen.** When Knowledge is thin, generating a plausible generic tip is easy and sending nothing feels like failure. It is not: under P11, silence is correct. That is why the floor is a hard 100% and why `seed_skipped` carries reasons.

**R5 is worth reading twice, and it is no longer about deferral.** Discovery now exists (§33), and conversion is *still* expected to be low — because a companion that genuinely works rarely produces the moment where a fuller arrangement becomes obvious. That is the honest price of P15 and D-G, and §33.10 states it without softening.

**R13 and R14 together define the one real decision left here.** If Door 2b is rare (E10) and Door 3 is costly (E11), then Doors 0–2 cannot fund the business, and the correct response is to revisit the free/paid boundary in §16.1 — a founder decision — rather than to add pressure to the doors, which is nobody's decision to make.

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
| **Any scoring model that decides who is "ready" to be offered** *(new)* | This is what the Judge was. 8 offers, 0 clicks. Banned in §33.5 |
| **The name "المرافقة الكاملة"** *(new)* | "Full" implies what she has is partial, contradicting P15. It has no name now (§33.6) |
| **Any launch announcement to the existing 291 parents** *(new)* | It would be exactly the surprise §33 exists to prevent |
| **Any conversion target on a discovery mechanism** *(new)* | A target is an instruction to optimise, and optimised discovery is a funnel (§33.8) |
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
| Discovery Doors 0–2 | NEXT | F16, §33 |
| Discovery Door 3 | NEXT — **built and enabled last**, after E11 | F16, §33.4 |

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
| **Pure passive discovery — "let them find it like an app feature"** *(new)* | **The founder's own framing, and it was adopted as the frame but rejected as the mechanism.** An app has periphery to wander into; a conversation has none — everything in it is foreground. So "passive" discovery in a chat is a category error. Telegram's menu and pinned message are the only real periphery, and they became Door 1 (§33.2) |
| **A "quiet affordance" with a conversion target** | v1's F9. A target on a discovery mechanism is a standing instruction to optimise it, and optimised discovery is a funnel (§33.8) |
| **Giving the paid arrangement a product name** *(new)* | Names belong to products that appeared. An extension of a relationship is described, in context, each time. Naming it also makes a pricing page buildable, and forces feature-list copy (§33.6) |
| **Door 3 firing on a timer or a message count** *(new)* | That is the Judge with different arithmetic. It fires only on evidence that ADAM's own method is failing this family (§33.4) |
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
| **32** | Open decisions | **Three new: D7 discovery, D8 month-vs-objective, D9 the DZD figure** | D-I |

### Revision 2026-07-30 — D7 resolved

| § | What changed | Why |
|---|---|---|
| **0** | D-I struck through and marked **RESOLVED → §33** | Approved |
| **9** | The TODO block in the journey replaced by the four doors | Integration |
| **10** | **S5 is now a real state** (`considering`), enterable only through a door. Rule 2 rewritten: a decline returns her unchanged with **no second mention ever** | The four-of-eight who never returned |
| **11.8** | **Split into 11.8a–d.** New 11.8a is the primary path — she asks for continuous help, ADAM answers the question fully and free *first*. New 11.8b scope answer. 11.8d keeps v1's feature-list offer on the page as the error to avoid | D-H + §33.4 |
| **15** | **F16 is now a real feature** with trust-first measures, replacing the struck-through TODO. v1's ≥10% conversion target named as the defect | §33.8 |
| **23** | **New DISCOVERY branch — observation only, no targets.** Four new guardrails including a Door 3 kill switch and dormancy-after-decline | §33.8 |
| **26** | **E10 Door 2b frequency** (free, zero build, start immediately) and **E11 Door 3 trust cost** (instrument before enabling) | R13, R14 |
| **27** | Doors 0–2 in NEXT; Door 3 built and enabled last | Risk ordering |
| **28** | **R5 rewritten** — no longer about deferral, now about low conversion being structural. **R13** Door 3 misreading, **R14** Door 2b too rare | §33.10 |
| **29** | Four new removals: scoring models, the name "المرافقة الكاملة", any launch announcement, any conversion target on discovery | §33.5 |
| **30** | **The founder's own "discover it like an app feature" framing recorded as adopted-as-frame, rejected-as-mechanism**, with the reason. Plus: no product name, no timer-based Door 3 | §33.2, §33.6 |
| **32** | D7 struck through. **D8 now carries a recommendation** — an objective with a month as its ceiling | — |
| **33** | **New section: the discovery architecture** | D7 |

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
| ~~D7~~ | ~~How a parent learns the fuller arrangement exists~~ **RESOLVED 2026-07-30 → §33.** Four doors; no push; no product name; trust measured before conversion; Door 3 killable on evidence | Approved in principle | **No longer blocking** |
| **D8** | **Is the paid unit a month, or an objective?** *(new)* The architecture describes an objective with an ending; the price is quoted monthly. A month implies a renewing subscription; an objective implies a result. **My recommendation: an objective, with a month as its ceiling** — "خمس ليالٍ هادئة من سبع، وسقفه شهر". It keeps the promise falsifiable, survives §33.6's no-name rule, and makes the end-of-month a verdict rather than an invoice. **But it means committing to an outcome you cannot fully control, which is a business-risk call, not a product one** | It determines what is promised | Blocks §11.8 copy |
| **D9** | **Confirm the DZD price.** *(new)* Legacy code used 2,300 DZD, materially above $10 at the official rate | Pricing decision | Blocks week 0 |

**D1 is now the only true blocker.** D7 is resolved in §33, so revenue is no longer architecturally unreachable — though §33.10 is explicit that it will be low by construction, and that is a consequence of your own non-negotiables rather than a flaw in the mechanism.

Everything else can proceed in parallel.

---

## 33. The discovery architecture (resolves D7)

**Status:** approved in principle 2026-07-30. This section replaces the deferral in D-I.

### 33.1 The problem, stated precisely

The old model produced *"انت طلعت بفلوس اخص عليك"* — "so you turned out to be after money, shame on you." Eight proactive offers, zero clicks on either button, and four of the eight parents never returned.

That is **two** failures, not one:

1. **Surprise.** The offer contradicted what the parent believed the relationship was.
2. **Attribution.** It arrived because a scoring machine decided she was ready — not because anything in *her* situation called for it. She could feel the difference.

Fixing only the wording fixes neither. The architecture has to make both impossible.

### 33.2 Why passive discovery is impossible in a conversation

The founder's instinct was: *let the parent discover it the way you discover features in an excellent app.*

**The instinct is right. The analogy does not transfer.** An app has **periphery** — menus, settings screens, greyed-out controls, a "Pro" badge in a corner. A user can wander and find things at their own initiative, and nobody said anything.

**A conversation has no periphery.** Everything in it is foreground. There is no elsewhere to wander into. Therefore, in a chat product, *every* discovery is an utterance, and every utterance has an initiator. "Passive discovery" in a conversation is a category error.

So the design question is not *how do we make discovery passive.* It is:

> **What utterance about a fuller arrangement would a trustworthy companion make anyway — even if there were nothing to sell?**

Everything in this section follows from that reframe.

**One genuine exception, and it is why Telegram matters.** Telegram gives ADAM two non-conversational surfaces: the **bot menu** and the **pinned message**. These are the only true periphery the product has. This is where the founder's instinct actually lands — and it lands *only* because of the channel.

### 33.3 The test every discovery moment must pass

> **Remove the price. Is the message still worth sending?**
>
> If no, it is a sales pitch wearing a companion's voice. Delete it.

This test is what separates this architecture from the one that produced the betrayal. Every door below passes it. Door 3 passes it only because it carries a free alternative — remove the paid option and the message still helps.

### 33.4 The four doors

| Door | Who initiates | Frequency | Honest expectation |
|---|---|---|---|
| **Door 0 — Another parent** | A third party | Organic | Highest trust of all. Nobody with an interest is speaking |
| **Door 1 — Ambient** | Nobody. It simply exists | Always available | **Low conversion. It is the ethical floor, not a growth lever** |
| **Door 2 — Asked for** | The parent | Whenever it arises | **The primary path.** The parent has already described the thing |
| **Door 3 — The honest limit** | ADAM, at most twice ever | Rare | Moderate, and the most fragile. Killable on evidence |

---

#### Door 0 — Another parent

Already specified as the referral loop (§20). Named here because **it is the best discovery channel we have and it is not a sales mechanism at all.** A parent hearing it from another parent hears it from someone with nothing to gain.

Nothing new is built. It is listed so that the discovery architecture is not mistaken for "the three things ADAM says."

---

#### Door 1 — Ambient (zero utterances)

| Surface | Content | Rule |
|---|---|---|
| **Bot menu** | One entry, worded as the parent's own question | Never a product name |
| **Pinned message** | The child's current situation and the rhythm, with one quiet closing line | Updated silently; never re-pinned as a notification |

**The menu entry is worded as a question, not an offer:**

```
هل يمكن لآدم أن يرافقني أكثر؟
```

Not "الاشتراك", not "المرافقة الكاملة", not "الخطط". A parent who is curious recognises their own question. A parent who is not sees a line that makes no demand.

**Honest expectation:** most parents will never open a bot menu. Door 1 converts close to nothing, and **that is not why it exists.** It exists so that (a) a self-directed parent can find out without having to ask a person, and (b) we never depend on "but we did tell her." Calling it a growth lever would be self-deception.

---

#### Door 2 — Asked for · **the primary path**

Two kinds, and the second is the most valuable moment in the entire product.

**2a — She asks about scope.** *"هل هناك نسخة مدفوعة؟"* · *"آدم مجاني بالكامل؟"*

Answer honestly and completely, then stop. Copy in §11.8. No elaboration, no follow-up, no second mention.

**2b — She asks for work the free rhythm does not do.**

Real requests of this shape:

- *"ذكّرني بكرة قبل المدرسة"*
- *"تقدر تسألني الساعة ٦ قبل ما نخرج؟"*
- *"خليك معايا في الموضوع ده شهر"*
- *"إزاي أعرف إن الليلة دي هتكون صعبة قبل ما تبدأ؟"*

**She has just described the paid arrangement in her own words.** Nothing was pitched. There is no surprise available, because the idea came from her. This is the highest-intent, lowest-pressure moment that exists, and it requires zero initiation from us.

**The discipline that makes this safe — and it is absolute:**

> **Answer the question fully and for free, first.** (P6)

If she asks how to tell a hard night is coming, ADAM tells her — completely, with the actual pattern from her own data. Only *after* that, and only if what she asked for is **continuous doing** rather than **knowing**, does ADAM say that the continuous version is a different arrangement.

This yields the line that defines the whole free/paid boundary:

> ### Knowing is always free. Doing it for her, every day, is the paid thing.

That line is defensible in a way "more features" never was. It withholds no information. It distinguishes **information from labour** — and labour is the only thing that can honestly cost money in a product whose entire moat is trust.

It is also consistent with everything already decided: P15 (free never crippled), D-G (difference is the level of companionship), D-H (sell the destination), and §21.1 (never say memory, say the outcome).

---

#### Door 3 — The honest limit

The one case where ADAM initiates. It exists because **silence is not always neutrality.** When ADAM can see that the way it is working is not enough for what this family is facing, saying nothing withholds something true and useful. A good companion says *"I don't think what I'm doing is helping enough."*

**Every condition below is required. Any one missing, and it does not fire.**

| Condition | Threshold | Why |
|---|---|---|
| Same Situation unresolved across | **≥12 Harvests** | Long enough to be a pattern, not a bad week |
| Failure rate on that Situation | **≥60%** answered *"جرّبناها وما نجحت"* | The method is demonstrably not landing |
| Days since the last hard night | **≥3** | **Never immediately after a failure.** Not harvesting a low moment |
| Crisis state | Never in X1, and not for **14 days** after it clears | P1 |
| Parent state | Not S9 dormant, not X4 paused | Respect the silence |
| Per Situation | **Once** | — |
| Per parent lifetime | **Maximum 2**, ≥90 days apart, and on a *different* Situation | — |
| A free alternative in the same message | **Required** | §33.3 — without it, this is a pitch |
| Never within the same conversation turn as a Mirror | Required | The Mirror must stay uncontaminated (§11.5) |

**The message locates the insufficiency in ADAM, never in the parent:**

```
ADAM: أريد أن أقول شيئاً بصراحة.

      منذ أسبوعين ونحن ندور حول نوم يوسف. فكرة كل صباح، وسؤال كل مساء —
      وتسع مرات من اثنتي عشرة لم تنجح.

      العيب في طريقتي لا فيكم: فكرة واحدة في اليوم لا تكفي لموقف
      متجذّر مثل هذا.

      أمامنا طريقان — والأول هو ما سأفعله إن لم يُقَل شيء:
      نغيّر الموقف الذي نعمل عليه، ونعود إلى النوم لاحقاً.
      أو شهر موجَّه لهذا وحده، أرافق فيه يوماً بيوم لا مرة في اليوم.

      [نغيّر الموقف]   [أخبرني عن الشهر]   [نكمل كما نحن]
```

**Five deliberate choices in that message:**

1. **"العيب في طريقتي لا فيكم"** — the insufficiency is ADAM's method, not the parent's effort. This inverts the usual dynamic: not *unlock more*, but *I have been under-serving you and here is the honest reason.* It is also simply true.
2. **The free option is stated first, and is the default on silence.** Doing nothing gets her the free path, not the paid one.
3. **Three buttons, one of which is "carry on unchanged."** Declining is a first-class outcome with a button of its own, not an absence.
4. **No price in this message.** The price appears only if she taps to ask. Achievement, honesty, and commerce never share a bubble (P1).
5. **It exceeds the 2–3 line ceiling (P6), knowingly.** This is the one structural message in the product where honesty needs more room, and it happens at most twice in a parent's lifetime. The exception is recorded here so it is not copied elsewhere.

**Door 3 is the only killable door.** If block/mute rate in the 7 days after Door 3 exceeds 2× baseline, it is switched off and the architecture runs on Doors 0–2. That is not a fallback position to be embarrassed about — Doors 0–2 are the ones that respect the constraints most completely.

### 33.5 Never permitted

| Banned | Why |
|---|---|
| Any message whose only purpose is to mention the arrangement | §33.3 |
| A second mention after a decline, ever | The old model's four-of-eight who never came back |
| Mentioning it in the same message as a Mirror, a win, or an end-of-month | P1 — achievement and commerce never share a bubble |
| Mentioning it within 14 days of a crisis | P1 |
| Mentioning it during or right after a hard night | Harvesting distress |
| A countdown, a limited window, a "special" price | P10 |
| Any scoring model that decides who is "ready" | **This is precisely what the Judge did.** 8 offers, 0 clicks |
| Degrading the free rhythm to make the paid one look better | P15, D-G |
| A pricing page, a plans screen, a comparison table | §33.6 |
| Announcing it to the existing 291 parents | It would be exactly the surprise this section exists to prevent |

That last row matters operationally: **there is no launch announcement.** Existing parents encounter the doors the same way new ones do.

### 33.6 It has no name — an architectural decision

v1 and early v2 called it **"المرافقة الكاملة"** — *full companionship*. That phrasing is a defect, for two reasons:

1. **"Full" implies what she has now is partial.** That directly contradicts P15 and D-G, which say the free tier is complete and never deliberately lessened. The name insults the free product.
2. **A named product is a product that appeared.** Names are what things have when they are sold. An extension of a relationship is *described*, in context, each time.

> **Rule: ADAM never gives it a proper name.** It is described, in this parent's own situation, every time it comes up.

Four consequences, all desirable:

- **A pricing page becomes impossible by construction.** There is no noun to put at the top of one.
- **Every description is forced into outcome language** (D-H), because there is no name to hide behind. "شهر موجَّه لنوم يوسف" says what happens; "المرافقة الكاملة" says nothing.
- **There is nothing to announce**, which removes the temptation at the root.
- **The internal name stays `Chapter`** — team vocabulary, never user-facing (§3.6, the two lexicons).

### 33.7 The handoff — discovery has to end well

Discovery that succeeds and then collapses at payment is a failure of this section, not of §22. Payment is manual and requires leaving the conversation for a DM with a stranger, which the product walkthrough identified as the single largest drop and a live trust problem.

| Rule | Why |
|---|---|
| ADAM names the handoff plainly, including that a human confirms it | Surprise is the thing we are eliminating; do not introduce a new one here |
| **The rhythm continues, uninterrupted, during S6** | Already specified in §10. Restated because it is the whole point: nothing is held hostage to payment |
| If unconfirmed after 72h, ADAM raises it — never silently drops it | A parent who paid and heard nothing is the worst outcome available |
| A parent who starts and does not finish is never messaged about it | Not once. Abandoned payment is a decision |

### 33.8 How this is measured — trust first, conversion second

**The primary metrics for this section are counter-metrics.** That ordering is deliberate: a discovery architecture optimised for conversion becomes a funnel, which is the thing we are avoiding.

| Metric | Target | Kind |
|---|---|---|
| Block/mute rate in 7 days after **any** door | **≤ baseline** | **Guardrail — halts the roadmap** |
| Block/mute after Door 3 specifically | **< 2× baseline, or Door 3 is switched off** | **Kill switch** |
| Dormancy within 14 days of a decline | **≤ baseline** | **Guardrail.** Catches the four-of-eight failure |
| Harvest rate in the 7 days after a decline | **≤ 5 points below baseline** | Did declining damage the relationship? |
| Door 2b occurrences per 100 parents in rhythm | Observe | **Demand signal, not a target** |
| Door distribution (0/1/2a/2b/3) | Observe | Which doors actually work |
| Conversion per door | Observe | Ranked **last**, deliberately |

**No conversion target is set anywhere in this section.** v1's F9 carried *"≥10% of S4 parents open it unprompted"*, and a target on a discovery mechanism is an instruction to optimise it. Conversion is observed, reported, and never optimised against.

### 33.9 Review pass — gaps found and closed

Reviewed as an outside critic looking for holes. Five were real and are closed here.

**Gap 1 — "Door 3 fires when free is failing 60% of the time. Isn't that just a bad product?"**

Fair challenge, and the answer has to be structural or Door 3 is indefensible. The free rhythm is capped at **one suggestion per day** — not by stinginess but because two proactive messages is the honest ceiling before ADAM becomes noise (§13.3, R3). Some situations genuinely need more attention than one idea a day can give. So the limit Door 3 names is **architectural, not a quality defect**, and saying so is accurate. If instead the failure were caused by *bad* suggestions, the fix is F6 and the Seed, not an offer — and E1 is what tells the difference.

**Gap 2 — The pinned message's "quiet closing line" was unspecified.** A gap that would have been filled by whoever built it. Specified now:

```
📌  يوسف · نعمل على: النوم
    هذا الأسبوع: ٤ ليالٍ أهدأ من ٧

    القائمة ☰ فيها كل ما يمكن أن نفعله معاً.
```

It points at the **menu**, not at a price or an arrangement. A parent who wants more looks; a parent who does not sees a line about a menu.

**Gap 3 — Door 2 could fire too eagerly.** Distinguishing "she wants to know" from "she wants it done every day" is a judgment call, and an eager model will mention the paid arrangement on any question that merely *sounds* adjacent. Guard, now required:

> **Door 2's paid mention requires an explicit request for recurring or continuous action** — a repetition word (*كل يوم*, *دايماً*, *شهر*, *باستمرار*) or a request for ADAM to initiate (*ذكّرني*, *اسألني*, *كلّمني قبل*).
> A question about *how*, *why*, or *what* is answered and closed. **Never inferred from tone or enthusiasm.**

Without this, Door 2 slowly becomes a push with extra steps.

**Gap 4 — Does tapping through Door 3 count as a second mention?** It must not, or the rules contradict each other. Clarified:

> **A door and its own follow-through are one event.** Door 3 → she taps *"أخبرني عن الشهر"* → the price answer: that is **one** mention. The no-second-mention rule (§33.5) applies to *new* events, not to completing one she chose to continue.

**Gap 5 — What do the doors do in X2, where no payment rail exists?** Previously unhandled, and it matters: 48.4% of signups are in exactly this position. Naming an arrangement she cannot buy is a cruelty with no upside.

| Door | Behaviour in X2 |
|---|---|
| **Door 1** | Menu entry hidden. Pinned line shows the rhythm only |
| **Door 2** | Answered honestly: it is not available in her country yet, everything between us stays as it is, and she is told when it changes. **Recorded as demand evidence** (§25 `payment_blocked_country`) |
| **Door 3** | **Never fires.** The free alternative is offered on its own, as a plain suggestion to change the situation — which is the useful half anyway |

Door 3's behaviour in X2 is the cleanest proof that §33.3's test was applied honestly: **strip the paid option and the message still stands as help.** If it collapsed without the price, it was a pitch.

### 33.10 The strategic consequence, stated plainly

**This architecture converts poorly by construction, and that is the honest cost of the constraints.**

Doors 0 and 1 convert near zero. Door 2 depends entirely on parents spontaneously asking for continuous help, which is a real behaviour but not a frequent one. Door 3 fires rarely by design and is the first thing to be switched off if it damages trust.

**A companion that genuinely works has a weak sales mechanism, necessarily.** The better the free rhythm is, the less often a parent hits a wall that makes the fuller arrangement obvious. Free quality and conversion are in direct tension, and the founder's non-negotiables resolve that tension in favour of free quality.

Two honest implications:

1. **The business must be sized for low conversion and high retention** — a small paying minority subsidising a large free base, with content as the acquisition engine (§19). That is a viable shape, but it is a different business from the one a funnel would build.
2. **If revenue proves insufficient, the constraint to revisit is the free/paid boundary (§16.1) — not this architecture.** Adding pressure here would break the trust that makes the product worth anything. Moving the boundary is a strategy decision and it is the founder's. Making the doors pushier is a betrayal and it is nobody's.

---

**End of blueprint v2. No implementation has begun. Awaiting your approval.**
