# Founder review — first `/start`, and what it exposed

The founder ran `/start` on the live bot and read the result as a first-time user would. Four problems, one of them serious.

## 1. We were promising voice that does not exist — **P11 violation**

First contact said *"الكتابة أو التسجيل الصوتي — كلاهما يصل"*. It was copied verbatim from architecture §9.1.

`Router` reads `message.text` and nothing else. A voice note arrives with **no** `text`, so `route` falls through to `normal`, reaches the agent with an empty prompt, and produces nonsense. **We advertised a capability, and its failure was silent.**

Two fixes: the promise is gone, and `Router` now detects `voice / audio / video_note / video / photo / document / sticker` and answers honestly:

> الصوت لا يصلني بعد — لكن الكتابة تصل كاملة.
> اكتبوا ما حدث ولو بكلمات قليلة.

That row carries an instruction to delete it the day transcription actually works.

## 2. "ماذا حدث؟" is unanswerable to someone who does not know what ADAM is

An open question with no frame reads as *"what happened about what?"*. It assumed orientation the parent has never been given.

```
السلام عليكم 🌿
أنا آدم — أرافق الأهل مع أطفالهم، يوماً بيوم.
ما الذي يشغلكم مع طفلكم هذه الأيام؟
```

One line of orientation, then a question that can actually be answered. Still no mechanics, still gender-free (impersonal + respectful plural, §0.7).

## 3. E10 was misapplied — my error

I wrote *"the product never explains itself"* and used it to justify having no help anywhere. The principle means **never explains itself unasked**. A help affordance the parent opts into is not self-promotion, and every product she uses daily has one.

Added `menu_help` — `❓ ما هو آدم؟` — as a **sixth fixed menu item**, and on the reply keyboard for parents ADAM does not know yet. It describes what happens *between us*, never mechanics.

**E10 is amended to:** *The product never explains itself unasked, and is never hard to ask.*

## 4. The keyboard assumed awareness, and was not derived

`surface_keyboard(state)` now grows:

| State | Keyboard |
|---|---|
| `brand_new` · `no_child_name` · `no_situation` | `💬 ما الذي يحدث الآن` · `❓ ما هو آدم؟` |
| everything else | `💬 ما الذي يحدث الآن` · `📈 كيف نتقدّم` · `☰ القائمة` |

This also closes F2 from the experience review — the keyboard was the one surface the derivation function exempted from itself.

**Routing matches by substring**, so changing an emoji can never break it.

### On emoji

The installed web design skill says *never use emoji as icons; use SVG*. **That does not transfer.** In Telegram there is no SVG layer — emoji are the icon system, used by Telegram's own UI. Menu and keyboard now carry them.

## Not done — the deepest item

The founder's last point is the **main conversation agent's prompt**: it lectures, it gathers information in a way that can feel like an interrogation, and its rigid three-part shape makes every reply feel templated.

**This is not fixed.** What was fixed is the *evening reply* composer, which now carries an explicit anti-repetition rule:

> غيّر المدخل والتركيب في كل مرة. لا تبدأ دائماً بالطريقة نفسها.

The main agent still says *"هذا المربّي في تجربة 7 أيام"* — a self-concept that contradicts the value model — and still mandates cause + step + measure on every turn. Rewriting it is the next task, and it is the largest remaining one.
