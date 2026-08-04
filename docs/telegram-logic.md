# The Telegram Logic — the one specification

**Status:** authoritative. Where this document and any other disagree, this wins.
**Supersedes:** `telegram-ux.md`, `telegram-command-menu.md`, `founder-review-2-navigation.md`
(kept as history; they describe decisions, this describes the system).

---

## 0. Why this document exists

Every fix since 2026-07-30 repaired a symptom the founder could see, and each
repair desynchronised something no one was looking at. The founder's words for
it — *"من تناقض لتناقض"* — are accurate, and the cause is not carelessness. It
is that **the Telegram experience had four descriptions and no definition**:
three documents and 128 workflow nodes, of which only the nodes reach a parent.

A single live example, true at the moment of writing:

- the in-chat menu (`/menu`) contains **one** item;
- the native command menu (☰) contains **eight**;
- the pinned message reads *"اضغط ☰ بجانب الكتابة لكل ما يمكن أن نفعله معاً"*.

A menu whose only purpose is to point at another menu. No patch fixes that,
because it is not a bug — it is the absence of a decision about what navigation
*is*. This document makes those decisions once, exhaustively, so that a
contradiction is visible on the page before it is visible on a phone.

**The completeness rule: every cell in §5 must be filled. An empty cell is the
next bug, already located.**

---

## 1. The four laws

**L1 — One obvious action, always the same one.**
At every moment, in every state, the single thing a parent is invited to do is
*write what happened*. Nothing else is ever demanded. Everything else is
discoverable and optional. A parent who only ever types free text must reach
the full value of the product; no feature may be gated behind knowing a command.

**L2 — Inline buttons are answers, never navigation.**
A button may only appear inside a message that asked a question, and may only
answer *that* question. Navigation lives in ☰ and nowhere else. This kills the
reply keyboard, the in-chat menu, and every "back to menu" affordance.
*Consequence:* a button that survives after its message scrolls away is a bug.

**L3 — The pinned message states, it never instructs.**
It answers "where are we?" — child, focus, progress. Instructions are said once,
at first contact, in the conversation. A permanent instruction is a permanent
admission that the product is not obvious (E-principle: *if the parent has to
ask "how does ADAM work?", the design failed*).

**L4 — Suppression is silent.**
Strain, pause, dormancy and unsupported-country all *remove* things. None of
them may announce that something was removed, relabel a control, or explain
itself. A parent must never learn she is being handled. (Enforced in SQL by
`surface_changing_item()`; this document extends it to every surface.)

---

## 2. The surfaces — exactly three

| # | Surface | Owns | Refreshed |
|---|---|---|---|
| **S1** | The conversation | everything ADAM says | on every turn |
| **S2** | The pinned message | *where are we* — child · focus · progress | after any turn that can change state |
| **S3** | The ☰ command menu | *what else can we do* | on first contact, and when the command set changes |

There is no S4. Specifically **removed**:

- the reply keyboard (removed 2026-07-31; legacy text labels still routed, §3 E3b),
- the in-chat menu (`/menu`, `Menu - Get Parent → Menu - Get Surface → Menu - Send`)
  — **to be deleted**, it is the menu-that-opens-a-menu,
- the `changing` menu item — with the in-chat menu gone it has no host; its
  content moves into the conversation, where a suggestion belongs (§6.9).

### S2 — the pinned message, defined

Three lines maximum. Line 3 of the current implementation
(`اضغط ☰ بجانب الكتابة…`) is **deleted** — it violates L3.

```
📌  ‹الطفل› · ‹التركيز›
‹سطر التقدّم›
```

Before a name exists, line 1 is `📌  ما سجّلناه معاً`.
`‹التركيز›` is omitted when there is no situation and no journey.

**Refresh obligation.** Today only three paths refresh the pin
(`CK - Reply Step`, `CK - Reply General`, `HR - Send`). Every path that can
change state must — see §7 R4.

### S3 — the command set, final

Seven. `/menu` and `/help` are removed (`/help` is folded into `/faq`; Telegram
clients that auto-offer `/help` will hit the same moment).

