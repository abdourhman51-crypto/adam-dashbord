# Founder review 2 — one navigation, and copy that says something

## The live failure: 29 executions, every command broken

`Tap - Answer` calls `answerCallbackQuery`. That API needs a `callback_query_id`, which exists only when a **button** was tapped. A **typed command** (`/faq`) has none, so it sent an empty string, Telegram returned

```
400 — query is too old and response timeout expired or query ID is invalid
```

and the node had no `onError`, so the whole chain died. **Every command I added yesterday reached the parent as silence.** Fixed with `onError: continueRegularOutput` — the call is meaningless for a typed command, and its failure must not be.

## Three navigations competing

| Surface | Held |
|---|---|
| Reply keyboard | ما الذي يحدث الآن · كيف نتقدّم · القائمة · ما هو آدم؟ |
| In-chat menu | 6 items, overlapping the above |
| Command menu ☰ | 8 commands, overlapping both |

`كيف نتقدّم` appeared in all three. `ما هو آدم؟` appeared in two, and duplicated `أسئلة شائعة` in the third.

**ChatGPT, Claude and WhatsApp ship none of the first two.** The input field is the product; the native menu is the navigation. That is the whole pattern.

### The reply keyboard is removed

`surface_keyboard()` now returns `[]`, and first contact sends `remove_keyboard: true` so parents who already have it get it cleared.

**`ما الذي يحدث الآن` was the worst offender.** As a label it means nothing — *what is happening now, about what?* And tapping it would only make ADAM ask what happened. **A button slower than the thing it replaces should not exist.** Typing is one step; the button was two.

### The in-chat menu is reduced to the one item that moves

Decision 009 says the menu is fixed with exactly one changing item. Everything fixed now lives in ☰, where it is native and never scrolls away. What remains is the changing item — and it moved into the **pinned message**, which is always visible, so there is no menu message to open at all.

### Commands: 8 → 7, no duplicates

```
/start البداية · /child طفلي · /progress كيف نتقدّم
/journey المرافقة الكاملة · /settings الإعدادات
/privacy الخصوصية · /faq أسئلة شائعة
```

`/menu` and `/help` dropped. `menu_help` merged into `menu_faq`, which now **opens with «ما هو آدم؟»** — the first thing a lost parent wonders is the first thing they read. Old buttons and old keyboard labels still resolve, so nobody hits a dead end mid-transition.

## Copy that said nothing

> نجمع الصورة — ليلة واحدة حتى الآن

Gathering **which** picture? Ending **when**? A parent cannot act on it. Every progress string now states what was recorded and what comes next:

| | |
|---|---|
| 0 | `لم نسجّل أي ليلة بعد — نبدأ من الليلة.` |
| 1 | `سجّلنا ليلة واحدة. نحتاج ثلاثاً حتى نعرف ما يتكرّر.` |
| 2 | `سجّلنا ليلتين. نحتاج ثلاثاً حتى نعرف ما يتكرّر.` |
| ≥3 | `هذا الأسبوع: ٤ ليالٍ هادئة من ٦ سجّلناها.` |
| ≥3, none this week | `لم نسجّل أي ليلة هذا الأسبوع.` |

`٤ من ٦ أهدأ` was also cryptic — four of six *what*, quieter *than what*. Now it says nights, and says they were recorded.

It is one function, `progress_line()`, so the sentence exists once.

The pinned footer changed from *«القائمة ☰ فيها…»* — which pointed at a menu that no longer exists — to **«اضغط ☰ بجانب الكتابة»**, which tells the parent where to look.

## What a parent now sees

- A text field, and a message inviting them to use it
- ☰ beside it with seven plainly-named entries
- A pinned line: the child, what we are working on, what was recorded, and **one** action

No keyboard bar. No menu message. Nothing that needs to be learned.
