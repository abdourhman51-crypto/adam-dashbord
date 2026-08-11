# لحظة الاتفاق — the conversion moment, under the microscope

**Written:** 2026-08-11. **BUILT the same day** —
`supabase/migrations/20260811120000_the_agreement_moment.sql`,
`supabase/tests/agreement_moment_test.sql` (31 assertions, zero failures on the
real migrated schema), and **zero n8n change**: the whole moment lives in the
database, reached through the tap pipeline that already exists. No engine was
turned on and no data is collected. What follows is the design; the "how it was
built" note is at the end.

A design pass on the single most important moment in the product's life: the
crossing from free to paid. It expands step 2 of `docs/the-conversion-seam.md`
into the depth the founder asked for — the funnel that delivers a parent to this
moment, how the moment appears, how the menu phrases the door, and the failure
modes a world-class version has to pre-empt.

Grounded in the live functions: `take_offer_moment`, `suggest_objective`,
`is_team_question`, `get_telegram_surface` (`meaning='open_question'`),
`commerce_allowed`, `followers.offer_fork_at`, `stage_proposals`.

---

## Why this moment is the whole game

Everything before it is free and costs the company money. Everything after it is a
paid relationship. This is the one hinge. Get every other screen slightly wrong and
you lose polish; get this one wrong and there is no revenue to polish.

And it is the easiest moment to get wrong, because the obvious version is a trap.
The obvious version is: parent shows interest → show price → ask for the sale. That
version treats the parent as someone to be *closed*. The constitution forbids it in
one sentence (§7):

> **فريق آدم أمين صندوق، لا وكيل مبيعات. الوالد يصل إليه بعد أن قرّر، لا ليُقنَع.**

The parent must arrive at the cashier **already decided**. Which means the deciding
happens earlier, in the chat, with ADAM — and it happens over a **goal**, never over
a price. That is what «لحظة الاتفاق» is: the moment the parent and ADAM agree, in one
concrete sentence, what *success* would mean — before money is ever mentioned.

---

## The principle that organises everything below

**Split the hard decision into two easy ones.**

A single "do I want this, and is it worth paying for?" is a hard decision made at a
weak moment (a tired parent, at night). Broken in two, it becomes:

1. **«هل هذا هو ما أريد أن يتغيّر؟»** — decided while it is still free, over a goal
   they can see. Easy: they have wanted this for months.
2. **«هل أدفع مقابل محاولة الوصول إليه؟»** — decided second, and *smaller*, because
   by now they are not weighing whether they want the outcome. They already said
   they do. They are only weighing the attempt.

> **The goal is agreed while it is free. The price is the cost of a destination
> they already chose — not a toll at a gate they are deciding whether to enter.**

Every design choice that follows serves this split.

---

## Part 1 — The funnel: three doors, one room

A parent can arrive at the agreement moment three ways. The design rule is that
**all three lead to the same room, and none of them opens onto a price.**

### Door 1 — the earned fork · the front door · ✅ exists

The evening harvest, on a night the parent reported went well, once ever
(`take_offer_moment` → `offer_fork_at` stamped):

> لاحظنا شيئاً يتكرّر مع يوسف.
> هل نتركه يتكرّر... أم نشتغل عليه حتى يتغيّر؟

This is the **highest-intent door**, and not because of the copy — because of the
**timing**. ADAM did not go looking for a sale; the question arrived at the one
moment the evidence was freshest, on the back of a calm night the parent themselves
just described. Intent that the product earned by waiting is worth more than intent
a button manufactured. Tapping «نشتغل عليه» is the parent raising their hand.

### Door 2 — the menu's open question · the side door · ✅ exists (as a surface)

The one changing item in the five-item menu, at precedence 4c
(`get_telegram_surface`, `meaning='open_question'`):

> ما الذي يمكن أن نعمل عليه؟

This is the parent coming to ADAM on their **own** time, between harvests, having
thought about it. Lower urgency, higher deliberation — a different and equally
valuable intent. It is deliberately **not** a "buy" button and carries **no price**
(the removal test, §2.1 / telegram-ux §3). It is an open question, and an open
question is an invitation to a conversation, not a checkout.

### Door 3 — the direct ask · the back door · ✅ detected

A parent who types «كيف أشترك؟» or «بقداش المرافقة الكاملة؟». `is_team_question()`
already catches this and answers with a fixed moment rather than letting the model
improvise a price. They have skipped ahead — the design must honour the intent
without skipping the agreement. So this door, too, lands in the same room: ADAM
answers warmly, then does exactly what the other two doors do — names the goal
first.

### The convergence rule

> **Whatever door you came through, ADAM's first move is never a price and never a
> pitch. It is to make sure you and it agree on what "better" means, in one sentence
> you can see.**

Three doors, one room. This is what keeps the product honest across every path a
parent can take, instead of having a clean funnel and three leaky side-entrances.

### The gatekeeper at every door: readiness

