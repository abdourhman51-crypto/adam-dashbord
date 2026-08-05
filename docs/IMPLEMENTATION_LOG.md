# ADAM — Implementation Log

Running record of what was built, what it replaced, and what was found wrong along the way.
Newest first. Every entry names the evidence, not the intention.

---

## 2026-08-07 · One family, walked — and 34 functions that only existed in the database

The next gap after the journey engine was the one the founder's decision creates: with
ADAM stopped and nobody being messaged, the time-and-evidence machines will never
accumulate data, so no path can be *watched* working. `lifecycle_test.sql` answers that —
35 cases walking one synthetic family from stranger to finished journey in seconds, every
row written by the production function the live product would call.

**But writing it uncovered something bigger.** Three migration files —
`rhythm_write_side`, `situation_catalog_and_detection`,
`strain_detection_and_graded_return` — contained **no SQL at all**. Nine, fourteen and
twenty-six lines of comment describing objects that had been applied straight to the
database and never written down.

That is not an isolated slip. Checked properly against a full offline load:

> **34 of 88 production functions cannot be rebuilt from this repo.**

Among them `commit_situation`, `record_harvest_answer`, `set_strain_level`,
`request_erasure`, `execute_erasure`, `get_child_record` — live product logic whose only
copy is the running database. The consequences: the offline suite can never cover them, a
rebuild would produce a product missing whole layers, and the repo's claim to be the
source of truth is false for over a third of the logic.

Six of them came home today — the three files above now carry their real definitions,
pulled from production with `pg_get_functiondef` and verified by the suite that now
exercises them. The remaining 28 are on the list.

**The harness caught the product three times while it was being written**, and none of
them were assertion bugs:

| The harness assumed | The product actually does |
|---|---|
| answering a harvest is enough | the harvest is **sent** first; without `record_harvest_sent` the gate still says an evening question is owed on a day already answered |
| strain drops when a parent recovers | L2 **holds three days** before stepping to L1 — nobody is declared recovered on one calm sentence |
| the journey clock counts the nights before it | it counts days on or after `started_at`; the free-tier nights before the sale are not borrowed |

**And the STABLE snapshot trap, for the fourth time.** `set_strain_level` is volatile,
`offer_ready` is stable; called in one expression the read sees the snapshot from before
the write and reports the offer still withdrawn — indistinguishable from a real bug. It
has now cost debugging in four separate suites and is written up in each.

**Fixture:** `situation_catalog` handed back to its migration where it belongs;
`erasure_requests`, `aha_moments`, the full `checkin_state` and `parent_strain` column
sets added — each one added the moment a production writer turned out to touch it.

Fifteen suites, 453 assertions, zero failures.

---

## 2026-08-07 · The journey can be started

Founder's decision first: ADAM is stopped, nobody is being messaged, and the build is to
be finished before any launch — the paused workflows are paused deliberately, to stop
them burning credit for nothing. So the order changed from «turn something on» to
«finish the parts that do not exist», and this is the most important of them.

Until today the complete list of journey functions in production was `can_propose_stage`.
A gate, and nothing to gate. `stages` held the shape, `v_stage_progress` derived the
phase and the clock, and **nothing had ever written a row**, so none of it had ever run.

Which means the offer shipped on 2026-08-06 sold this —

> نتّفق قبل أن نبدأ على هدف واضح ترونه بأعينكم.
> وإن لم نصل إليه في المدّة، أُكمل معكم نصف المدّة كاملةً مجاناً حتى نصل.

— while the only tool that turned a payment into access granted 30 calendar days on a
clock, with no goal, no measurement, and nothing for «نصل» to refer to.

**Four functions, and one rewritten:**

| | |
|---|---|
| `suggest_objective(parent)` | the sentence فريق آدم agrees with the parent, built from the situation already confirmed. Returns `ready=false` with a reason rather than inventing a goal for a house we do not know |
| `start_stage(...)` | the journey begins, once |
| `stage_state(parent)` | the live journey, its progress, its clock and its phase, in one call |
| `close_stage(stage)` | met → completed; missed → the extension; missed again → failed |
| `activate_subscription` | unchanged signature, same payment row — now also starts the journey, and reports whether one exists |

**The extension is granted by the same call that detects the miss.** That is what lets
the offer promise it «بلا أن تطلبوا»: there is no path where a parent has to ask and no
path where an operator has to remember.

**What `start_stage` deliberately does not enforce.** `can_propose_stage` blocks on a
30-day cadence, a lifetime cap per problem, and an improving trend — rules about when
ADAM may *raise* the subject. Applying them at start would mean refusing to begin a
journey someone had already agreed and paid for. That is not a safeguard; it is a bug
that takes money. `start_stage` enforces only structural invariants.

**The objective has no default, on purpose.** A goal nobody agreed is not a goal, and a
fallback here would recreate the gap in a new place. So `activate_subscription` without
one still records the money and returns `journey.started = false, reason =
objective_required` — the half-state made loud instead of silent.

**Tested:** 36 assertions walking two families through a whole journey — one missed,
extended by 14 in the same call, missed again, failed; one that reached it and completed
*before* the clock. All fourteen suites green (396 assertions). Verified on production
with a disposable family: suggest → start → 29 hard nights → `hold`, exhausted →
`close_stage` → extended by 14, allowed_days 43, live again.

**The walk is the first piece of the simulation harness** the next step needs. With
nobody being messaged, walking a synthetic family through time is the only way any
time-and-evidence path can be seen working.

**Two fixture findings on the way.** `fixture_minimal.stages` carried four loose columns
where production has a dozen with constraints — so `telegram_surface_test` had been
creating stages production would refuse, and tightening the fixture caught it
immediately. And `situations` is still looser than production (`parent_id`, `label_ar`,
`window_start`, `window_end` are NOT NULL there). That one is recorded in the fixture and
in `docs/what-is-missing.md` §7 rather than fixed quietly at the end of an unrelated
change: it means moving ~25 raw inserts onto `commit_situation()`.

---

## 2026-08-06 · The setting that made ADAM answer blind

The handover shipped, the database returned it correctly with the link — and parents
still got the model's one-line deflection. The cause was one option on
`M2 - Get Memory Snapshot`:

    options.response.response.responseFormat = "text"

With that set, n8n does not parse the JSON body. It puts the whole thing in a **string**
under `data`. So `$json.handled` was `undefined`, the IF fell to false, and the model ran
the turn it was supposed to never see.

**And the same setting had been breaking two much bigger things, silently:**

| Reader | What it asked for | What it got |
|---|---|---|
| `M2 - Build Paid Context` | `b.context`, `b.family_context`, `b.knowledge_level` | undefined — so **every reply was written with no knowledge of the family at all**, always falling back to «لا توجد ذاكرة مسجلة بعد» at level 0 |
| `FA - Send Reply1` | `b.ask`, `b.ask_body` | undefined — the country question was never appended to a reply |

`get_agent_bundle` was built precisely so the agent would stop answering strangers, and
it has been returning the right answer to a node that could not read it. Personalisation
— the thing the offer sells — was never reaching the model. That reframes the founder's
standing complaint about reply quality: the prompt was not the only problem. The model
was working blind.

Fixed by clearing the option, and by making all four readers unwrap `data` when it is a
string, so flipping one dropdown can never again break three features without a word.

