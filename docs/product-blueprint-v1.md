# ADAM — Product Blueprint v1
**Date:** 2026-07-29
**Status:** Specification for review. No implementation. Awaiting approval.
**Rule for this document:** every feature carries *why it exists*, *the user evidence*, *the problem it solves*, and *how success is measured*. Anything that cannot answer all four was cut. Nothing is inherited from the current build because it exists.

---

## Table of contents

1. Product vision
2. Product principles
3. Positioning
4. Value proposition
5. Customer transformation
6. User personas
7. Jobs To Be Done
8. Information architecture
9. Complete user journey
10. Every user state
11. Conversation flows
12. UX flows
13. Feature map
14. Value ladder
15. Activation strategy
16. Habit loop
17. Growth loop
18. Referral loop
19. Monetization strategy
20. Pricing strategy
21. Success metrics
22. North Star Metric
23. Product analytics events
24. Experiment roadmap
25. Product roadmap
26. Risks and assumptions
27. Features to remove / keep / build
28. Decisions challenged and rejected
29. Open decisions requiring founder input

---

## 1. Product vision

**Ten-year vision**

> Every Arab parent who wants to break a cycle of shouting has someone with them in the moment it matters — and proof, in their own hands, that they are changing.

**Three-year vision**

> ADAM is the default companion for Arabic-speaking parents in the hardest moments of raising a child: present in seconds, free to anyone, and trusted enough that parents tell it what they hide from their own families.

**One-year vision**

> A parent anywhere in the Arab world can reach ADAM at 9pm, get one thing to do in under sixty seconds, and after thirty days hold a report that shows exactly how much calmer their home became.

**What we are not building:** a parenting course, a content library, a diagnosis tool, a therapist replacement, or a child-behaviour tracker. Each was considered and rejected in §28.

---

## 2. Product principles

These are decision rules. When a build decision is ambiguous, these resolve it — in order.

| # | Principle | Rule in practice | Evidence |
|---|---|---|---|
| **P1** | **The crisis is never monetised** | No paywall, cap, or upsell may ever appear in a conversation where a parent is distressed | *"انت طلعت بفلوس اخص عليك"* — the observed reaction to a paywall in an emotional relationship |
| **P2** | **Never ask before you give** | No profiling question may precede the first useful answer | 94.1% onboarding abandonment (271/289 stuck at step 0) |
| **P3** | **She is tired, not guilty** | No output may attribute blame to the parent, even when factually true | Already encoded: *"هي متعبة لا مذنبة"*; 73 guilt messages in data |
| **P4** | **One tap beats one sentence** | Any recurring interaction must be answerable with a button | Avg human message = 53 chars; parents are dysregulated when they write |
| **P5** | **Show memory, never announce it** | Never say "I see in your file". Demonstrate continuity by using it | Already encoded; announcing memory reads as surveillance |
| **P6** | **Value per effort** | Every reply is 2–3 lines: one cause, one step, one measure | Already encoded and correct; matches exhausted-user context |
| **P7** | **Honest limits** | Never promise a guaranteed child outcome | Already encoded; protects trust, which is the moat |
| **P8** | **Free forever, everywhere** | Geography may gate payment. It may never gate help | 140/289 signups blocked; 23,697 unserved audience |
| **P9** | **Silence over harm** | When memory could reopen a wound, store nothing | Already encoded in Heart Writer: *"الذاكرة الناقصة أرحم ألف مرة من الذاكرة التي تجرح"* |
| **P10** | **No scarcity, ever** | No countdowns, limited seats, expiring offers | Already banned in prompts; incompatible with P1 and P3 |

**P1, P2 and P8 override commercial considerations.** If a growth tactic conflicts with them, the tactic is wrong.

---

## 3. Positioning

### Positioning statement

> **For** exhausted Arabic-speaking parents who already know what good parenting looks like but cannot reach it when they are angry,
> **ADAM is** a companion present in the moment itself
> **that** gives one thing to do tonight, remembers your child, and shows you month by month that you are becoming calmer.
> **Unlike** parenting content, courses, or general AI assistants,
> **ADAM** is there at 9pm and keeps the receipts of your progress.

### The category shift

| | From (current) | To (proposed) |
|---|---|---|
| **Hero** | The child | The parent |
| **Promise** | Understand what your child doesn't say | Become the parent you want to be |
| **Proof** | ADAM explains | ADAM shows you your own change |
| **Category** | AI parenting advice | The parent's companion in the hard moment |
| **Moment of use** | Whenever curious | The moment of losing control |

### Brand continuity — a deliberate constraint

**Keep the name, handle, and visual identity.** "آدم | ما لا يقوله طفلك" carries ~41,100 followers and a 525,682-reach proof point. The promise evolves; the brand does not reset. Tagline shifts over one quarter, not overnight.

### Tone of voice system

Derived from the existing prompts, which are already excellent and should be preserved as a formal spec.

**Voice attributes**

| Attribute | Do | Don't |
|---|---|---|
| **Warm without excess** | "أنا هنا" | "حبيبتي", "قلبي", any pet name |
| **Never blaming** | "الخوف صار ضيفاً ثقيلاً في البيت" | "أنتِ أخفتِها", "بسببك" |
| **Short** | 2–3 lines, phone-readable | Walls of text, numbered essays |
| **Practical** | One cause, one step, one measure | Theory, philosophy, citations |
| **Honest** | "أمشي معكِ ولا أعِدكِ بطفلٍ مثالي" | "سيتوقف", "مضمون" |
| **Plain Arabic** | Simplified MSA | Foreign words, ornate metaphor, poetry |

**Absolute bans:** scarcity, urgency, expiring offers, intimate pet names, guilt attribution, guaranteed child outcomes, claiming to remember something never said, any link or phone number inside emotional messages.

**Gender handling:** ADAM always speaks of himself in masculine. He addresses the parent in their declared or inferred gender; where unknown, neutral construction. **The mother-only assumption in the current Heart Writer prompt is a defect** — 18.5% of the audience is male.

---

## 4. Value proposition

**Primary**

> **آدم معكِ في اللحظة الصعبة — ويريكِ بعد ثلاثين يوماً كم تغيّرتِ.**
> *ADAM is with you in the hardest moment — and after thirty days, shows you how much you've changed.*

**Layered by audience temperature**

| Audience state | Message | Where used |
|---|---|---|
| Cold (content viewer) | "طفلكِ لا يحتاج صراخاً أكثر — يحتاج بيتاً يشعر فيه بالأمان" | Instagram (already proven, 525k reach) |
| Warm (in the moment) | "احكيلي شنو صار الآن. أنا معكِ." | Bot first contact |
| Engaged (3+ nights) | "ثلاث ليالٍ من خمس كانت هادئة. هذا أنتِ." | First Mirror |
| Considering | "الشهر القادم: نعرف طبع طفلكِ، ونقيس تقدّمكِ أسبوعاً بأسبوع." | Journey offer |
| Completed | "بدأتِ هنا. أنتِ الآن هنا." | Day-30 Report |

**What we never say again:** "remembers every situation", "knows your child by name", or any feature list as the lead. These describe machinery. The current offer prompt leads with a four-bullet feature list into an identity-driven job — that is the core copy error.

---

## 5. Customer transformation

The product exists to move a parent along one axis.

```
BEFORE                                          AFTER
─────────────────────────────────────────────────────────────
"I shout, then I hate myself."          →   "I caught myself, and I know it."
"I have no idea why he does this."      →   "I know his flashpoint by name."
"I read a lot and change nothing."      →   "I did one thing and it worked."
"I'm alone in this."                    →   "Someone is with me at 9pm."
"I might be a bad mother."              →   "I have proof I'm becoming calmer."
```

**The transformation is measured, not claimed.** That measurement — nights logged, calm ratio, flashpoint identified, steps that worked — *is* the product's paid layer. This is the central design decision of the entire blueprint.

**Transformation milestones (product must make each one legible to the parent):**

