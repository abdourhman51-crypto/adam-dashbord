# The Telegram command menu

Registered with `setMyCommands`. The native ☰ beside the input — the affordance every Telegram user already knows — was empty until now.

| Command | Label | Goes to |
|---|---|---|
| `/start` | البداية | first contact |
| `/menu` | القائمة | the in-chat menu |
| `/child` | ما نعرفه عن طفلي | `menu_child` |
| `/progress` | كيف نتقدّم | `menu_progress` |
| `/journey` | المرافقة الكاملة | `menu_journey` — pricing |
| `/settings` | إعدادات الرسائل | `menu_settings` |
| `/privacy` | الخصوصية وحذف البيانات | `menu_privacy` |
| `/faq` | أسئلة شائعة | `menu_faq` — last, as asked |

**Every command maps to a moment that already exists**, so the native menu and the in-chat menu cannot drift apart. Adding a command without a moment is impossible without noticing.

---

## The price question, and how it was resolved

The founder asked for an item explaining full companionship, with a local price per country. §3.7 says ADAM never speaks a price.

**Both are right, because they govern different things.** §3.7 governs ADAM's *voice* — the conversation. D7 makes the **Menu** the door and فريق آدم the cashier, and the entire point is that a parent can find the price without ever being pitched.

But `chk_body_clean` — my own constraint — forbade any price in any stored body, which is stricter than the constitution.

**Resolution: the table still stores no price.** `menu_journey` is `tier = 'composed'` with `body_ar` null. `get_conversation_moment()` builds the text at read time from `supported_countries`, the one sanctioned pricing source.

Consequences worth stating:

- The removal test still passes on everything stored.
- A price still changes in exactly one place — the table, not a prompt and not a node. This is the direct fix for W1 review finding **E**, where `CTA - Build Offer Prompt` carried a hardcoded `PRICES` map.
- `requires_commerce = true`, so a parent at strain L2 or L3, or within 14 days of a crisis flag, gets presence instead of a price. **The strain gate covers the Menu too, not just the conversation.**

### Supported country

Free is affirmed *first*, the journey is described as an outcome, failure is pre-committed, the price appears once, and the handoff is the last line.

```
المرافقة اليومية التي بيننا الآن تبقى كما هي — مجاناً، دائماً.

وحين يظهر هدف واضح لطفلكم — ليالٍ أهدأ، أو صباح بلا معركة —
يمكن أن نبني له رحلة: نمشي إليه يوماً بيوم حتى نصل،
أو حتى نعرف أنه لا يصلح، وأقولها لكم بصراحة.

الرحلة الواحدة: ‹السعر المحلي›.

التفاصيل وطرق الدفع — فريق آدم يسعده مساعدتكم:
https://t.me/Abdouleg
```

No urgency, no scarcity, no comparison, no "starting from". One sentence of what it is, one number, one door.

### Unsupported country

The honest reason, not a brush-off:

```
آدم يرافقكم بالكامل، كما يرافق الجميع.
كل ما بيننا الآن يبقى كما هو، دون نقص.

والرحلات المدفوعة لم تصل بلدكم بعد، لسبب واحد:
لا تتوفّر بعد طريقة دفع محلية نثق بها ونستطيع دعمها كما ينبغي.
وحين تتوفّر، تصلكم رسالة.

[أخبروني حين يصل]  [شيء آخر]
```

**The waitlist promise is now real.** `Tap - Record Waitlist` sets `followers.waitlist`. Telling a parent "we will write to you" and recording nothing is the kind of small lie that makes everything else suspect. The acknowledgement also says **«ولا شيء قبلها»** — joining a waitlist is not permission to market.

---

## A constraint was relaxed, deliberately

`chk_line_budget` capped everything at three lines. That rule exists because **ADAM's replies** must be short — an exhausted parent cannot read an essay she did not ask for.

A reference page she deliberately opened is a different object. A new category `reference` says so, rather than smuggling help text into `review`. The three-line cap still binds every unprompted message.
