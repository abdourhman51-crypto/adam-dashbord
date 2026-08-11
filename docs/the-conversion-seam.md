# المرحلة بين المجاني والمدفوع — الجسر، مُؤتمتاً

**Written:** 2026-08-11. A design pass, not a build. Nothing here is wired, no
engine is turned on, and no data is collected. It puts the microscope on the one
stretch of the product the founder named as the priority: **what happens from the
moment a free parent is ready, to the moment they are running a paid journey with
a plan built for their child** — and how much of that a human still touches.

Everything below is checked against the live functions and migrations, not
recalled. Where something exists it says so; where it is missing it says so as a
fact.

---

## The problem, stated honestly

There are no fixed plans in this product. There is no «حزمة النوم» and no «برنامج
العناد». The founder's rule is deliberate: **each family gets a plan built from
their own child's evidence, not pulled off a shelf.** That is the whole
differentiator (`menu_why`: «النصيحة العامّة تصلح لكل الأطفال، ولهذا لا تصلح لطفلكم
بالذات»).

But a plan that is not on a shelf has to come from *somewhere*. Today it comes
from a person: the parent reaches فريق آدم, and a human agrees the goal and, in
the founder's words, «يحدّدون الخطوة». The founder wants that person removed from
the deciding — not from the cashier's desk, from the deciding.

The constitution already says the human should not be deciding. §7 of
`adam-system.md` is explicit:

> **فريق آدم أمين صندوق، لا وكيل مبيعات. الوالد يصل إليه بعد أن قرّر، لا ليُقنَع.**

So this design is not a new direction. It is closing the gap between what the
constitution says the human is (a cashier) and what the human is currently doing
(agreeing the goal and improvising the daily step).

---

## Where the seam actually breaks — three gaps, measured

Walking the path a ready parent takes today, function by function:

| Step | What runs today | State |
|---|---|---|
| The fork on the evening harvest | `take_offer_moment` → «نتركه يتكرّر / نشتغل عليه» | ✅ live, stamped once |
| Tap «نشتغل عليه» | `cta_full_companion` → `menu_journey` | ✅ live |
| The offer surface (price, guarantees, CTA) | `get_conversation_moment('menu_journey')` | ✅ live |
| **Agree the goal** | a human reads `suggest_objective` and agrees it by DM | 🔴 **manual** |
| **Take payment** | a human confirms money, runs the dashboard | ✅ correct — cashier |
| Start the journey | `activate_subscription` → `start_stage` | ✅ live, but the human types the objective |
| **The daily plan** | — | 🔴 **does not exist as content** |
| Close the journey | `close_stage` → after-arrival | ✅ live |

Three of those rows are the seam, and they are the whole of what the founder is
pointing at.

### Gap 1 — the goal is agreed by a human, not in the chat

`suggest_objective(parent)` already exists and already does the hard part: it
reads the child's confirmed situation and returns the exact sentence to agree —
«خمس ليالٍ هادئة من سبع في النوم مع يوسف» — or `ready:false` with a reason when we
do not yet know enough. It was built to be **read out by فريق آدم**. The parent
never sees it. So the one moment that turns a vague «نشتغل عليه» into a concrete,
measurable, agreed goal happens in a human's DM, off the rails, un-recorded.

### Gap 2 — the plan has a skeleton but no body

This is the important one, and it is easy to miss because half of it looks done.

The journey has a **spine**: `stages` holds the objective, the clock counts logged
days (not calendar days), and `v_stage_progress` derives the phase —
`observe → build → hold` — automatically from how many days were logged. There is
even a **gate** for the daily step: `can_send('journey_step', parent)` returns
`ready` once there is a live journey, an objective, and at least one outcome.

But a gate only says *whether* a step may be sent. **Nothing composes what the
step says.** There is:

- no `compose_journey_step()` — no function that turns the objective + phase +
  the child's last outcome into tonight's single small step;
- no route in `get_rhythm_due` that sends a paid parent a `journey_step` instead
  of an ordinary free `seed`.

