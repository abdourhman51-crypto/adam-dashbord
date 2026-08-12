# The W3 branch that sends the daily plan

**Written:** 2026-08-11. A ready-to-apply wire, not applied. `ADAM · W3 Rhythm
Sender` (`Vb4ADCkPsevPRWRN`) stays `active: false` — the founder's standing rule.
Nothing here has been run, tested against Telegram, or activated.

Everything the database side needs is already built and deployed:
`compose_journey_step`, and `get_rhythm_due` routing a live-journey parent's
morning give to `action = 'journey_step'` instead of `'seed'` (§ `the-conversion-seam.md` step 5, HANDOFF 2026-08-11). What follows is the **one thing left** —
the four nodes W3 needs to actually compose and send that step — specified to the
same precision as `country-capture-remaining-wire.md`, so applying it is
transcription, not design.

---

## What W3 looks like today, exactly

```
Every Hour → Who Is Due Now (get_rhythm_due)
           → One Parent At A Time (loop)
                ├─ (done)      → Round Complete
                └─ (per item)  → Seed Or Harvest (switch on action)
                                    ├─ action=seed    → Compose Seed → Send Seed
                                    │                                    → Record Seed Sent → (loop back)
                                    └─ action=harvest → Harvest Prompt → Send Harvest
                                                                            → Record Harvest Sent → (loop back)
```

`Seed Or Harvest` is an n8n **Switch** node with exactly two rules
(`action equals seed`, `action equals harvest`) and no configured fallback
output. **Today, a row with `action = 'journey_step'` matches neither rule and
is silently dropped** — the switch has no third output to catch it. That is the
entire reason nothing sends yet; the database has been ready since the routing
migration deployed.

---

## The four new nodes, and nothing else touched

```
Seed Or Harvest ──(⭐ new 3rd rule: action=journey_step)──▶ Compose Journey Step
                                                                    │
                                            (fan-out from Seed Model, no new AI credential)
                                                                    ▼
                                                            Send Journey Step
                                                                    ▼
                                                       Record Journey Step Sent
                                                                    ▼
                                                       (loop back to One Parent At A Time,
                                                        same as Record Seed Sent does)
```

No existing node's parameters change except `Seed Or Harvest` (one rule added)
and `Seed Model` (one more fan-out connection). `Compose Seed`, `Send Seed`,
`Record Seed Sent`, `Harvest Prompt`, `Send Harvest`, `Record Harvest Sent` are
untouched.

### 1 · `Seed Or Harvest` — add a third rule

Switch node, `rules.values`, append:

```json
{
  "conditions": {
    "options": { "caseSensitive": true, "leftValue": "", "typeValidation": "loose", "version": 1 },
    "conditions": [
      { "leftValue": "={{ $json.action }}", "operator": { "type": "string", "operation": "equals" }, "rightValue": "journey_step" }
    ],
    "combinator": "and"
  }
}
```

Wire the switch's new (third) output to the new `Compose Journey Step` node.
`setNodeParameter` on `rules` replaces the whole array — supply the existing two
rules plus this one, not this one alone (the known "cannot append" trap).

### 2 · `Compose Journey Step` — new LangChain agent node

Same node type as `Compose Seed`
(`@n8n/n8n-nodes-langchain.agent`, `typeVersion: 3.1`), same `promptType: define`,
`text`: `={{ JSON.stringify($json.grounding) }}` — `compose_journey_step`'s output
is already exactly the shape a composer needs: facts **and** the phase's posture
in `phase_directive`, computed in SQL so the model does not have to infer what
"نراقب / نبني / نُمسك" means.

**System message** (mirrors `Compose Seed`'s prohibitions; the phase logic is
delegated to `phase_directive` rather than re-derived here, so this prompt is
shorter and cannot disagree with the database about what phase means):