**The lesson, and it is the same one twice this week:** every layer reported success. The
function returned correct JSON. The node returned HTTP 200. The IF evaluated without
error. The reply sent. Nothing anywhere was red. Only reading an actual execution showed
it — which is why «حل كامل» has to mean *verified in a live execution*, not *applied and
green offline*.

---

## 2026-08-06 · «هل انت مجاني» is the same question

Three messages, one turn apart: «بخصوص المرافقة الكاملة» caught, «بكم الاشتراك» caught,
«هل انت مجاني» **not** caught — it carries no word about a price, a subscription or
paying, so it reached the model.

It is the same question. A parent asking whether ADAM is free is asking what they get for
nothing and what costs money.

**And the answer was the wrong shape, not only missing.** «هذا يتولّاه فريق آدم» in
response to «هل انت مجاني» is close to a refusal: they asked whether they owe anything
and ADAM declined to say. He *can* answer that half — what is free is the relationship he
is in, not a commercial term he lacks facts for. So the moment now answers first and
hands over second:

    🌿 كل ما بيننا الآن مجاني، ويبقى مجانياً.        ← he knows this
    🤝 وهناك مرافقة كاملة… يتولّاها فريق آدم وحده     ← he does not

One moment serves all three messages, and every one of them ends with the link.

`تدفع` and `فلوس` were **not** added, and that is the discipline of this list in two
words: «تدفعه للنوم بالقوة» is a parent pushing a child, and «يطلب فلوس كل يوم للمدرسة»
is pocket money. Both are now false-positive cases in the suite.

---

## 2026-08-06 · A question for فريق آدم is not a question for آدم

A parent asked «اريد ان اعرف بخصوص المرافقة الكاملة». The model answered at length, and
invented this:

> «وسيتواصلون معكم لتوضيح كل شيء قريباً»

Nobody was going to contact them. Nothing schedules that and no human was told. The
reply also carried no link — so a parent who had raised their own hand was left with a
promise that will not arrive and no way to act. That is the worst possible outcome on
the one turn that matters commercially.

**The prompt could not have fixed this.** It already forbids quoting a price, and the
model obeyed that. The failure was not vocabulary: it was a model answering a question
it has no facts for, and filling the gap the way models do. So the fix is to stop
asking it. `is_team_question()` recognises the shape and the reply becomes a fixed
moment with the فريق آدم button on it. The model never sees the turn.

**And the prompt got shorter, not longer** — the founder's constraint, and the right
one. The worked example teaching the model how to answer «كم يكلّف هذا؟» is deleted,
because that turn no longer reaches it, and the prohibition is now one sentence that
also forbids the specific thing that went wrong: «ولا تعد بأن أحداً سيتّصل». Net −127
characters.

**Precision over reach, deliberately.** The two errors are not symmetrical: a missed
phrasing costs one ordinary reply, a false positive hands a sales card to a parent
telling us their child hit their brother. So the dangerous near-misses are excluded and
sit in the test file as cases:

| Excluded | Because |
|---|---|
| `بكم` | «أهلاً بكم» — `بكام` is kept |
| `شحال` · `قداش` | «شحال من مرة قلت له» is a count — `بشحال` · `بقداش` are kept |
| `الدفع` | «الدفع بينهم صار عادة» is pushing — `طريقة الدفع` is kept |
| `رحلة` | a real journey to the grandmother's — `المرافقة الكاملة` is exact |

**Ordering matters more than it looks.** The team check runs *before*
`capture_intention`. «اشتراك» is short, carries no question mark and is one line — the
capture would have taken it and written it into that parent's intention permanently, as
who they hoped to be. There is a test for exactly that.

**The branch generalised.** `intention_captured` became `handled` / `handled_reason` /
`handled_body` / `handled_buttons`, so the bundle can answer a turn itself for more than
one reason. The nodes are now `BD - Handled?` and `BD - Send Handled`, and the sender
renders `url` buttons, so the handover carries a link rather than a wait.

**The prompt doc had drifted from the node** — example order and three diacritics,
because the node had been edited directly. A prompt doc that differs from the node is
worse than no doc: it describes rules the model never sees. The doc now mirrors the live
node byte for byte, and says so.

**Tested:** 17 assertions in `team_question_test.sql`, all thirteen suites green.
Verified live on production: «اريد ان اعرف بخصوص المرافقة الكاملة» and «بشحال؟» both
return the handover with the link and «💬 نكمل مع أحمد»; «أحمد دفع أخاه اليوم» is
untouched and still reaches the model.

---

## 2026-08-06 · One promise, one next step

The offer stacked five reassurances — logged days, an extension, a refund,
one-journey-at-a-time, and a vow of silence on an improving trend. Each was true.
Together they read as a legal notice, and a parent skims a legal notice. Founder's
call: **one guarantee**.

    نتّفق قبل أن نبدأ على هدف واضح ترونه بأعينكم.
    وإن لم نصل إليه في المدّة، أُكمل معكم نصف المدّة كاملةً مجاناً حتى نصل.

**The refund left the design with it, and that cost nothing** — because it was never
built. No function has ever written `stages.refunded_at`; the refund existed as a
sentence in a column comment saying one "follows instead". A promise that lives only
in a comment cannot be kept, so the comment is what went. `'refunded'` survives as a
status an operator may set by hand — `can_propose_stage`, `get_telegram_surface` and
the erasure view all read it. `erasure_requests.refund_due` is untouched: money back
pro-rata when a parent erases everything mid-journey is a right, not a sales
guarantee, and a different thing entirely.

**٢٩ is now the engine's number, not an advert's.** `planned_logged_days` had no
default at all, so the first stage فريق آدم started by hand would have hit a NOT NULL.
It defaults to 29, and the column comment says the offer and the column move together.

**The offer rebuilt on the value equation**, one section per term:

| Term | What carries it |
|---|---|
| Outcome | a problem *they* name stops repeating — four named, so it is concrete before they imagine it |
| Belief | the goal is agreed and observable **before** money moves; the guarantee; and «لا أعدكم بطفلٍ مثالي» — a smaller promise made honestly is believed more than a large one |
| Wait | «خلال ٢٩ يوماً». Named and finite |
| Effort | a minute or two a day, and «اليوم الذي لا تحتملونه لا يُحسب عليكم» |

That last line is the honest edge of the ٢٩: the clock counts logged days, never
calendar days. Said as a caveat it shrinks the offer; said as relief it grows it. Same
fact either way — and that is where it now sits, in the effort section, not the
guarantee.

**Personalisation is the sale**, so it got its own section with the child's name in
it, seven capabilities, one emoji each: the child row, yesterday's result feeding
today's step, the counted repeats, the single evening question, `parent_strain`
backing off, the §2.6 refusal to send anything generic, and erasure.

**The buttons finally tell the truth.** ADAM is forbidden to say a price and does not
know the terms — the agent prompt has said so since it was written. The old second
button was «🤔 عندي سؤال قبل أن أقرّر» routed to ADAM, *who by design cannot answer
it*: a dead end dressed as help, sitting on the conversion screen. Now:

    📞 أتحدّث مع فريق آدم عن يوسف   → the humans, named, and the child named
    🌿 ليس الآن — نكمل مجاناً       → new moment menu_not_now

