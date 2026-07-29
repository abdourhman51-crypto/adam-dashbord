# ADAM — Product Research Report
**Date:** 2026-07-29
**Sources:** n8n (11 workflows), Supabase `Adam OS` (28 tables, 4,172 live chat rows), Instagram/Facebook via Windsor.ai
**Method:** Discovery Process (Torres/Cagan) · Jobs To Be Done (Christensen) · Product Strategy (vision/PMF/moats) · Product Design (journey mapping)
**Status:** Research only. No code written, no workflow modified, no data mutated. All queries read-only.

> **Evidence rule applied throughout:** every claim below carries its source. Where evidence was thin or contradictory, it is labelled as such rather than smoothed over. Section 16 lists what could not be resolved with available data.

---

## 1. Executive Summary

ADAM is an Arabic-language AI parenting companion delivered through Telegram, targeting exhausted parents (predominantly mothers, 25–44) in the Arab world. A parent describes a moment with their child; ADAM explains the cause and gives one executable step for tonight, remembering the child across sessions.

**The single most important finding: ADAM has strong problem/solution fit and effectively zero monetisation fit — and the gap is mostly self-inflicted, not market-inflicted.**

Six findings drive everything else:

1. **Engagement is genuinely strong.** 188 conversation sessions, **average 11.1 human turns per session**, 34% of sessions exceed 10 turns, max 138 turns. Parents disclose abuse, bereavement, and their own violence. This is not idle curiosity — it is the behaviour of people who have found something that works.

2. **Monetisation is switched off, not rejected.** 7 of 11 workflows are inactive — including the entire paid pipeline: The Judge (offer eligibility), Silent Seller (offer delivery), First Insight (the trial "wow moment"), Reactivation, and both survey workflows. Only 8 offers have ever been presented, all around 16–23 July, with **0 CTA clicks** and **1 confirmed payment** in the system's entire life.

3. **48% of demand is legally/operationally unservable today.** 140 of 289 followers are waitlisted because only DZ/EG/MA are supported. Instagram audience data independently confirms this: **57.6% of a ~41,100-person audience sits outside supported countries** (IQ 4,655 · SY 2,437 · SA 2,175 · JO 1,819 · YE 1,724 · OM 1,506).

4. **The acquisition engine and the product are disconnected.** Parenting content reaches 150k–525k people. Product-announcement posts reach 445–770. That is a **~1,150x gap**. Only ~0.7% of the Instagram audience has ever reached the bot.

5. **A live data-integrity bug is corrupting every funnel metric.** The `followers.message_count` counter has been stuck at 0 since ~25 July for all new signups, while those users are demonstrably conversing (one has 15 real messages, counter reads 0). Separately, **47 of 188 chat sessions (25%) have no `followers` row at all** — a quarter of all conversations are invisible to the funnel, the Judge, and every automation that gates on engagement.

6. **The "4 paid subscribers" are not real customers.** All four have `message_count = 0`, blank country, no memory, no onboarding, and were created 27–28 June (day one). The `payments` table contains exactly **one** confirmed transaction: 490 EGP, Egypt, confirmed manually via dashboard.

**PMF assessment: Level 1 (Solution Fit), approaching but not at Level 2.** Evidence of pull is real but confined to the free tier. No repeatable willingness-to-pay signal exists yet — and critically, *it has not been fairly tested*, because the machinery that would test it is turned off.

---

## 2. Current Product Understanding

### What ADAM is
An AI "تربوي مرافق" (parenting companion) on Telegram. Positioning from the brand's own copy:

> "آدم ليس تطبيقاً، ولا كتاباً في التربية. آدم مرافق تربوي ذكي تحادثه مباشرة على تيليغرام… يتذكر طفلك. يتذكر كل موقف."
> *(ADAM is not an app, nor a parenting book. ADAM is an intelligent parenting companion you talk to directly on Telegram… He remembers your child. He remembers every situation.)*

### The value proposition, as the system itself defines it
From the paid agent's system prompt — the governing rule is value-per-effort:

> "كل ردّك يُقاس بهذا: هل النتيجة التي يحملها تستحق الوقت والجهد اللذين طلبتهما من مربٍّ منهك."
> *(Every reply is measured by this: is the result worth the time and effort you demanded from an exhausted parent.)*

Response shape is constrained to 2–3 lines: one cause, one step executable tonight, plus a measurable check. Notably, the prompt explicitly forbids withholding value behind payment:

> "الوصفة تُعطى كاملة دائماً… الحبس مقابل الدفع هو أكبر قاتل للقيمة."
> *(The prescription is always given in full… withholding for payment is the biggest killer of value.)*

This is a deliberate and, in my assessment, strategically sound choice — but it creates the monetisation tension analysed in §14.

### Business model
| Country | Monthly price | Payment method |
|---|---|---|
| Algeria (DZ) | 2,300 DZD | CCP bank transfer + receipt photo |
| Egypt (EG) | 490 EGP | Manual, via Telegram operator |
| Morocco (MA) | 110 MAD | Manual, via Telegram operator |

Guarantee: 30 days; if no real difference is felt, a further month free. Payment is **entirely manual** — no payment processor, no automated activation.