So even with the engines on, a parent inside a paid journey would receive the
**identical** free-tier seed as everyone else. The «خطة مخصّصة» the offer sells
does not exist as a daily experience yet. The skeleton is real; there is no
muscle on it.

### Gap 3 — the human is doing two jobs, and only one is theirs

Right now فريق آدم is the goal-agreer **and** the cashier. The constitution allows
them exactly one of those. The reason the cashier stays human is real and
unchanged: there is no trusted local payment automation in DZ/EG/MA yet, so a
person still has to confirm the money arrived. That is the *only* thing that must
stay human. The goal (Gap 1) and the step (Gap 2) are software.

---

## The principle

**The plan is not authored. It is grown, one day at a time, from the child's own
evidence — bounded by the goal the parent agreed and shaped by where they are in
the journey.**

This is the answer to «كيف نصنع خطة مخصّصة لكل عميل بلا خطط ثابتة». You do not build
a plan-authoring tool and you do not pre-write plans. You reuse the engine that
already grounds the free seed — child, situation, what worked yesterday — and you
give it a **spine** (the objective) and a **posture** (the phase). Two families
who both said «النوم» get different steps every night, because their children
differ and because last night differed. The personalisation is not a feature you
add; it is what you get for free once the daily step reads the child instead of a
template.

And the human shrinks to one sentence of work: **«وصلني المبلغ.»**

---

## The seam, redesigned — the automated path

Six moments. What already exists is marked; what is new is named precisely, so the
build (when the founder approves it) is a list, not a discovery.

### 1 — The fork · ✅ exists

The evening harvest, on a good night, once ever:
«لاحظنا شيئاً يتكرّر مع يوسف. هل نتركه يتكرّر... أم نشتغل عليه حتى يتغيّر؟»
Tap «نشتغل عليه». (`take_offer_moment`, live.)

### 2 — Agree the goal, in the chat · ✅ BUILT 2026-08-11

Before any price is shown, ADAM proposes the concrete goal it already knows how to
compute, and asks the parent to own it:

> لاحظت أن أصعب لحظة مع يوسف هي **النوم**.
> أقترح هدفاً نراه معاً، لا شعوراً نتجادل فيه: **خمس ليالٍ هادئة من سبع**.
> هل هذا هو ما تريدون أن نعمل عليه؟
> · نعم، هذا هو · لا، المشكلة الأكبر شيء آخر

- **«نعم»** → the agreed objective is stamped on a `stage_proposals` row
  (`outcome = pending`, objective attached). Go to 3.
- **«شيء آخر»** → ADAM asks them to name it in their own words. The situation
  classifier (W2) confirms the new problem, and the goal is recomputed for *that*
  problem, then re-proposed. This loop is the «مخصّص» made literal: the goal is
  grounded in whichever problem the parent names, never chosen from a menu.
- If `suggest_objective` returns `ready:false` (no confirmed situation yet), ADAM
  does not fake a goal — it says plainly that it needs a few more evenings first,
  which is the same honesty the free tier already lives by.

**Build cost:** two conversation moments and two callbacks on the existing tap
pipeline (no new credentialed n8n node — same pattern as the country taps). One
small function, `agree_objective(parent)`, that stamps the proposal.

### 3 — The offer surface · ✅ exists, one change

`menu_journey` already sells the result, not the mechanism, with the three
guarantees the schema enforces (logged-day clock, free half-length extension,
automatic refund). It shows the price for the parent's country. **One change:** its
call-to-action button carries the parent to the cashier with the goal *already
agreed and attached*, so the human has nothing to decide — only to receive money.

### 4 — Payment · ✅ stays human, correctly

The parent pays through فريق آدم because no local payment rail is automated yet.
The human's entire job becomes one action: confirm the money arrived. **They never
type a goal** — `activate_subscription` reads the agreed objective from the
`stage_proposals` row stamped in step 2, instead of taking it as an argument a
human fills in. A paid parent with no agreed goal is already impossible to create
silently (the function returns `journey.started = false, reason =
objective_required`), so this simply moves the goal from the human's keyboard to
the parent's own confirmation.