Declining had to become a real destination. If saying no costs a parent something, the
safest move is never to open the offer at all. `menu_not_now` says the refusal was
heard, restates that nothing was lost, and returns to the conversation in one line. The
`menu_` prefix means the Router dispatches it with no code change. The same boundary is
now stated in `menu_how`, where a parent reading about the method learns where the
method stops.

**Two test findings worth keeping.**

*The escape-hatch rule was too literal.* `country_state` asserted every composed button
set contains `cb='other'`. The offer's exit is «ليس الآن — نكمل مجاناً», which is a
better exit than a generic one — it names what declining costs (nothing) — and it lands
on a moment that itself offers `other`. The check now **follows the link** rather than
matching a literal, which makes it stricter, not looser: a decline button pointing at a
dead end now fails, where before it was merely absent.

*A suite that is red for eight hours a day teaches people to ignore it.*
`rhythm_gate` guarded its harvest block with `if hr >= 10` and no upper bound, but
`get_rhythm_due` considers nobody outside `local_hour >= 7 and local_hour < 23` — ADAM
is silent at night by design. Every night from 23:00 Algiers time the suite went red for
the one reason that is not a bug. The guard now has its upper bound and the night branch
asserts the quiet window instead of skipping it.

**Tested:** 35 assertions in `offer_surface_test.sql`, all eleven suites green.
`fixture_minimal` gained `planned_logged_days` and `extension_days` — the moment copy
started promising what a column holds, the fixture had to hold it too. Applied to
production and verified there: the Moroccan offer renders with «110 دراهم مغربية، لمدّة
٢٩ يوماً», both buttons correct, and `menu_not_now` returns its own escape.

---

## 2026-08-05 · The offer sells the result, and stops underselling the product

Three faults on the one screen where a parent decides whether to pay.

**Bold that was never bold.** Nothing in this product sends with a `parse_mode`, so
every `**عنوان**` reached the parent as literal asterisks — on `/faq`, `/how`, `/why`
and the offer itself. Removed everywhere, and a CHECK constraint
(`chk_body_no_dead_markup`) now refuses the next one. Deliberately a constraint on
stored copy rather than a new `copy_violations()` rule: that function also gates what
the model writes at send time, and an LLM reaching for markdown would start costing
real sends. The bug was in copy we wrote, so the guard sits exactly there.

**The offer described the machinery.** A parent at 10pm is not buying a method; they
are buying the end of a night that keeps coming back. Rewritten around that: what the
free side already gives and that it is permanent, then the enemy named
(«ترجع الأسبوع القادم، وبعده، وبعده»), then how we get there — including the fourth
step, which is the whole differentiator: «ثم أتراجع أنا عمداً… لا أريدكم أن تحتاجوني
بعد شهر».

**And we had been underselling it.** The journey engine already implements three
promises the offer never mentioned, each one a column, not a claim:

| The line the parent reads | What enforces it |
|---|---|
| «الأيام تُحسب حين تكونون معي، لا حين يمرّ التقويم» | `v_stage_progress.logged_days` counts logged days, never calendar days |
| «أُكمل معكم نصفها كاملاً، مجاناً، وبلا أن تطلبوا» | `stages.extension_days` — the column comment says *unrequested* |
| «ولم نصل بعدها؟ يرجع مالكم» | `stages.refunded_at`; a second extension is never granted |
| «رحلة واحدة في المرّة» | `uq_one_live_stage_per_parent` |
| «وإن رأيت الأمور تتحسّن عندكم، أصمت» | `can_propose_stage` → `trend_improving` |

The last two are refusals, and they buy more trust than any claim precisely because
they cost us money. They were free to say — they were already true.

**The call to action is a button now.** `get_conversation_moment` may emit a button
carrying `url` instead of `cb`, and `Tap - Send Fixed` renders it as a Telegram link
button. The label carries the child's name when we know it — «💚 نبدأ رحلة يوسف» is a
decision about one child; a bare `t.me` address in the message body was not. Ordered
carefully: the sender shipped and was published *before* the migration, because the
reverse order would have sent a button with `callback_data: undefined` and Telegram
would have rejected the whole offer.

**The command list has its emoji.** Written by `setMyCommands` from a new one-shot
workflow (`ADAM · Bot Commands`, `Wlc3VSq3YYmZZdZj`, manual trigger, never scheduled)
because api.telegram.org is not reachable from this session's proxy. Both calls
returned `ok:true`. The word «القائمة» beside the input box is Telegram's own
localisation of "Menu" for a `commands`-type menu button — the Bot API exposes no text
field for it, so that one is not ours to move.

**Tested:** 22 new assertions in `offer_surface_test.sql`, which pins each promise to
its schema counterpart so the offer cannot quietly shrink back to the modest version.
Regressions clean across all eleven suites. Two `country_state` assertions were
rewritten: they pinned the old implementation («no buttons at all», «the body contains
the t.me address») rather than the rule, which was always *فريق آدم is the only next
step and nothing in the bot takes money*. A third was passing vacuously —
`position(a) < position(b)` is true whenever `a` is missing, so a copy rewrite had
silently turned it into a test of nothing; both needles are now asserted present first.

---

## 2026-08-05 · The answer is kept

ADAM asked the one question the whole promise hangs on — «أيّ أب أو أمّ تمنّيتم أن
تكونوا له؟» — and threw the answer away. `record_intention()` had existed, tested,
since `give_before_asking`, called from nowhere. Without that sentence stored,
«تقتربون ممّن أردتم أن تكونوا له» has no referent: the Mirror's closing line is a
promise about a thing the database does not hold.

Worse than missing: the parent typed the most personal sentence they will ever type
into this product and got an ordinary conversational reply, as if it were small talk
about bedtime.

**The ask now says how to answer.** It had no buttons by design — an intention cannot
be picked from a list — but it also never said that typing was the move. A buttonless
message with no instruction reads as an announcement, and an announcement gets no
reply. Third line added: «اكتبوها بكلماتكم الآن، سطر واحد يكفي.»

**And the answer gets an answer.** New `intention_kept`, the one moment ADAM replies
to a typed message with fixed copy. Not a receipt — a parent who has just written who
they hoped to be does not need «تم الحفظ». It says what the sentence is *for*:

    🌱 هذه الجملة تكفي، ولن أسألكم عنها ثانية.

    لن أطلب منكم أن تصيروها هذه الليلة.
    لكن في كلّ مرّة يهدأ شيء، سأريكم أنّكم اقتربتم منها خطوة.

**Most of the work is refusing to capture.** `intention_text` is written once and never
overwritten, so a wrong capture is permanent. `capture_intention()` holds every guard in
one place — not awaiting, more than 36h after the ask, under 3 characters, over 240,
starts with `/`, ends with `؟` or `?`, more than three lines — and anything it declines
writes nothing and falls through to the ordinary reply. `كيف يعني؟` is the case that
mattered: the most likely reply to a question a parent did not expect, and the one a
naive capture would have frozen into their identity forever.

**No new authenticated node.** `supabase/tests/README.md` states why the count cannot go
up. `get_agent_bundle` gained a second argument and now performs the capture on the call
`M2 - Get Memory Snapshot` was already making; two credential-free nodes — `IN - Kept?`
(IF) and `IN - Send Kept` (Telegram, token in URL like every other sender) — do the
branching. Two arities, no default: a default makes the one-argument call ambiguous and
would have broken the live node between apply and publish, so `get_agent_bundle(uuid)`
survives as a thin forward.