| Command | Label | Moment |
|---|---|---|
| `/start` | البداية | §6.1 / §6.2 |
| `/child` | ما نعرفه عن طفلي | `menu_child` |
| `/progress` | كيف نتقدّم | `menu_progress` |
| `/journey` | المرافقة الكاملة | `menu_journey` |
| `/settings` | إعدادات الرسائل | `menu_settings` |
| `/privacy` | الخصوصية وحذف البيانات | `menu_privacy` |
| `/faq` | أسئلة شائعة | `menu_faq` |

Every command resolves to a row in `conversation_moments`. Adding a command
without a moment is impossible without noticing — that is the anti-drift
mechanism, and it is the reason the list is short.

---

## 3. The entry points — exhaustive

Everything a parent can physically do in a Telegram chat. If an update matches
no row, it is E9.

| ID | Entry | Detection (`Router`) |
|---|---|---|
| **E1** | First `/start` ever | `cmd === '/start'` ∧ no `followers` row |
| **E2** | Repeat `/start` | `cmd === '/start'` ∧ row exists |
| **E3a** | Free text | `message.text`, not a command |
| **E3b** | Legacy keyboard label | `message.text` matching a removed button label |
| **E4** | Voice / audio / video note | `message.voice ∨ audio ∨ video_note` ∧ no text |
| **E5** | Photo / document / sticker / video | those fields ∧ no text |
| **E6** | A ☰ command | `COMMANDS[cmd]` |
| **E7** | Inline button tap | `callback_query` |
| **E8** | Reply to a scheduled message | E3a or E7 with an open `daily_logs` row |
| **E9** | Anything else | fell through every branch |

**E9 is the important row.** Today an unmatched update falls to `route='normal'`
and reaches the agent with an empty prompt. Under this spec E9 sends the rescue
(§6.10) — never silence. *Silence is the one output that is always wrong.*

---

## 4. States and modifiers

**States** — derived, never stored (`get_telegram_surface`, one of exactly seven):

| State | Means |
|---|---|
| `brand_new` | no child row and ≤1 message |
| `no_child_name` | talking, child unnamed |
| `no_situation` | named, no recurring moment identified |
| `gathering` | situation known, fewer than 3 nights recorded |
| `rhythm` | ≥3 nights, no journey |
| `journey_active` | a paid stage is running |
| `journey_ended_no_next` | a stage finished, none since |

**Modifiers** — orthogonal, may combine:

`paused` · `dormant` (21d silent) · `strain_level` 1/2/3 · `commerce_allowed` ·
`country_state`

`country_state` is one of **`supported` · `unsupported` · `unknown`** — never a
boolean. It was a boolean, and that is why one parent in five (59 of 301) was
told the offer had not reached their country, about a country nobody knew.
`country_supported` still ships, derived from it, so no consumer breaks
silently; it is true only for `supported`.

Modifier precedence, highest first: **strain 3 → strain 2 → paused → dormant →
commerce → country**. The first that applies decides; the rest are inert. This
ordering exists so two modifiers can never produce two messages.

---

## 5. The complete table — entry × state

`→` = what the parent receives. Everything is one message unless stated.

### 5.1 State-independent entries

These behave identically in all seven states. That is a design decision, not an
oversight: a parent who opens `/privacy` gets privacy, never a state lecture.

| Entry | Result |
|---|---|
| **E3b** | Rewritten to the E6 equivalent, then E6. |
| **E4** | `voice_unsupported` (§6.6). Never silence, never a fake transcript. |
| **E5** | `media_unsupported` (§6.7) — **new moment, does not exist yet.** |
| **E6** `/child` | `menu_child` — composed from what is known; if nothing, §6.8. |
| **E6** `/progress` | `menu_progress` — composed from `progress_line`. |
| **E6** `/journey` | `menu_journey`, which branches three ways on `country_state`: **supported** → the price of *their* country, no buttons, فريق آدم as the only next step. **unsupported** → the one true reason (no local payment method) + waitlist. **unknown** → «من أي بلد أنتم؟» with الجزائر · مصر · المغرب · بلد آخر. |
| **E6** `set_country_*` | `record_country()`, then `country_recorded` — which answers the journey question in the same breath, so naming the country never costs the parent a second tap. `set_country_OTHER` → `country_other`, and we do **not** ask which country: it decides payment only, and payment is unavailable either way. |
| **E6** `/settings` | `menu_settings`, or `menu_resume` when `paused`. |
| **E6** `/privacy` | `menu_privacy`. |
| **E6** `/faq` | `menu_faq`. |
| **E7** `waitlist_join` | record in `followers.waitlist`, then `waitlist_joined`. |
| **E9** | `rescue` (§6.10). |