| # | Milestone | Trigger | Parent feels |
|---|---|---|---|
| **T1** | First relief | First usable step received | "Someone is here." |
| **T2** | First win | First night logged as calm/step done | "It actually worked." |
| **T3** | First proof | First Mirror at 3+ nights | "I can see myself changing." |
| **T4** | Named pattern | Flashpoint identified and confirmed | "I understand my child." |
| **T5** | Identity shift | Day-30 Report | "I am a calmer parent." |

---

## 6. User personas

### Persona A — أمّ منهكة · "The Exhausted Mother" (primary)

| | |
|---|---|
| **Who** | Woman, 25–44, DZ/EG/MA/IQ/SY, 1–3 children aged 2–11 |
| **Size** | 44.4% of audience (18,348 of ~41,100); women overall 57.6% |
| **Trigger moment** | 9pm, after shouting or hitting, alone, flooded with shame |
| **Current alternative** | Instagram reels, family advice, the bathroom door |
| **Job** | Stop being the angry mother; be seen without judgement |
| **Evidence** | *"بنتي عمرها ٤ سنوات حاسة اني فاشله ف التربية"* · *"بس اريد اكون ام اسلوبها هادئ"* |
| **Blocker** | Cannot pay by card; may be in an unsupported country |
| **Design implication** | Voice input, one-tap logging, zero forms, free rescue |

### Persona B — أمّ على القائمة · "The Waitlisted Parent" (largest untapped)

| | |
|---|---|
| **Who** | Identical job to A, in IQ/SY/SA/JO/YE/OM/Gulf |
| **Size** | 48.4% of signups (140/289); 57.6% of audience (23,697) |
| **Distinguishing fact** | Gulf sub-segment (~5,749) has materially higher ability to pay than all three current markets |
| **Evidence** | Country distribution in `followers` + Instagram audience data, two independent sources agreeing |
| **Design implication** | **Serve free immediately. Gate only payment.** Collect proven demand for a future rail |

### Persona C — أب مشارك · "The Engaged Father"

| | |
|---|---|
| **Who** | Man, 25–44 |
| **Size** | 18.5% of audience; 4 of 18 declared users (22%) |
| **Job variant** | Includes authority and discipline framing alongside connection |
| **Evidence** | Audience gender split; declared `parent_gender` distribution |
| **Design implication** | **Remove the mother-only assumption from memory extraction.** Neutral default until known |

### Persona D — والد في أزمة · "The Crisis Parent" (small, highest stakes)

| | |
|---|---|
| **Who** | Parent disclosing third-party abuse, bereavement, adolescent substance use, or their own violence |
| **Size** | Small but present across 2,086 messages |
| **Evidence** | *"حذرنا المعتدي سابقا"* · *"اكتشفت أنه يدخن ويتعاطى"* · *"فقدنا أمنا منذ عام"* · *"انا بضرب"* |
| **Design implication** | **Detection + containment + human escalation path.** Never automated advice. See §11.7 and §29 |

**Explicitly not a persona:** the "curious browser." No evidence of a meaningful non-distressed user segment. Do not design for them.

---

## 7. Jobs To Be Done

### Primary job

> **When** my child does something I can't handle and I feel myself losing control,
> **I want to** not become the parent I'm ashamed of,
> **so that** my child remembers a home that was safe.

### Job dimensions — all three must be served

| Dimension | Job | Served by | Evidence |
|---|---|---|---|
| **Functional** | Interrupt escalation; give me one action now | The Moment | 168 "how do I" messages; 53-char avg |
| **Emotional** | Stop feeling like a failure; be seen without judgement | Voice + no-blame discipline | *"عايزه حد يشوفنى حلوه من جوه من غير احكام"* |
| **Social** | Be a parent whose children remember warmth | The Mirror + Day-30 Report | *"عندما يكبرون لا يذكرون الا الصراخ والتوبيخ"* |

**Current product serves the functional dimension well and the other two barely.** That imbalance is why engagement is high and conversion is zero.

### Secondary jobs

| Job | Evidence | Served in |
|---|---|---|
| Interrupt intergenerational trauma | *"لا أريد أن تنتقل لهم الصدمات"* | Positioning + Day-30 Report |
| Not be alone | 20,991 shares on one post | Later (Circle) — not MVP |
| Understand a specific worry (speech/development) | 98 messages — #3 theme | Next (§25) |

### Forces of Progress — the design brief

| Force | State | What the blueprint does about it |
|---|---|---|
| **Push** | 🟢 Very strong | Nothing needed — 73 guilt + 28 exhaustion messages |
| **Pull** | 🟢 Strong | Preserve conversation quality; add the Mirror |
| **Anxiety** | 🔴 Unaddressed | Permanent tier indicator; free-forever guarantee; no recurring commitment; 30-day guarantee |
| **Habit** | 🔴 Unaddressed | Delete onboarding form; one-time purchase not subscription; one-tap logging; voice input |

**Every feature in §13 exists to reduce Anxiety or Habit.** Adding more Pull is not the constraint.

---

## 8. Information architecture

A conversational product has no navigation tree. Its IA is: **entity model + state machine + interruption points.**

### 8.1 Entity model (redesigned from first principles — 12 entities, not 28 tables)

```
Parent ─┬─ 1:N ─ Child ─┬─ 1:N ─ Flashpoint
        │               └─ 1:N ─ Pattern
        ├─ 1:N ─ Moment          (a rescue event)
        ├─ 1:N ─ Night           (a daily log)
        ├─ 1:N ─ Mirror          (a generated report)
        ├─ 0:1 ─ Journey ─ 1:N ─ Payment
        ├─ 1:N ─ Message
        └─ 0:N ─ CrisisFlag
```

| Entity | Purpose | Key fields | Why it exists |
|---|---|---|---|
| **Parent** | The customer | id, channel_id, locale, country, gender, state, tier, created_at | Identity and state routing |
| **Child** | Who this is about | id, parent_id, name, age_band, gender, temperament_note, is_primary | Personalisation; name is the strongest continuity signal |
| **Flashpoint** | The recurring hard moment | id, child_id, label, context, status, confidence | **Replaces `main_pain`.** The unit of work — what we actually help with |
| **Moment** | A rescue event | id, parent_id, occurred_at, trigger_text, response_given, outcome | Measures the highest-value interaction, currently unmeasured |
| **Night** | A daily log | id, parent_id, child_id, log_date, result, hard_moment, step_id, step_outcome | Powers the Mirror. The atomic unit of proof |
| **Step** | Advice given | id, night_id, text, outcome | Enables "the step that worked most" |
| **Pattern** | Derived insight | id, child_id, label, evidence_count, status | What makes ADAM feel like it knows the child |
| **Mirror** | A generated report | id, parent_id, kind(first/weekly/day30), payload, sent_at | The conversion engine — must be a first-class object, not a message |
| **Journey** | Paid 30-day container | id, parent_id, started_at, ends_at, status | The paid unit |
| **Payment** | A transaction | id, journey_id, amount, currency, method, claimed_at, confirmed_at, confirmed_by | Manual reconciliation |
| **Message** | Conversation history | id, parent_id, role, content, created_at | Memory + analysis corpus |
| **CrisisFlag** | Safeguarding | id, parent_id, category, detected_at, handled_at, handled_by | Duty of care |

**Deleted from current model:** `messages` (0 rows), `collective_intelligence` (0), `weekly_plans` (0), `survey_responses` (0), and the eight `*_archive_20260708` tables (move to cold storage). **`main_pain` as a fixed 8-value enum is deleted** — it forced a taxonomy that missed the #3 theme (speech/development, 98 messages). Flashpoint is free-text with a derived label.

### 8.2 Data integrity rules (non-negotiable — these are current live bugs)

| Rule | Why | Current failure |
|---|---|---|
| Every conversation must resolve to a Parent row before the first reply | Otherwise the user is invisible to every downstream system | **47 of 188 sessions (25%) have no follower row** |
| Engagement counters must be derived, never incremented by a workflow | Incrementers silently fail | `message_count` frozen at 0 since ~25 July while users actively converse |
| Agent context must never be persisted into stored user messages | Pollutes memory, inflates cost | Rows begin `=[اليوم 1 من 30…] === ذاكرة الرحلة ===` |
| Every generated message must have a hard length ceiling | Runaway generation | One stored AI message is **169,230 chars** (466× the 363-char average) |
| Price must be injected into agent context, never inferred | Hallucinated prices are broken promises | Agent invented "150 EGP"; real price is $10-equivalent (490 EGP) |

