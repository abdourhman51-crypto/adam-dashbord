# ADAM — Product Blueprint v3

**Date:** 2026-07-30
**Status:** Specification for review. **No implementation. Awaiting approval.**
**Supersedes:** v2 (2026-07-30) and v1 (2026-07-29), both in git history.

**Governing rule:** the twenty decisions in *PRODUCT DECISIONS v2* override anything that contradicts them. Where v2 conflicted, v2 is void. §0 records what changed and §26 lists every conflict resolved.

**Organising rule (Decision 020):** this document is structured around **five engines**, not a feature list. Nothing exists outside an engine.

---

## Table of contents

**Part I — The product**
0. What changed, and the conflicts resolved
1. Vision and philosophy
2. Principles
3. Positioning, voice, and the two lexicons
4. Personas and jobs
5. The free/paid boundary
6. The business unit: the Journey

**Part II — The five engines**
7. Knowledge Engine
8. Conversation Engine
9. Journey Engine
10. Telegram Engine
11. Growth Engine

**Part III — The experience**
12. Complete user journey
13. Every user state
14. Conversation flows
15. Commerce: how it reaches the parent without selling

**Part IV — Operating the product**
16. North Star and metrics
17. Analytics events
18. Experiments
19. Roadmap
20. Risks and assumptions
21. Rejected decisions
22. Open decisions

**Appendix**
23. Change log

---

# PART I — THE PRODUCT

## 0. What changed, and the conflicts resolved

### 0.1 The twenty decisions

| # | Decision | Effect here |
|---|---|---|
| 001 | ADAM is a long-term parenting companion driving a real outcome. **The conversation is not the product; the outcome is** | §1, §6 |
| 002 | **Free and paid share the same intelligence, the same answer quality, the same understanding.** Free gives knowledge, understanding, daily companionship, personalisation. Paid leads the parent through a personal journey to a clear goal | §5 |
| 003 | **Memory is the foundation of the whole product**, not a paid feature. Paid has no more memory — it uses memory to build a journey | §7 |
| 004 | **No fixed plans.** Every plan is generated from this child, this parent, the history, the knowledge, the current problem, the goal. **No templates** | §9 |
| 005 | Paid is described in outcomes. **Banned words: memory, reports, follow-up, plan, intelligence** | §3.5 |
| 006 | **ADAM does not sell.** No prices, no subscription talk, no payment methods. Purchase moves to a specialised agent | §15 |
| 007 | **All subscription and payment information lives in the Telegram Menu**, not in conversation. Supported countries see a payment method; others see a waitlist. **Prices: 2,300 DZD · 490 EGP · 110 MAD** | §10, §15 |
| 008 | **Telegram is the product surface**, not a channel: Menu, Commands, Pinned, Inline Buttons, Reply Keyboard, Deep Links — at app quality | §10 |
| 009 | The main menu is **fixed**. Exactly **one item changes** with the parent's stage | §10.3 |
| 010 | Free has a daily rhythm: **Seed → Harvest**, and Harvest is an extension of Seed, never a separate question | §9.2 |
| 011 | Timing follows the logic of the day, not fixed hours | §9.3 |
| 012 | Every message uses what is known. The child's name appears naturally whenever useful | §7 |
| 013 | Parents, not mothers. Neutral Arabic. Internal terms like **الاحتواء** never reach a user | §3.4, §3.6 |
| 014 | **Hybrid conversation:** dynamic context-generated buttons + free conversation, always with a **"شيء آخر"** button. ADAM can create new buttons mid-dialogue | §8 |
| 015 | **Supabase is the single source of truth. n8n is the nervous system. The LLM stores nothing.** Everything passes through the Knowledge Engine | §7 |
| 016 | **The Journey is the business unit, not the subscription.** Each journey has a goal, progress, adjustment, outcome. The subscription lets journeys continue | §6 |
| 017 | Country is core to the experience: payment, currency, commercial journeys, waitlist | §10.4 |
| 018 | **Assume the parent believes ADAM is entirely free.** Do not rely on them asking, and do not rely on chance discovery. The commercial model must be integrated into the experience itself, naturally and gracefully, without sales pressure | §15 |
| 019 | **Knowledge is free. Daily execution, follow-through, and the personal journey to an outcome are paid** | §5 |
| 020 | **Build engines, not features.** Knowledge · Conversation · Journey · Telegram · Growth. Nothing outside them | Whole document |

### 0.2 The one real contradiction, and how it is resolved

**Decision 006 says ADAM never mentions price or subscription. Decision 018 says do not rely on the parent asking, and do not rely on chance discovery.**

Taken literally, those two close every door: ADAM cannot speak about it, and the parent cannot be expected to ask. Something has to carry it.

**Decisions 007 and 009 are the answer, and they are why this works:**

> **The Menu is permanently visible from the first message.** It always contains what is possible and what it costs. Therefore the parent *cannot* be surprised — the commercial model was never hidden and was never announced either. There is nothing to "discover" because nothing was concealed.

That yields the seam this product is built on:

| Layer | Owns | Never does |
|---|---|---|
| **ADAM** | Naming the goal. *"نعمل على نوم يوسف — خمس ليالٍ هادئة من سبع."* Pure product | Never says a price, a currency, a payment method, or the word subscription |
| **The Menu** | Turning a goal into a startable journey. Always visible, never announced | Never notifies, never badges, never nags |
| **The sales agent** | Country, currency, price, payment, receipt, confirmation | Never gives parenting advice |

**ADAM names goals. The Menu is the door. The agent is the cashier.** Naming a goal is a product act, not a sales act — which is precisely why ADAM can do it without breaking 006.

### 0.3 Conflicts with v2, resolved in favour of the new decisions

| v2 said | Now | Why the new decision wins |
|---|---|---|
| ADAM quotes `{price}` when asked (§11.8) | **ADAM never quotes a price** | 006 |
| Discovery relies on the parent asking (Door 2 as primary path) | **The Menu carries it, permanently** | 018 |
| Persistent reply keyboard **refused** | **Adopted** | 008 |
| One-time purchase, not subscription (four evidenced reasons) | **Journey is the unit; subscription enables continuation** | 016 — see the risk in §20 R6 |
| DZD price pending confirmation | **2,300 DZD confirmed** | 007 — closes v2's D9 |
| The paid thing has no product name | **Still has no product name** — it is described as a journey toward a stated goal | Consistent with 005 |
| Fixed button sets | **Dynamic, context-generated buttons + "شيء آخر"** | 014 |
| Features F1–F16 | **Five engines** | 020 |

---

## 1. Vision and philosophy

### 1.1 The philosophy shift (001)

> **The conversation is not the product. The outcome is.**

ADAM is not an assistant that answers parenting questions well. It is a companion that takes a parent from a real problem to a real result with their own child, and stays for the next one.

Everything follows from that sentence. A brilliant answer that changes nothing is a failure. A modest suggestion that ends the bedtime fight is the product working.

### 1.2 Vision

**Ten-year**

> Every Arab parent who wants to break a cycle of shouting has someone with them in the moment it matters — and a home that is measurably calmer because of it.

**Three-year**

> ADAM is the default companion for Arabic-speaking parents in the hardest moments of raising a child: present in seconds, free to anyone, and trusted enough that parents tell it what they hide from their own families.

**One-year**

> A parent anywhere in the Arab world wakes up to one small thing worth trying with their own child, is asked that evening how it went, and after a month lives in a noticeably quieter home.

### 1.3 What we are not building

A parenting course · a content library · a diagnosis tool · a therapist replacement · a child-behaviour tracker · a chatbot that is impressive to talk to. Each rejected in §21.

---

## 2. Principles

Decision rules, in priority order.