**Modifier override, applied before the above:** at `strain_level = 3`, every
entry except `/privacy` and `/settings` returns `strain_l3` (§6.11). A parent in
crisis is not shown a price, a progress chart, or an FAQ. `/privacy` and
`/settings` survive because they are exits, and an exit is never withheld (P1).

### 5.2 `/start` — E1 and E2

| Entry | State | Result |
|---|---|---|
| **E1** | (always `brand_new`) | ① `setMyCommands` ② `first_contact` (§6.1) ③ create + pin S2 |
| **E2** | `brand_new` | same as E1 — she has not begun; repeating is not re-onboarding |
| **E2** | any other state | `welcome_back` (§6.2) + refresh S2. **Never `first_contact`.** |

**This is a current defect.** `Get Surface → Get First Contact → Send First Contact`
has no branch: a parent three weeks in who taps `/start` is greeted as a
stranger. Fix in §7 R2.

**And the pin is never created at first contact** — `Send First Contact` does
not chain to `Pin - Load`. The one moment the pin most needs to exist is the
only moment it does not. Fix in §7 R4.

### 5.3 E3a — free text, the main path

Free text always reaches the conversation agent. State does not gate it; state
*informs* it. What changes per state is the single fact the agent is told to
pursue — never as an interrogation, always as the natural next thing a companion
would want to know.

| State | What the reply must move toward | Never |
|---|---|---|
| `brand_new` | let her say the thing she came to say | asking anything before she has spoken |
| `no_child_name` | the child's name, once, in passing | a form; asking twice in one conversation |
| `no_situation` | *when* it happens (bedtime, meals, leaving) | naming a diagnosis |
| `gathering` | tonight's outcome | implying she is behind |
| `rhythm` | the next small step | a new topic while one is open |
| `journey_active` | today's step in the journey | anything about buying |
| `journey_ended_no_next` | whether the result held | re-selling on the same breath |

Modifier effects on E3a:

- `strain_level = 2` → the reply carries no step and no question (`strain_l2`
  tone), and `commerce_allowed` is already false.
- `strain_level = 3` → `strain_l3` replaces the reply entirely.
- `paused` → unchanged. Pausing silences *scheduled* messages; it never makes
  ADAM ignore her.
- `dormant` → unchanged. No "we missed you". A companion does not bill absence.
- `commerce_allowed = false` → the agent is not told why, and has no vocabulary
  for it (L4).

**The reply must pass `gate_composed_reply` before it is sent.** It currently
does not — see §7 R5. This is the largest remaining hole in the system: half the
outgoing gate is built and unwired.

### 5.4 E7 — inline taps, by origin

Buttons only exist inside four messages (L2):

| Origin message | Buttons | Result |
|---|---|---|
| `harvest_ask` | هدأت · صعبة · لم أجرّب · شيء آخر | record `night_result`, reply §6.12 |
| `menu_waitlist` | أخبروني حين يصل · شيء آخر | record waitlist / return to conversation |
| `menu_settings` | يومياً · أقل · أوقِف | write `checkin_state`, confirm in one line |
| `menu_faq` | شيء آخر | return to conversation |

Any `callback_data` not in this set → E9.

**«شيء آخر» is the escape hatch required by `chk_escape_hatch`** and appears on
every buttoned message except `harvest_ask`, where it is one of the four.
Tapping it produces §6.9 — an invitation, not a menu.

---

## 6. The texts

Verbatim. No paraphrase in implementation.

### 6.1 `first_contact` — E1

Three lines. One instruction, said once, and never repeated (L3).

```
السلام عليكم 🌿
أنا آدم — أرافق الأهل مع أطفالهم، يوماً بيوم.
احكِ لي ما حدث اليوم مع طفلك، بكلماتك.
```

Nothing to tap. Nothing to choose. The first action is the only action, and it
is the one she already knows how to do: type.

### 6.2 `welcome_back` — E2, **new moment**

```
أنا هنا.
احكِ لي ما حدث.
```

Two lines. No summary of what was missed, no progress report — the pin already
carries that, and repeating it makes returning feel audited.