### 8.3 Surfaces

| Surface | Role | Notes |
|---|---|---|
| **Telegram chat** | The whole product | Text + voice notes + inline buttons |
| **Inline buttons** | All recurring interactions | Per P4 |
| **Voice notes** | Primary input for distressed states | New — see F3 |
| **Instagram/Facebook** | Acquisition only | Never the product surface |
| **Operator console** | Manual payment confirmation + crisis queue | Minimal internal tool |

**No mobile app. No web dashboard. No email.** Each adds surface without serving an evidenced job.

---

## 9. Complete user journey

```
┌─ ACQUISITION ────────────────────────────────────────────────┐
│  Instagram content — reach 150k–525k (already working)       │
│  CTA reframed from product to moment:                        │
│  "إذا كنتِ في هذه اللحظة الآن — اكتبي لي"                      │
└──────────────────────────┬───────────────────────────────────┘
                           ▼
┌─ FIRST CONTACT ──────────────────────────────────────────────┐
│  /start  →  NO country gate.  NO form.  NO questions.        │
│  "احكيلي شنو صار. اكتبي أو سجّلي صوتاً."                        │
│  TARGET: usable step in < 60 seconds        [T1 relief]      │
└──────────────────────────┬───────────────────────────────────┘
                           ▼
┌─ THE MOMENT (free, forever, everywhere) ─────────────────────┐
│  One cause · one step for tonight · one way to know          │
│  Ends with: "أخبريني الليلة كيف كانت."                         │
└──────────────────────────┬───────────────────────────────────┘
                           ▼
┌─ THE NIGHTLY LOOP (free) ────────────────────────────────────┐
│  21:00 local — one tap                                       │
│  [نجحت] [جرّبت وما نجحت] [ما جرّبتها]                          │
│  or, if no step given: [هادئة] [صعبة] [عادية]        [T2 win] │
│  If صعبة → "متى كان الأصعب؟" → flashpoint learning            │
└──────────────────────────┬───────────────────────────────────┘
                           ▼
┌─ THE FIRST MIRROR (free — the wow moment) ───────────────────┐
│  Fires at 3 logged nights. Data-gated, not day-gated.        │
│  "▓▓▓░░  ٣ من ٥ ليالٍ كانت هادئة.                             │
│   الموقف المتكرر: عند النوم.                                   │
│   الخطوة التي نجحت أكثر: «...»"                [T3 proof]     │
│  ← BUILT. DATA-GATED. HAS FIRED ZERO TIMES.                  │
└──────────────────────────┬───────────────────────────────────┘
                           ▼
┌─ THE ASK (parent-initiated ONLY) ────────────────────────────┐
│  Persistent, quiet: "ما هي المرافقة الكاملة؟" always available │
│  NEVER pushed. NEVER during distress.              [P1]      │
└──────────────────────────┬───────────────────────────────────┘
                           ▼
┌─ THE JOURNEY (paid — 30 days, one-time, $10 eq) ─────────────┐
│  Named child · tracked flashpoint · weekly Mirror            │
│  Manual payment → operator confirms → starts                 │
└──────────────────────────┬───────────────────────────────────┘
                           ▼
┌─ WEEKLY MIRROR ×4 ───────────────────────────────────────────┐
│  Each week: what changed, what's working, what's next        │
└──────────────────────────┬───────────────────────────────────┘
                           ▼
┌─ DAY-30 REPORT ──────────────────────────────────────────────┐
│  "بدأتِ هنا. أنتِ الآن هنا."                       [T5 identity]│
│  → shareable insight card (not her stats — see §18)          │
│  → offer to continue at reduced price                        │
└──────────────────────────┬───────────────────────────────────┘
                           ▼
              Continue  ·  Or return to free tier
              (nothing is taken away — P1)
```

---

## 10. Every user state

The engineering team must implement this state machine exactly. States are mutually exclusive except where marked orthogonal.

### 10.1 Primary lifecycle states

| # | State | Entry condition | Exit condition | System behaviour |
|---|---|---|---|---|
| **S0** | `new` | `/start` received | First user message | Greet; invite the moment; no questions |
| **S1** | `first_moment` | First substantive message | First step delivered | Full attention; no logging prompts |
| **S2** | `helped` | First step delivered | First night logged | Enable nightly check-in from tonight |
| **S3** | `logging` | ≥1 night logged | 3 nights logged | Nightly loop active; learning flashpoint |
| **S4** | `mirrored` | First Mirror delivered (3 nights) | Journey requested, or 14d inactive | Quiet ask available; weekly rhythm |
| **S5** | `considering` | Parent asked about the Journey | Payment claimed, or declines | Offer presented once; then silence |
| **S6** | `payment_claimed` | Parent states they paid | Operator confirms or 72h timeout | Warm acknowledgement; no pressure |
| **S7** | `journey_active` | Payment confirmed | Day 30 reached | Full paid experience |
| **S8** | `journey_complete` | Day-30 Report delivered | Continues, or 14d inactive | Continuation offered once |
| **S9** | `dormant` | 14 days no interaction | Any message received | One reactivation attempt max, then silence |
| **S10** | `returned` | Message after dormancy | Next state resolves within 1 turn | Acknowledge continuity, never guilt the absence |

### 10.2 Orthogonal states (can coexist with any primary state)

| State | Entry | Effect | Priority |
|---|---|---|---|
| **X1** `in_crisis` | Crisis category detected | **All commercial messaging suppressed.** Containment mode. Human queue | **Overrides everything** |
| **X2** `payment_blocked` | Country has no payment rail | Free tier fully available; Journey offer replaced with "notify me" | Never blocks help (P8) |
| **X3** `voice_preferred` | ≥2 voice notes sent | Reply in voice-friendly cadence; shorter text | Cosmetic |
| **X4** `paused` | Parent asks for silence | All proactive messages stop; conversation still available | Honoured indefinitely |

### 10.3 State transition rules

**Hard rules:**
1. **No transition may skip S1→S2.** A parent must receive value before any other system behaviour activates. (P2)
2. **S5 (`considering`) can only be entered by parent action.** No automatic transition. (P1)
3. **X1 (`in_crisis`) suppresses S5–S8 messaging entirely** for the duration plus 7 days.
4. **X2 never blocks S0–S4.** Payment geography gates S5 onward only. (P8)
5. **S9 (`dormant`) permits exactly one reactivation message, ever.** Not one per dormancy — one per parent lifetime.

**Why rule 5:** the current Reactivation workflow has no lifetime cap. Repeated re-engagement of a parent who left is the fastest way to become the thing she mutes.

---

## 11. Conversation flows

Scripts are specification, not suggestion. Arabic is the deliverable; English glosses are for review.

### 11.1 First contact (S0 → S1)

```
ADAM: السلام عليكم 🌿
      أنا آدم.
      احكيلي شنو صار — اكتبي، أو سجّلي صوتاً إذا كان أسهل.
```
*(Peace be upon you. I'm ADAM. Tell me what happened — write, or send a voice note if that's easier.)*

**Rules:** no name request, no country question, no age question, no menu. One line of identity, one invitation. Voice offered explicitly at first contact because that is when the parent is most dysregulated.

### 11.2 The Moment — core response shape (S1 → S2)

```
[one line: the cause, without blaming her]
[one line: the step, specific to tonight]
[one line: how she'll know it worked]

أخبريني الليلة كيف كانت.
```

**Worked example:**
```
ADAM: الرفض عند النوم غالباً ليس عناداً — هو خوف من الانفصال عنكِ في الظلام.

      الليلة، قبل النوم بعشر دقائق، اجلسي معه واتركي الباب مفتوحاً شبراً.
      لا تشرحي، فقط اجلسي.

      ستعرفين أنها نجحت إذا نام دون أن يناديكِ أكثر من مرة.

      أخبريني الليلة كيف كانت.
```

**Constraints:** max 3 content lines + 1 closing. Never withhold detail — if she asks "how exactly?", give it fully (P6, and the existing prompt is correct on this). Never mention subscription unless she asks first (P1).

