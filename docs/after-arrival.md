# ما بعد الوصول

**Written:** 2026-08-07. The last piece of ADAM missing from its *design* rather
than its build. §6 of `what-is-missing.md` has said «غير مصمَّم» since the
beginning, and it is needed before the first journey finishes — which is 29 days
after the first sale, not 29 days from now.

---

## The problem, stated honestly

A family agreed one goal. They paid. They answered a question every night for a
month. And one evening `close_stage` returns `completed`, because five of the last
seven nights were calm.

**That is the most dangerous moment in the entire product.**

Not the hardest to build — the easiest to get wrong, because every instinct
points the wrong way:

| The instinct | Why it destroys the thing |
|---|---|
| Offer the next journey | The trust that produced this month was built on ADAM never selling. Cashing it in at the exact moment of victory tells them the month was a sales funnel with a nice interface. |
| Declare it solved and stop | Sleep is not cured, it improves. The first bad week after ADAM vanished feels like abandonment, and it is. |
| Keep asking every night | The question existed to measure a goal. The goal is met. Continuing is collecting evidence for nothing — extraction with the shape of care. |
| Say «اشتراككم ينتهي بعد ٥ أيام» | That is the old funnel talking. It reframes a month of their work as a rental agreement about to lapse. |

The design below is built to make all four impossible.

---

## The principle

**Arrival is a handover, not an ending.**

For a month ADAM held the measuring. At arrival that job is finished and it goes
back to them — but ADAM stays within reach, quietly, and comes back on its own if
the thing returns.

Two sentences follow from that, and everything else is detail:

- **ADAM takes no credit.** It did not calm the child. It asked one question a
  night and remembered the answers. The parent did the rest, in the hardest hours
  of their day, and the message says exactly that.
- **The rhythm steps down by itself.** Nobody should have to ask ADAM to stop
  asking about a problem they have solved.

---

## The shape: three moments across a week, never one message

Compressing this into a single «مبروك + اشتركوا مرّة أخرى» is the whole failure in
one bubble. It is spread out because the emotion has a shape: recognition, then
proof, then — only once the calm has held — a choice.

### Moment 1 — الوصول. The evening the objective is met.

Sent the moment `close_stage` returns `completed`. It contains **no button that
leads to money**. This is the one message in the product that sells nothing at all,
and that is precisely what makes the third moment credible.

```
🌿 وصلتم.

خمس ليالٍ هادئة من سبع، عند النوم، مع يوسف.
هذا ما اتّفقنا عليه قبل تسعة وعشرين يوماً، وهذا ما صار.

لم أفعل هذا أنا. أنا سألتكم كل مساء سؤالاً واحداً وكتبت الجواب.
أنتم من جرّب، في أصعب ساعة من يومكم، وأعاد المحاولة بعد الليالي التي لم تنجح.

الليلة لا خطوة ولا سؤال. فقط أردتُ أن تعرفوا أنّ ما تعبتم فيه ظهر.
```

Nothing is asked. No step, no question, no next thing.

### Moment 2 — القراءة الأخيرة. The morning after.

قراءة آدم gains a fifth state, `arrived`: the whole month on one page — where they
started, what they tried, what actually worked and how often, and the week the line
turned.

This is the artifact they keep. It is also, without a word of persuasion, the
strongest thing ADAM will ever produce for its own growth: it is specific, it is
about their child, and it is theirs to share if they want to. **It is not designed
to be shared.** Designing it to be shared is what would make it worthless.

### Moment 3 — ماذا الآن. After the calm has held ~3 days.

Not the same day. A choice offered inside the emotion of arrival is not a choice.

Three doors, and **the free one is named first** — which is the only reason the
paid one is believable:

```
🌿 مرّت أيام على وصولكم، وما زالت هادئة.

من هنا، الأمر لكم:

👁 نُبقي عيناً على النوم — أسألكم مرّة في الأسبوع بدل كل مساء.
   إن رجعت الليالي الصعبة، أعرف قبل أن تصير عادة. وهذا يبقى مجانياً.

🎯 أو نعمل على شيء آخر يتعبكم — الأكل، الخروج، العناد.
   نتّفق على هدف، ونمشي إليه كما فعلنا تماماً.

🌿 أو نكتفي بهذا. تعرفون أين أجدكم، وأنا لا أختفي.
```

The middle door is where the next journey is named. It is named **by the parent
choosing it**, not by ADAM raising it — and it appears at all only when
`can_propose_stage` allows: not under strain, not near a crisis flag.

---

## The relapse watch — the part nobody else can promise

This is the strongest idea in the design and the reason arrival should not end the
relationship.

For **30 days after arrival**, ADAM keeps watching quietly — weekly, not nightly.
If the calm breaks (three hard nights inside one week), ADAM comes back **on its
own, unprompted, and free**:

```
🌿 لاحظتُ أنّ الليالي رجعت صعبة هذا الأسبوع.

هذا يحدث — الهدوء لا يمشي في خط مستقيم.
والفرق أنّنا لا نبدأ من الصفر: نعرف ما نجح معكم آخر مرّة.

«تنبيه قبل النوم بعشر دقائق» نجح ٧ من ٩ ليالٍ في الشهر الماضي.
نعيده أسبوعاً ونرى؟
```

Three things make this worth more than the month that preceded it:

1. **It is unpurchasable.** It only works because the evidence already exists.
   Nobody arriving new can buy it; it is earned by having been here.
2. **It is free, and it must stay free.** Charging for the return is charging for
   the failure of the thing they already paid for.
3. **It converts better than any offer**, precisely because it is not one. A
   parent who is caught before a relapse becomes a habit does not need persuading
   that the next journey is worth it.

---

## What the product must refuse to do

Stated as prohibitions, because these are the four things a future session — or a
future me — will be tempted to add:

1. **No offer in Moment 1.** Not a button, not a footer, not a hint.
2. **No stage renews itself.** `close_stage` ends it and nothing starts another.
   A journey nobody agreed is not a journey — the same rule
   `activate_subscription` already enforces with `objective_required`.
3. **No expiry framing at arrival.** «اشتراككم ينتهي» is the legacy funnel. What
   ends is a *goal that was reached*, and the words must say that.
4. **ADAM never claims the result.** Every sentence about what changed is written
   in the parent's grammar, not ADAM's.

---

## What it needs to be built

Small, and mostly assembled from parts that exist:

| Piece | State |
|---|---|
| `close_stage` returning `completed` | ✅ built and tested |
| The arrival moment + the «ماذا الآن» moment | new rows in `conversation_moments` |
| قراءة آدم state `arrived` | one branch in `adam_reading` — the data is already gathered |
| Rhythm steps to weekly at arrival | one write to `checkin_state.cadence`, next to the one `close_stage` already does |
| The 30-day relapse watch | a view over `daily_logs` and `stages.completed_at`; no new table |
| The relapse message | one moment, and the sender W3 already is |

The only genuinely new logic is the relapse watch, and it is a `where` clause over
data the product already keeps.

**Nothing here needs a workflow switched on to be built or tested.** Every state is
reachable in the offline suite by walking a synthetic family to arrival, which
`journey_engine_test.sql` already does.