| # | Principle | Rule in practice |
|---|---|---|
| **P1** | **The crisis is never monetised** | No price, cap or commercial surface may appear in a conversation where a parent is distressed |
| **P2** | **Never ask before you give** | No profiling question precedes the first useful answer. *94.1% onboarding abandonment* |
| **P3** | **They are tired, not guilty** | No output may attribute blame, even when factually true. *73 guilt messages in the corpus* |
| **P4** | **Fewest taps wins** | Any recurring interaction is answerable with a tap. *Avg human message = 53 chars* |
| **P5** | **Show memory, never announce it** | Never "I see in your file". Demonstrate continuity by using it |
| **P6** | **Value per effort** | 2–3 lines: one cause, one step, one measure |
| **P7** | **Honest limits** | Never promise a guaranteed child outcome |
| **P8** | **Free forever, everywhere** | Geography may gate payment. It may never gate help. *140/289 blocked; 23,697 unserved* |
| **P9** | **Silence over harm** | When memory could reopen a wound, store nothing |
| **P10** | **No scarcity, ever** | No countdowns, limited seats, expiring offers |
| **P11** | **Memory is the foundation** (003) | No proactive message may be generic. Ungrounded in *this* child → not sent |
| **P12** | **Written for both parents** (013) | Gender-free by default; rendered when known; never assume mother |
| **P13** | **A daily rhythm, not a crisis line** (010) | Free has a heartbeat: Seed, then Harvest |
| **P14** | **Timing follows the event** (011) | Scheduled relative to the moment it concerns |
| **P15** | **Free is never crippled** (002) | Same intelligence, same answer quality, same understanding. No feature is degraded to create a reason to pay |
| **P16** | **Sell the destination, never the machinery** (005) | Every commercial sentence answers *"what will my life be like in a month?"* |
| **P17** | **ADAM never sells** (006) | ADAM names goals. It never names prices |
| **P18** | **Nothing is generated from a template** (004) | Every plan, Seed and journey is generated from this family's actual knowledge |
| **P19** | **Build engines, not features** (020) | No capability exists outside the five engines |

**P1, P2, P8, P15 and P17 override commercial considerations.** A growth tactic that conflicts with them is wrong.

---

## 3. Positioning, voice, and the two lexicons

### 3.1 Positioning statement

> **For** exhausted Arabic-speaking parents who already know what good parenting looks like but cannot reach it when they are angry,
> **ADAM is** a companion that knows your child by name and walks with you to an actual result,
> **that** offers one small thing each morning, asks how it went each evening, and takes you through a named goal until the house is quieter.
> **Unlike** parenting content, courses, or general AI assistants,
> **ADAM** is already in the middle of your family's story and measures whether things actually changed.

### 3.2 The category shift

| | From | To |
|---|---|---|
| **Hero** | The child | The parent |
| **Promise** | Understand what your child doesn't say | A quieter house, and you steadier in it |
| **Proof** | ADAM explains | ADAM shows change that already happened |
| **Category** | AI parenting advice | The companion who gets you to a result |
| **Moment of use** | Whenever curious | Every morning, every evening, and the moment of losing control |

**Brand continuity:** keep the name, handle and identity. 41,100 followers and a 525,682-reach proof point. The promise evolves; the brand does not reset.

### 3.3 Voice attributes

| Attribute | Do | Don't |
|---|---|---|
| **Warm without excess** | "أنا هنا" | "حبيبتي", "قلبي", pet names |
| **Never blaming** | "الخوف صار ضيفاً ثقيلاً في البيت" | "أنتِ أخفتِها", "بسببك" |
| **Short** | 2–3 lines | Walls of text |
| **Practical** | One cause, one step, one measure | Theory, citations |
| **Honest** | "أمشي معكم ولا أعِد بطفلٍ مثالي" | "سيتوقف", "مضمون" |
| **Plain Arabic** | Simplified MSA, light dialect | Foreign words, ornate metaphor |
| **Specific to this family** | "تجربة التنبيه مع يوسف" | "جرّب التنبيه المسبق مع طفلك" |

### 3.4 Writing for both parents (013)

Arabic has no neutral second-person imperative. Neutrality is achieved **structurally**.

**Every user-facing string exists in three forms:** masculine, feminine, and a **gender-free default** used when gender is unknown. The gender-free default is primary.

| Technique | Instead of | Write |
|---|---|---|
| **Nominal sentence** | "أخبريني كيف كانت" | "والليلة: كيف كانت؟" |
| **First-person plural** | "جرّبتِ وما نجحت" | "جرّبناها وما نجحت" |
| **Button instead of imperative** | "اكتبي لي ما حدث" | `[ما حدث الليلة]` |
| **Impersonal / passive** | "ستعرفين أنها نجحت إذا…" | "علامة النجاح: أن ينام دون نداء" |
| **Respectful plural** | "أمشي معكِ" | "أمشي معكم" |

**"جرّبناها" is an upgrade, not a workaround** — warmer than "جرّبتِها", and it stops implying the outcome belonged to the parent alone.

**Ranked preference for any new string:**

1. Nominal, impersonal, or first-person plural — no gendered form needed
2. Respectful plural — acceptable as the unknown-gender form
3. Three explicit forms rendered from known gender
4. **Masculine singular as a generic — never.** 57.6% of this audience is women

**ADAM refers to himself in the masculine.** That is a name, not an assumption. Never infer the parent's gender from the child's, or from a name.

### 3.5 Banned and approved commercial vocabulary (005)

**Banned in any user-facing string — these describe machinery:**

`ذاكرة` · `تقارير` · `متابعة` · `خطة` · `ذكاء` · `اشتراك` (from ADAM) · `ميزات` · `نظام` · `تحليل`

**Approved — these describe a life:**

`هدوء أكبر في البيت` · `عناد أقل` · `فهم الطفل` · `روتين يستقر` · `صراخ أقل` · `علاقة أفضل` · `ليلة تنتهي دون معركة`

**The test:** does the sentence answer *"what will my life be like in a month?"* — or *"what is included?"* If the second, rewrite or delete.

### 3.6 The two lexicons (013)

Diagnostic vocabulary for the team that would be alienating if a parent saw it.

| Internal term | What the parent experiences |
|---|---|
| **الاحتواء** (containment) | ADAM stays, listens, and does not rush to advise |
| Seed / Harvest | A morning thought and an evening question — no names |
| Situation | The situation named plainly: "عند النوم" |
| Journey | "نعمل على نوم يوسف" — described, never labelled |
| Mirror | ADAM noticing something |
| Crisis state / X1 | Nothing. The parent never senses a mode change |
| Engine, tier, funnel, conversion | Never, in any form |

**Hard rule:** these appear in specs, code and team conversation. In a user-facing string, **never**. One in a live string is a defect, not a wording preference.

**Why "الاحتواء" specifically:** it is a therapeutic term. A parent who reads it learns they are being handled according to a protocol — the exact opposite of what the protocol exists to create.

---

## 4. Personas and jobs

### 4.1 Persona A — والد منهك · The Exhausted Parent (primary)

| | |
|---|---|
| **Who** | Parent, 25–44, across the Arab world, 1–3 children aged 2–11 |
| **Size** | The core. Gender split: 57.6% women, 18.5% men, remainder undeclared |
| **Trigger** | Late evening, after shouting or hitting, alone, flooded with shame |
| **Alternative today** | Instagram reels, family advice, the bathroom door |
| **Job** | Stop being the angry parent; be seen without judgement |
| **Evidence** | *"بنتي عمرها ٤ سنوات حاسة اني فاشله ف التربية"* · *"بس اريد اكون ام اسلوبها هادئ"* · *"انا بضرب"* |
| **Blocker** | Cannot pay by card; may be in an unsupported country |

**Two sub-variants, one job:** **A1 الأم** (57.6%) names shame more explicitly; **A2 الأب** (18.5%) frames around authority and discipline alongside connection. **Not separate personas** — treating the father as an exception is what produced a mother-default product.

### 4.2 Persona B — والد على القائمة · The Waitlisted Parent

48.4% of signups (140/289); 57.6% of audience (23,697). Identical job. The Gulf sub-segment (~5,749) has materially higher ability to pay than all three current markets. **Serve free immediately; gate only payment** (P8, 017).

### 4.3 Persona C — والد في أزمة · The Crisis Parent

Small, highest stakes. Disclosures of third-party abuse, bereavement, adolescent substance use, or the parent's own violence. *"حذرنا المعتدي سابقا"* · *"اكتشفت أنه يدخن ويتعاطى"* · *"انا بضرب"*. **The daily rhythm suspends entirely.** §14.6, §22 D1.

**Not a persona:** the curious browser. No evidence of a meaningful non-distressed segment.

### 4.4 The job

> **When** my child does something I can't handle and I feel myself losing control,
> **I want to** not become the parent I'm ashamed of,
> **so that** my child remembers a home that was safe.