### 6.6 `voice_unsupported` — E4 *(exists)*

```
الصوت لا يصلني بعد — لكن الكتابة تصل كاملة.
اكتبوا ما حدث ولو بسطر.
```

### 6.7 `media_unsupported` — E5, **new moment**

```
لا أستطيع رؤية الصور بعد.
لكن صِفي لي ما فيها بكلماتك، وسأفهم.
```

### 6.8 `menu_child` when nothing is known — **new fallback**

```
لم نتعرّف على طفلك بعد.
قولي لي اسمه، وما الذي يصعب معه عادةً.
```

### 6.9 `menu_open_question` — «شيء آخر» *(exists, retargeted)*

Now the host of what used to be the `changing` menu item.

```
احكِ لي ما يشغلك الآن.
```

One line. An open door, not a list.

### 6.10 `rescue` — E9 *(exists)*

Composed, uniqueness waived, never blocked. The only message that may be
generic, because it fires when nothing else could be determined.

### 6.11 `strain_l3` *(exists)*

```
أنا هنا.
هذا الحِمل أثقل من أن يُحمل وحده.
أنا هنا. ولا شيء مطلوب منك الآن.
```

No buttons (`buttons_forbidden = true`, enforced by `chk_crisis_has_no_buttons`).

### 6.12 harvest replies *(exist — to be composed)*

`harvest_reply_ok` / `harvest_reply_failed` / `harvest_reply_skip` are the fixed
fallbacks. The composed version via `get_harvest_context` + `gate_composed_reply`
is the intended path — Peak-End says this is the most-remembered message in the
product, and it is currently three fixed strings.

---

## 7. What changes in W1

Ordered by what a parent feels first.

| # | Change | Why |
|---|---|---|
| **R1** | Delete route `menu`; delete `Menu - Get Parent`, `Menu - Get Surface`, `Menu - Send`; drop `/menu` from `COMMANDS` and from `setMyCommands` | S3 is the only navigation (L2) |
| **R2** | Branch `Get Surface` on `state`: `brand_new` → `first_contact`, else → `welcome_back` | §5.2 defect |
| **R3** | Add `media_unsupported`, `welcome_back`, `menu_child` empty-fallback moments | E5, E2, §6.8 gaps |
| **R4** | Chain `Pin - Load` after `Send First Contact`, `FA - Send Reply1`, `Tap - Send Fixed`, `Tap - Send Derived` | S2 refresh obligation |
| **R5** | Route `FA - Send Reply1` through `gate_composed_reply`; on failure send the state's fixed fallback | §5.3 — half the gate is unwired |
| **R6** | Remove line 3 from the pin body in `get_telegram_surface` | L3 |
| **R7** | Drop the `changing` item and the `menu` key from `get_telegram_surface` | no host after R1 |
| **R8** | `Router`: unmatched update → `route='rescue'`, not `'normal'` | E9 — never silence |
| **R9** | Delete the 6 `ob_*` routes, `country`, and `cta_*` from `Route Switch` and archive their 24 disabled nodes | dead routes that still catch callbacks |
| **R10** | Pass `knowledge_depth` into the agent prompt | §5.3 per-state pursuit |

R1–R4 are what the founder sees. R5 is what makes ADAM stop sounding templated.
R9 is why old buttons still resolve to behaviour no one designed.

---

## 7b. The reason the commands are silent — found while doing R1–R9

Twelve nodes are configured with `authentication: predefinedCredentialType`
and `nodeCredentialType: supabaseApi`, and **no credential instance selected**.
Every request they make is unauthenticated.

Those twelve are the entire `/start`, ☰-command and pinned-message spine:

| Node | Breaks |
|---|---|
| `Get Parent Row`, `Get Surface`, `Get First Contact` | `/start` — greeting and state branch |
| `Tap - Get Parent`, `Tap - Get Moment` | all seven ☰ commands |
| `Tap - Record Waitlist`, `Get Presence Moment` | waitlist, commerce-blocked journey |
| `Pin - Load`, `Pin - Surface`, `Pin - Remember` | the pinned message |
| `HR - Context`, `HR - Gate` | the evening harvest reply |