### Free vs paid design
- **Free tier:** unlimited conversation with a daily message cap; "Heart Writer" extracts a light 5-field emotional memory every 2 hours.
- **Paid tier:** persistent Postgres-backed conversational memory, a child profile (`children`, `child_patterns`, `memory_events`), daily steps, and nightly check-ins.

The intended sales argument, verbatim from the offer-writer prompt:

> "المجاني يفهمها في اللحظة ثم ينساها — راحة عابرة ليوم. المرافقة الكاملة تتذكّرها وتمشي معها — حلّ يتقدّم."
> *(The free tier understands her in the moment then forgets her — passing relief for a day. Full companionship remembers her and walks with her — a solution that progresses.)*

---

## 3. Current User Journey

```
Instagram/Facebook content (reach 150k–525k on hits)
   │  trigger-word comment ("سامحني" / "آدم" / "ملف" / "برنامج" / "دستور")
   ▼
Auto-DM with t.me link  ──► ~0.7% of audience converts to bot
   ▼
/start → Telegram bot
   ▼
Country selection (buttons)
   ├── DZ / EG / MA ──► Main welcome
   └── Everyone else ──► WAITLIST (48% of all signups land here)
   ▼
Onboarding: gender → age band → pain → time → state → "measured step"
   │  ONLY 17 of 289 (5.9%) complete this
   ▼
Free conversation with ADAM agent (Gemini 3.5 Flash, Postgres memory)
   │  avg 11.1 turns/session — the product genuinely works here
   ▼
Heart Writer (every 2h) → light_memory
   ▼
[The Judge → eligibility scoring]           ⛔ INACTIVE
   ▼
[Silent Seller → personalised offer]        ⛔ INACTIVE
   ▼
Offer + 2 buttons (ready / stay free)  ──► 8 ever sent, 0 clicked
   ▼
Manual payment (CCP / Telegram operator)  ──► 1 confirmed payment, ever
   ▼
Renewal Guard (D-5 → D-0 → D+3 downgrade)   ✅ ACTIVE
```

### Journey friction map (Product Designer method)

| Stage | Emotion | Pain point | Evidence |
|---|---|---|---|
| Discovery | Guilt, recognition | Hook is guilt-based ("سامحني" = *forgive me*) | Dominant comment trigger, IG last 30d |
| Entry | Hope | 48% hit a waitlist wall immediately | 140/289 `waitlist=true` |
| Onboarding | Impatience | 94.1% never finish | 17/289 `onboarding_done` |
| Conversation | **Relief, trust** | *This stage works* | 11.1 avg turns; 138 max |
| Memory | Frustration | Free tier forgets; users notice and complain | Verbatim §9 |
| Offer | Confusion / betrayal | Unclear which tier they are on; price inconsistency | Verbatim §10 |
| Payment | Friction | Manual bank transfer + receipt photo | Machine 5 code |

---

## 4. Current Architecture Overview

### Workflow inventory (11 total — **only 4 active**)

| # | Workflow | Trigger | Status | Function |
|---|---|---|---|---|
| 1 | Machine 1+2 — Reception, Gates & AI Agents | Telegram | ✅ **ACTIVE** | 89 nodes. Router, country gate, onboarding, main agent, CTA, check-in callbacks |
| 2 | Heart Writer | Every 2h | ✅ **ACTIVE** | Free-tier emotional memory extraction |
| 3 | Nightly Checkin | Hourly (fires at 21:00 local) | ✅ **ACTIVE** | DZ/EG/MA check-in with step feedback buttons |
| 4 | Renewal Guard (Machine 5) | Daily 10:00 | ✅ **ACTIVE** | D-5 reminder, D-0 renewal, D+3 downgrade |
| 5 | The Judge v2 (Machine 4-J) | Schedule | ⛔ INACTIVE | **Offer eligibility scoring** |
| 6 | Silent Seller (Machine 4) | Webhook | ⛔ INACTIVE | **Personalised offer delivery** |
| 7 | The Writer finale (Machine 3) | Schedule | ⛔ INACTIVE | Deep memory / snapshot builder |
| 8 | First Insight (Trial) | Daily | ⛔ INACTIVE | **The trial "wow moment"** |
| 9 | Reactivation | Manual | ⛔ INACTIVE | Dormant-user win-back |
| 10 | Founder Survey | Manual | ⛔ INACTIVE | Sends founder question |
| 11 | Survey Reply Inbox | Telegram | ⛔ INACTIVE | **Captures survey replies** |

**The entire monetisation path (5 → 6) and the entire trial-value path (8) are switched off.** This is the single highest-leverage fact in this report.

### AI agents
| Agent | Model | Role |
|---|---|---|
| `paid aget adam` | `google/gemini-3.5-flash` | Main conversational companion; Postgres chat memory |
| `HW - Heart Agent` | `google/gemini-3.1-flash-lite` | Extracts 5-field emotional memory JSON |
| `CTA - Offer Writer` | `google/gemini-3.1-flash-lite` | Writes offer when user requests it |
| `M4 - Offer Writer` | `google/gemini-3.1-flash-lite` | Writes proactive offer (inactive) |