| Dimension | Job | Served by | Evidence |
|---|---|---|---|
| **Functional** | Interrupt escalation; one action now | Conversation Engine | 168 "how do I" messages |
| **Emotional** | Stop feeling like a failure | Voice + no-blame discipline | *"عايزه حد يشوفنى حلوه من جوه من غير احكام"* |
| **Social** | Be a parent whose children remember warmth | Journey Engine outcomes | *"عندما يكبرون لا يذكرون الا الصراخ والتوبيخ"* |
| **Relational** | Someone in this with me who doesn't need re-explaining | Knowledge Engine | *"خسارة انك لا تذكرني"* |

That last quote is the clearest justification for making memory the foundation (003). **A parent told us the discontinuity hurt.**

### 4.5 Forces of Progress

| Force | State | Answer |
|---|---|---|
| **Push** | 🟢 Very strong | Nothing needed — 73 guilt + 28 exhaustion messages |
| **Pull** | 🟢 Strong | Preserve conversation quality; add visible change |
| **Anxiety** | 🔴 | Free forever; no hidden commercial model; guarantee |
| **Habit** | 🔴 → **answered** | The Seed/Harvest rhythm (010) |

---

## 5. The free/paid boundary

### 5.1 The principle (002, 019)

> **Knowledge is free. Daily execution, follow-through, and the personal journey to a result are paid.**

**Same intelligence. Same answer quality. Same understanding. Same memory.** Free is not a degraded product — it is a complete one with a different scope of *labour*.

| | Free | Paid |
|---|---|---|
| **Intelligence** | **Full** | **Identical** |
| **Answer quality** | **Full** | **Identical** |
| **Memory of the child** | **Full** | **Identical** |
| **Personalisation** | **Full** | **Identical** |
| **Help when asked** | **Unlimited** | Unlimited |
| **Daily rhythm** | Seed + Harvest | Seed + Harvest |
| **What is different** | — | **A named goal, driven daily until it is reached or honestly declared unreached** |

### 5.2 Why this line is defensible

It withholds **no information**. Ask ADAM how to predict a hard night and it tells you, completely, free, from your own data. What costs money is not knowing — it is **someone doing it with you, every day, until the goal lands.**

Information versus labour is the only boundary that can honestly carry a price in a product whose entire moat is trust.

### 5.3 Banned framings (P15)

| Never | Why |
|---|---|
| "Free remembers 7 days" | Crippling the product to manufacture a reason to pay. Also self-defeating: shallow memory makes the free Seed generic, breaking P11 |
| "Free gets 3 messages a day" | Rationing help (P1, P8) |
| "Unlock full memory / smarter answers" | Directly contradicts 002 |
| "Paid gets more features" | Nobody wants more features. They want the house quieter |

---

## 6. The business unit: the Journey (016)

### 6.1 The unit of value is not the subscription

> **A Journey is: a goal · progress · adjustment · an outcome.**
>
> The subscription is what lets journeys continue. It is the access mechanism, not the thing being bought.

A parent does not buy "a month of ADAM." They start **the sleep journey with Yusuf**, aimed at five calm nights out of seven. That either happens or it does not, and ADAM says which.

### 6.2 Anatomy of a Journey

| Element | Rule |
|---|---|
| **Goal** | Concrete and falsifiable. "خمس ليالٍ هادئة من سبع" — never "نوم أفضل" |
| **Generated, never templated** | From this child, this parent, the history, the current problem (004, P18) |
| **Progress** | Derived from Harvests, never a stored counter |
| **Adjustment** | When the approach is not working, the journey changes course — and says so |
| **Outcome** | Declared honestly at the end, reached or not |
| **Clock** | Counts **days actually logged**, not calendar days. Illness, travel and Ramadan cost the parent nothing |

### 6.3 Honest declaration of failure

A journey that misses its goal says so plainly, and says what was learned. **A failed journey stated honestly builds more trust than a success that was quietly redefined.** This is not a nicety — it is what makes the goal worth stating at all.

### 6.4 The subscription's only role

Journeys continue while the subscription is active. It buys **continuation**, not features, not memory, not intelligence.

**Hard constraint carried forward from a live incident:** the old renewal machinery was found in production sending a parent — last active a month earlier — a demand for 2,300 DZD to a personal bank account, quoting Algerian pricing because her country field was empty, and asserting a "real turning point" assembled from empty fields.

> **ADAM never sends a renewal, expiry, or payment message. Ever.** Continuation is surfaced in the Menu and handled by the sales agent (006, §15). Automated dunning is permanently banned.

---

# PART II — THE FIVE ENGINES

*(Decision 020: nothing exists outside these five.)*

## 7. Knowledge Engine

**Owns:** everything ADAM knows about a family, and the enforcement that no message goes out ungrounded.

### 7.1 The architecture rule (015)

> **Supabase is the single source of truth.**
> **n8n is the nervous system** — it moves and schedules, it does not decide what is true.
> **The LLM stores nothing.** It receives knowledge, produces language, and forgets.

Every proactive message reads from the Knowledge Engine before it is composed. No component holds its own private memory.

### 7.2 What Knowledge is built from (012)

Real signal only — **never a static content library** (P18):

| Source | Contributes |
|---|---|
| Conversations | The presenting problem, the parent's own words, emotional state |
| Child's name | Named in proactive messages whenever useful |
| Child's age | Calibrates what is developmentally reasonable |
| Recurring situations | Which moment of the day keeps failing, and its time window |
| Prior outcomes | What worked and what did not — **for this child** |
| Logged evenings | The calm/hard series over time |
| Detected patterns | Correlations the parent has not noticed |
| Country | Language register, and the commercial surface (017) |

### 7.3 Gate: what each message must read before sending

| Message | Must read | Refuses to send if |
|---|---|---|
| **Seed** | Child name + (situation OR prior outcome OR pattern) | Any missing → no Seed; ask once instead |
| **Harvest** | The Seed it belongs to | No Seed today → no Harvest |
| **Mirror** | ≥3 results + situation labels | Fewer than 3 → does not fire |
| **Journey step** | Goal + progress + last outcome | Missing → journey pauses, parent told plainly |
| **Rescue reply** | Whatever exists; may be nothing | **Never refuses — the rescue is unconditional** |

**Only the rescue is unconditional.** Everything proactive earns the right to interrupt by being specific.

### 7.4 The test for any proactive message

> **Could this exact message be sent to a different family?**
> **If yes, it does not send.**

### 7.5 Show, never announce (P5)

| Wrong — announces | Right — demonstrates |
|---|---|
| "أتذكّر أنك أخبرتني عن يوسف" | "كيف كانت تجربة التنبيه مع يوسف اليوم؟" |
| "بحسب سجلّك، ثلاث ليالٍ صعبة" | "الليلة الصعبة الوحيدة كانت في يوم بلا قيلولة" |
| "لدي معلومات عن طفلك" | *(nothing — just use them)* |

### 7.6 What is deliberately not remembered (P9)

Content touching separation, violence, bereavement or abuse is **not** written to the memory feeding proactive messages. Two live rows settled this: a child-assault disclosure, and a pattern label revealing family separation — neither distinguishable from a safe label by pattern matching.

> **The rule is provenance, not content filtering.** Proactive messages draw only on what ADAM authored or measured, never on what the parent disclosed.

---

## 8. Conversation Engine

**Owns:** every exchange, and the hybrid button/free-text model.

### 8.1 The hybrid model (014)

Neither a menu tree nor a bare chat box.

| Element | Rule |
|---|---|
| **Buttons are generated from context** | Never a fixed set. The options ADAM offers depend on what is happening now |
| **"شيء آخر" is always present** | On every button set, without exception. The parent is never cornered |
| **Buttons dissolve into free text** | Once their role is done, the conversation returns to open dialogue |
| **ADAM may create new buttons mid-dialogue** | If a moment calls for structured choices, they appear |
| **Free text is always available** | Buttons never block typing or voice |

**Why hybrid rather than either extreme.** Pure free text asks an exhausted parent to compose sentences at 23:00 — the average message is 53 characters, heavy with dialect and typos. Pure buttons cannot hold a real problem. The hybrid gives structure where structure helps and gets out of the way where it does not.

**Why "شيء آخر" is non-negotiable.** A button set without an escape is an interrogation. Its presence is what makes the buttons feel like an offer rather than a form.