The other 29 Supabase calls work because they carry the service-role key as
two hardcoded headers — which is why the conversation itself has been fine
while every command was silent. **Two independent causes, and the callback
fix on 2026-08-01 addressed only one.** Saying the commands were fixed was
premature; this is the other half.

`setNodeCredential` is refused by the MCP layer for `supabaseApi` on an
`httpRequest` node — n8n itself allows it, the API surface does not. The
alternatives are both worse than asking: copying the key into 24 more
plaintext header fields, or attaching a credential whose contents cannot be
inspected and hoping. Guessing here would produce exactly the failure this
document exists to end — a change reported as done that was never verified.

**Founder action, ~2 minutes:** open each of the twelve nodes and pick
*adam Supabase* in the credential dropdown. Nothing else about them changes.

### The R5 correction

§7 R5 said to route the conversational reply through `gate_composed_reply`.
Having read what that gate does, that is wrong and would make the founder's
complaint worse, not better.

The gate applies three checks. Vocabulary belongs on every outgoing message.
The other two do not belong on free conversation: the three-line budget would
truncate a genuine answer to a hard evening, and the uniqueness rule — every
message must contain a measured family token — would force the child's name
into every turn. That is a machine for producing the templated, rigid voice
the founder identified as the deepest problem.

**Revised:** conversation is gated on vocabulary only. The full three-check
gate stays where it was designed to go — the proactive composed messages
(`seed`, the harvest reply), where being generic is the actual risk.

---

## 8. How this gets verified

The failure mode of the last three days was reporting success from a tool
acknowledgement. `setNodeSettings` returned `{ok}` and the node never received
the property; execution 5566 proved it hours later.

**Rule: no change is reported as working until a live execution shows it.**

I cannot trigger W1 myself — the Telegram trigger is not executable via MCP, and
the webhook rejects requests without `X-Telegram-Bot-Api-Secret-Token`. So:

1. Every change is verified **structurally** first — re-read the workflow JSON
   after writing and confirm the property is actually present, not merely
   accepted.
2. Every SQL change is verified against the **local Postgres fixture** before it
   touches production.
3. **One founder test round at the end**, against the checklist in §9 — one, not
   one per patch.
4. Executions are read after that round, and anything red is fixed before
   anything is called done.

---

## 9. The founder's test round

In order. Each line states what must happen; anything else is a defect.

1. `/start` → three lines, no buttons, no keyboard, pinned message appears.
2. Type `مرحبا` → a reply that is not a template and asks nothing yet.
3. Type a real sentence about the child → the reply mentions something only true
   of this family.
4. `/start` again → *"أنا هنا. احكِ لي ما حدث."* — **not** the greeting.
5. Send a voice note → the honest voice line.
6. Send a photo → the honest media line.
7. ☰ → exactly seven commands, no `/menu`.
8. `/child`, `/progress`, `/journey`, `/settings`, `/privacy`, `/faq` → each
   replies, none silent.
9. `/journey` from an unsupported country → the reason + waitlist button;
   tapping it records and acknowledges.
10. Nothing anywhere says "نجمع الصورة"، "نخفّف الحمل"، or any label that
    describes ADAM's own machinery.

---

## Appendix — n8n findings paid for in production

**`httpRequest` + `supabaseApi` must be `typeVersion` 4.4.**
A node added at 4.2 with an empty `credentials` field returns
`Credentials not found` at runtime. It saves cleanly, publishes cleanly, and
fails only when a real parent triggers it. Every working Supabase node in W1 is
4.4; `FA - Country Ask?` was added at 4.2 and was the only one that failed.
`sendHeaders` is *not* the variable — `Pin - Load` has it false and succeeds.

The corollary to the earlier finding, which stands: at 4.4 an **empty**
`credentials` field is fine, because n8n resolves against the single credential
of that type. Missing credentials in the JSON are not evidence of a broken node.
Only a live trace is.

**A draft is invisible.** `update_workflow` saves a draft; `publish_workflow` is
what makes it run. Verify `versionId == activeVersionId` *and* read
`activeVersion.nodes` — reading the draft proves nothing. This has cost a full
day once already.

**Every new node on a send path needs `onError: continueRegularOutput`.**
`FA - Country Ask?` failed on live traffic and فاطمة still received her reply,
because the failure could only ever subtract the footer, never the message. That
was designed in, and it is the only reason a bad node was a non-event.