`M2 - Get Memory Snapshot` also gained `onError: continueRegularOutput`. It sits on every
free and paid message, and until today a failure there took the whole reply with it. Now
a failed bundle degrades to «لا توجد ذاكرة مسجلة بعد» and `intention_captured` reads
false — the parent still gets answered.

**Tested:** 29 new assertions in `intention_capture_test.sql`, offline, with a separate
parent per guard so a capture in one case cannot make the next pass for the wrong reason.
Regressions clean: conversation_law 27/27, knowledge_gate 25/25, one_send 35/35,
give_before_asking 29/29, country_state 71/71, agent_gate 27/27, agent_bundle 19/19,
composed_gate 32/32, rhythm_gate 7/7, telegram_surface 21/21. Applied to production and
verified there on a disposable parent: `كيف يعني؟` → not captured, nothing stored;
`أب هادئ، يسمع قبل ما يحكم` → captured, stored verbatim, `intention_kept` returned with
its escape button, country ask not spent; the next message → ordinary bundle, 217-character
context. W1 published.

**One stale assertion fixed on the way.** `give_before_asking` had `/progress opens with
what THEY did` pinned to `like 'هذا الأسبوع: جرّبتم%'` — a prefix that stopped being the
prefix when `no_message_assumes_you_know_adam` added the «📊 رحلتكم مع» heading. Same
class as the three `one_send` assertions fixed two days ago: the copy rewrite was right,
the test was pinned to wording instead of to what it was defending.

**And a trap in the test harness itself.** `composed_reply_gate` was missing from the
README's migration chain. Appending it at the end — where a reader naturally appends —
silently reverted four later migrations and turned 32 green assertions into 24 red ones
that looked exactly like a broken change. The chain is now complete and ordered by
timestamp, with the trap written down next to it.

---

## 2026-08-05 · A soft funnel, from the first tap to the payment link

`/faq` was a single 34-line wall. A document, not a journey: the parent either
reads all of it or none of it, and either way reaches the offer only by accident.

Now four stops, each short, each ending in a button that opens the next:

    ١. 🌿 ما هو آدم؟        the hook + the result, in three lines
    ٢. ⚙️ كيف يشتغل؟         the method, and the time it costs
    ٣. ✨ ما الذي يميّزه؟     personalisation — the whole sale
    ٤. 🎯 المرافقة والسعر    the offer and the فريق آدم link

`first_contact` had no buttons at all — the very first message a parent ever
sees was a dead end. It now opens the funnel: «🌿 ما هو آدم؟».

**Why personalisation is the sale.** The Arab parent has already tried videos,
articles and advice from every direction, and most of it did not work. Not
because it was bad — because it was about *children*, not about *their* child.
That is the sentence that sells, and it is the one thing a video or a general
assistant cannot claim: to know the name, remember what was tried, and count
what recurs.

Every ✅ claim maps to something actually built, and nothing is inflated:

| الادّعاء | ما يسنده |
|---|---|
| يعرف طفلكم بالاسم وأصعب لحظة عنده | `children` · `situations` |
| يتذكّر ما جرّبتموه وما نفع | `daily_logs.step_given` / `step_status` |
| يعدّ ما يتكرّر — «هذه ثالث مرة» | `get_harvest_prompt` |
| يسأل عن النتيجة ويتعلّم | الحصاد المسائي |

**Objection handling is placed where the objection appears**, not collected at
the end: step 2 answers "how much of my time does this cost" (دقيقة في اليوم)
before it is asked, because that is the silent objection at exactly that point.

Emojis are used as section markers, not decoration — headings, the four numbered
steps, and the ✅ feature list — so the surface scans like an app rather than a
letter.

Routing lesson applied from yesterday: every new key is `menu_`-prefixed so the
Router's generic rule dispatches it with no code change, and the routing test
added yesterday confirms all funnel buttons are live — `every_button_routes`
PASS, `menu_callbacks_have_moments` PASS.

Tests: conversation_law 27/27 + both routing assertions, one_send 35/35,
knowledge_gate 25/25, country_state 71/71, composed_gate 32/32.

---

## 2026-08-04 · Seven dead buttons, and the method the FAQ never explained

Third founder review, on a live session. He tapped «امحوا كل ما قلته» and was
answered «لم أفهم هذه تماماً». Same for «أوقفوا الرسالة اليومية». Not a copy
defect — **dead buttons**.

**The evidence, not a guess.** Searched all 262,000 characters of the workflow
JSON: `quiet_hours`, `pause`, `erase`, `resume_tomorrow`, `stay_paused`,
`review_yes`, `review_stay` appear **zero times**. The Router's dispatch ends
with `else { route = 'menu_tap'; cbdata = 'rescue'; }`, so every one of them
fell to the rescue. Seven buttons promised an action and delivered an apology.
Pre-existing — my better labels only made them more inviting to press.

**Fixed without touching the Router.** It already has a generic rule —
`else if (cbdata.indexOf('menu_') === 0) route = 'menu_tap'` — which dispatches
any `menu_`-prefixed callback verbatim as the moment key. Naming the new
callbacks accordingly makes them live with a **database change alone**, instead
of hand-editing a 7,000-character Code node, which would be the riskiest
possible way to fix a copy bug. `review_yes`/`review_stay` needed no new moments
at all: they now point at `menu_journey` and `menu_open_question`, both always
routable.

`get_moment_after_tap` becomes the one place a tap performs its action — the
pattern it already used to record the country. The action runs **before** the
moment is composed, so a confirmation can never describe something that did not
happen. Verified end to end against production with a disposable parent:

    الوقت → لا فعل · صباحاً → local_hour=8 · قبل النوم → local_hour=21
    إيقاف → cadence=stopped · إعادة → cadence=nightly
    طلب المحو → لا فعل، الوالد باقٍ · تأكيد المحو → 0 صفوف

**Erasure is two taps now.** The old copy promised «بضغطة واحدة وبلا أسئلة» — a
one-tap irreversible delete of the parent row. "No questions asked" stays true
(we never ask why), but the act is confirmed once so a misplaced thumb cannot
erase a family. After erasure the moment is composed with a null id, because
the parent row no longer exists.

**A test that would have caught it.** `conversation_law_test.sql` now asserts
that every button callback in the table is routable by the Router's actual
rules, and that every `menu_`-prefixed callback has a moment. The copy law
passed for weeks while the product was broken because nothing tested routing.

**The FAQ still described the machine.** Added «كيف نصل إلى ذلك؟» — the method
in four steps, each starting with the parent, ending at "after three times I
show you the situation that repeats in your house and what calms your child" —
plus «كم يأخذ منّي هذا؟» (a minute a day) and «هل ستصلني رسائل كثيرة؟», because
a parent does not know ADAM sends anything at all, so «إيقاف الرسائل» read as a
setting for a thing they had never been told about.

**Why the founder never saw the new commercial copy.** His own test account
carried `strain_level = 2`, set by W2's classifier during his earlier probing
(«انت خطر»). `commerce_allowed` was false, so `menu_journey` was correctly
suppressed and `/journey` fell to `menu_journey_presence` every time. Correct
product behaviour, invisible cause. Reset to 1 on his account only, and
`/journey` now renders the full offer with the price.