### 11.3 Nightly check-in (S2 → S3), 21:00 local

**With a step given:**
```
ADAM: كيف كانت محاولتكِ مع {child} اليوم؟
      «{step_text}»

      [نجحت]  [جرّبتِ وما نجحت]  [ما جرّبتها]
```

**Without a step:**
```
ADAM: كيف كانت الليلة مع {child}؟

      [هادئة]  [صعبة]  [عادية]
```

**If "صعبة" or "جرّبتِ وما نجحت":**
```
ADAM: متى كان الأصعب؟

      [عند الأكل] [عند النوم] [عند الخروج]
      [وقت الشاشة] [عند الدراسة] [موقف آخر]
```

**Response to each outcome — never neutral, never effusive:**

| Answer | ADAM replies |
|---|---|
| نجحت | "هذا أنتِ من فعلتِ ذلك. سنبني عليها غداً." |
| جرّبتِ وما نجحت | "المحاولة نفسها تغيّر شيئاً. غداً نجرّب زاوية أخرى." |
| ما جرّبتها | "لا بأس. ليس كل ليلة تحتمل محاولة." |
| هادئة | "ليلة هادئة تُحتسب. 🌿" |
| صعبة | "ليلة صعبة لا تلغي ما قبلها." |

**Critical:** "ما جرّبتها" must never carry disappointment. A parent who feels judged for not trying will stop logging, and logging is the entire proof engine.

### 11.4 The First Mirror (S3 → S4) — the conversion moment

Fires when `nights_logged >= 3`. Data-gated, never day-gated.

```
ADAM: لاحظتُ شيئاً معكِ 🌿

      الليالي حتى الآن:
      ▓▓▓░░  (٣ من ٥ هادئة)

      والموقف المتكرر في الليالي الصعبة: عند النوم (٣ مرات)

      الخطوة التي نجحت أكثر: «الجلوس بلا شرح»

      هذا نمط حقيقي بنيتِه أنتِ — لم تكوني ترينه بهذا الوضوح من قبل.
```

**Why this converts where feature lists don't:** it is evidence about *her*, produced from *her* data, that she could not have assembled alone. It makes the invisible (memory) visible (progress). This is the single most important message in the product.

**No offer attached.** The Mirror must never carry a sales message. It earns the ask; it does not make it.

### 11.5 The Ask (S4 → S5) — parent-initiated only

Available as a persistent, quiet affordance. Never pushed.

When she asks:
```
ADAM: في المساحة المجانية أنا معكِ في كل لحظة صعبة — دائماً، بلا مقابل.

      المرافقة الكاملة شهر كامل نمشيه معاً:
      أعرف طبع {child} وما يفجّر الموقف ومايهدّئه
      خطوة كل يوم مفصّلة عليه هو
      وفي نهاية الشهر، تقرير يريكِ بالضبط كم تغيّرتِ

      {price} — مرة واحدة، لثلاثين يوماً.
      إن لم تشعري بفرق حقيقي، أمدّد لكِ شهراً بلا مقابل.

      [أريد أن أبدأ]  [ليس الآن]
```

**"ليس الآن" response:**
```
ADAM: لا شيء يتغيّر بيننا. أنا هنا كل ليلة كما كنت. 🌿
```
Then never raise it again unprompted.

**Price is injected from configuration, never generated.** (§8.2)

### 11.6 Day-30 Report (S7 → S8)

```
ADAM: اليوم يكتمل شهركما.

      بدأتِ هنا:   ▓░░░░░░░░░  (١ من ١٠ ليالٍ هادئة)
      أنتِ الآن هنا: ▓▓▓▓▓▓▓░░░  (٧ من ١٠)

      الموقف الذي كان يهزمكِ: عند النوم
      اليوم: ست ليالٍ متتالية دون معركة

      ما تعلّمناه عن {child}: يحتاج تنبيهاً قبل الانتقال، لا أوامر مباشرة

      هذا لم يفعله أحد غيركِ.
```

Then, separately — never in the same message:
```
ADAM: إن أردتِ أن نواصل شهراً آخر: {continuation_price}
      وإن اخترتِ التوقف، أبقى معكِ في المساحة المجانية كما كنت دائماً.
```

**The separation is deliberate.** Achievement and commerce must not share a message (P1).

### 11.7 Crisis path (X1) — overrides everything

**Detection categories:** self-harm or suicidal ideation · domestic violence · child physical/sexual abuse by a third party · parent's own escalating violence · bereavement · substance use in a minor.

**Behaviour on detection:**
1. **Suppress all commercial messaging** for this conversation + 7 days
2. **Suppress memory write** for the sensitive content (already correctly encoded in Heart Writer — P9)
3. **Contain, do not advise:**
```
ADAM: أنا معكِ.
      ما تحملينه أثقل من أن يُحمل وحده.
      [containment line specific to category]
      أنا هنا. تحدّثي متى شئتِ.
```
4. **Raise CrisisFlag → human queue.** No automated advice on these categories.
5. **Never give clinical, legal, or safeguarding instructions.**

**This is the one area where the product must not act autonomously.** See §29 — the escalation destination is a founder decision, not a product decision.

---

## 12. UX flows

### 12.1 Interaction inventory (complete)

| Interaction | Input | Trigger | State |
|---|---|---|---|
| First contact | `/start` | User | S0 |
| Describe a moment | Text or voice | User | S1, any |
| Ask for detail | Text or voice | User | any |
| Nightly log | Button ×3 | System 21:00 | S2+ |
| Hard-moment tag | Button ×6 | Conditional | S3+ |
| View progress | Command `/تقدمي` | User | S3+ |
| Ask about Journey | Command or button | **User only** | S4+ |
| Claim payment | Text + receipt image | User | S5 |
| Pause messages | Command `/إيقاف` | User | any |
| Resume | Any message | User | X4 |

**Ten interactions total.** Anything not on this list does not exist in v1.

### 12.2 Voice note flow (new)

```
Parent sends voice note
   → transcribe (Arabic, dialect-tolerant)
   → if confidence low: "سمعتُ: «{transcript}» — صحيح؟" [نعم] [أكتبها]
   → if confidence high: respond normally, never mention transcription
```

**Why voice matters more than it looks:** average human message is 53 characters, heavy with dialect and typos (*"مبعرف"*, *"بيتم رضرب"*, *"شو العمل😭"*). A dysregulated parent at 9pm types badly and briefly. Voice removes the effort tax at exactly the moment effort is least available.

### 12.3 Payment flow (manual, by design)

```
[أريد أن أبدأ]
   → ADAM shows price + method for her country
   → "أرسلي صورة الوصل هنا"
   → Parent sends image  →  S6 payment_claimed
   → ADAM: "وصلني. سأؤكّد خلال ساعات، وأخبركِ."
   → Operator confirms in console  →  S7 journey_active
   → ADAM: "بدأنا. 🌿"
```

**If unconfirmed after 72h:** ADAM apologises and escalates to operator. Never silently drops.

**If country has no rail (X2):**
```
ADAM: المرافقة الكاملة ليست متاحة في بلدكِ بعد — لا أستطيع استقبال الدفع هناك حتى الآن.
      لكن كل ما بيننا يبقى كما هو، مجاناً، دائماً.
      أخبركِ أول ما تتاح. [أخبريني]
```
This converts a dead end into a measured demand signal — the evidence needed to justify opening a market.

---

## 13. Feature map

Every feature answers four questions. Features that could not are absent.

### F1 — The Moment (free, core)

| | |
|---|---|
| **Why it exists** | The highest-value, zero-coverage need: help *during* escalation |
| **Evidence** | 132 hitting / 78 anger / 42 screaming messages; *"بسيبه وادخل الحمام جري علشان ابعد عنهم قبل ما اتصرف تصرف غبي"* |
| **Problem solved** | The state-access gap — she knows what to do and can't reach it while dysregulated |
| **Success measure** | Time-to-first-step < 60s (p50); Moment→Night conversion ≥ 40% |

### F2 — Nightly one-tap check-in (free)

