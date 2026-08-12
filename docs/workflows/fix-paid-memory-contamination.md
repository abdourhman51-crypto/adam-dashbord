# Fixing what `Postgres Memory Paid` actually remembers

**Written:** 2026-08-12. Updated 2026-08-12 with a verified, executed proof (see
Tests). Still a ready-to-apply node-parameter change, **not applied**. The live
workflow (`ADAM - Machine 1+2 - Reception, Gates & AI Agents`, `42loY0bgUSwYmHFV`,
`active: true`) was read via the n8n MCP `get_workflow_details` call only — no
`update_workflow` call was made against it, and no live node, no production
database, and no n8n process were touched at any point while producing this
document, including the proof below. This is the same "prepared, not activated"
discipline `w3-journey-step-branch.md` used for W3, applied here to a live W1
node instead of a dormant one, because the founder's instruction was explicit:
build and prove, push nothing until reviewed.

---

## 1 — Current behavior

The `paid aget adam` node (`bca58129-47e0-4120-b4ff-c60edea0ad44`,
`@n8n/n8n-nodes-langchain.agent`, confirmed by reading the live node directly)
has its `text` (chatInput) parameter set to:

```
={{ ($json.family_context ? $json.family_context + '\n\n[رسالة الأهل الآن]\n' : '') + $json.message_text }}
```