Tests: conversation_law 29/29 (two new), one_send 35/35, knowledge_gate 25/25,
country_state 71/71, composed_gate 32/32.

---

## 2026-08-04 · The copy stops describing the machine, and the prompt stops being a rulebook

Founder review of a live Telegram session: the replies are weak, the button copy is poor, there is no
clear line between free and paid, and nothing anywhere gives a parent a reason to want the paid thing.
All four were true. **All four were already answered in the brand bible — the product simply never
carried the answers.**

**«المجاني: أن تكون القصة أخفّ. / المرافقة: ألّا تتكرّر القصة.»** is the sharpest sentence this product
owns, decided in `adam-promise.md`, and it appeared in **zero** live strings. It is the entire answer to
"what am I paying for", understood in one second without explanation. It now opens every commercial
surface: `menu_journey`, `menu_faq`, `menu_journey_presence`.

**«شيء آخر» — nine times, meaning nothing.** `chk_escape_hatch` requires a button whose *callback* is
`other`; it says nothing about the *label*. Every escape hatch shipped with the same placeholder, so a
parent who does not know ADAM read nine dead ends. The constraint was never the cause — laziness was.
Each label is now written for its context («عندي موقف آخر» · «عندي سؤال آخر» · «صار شيء آخر» ·
«أفضّل ألّا أقول»). Zero dead-end buttons remain, verified by query.

**The command that sells could not be named.** Verified against production `copy_violations()`: the
literal string `/journey` is blocked as `internal:latin`. So the one command reaching the paid offer was
unwritable in stored copy — the FAQ literally could not tell a parent where to go, and that is a hard
conversion blocker nobody had noticed. Fixed without loosening the rule: a **button** carrying
`cta_full_companion`, which the Router already maps to `menu_journey`. No typing, no hunting, lexicon
still banned.

**The evening buttons blamed the parent.** «ما صارت الفرصة» makes an exhausted parent report in the
language of a missed obligation, and an unanswered demand from an app produces guilt — which ends
subscriptions before they start. Now «اليوم كان أثقل»: same fact, none of the blame. And «نجحت» became
«مرّ أهدأ», because `parent_effort()` exists precisely so the score is about the parent, not a verdict on
the step.

**Also corrected:** `menu_journey` said «ليالٍ أهدأ». `adam-promise.md` names night-shaped vocabulary as
the sleep-product leak that tells a morning-battle parent this is not for them — one sentence that loses
them. Now «الموقف», domain-neutral by design.

### The system prompt — a compliance document became a character

The replies were cold because of the prompt's *architecture*, not the model. ~60% of it was prohibitions;
under heavy negative constraint a model optimises for the shortest output that violates nothing.
«قاعدتك الأولى: أقلّ كلاماً» led the document, anchoring brevity above warmth. And there were almost no
worked examples — while W3's seed prompt has three and is visibly warmer for it.