### 8.2 Response shape (P6)

```
[one line: the cause, without blame]
[one line: the small thing, specific to tonight]
[one line: how it will be recognisable]
```

Max 3 content lines. **Never withhold detail** — a direct "how exactly?" gets a complete answer. Knowledge is free (019).

### 8.3 Voice

Voice notes in are a primary input, especially at distress. Transcription below the confidence threshold falls back to text confirmation; above it, transcription is never mentioned.

**Voice out is a candidate, not committed.** It may carry warmth text cannot — but a synthetic voice can unsettle. Test before adopting.

### 8.4 What the Conversation Engine never does

Sell · quote a price · mention a subscription · explain a payment method (006, P17). If a parent raises any of these, §15.4 governs the response.

---

## 9. Journey Engine

**Owns:** the daily rhythm, goals, progress, adjustment, and outcomes.

### 9.1 Everything is generated (004, P18)

> **There are no plan templates.** Every goal, every day's suggestion, and every adjustment is generated from this family's knowledge.

A template library would be indistinguishable from the free parenting content already available everywhere, and it would break P11 the moment it produced a message that could belong to any family.

### 9.2 The daily rhythm: Seed → Harvest (010)

**Seed — one small thing, grounded in this child.**

| Rule | Why |
|---|---|
| Names the child | Strongest continuity signal |
| Derives from Knowledge | A generic tip is free everywhere |
| **One** thing only | Two halves the chance either is tried and makes the Harvest ambiguous |
| Small enough for a bad day | Ambition is the enemy of measurement |
| Sets up its own Harvest | The pair is the unit |
| **Not sent if Knowledge is thin** | Silence beats a generic message |
| Never in crisis | §13.2 |

**Harvest — the same subject, that evening.**

> **The Harvest is an extension of the Seed, never a separate question.**

"كيف كان يومك؟" is a message from a stranger. "كيف كانت تجربة التنبيه مع يوسف؟" is from someone who was in the room this morning.

**No Seed, no Harvest.** The pair is atomic. A standalone evening question is exactly the generic check-in this decision abolishes.

### 9.3 Timing follows the logic of the day (011)

Each situation carries a time window. The Seed arrives **before** it, the Harvest **after** it.

| Situation | Occurs | Seed | Harvest |
|---|---|---|---|
| **النوم** | 20:00–22:00 | Late afternoon — while the evening can still change | After the window, ~22:30 |
| **المدرسة** | 07:00–08:00, 16:00–18:00 | Evening before, or early morning | After homework time |
| **الأكل** | Mealtimes | ~1h before the main meal | After it |
| **الانتقالات** | Variable | Morning | Evening |
| **وقت الشاشة** | Late afternoon–evening | Early afternoon | Evening |
| **Unknown** | — | Mid-morning default | ~21:00 local default |

**Hard rules:**

1. A Seed must arrive with time to act. A bedtime Seed at 21:30 is useless.
2. A Harvest must arrive after the window closes. **Asking at 20:00 how bedtime went asks about a thing that has not happened.**
3. All times are the parent's true local time via IANA zones. *The legacy map had Egypt at +2 against a real +3 — the largest market messaged an hour early, nightly, for months.*
4. **Ceiling: one Seed and one Harvest per day.** Two proactive messages is the maximum.
5. Unknown local evening → send nothing, surface for resolution. *56 parents currently have no resolvable timezone.*
6. Quiet hours absolute: nothing proactive 23:00–07:00 local.

### 9.4 The Mirror

Fires when three Harvests carry a result. Data-gated, never day-gated. Shows a pattern from the family's own data.

**Carries no price and no commercial content — enforced structurally, not by wording discipline.**

**Deliberately under-claims.** Three nights prove nothing; over-claiming loses trust the moment night four contradicts it.

### 9.5 Journey progression

| Stage | Behaviour |
|---|---|
| **Goal set** | Stated concretely and falsifiably |
| **Daily drive** | Seed and Harvest aimed at the goal, not at the day in general |
| **Adjustment** | When the approach is not landing, the journey changes course and says so |
| **Outcome** | Declared honestly — reached, or not, with what was learned |
| **Next** | A new goal may follow. Nothing is taken away in between |

---

## 10. Telegram Engine

**Owns:** every surface. Telegram is not a channel — it is the product (008).

### 10.1 Surfaces in use

| Surface | Role |
|---|---|
| **Inline buttons** | Dynamic, context-generated (§8.1) |
| **Reply keyboard** | **Persistent bottom bar** — the always-available actions |
| **Bot menu / commands** | The structured entry to everything, including commerce (007) |
| **Pinned message** | Live state: the child, the current goal, this week's progress |
| **Deep links** | Instagram → a specific starting context, without a form |
| **Voice notes** | Primary input at distress |
| **Message reactions** | Zero-tap acknowledgement of a Mirror |
| **Reply-to-message** | The Harvest threads as a reply to its own Seed |

**On the reply keyboard — reversing v2.** v2 refused it, arguing it occupies the input area and discourages free text. Decision 008 overrides that, and the objection is answerable: the keyboard carries **three** entries, collapses on demand, and typing remains available at all times. The gain — permanently visible actions with zero recall burden — outweighs a partly-occupied input area for an exhausted user.

**On deep links.** An Instagram post about bedtime opens ADAM *already in the bedtime context*, with no form and no question. This is the cleanest fix available for the 0.7% audience→bot conversion, and it needs no new product — only a link parameter.

### 10.2 The reply keyboard

```
┌──────────────────┬──────────────────┬──────────────────┐
│   ما حدث الآن     │    كيف نتقدّم     │      القائمة ☰    │
└──────────────────┴──────────────────┴──────────────────┘
```

Three entries: the rescue, progress, and the menu. Never more.

### 10.3 The menu — fixed, with exactly one changing item (009)

> **The main menu is stable. Exactly one item changes with the parent's stage.**

Stability is what makes it trustworthy; the single changing item is what makes ADAM feel like it is moving with them.

```
☰  القائمة

   يوسف                        ← the child, always
   كيف نتقدّم                   ← progress, always
   ما الذي يمكن أن نعمل عليه؟    ← ★ THE CHANGING ITEM
   إعدادات الرسائل               ← quiet hours, pause, always
   الخصوصية وحذف البيانات        ← always
```

**The changing item by stage:**

| Stage | The item reads | What it opens |
|---|---|---|
| New / no goal yet | "ما الذي يمكن أن نعمل عليه؟" | The situations ADAM can see, and how journeys work |
| A goal is visible | "ابدأ رحلة نوم يوسف" | The journey, its goal — and, for supported countries, how to begin |
| Journey active | "رحلة نوم يوسف" | Goal, progress, what's next |
| Journey complete | "ما بعد النوم؟" | The next goal worth taking |
| Unsupported country | "متى يصل آدم إلى بلدي؟" | The waitlist |

**This single item is the entire commercial surface.** It is never a notification, never badged, never announced. It is simply always there, and it changes as the relationship changes.

### 10.4 Country in the experience (017)

Country determines payment availability, currency, which journeys can be started commercially, and waitlist membership. It is resolved from the parent's own signals, never demanded up front (P2).

| Country state | Menu item | Free experience |
|---|---|---|
| **Supported** (DZ, EG, MA) | Shows how to begin a journey | Full |
| **Unsupported** | Shows the waitlist | **Full, identical** |

**Unsupported countries lose nothing except the ability to pay.** 48.4% of signups are in this position, and their free experience is complete (P8).

### 10.5 The pinned message

```
📌  يوسف · نعمل على: النوم
    هذا الأسبوع: ٤ ليالٍ أهدأ من ٧

    القائمة ☰ فيها كل ما يمكن أن نفعله معاً.
```

Updated silently. Never re-pinned as a notification. Points at the menu, never at a price.

---

## 11. Growth Engine

**Owns:** acquisition, the content bridge, and referral.

### 11.1 The loop

```
Content naming a parenting pain  (525,682 reach, 20,991 shares)
        │
        ▼
Deep link into the exact context      ← the bridge, currently 0.7%
        │
        ▼
Value in < 60 seconds
        │
        ▼
Daily rhythm → recognition → a goal → a result
        │
        ▼
Parent tells another parent, AND generates new content raw material
        │
        └──► feeds content ──┘
```