```
أنت آدم. تكتب رسالة الصباح لعائلة داخل رحلة مدفوعة — خطوة واحدة صغيرة، أو لا
خطوة، حسب طور الرحلة.

يصلك JSON فيه ما تعرفه عن هذه العائلة، وحقل phase_directive الذي يخبرك بالضبط
ما الذي يجب أن تفعله الرسالة الليلة. اتّبعه بدقة — هو من يقرّر الطور، لا أنت.

=== القاعدة الأولى ===
لا تخترع سياقاً خارج الـJSON. لا تذكر رقماً، موعداً، أو تفصيلاً لم يرد فيه.
إن كان phase_directive يقول لا تقترح خطوة، فلا تقترح خطوة — لا حتى ملطّفة.

=== الشكل ===
سطران أو ثلاثة. لا تختم بسؤال — الحصاد يسأل مساءً.
لا تكرّر أياً من العبارات في recent_steps.
لا تبدأ بـ«تجربة صغيرة اليوم مع» ولا تنهِ بـ«مساءً نتكلم عنها» — هاتان الصيغتان
مستهلكتان بالفعل من رسائل الصباح المجانية.

=== لغة محايدة إلزامية ===
لا تخاطب الوالد بصيغة مذكّر أو مؤنث. استعمل صيغة الجمع: «جرّبوا»، «طفلكم».
ممنوع: «جرّبي» أو «جرّب» أو «أخبريني» أو «أخبرني».

=== ممنوع منعاً باتاً ===
كلمات: ذاكرة، تقرير، خطة، ذكاء، نظام، تحليل، متابعة، اشتراك، سعر، يوم، أيام
(الإشارة للعدّاد — الرحلة لا تُذكر كساعة تُعدّ).
أي جملة عن نفسك («أتذكّر»، «لاحظتُ أنني»).
أي نصيحة عامة تصلح لطفل آخر — استعمل child_name وsituation مباشرة أو احذف الجملة.

اكتب نص الرسالة فقط. بلا مقدمات وبلا علامات تنسيق.
```

**AI model input:** fan `Seed Model`'s existing `ai_languageModel` output to this
node too (`Seed Model` → `[Compose Seed, Compose Journey Step]`). **No new AI
credential is created or bound** — this is the node that already carries a
working OpenRouter credential invisibly (the same "pre-existing nodes hold their
credential server-side" fact HANDOFF documents for Supabase applies here), so
reusing its output avoids the whole class of credential-binding problem for the
model call.

### 3 · `Send Journey Step` — new httpRequest node, cloned from `Send Seed`

**No Supabase credential involved — Telegram's node carries the bot token
directly in the URL, not through an n8n credential**, so this node needs no
manual credential step at all:

- method `POST`
- url `https://api.telegram.org/bot8840311808:AAHAUo1NILY7mbn9CiHZApFYU1fXflC4NYg/sendMessage`
  (the same literal URL `Send Seed` already uses)
- `sendHeaders`: `Content-Type: application/json`
- `onError: continueRegularOutput` (matches `Send Seed` — a delivery failure must
  not crash the loop)
- body, identical pattern to `Send Seed`, reading from `Compose Journey Step`
  instead of `Compose Seed`:

```js
={{ (() => {
  const p = $('One Parent At A Time').item.json;
  const NL = String.fromCharCode(10);
  let text = String($json.output || '').trim();
  if (p.footer_ar) { text = text + NL + NL + p.footer_ar; }
  return JSON.stringify({ chat_id: p.platform_user_id, text: text, disable_web_page_preview: true });
})() }}
```

`p.footer_ar` still applies unchanged — a journey parent can in principle still
owe the exit footer (§`the-conversion-seam.md`: `get_rhythm_due`'s `owes_exit` is
about the parent, not the action), so this must not be special-cased away.

### 4 · `Record Journey Step Sent` — new httpRequest node, reuses `record_seed_sent`

**No new SQL function.** `record_seed_sent` already does exactly what is needed —
stamp `daily_logs.seed_sent_at`/`seed_text`/`seed_grounded_on`, upsert on
`(follower_id, log_date)`, and settle the exit-footer debt — and reusing it is
what makes the evening `Harvest` fire for a journey parent with zero change to
`get_rhythm_due`'s harvest branch (it only checks `seed_sent_at is not null`, not
which action produced it).

