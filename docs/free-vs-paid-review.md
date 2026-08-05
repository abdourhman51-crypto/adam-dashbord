# Free vs paid — a design review

**Written:** 2026-08-06, at the founder's request, after the `responseFormat` fix.
**Status:** review and recommendation. Nothing here is built. Founder decides the order.

Every number below was queried against production on the day of writing, not recalled.

---

## Part 1 — What is true today

```
parents                     310
marked paid_active            4
live subscriptions            0     (subscription_expires_at > now)
stages ever created           0
stage proposals ever          0
payment rows                  1
children named               71
nights ever logged            3     ← daily_logs.night_result is not null
parents with any log row     45
```

Knowledge depth across all 310 parents:

| level | parents | what it means |
|---|---|---|
| 0 | 239 | ADAM knows nothing about this house |
| 1 | 43 | knows the child's name |
| 2 | 28 | knows the name and what usually tires them |
| 3 | **0** | knows what actually repeats |
| 4 | **0** | knows the house well enough to name a goal |

`funnel_stage` is read by exactly six functions: `activate_subscription`,
`return_to_free`, `check_daily_message_cap`, `get_agent_context`,
`get_extraction_batch`, `get_heart_batch`. **None of them changes what a parent
experiences in a conversation.**

`check_daily_message_cap` returns 68 for everyone and 15 for the waitlisted — it does
not read `funnel_stage` at all — and the node that would call it (`Check daily Cap`) has
no inbound connection in W1, so no cap runs on anyone.

---

## Part 2 — Three findings

### Finding 1 — The engine has no fuel

Everything that makes ADAM different from a chatbot runs on one column:
`daily_logs.night_result`. There are **three rows in it, ever.**

The only writer is the evening harvest reply, and the harvest is sent by W3, which is
paused. So the pipe that feeds personalisation is closed at the tap.

The consequences are not cosmetic. They are the product:

| What cannot happen | Why |
|---|---|
| «هذه ثالث مرّة هذا الأسبوع» | needs counted repeats — no data to count |
| `knowledge_depth` reaching 3 or 4 | needs repeated evidence, then a month of outcomes |
| `offer_ready` firing for anyone | needs 3 attempts **and 2 calm nights** |
| a paid journey being measured at all | `objective_metric = calm_nights_in_window` reads the same column |

The offer sells «يعدّ ما يتكرّر ويريكم ما لم تروه». That capability is built, tested,
and starved. **This is the single most important fact in this document**, and it makes
the free/paid question partly a false question: today there is no difference because the
machine that would create the difference has never run.

### Finding 2 — There are two different paid products in the code

They do not agree with each other.

| | Legacy subscription | Journey engine |
|---|---|---|
| Created by | `activate_subscription(p_days => 30)` | `stages` — nothing calls it |
| Unit | 30 **calendar** days | 29 **logged** days |
| What is promised | access, for a period | one named goal, reached or extended |
| Ends | when the clock runs out | when the objective is met |
| Records | `payments`, `renewal_d5/d0_sent_at` | `objective_text/metric/target/window`, phases, `extension_days` |
| Wired | yes — the dashboard calls it | no — 0 rows ever |

**The offer I shipped on 2026-08-06 sells the right-hand column. The only tool that turns
a payment into access implements the left-hand one.** If فريق آدم confirms a payment
today, the parent becomes `paid_active` for 30 calendar days, no stage is created, no
objective is agreed, nothing measures anything, and the guarantee — «نصف المدّة مجاناً
إن لم نصل» — has no object to attach to, because there is no «نصل».

This is a delivery gap, and it is the dangerous kind: it appears *after* the money moves.

### Finding 3 — `paid_active` changes nothing a parent can feel

Same ADAM, same system prompt, same memory, same rhythm, same (absent) cap. The only
behavioural differences in the whole system are the menu row and `commerce_allowed`.

A parent who pays 110 dirhams today receives the free product, plus a Telegram
conversation with a human.

---

## Part 3 — The design

The distinction that makes all of this resolve is not "more features". It is:

> **Free is a companion. Paid is a contract.**