None of the three doors may open the agreement moment unless
`suggest_objective(parent)` returns `ready:true` — meaning there is a named child
and a **confirmed** situation. When it returns `ready:false`, ADAM does not
improvise a goal it cannot honestly stand behind. It says the true thing:

> ما زلت لا أعرف بيتكم بما يكفي لأسمّي هدفاً حقيقياً — أعطوني بضع أمسيات أخرى نجرّب
> فيها، وسأعرف حينها ما الذي يستحقّ أن نعمل عليه.

This is not a conversion leak. It is conversion **protection**. A goal proposed
before the evidence exists is a weak goal; a weak goal converts once and refunds,
and it teaches the parent that ADAM guesses. The «not yet» is the same honesty the
free tier runs on, and it is what makes the eventual «نعم» worth something.

---

## Part 2 — The moment itself: three beats, never one wall

The agreement is delivered as a short **sequence**, because the emotion has a shape
and a wall of text flattens it. Three beats.

### Beat 1 — the mirror · «what I see»

Not an offer. A reflection of the pattern ADAM has earned the right to name — the
Witness, not the Sentinel (§6):

> لاحظت أن أصعب لحظة معكم ومع يوسف هي **النوم** — رأيتها تتكرّر أكثر من غيرها.

The test from §6 holds: this is a thing the parent would be *proud* someone noticed,
about them, for them. It costs nothing and asks nothing. It re-establishes that ADAM
is on their side one beat before anything is proposed.

### Beat 2 — the agreement · «what would 'better' mean»

The concrete, measurable, **falsifiable** goal — and the question that hands the
parent ownership of it:

> لو عملنا عليها معاً، «الوصول» عندي ليس شعوراً نتجادل فيه — بل شيء نراه بأعيننا:
> **خمس ليالٍ هادئة من سبع**.
> هل هذا هو ما تريدون أن يتغيّر؟
>
> · نعم، هذا ما أريده
> · المشكلة الأكبر شيء آخر

Two things make this beat load-bearing:

- **The goal is falsifiable** — «خمس ليالٍ هادئة من سبع», not «نوم أفضل». A goal that
  cannot fail cannot be honestly sold, and the fairness of the whole price rests on
  the pre-committed failure (§5: «أو حتى نعرف معاً أنه لا يصلح، وأقولها لكم بصراحة»).
  The measurability is not UX polish; it is the ethics of the transaction.
- **«شيء آخر» is non-negotiable** (F9). A choice with no exit is an interrogation, not
  an agreement. And it is also the *engine of personalisation*: if they name a
  different problem, ADAM re-grounds `suggest_objective` on **that** problem and
  re-proposes. This is how a plan becomes «مخصّص» without a menu of plans — the goal
  is grounded in whichever problem the parent themselves names as the one that hurts
  most.

### Beat 3 — how we get there, and what it costs · only after «نعم»

Only now does the offer surface appear (`menu_journey`, live): the four steps, the
three guarantees the schema actually enforces (the logged-day clock, the free
half-length extension, the automatic refund), the price for their country, and the
button to the cashier.

By this beat the price is not a gate. It is the cost of a destination the parent
named as theirs one message ago. That is the entire point of agreeing the goal
while it was still free.

---

## Part 3 — How the menu phrases the door

The menu is the most-seen surface and the easiest place to quietly become a
salesman. Three rules keep it honest:

1. **The label stays an open question.** «ما الذي يمكن أن نعمل عليه؟» — never «ابدأ
   رحلتك» and never a price. Readiness changes what *tapping* does (for a ready
   parent it opens Beat 1; for a not-ready parent it opens the honest «not yet»), it
   does **not** change what the label *shouts*. A menu whose wording escalates the
   moment a parent becomes sellable is a menu that is watching them, and they feel
   it.

2. **The moment is pull, not push, through this door.** The fork (Door 1) is the one
   time ADAM raises the subject, and it is stamped once ever (`offer_fork_at`). The
   menu (Door 2) never initiates — the parent taps it. So the only *proactive* mention
   of the paid journey a parent ever gets is a single earned question on a single
   good night. Everything else waits to be opened.

3. **Strain outranks all of it, silently.** At strain level 2, `commerce_allowed`
   returns false: the agreement moment is withdrawn from every door, and the menu's
   changing item becomes «أن نخفّف الحمل قليلاً» (`meaning='lighten_load'`, precedence
   2). A parent who is drowning is never shown a goal to buy — and is never *told*
   that something was withheld. The withdrawal is invisible, which is the only decent
   way to do it.

---

## Part 4 — Failure modes a world-class version pre-empts