Rewritten around: a success criterion first (*that the parent feels someone knows their house in
particular, and that they are not alone*), **four worked exchanges** (guilt disclosure, collapse,
recurrence, the price question), and an explicit split the founder asked for by name — **defaults that
bend for the parent** (length, opening, shape, whether to give a step at all; *"the default is two or
three lines; if their moment needs five, give five… do not cut until it goes cold"*) versus **lines never
crossed**. The commercial bans were deliberately left firm: `gate_agent_reply` *blocks* a reply that
breaks them, so loosening them buys more blocking, not more warmth. Full text and rationale now live in
`docs/prompts/adam-conversation-agent.md`, which is the source of truth; the node is pushed from it.

Every string was checked against production's own `copy_violations()` and `content_line_count()` **before**
the migration was written. Applied and published; `conversation_law` 27/27, `knowledge_gate` 25/25,
`country_state` 71/71, `one_send` 34/34 clean.

---

## 2026-08-04 · The Mirror carries the intention forward — as a flag, never a quote

`intention_text` (`give_before_asking` migration) has been write-only since it shipped: asked, stored,
read by nothing. The Mirror — the one surface built to show a parent evidence of their own change — is
where §10 item 4 always meant it to surface.

**Why a flag, not the text.** `intention_text` is free text an exhausted parent typed once, and
`record_intention()` only ever *wrote* it — it never had to be safe to *send*. Every other proactive
message in this product passes `gate_agent_reply` or `gate_composed_reply` before a parent sees it.
Piping `intention_text` into a Mirror payload that an LLM (or template) then echoes would quietly skip
that entire discipline for exactly the kind of text most likely to be personal, mistyped, or unsafe to
repeat back verbatim. So `generate_first_mirror` now emits `has_intention: boolean` only. The sentence
the Mirror should actually say is fixed, pre-approved copy that shows *approach* without quoting her —
`وتقتربون، خطوة بخطوة، ممّن أردتم أن تكونوا له.` — verified clean against production's own
`copy_violations()`. Documented here rather than wired into a render step because **W4 (First Mirror
Sender, `pj19WNHEqU4xDDjy`) is currently archived** — the payload is ready; there is no live workflow to
carry the line yet.

**Why the first Mirror, with no repetition guard needed.** `generate_first_mirror` is the only
implemented Mirror kind — `weekly`, `stage_report`, and `parent` (the "identity payoff" kind that would
be the more natural semantic home for this) are declared in the `mirrors.kind` CHECK constraint and
never built. `uq_one_first_mirror_per_child` already guarantees the first Mirror fires at most once per
child, so a fixed intention line here can never repeat to the same family without any new guard.

**This engine had zero test coverage before today** — a live, revenue/retention-adjacent function with
no assertions at all. New `supabase/tests/mirror_engine_test.sql` (10/10 passing) covers the pre-existing
behavior it had never had tested (not-due-before-3-nights, generates-once, crisis suppression) alongside
the new flag, including an explicit leak check: the parent's literal words are asserted absent from the
payload's serialized text. `supabase/tests/fixture_mirror.sql` stubs `v_child_record`/`crisis_flags` —
the real ones sit behind the journey_engine/child_record chain, which assumes columns
(`stages.started_at`, `stages.created_at`) that predate this repo's migration history and cannot be
reproduced from a blank fixture, the same constraint noted for `give_before_asking_test.sql`'s
`ar_occasions` gap.

**Also found while investigating where this consumer would even deliver:** W2 (Knowledge Writer) and W3
(Rhythm Sender) are both currently `active: false` with `activeVersionId: null` — not merely paused, no
published version exists to run. Confirmed with the founder: **deliberate**, to control cost while ADAM
is pre-launch with no real users and known copywriting/UX gaps still being found through his own manual
testing. Not a bug; left untouched. Recorded so a future session doesn't "fix" it.

---

## 2026-08-04 · The offer moment — the fork, presented once, on the harvest

`offer_ready()` (§10.5, the conversion moment) was built and tested and called from nowhere. Wired it
into the evening harvest, the way the intention ask already rides it — because §10.5 is «لحظة العرض
بعد أول نمط»: the fork appears after the parent has seen their own evidence, not on demand.

**Why it rides the harvest, and why it is stamped once.** `offer_ready` is purely derived — left
alone it returns `ready:true` every night until the parent converts, which is the push that produced
8 offers and 0 clicks. New `take_offer_moment()` claims the fork atomically via a new `offer_fork_at`
stamp (mirroring `record_country_ask` / `record_intention_ask`), so it is shown once, ever.
`get_harvest_context` now decides exactly one proactive add-on per positive harvest: the offer fork if
earned, else the intention ask if due. The offer outranks the intention and does not spend its stamp,
so the anchor is not lost when both are eligible on the same night.

**Why the buttons add no new route.** The founder chose «reuse the existing CTA → فريق آدم». Tracing
that showed the CTA LLM offer-writer chain is **dead** — its entry nodes (`CTA - Answer Callback`,
`CTA Ready - Answer Callback`) have no input and never fire. But `cta_full_companion` is a **live** tap
already in the Router's table, routed to `menu_journey` — the real journey door, built from
`supported_countries` at read time, with فريق آدم as the cashier (§7) and the price withheld under
strain. So «نشتغل عليه» carries `cta_full_companion` and «نتركه يتكرّر» carries `not_now` (the open
free space): both live callbacks, no new node, no new handoff, and the dead chain stays dead. `HR -
Send` appends the fork + buttons when `offer_present`, else the intention, else the plain reply —
built with `String.fromCharCode(10)`, not a literal `\n` (see the newline trap above).

**State.** 0 parents are offer-ready today — none yet has three attempts and two outcomes against a
confirmed situation — so nothing fires tonight, and none is double-stamped. The machinery runs
correctly on live data (returns `offer_present:false` for everyone) and will present the fork the first
night a family earns it. Tested offline: 32/32 in `composed_gate` (offer + intention + precedence +
once-ever + strain-withdrawal), `knowledge_gate` 25/25 and `conversation_law` 27/27 clean. Migration
applied to production and `HR - Send` republished.

**Still not wired: the parent's free-text answers.** The intention ask and the fork's «نتركه يتكرّر»
both leave the parent able to type a reply that nothing captures — `record_intention()` is still
called from nowhere. The fork's «نشتغل عليه» is fully live (it reuses the journey door); it is only the
*typed* answers that are unrecorded, and because both asks are stamped once regardless, the missing
capture never causes a repeat — it only means the answer is not stored.

---

## 2026-08-04 · Two live bugs in the reply path — one mine, one old

**Every normal reply was erroring (mine, same session).** Execution `5918`:
`FA - Send Reply1` failed with `ExpressionExtensionError: invalid syntax`, so from the moment
`gate_agent_reply` was wired in, the paid/free conversation path sent nothing at all. Cause: when I
set the node's `jsonBody` via `setNodeParameter`, the `\n` I wrote in the tool-call JSON was decoded
by JSON into a real linefeed — and a real linefeed sitting inside a single-quoted JS string
(`'…سأقول.⏎'`) is a syntax error n8n's expression parser rejects before it ever runs. `cat -A` on the
stored value showed the bare `$` mid-string, confirming a literal LF, not the escape I intended. The
same defect was in `HR - Send` from the intention-ask change. Fixed both by building the newline with
`String.fromCharCode(10)` instead of any literal — immune to how JSON encodes the value. Both verified
by evaluating the extracted expression under `node` (correct output, both branches) before publishing.

This is the deeper form of the `setNodeParameter` trap already in HANDOFF: not just *where* the path
points, but that **any `\n` in the value becomes a real newline in the stored expression source**. Use
`String.fromCharCode(10)`, never a bare `\n`, inside an expression string literal set this way.

**ADAM re-pinned the banner on every reply (old bug, surfaced now).** `Pin - Edit` carried
`onError: continueErrorOutput` with its **error output wired to `Pin - Create`**. `editMessageText`
returns `400 "message is not modified"` whenever the pinned surface text is unchanged — which is most
replies — so every such reply fell through the error branch to Create + Attach, i.e. a brand-new
pinned message. The banner was meant to be "created once, edited in place thereafter" (HANDOFF item 3);
the error fallback quietly turned every steady-state reply into a re-pin. Confirmed against the DB:
`pinned_message_id` was populated (11700) and the credential path worked, so the id-load hypothesis was
wrong — it was the edit-failure fallback. Fixed by removing the `Pin - Edit → Pin - Create` connection:
a failed or no-op edit now ends silently, and `Pin - Create` runs only when `Pin - Exists?` is false (a
follower with no pin yet). Trade-off accepted: if a parent deletes their pinned message, it is not
auto-recreated — far better than a fresh pin on every message, and aligned with the stated design.

Both fixes applied to the live workflow (`42loY0bgUSwYmHFV`) and published. No repo/SQL change — n8n
wiring only.

---

## 2026-08-03 · The intention question is asked, not just written

`should_ask_intention()`, `record_intention()` and `offer_ready()` (`give_before_asking` migration)
were built and tested and never called from anywhere — `docs/adam-system.md` §10 item 4. This wires
the first of the two: the intention ask, into the one live path it belongs to — the evening harvest
reply, "asked once, ever, and only after something has already worked."

**No new node, again.** `get_harvest_context(p_parent_id, p_answer)` is the one call already on the
harvest path with a working credential (`HR - Context`). New migration
`20260803180000_ask_the_intention.sql` makes it decide the ask too: on a positive answer
(`p_answer = 'ok'`) with `should_ask_intention()` true, it stamps `intention_asked_at` (new function
`record_intention_ask`, idempotent, mirrors `record_country_ask()`) and returns `ask_intention: true`
plus the fixed `intention_ask` body. `get_harvest_context` is now `volatile`, not `stable` — the stamp
is the point. `HR - Send`'s body now appends `intention_ask_body` to the composed reply when
`ask_intention` is true, exactly the `country_ask_footer` pattern.

**The stamp lands whether or not the gate later passes.** `HR - Context` runs before `HR - Compose`
and `HR - Gate`, so it cannot know if the composed reply will be accepted. If `HR - Gate` rejects it,
the flow falls to `CK - Reply Step` for a fallback message — a node shared with the unrelated CK
check-in-step feature, keyed on `callback_data` equality, not on harvest context. Extending it to also
carry the intention footer was judged out of scope for this change (real risk of breaking the CK step
flow it already serves) — so on a gate-rejected harvest night, the stamp is spent and the question is
not shown. This is the same tradeoff `record_country_ask()` already accepts and documents: "a spent
stamp with no send costs one ask." Worth revisiting if gate rejections turn out to be common on nights
the ask would otherwise fire.

**Capture is not wired.** The parent's free-text reply to `intention_ask` (no buttons, by design) is
not recognized anywhere — it will reach `paid aget adam` as an ordinary message and get an ordinary
reply, not `record_intention()`. That needs a routing decision (an `intention_asked_at is not null and
intention_text is null` check, most likely in `M2 - Classify Track`, the way `survey_mode` already
intercepts a different flow) that this change deliberately does not make. Because the ask is stamped
once, ever, regardless of capture, not wiring this does not risk asking twice — it only risks the
answer never being recorded.

Tested offline against `fixture_minimal.sql` plus the exact migration chain
`get_harvest_context`/`should_ask_intention` depend on (21/21 new assertions in
`composed_gate_test.sql`, plus the full `knowledge_gate_test.sql` and `conversation_law_test.sql`
suites re-run for regressions — clean except one pre-existing, unrelated `can_send('harvest', ...)`
failure that predates this change and touches no function this migration modifies).

`offer_ready()` — item 5, the offer moment — is still completely unwired. Not attempted here: it has
no buttons either (free-text fork, "هل نتركه يتكرّر... أم نشتغل عليه حتى يتغيّر؟"), so it inherits the
same capture question as the intention ask, and its trigger point (which rhythm event, what
`get_rhythm_due` action) has not been investigated the way the harvest path had already been mapped
for this one.

---

## 2026-08-03 · Wired `gate_agent_reply` into W1

`gate_agent_reply` (commit `35099f1`, `20260801250000_the_agent_speaks_under_law.sql`) was built and
tested but never connected — every reply `paid aget adam` produced still went straight to Telegram
unchecked. Confirmed live against workflow `42loY0bgUSwYmHFV`: no node called it, and `paid aget adam`
connected directly to `FA - Send Reply1`.

**Wired via `update_workflow`'s atomic operations** (not the SDK — this is an existing production
workflow, not a fresh build): added `Gate - Agent Reply` (`httpRequest`, typeVersion 4.4, POST
`/rest/v1/rpc/gate_agent_reply`, `authentication: predefinedCredentialType` / `nodeCredentialType:
supabaseApi`, `onError: continueRegularOutput`) between `paid aget adam` and `FA - Send Reply1`, and
rewrote `FA - Send Reply1`'s body to use the gate's `blocked` result — the fixed `reply_withheld` text
when blocked, the raw reply otherwise, with the existing country-ask-footer logic untouched. On a gate
error the raw reply still sends (fail open, not fail silent-and-broken): `gate.blocked` reads as
`undefined`, not `=== true`.