| | |
|---|---|
| **Why it exists** | Creates the habit loop and generates the proof data |
| **Evidence** | Already built and active; button interaction matches 53-char message behaviour |
| **Problem solved** | Parents won't write daily journals; they will tap once |
| **Success measure** | ≥50% of S2+ parents log ≥3 nights in first 7 days |

### F3 — Voice input (free, new)

| | |
|---|---|
| **Why it exists** | Removes the effort tax at peak distress; handles dialect |
| **Evidence** | 53-char avg messages; heavy dialect/typos across corpus |
| **Problem solved** | Typing is hard when shaking with anger; MSA-biased text input mis-serves dialect speakers |
| **Success measure** | ≥25% of first messages are voice within 30d; session depth ≥ text baseline |

### F4 — The First Mirror (free, the wow)

| | |
|---|---|
| **Why it exists** | Makes the identity transformation visible — the thing actually being sold |
| **Evidence** | Built, data-gated at 3+ nights, **fired zero times**; transformation is identity-level per §5 |
| **Problem solved** | Memory is invisible and unsellable; progress is visible and desirable |
| **Success measure** | ≥30% of Mirror recipients open the Journey ask within 7 days |

### F5 — Weekly Mirror (paid)

| | |
|---|---|
| **Why it exists** | Sustains the paid month's felt value between purchase and Day-30 |
| **Evidence** | *"خسارة انك لا تذكرني"* — continuity is explicitly wanted |
| **Problem solved** | A 30-day purchase with no mid-point proof feels like a gamble |
| **Success measure** | ≥70% of journey parents still logging at day 21 |

### F6 — Day-30 Report (paid)

| | |
|---|---|
| **Why it exists** | Delivers T5 (identity shift) and is the repurchase trigger |
| **Evidence** | Transformation milestones §5; Renewal Guard D-0 already contains 80% of the content |
| **Problem solved** | Repurchase needs proof, not a calendar reminder |
| **Success measure** | ≥25% continuation rate |

### F7 — Flashpoint learning (free → deepens paid)

| | |
|---|---|
| **Why it exists** | Turns scattered complaints into one named, trackable problem |
| **Evidence** | `hard_moment` taxonomy already validated; #1–#5 themes are all situational |
| **Problem solved** | "My child is difficult" is unsolvable; "bedtime transitions" is solvable |
| **Success measure** | ≥60% of S4 parents have a confirmed flashpoint |

### F8 — Child identity (name + age band, inferred)

| | |
|---|---|
| **Why it exists** | Using the child's name is the strongest felt-continuity signal available |
| **Evidence** | Heart Writer already extracts it; existing check-in uses it; never invents it |
| **Problem solved** | Generic advice feels generic; named advice feels personal |
| **Success measure** | ≥70% of S3 parents have a child name captured **without being asked** |

### F9 — Quiet ask (free)

| | |
|---|---|
| **Why it exists** | Lets willingness-to-pay surface without ever pushing |
| **Evidence** | 8 proactive offers → **0 clicks on both buttons**, while live |
| **Problem solved** | Proactive selling into grief destroys trust and converts nobody |
| **Success measure** | ≥10% of S4 parents open it unprompted |

### F10 — Manual payment + operator console

| | |
|---|---|
| **Why it exists** | It is the only rail available, and founder confirms it is sufficient to start |
| **Evidence** | One confirmed payment (490 EGP) came through exactly this path |
| **Problem solved** | No card infrastructure in target markets |
| **Success measure** | Claim→confirm < 6h (p50); zero unconfirmed >72h |

### F11 — Crisis detection + containment

| | |
|---|---|
| **Why it exists** | Duty of care |
| **Evidence** | Abuse, bereavement, substance use, parental violence present in corpus |
| **Problem solved** | An AI giving parenting advice into a violence situation is a real harm risk |
| **Success measure** | 100% of flagged conversations reach human review < 24h; zero commercial messages sent in X1 |

### F12 — Free-everywhere access

| | |
|---|---|
| **Why it exists** | Half of demand is being discarded for no benefit |
| **Evidence** | 140/289 blocked; 23,697 unserved audience; two independent sources |
| **Problem solved** | Geography gating *usage* costs the audience, the data, and the word-of-mouth |
| **Success measure** | Unserved-country signups ≥40% of new; "notify me" list as market evidence |

### F13 — Content→product bridge

| | |
|---|---|
| **Why it exists** | Highest-ROI hour available in the entire business |
| **Evidence** | 525,682 vs 445–770 reach; ~0.7% audience→bot conversion |
| **Problem solved** | Enormous audience, almost no door |
| **Success measure** | Audience→bot conversion 0.7% → ≥2% on bridged posts |

---

## 14. Value ladder

| Rung | Offer | Price | Job served | Gate |
|---|---|---|---|---|
| **0** | Instagram content | Free | Awareness; naming the pain | None |
| **1** | **The Moment** — unlimited conversation, voice, crisis presence | **Free forever, every country** | Functional + emotional | None |
| **2** | **The Nightly Loop + First Mirror** | **Free** | Social (proof) begins | 3 nights logged |
| **3** | **The Journey** — 30 days, flashpoint tracking, weekly Mirrors, Day-30 Report | **$10 equivalent, one-time** | Full transformation | Parent-initiated + payment rail |
| **4** | **Continuation** — next 30 days | **~$6–7 equivalent** | Sustained change | Completed a Journey |
| **5** | *(Later)* The Circle — peer presence | TBD | "I'm not alone" | Not in scope |

**The ladder's load-bearing design choice:** rung 2 is free. The wow moment is given away. That is what earns the right to rung 3, and it is the inverse of the current model, where everything is free and the paid tier adds an invisible mechanism.

---

## 15. Activation strategy

### Definitions

| Term | Definition | Why this threshold |
|---|---|---|
| **First Value** | Received a usable step in first session | The relief moment (T1) |
| **Activated** | Logged 3 nights AND received First Mirror | The proof moment (T3) — the gate that predicts conversion |
| **Habituated** | Logged ≥8 nights in first 14 days | Loop has become automatic |

### Activation funnel with targets

| Step | Target | Current baseline |
|---|---|---|
| `/start` → first message | ≥80% | 62.6% (understated — counter bug) |
| First message → First Value | ≥90% | Not measured |
| First Value → 1 night logged | ≥50% | Not measured |
| 1 night → 3 nights (**Activated**) | ≥50% | Not measured |
| Activated → opens the ask | ≥30% | 0% (Mirror never fired) |

### The three activation interventions

1. **Delete the onboarding form.** 94.1% abandonment. Fields are inferred from conversation by the existing extractor. *This single change recovers the majority of the funnel.*
2. **Delete the country gate on usage.** 48.4% blocked at the door. (P8)
3. **Fire the First Mirror.** It exists, it is data-gated at 3+ nights, and it has fired zero times. It is the designed activation payoff.

**Note on ordering:** all three are deletions or switch-ons. None requires new product invention. This is the cheapest activation improvement available to the business.

---

## 16. Habit loop

Designed as an explicit Hook cycle.

```
┌──────────────────────────────────────────────────────────┐
│  TRIGGER                                                 │
│   External: 21:00 nightly check-in                       │
│   Internal: the felt moment of losing control            │
│   (the internal trigger is the goal — external scaffolds)│
└───────────────────────┬──────────────────────────────────┘
                        ▼
┌──────────────────────────────────────────────────────────┐
│  ACTION — minimum viable effort                          │
│   One tap. Or one voice note.                            │
│   Never: a form, a paragraph, a rating scale             │
└───────────────────────┬──────────────────────────────────┘
                        ▼
┌──────────────────────────────────────────────────────────┐
│  VARIABLE REWARD                                         │
│   Sometimes: recognition ("هذا أنتِ من فعلتِ ذلك")          │
│   Sometimes: a new angle for tomorrow                    │
│   Sometimes: a pattern noticed ("ثالث مرة عند النوم")      │
│   Occasionally: the Mirror — the jackpot                 │
│   Variability is required. A constant reply becomes noise│
└───────────────────────┬──────────────────────────────────┘
                        ▼
┌──────────────────────────────────────────────────────────┐
│  INVESTMENT                                              │
│   Each logged night makes the next Mirror richer.        │
│   The parent is building an asset about herself.         │
│   → loads the next trigger                               │
└──────────────────────────────────────────────────────────┘
```