| The failure | What causes it | How the design forbids it |
|---|---|---|
| **Bait-and-switch** — "I tapped 'let's work on it' and got a bill" | price shown at the moment of interest | the goal is agreed, free, one beat before any price (the two-decision split) |
| **The premature goal** — a weak goal proposed before evidence | a door forced early | the readiness gate: `suggest_objective ready:false` → honest «not yet», never a guessed goal |
| **The menu turns salesman** | label escalates when a parent becomes sellable | the label is a fixed open question with no price; readiness changes the destination, not the wording |
| **The agreement that traps** | a yes/no with no third way | «المشكلة الأكبر شيء آخر» is always present, and re-grounds the goal |
| **Pushing** — the offer repeats | a derived «ready» re-fires nightly | `offer_fork_at` stamps the proactive ask once, ever; the menu door is pull-only |
| **A goal that cannot fail** | «نوم أفضل» instead of a number | the goal is falsifiable by construction (target-of-window), and failure is pre-committed to an extension then a refund |
| **Selling to the drowning** | commerce shown at strain | `commerce_allowed=false` withdraws the moment from every door, silently |

Each row is a real way this moment dies, and each is closed by a mechanism that
already exists or is named in `the-conversion-seam.md`. None of them is closed by
"remember not to do that."

---

## Part 5 — What the moment writes, and why it is reversible

The agreement is **free and reversible**. Saying «نعم، هذا ما أريده» does not take
money and does not start a clock. It writes one thing: a `stage_proposals` row,
`outcome='pending'`, with the agreed objective attached.

That row is the **receipt that the parent, not a human, agreed the goal.** When the
parent later reaches the cashier and the money is confirmed, `activate_subscription`
reads the objective from this pending proposal instead of taking it as an argument a
human types. This is the mechanism that finally makes §7 literally true: the human
confirms money and nothing else; the goal was set by the parent, in the chat, at
Beat 2.

Two properties worth stating:

- **An agreed goal that is never paid does not haunt the parent.** The pending
  proposal has a natural life — like the country-ask window, it expires quietly
  rather than turning into a follow-up («ألم تكملوا بعد؟» is exactly the Sentinel the
  product refuses to be). If the parent comes back weeks later, ADAM re-mirrors from
  current evidence rather than resurrecting a stale goal.
- **Agreeing again after a decline is allowed; being nagged is not.** A parent may
  reopen the menu door and agree later. What they never get is ADAM re-raising it on
  its own.

---

## The one-paragraph version

Three doors — an earned question on a good night, an open question in the menu, and
a direct ask — all lead to one room, and the room never opens onto a price. In it,
ADAM mirrors the pattern it earned the right to name, proposes one concrete
falsifiable goal, and hands the parent ownership of it with a real way to say "the
real problem is something else." Only after the parent agrees the destination —
while it is still free — does the price appear, as the cost of a thing they already
chose. The menu stays an open question and never a salesman; strain withdraws the
whole moment in silence; and the agreement writes a reversible receipt that lets the
human, at the end, do the one thing the constitution leaves them: confirm the money
arrived.

## How it was built (2026-08-11)

The moment is entirely in the database, so it needed no workflow edit and turned
no engine on. The tap pipeline already calls `get_moment_after_tap`, and any
callback beginning with `menu_` flows through it untouched.

| Piece | What it does |
|---|---|
| `followers.agreed_objective` / `agreed_at` | the reversible receipt — the goal the parent agreed, and when. A fact about the parent, like `offer_fork_at`. |
| `should_agree_first(parent)` | the gatekeeper: ready (`suggest_objective`), commerce not withdrawn by strain, no live journey, no still-fresh prior agreement. |
| `compose_agreement_moment(parent)` | the screen — mirror + falsifiable goal + ownership question, no price, composed at read time; falls back to the offer rather than inventing a goal. |
| `agree_objective(parent)` | records the «نعم»: writes the receipt and a pending `stage_proposals` row. Takes no money, starts no clock, idempotent, refuses at strain / in-journey / before evidence. |
| `get_moment_after_tap` | copied verbatim from `20260807270000` with two branches added: `menu_journey` → the agreement when `should_agree_first`; `menu_goal_agreed` → record, then show the offer. |

`get_conversation_moment` was **not** touched — a large, critical, live function
gets one new caller, not a rewrite. The two agreement buttons carry
`menu_goal_agreed` (menu-prefixed, so it routes with no Router edit) and `other`
(the escape hatch, already the open free space).

**The cashier's read side — BUILT 2026-08-11**
(`supabase/migrations/20260811130000_the_cashier_never_types_the_goal.sql`).
`activate_subscription`, called with no goal — exactly what a payment confirmation
passes — now reads `agreed_objective` and starts the journey from the goal the
parent agreed, then consumes the receipt. An explicitly passed goal still wins; a
payment with no goal and no receipt still records the money and returns
`journey.started=false, objective_required`, unchanged. Only the ten-argument body
changed, additively, with the signature untouched (a true replace, not an
overload). The security posture from `20260807160000` is re-affirmed in the same
file. Covered by three cases in `agreement_moment_test.sql` (38 assertions total).

The design above is drawn from the code as it stands on 2026-08-11; the build
matches it.