| | 🌿 المجاني | 🎯 المرافقة |
|---|---|---|
| Owns | **today** | **the repeat** |
| Unit of work | a message | a goal |
| Who starts | the parent | ADAM, daily |
| ADAM's job | answer this moment well | reach an agreed number, then withdraw |
| Ends | never | when reached — deliberately |
| Success looks like | the night was lighter | the situation stopped coming back |
| Measured | not at all | one number, agreed before any money moves |

Everything in the free tier stays exactly as it is. Nothing is removed to make room for
the paid tier — that is already the promise («المجاني يبقى مجانياً، بلا نقص») and it
should stay a promise, because a free tier that degrades is a free tier nobody trusts.

**What the paid tier adds is not volume. It is structure**, and structure is exactly
what the free tier cannot have: a free conversation has no goal, so it cannot be
measured, so it cannot end, so it cannot succeed. That is not a limitation to apologise
for — it is what makes the paid thing worth money.

### The four mechanisms the difference actually requires

1. **A payment creates a stage, not a subscription.** `activate_subscription` must call
   a new `start_stage(parent, problem_key, objective_text, target, window)`. Until then
   the offer is unbacked.
2. **The daily seed is the paid product.** «كل يوم خطوة واحدة مبنية على طفلكم وعلى ما
   نفع معه أمس» is a proactive daily message. That is W3. For the free tier it can stay
   optional and lighter; for a paid stage it is the deliverable itself.
3. **The evening harvest must run for both**, because it is the only writer of
   `night_result` — and without it neither tier can ever show a parent anything they did
   not already know.
4. **The conversation must know it is inside a stage.** `get_agent_bundle` already makes
   the one authenticated call per message; it should carry the stage, the phase
   (`observe → build → hold`), days remaining and progress, so ADAM speaks like someone
   working towards something rather than someone answering messages.

Mechanism 4 is where the paid personality lives. The paid ADAM is not warmer or longer —
he is **oriented**. And in `hold` he deliberately says less, because the phase exists to
prove the change belongs to the family and not to him.

---

## Part 4 — The order, by dependency

This ordering is not preference. Each step is blocked by the one above it.

| # | Step | Blocked until |
|---|---|---|
| 0 | **Turn W3 on for a small cohort** — the 28 parents at level 2, not all 310 | — |
| 1 | `start_stage()`, and `activate_subscription` calls it | — (can be built now) |
| 2 | Stage context into `get_agent_bundle` | 1 |
| 3 | `/progress` becomes the stage report for a parent in a stage | 1, and data from 0 |
| 4 | The `hold` phase — ADAM withdrawing on purpose | 2, 3 |
| 5 | «ما بعد الوصول» (§10 item 6) | 4 |

Step 0 is the founder's call, because it is the one with a cost. The recommendation is
a cohort, not a launch: the 28 parents at knowledge level 2 are the only ones for whom
the evening question is answerable at all, and they are enough to produce the first
`night_result` rows the entire product is waiting on.

---

## Part 5 — ADAM's persona

**The persona review should not be written yet, and this is the honest reason.**

Until the `responseFormat` fix landed on 2026-08-06, `M2 - Build Paid Context` read
`b.context` and `b.family_context` as `undefined` on every single message. ADAM has been
answering every parent with no knowledge of their family at all — no child's name, no
situation, nothing — while the system reported success at every layer.

So every judgement about the personality made before that fix was a judgement of a model
running blind. The founder's standing complaint that the replies were weak and generic
was correct, and at least partly caused by this rather than by the prompt.

The prompt itself is now 5,407 characters, roughly a quarter of it prohibitions, down
from ~60% before the 2026-08-04 rewrite. It carries four worked examples, a success
criterion, and an explicit split between breakable defaults and lines never crossed.
There is one structural gap that can be named without new evidence: **it contains no
instruction about being inside a stage**, because stages do not exist yet. That gap
closes with mechanism 4, not with a rewrite.

**Recommendation:** read ten real replies after the context fix has been live for a day,
then judge. Rewriting the persona now would be tuning an instrument while wearing
earplugs.