**Why the investment step is the strategic core:** logged nights are not telemetry, they are *her* accumulating evidence. This is what makes leaving costly in a way that is honest rather than manipulative — she'd be abandoning her own record, not a subscription.

**Anti-patterns explicitly banned:** streak-shaming, guilt-based re-engagement, notification escalation, "you haven't logged in 3 days!" All conflict with P3.

---

## 17. Growth loop

```
        ┌─────────────────────────────────────────┐
        │  Content naming a parenting pain        │
        │  (proven: 525,682 reach, 20,991 shares) │
        └──────────────────┬──────────────────────┘
                           ▼
        ┌─────────────────────────────────────────┐
        │  Moment-framed CTA (NEW — the bridge)   │
        │  "إذا كنتِ في هذه اللحظة الآن — اكتبي لي"  │
        └──────────────────┬──────────────────────┘
                           ▼
        ┌─────────────────────────────────────────┐
        │  Value in < 60 seconds                  │
        └──────────────────┬──────────────────────┘
                           ▼
        ┌─────────────────────────────────────────┐
        │  Nightly loop → First Mirror            │
        └──────────────────┬──────────────────────┘
                           ▼
        ┌─────────────────────────────────────────┐
        │  Parent tells another parent            │
        │  AND generates new content raw material │
        └──────────────────┬──────────────────────┘
                           │
                           └──► feeds content ────┘
```

**The loop's compounding asset:** every conversation teaches which pains are most common in which countries — which directly informs the next post. The product feeds the content engine that feeds the product. That is a genuine loop, not a funnel.

**Current break point:** the bridge. 0.7% of audience has reached the bot. Fixing this is a copy change on existing high-performing posts.

---

## 18. Referral loop

### Design constraint discovered in the evidence

The obvious mechanic — "share your progress" — is **wrong for this audience**. Sharing "3 of 5 nights calm" also discloses two hard nights to her social circle. In a shame-loaded context, that is a disincentive.

**But** parents already share at enormous volume: 20,991 shares on one post. They share **the insight, not themselves.**

### The mechanic

**Share the insight, never the scorecard.**

At the Day-30 Report and after notable wins, ADAM offers a clean, beautiful card containing the *learning* — never her data:

```
┌──────────────────────────────┐
│  الرفض عند النوم              │
│  ليس عناداً —                 │
│  هو خوف من الانفصال في الظلام.│
│                              │
│              آدم 🌿           │
└──────────────────────────────┘
```

She shares it because it makes her look insightful, not because it exposes her struggle.

**Second mechanic — the direct pass:**
```
ADAM: تعرفين أمّاً تمرّ بهذا الآن؟
      أرسلي لها هذا. سأكون معها كما كنت معكِ. [مشاركة]
```

**No incentive, no reward, no referral code.** Paying for referrals in a trust-based, shame-adjacent product corrupts the motive and risks the moat. The share is offered once, at a moment of pride, and never repeated.

**Success measure:** ≥15% of Day-30 completers share; referred-parent share of new signups ≥10% by month 3.

---

## 19. Monetization strategy

### Model: **Free Rescue + Paid Journey (one-time, repeatable)**

| Layer | Contents | Price | Available |
|---|---|---|---|
| **Rescue** | Unlimited conversation, voice, the Moment, nightly loop, First Mirror, crisis presence | **Free forever** | **Every country** |
| **Journey** | 30 days: named child, tracked flashpoint, weekly Mirrors, Day-30 Report | **$10 equivalent, one-time** | Where a rail exists |
| **Continuation** | Next 30 days | **~$6–7 equivalent** | After a completed Journey |

### Why one-time, not subscription — four evidenced reasons

1. **It matches the actual rail.** Payment is collected manually. A "subscription" collected by manual bank transfer is a one-time purchase in a costume — and Machine 5 exists solely to manage that costume. Drop the costume, delete the machine.
2. **It removes renewal anxiety.** No recurring commitment to fear. Directly attacks the unaddressed Anxiety force (§7).
3. **It makes the Day-30 Report the sales moment.** Repurchase is triggered by demonstrated progress, not a calendar date. Selling on proof is stronger than selling on a deadline.
4. **It resolves the betrayal.** When 30 days end, nothing is confiscated — the free companion remains exactly as warm. She loses the *journey*, not the *relationship*. Directly answers *"انت طلعت بفلوس اخص عليك"*.

### What is never monetised

- The moment of crisis (P1)
- Any conversation in state X1 (P1, F11)
- Access to ADAM at all, in any country (P8)
- Emotional availability

---

## 20. Pricing strategy

### Structure

| Offer | Price | Basis |
|---|---|---|
| **First Journey** | $10 equivalent — 2,300 DZD / 490 EGP / 110 MAD | The only real datapoint is a completed 490 EGP payment. Do not discount away from your one proof |
| **Continuation** | ~$6–7 equivalent | Rewards demonstrated progress; lowers friction where Habit is weakest |
| **Rescue** | Free, permanently | Ethical floor + acquisition engine |

### Pricing rules (non-negotiable)

1. **Price is injected into agent context from configuration.** The agent must never generate a number. *(It invented "150 EGP"; the real price is $10-equivalent. That is a broken promise to a customer, and it is a trivially preventable defect.)*
2. **One published price per market.** Never improvised, never negotiated in conversation.
3. **Keep the 30-day guarantee.** Strongest available Anxiety-reducer, near-zero cost at these volumes.
4. **Never discount to a parent in distress.** Warmth is free; the Journey has a price. Blurring this teaches parents to negotiate while suffering, which is corrosive for both sides.

### On the affordability objection

*"صراحة ما بقدر على الاشتراك"* is real and will not go away. **The answer is not a lower price — it is that she never needs to pay to be helped tonight.** The free layer answers affordability completely. The Journey is for parents ready to invest a month in change, and that will always be a minority. It only needs to be a viable minority.

---

## 21. Success metrics

### Metric tree

```
NORTH STAR: Tracked Parents
(parents with ≥3 nights logged in trailing 7 days)
   │
   ├── ACQUISITION
   │     Audience→bot conversion       target ≥2%   (now 0.7%)
   │     New parents / week
   │     Unserved-country share        target ≥40%
   │
   ├── ACTIVATION
   │     /start → first message        ≥80%
   │     First message → First Value   ≥90%
   │     First Value → 1 night         ≥50%
   │     1 night → 3 nights            ≥50%
   │
   ├── ENGAGEMENT
   │     Nights logged / parent / week ≥4
   │     Session depth (human turns)   ≥8   (now 11.1 — protect it)
   │     Moment→Night conversion       ≥40%
   │
   ├── TRANSFORMATION  (the product's real output)
   │     Calm-night ratio, week 1 → week 4
   │     Flashpoint identified          ≥60% of S4
   │     Step-success rate trend
   │
   ├── MONETIZATION
   │     Mirror → ask opened            ≥30%
   │     Ask → payment claimed          ≥20%
   │     Claim → confirmed              ≥95%
   │     Journey completion             ≥70%
   │     Continuation rate              ≥25%
   │
   └── TRUST  (counter-metrics — guardrails)
         Crisis flags → human < 24h     100%
         Commercial messages in X1      0  (hard zero)
         Block/mute rate                <2%
         Hallucinated price incidents   0  (hard zero)
```

### Guardrail metrics — a breach halts the roadmap

| Guardrail | Threshold | Rationale |
|---|---|---|
| Commercial message sent during crisis state | **0, always** | P1 |
| Crisis flag unreviewed > 24h | **0** | Duty of care |
| Hallucinated price | **0** | Trust is the moat |
| Parent block/mute rate | **< 2%** | Early signal of over-messaging |
| Median reply latency | **< 15s** | The moment doesn't wait |

---

## 22. North Star Metric

> ## Tracked Parents
> **The number of parents who logged ≥3 nights in the trailing 7 days.**

### Why this metric