**The compounding asset:** every conversation teaches which pains are most common in which countries, which informs the next post.

**The break point is the bridge.** 0.7% of the audience has reached the bot. Deep links (§10.1) plus moment-framed CTAs are the highest-ROI work available in the business.

### 11.2 Referral — share the insight, never the scorecard

Sharing "3 of 5 nights calm" also discloses two hard nights. In a shame-loaded context that is a disincentive. But parents already share at enormous volume — 20,991 shares on one post. **They share the insight, not themselves.**

```
┌──────────────────────────────┐
│  الرفض عند النوم              │
│  ليس عناداً —                 │
│  هو خوف من الانفصال في الظلام.│
│              آدم 🌿           │
└──────────────────────────────┘
```

**No incentive, no reward, no referral code.** Paying for referrals in a trust-based product corrupts the motive. Offered once, at a moment of pride, never repeated.

**Referral is also the highest-trust commercial surface we have** — a parent hearing about journeys from another parent hears it from someone with nothing to gain.

---

# PART III — THE EXPERIENCE

## 12. Complete user journey

```
┌─ ACQUISITION ────────────────────────────────────────────────┐
│  Instagram content → deep link into the exact context        │
└──────────────────────────┬───────────────────────────────────┘
                           ▼
┌─ FIRST CONTACT ──────────────────────────────────────────────┐
│  No country gate. No form. No questions.                     │
│  Reply keyboard + menu visible from message one              │
│  ★ The commercial model is already visible, never announced  │
└──────────────────────────┬───────────────────────────────────┘
                           ▼
┌─ THE RESCUE (free, everywhere, unconditional) ───────────────┐
│  One cause · one small thing for tonight · one way to know   │
└──────────────────────────┬───────────────────────────────────┘
                           ▼
┌─ THE DAILY RHYTHM (free) ────────────────────────────────────┐
│   MORNING · Seed        →        EVENING · Harvest           │
│   grounded in this child          the same subject, one tap  │
│   Timed to the situation, never to a global clock            │
└──────────────────────────┬───────────────────────────────────┘
                           ▼
┌─ THE MIRROR (free) ──────────────────────────────────────────┐
│  At 3 logged evenings. A pattern from their own data.        │
│  No price, no commercial content — structurally              │
└──────────────────────────┬───────────────────────────────────┘
                           ▼
┌─ A GOAL BECOMES VISIBLE ─────────────────────────────────────┐
│  ADAM names it: "خمس ليالٍ هادئة من سبع"                      │
│  This is PRODUCT, not sales. ADAM says no price.             │
│  The menu item changes to: "ابدأ رحلة نوم يوسف"               │
└──────────────────────────┬───────────────────────────────────┘
                           ▼
┌─ THE MENU → THE AGENT (only if the parent taps) ─────────────┐
│  Country · currency · price · payment · receipt              │
│  Handled by the sales agent. ADAM is not in this room.       │
│  The daily rhythm continues untouched throughout             │
└──────────────────────────┬───────────────────────────────────┘
                           ▼
┌─ THE JOURNEY (paid) ─────────────────────────────────────────┐
│  Goal · daily drive · adjustment when it isn't landing       │
│  Clock counts logged days, not calendar days                 │
└──────────────────────────┬───────────────────────────────────┘
                           ▼
┌─ OUTCOME, DECLARED HONESTLY ─────────────────────────────────┐
│  Reached, or not — and what was learned either way           │
└──────────────────────────┬───────────────────────────────────┘
                           ▼
        Next goal  ·  Or back to the free rhythm, complete
                    (nothing is taken away — P1, P15)
```

## 13. Every user state

### 13.1 Primary states

| # | State | Entry | Exit | Behaviour |
|---|---|---|---|---|
| **S0** | `new` | First contact | First message | Greet; invite; no questions. **Menu and keyboard live immediately** |
| **S1** | `first_moment` | First substantive message | First step delivered | Full attention |
| **S2** | `helped` | Step delivered | Enough known to ground a Seed | Enrol in the rhythm |
| **S3** | `in_rhythm` | First Seed sent | 3 Harvests logged | Daily Seed + Harvest |
| **S4** | `recognised` | Mirror delivered | A goal becomes visible | Rhythm continues |
| **S5** | `goal_visible` | ADAM names a concrete goal | Parent starts, or does not | **Menu item changes. ADAM says nothing further** |
| **S6** | `with_agent` | Parent taps to begin | Agent confirms, or parent leaves | **Rhythm continues untouched.** ADAM absent from this |
| **S7** | `journey_active` | Payment confirmed | Goal reached, or honestly declared unreached | Daily drive toward the goal |
| **S8** | `journey_complete` | Outcome delivered | — | Returns to S4 rhythm, complete |
| **S9** | `dormant` | 14 days silent | Any message | Rhythm decays, then stops. One reactivation per lifetime |
| **S10** | `returned` | Message after dormancy | Resolves in 1 turn | Acknowledge continuity, never guilt the absence |

**S5 is the critical state.** ADAM names a goal — a product act — and then stops. The menu carries the rest. **No message follows. No reminder. No second mention.**

### 13.2 Orthogonal states

| State | Effect |
|---|---|
| **X1** `in_crisis` | **Everything commercial suppressed. Seed and Harvest suspended. The changing menu item reverts to neutral.** Human queue. Overrides all |
| **X2** `payment_blocked` | Free experience identical. Menu item shows the waitlist |
| **X3** `voice_preferred` | Voice-friendly cadence |
| **X4** `paused` | All proactive messages stop; conversation remains |

**X1 reverting the menu item is deliberate.** A parent who has just disclosed violence must not open the menu and find an invitation to start a paid journey.

### 13.3 Transition rules

1. No transition may skip S1→S2. Value before anything else (P2).
2. **S5 is entered only when a concrete, falsifiable goal exists** — never on a timer, a message count, or a readiness score. **A scoring model that decides who is "ready" is banned: that is what the Judge was, and it produced 8 offers and 0 clicks.**
3. X1 suppresses S5–S8 behaviour and the rhythm, for the duration plus 7 days.
4. X2 never blocks S0–S5. Only S6 onward.
5. S9 permits exactly one reactivation per parent lifetime.
6. S8 returns to S4 with nothing removed (P15).

---

## 14. Conversation flows

All strings are the **gender-free default**; masculine and feminine variants are required at build time (§3.4).

### 14.1 First contact

```
ADAM: السلام عليكم 🌿
      أنا آدم.
      ماذا حدث؟ الكتابة أو التسجيل الصوتي — كلاهما يصل.
```

No name request, no country question, no age question. **The reply keyboard and menu are visible from this moment** — which is what makes the commercial model impossible to be surprised by later.

### 14.2 The rescue

```
ADAM: الرفض عند النوم غالباً ليس عناداً — هو خوف من الانفصال في الظلام.

      الليلة، قبل النوم بعشر دقائق: الجلوس معه، والباب مفتوح شبراً.
      بلا شرح — الجلوس وحده.

      علامة النجاح: أن ينام دون نداء أكثر من مرة.

      [كيف أفعلها بالضبط؟]  [شيء آخر]
```

Buttons generated from context; **"شيء آخر" always present** (014).

### 14.3 The Seed

```
ADAM: صباح الخير 🌿

      تجربة صغيرة اليوم مع يوسف:
      تنبيه قبل الانتقال بخمس دقائق — قبل الخروج، وقبل النوم.

      مساءً نتكلم عنها.
```

**If Knowledge is thin**, no Seed. Instead, once — never repeated daily:
```
ADAM: صباح الخير 🌿
      حتى تكون التجربة على مقاس ابنك: ما اسمه، وكم عمره؟
```

### 14.4 The Harvest

```
ADAM: كيف كانت تجربة التنبيه مع يوسف اليوم؟

      [نجحت]  [جرّبناها وما نجحت]  [ما صارت الفرصة]  [شيء آخر]
```

| Answer | Reply |
|---|---|
| نجحت | "هذه خطوة حقيقية. نبني عليها غداً." |
| جرّبناها وما نجحت | "المحاولة نفسها تغيّر شيئاً. غداً زاوية أخرى." |
| ما صارت الفرصة | "لا بأس. ليس كل يوم يحتمل تجربة." |