**The credential-attach trap held exactly as documented.** Setting `node.credentials.supabaseApi` on
`addNode` was rejected outright: `"node type 'n8n-nodes-base.httpRequest' does not accept credential
'supabaseApi'"`. Same limitation `HANDOFF.md` already named for `FA - Country Ask?`. Left as
`authentication: predefinedCredentialType` in `parameters` only — the credential itself needs a manual
UI attach, same as `Pin - Load` / `Pin - Surface` / `Pin - Remember` before it.

**`setNodeParameter`'s `path` is relative to the node's `parameters` object, not the node.** The first
attempt used `path: "/parameters/jsonBody"` — it returned `appliedOperations: 1` with no error, but the
node was unchanged on re-fetch. `path: "/jsonBody"` is what actually lands. Caught by re-fetching the
node after the write rather than trusting the success response, which is now the standing rule for any
`setNodeParameter` call.

Verified the two new expressions offline (normal reply passes through; blocked reply falls back to the
fixed text plus the country-ask footer when owed; a gate error or malformed response both fail open) —
`node`-run, not live, since `test_workflow` pins every `httpRequest` node and so cannot exercise the
real credential resolution. That resolution — the one open question — needs a live message after the
credential is attached.

---

## 2026-07-29 · Pre-launch cleanup
**Full report:** `docs/CLEANUP-2026-07-29.md` · **Status:** n8n 13 → 5 workflows, `public` 32 → 23 tables.

**A live workflow was sending dunning messages.** `Machine 5 (Renewal Guard)` was
**active** on a daily 10:00 schedule. Execution `5057` at 08:00 UTC today delivered a
real Telegram message (`message_id: 10827`) asking a parent for **2,300 DZD to a CCP
account** — a parent who last spoke on 29 June. Her `country` was empty, so the code
fell through to the Algerian default and quoted her an Algerian bank account
regardless of where she lives. The message also asserted *"there was a real turning
point in your journey together"* while `plan_sessions` held nothing for her: the text
is assembled from empty fields. Two more parents were queued for auto-downgrade on
31 July. Deactivated, then archived.

**The dashboard has never been buildable from this repo.** `app/` imports 14 modules
from `@/lib/*` and `@/components/*`; none exist, and `git log --diff-filter=A` shows
none were ever committed. This is missing source, not technical debt — reconstructing
it would mean inventing product. It also bounded the cleanup: with `lib/queries.ts`
unavailable, every view and every function reachable from committed code was kept.

**Deleted** — only what was proven dead against the live workflows, every function
body, and every committed file: the offer/renewal query layer
(`get_offer_candidates`, `get_live_offer_signal`, `get_followup_candidates`,
`get_renewal_actions`, `increment_waitlist_daily`), the broken counter pair, and two
zero-row tables. Full recovery DDL is embedded in the migration.

**Moved, not dropped.** Nine `*_archive_20260708` tables hold 3,694 rows of real
history. They left `public` for a new `archive` schema — PostgREST only serves
`public`, and a snapshot beside live tables is one forgotten GRANT away from
re-opening the Week-0 exposure.

**Refused to delete** three things that looked legacy and were not: `Heart Writer`
(its `write_child_name` is the only writer of `children`, and `light_memory` covers
129 parents), the legacy `Nightly Checkin` (11 opted in, 16 `daily_logs` rows this
week — stopping it before v2 activates costs real parents nothing gained), and
`writer_commit` and friends (an unattributed write on 2026-07-28 10:01 that no n8n
execution explains).

**Correction to the blueprint.** It listed `weekly_plans` and `survey_responses` as
dead. Both have live references — `write_child_name()` writes one, the live router
writes the other. The blueprint predated the dependency audit.

---

## 2026-07-29 · Integration pass — shipping over infrastructure
**Status:** Two workflows built, tested, **inactive**. Deployment steps in `docs/DEPLOYMENT.md`.

Applied the ship-first filter to my own plan and deferred three things I was about
to build. None of Flashpoint Detection, prep messages, or the Sleep Journey config
increases learning from real parents or unblocks shipping — there are zero paid
parents, and `hard_moment` is already captured by six buttons.

The honest finding: **I had been building infrastructure ahead of integration.**
Everything built so far was dark. Nothing had reached a parent.

**Constraint that shaped the design.** A Telegram bot holds one webhook, and the
live 89-node workflow owns it, so response handling must stay there. Checking what
that router already does: it *already* writes `daily_logs` on check-in responses.
So the blocker was never the router — it was that the **sender** carries the Egypt
timezone bug and the **Mirror has never run**. Both are schedule-triggered, so both
ship without touching the live conversational workflow at all.

**Built**
- `ADAM · Check-in Sender v2` (`xcebVnU05w5Sx4JO`) — hourly, all scheduling logic
  in `get_checkin_batch()`, Telegram credential instead of a hardcoded token
- `ADAM · First Mirror Sender` (`pj19WNHEqU4xDDjy`) — daily, renders the Mirror in
  Arabic-Indic numerals, her own change as one quiet closing line

**Deliberately not done:** swapping the HTTP nodes to a credential whose contents I
cannot verify. The MCP tool refuses to attach `supabaseApi` to an HTTP node even
though n8n supports it and the existing production workflows use exactly that
pattern. Forcing a different credential risked 401s against live data to save five
UI clicks.

**Requires founder action before parents see anything:** credential attach, Telegram
bot verification, deactivating the legacy check-in sender, activation.

---

## 2026-07-29 · Nightly Check-in Engine
**Commits:** `<this>` · **Status:** DB layer complete and tested. Workflow wiring pending.

The nightly log is the measurement spine (review A3) — the stage clock, the Mirror and the
child record are all derived from it.

**Production bug found and fixed.** The live workflow hardcodes `{ DZ: 1, EG: 2, MA: 1 }` as
fixed UTC offsets. Verified against `tzdata`: Egypt's real offset is **+3** (DST reintroduced
2023). Egyptian parents — the largest market and the source of the only real payment — have
been receiving the nightly check-in at **20:00 local, not 21:00**, every night. Replaced with
IANA zones so Postgres handles DST and Ramadan shifts.