### Memory system — a genuine architectural strength
Four tiers, cleanly separated:
1. **`light_memory`** (free) — 5 fields, LLM-extracted every 2h, with an explicit safety gate.
2. **Postgres chat memory** (paid) — full conversational history.
3. **Structured child model** — `children`, `child_patterns`, `memory_events`, `daily_logs`.
4. **`memory_snapshots` / `plan_sessions`** — compressed long-term state, preserved through downgrade for win-back.

The Heart Writer's safety rule is, in my assessment, the most impressive single artefact in the codebase:

> "إن لمست المحادثة أياً من هذه: طلاق أو خلاف زوجي، عنف منزلي، موت أو فقد، أفكار انتحارية، إيذاء النفس — اترك core_pain فارغاً تماماً… الذاكرة الناقصة أرحم ألف مرة من الذاكرة التي تجرح."
> *(If the conversation touches divorce, domestic violence, death, suicidal thoughts, or self-harm — leave core_pain completely empty… Incomplete memory is a thousand times more merciful than memory that wounds.)*

This is real product ethics encoded as a system constraint, and §9 shows it is not hypothetical — those exact topics appear in the data.

### 🔴 Security finding (urgent, reported without reproducing values)
Multiple workflow nodes contain **hardcoded plaintext production credentials**: the Supabase `service_role` key (both as a legacy JWT and as an `sb_secret_...` token) and at least two Telegram bot tokens, embedded directly in HTTP node headers and URLs rather than referenced from n8n credentials. A service-role key bypasses all Row Level Security on a database holding 4,172 real conversations containing abuse disclosures, bereavement, and identifiable children.

I have deliberately not reproduced the values here. **Recommended action: rotate the Supabase service-role key and both Telegram bot tokens, then migrate all nodes to n8n credential references.** This should precede any other work in this report.

---

## 5. Audience Analysis

### Scale and geography (Instagram, ~41,109 followers)

| Tier | Countries | Followers | Share |
|---|---|---|---|
| **Supported** | MA 7,106 · DZ 5,281 · EG 5,025 | **17,412** | **42.4%** |
| **Unserved** | IQ 4,655 · SY 2,437 · SA 2,175 · JO 1,819 · YE 1,724 · OM 1,506 · TN 1,106 · LB 853 · AE 816 · PS 601 · KW 533 · BH 484 · +others | **23,697** | **57.6%** |

The DB independently corroborates: 140/289 (48.4%) of actual signups are waitlisted. **Two independent sources agree that roughly half of all demand is being turned away at the door.**

Note the composition of unserved demand: Gulf states (SA, OM, AE, KW, BH, QA ≈ 5,749 followers) have materially higher ability to pay than the currently supported markets, and Iraq alone (4,655) is nearly as large as Egypt.

### Demographics
| Segment | Followers | Share |
|---|---|---|
| Women 25–44 | 18,348 | 44.4% |
| Women (all) | 23,789 | 57.6% |
| Men (all) | 7,621 | 18.5% |
| Undeclared | 9,865 | 23.9% |

Core persona is confirmed as women 25–44. **However, 18.5% male is not negligible**, and this creates a product inconsistency: the Heart Writer prompt assumes the user is a mother throughout ("محادثة بين أمٍّ وآدم"), while the main agent and offer writer correctly handle both genders. The DB shows 14 female / 4 male among the 18 users who declared — a 22% male share consistent with the Instagram data.

### Content performance — the acquisition disconnect

| Post | Reach | Comments | Shares |
|---|---|---|---|
| العناد (stubbornness) | **525,682** | 5,998 | 20,991 |
| إدمان الشاشات (screen addiction) | 152,494 | 2,370 | 17,486 |
| 5 عبارات لتعزيز الثقة | 147,101 | 5,937 | 9,629 |
| أمي حين تختارين لي | 70,351 | 39 | 1,528 |
| — | — | — | — |
| **"آدم ليس تطبيقاً" (product)** | **770** | 0 | 3 |
| **"مرافق تربوي" (product)** | **615** | 4 | 1 |
| **"تطلبين منه أمراً بسيطاً" (product)** | **456** | 3 | 1 |
| **"مرافق تربوي" (product)** | **445** | 0 | 0 |

**Content that names a parenting pain reaches ~1,150x more people than content that describes the product.** The audience is enormous and highly engaged; the bridge from audience to product is nearly absent.

### Comment analysis (per instructions: CTA-only comments clustered, not individually analysed)
Last-30-day comments are overwhelmingly a single clustered pattern: trigger-word replies to a keyword-DM campaign — "سامحني" / "سامحيني" / transliterations (Samihini, Samahni, …), "آدم"/"Adam", and emoji-only reactions (😭 🥺 😢). These are excluded from insight extraction as instructed.

Two observations survive the filter:

1. **The primary acquisition hook is parental guilt.** The dominant trigger word is *سامحني* — "forgive me." The campaign asks parents to publicly apologise to their child. This is emotionally potent (it drove 525k reach) but selects for a guilt-activated state, which has consequences discussed in §10 and §14.
2. **Unprompted gratitude exists**: "شكرا لكم على ادم 😍.. جزاكم الله عنا خير الجزاء" — the only substantive non-CTA comment in the window, and it is a testimonial.