**"ما صارت الفرصة" must never carry disappointment.** A parent who feels judged for not trying stops answering, and the Harvest is the entire proof engine.

### 14.5 A goal becomes visible — S5

**The single most important message in the commercial model, and it contains no commerce.**

```
ADAM: صار عندي صورة واضحة عن ليالي يوسف.

      الليالي الصعبة كلها تقريباً في أيام بلا قيلولة.
      وهذا شيء يمكن تغييره.

      الهدف الذي أراه: خمس ليالٍ هادئة من سبع.
      نمشي إليه يوماً بيوم حتى نصل — أو حتى نعرف أنه لا يصلح، وأقولها.

      [كيف نبدأ؟]   [ليس الآن]   [شيء آخر]
```

**Five deliberate properties:**

1. **No price. No currency. No subscription. No payment method.** (006)
2. **The goal is falsifiable** — five of seven, not "better sleep"
3. **Failure is pre-committed** — "أو حتى نعرف أنه لا يصلح، وأقولها" (§6.3)
4. **"كيف نبدأ؟" opens the Menu**, not a pitch. ADAM's part ends there
5. **"ليس الآن" costs nothing** and is never followed up

**On tapping "كيف نبدأ؟"** — ADAM hands off and says so plainly:
```
ADAM: كل تفاصيل البدء في القائمة ☰ — البلد، والطريقة، والباقي.
      وأنا هنا كما أنا، مهما كان القرار.
```

That is the last thing ADAM says about it. **Ever, unless asked.**

### 14.6 Crisis (X1) — overrides everything

**Categories:** self-harm or suicidal ideation · domestic violence · child abuse by a third party · the parent's own escalating violence · bereavement · substance use in a minor.

1. Suppress everything commercial — conversation + 7 days
2. **Suspend Seed and Harvest**
3. **Revert the changing menu item to neutral**
4. Suppress memory write for the sensitive content (P9)
5. Stay, and do not advise:
```
ADAM: أنا هنا.
      هذا الحِمل أثقل من أن يُحمل وحده.
      [line specific to the category]
      أنا هنا. ولا شيء مطلوب الآن.
```
6. Raise to the human queue
7. Never give clinical, legal, or safeguarding instructions

**The one exception to Decision 014.** Crisis messages carry **no buttons at all** — not even "شيء آخر". Offering a parent who has just disclosed violence a set of options turns a moment of being heard into a form to complete. The escape hatch that "شيء آخر" provides everywhere else is, here, the whole message: nothing is asked of them.

This is the only place in the product where a button set is absent, and it is recorded so that nobody adds one to satisfy 014.

**Vocabulary (013):** the internal name for step 5 is **الاحتواء**. The parent never sees that word and never senses a mode change.

**This is the one area where the product must not act autonomously.** §22 D1.

---

## 15. Commerce: how it reaches the parent without selling

### 15.1 The problem (018)

Assume the parent believes ADAM is entirely free. Do not rely on them asking. Do not rely on chance discovery. And ADAM may not sell (006).

**The old model failed by surprise.** Eight proactive offers, zero clicks, four of eight never returned, and *"انت طلعت بفلوس اخص عليك"* — "so you turned out to be after money, shame on you."

### 15.2 The resolution: nothing was ever hidden

> **The commercial model is visible from the first message and announced at no message.**

A parent cannot be surprised by something that was in the menu the whole time. This is the entire mechanism, and it is why 006 and 018 are compatible rather than contradictory.

| Layer | Owns | Never |
|---|---|---|
| **ADAM** | Names a goal (§14.5). Pure product | Price, currency, payment, the word subscription |
| **The Menu** | Turns the goal into something startable. Permanently visible | Notify, badge, nag, expire |
| **The sales agent** | Country, currency, price, payment, receipt, confirmation | Parenting advice |

**The seam is the design.** Naming a goal is a product act. Handling money is a separate role in a separate room.

### 15.3 Why this is not a funnel

| Funnel property | Here |
|---|---|
| Triggered by a readiness score | **Banned** (§13.3). Triggered by a real, falsifiable goal existing |
| Escalating pressure | One mention, ever. No follow-up |
| Urgency or scarcity | Banned (P10) |
| Optimised for conversion | **No conversion target exists anywhere in this document** (§16.4) |
| Free degraded to motivate upgrade | Banned (P15, 002) |
| Value withheld pending payment | Knowledge is free and complete (019) |

### 15.4 If the parent raises money directly

ADAM answers honestly and hands off — without quoting anything:

```
PARENT: بكام الاشتراك؟

ADAM:   التفاصيل كلها في القائمة ☰ — أدقّ من أن أقولها هنا،
        وتختلف حسب البلد.

        وما بيننا الآن لا يتغيّر بأي حال.
```

**ADAM does not name a number, even when asked directly.** (006)

### 15.5 Payment (007)

| Country | Menu shows | Price |
|---|---|---|
| **الجزائر** | Payment method | **2,300 دج** |
| **مصر** | Payment method | **490 جنيه** |
| **المغرب** | Payment method | **110 درهم** |
| **Other** | Waitlist | — |

Collection is manual and handled by the sales agent. **The rhythm never pauses while payment is pending** — nothing is held hostage.

If unconfirmed after 72h, the agent raises it. **A parent who paid and heard nothing is the worst outcome available.**

A parent who starts and does not finish is **never messaged about it.** Abandoned payment is a decision.

### 15.6 Never permitted

| Banned | Why |
|---|---|
| Any message from ADAM whose purpose is commercial | 006, P17 |
| A price spoken by ADAM, even on direct request | 006 |
| A second mention after "ليس الآن" | The four-of-eight who never returned |
| Commerce in the same message as a Mirror, a win, or an outcome | P1 |
| Anything commercial within 14 days of a crisis | P1 |
| A scoring model deciding who is "ready" | This was the Judge |
| Countdown, limited window, special price | P10 |
| Degrading free to make paid attractive | P15, 002 |
| **A launch announcement to the existing 291 parents** | It would be exactly the surprise this section prevents |

**There is no launch announcement.** Existing parents meet the menu the same way new ones do.

---

# PART IV — OPERATING THE PRODUCT

## 16. North Star and metrics

### 16.1 North Star

> ## Parents Reaching Outcomes
> **Parents who completed ≥3 Seed→Harvest pairs in the trailing 7 days, plus parents whose journey reached its stated goal.**

**Why the pair, not the night.** A logged night can be produced by a generic ping — it measures the parent's compliance. A completed **pair** cannot rise unless ADAM's morning message was worth answering. **It is the only metric that holds us accountable rather than the parent.**

**Why goals reached are included (001).** The conversation is not the product; the outcome is. A metric that counts only engagement would let us succeed while nothing changed in anyone's house.

### 16.2 The tree

```
NORTH STAR: Parents Reaching Outcomes
   │
   ├── ACQUISITION
   │     Audience→bot (deep links)    ≥2%   (now 0.7%)
   │     Unserved-country share       ≥40%
   │
   ├── ACTIVATION
   │     First message → first value  ≥90%
   │     First value → in rhythm      ≥70%
   │     1 → 3 pairs                  ≥50%
   │
   ├── THE RHYTHM
   │     Seed→Harvest completion      ≥50%
   │     Seeds grounded in Knowledge  100%  (hard floor)
   │     Pairs / parent / week        ≥4
   │
   ├── OUTCOMES  (the product's real output)
   │     Journeys reaching their goal  observe, then target
   │     Journeys honestly declared unreached  observe — a healthy number is not zero
   │     Calm ratio, week 1 → week 4
   │
   ├── COMMERCE  (observed, never targeted)
   │     Menu opens / parent
   │     Goal-visible → journey started    observe
   │     Claim → confirmed            ≥95%
   │
   └── TRUST  (guardrails — a breach halts the roadmap)
         Prices spoken by ADAM         0    (hard zero)
         Commercial content in X1      0    (hard zero)
         Seeds in X1                   0    (hard zero)
         Ungrounded Seeds              0    (hard zero)
         Gendered strings to unknown   0    (hard zero)
         Second mention after decline  0    (hard zero)
         Banned vocabulary in output   0    (hard zero)
         Crisis flags → human < 24h    100%
         Block/mute rate               < 2%
         Median reply latency          < 15s
```