**Built**
- `country_timezone` — 30 countries, not just the 3 payment markets (free support is universal, P8)
- `checkin_state` — cadence, consent decay, local hour. A separate table, because `followers`
  already carries 60+ columns
- `get_checkin_batch()` — selects only in the parent's local evening hour; excludes the 7-day
  crisis window, anyone already sent today, and anyone with no resolvable timezone
- `record_checkin_response()` — writes against her **local** date and resolves `child_id`
- `decay_checkin_consent()` — 5 ignored → weekly, 4 more → stopped. Any reply restores everything
- `ensure_checkin_state()` — enrolment on engagement
- `v_checkin_unschedulable` — 56 parents whose local evening is unknown

**Decisions**
- *Local date, never UTC.* At 21:00 in Algiers the UTC date has already rolled over; filing a
  Tuesday evening under Wednesday would silently corrupt the stage clock.
- *No bulk enrolment.* 234 parents are schedulable, 12 are enrolled. Backfilling all 234 was
  tempting and wrong: most last spoke weeks ago, and a nightly message to a dormant stranger is
  how ADAM becomes the thing she mutes. The rhythm is earned by an exchange.
- *Unknown timezone means no message.* Not a guess at UTC+3. Surfaced in a view instead.

**Tests** C1–C12: timezone correctness, batch selection, send idempotency, response logging,
`child_id` linkage, follow-up merge (no duplicate row), crisis suppression, decay to weekly,
decay to stopped, full recovery on reply, enrolment idempotency, unknown-country refusal.

**Resolves** the gap flagged in Child Record: `daily_logs.child_id` was NULL on all 21 rows,
so sibling-parents got an empty record. Now populated on every response.

---

## 2026-07-29 · `safe_for_record` operator-only invariant
**Commit:** `f1c694f`

Two of my own defects were caught by tests and corrected.

**H4 defeated the first design.** It used a transaction-scoped GUC as proof of approval; anyone
able to run SQL could `set_config` and flip the flag with **zero audit rows**. A guessable token
is a convention, not an invariant. Rebuilt so the guard requires a matching approval row written
in the same transaction — flag and justification cannot come apart.

**The column REVOKE was a silent no-op.** `has_column_privilege` returned `true` afterwards:
PostgreSQL will not let a column-level revoke subtract from a table-level grant. Revoked the
table grant, re-granted per column. The trigger covered the gap throughout, so nothing leaked —
but a defence that is claimed and does not hold invites reliance.

**A design error surfaced while fixing the first:** requiring approval for *any* change made
revocation as hard as granting. Hiding a possible disclosure must never require ceremony.
Revocation is now always permitted and always logged.

9 attack paths tested, all correct.

---

## 2026-07-29 · Child Record
**Commit:** `1d081af`

Derived at request time, never stored, so redaction always applies and no stale copy can leak.

**Governing rule, established from live data:** the record contains what ADAM **authored** and
what was **measured** — never what the parent **disclosed**. An allowlist by provenance, not a
content filter, because filtering Arabic free text cannot be done safely. The live rows that
settled it:

- `memory_events.title` = *"حادثة الاعتداء المؤلمة"* — a child assault disclosure
- `child_patterns.pattern_label` = *"التنقل بين ثلاث عائلات"* — reveals family separation

Neither is distinguishable from a safe label by pattern matching.

**Also added:** the right to erasure, absent from all four design documents. Two-step, removes
conversations via the **normalised** session key (drifted `=`/`_s1` keys would otherwise
survive), de-identifies payments rather than deleting them, and the audit row carries no FK so
it outlives the erasure.

**Defect caught by T5:** `RETURNS TABLE` column `delivered` collided with the table column of
the same name — runtime `42702`. Renamed `was_delivered`.

---

## 2026-07-29 · Journey Engine
**Commit:** `7d914c8`

`stages`, `stage_proposals`, `erasure_requests`, `crisis_flags`. All RLS-enabled and
service-role-only from birth — no repeat of the Week-0 exposure.

- The clock counts **logged days**, not calendar days, so crisis, travel, illness and Ramadan
  need no pause feature and the guarantee stays fair both ways.
- Progress is **derived**, never a stored counter — the exact failure mode that froze
  `message_count`.
- Phase is computed, so the `hold` phase that proves change was real cannot be shortened.
- `objective_met` requires a **full** measurement window: a 5-of-7 target cannot be declared met
  on 4 nights.
- `can_propose_stage()` enforces the cadence caps that stop free guidance becoming the pushing
  that produced 8 offers and 0 clicks.

9 tests, all passing.

---

## 2026-07-29 · Week-0 security and data validity
**Commits:** `d958317`, `6aab790`, `554e1f6`

**Critical exposure closed.** Executing *as the `anon` role* — whose key is public by design and
ships in client bundles — returned **4,174 parent conversations**, 290 follower records, named
children, payments and logs. 17 permissive `USING (true)` policies; three targeting the broader
`public` role. API logs showed a **mobile browser** already reading `n8n_chat_histories`
directly. `activate_subscription` was executable by `anon`: anyone could grant themselves paid
access. All revoked; `service_role` verified unaffected.

**Engagement truth layer.** `message_count` froze at 0 for signups after ~25 July while those
parents were demonstrably conversing. Two causes: a trigger pointed at `public.messages`
(0 rows) and a dropped RPC call. Replaced with a derived view. Reconciles exactly:
2080 attributed + 7 orphaned = 2087.

**Correction to my own research.** I reported "47 orphaned sessions, 25% of conversations
invisible." Wrong — a naive join. 40 were session-key format drift (`=` prefix, `_sN` suffix)
on 10–11 July. Real orphans: **7 sessions, 7 messages** — 0.3%, not 25%.

**Pricing.** The agent quoted a parent 150 EGP against a real price of 490, because its prompt
carries no price data and generated one. `get_pricing()` is now the only sanctioned source;
unknown markets return `is_supported=false` with null prices, leaving nothing to latch onto.

**Chat integrity.** One stored AI message was 169,230 chars against a p99.9 of 1,832. Ceiling
enforced at 12,000. Scaffolding contamination (25 rows) is **detected, not stripped** — regex
surgery on Arabic free text risks corrupting what a parent wrote.

---

## Outstanding

| Item | Owner | Note |
|---|---|---|
| **Restore `lib/` and `components/`** | **Founder** | Never committed. Dashboard cannot build without them |
| Rotate service-role key + Telegram bot tokens | **Founder** | Exposed in workflow JSON |
| Attach `adam Supabase` to 5 HTTP nodes | **Founder** | MCP refuses `supabaseApi` on httpRequest; n8n itself supports it |
| Verify Telegram credential, deactivate legacy sender, activate v2 | **Founder** | Two credentials, cannot tell which is the ADAM bot |
| Dashboard → service key | **Founder** | Anon reads now correctly fail |
| Crisis escalation destination (review D1) | **Founder** | Duty-of-care; gates scale past pilot |
| 56 parents with unknown timezone | Me | Needs a country prompt or inference |
| `country` empty on all 4 paid rows | Me | Caused Renewal Guard to quote Algerian pricing to everyone |