`Postgres Memory Paid` (`memoryPostgresChat`, `contextWindowLength: 10`, keyed
on `telegram_id`) is wired to this same agent's `ai_memory` input. Mechanically,
underneath n8n's node, this is LangChain's `PostgresChatMessageHistory` (schema:
`id serial, session_id, message jsonb` — identical to `n8n_chat_histories`) fed
by a `BufferWindowMemory`. The memory has no independent view of "what the human
said" — an agent executor calls `memory.saveContext({input: <one string>},
{output: <the agent's reply>})`, and the one string it is given is whatever
`text` resolved to for that call. There is exactly one input key, by
construction (`paid aget adam` exposes a single `text` parameter, nothing else
feeds the executor's input side) — this matters because LangChain's
`getInputValue()` throws if more than one key is offered without an explicit
`inputKey`; the node's own design (one text field) is what makes `text` alone,
unambiguously, the thing that gets memorized.

**So today:** every stored "human" row for a paid parent's last 10-message
window is `family_context + "\n\n[رسالة الأهل الآن]\n" + message_text` — the
system's own notes (`[ما نعرفه عن هذا البيت…][ما يُسمح لك أن تدّعي معرفته…]`),
not the parent's raw words. On the next turn, `BufferWindowMemory` replays
those stored rows back into the prompt as chat history — labelled `Human:` —
so the model is shown, turn after turn, its own scaffolding as if the parent
had said it. `docs/adam-constitution.md` names this Conflict 2.

`M2 - Build Paid Context` (the code node immediately upstream) already computes
`family_context` and `message_text` as **two separate fields** on the same JSON
item — nothing new needs to be computed. The bug is that the agent node's `text`
parameter concatenates them before either the model or the memory node ever
sees them apart.

**Downstream of the agent, checked directly:** nothing reads the agent node's
`text` input back out. `Gate - Agent Reply` and the Telegram-send node both read
only `.json.output` (the agent's reply). Changing what `text` resolves to has
no consumer anywhere else in the workflow — the only thing that changes is what
gets memorized.

---

## 2 — Proposed behavior

Two parameter edits to `paid aget adam`, nothing else:

**`text`** — carries only what the parent actually typed:
```
Before: ={{ ($json.family_context ? $json.family_context + '\n\n[رسالة الأهل الآن]\n' : '') + $json.message_text }}
After:  ={{ $json.message_text }}
```

**`options.systemMessage`** — becomes an expression carrying the static prompt
plus that turn's `family_context`, recomputed every call exactly as `text` used
to be:
```
={{ `<the static prompt text, unchanged, exactly as in docs/prompts/adam-conversation-agent.md>` + ($json.family_context ? '\n\n' + $json.family_context : '') }}
```

`family_context` still reaches the model on every single turn — n8n evaluates
node-parameter expressions per item, so this is recomputed fresh each call, the
same as `text` is today. It is simply never memorized, because n8n's LangChain
agent node does not route `systemMessage` through `saveContext` — it is part of
the prompt template construction, structurally outside the `{input, output}`
pair the memory ever sees.

**What is stored after the fix:** the parent's own words, verbatim, as the
"human" row; the model's reply as the "AI" row. Nothing else changes —
`Postgres Memory Paid`'s own parameters (`sessionIdType`, `sessionKey`,
`contextWindowLength`) are untouched, `M2 - Build Paid Context` is untouched,
the static prompt file is untouched.

---

## 3 — Tests

No SQL test can exercise this — it is a property of what n8n's LangChain agent
node persists, not of any Postgres function, so nothing in `supabase/tests/`
touches it. Instead of leaving that as an assumption, it was verified by
**running the actual upstream library n8n's node wraps** —
`@langchain/community`'s `PostgresChatMessageHistory` (same table shape as
`n8n_chat_histories`: `id serial, session_id, message jsonb`) and `langchain`'s
`BufferWindowMemory` — against a disposable, throwaway local Postgres instance.
No n8n process, no production database, no live workflow, no LLM call (the
"model" step is a stub that only records what final prompt it was handed).
Torn down immediately after. Source, quoted directly from the installed
package:

```js
// node_modules/langchain/dist/memory/chat_memory.js — BaseChatMemory.saveContext
async saveContext(inputValues, outputValues) {
  await this.chatHistory.addUserMessage(getInputValue(inputValues, this.inputKey));
  await this.chatHistory.addAIChatMessage(getOutputValue(outputValues, this.outputKey));
}

// node_modules/@langchain/community/dist/stores/message/postgres.js — addMessage
async addMessage(message) {
  await this.ensureTable();
  const { data, type } = mapChatMessagesToStoredMessages([message])[0];
  const query = `INSERT INTO ${this.tableName} (session_id, message) VALUES ($1, $2)`;
  await this.pool.query(query, [this.sessionId, { ...data, type }]);
}
```

Two simulated sessions were run through three consecutive turns each — a first
message, a follow-up that adds the child's name, and a recurrence — once
reproducing **today's** `text` expression, once reproducing the **proposed**
one, with `family_context` deliberately changing turn to turn (as the real
`get_agent_bundle()` output does while `knowledge_depth` grows).

**13/13 checks passed.** Actual stored rows, read back from the throwaway
database after the run:

Current (today's expression):
```
id | type  | content_preview
 1 | human | [ما نعرفه عن هذا البيت — ملاحظاتنا نحن، لم يقلها الأهل الآن]…
 2 | ai    | ردّ تجريبي ابني م…
 3 | human | [ما نعرفه عن هذا البيت — ملاحظاتنا نحن، لم يقلها الأهل الآن]…
 4 | ai    | ردّ تجريبي اسمه ي…
 5 | human | [ما نعرفه عن هذا البيت — ملاحظاتنا نحن، لم يقلها الأهل الآن]…
 6 | ai    | ردّ تجريبي رجع نف…
```

Proposed (fix applied):
```
id | type  | content_preview
 1 | human | ابني ما ينامش الليل
 2 | ai    | ردّ تجريبي ابني م…
 3 | human | اسمه يوسف
 4 | ai    | ردّ تجريبي اسمه ي…
 5 | human | رجع نفس الشي رفض ينام
 6 | ai    | ردّ تجريبي رجع نف…
```

### Test cases and what they prove

| # | Case | What it proves | Result |
|---|---|---|---|
| 1 | Ordinary parent message, no `family_context` yet (a brand-new stranger) | Nothing crashes, nothing garbled is stored, the row is exactly the raw message | PASS |
| 2 | Parent message + `family_context` present | Under the current expression the stored row is the scaffolding, not the message; under the proposed one it is the message alone | PASS (both sides) |
| 3 | Three consecutive messages in one session | Each is stored as its own clean row; row count matches message count exactly (3 human + 3 AI) | PASS |
| 4 | Memory recall in a later message (turn 3 needs to "remember" the child's name given in turn 2) | Turn 3's reconstructed prompt contains turn 2's raw text (`اسمه يوسف`) via chat history — real recall through the actual conversation, not through invented memory | PASS |

**Answering the four questions directly, each backed by a check above:**

**Q1 — How does memory work today, exactly, and what is stored?**
`Postgres Memory Paid` persists exactly the string the agent node's `text`
parameter resolves to, per turn, as the "human" message — today that string is
`family_context + "\n\n[رسالة الأهل الآن]\n" + message_text`. Proven by check
"CURRENT: every stored human row begins with the system scaffolding" (PASS) and
the raw row dump above (id 1/3/5).

**Q2 — After the fix, what is stored and what remains available to ADAM at
reply time?** Stored: the parent's raw message only (raw row dump, proposed
side). Available at reply time: the exact same `family_context` as today,
because it is recomputed into `systemMessage` on every call — proven by the
three "Q4 PROVEN: turn N's prompt still carries that turn's own fresh
family_context" checks (all PASS), one per turn, each checking that turn's
*specific* (turn-appropriate) context string, not a stale one.

**Q3 — Prove `family_context` can never later appear as if the parent wrote
it.** Two direct checks: "no stored human row contains the family-context
marker, ever" (PASS, all 3 rows) and "stored human rows equal the raw parent
messages, verbatim, nothing prepended" (PASS, exact string equality against the
three input messages). A third check confirms the *replay* path specifically —
turn 3's reconstructed prompt, which includes the full replayed chat history,
contains the family-context marker **exactly once**: the one instance from
turn 3's own live `systemMessage`, zero from history (PASS). Under the current
expression, the same measurement finds the marker **three or more times** in
turn 3's prompt — turn 1's and turn 2's memorized scaffolding plus the current
one (PASS on the current-behavior side, which is the problem being fixed).

**Q4 — Prove ADAM loses no necessary context from separating `text` and
`systemMessage`.** Beyond the per-turn freshness checks above: turn 3's
reconstructed prompt was checked to still contain turn 1's and turn 2's actual
raw parent messages, and the prior AI replies, via the replayed chat history
(PASS) — the real conversation is not lost, only the contamination is removed.
Nothing downstream of the agent node reads its `text` parameter either (checked
directly against the live workflow's connections — `Gate - Agent Reply` and the
Telegram send step both read only `.json.output`), so there is no second
consumer that would break from this change.

**What this does not prove:** that n8n's own `@n8n/n8n-nodes-langchain.agent`
node assembles its final `ChatPromptTemplate` from `systemMessage` +
`chat_history` + `text` in exactly this shape internally — that is standard
LangChain `AgentExecutor` construction and the node's documented `options`
contract, not something inspectable without the node's own source, which was
not available locally. The data-flow question this document exists to answer —
which field the memory persists, and whether `systemMessage` is one of the
fields it can persist — is proven directly, against the actual library classes
`memoryPostgresChat`/the agent node are built on. The residual gap (confirming
n8n's own wiring matches this exactly) is closed the same way the bug itself
was found: reading real stored rows after deployment. Left as the one open
item in Risks below, not glossed over.

---

## 4 — Risks

- **Residual verification gap.** The proof above exercises the LangChain
  primitives directly, not the n8n node wrapper itself (no n8n runtime was
  available to test against, and testing against the live one would mean
  touching production, which this pass was explicitly told not to do). Low
  risk — `memoryPostgresChat`'s own parameters (`sessionIdType`, `sessionKey`,
  `contextWindowLength`) are unchanged, so its behavior is unchanged; the only
  variable is what `text` resolves to, which is a plain node-parameter
  expression change, the same kind of change already made safely elsewhere in
  this workflow. Still, the first real deployment should be followed by
  reading actual rows (`select message from n8n_chat_histories where
  session_id = '<a real telegram_id>' order by id desc limit 10`) to confirm
  the live behavior matches this proof, exactly as the bug itself was
  originally found by reading rows, not by inspecting parameters alone.
- **In-flight conversations at the moment of deployment.** A parent mid-window
  when this ships will have older rows in the old (contaminated) shape and
  newer rows in the new (clean) shape, both inside the same 10-message buffer
  for a while. Not a regression — those old rows carry the same contamination
  they always did — but worth knowing so a spot-check right after deploy isn't
  misread as a partial fix.
- **Any future change to the static prompt file must also touch the
  `systemMessage` expression**, not just the file — today a prompt edit means
  copying the file's text into the node's static string; after this fix it
  means the same copy, just into an expression's literal-string portion
  instead. Same manual step as today, not a new one, but worth naming so it
  is not assumed to become automatic.
- **No risk of information loss** was found — Q4's checks are symmetric
  per-turn and per-history, and the mechanism (expressions re-evaluated per
  item) is standard, documented n8n behavior, not a special case being relied
  on speculatively.

---

## 5 — Recommendation

**Apply.** The current behavior is a genuine, previously-undocumented defect
(Conflict 2) with a plausible mechanical role in long-conversation drift, and
the fix is two parameter edits to one already-live node with a verified,
zero-information-loss data flow and no other consumer of the changed field.
The one residual gap (confirming n8n's own internal prompt assembly matches
the proven LangChain mechanics) is a one-query check to run immediately after
deployment, not a reason to withhold it.

**Still not applied.** `update_workflow` was not called against
`42loY0bgUSwYmHFV`. Applying it, if approved, is exactly the two parameter
edits in §2, to the one node, with the post-deploy row check in Risks as the
immediate next step after.