### 16.3 A healthy number of failed journeys is not zero

If every journey reaches its goal, the goals are too easy or the outcome is being quietly redefined. §6.3 requires honest declaration; this metric is how we check it is happening.

### 16.4 No conversion target, anywhere

A target on a commercial mechanism is a standing instruction to optimise it, and optimised commerce is a funnel. Conversion is **observed, reported, and never optimised against.** The metrics that *are* targeted are the trust guardrails.

---

## 17. Analytics events

Every event carries `parent_id`, `timestamp`, `state`, `country`, `gender_form_used`.

**Lifecycle:** `parent_started` · `parent_state_changed` · `parent_dormant` · `parent_returned`

**Conversation:** `message_received` (channel, char_count) · `first_value_delivered` · `buttons_generated` (count, context) · `something_else_tapped` · `crisis_detected` · `crisis_reviewed`

**Rhythm:** `seed_sent` (situation, knowledge_sources[], scheduled_offset) · `seed_skipped` (**reason**) · `harvest_sent` · `harvest_answered` · `harvest_ignored` · `pair_completed` · `situation_identified`

> **`seed_skipped` matters as much as `seed_sent`.** Silence is correct when there is nothing personal to say, so principled silence must be distinguishable from a broken scheduler.

**Journey:** `goal_named` · `journey_started` · `journey_adjusted` (**reason**) · `journey_goal_reached` · `journey_goal_missed` (**what was learned**)

**Telegram:** `menu_opened` · `menu_item_changed` (from, to) · `keyboard_action` · `deep_link_opened` (source post)

**Commerce:** `agent_handoff` · `payment_claimed` · `payment_confirmed` (hours) · `payment_blocked_country` · `waitlist_joined`

**Quality guardrails:** `ungrounded_send_blocked` · `gender_form_fallback` · `banned_vocabulary_blocked` · `price_mention_blocked`

**Never tracked:** message content, anything from an X1 conversation, any field letting an operator browse disclosures casually.

---

## 18. Experiments

| # | Experiment | Hypothesis | Kill signal | Effort |
|---|---|---|---|---|
| **E1** | **Seed grounding** | A memory-grounded Seed beats a generic tip | Grounded ≤ generic on Harvest rate | Low — two arms, same pipeline |
| **E2** | **Deep links** | Context-preserving links beat generic CTAs | No lift over 0.7% | Link parameter only |
| **E3** | **Delete onboarding** | The form is pure loss | Extraction materially worse | Deletion |
| **E4** | **Free everywhere** | Serving all countries returns more than it costs | Cost outruns signal | Deletion |
| **E5** | **Menu visibility** | Parents who open the menu early are *more* trusting, not less | Block rate rises with menu exposure | Observation |
| **E6** | **Timing** | Situation-relative beats fixed-hour | No difference in Harvest rate | Config |
| **E7** | **Goal falsifiability** | A concrete goal ("5 of 7") outperforms a vague one | No difference in journeys started | Copy |
| **E8** | **Gulf concierge** | Waitlisted high-ATP parents will pay | 0/10 pay | Days, no engineering |
| **E9** | **Voice input** | Voice increases depth | No lift | Medium |

**E1 is the most important experiment in this document.** The whole thesis is that a grounded Seed is categorically different from a parenting tip. If a generic tip performs equally well, then P11 and Decision 003 are wrong, memory is not the foundation, and the free rhythm is a content channel rather than a relationship. **Worth knowing before building the Knowledge Engine everything else assumes.**

**E5 is the honest test of §15.2.** The entire commerce design rests on the claim that permanent visibility builds trust rather than eroding it. If parents who see the menu early are *more* likely to leave, the claim is wrong and §15 needs rework.

---

## 19. Roadmap

### NOW — weeks 0–4

**Week 0 — nothing ships until these are done**
1. Rotate exposed credentials *(service-role key and bot tokens sit in plaintext in workflow JSON)*
2. Restore the dashboard source *(`lib/` and `components/` were never committed; it cannot build)*

**Weeks 1–2 — deletions, switch-ons, and surfaces**
3. Remove the country gate on usage
4. Remove the onboarding form
5. Activate the timezone-correct sender; retire the legacy one
6. Fire the Mirror *(built, data-gated, has fired zero times)*
7. **Gender-neutral rewrite of every existing string**, including the prompt that hardcodes *"أمٍّ"*
8. **Telegram Engine: reply keyboard, menu, pinned message, deep links** — the commerce surface must exist before any goal is named

**Weeks 3–4 — the engines**
9. **Knowledge Engine** — the precondition for everything
10. **Conversation Engine** — hybrid buttons, "شيء آخر", dynamic generation
11. **Journey Engine** — Seed, Harvest, timing windows
12. Voice input
13. Crisis detection + human queue — **gated on §22 D1**
14. **E1 runs from the first day the Seed exists**

**Decision gate at week 4:** grounded Seeds beat generic on Harvest rate, **and** ≥50% of parents in rhythm complete 3 pairs. If grounded is not better, stop and revisit §1 — the memory thesis *is* the product thesis.

### NEXT — months 2–3

Journey goals and honest outcomes · the sales agent · commercial journeys in supported countries · situation depth · shareable insight cards · operator console · global payment rail

### LATER — months 4+

Peer presence *(only after retention is proven)* · multi-child *(currently 3 children rows)* · collective intelligence *(needs privacy design first)* · additional markets *(requires a rail)* · voice output *(only if tested and it does not unsettle)*

---

## 20. Risks and assumptions

### Assumptions, ranked by damage if wrong

| # | Assumption | Test | Damage |
|---|---|---|---|
| **A1** | A grounded Seed is categorically better than a generic tip | E1 | **Fatal** — the product thesis |
| **A2** | Parents want a daily rhythm, not an on-call helper | E1 + Harvest rates | **Fatal** |
| **A3** | **Permanent menu visibility builds trust rather than eroding it** | E5 | **Fatal** — the entire commerce design rests on it |
| **A4** | Parents pay for a driven outcome, not for access | Journeys started | **Fatal** — the business model |
| **A5** | A concrete goal is more compelling than a vague one | E7 | Medium |
| **A6** | Situation-relative timing beats a fixed hour | E6 | Medium |
| **A7** | Waitlisted Gulf parents will pay | E8 | High |
| **A8** | Free-everywhere costs less than it returns | E4 | High |

### Risk register

| # | Risk | Severity | Mitigation |
|---|---|---|---|
| **R1** | **Safeguarding** — disclosures of abuse and the parent's own violence with no escalation path | 🔴 Critical | Crisis detection + human protocol **before scale**. §22 D1 |
| **R2** | **The Seed becomes a tip library** — the easy path whenever Knowledge is thin | 🔴 Critical | P11 as a hard block; `ungrounded_send_blocked`; 100% floor. **Prefer silence** |
| **R3** | **Nobody opens the menu**, so the commerce model is invisible in practice and §15.2 fails silently | 🔴 Critical | `menu_opened` from day one. If low, the changing item must become more legible — **never a message** |
| **R4** | **Subscription + manual payment reproduces the dunning machine** | 🟠 High | **ADAM never sends a renewal or expiry message (§6.4).** The agent owns continuation. Automated dunning permanently banned |
| **R5** | **Two roles confuse the parent** — ADAM warm, agent transactional, and the seam feels like a bait-and-switch | 🟠 High | ADAM names the handoff plainly (§14.5). Agent never gives advice. Monitor block rate at handoff |
| **R6** | **Low conversion by construction** — the better free works, the less often a goal feels urgent | 🟠 High | **Accepted, not mitigated.** Size the business for a small paying minority. §20.1 |
| **R7** | **Exposed credentials** — plaintext service-role key and bot tokens | 🟠 High | Week 0 |
| **R8** | **Dynamic buttons produce nonsense options** under a weak model | 🟠 High | "شيء آخر" always present as the escape; log `something_else_tapped` as the quality signal |
| **R9** | **Generated journeys drift into generic advice** without templates to anchor them | 🟠 High | Every journey step reads Knowledge (§7.3) and is blocked if ungrounded |
| **R10** | **Founder is the payment rail** | 🟠 High | Fine now; binding at ~50 customers |
| **R11** | **Gendered copy leaks to fathers** | 🟡 Medium | Three-form requirement; `gender_form_fallback` |
| **R12** | **Reply keyboard discourages free text** — v2's original objection, now overridden | 🟡 Medium | Three entries only; collapsible; monitor free-text rate before and after |