| Criterion | Assessment |
|---|---|
| **Reflects delivered value** | ✅ A logged night means she engaged with a hard moment deliberately rather than just surviving it |
| **Leads revenue** | ✅ 3 nights is exactly the gate that unlocks the First Mirror, which is the conversion engine |
| **Team can move it** | ✅ Directly improved by activation, habit, and check-in quality |
| **Hard to game without real value** | ✅ Requires sustained voluntary daily action from an exhausted person |
| **Honest** | ✅ Rises only if parents genuinely return |

### Rejected alternatives

| Candidate | Why rejected |
|---|---|
| Total messages | Rewards verbosity; current data shows AI verbosity already (363 vs 53 chars) |
| Weekly active users | Doesn't distinguish a passer-by from a parent doing the work |
| Revenue | Lags too far; n=1 payment gives no signal at this stage |
| Calm-night ratio | It is an *outcome* we must not incentivise gaming — a parent should never feel pressure to report calm |
| Sessions | Already high (11.1 turns) while conversion is zero — proves it doesn't lead value |

**Important guardrail:** Tracked Parents counts *logging*, deliberately not *calm nights*. Optimising for reported calm would pressure parents to misreport, corrupting both the data and the trust. We measure participation; we report outcome.

---

## 23. Product analytics events

Complete v1 event schema. Every event carries `parent_id`, `timestamp`, `state`, `country`, `tier`.

### Lifecycle
| Event | Properties | Answers |
|---|---|---|
| `parent_started` | source, campaign | Where do parents come from? |
| `parent_state_changed` | from, to, reason | Where does the funnel leak? |
| `parent_dormant` | days_inactive, last_state | When do we lose them? |
| `parent_returned` | days_away | Does reactivation work? |

### Conversation
| Event | Properties | Answers |
|---|---|---|
| `message_received` | channel(text/voice), char_count, is_first | Is voice adopted? |
| `first_value_delivered` | seconds_since_start | Are we under 60s? |
| `step_given` | flashpoint_id, step_hash | Which steps work? |
| `crisis_detected` | category, confidence | How common, which types? |
| `crisis_reviewed` | hours_to_review, outcome | Are we meeting duty of care? |

### The loop
| Event | Properties | Answers |
|---|---|---|
| `checkin_sent` | local_hour, has_step | Is timing right? |
| `night_logged` | result, hard_moment, step_outcome, night_index | **Feeds the North Star** |
| `checkin_ignored` | consecutive_count | Are we over-messaging? |
| `flashpoint_identified` | label, nights_to_identify | How fast do we get useful? |

### Proof
| Event | Properties | Answers |
|---|---|---|
| `mirror_generated` | kind, nights_included, calm_ratio | Does it fire when it should? |
| `mirror_delivered` | kind | Delivery integrity |
| `mirror_reacted` | reaction_type | Does it land emotionally? |

### Commerce
| Event | Properties | Answers |
|---|---|---|
| `ask_opened` | trigger(user/command), days_since_mirror | **Is the Mirror converting?** |
| `ask_declined` | — | Rejection rate without pressure |
| `payment_claimed` | amount, currency, method | Claim volume |
| `payment_confirmed` | hours_to_confirm | Operator SLA |
| `journey_started` / `journey_completed` | nights_logged, calm_delta | Does the paid month deliver? |
| `continuation_purchased` | — | True retention |
| `payment_blocked_country` | country | **Demand evidence for market opening** |

### Growth
| Event | Properties | Answers |
|---|---|---|
| `bridge_clicked` | post_id, post_reach | Which content converts? |
| `insight_shared` | context | Referral engine health |
| `referred_signup` | referrer_parent_id | Loop is closing? |

**Explicitly not tracked:** message content in analytics, anything from an X1 conversation, any field that would let an operator browse a parent's disclosures casually. Analytics gets counts and categories, never intimate text.

---

## 24. Experiment roadmap

Ordered by information value per day of effort.

| # | Experiment | Hypothesis | Method | Kill signal | Effort |
|---|---|---|---|---|---|
| **E1** | **Gulf concierge test** | Waitlisted high-ATP parents will pay | Manually serve 10 Gulf parents end-to-end, human-in-the-loop | 0/10 pay | **Days, no engineering** |
| **E2** | **Fire the First Mirror** | Visible progress converts where memory doesn't | Switch on; measure ask-opened within 7d | <5% open the ask | Switch-on |
| **E3** | **Delete onboarding** | Form is pure loss | Remove; compare activation + extraction quality | Extraction materially worse | Deletion |
| **E4** | **Free-everywhere** | Serving all countries grows more than it costs | Remove gate; track cost/parent vs referral | Cost outruns any signal | Deletion |
| **E5** | **Content bridge** | Moment-framed CTA beats product CTA | A/B on 3 high-reach posts | No lift over baseline 0.7% | Copy only |
| **E6** | **Voice input** | Voice increases depth and activation | Ship; compare cohorts | No lift | Medium |
| **E7** | **Price test** | $10 is right for EG | $10 vs ~$5 split | Both <2% | Config |
| **E8** | **Pride vs guilt copy** | Pride converts better at the ask | Split by `signup_source` | No difference | Copy only |
| **E9** | **Global rail (Telegram Stars)** | A no-agent rail exists | Feasibility + small live test | Not workable in target markets | Research |

**E1 first, deliberately.** Ten manual conversations with Gulf parents will teach more about the real market than any funnel optimisation in DZ/EG/MA — and it requires zero engineering. It also directly de-risks the largest strategic bet in this blueprint (F12/P8).

---

## 25. Product roadmap

### NOW — weeks 0–4 (correctness, deletions, the wow)

**Week 0 — nothing ships until these are done**
1. Rotate exposed credentials; migrate to credential references *(service-role key currently bypasses RLS on 4,172 intimate conversations)*
2. Fix derived engagement counters + the 47 orphaned sessions *(without this, nothing below is measurable)*
3. Inject price into agent context + hallucination guard
4. Cap generated message length *(one stored message is 169,230 chars)*
5. Stop persisting agent scaffolding into stored user messages

**Weeks 1–2 — the deletions and the switch-on**
6. Remove the country gate on usage (F12)
7. Remove the onboarding form (activation §15)
8. Fire the First Mirror (F4)
9. Content→product bridge on top 3 posts (F13)
10. Remove the Judge and Silent Seller
11. Fix the mother-only assumption in memory extraction

**Weeks 3–4 — the new core**
12. The Moment as an explicit flow (F1)
13. Voice input (F3)
14. Quiet ask, parent-initiated only (F9)
15. Journey reframe: 30 days, one-time (F10)
16. Crisis detection + containment + human queue (F11)
17. **E1 Gulf concierge test runs in parallel throughout**

**Decision gate at week 4:** ≥5% of Mirror recipients open the ask, AND ≥2 of 10 concierge parents pay → proceed. Otherwise the identity-transformation thesis is wrong and we return to §1.

### NEXT — months 2–3

| Item | Rationale |
|---|---|
| Weekly Mirror + Day-30 Report (F5, F6) | Completes the paid experience |
| Continuation offer | Real retention test |
| Speech/development track | #3 theme (98 messages), entirely unserved |
| Flashpoint depth (F7) | Multi-week pattern tracking |
| Referral: shareable insight cards (§18) | Growth loop closes |
| Operator console v1 | Founder is currently the bottleneck |
| Global payment rail (E9) | Unlocks 23,697 |

### LATER — months 4+

| Item | Precondition |
|---|---|
| The Circle (peer presence) | Only after retention is proven; large build |
| Multi-child support | Only when data shows demand — currently 3 children rows |
| Collective intelligence | The corpus is a genuine long-term moat; needs privacy design first |
| Additional markets | Requires a rail; E1 evidence justifies |
| Partner/institutional | Almost no evidence today — do not build on speculation |

---

## 26. Risks and assumptions

### Assumptions requiring validation, ranked by damage-if-wrong