**Build cost:** `activate_subscription` gains a path that pulls the pending
proposal's objective when the caller does not pass one. The dashboard's "confirm
payment" screen loses its goal field.

### 5 — The daily plan · 🔴 new (this is the real work)

Each day, for a parent in a live journey, the rhythm sends a `journey_step`
instead of an ordinary seed. A new composer builds tonight's single small step
from four facts, and nothing else:

| Input | Where it already lives |
|---|---|
| the agreed objective | `stages.objective_text` |
| the phase — observe / build / hold | `v_stage_progress.phase` |
| the child's confirmed situation | `situations` |
| last night's outcome (worked / did not) | `daily_logs` (most recent) |

The phase is the posture, and it is what makes the plan feel like a plan rather
than a stream of tips:

- **observe** (first days) — change nothing. «الليلة، لا تغيّروا شيئاً — فقط
  لاحظوا متى بالضبط يبدأ التوتّر قبل النوم.» We are learning the real trigger, not
  guessing.
- **build** (the middle) — one step a day, each built on what worked yesterday for
  *this* child. Never a lecture; small enough to try on the worst night.
- **hold** (the last third) — ADAM deliberately fades. «أنتم تعرفون الآن ما ينفع.
  الليلة لن أقترح شيئاً — سأسألكم فقط كيف مرّت.» The calm has to be shown to belong
  to the family, not to ADAM. Nothing may shorten this phase.

The LLM writes the language; the function supplies the four facts and the phase
discipline, and the existing uniqueness test (`passes_uniqueness_test`) forbids
repeating a step. **This is why there are no fixed plans and no plan-authoring
screen: the plan is regenerated every night from the child's evidence, and the
objective + phase are the only things that make two nights cohere into a journey.**

**Build cost:** `compose_journey_step(parent)` (a facts function, LLM-facing, the
sibling of the free seed grounder). A `journey_step` branch in `get_rhythm_due`.
A `journey_step` branch in W3 that composes and sends. All of it is offline-testable
against a synthetic family exactly like `lifecycle_test.sql` already does — no
users, no sends, no cost, until the founder turns W3 on.

### 6 — Close · ✅ exists

`close_stage`: met → `completed` → the after-arrival sequence
(`docs/after-arrival.md`); missed once → the free half-length extension, granted
unrequested; missed again → automatic refund. Live and tested.

---

## What stays a human, forever, and why that is correct

One thing, and it is the cashier: confirming the payment arrived. Not because the
product cannot be trusted to the software, but because the *money rail* cannot yet
— there is no automated local payment in the three countries. The moment that
exists, even the cashier can go. Nothing in this design depends on the human doing
anything except that one confirmation, so nothing has to be rebuilt when the rail
arrives.

Everything the founder called «تحديد الخطوة» — the goal and the daily plan — becomes
software in steps 2 and 5.

---

## The build order, when approved

Smallest and safest first, each one offline-testable, none of it turning an engine
on:

| # | Build | Depends on | Cost | State |
|---|---|---|---|---|
| 1 | `agree_objective` + the two goal-agreement moments (step 2) | nothing | small | ✅ **done 2026-08-11** — `20260811120000`, 31 assertions, zero n8n change |
| 2 | `activate_subscription` reads the agreed goal (step 4) | 1 | small | ✅ **done 2026-08-11** — `20260811130000`, cashier never types the goal |
| 3 | `compose_journey_step` + its offline test on a synthetic family (step 5) | nothing | **the real work** | pending |
| 4 | `journey_step` route in `get_rhythm_due` (step 5) | 3 | small | pending |
| 5 | W3's `journey_step` branch — compose + send | 4 | wiring, W3 stays paused until launch | pending |

Steps 1–4 are pure database with an offline suite, the same shape as everything
built this month. Step 5 is the only one that touches a live workflow, and it
changes a **paused** one, so nothing a real parent sees moves until the founder
decides to turn it on.

Nothing in this document has been built. It is the map of the seam, drawn from the
code as it stands on 2026-08-11.