### 20.1 The strategic consequence, stated plainly

**This model converts poorly by construction, and that is the honest cost of the constraints.**

ADAM cannot sell. The menu does not push. No conversion target exists. And the better the free rhythm works, the less often a parent feels the need for a driven goal.

Two implications, neither of which should be softened:

1. **Size the business for a small paying minority subsidising a large free base**, with content as the acquisition engine. That is a viable shape, but it is a different business from what a funnel would build.
2. **If revenue proves insufficient, the thing to revisit is the free/paid boundary (§5) — a founder decision — not the pressure in §15.** Moving the boundary is strategy. Making the menu pushier is a betrayal, and it is nobody's call.

---

## 21. Rejected decisions

| Considered | Rejected because |
|---|---|
| **Keep the subscription as the business unit** | Decision 016. The journey is the unit; the subscription only permits continuation |
| **ADAM quotes the price when asked** | Decision 006. Even on direct request, ADAM points at the menu |
| **Announce the commercial model to existing parents** | It is exactly the surprise §15 exists to prevent |
| **Tier memory or intelligence** | Decision 002 and P15. Also self-defeating: shallow memory makes the free Seed generic, breaking P11 |
| **A library of parenting tips for the Seed** | Decision 004. Converts the rhythm into a content channel and destroys the only differentiator |
| **Plan templates for journeys** | Decision 004. A template is indistinguishable from the free content already everywhere |
| **Pure passive discovery — "let them find it like an app feature"** | An app has periphery to wander into; a conversation has none. Telegram's menu and keyboard *are* that periphery, which is why §10 carries the commerce rather than a message |
| **A "quiet affordance" with a conversion target** | A target on a commercial mechanism is an instruction to optimise it |
| **A readiness score deciding when to surface commerce** | This was the Judge. 8 offers, 0 clicks, 4 of 8 gone |
| **Ask country and gender at onboarding** | P2. Both are inferable; the neutral default costs nothing meanwhile |
| **A mobile app** | Telegram is the product surface (008). A second surface serves no evidenced job |
| **A course** | Competes with our own free content; serves *knowing*, which is not the gap |
| **Ads** | Destroys the no-judgement trust that is the moat |
| **B2B / schools / clinics** | Almost no evidence in 2,086 messages |
| **Community in MVP** | Real job, large build, moderation risk in a shame-loaded context |
| **Gamified streaks** | Streak-shaming after a hard night violates P3 catastrophically |
| **Incentivised referral** | Corrupts the motive in a trust-based product |
| **Rename the brand** | 41,100 followers and a 525k-reach proof point |

---

## 22. Open decisions

| # | Decision | Why it's yours | Blocking |
|---|---|---|---|
| **D1** | **Crisis escalation destination.** A parent discloses abuse, suicidal ideation, or their own violence — what happens? | Duty of care, legal exposure, your capacity | **Blocks crisis detection and therefore scale** |
| **D2** | **Who staffs the crisis queue, within what SLA?** | Your team and hours | Blocks the same |
| **D3** | **Fair-use ceiling for free.** Unlimited is the principle; some finite ceiling is the reality | Your cost tolerance | Blocks free-everywhere rollout |
| **D4** | **Is the sales agent a human, or an automated agent?** *(new)* Decision 006 moves purchase to "a specialised agent" without saying which. A human is warmer and does not scale; an automated one scales and must never sound like a bot closing a sale | Positioning and staffing | **Blocks the commerce build** |
| **D5** | **Does the subscription auto-expire, or lapse silently?** *(new)* Expiry implies a notification, and ADAM may not send one (§6.4). The honest option is silent lapse plus a menu state | It determines whether continuation is a nudge or a choice | Blocks the Journey Engine's end state |
| **D6** | **Which market to open first** if E8 succeeds — Saudi (highest ATP) or Iraq (largest volume) | Access to a payment agent | Blocks post-E8 planning |
| **D7** | **The existing 291 parents and 4,212 conversations** — carry memory forward, or fresh start with continuity messaging? | Relationship decision | Blocks week 1 |
| **D8** | **Whether ADAM ever says it is an AI.** One parent asked directly: *"هل انت ذكاء اصطناعي مجاني ام مدفوع"* | Positioning and ethics | Before scale |

**D1 remains the only blocker on scale. D4 is the new blocker on revenue** — the seam in §15.2 cannot be built until we know who is standing on the other side of it.

---

## 23. Change log

### v2 → v3 (2026-07-30) — PRODUCT DECISIONS v2

| Area | What changed | Decision |
|---|---|---|
| **Whole document** | **Restructured around five engines.** Features F1–F16 dissolved into Knowledge, Conversation, Journey, Telegram, Growth. Four parts: product, engines, experience, operations | 020 |
| **§0** | New — the twenty decisions, the 006/018 contradiction and its resolution, and every v2 conflict | All |
| **§1** | Philosophy stated first: **the conversation is not the product, the outcome is** | 001 |
| **§2** | **P15 rewritten** — free and paid share the same intelligence, quality and understanding. **P17 ADAM never sells. P18 nothing from a template. P19 engines not features** | 002, 004, 006, 020 |
| **§3.5** | **New: banned and approved commercial vocabulary.** ذاكرة، تقارير، متابعة، خطة، ذكاء all banned in user-facing strings | 005 |
| **§5** | **The boundary rewritten: knowledge free, execution and the driven journey paid.** Table shows intelligence, quality, memory and personalisation as *identical* | 002, 019 |
| **§6** | **New section: the Journey is the business unit.** Goal, progress, adjustment, outcome. Subscription only permits continuation. **ADAM never sends a renewal message** | 016 |
| **§7** | **New: Knowledge Engine.** Supabase the only truth, n8n the nervous system, **the LLM stores nothing** | 003, 012, 015 |
| **§8** | **New: Conversation Engine.** Hybrid dynamic buttons + free text, **"شيء آخر" mandatory on every set**, buttons creatable mid-dialogue | 014 |
| **§9** | **New: Journey Engine.** Everything generated, no templates. Seed→Harvest with Harvest as an extension. Timing by the logic of the day | 004, 010, 011 |
| **§10** | **New: Telegram Engine.** **Reply keyboard adopted, reversing v2's explicit refusal.** Deep links added. **Menu fixed with exactly one changing item** — and that item is the entire commercial surface | 007, 008, 009, 017 |
| **§11** | **New: Growth Engine.** Deep links become the bridge fix | 008 |
| **§13** | **S5 `goal_visible` replaces v2's discovery state.** ADAM names a goal and stops; the menu carries the rest. **S6 `with_agent` — ADAM is absent from the money conversation.** X1 now reverts the menu item | 006, 018 |
| **§14.5** | **Rewritten: the goal message contains no commerce.** No price, no currency, no subscription. Falsifiable goal, pre-committed honest failure | 005, 006 |
| **§15** | **Rewritten.** v2's four-door discovery model is replaced: the commercial model is **visible from message one and announced at no message**. ADAM names goals · the Menu is the door · the agent is the cashier. **ADAM will not quote a price even when asked directly** | 006, 007, 018 |
| **§16** | North Star becomes **Parents Reaching Outcomes** — engagement plus goals actually reached. **A healthy number of failed journeys is not zero.** New hard-zero guardrails for prices spoken by ADAM and banned vocabulary | 001, 005, 006 |
| **§18** | **E5 menu visibility** — the honest test of §15.2. **E7 goal falsifiability.** E2 deep links | 008, 018 |
| **§20** | **R3 nobody opens the menu** (critical — §15 fails silently). **R4 subscription reproduces dunning. R5 the two-role seam. R8 nonsense dynamic buttons. R9 generated journeys drifting generic. R12 reply keyboard** | 008, 014, 016 |
| **§22** | v2's D7 and D9 closed. **New D4 — is the sales agent human or automated?** (now the revenue blocker). **New D5 — silent lapse or expiry?** | 006, 007 |

**Prices confirmed and no longer open:** 2,300 DZD · 490 EGP · 110 MAD (Decision 007) — this closes v2's D9.

---

**End of blueprint v3. No implementation has begun. Awaiting your approval.**