---

## 6. Jobs To Be Done

Applying Christensen's framework to 2,086 human messages.

### Primary job

> **When** my child does something I can't handle and I've already lost my temper,
> **I want to** understand what's actually driving it and get one thing I can do tonight,
> **so that** I can stop being the angry parent I don't want to be.

Note what this job is *not* about: it is not primarily about fixing the child. The parent is hiring ADAM to change **their own identity**. This is the deepest insight in the research and it is stated almost verbatim by users:

> "بس اريد اكون ام اسلوبها هادئ ومااريد اكون ام عصبيه"
> *(I just want to be a mother with a calm approach — I don't want to be an angry mother.)*

### Three dimensions

| Dimension | Job | Verbatim evidence |
|---|---|---|
| **Functional** | Diagnose behaviour, get one executable step | "كيف اتعامل مع ابني حيث هو لا يبالي بكلامي" |
| **Emotional** | Stop feeling like a failure; be seen without judgement | "أنا عايزه حد يشوفنى حلوه من جوه من غير احكام" *(I want someone to see me as beautiful inside, without judgement)* |
| **Social** | Be a parent whose children remember warmth, not shouting | "لا اريد أن اصبح اما سيئة لأولادي وعندما يكبرون لا يذكرون الا الصراخ والتوبيخ" *(I don't want to become a bad mother whose children, when grown, remember only shouting and scolding)* |

**All three dimensions are strongly evidenced.** The emotional and social dimensions are, if anything, *stronger* than the functional one — which the current offer copy under-uses relative to its feature list.

### Secondary job — intergenerational trauma interruption
> "نعم لدي لكنني أبحث عن أمان أبنائي لا أريد أن تنتقل لهم الصدمات"
> *(Yes I have [trauma], but I'm seeking safety for my children — I don't want it transmitted to them.)*

This is a distinct and powerful job that the product does not currently name in any copy.

### The Four Forces

| Force | Strength | Evidence |
|---|---|---|
| **Push** (frustration with status quo) | 🟢 **Very strong** | 73 messages express guilt/self-blame; 28 express exhaustion; 132 reference hitting |
| **Pull** (attraction of ADAM) | 🟢 **Strong** | 11.1 avg turns; 34% of sessions >10 turns; unprompted "خسارة انك لا تذكرني" |
| **Anxiety** (fear of the new) | 🟡 **Moderate, unaddressed** | Repeated "are you free or paid?" confusion; "هل انت ذكاء اصطناعي مجاني ام مدفوع" |
| **Habit** (inertia) | 🔴 **Very strong, unaddressed** | Manual bank transfer; 94% never finish onboarding |

**Diagnosis:** Push and Pull are both strong. The product is losing on **Anxiety and Habit** — precisely the two forces the JTBD literature identifies as most commonly ignored. Current strategy invests almost entirely in increasing Pull (better offer copy, better agent prompts) while the actual blockers are payment friction, tier confusion, and a 48% geographic wall.

### Big Hire vs Little Hire

- **Little Hire (using ADAM in the moment): WON.** 11.1 turns/session, deep disclosure, users returning (32 with return_count > 0).
- **Big Hire (paying): NOT TESTED.** 8 offers, 0 clicks, 1 payment. The machinery that would create Big Hire moments is inactive.

This is an unusual and *favourable* position: most products lose the Little Hire. ADAM has won the hard part.

### Competition (non-obvious)
| Competitor | Nature |
|---|---|
| **Non-consumption** — coping alone | Largest competitor by far |
| **Free ChatGPT / Gemini** | Direct, free, no memory, no Arabic parenting specialisation |
| **The Instagram content itself** | ADAM's own free content competes with ADAM's paid product |
| Extended family / mother-in-law advice | Culturally dominant default |
| Paid child psychologists | High cost, stigma, scheduling friction |

**The most under-appreciated competitor is ADAM's own free tier**, by explicit design ("الوصفة تُعطى كاملة دائماً").

### JTBD Quick Diagnostic score: **9/10**
Job stated without naming the product ✅ · four forces mapped ✅ · three dimensions evidenced ✅ · non-obvious competition incl. non-consumption ✅ · Little Hire tracked separately ✅. Point deducted: purchase-timeline switch interviews have not been run with actual payers (n=1 available).

---

## 7. Personas

### Persona A — "The Exhausted Mother" (primary, ~58% of audience)
- Woman, 25–44, Egypt/Algeria/Morocco/Iraq/Syria, 1–3 children aged 2–11
- **Trigger moment:** after shouting or hitting, alone at night, flooded with guilt
- **Current alternatives:** Instagram reels, family advice, nothing
- **Job:** stop being the angry mother; be seen without judgement
- **Quote:** "بنتي عمرها ٤ سنوات حاسة اني فاشله ف التربية"
- **Blocker:** may be in a waitlisted country; cannot pay by card

### Persona B — "The Waitlisted Parent" (~48% of signups, ~58% of audience)
- Iraq, Syria, Saudi, Jordan, Yemen, Oman, Gulf
- **Identical job to Persona A**, but hits a wall at country selection
- **Gulf sub-segment has notably higher ability to pay than current markets**
- **This is the single largest untapped segment and it is being actively turned away**

### Persona C — "The Engaged Father" (~18.5% of audience)
- Man, 25–44; 4 of 18 declared users
- Job includes discipline/authority framing alongside emotional connection
- **Product inconsistency:** Heart Writer assumes motherhood; offer copy handles both

### Persona D — "The Crisis Parent" (small but critical)
- Disclosing abuse by third parties, bereavement, substance use in teens, or their own violence
- **Quotes:** "حذرنا المعتدي سابقا…" · "اكتشفت أنه يدخن ويتعاطى" · "طفلتي أو بالأحرى أختي الصغيرة… لأننا فقدنا أمنا منذ عام"
- **Needs escalation paths that do not currently exist** (see §13, §16)

---

## 8. User Pain Points

Frequency across 2,086 human messages:

| Theme | Messages | % | Note |
|---|---|---|---|
| Asking "how do I…" | 168 | 8.1% | Wants procedure, not theory |
| **Hitting / violence** | **132** | **6.3%** | Child→sibling, child→parent, **and parent→child** |
| Speech / developmental delay | 98 | 4.7% | Largely unserved by current design |
| Defiance / not listening | 83 | 4.0% | Matches top-performing content |
| Anger (child's or parent's) | 78 | 3.7% | |
| **Guilt / self-blame** | **73** | **3.5%** | The emotional core |
| Sibling conflict | 56 | 2.7% | |
| Fear / anxiety in child | 54 | 2.6% | |
| Money / price | 52 | 2.5% | See §10 |
| Screens | 49 | 2.4% | 152k-reach content topic |
| Eating | 45 | 2.2% | |
| School | 42 | 2.0% | |
| Screaming | 42 | 2.0% | |
| Sleep | 35 | 1.7% | |
| Exhaustion / burnout | 28 | 1.3% | |
| Neurodevelopmental (ASD/ADHD) | 10 | 0.5% | |

### Product-level pain points

**P1 — Onboarding abandonment: 94.1%.** Only 17/289 complete. 271 sit at step 0. The 6-step flow (gender→age→pain→time→state→step) is asked *before* the parent has received any value.

**P2 — The waitlist wall.** 48.4% of signups blocked at the first interaction.

**P3 — Free/paid confusion.** Users repeatedly cannot tell which tier they are on:
> "انا الان في المدفوع او المجاني" · "انا في الخطة المجانية؟" · "هل انت ذكاء اصطناعي مجاني ام مدفوع"

**P4 — Memory loss is felt as abandonment.** The clearest product signal in the dataset:
> "خسارة انك لا تذكرني . اريد ان تحفظ ما اقوله لك دائما"
> *(It's a shame you don't remember me. I want you to always keep what I tell you.)*
This is a user independently articulating the exact paid value proposition — unprompted.

**P5 — Data integrity (live bug).**
- `message_count` frozen at 0 for all signups since ~25 July while those users actively converse (verified: user `6300769527` has 15 real human messages, counter reads 0).
- **47 of 188 chat sessions (25%) have no `followers` row** — orphaned conversations invisible to the funnel and to every engagement-gated automation.
- Agent context scaffolding is being persisted *into* the human message record: rows begin `=[اليوم 1 من 30 | متبقي 30 يوم]\n\n=== ذاكرة الرحلة ===` followed by ADAM's own prior output. This pollutes memory and inflates token cost.
- One AI message is **169,230 characters** — an anomaly ~466x the 363-char average.

**P6 — Dead data structures.** `messages` (0 rows), `collective_intelligence` (0), `weekly_plans` (0), `survey_responses` (0 — despite 29 surveys sent, because the capture workflow is inactive).

---

## 9. User Desired Outcomes

In users' own words — these are the outcomes to write copy and metrics against:

| Desired outcome | Verbatim |
|---|---|
| **Become a calm parent** | "بس اريد اكون ام اسلوبها هادئ ومااريد اكون ام عصبيه" |
| **Earn love without fear** | "عايزة اتعامل بيها معاهم اكسب قلوبهم واحترامهم من غير خوف" |
| **Be seen without judgement** | "أنا عايزه حد يشوفنى حلوه من جوه من غير احكام" |
| **Break the trauma cycle** | "لا أريد أن تنتقل لهم الصدمات" |
| **Not be remembered as the shouting parent** | "عندما يكبرون لا يذكرون الا الصراخ والتوبيخ" |
| **Be remembered by ADAM** | "اريد ان تحفظ ما اقوله لك دائما" |
| **Child faces fears instead of fleeing** | "أريده أن يتعلم مواجهة مخاوفه بدل الهرب منها" |
| **Concrete, immediate tactics** | "عاوزه افكار تساعدني ع تعديل النوم بدري بدل السهر" |

**Strategic read:** the top four outcomes are about the *parent's* identity and self-perception, not the child's behaviour. Current offer copy leads with a four-bullet feature list (memory, diagnosis, daily step, tracking). It is selling the functional dimension into an emotionally-driven job.

---

## 10. Objections

Real objections extracted from conversation data:

**O1 — Affordability (strongest).**
> "صراحة ما بقدر على الاشتراك" *(honestly I can't afford the subscription)*
> "ممكن تساعدني من غير فلوس دلوقتي" *(can you help me without money right now)*

**O2 — Betrayal at monetisation.** The sharpest signal in the dataset:
> "انت طلعت بفلوس اخص عليك"
> *(So you turned out to cost money — shame on you.)*
The free tier's warmth creates an implicit expectation of unconditional help. Introducing price is experienced by some users as a moral breach, not a commercial transaction. This is a direct consequence of the guilt-based acquisition hook plus a deliberately generous free tier.

**O3 — 🔴 Price inconsistency (trust-critical).**
> "عارفه قلت لك قبل كده مصر وقلت لي الاشتراك 150 جنيه"
> *(I know — I told you before I'm in Egypt and you told me the subscription is 150 EGP.)*
The current Egypt price is **490 EGP**. A user was quoted **150 EGP**. Meanwhile the single confirmed payment was **490 EGP**, and a Machine 5 code comment warns "2300 DZD renewal — NEVER 1900," implying prior Algerian price drift too. **The system has quoted at least three different prices across markets and time.** For a product whose entire moat is trust, this is the most damaging non-security defect found.

**O4 — Tier confusion as pre-purchase anxiety.** (see P3) Users cannot form a purchase intent when they cannot tell what they currently have.

**O5 — Identity uncertainty.**
> "قولي قبل من انت عرفني بنفسك هل انت ذكاء اصطناعي مجاني ام مدفوع"

---

## 11. Product Strengths

1. **Conversation quality is the moat.** 11.1 avg turns, 138 max, deep disclosure of abuse and bereavement. Parents trust ADAM with material they hide from family.
2. **Memory architecture is genuinely differentiated** and — per P4 — users notice and want it without being sold it.
3. **Safety-first memory design is exemplary.** The Heart Writer's rule to leave trauma unrecorded is ethically sophisticated and rare.
4. **Anti-guilt discipline is encoded system-wide.** Offer prompts explicitly forbid blame ("هي متعبة لا مذنبة") and ban scarcity/urgency tactics outright.
5. **Distribution is proven at scale.** 525k reach on a single post; ~41k engaged audience built organically.
6. **Value-per-effort constraint** (2–3 line replies) is well-matched to an exhausted user in a hostile moment.
7. **Renewal Guard preserves memory through downgrade** — a thoughtful win-back design already built.

---

## 12. Product Weaknesses

1. **The monetisation pipeline is off.** Judge + Silent Seller + First Insight inactive. Willingness to pay has never been fairly tested.
2. **48% of demand rejected at the door.**
3. **94.1% onboarding abandonment** — value is demanded before value is delivered.
4. **Manual payment only.** No processor; CCP transfer + receipt photo, or DM an operator.
5. **Price inconsistency across markets and time** (§O3).
6. **Live data-integrity bugs** corrupting every funnel metric (§P5) — including 25% orphaned sessions.
7. **🔴 Hardcoded production credentials** in workflow nodes (§4).
8. **Free tier is deliberately un-monetisable** by prompt design, with no compensating conversion mechanism.
9. **Feedback loop broken:** 29 surveys sent, 0 responses captured, because the capture workflow is inactive.
10. **No escalation path for crisis disclosures** despite documented abuse/bereavement/substance-use content.
11. **Persona inconsistency:** Heart Writer assumes mothers; ~18.5% of audience is male.
12. **Dead schema** (4 empty tables) increases maintenance surface and obscures intent.

---

## 13. Missing Opportunities

**M1 — Unserved geography (largest single opportunity).** 23,697 audience members and 140 waitlisted signups in unsupported countries. Gulf states (~5,749) have materially higher ability to pay than DZ/EG/MA. Requires only a payment rail, not product change.

**M2 — Turn on what is already built.** Judge, Silent Seller, and First Insight are complete and dormant. First Insight in particular is designed as the trial's "wow moment" — data-gated at 3+ logged nights — and has fired **zero** times.

**M3 — Bridge content to product.** A 525k-reach post drives ~0.7% of audience to the bot. Even a 3% bridge on existing reach would multiply the user base several-fold with no new acquisition spend.

**M4 — Sell the identity outcome, not the feature list.** Offer copy leads with memory/diagnosis/steps/tracking. Users articulate wanting to *become calm parents* and to *be seen*. The emotional and social JTBD dimensions are under-sold.

**M5 — Speech/developmental delay is the #3 theme (98 messages) and is entirely unaddressed** by the current pain taxonomy (`anger`, `fear`, `obey`, `not_listen`, `screen`, `cry`, `siblings`).

**M6 — The 47 orphaned sessions** represent real engaged users completely invisible to the funnel.

**M7 — Collective intelligence.** 4,172 conversations constitute a uniquely valuable Arabic parenting dataset. The `collective_intelligence` table exists and is empty.

**M8 — Community.** Content posts already drive users to WhatsApp channels. A peer community would address the "I am alone in this" job dimension that 1:1 chat cannot.

---

## 14. Product-Market Fit Assessment

### Level: **1.5 of 4** (Solution Fit achieved; Product-Market Fit not established)

| Level | Status | Evidence |
|---|---|---|
| **0 — Problem Fit** | ✅ **Strong** | 73 guilt messages, 132 violence-related, 525k-reach content, ~41k organic audience |
| **1 — Solution Fit** | ✅ **Achieved** | 11.1 turns/session; 34% >10 turns; deep disclosure; unprompted memory requests |
| **2 — Product-Market Fit** | ❌ **Not demonstrated** | 1 confirmed payment; 0/8 CTA clicks; no pull toward purchase |
| **3 — Scale Fit** | ❌ Not attempted | Manual payments; 4/11 workflows active |
| **4 — Moat Fit** | 🟡 Latent | Memory + Arabic + trust are defensible *if* monetised |

### The central strategic judgement

**The absence of PMF evidence is not the same as evidence of absent PMF.** The conversion machinery has been switched off for the entire period in which meaningful traffic arrived. Of 289 followers, only 8 have ever seen an offer, and those 8 saw it during a one-week window in mid-July.

This is a **measurement failure before it is a market failure.** The honest position: ADAM has demonstrated that parents will *engage deeply and disclose intimately*. It has not yet run the experiment that would show whether they will *pay*.

There is, however, a genuine strategic tension that turning the machinery on will not resolve by itself:

> The free tier is designed to give everything ("الوصفة تُعطى كاملة دائماً"), the acquisition hook activates guilt, and the paid tier's differentiator is memory — an abstraction the offer prompt itself concedes is hard to sell ("لا أحد يشتري ذاكرة" — *nobody buys memory*).

The "انت طلعت بفلوس اخص عليك" objection is the predictable output of that combination. Monetisation design, not just monetisation activation, needs attention.

---

## 15. Prioritised Recommendations

Each carries its supporting evidence. Sequencing reflects reversibility (Type 1 vs Type 2 decisions).

### P0 — Do before anything else

**R1. Rotate all exposed credentials and migrate to n8n credential references.**
*Evidence:* Supabase `service_role` key and ≥2 Telegram bot tokens hardcoded in plaintext across multiple workflow nodes (§4). Service-role bypasses RLS on a DB containing 4,172 conversations with abuse disclosures and identifiable children.
*Type 1 (irreversible if exploited). Cost: hours.*

**R2. Fix the `message_count` counter and the 47 orphaned sessions.**
*Evidence:* User `6300769527` has 15 human messages, counter reads 0; 47/188 sessions (25%) have no `followers` row (§P5).
*Rationale:* Every downstream decision — including whether to trust this report's funnel numbers — depends on this. The Judge gates on engagement it cannot currently see.
*Type 2. Cost: low.*

**R3. Resolve price inconsistency and publish one price per market.**
*Evidence:* User quoted 150 EGP; current price 490 EGP; only confirmed payment 490 EGP; code comment warns "NEVER 1900" for DZ (§O3).
*Rationale:* Trust is the entire moat. Nothing else in this list survives a customer who believes they were misquoted.
*Type 1. Cost: hours.*

### P1 — Run the experiment that has never been run

**R4. Reactivate The Judge + Silent Seller + First Insight, in that order.**
*Evidence:* All three complete and inactive (§4). 8 offers ever sent; `insight_sent = 0` across all users (§1).
*Rationale:* PMF cannot be assessed while the conversion path is off. First Insight is the designed trial wow-moment and has never fired once.
*Type 2 (fully reversible). Cost: low — the code exists.*
*Success criterion: ≥30 offers presented and a measured click-through, within 3 weeks.*

**R5. Reactivate Survey Reply Inbox and re-run the founder survey.**
*Evidence:* 29 surveys sent, `survey_responses` = 0 rows, capture workflow inactive (§P6).
*Rationale:* This is the only direct qualitative channel and it has been discarding every reply. Restores the Discovery loop.
*Type 2. Cost: minimal.*

### P2 — Unlock demand already knocking

**R6. Open one high-ability-to-pay unsupported market (recommend Saudi Arabia or Iraq).**
*Evidence:* 23,697 unserved audience; 140 waitlisted signups; SA 2,175 / IQ 4,655 followers (§5, §M1).
*Rationale:* Requires a payment rail, not product change. Largest single lever available.
*Type 1 (operationally hard to reverse). Recommend piloting with the existing manual rail before building automation.*

**R7. Add an automated payment option for at least one market.**
*Evidence:* Habit is the strongest unaddressed force (§6); current flow requires bank transfer plus receipt photo.
*Type 1. Cost: moderate.*

### P3 — Fix the funnel's shape

**R8. Move onboarding after first value, not before it.**
*Evidence:* 94.1% abandonment (271/289 at step 0), while conversation itself sustains 11.1 turns (§P1).
*Rationale:* The data shows parents will talk at length but will not fill in a form first. Let ADAM infer gender/age/pain from conversation — the Heart Writer already extracts exactly these fields.
*Type 2. Recommend A/B test rather than wholesale replacement.*

**R9. Make tier status permanently visible.**
*Evidence:* Repeated "am I free or paid?" confusion (§P3, §O4).
*Type 2. Cost: trivial.*

**R10. Rewrite offer copy to lead with identity outcomes.**
*Evidence:* Top four desired outcomes are about the parent's self-perception (§9); current copy leads with a feature list (§4).
*Suggested lead:* the parent's own words — *"أن تكوني الأم الهادئة التي تريدينها"* — before any feature.
*Type 2. Cost: low.*

**R11. Add a content→product bridge to high-reach posts.**
*Evidence:* 525,682 reach vs 445–770 on product posts; ~0.7% audience conversion (§5, §M3).
*Type 2. Cost: low. Highest ROI per hour of the entire list.*

### P4 — Address coverage and duty of care

**R12. Define an escalation protocol for crisis disclosures.**
*Evidence:* Documented disclosures of third-party abuse, bereavement, adolescent substance use, and parental violence (§7 Persona D, §8).
*Rationale:* Heart Writer correctly refuses to *store* these, but nothing defines what ADAM should *do* about them in the moment. This is a duty-of-care gap, not a growth item — but it carries real risk.
*Type 1. Requires human judgement, not automation.*

**R13. Extend the pain taxonomy to include speech/developmental delay.**
*Evidence:* 98 messages (#3 theme), absent from the current 8-value taxonomy (§M5).
*Type 2. Cost: low.*

**R14. Resolve the mother-only assumption in Heart Writer.**
*Evidence:* 18.5% male audience; 4/18 declared users male; prompt hardcodes "أمٍّ" (§5, §12).
*Type 2. Cost: trivial.*

---

## 16. Open Questions Requiring Further Research

**Q1. Why were Judge, Silent Seller, and First Insight deactivated?** Deliberate pause, cost control, or a defect? This single answer changes whether R4 is a 1-hour or 3-week task. *Requires: founder input — not derivable from data.*

**Q2. Are the 4 `paid_active` records seed data?** All four have `message_count = 0`, blank country, no memory, created day one, while `payments` holds exactly one row. Strong inference, not proof. *Requires: founder confirmation.*

**Q3. Did the single paying customer renew, and why did they pay?** n=1 (490 EGP, Egypt, confirmed 19 July). The single most valuable interview available. *Requires: a JTBD switch interview.*

**Q4. Why did 0 of 8 offer recipients click either button?** Zero clicks on *both* "ready" and "stay free" suggests a possible delivery/callback defect rather than pure rejection — 4 of the 8 never returned after the offer date. *Requires: log inspection + user follow-up.*

**Q5. What is the true engagement baseline?** With a broken counter and 25% orphaned sessions, all funnel percentages in this report are lower bounds. *Requires: R2 first.*

**Q6. What happened to the 150 EGP price point?** Historical pricing decisions are not recoverable from the data. *Requires: founder input.*

**Q7. Would waitlisted users actually pay?** 140 people expressed intent then hit a wall. Their willingness to pay is completely unmeasured. *Requires: a concierge test — manually serve 10 waitlisted Gulf users.*

**Q8. Is the guilt-based acquisition hook net-positive?** It produces 525k reach and also produces "انت طلعت بفلوس اخص عليك." *Requires: cohort comparison of guilt-hook vs curiosity-hook signups — testable with existing `signup_source`.*

**Q9. What is the 169,230-character AI message?** Likely a runaway generation or a serialisation defect; unquantified cost and UX impact. *Requires: log inspection.*

**Q10. Retention beyond 30 days is unmeasurable.** Only 4 users have `return_count ≥ 3`; the oldest real cohort is ~4 weeks old. *Requires: time.*

---

## Appendix — Key Metrics Reference

| Metric | Value | Source |
|---|---|---|
| Total followers | 289 | `followers` |
| Waitlisted (unsupported country) | 140 (48.4%) | `followers` |
| Onboarding completed | 17 (5.9%) | `followers` |
| Trial started | 8 (2.8%) | `followers` |
| Offers presented (all time) | 8 (2.8%) | `followers` |
| CTA clicks | **0** | `followers` |
| First Insight sent | **0** | `followers` |
| Confirmed payments (all time) | **1** (490 EGP) | `payments` |
| `paid_active` rows | 4 (all `message_count`=0 — likely seed) | `followers` |
| Chat messages (live) | 4,172 (2,086 human / 2,086 AI) | `n8n_chat_histories` |
| Chat messages (archived) | 3,428 | archive table |
| Conversation sessions | 188 | `n8n_chat_histories` |
| **Avg human turns/session** | **11.1** | derived |
| Sessions >10 turns | 64 (34%) | derived |
| Longest session | 138 turns | derived |
| **Orphaned sessions (no follower row)** | **47 (25%)** | join |
| Instagram audience | ~41,109 | Windsor |
| — in supported countries | 17,412 (42.4%) | Windsor |
| — unserved | 23,697 (57.6%) | Windsor |
| Women 25–44 | 18,348 (44.4%) | Windsor |
| Best post reach | 525,682 | Windsor |
| Best product-post reach | 770 | Windsor |
| Workflows active | **4 of 11** | n8n |

---

**End of report.** Awaiting review before any design or implementation work proceeds.