| # | Assumption | Test | Damage if wrong |
|---|---|---|---|
| **A1** | Visible progress converts better than memory | E2 | **Fatal** — the core thesis |
| **A2** | Parents pay for completed transformation, not access | Day-30 → continuation | **Fatal** — the business model |
| **A3** | Waitlisted (Gulf) parents will pay | E1 | High — the growth thesis |
| **A4** | Free-everywhere costs less than it returns | E4 | High — unit economics |
| **A5** | $10 is right for this audience | E7 | Medium — recoverable |
| **A6** | Voice materially lifts engagement | E6 | Low — recoverable |
| **A7** | Removing onboarding doesn't degrade personalisation | E3 | Low — reversible |
| **A8** | Pride converts better than guilt | E8 | Low |
| **A9** | A global rail exists | E9 | Medium — gates scale |

### Risk register

| # | Risk | Severity | Mitigation |
|---|---|---|---|
| **R1** | **Safeguarding** — parents disclose abuse and their own violence to an AI with no escalation | 🔴 Critical | F11 + human protocol **before scale**. §29 |
| **R2** | **Exposed credentials** — service-role key bypasses RLS on 4,172 intimate conversations | 🔴 Critical | Week 0, item 1 |
| **R3** | **The Mirror doesn't convert** | 🟠 High | E2 before building further on the thesis |
| **R4** | **Free-everywhere burns cash** | 🟠 High | Weekly cost/parent monitoring; generous but finite fair-use |
| **R5** | **Founder is the payment rail** | 🟠 High | Fine now; binding at ~50 customers. Operator console in NEXT |
| **R6** | **Advice quality in violence-adjacent situations** | 🟠 High | Weekly human review sample; hardened refusals |
| **R7** | **Retention unproven** — oldest cohort ~4 weeks, 4 users with return_count ≥3 | 🟡 Medium | Day-30 Report *is* the test |
| **R8** | **Brand promise shift confuses 41k audience** | 🟡 Medium | Evolve over a quarter; keep name and identity |
| **R9** | **Trust collapse from one bad interaction** in a shame-loaded context | 🟡 Medium | The no-blame discipline is already excellent — protect it absolutely |
| **R10** | **Voice transcription fails on dialect** | 🟡 Medium | Confidence threshold + text fallback (§12.2) |

---

## 27. Features to remove / keep / build

### REMOVE

| Feature | Why | Evidence |
|---|---|---|
| Country gate on **usage** | Discards half of demand for zero gain | 140/289 blocked; 23,697 unserved |
| 6-step onboarding form | Asks before giving | 94.1% abandonment |
| The Judge (Machine 4-J) | Elaborate scoring for an unwanted pitch | 8 offers → 0 clicks, **while live** |
| Silent Seller (proactive offer) | Interrupts grief with a sale | 0/8 on **both** buttons; 4 of 8 never returned |
| "Subscription" framing + Renewal Guard | Doesn't match a manual rail; you built a machine to fight friction you created | Machine 5 exists solely for this |
| Selling "memory" as the benefit | Your own prompt concedes nobody buys it | *"لا أحد يشتري ذاكرة"* |
| `main_pain` fixed 8-value enum | Forced a taxonomy that missed the #3 theme | Speech/development = 98 messages, no category |
| `messages`, `collective_intelligence`, `weekly_plans`, `survey_responses` tables | Dead — 0 rows each | Schema |
| Mother-only assumption in extraction | 18.5% of audience is male | Prompt hardcodes *"أمٍّ"* |
| Hardcoded credentials in nodes | Bypasses RLS on intimate data | §8.2 |
| Uncapped reactivation | Re-engaging someone who left is how you get muted | No lifetime cap today |

### KEEP (and protect)

| Feature | Why it must not be touched |
|---|---|
| **The no-blame prompt discipline** | *"هي متعبة لا مذنبة"* — this is the moat |
| **Heart Writer safety rule** | *"الذاكرة الناقصة أرحم ألف مرة من الذاكرة التي تجرح"* — genuinely exemplary |
| **2–3 line response constraint** | Correctly matched to an exhausted reader |
| **Full prescription, never withheld** | *"الحبس مقابل الدفع هو أكبر قاتل للقيمة"* — correct |
| **Nightly one-tap check-in** | Built, active, and the habit engine |
| **Show-don't-announce memory** | Announcing memory reads as surveillance |
| **Ban on scarcity and urgency** | Incompatible with the trust position |
| **30-day guarantee** | Strongest Anxiety-reducer available |
| **Brand name and identity** | 41,100 followers; 525k-reach proof |

### BUILD

| Feature | Priority | Ref |
|---|---|---|
| The Moment as explicit flow | NOW | F1 |
| Voice input | NOW | F3 |
| First Mirror **firing** | NOW | F4 |
| Quiet parent-initiated ask | NOW | F9 |
| Crisis detection + human queue | NOW | F11 |
| Free-everywhere access | NOW | F12 |
| Content bridge | NOW | F13 |
| Weekly Mirror | NEXT | F5 |
| Day-30 Report | NEXT | F6 |
| Flashpoint depth | NEXT | F7 |
| Operator console | NEXT | F10 |
| Shareable insight cards | NEXT | §18 |

---

## 28. Decisions challenged and rejected

Alternatives seriously considered and turned down, with reasons — so they are not silently revisited.

| Considered | Rejected because |
|---|---|
| **Keep the subscription model** | Manual collection makes every renewal a friction event; you built Machine 5 to fight a problem the model itself creates |
| **Lower the price to ~$3** | Your only real datapoint is a completed $10-equivalent payment. Free rescue solves affordability; discounting solves nothing and forfeits your one proof |
| **Freemium with message caps** | Paywalls the crisis. Directly violates P1 and reproduces the observed betrayal |
| **Build a mobile app** | Adds a surface with no evidenced job. Telegram is where the audience already is |
| **Sell a course** | Competes with your own free content and serves *knowing*, which the evidence says is not the gap |
| **Ads** | Destroys the no-judgement trust that constitutes the entire moat |
| **B2B / schools / clinics** | Almost no evidence in 2,086 messages. Building on speculation |
| **Community in MVP** | Real job ("I'm alone"), but a large build with moderation risk in a shame-loaded context. Deferred to LATER, gated on retention |
| **Gamified streaks** | Streak-shaming a parent who had a hard night violates P3 catastrophically |
| **Incentivised referral** | Paying for referrals in a trust-based product corrupts the motive |
| **Child-behaviour tracking as the hero** | Points the product at the child; the evidence says the job is the parent's identity |
| **Rename the brand** | 41,100 followers and a 525k-reach proof point. Evolve the promise, keep the name |
| **Keep the Judge but improve its scoring** | The failure was strategic, not algorithmic. Better targeting of an unwanted pitch is still an unwanted pitch |

---

## 29. Open decisions requiring founder input

These are **not** product decisions and I have deliberately not made them.

| # | Decision | Why it's yours | Blocking |
|---|---|---|---|
| **D1** | **Crisis escalation destination.** When a parent discloses abuse, suicidal ideation, or their own violence — what happens? A human replies? A referral to a named local service? A defined boundary ("I can't help with this, here is who can")? | Duty of care, legal exposure, and your capacity. No defensible automated answer exists | **Blocks F11 and therefore scale** |
| **D2** | **Who staffs the crisis queue, and within what SLA?** | Depends on your team and hours | Blocks F11 |
| **D3** | **Fair-use ceiling for the free tier.** Unlimited is the principle; some finite ceiling is the reality | Depends on your cost tolerance | Blocks F12 rollout |
| **D4** | **Which market to open first** if E1 succeeds — Saudi (highest ATP) or Iraq (largest volume) | Depends on your access to a payment agent | Blocks post-E1 planning |
| **D5** | **What happens to the existing 289 parents and 4,172 conversations** on migration — carry memory forward, or fresh start with continuity messaging? | Relationship decision, not technical | Blocks Week 1 |
| **D6** | **Whether ADAM ever says it is an AI.** One parent asked directly: *"هل انت ذكاء اصطناعي مجاني ام مدفوع"* | Positioning and ethics call | Should be settled before scale |

**D1 is the true blocker.** Everything else can proceed in parallel, but scaling a product that receives disclosures of violence without a defined human path is not something I would recommend building past the pilot stage.

---

**End of blueprint. No implementation has begun. Awaiting your approval.**