**One real constraint to respect:** `record_seed_sent` raises `seed_not_grounded`
if `p_grounded_on` is not a **non-empty JSON array** — it is not the same shape
as `compose_journey_step`'s `grounding` object, so the array must be built in
this node's expression, not passed through raw. It also drives the A1/A2
Aha-moment bookkeeping by checking whether the array contains the literal strings
`'child_name'` / `'prior_outcome'` — reuse those exact labels so a journey
parent's Aha moments still count correctly instead of silently going uncounted.

- method `POST`
- url `https://aajqbmjasnbwwyvgrlzy.supabase.co/rest/v1/rpc/record_seed_sent`
- authentication `predefinedCredentialType`, `nodeCredentialType` `supabaseApi`
  — **attach the `adam Supabase` credential in the UI** (MCP cannot; the same
  trap as every other credentialed node in W1/W3)
- body:

```js
={{ (() => {
  const p = $('One Parent At A Time').item.json;
  const g = p.grounding || {};
  const basis = [];
  if (g.child_name) basis.push('child_name');
  if (g.situation)  basis.push('situation');
  if (g.last_night && g.last_night.result) basis.push('prior_outcome');
  return JSON.stringify({
    p_parent_id: p.parent_id,
    p_local_date: p.local_date,
    p_seed_text: $('Compose Journey Step').item.json.output,
    p_grounded_on: basis,
    p_situation_id: p.situation_id,
    p_child_id: p.child_id
  });
})() }}
```

`basis` is never empty in practice: `get_rhythm_due` only routes to
`journey_step` when `compose_journey_step(...).can_send` is true, which itself
requires a live stage — and a stage cannot start without a confirmed situation
and (via `agree_objective`/`start_stage`) a child. If that invariant were ever
violated, `record_seed_sent` refuses loudly (`seed_not_grounded`) rather than
silently recording an ungrounded send — the same honesty the free Seed already
has, inherited for free.

Connect `Record Journey Step Sent`'s output back to `One Parent At A Time`,
exactly as `Record Seed Sent` and `Record Harvest Sent` already do — this is
what advances the loop to the next parent.

---

## What is deliberately unchanged

- **`get_rhythm_due` and `compose_journey_step`** — already deployed, already
  correct. This wire only consumes what they already produce.
- **The evening Harvest** — a journey parent gets the ordinary `Harvest Prompt` →
  `Send Harvest` → `Record Harvest Sent` path, unmodified. It fires because
  `Record Journey Step Sent` stamps `seed_sent_at` the same way `Record Seed
  Sent` does, and the harvest branch's only precondition is that stamp.
- **The exit footer, strain, pause, quiet hours, cadence** — all already enforced
  inside `get_rhythm_due` before a `journey_step` row is even returned. This wire
  adds no new gate because none is needed; the row only exists when it is safe.
- **W3's `active` flag** — stays `false`. This document changes nothing about
  when W3 runs; it only says what to add to the four idle nodes so that, on the
  day the founder turns it on, a journey parent is composed to instead of
  silently dropped by the switch.

## How to know it works, once applied and the credential attached

From Telegram, on a synthetic or real parent inside a live stage with at least
one outcome logged (`compose_journey_step(...).can_send = true`), manually
executing `Who Is Due Now` → the loop should reach `Compose Journey Step` for
that parent instead of falling through the switch. After a manual test run:

```sql
select seed_text, seed_grounded_on, seed_sent_at
from public.daily_logs
where follower_id = '<parent id>' and log_date = current_date;
-- seed_text = the journey-step message; seed_grounded_on carries the basis array
```

and confirm the harvest fires that same evening as it always has.
