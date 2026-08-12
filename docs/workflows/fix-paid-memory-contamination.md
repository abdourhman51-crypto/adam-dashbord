# Fixing what `Postgres Memory Paid` actually remembers

**Written:** 2026-08-12. A ready-to-apply node-parameter change, **not applied**.
The live workflow (`ADAM - Machine 1+2 - Reception, Gates & AI Agents`,
`42loY0bgUSwYmHFV`, `active: true`) was read via the n8n MCP `get_workflow_details`
call only — no `update_workflow` call was made against it. This is the same
"prepared, not activated" discipline `w3-journey-step-branch.md` used for W3,
applied here to a live W1 node instead of a dormant one, because the founder's
instruction for this pass was explicit: build and test everything, push nothing
until reviewed.

---

## The bug, confirmed by reading the live node

Design: `docs/adam-constitution.md`, Part 0, Conflict 2.

The `paid aget adam` node (`bca58129-47e0-4120-b4ff-c60edea0ad44`,
`@n8n/n8n-nodes-langchain.agent`) has its `text` (chatInput) parameter set to:

```
={{ ($json.family_context ? $json.family_context + '\n\n[رسالة الأهل الآن]\n' : '') + $json.message_text }}
```

This is the **exact string LangChain's Postgres-backed memory persists as the
"human" turn**, because `Postgres Memory Paid` (`memoryPostgresChat`, window 10,
keyed on `telegram_id`) is wired to the same agent's `ai_memory` input and has no
say over what counts as "what the human said" — it records whatever `text`
resolves to, which the agent node also uses as its own live input.

The result: every one of the last 10 turns the model is shown as spoken by the
parent actually opens with `[ما نعرفه عن هذا البيت — ملاحظاتنا نحن، لم يقلها
الأهل الآن]…[ما يُسمح لك أن تدّعي معرفته]…` — the system's own scaffolding,
labelled as the human's voice, replayed turn after turn. A model conditioned on
its own recent instructions arriving under the "human" role is a plausible,
independent contributor to drift over a long conversation, and it is not
something any amount of system-prompt wording can fix — the problem is which
field the workflow hands to the memory node, not what the prompt says.

`M2 - Build Paid Context` (the code node immediately upstream) already computes
`family_context` and `message_text` as **two separate fields** on the same JSON
item — nothing needs to be computed that is not already there. The bug is purely
that the agent node's `text` parameter concatenates them before either the model
or the memory node ever sees them separately.

---

## The fix — two parameter changes, one node, nothing else touched

Both changes are to `paid aget adam`'s existing `parameters` object. No new
node, no rewiring, no change to `M2 - Build Paid Context`, `Postgres Memory
Paid`'s own settings, or anything downstream.

### 1. `text` carries only what the parent actually said

```
Before: ={{ ($json.family_context ? $json.family_context + '\n\n[رسالة الأهل الآن]\n' : '') + $json.message_text }}
After:  ={{ $json.message_text }}
```

This is what gets memorized from now on: the parent's own words, nothing else.
A replayed turn from the history now reads exactly as it should —
`$json.message_text` from that turn — instead of the scaffolding.

### 2. `options.systemMessage` carries the context instead, recomputed every turn

Today `systemMessage` is a static string (the file at
`docs/prompts/adam-conversation-agent.md`). It becomes an expression that
appends the same `family_context` the model needs, every call, exactly as
before — the model loses nothing it currently has:

```
={{ `<the static prompt text, unchanged, exactly as in docs/prompts/adam-conversation-agent.md>` + ($json.family_context ? '\n\n' + $json.family_context : '') }}
```

`family_context` is **not** memorized this way, because n8n's LangChain agent
node does not persist `systemMessage` into chat memory — only the `text`
(human) and the model's own response (AI) turns are stored. This is the entire
point of the fix: the family's facts still reach the model on every single
turn, fresh, computed by `get_agent_bundle` moments earlier — they just never
get written into the record as something the parent said.

---

## Why this is the correct fix, not a workaround

- **Zero information loss.** The model sees exactly the same `family_context`
  on the turn it arrives, because `systemMessage` is evaluated fresh per
  invocation just as `text` was.
- **Zero schema change.** `Postgres Memory Paid`'s own parameters
  (`sessionIdType`, `sessionKey`, `contextWindowLength`) are untouched — it is
  still told nothing about what it stores; it simply stores a cleaner `text`
  now because the upstream node hands it a cleaner one.
- **The 10-message window becomes what it was always supposed to be**: ten real
  exchanges, not ten copies of the system's own notes interleaved with real
  replies. `notice_a_pattern`/`aim_a_seed`-level replies that build on a
  parent's own prior wording (Conversation Behavior's "gives new information"
  row) get *more* reliable with this fix, not less — the model now sees what
  the parent actually typed at each of those points, not a paraphrase of the
  product's own state.
- **No test in this repo's suite can exercise this.** It is a property of
  what n8n writes to `n8n_chat_histories`, not of any SQL function — nothing
  in `supabase/tests/` calls the agent node. Verifying it requires watching
  real stored rows after deployment (`select message from n8n_chat_histories
  where session_id = '<telegram_id>' order by id desc limit 10` and confirming
  the "human" rows no longer start with `[ما نعرفه عن هذا البيت`), the same way
  the bug itself was found.

---

## What this document is not

It is not a change. `update_workflow` was not called. The live node's `text`
and `options.systemMessage` parameters are unchanged as of this writing. If
approved, applying it is exactly the two parameter edits above, to one node, in
the one live workflow already carrying every other paid-path change — no new
workflow, no new credential, no n8n object created.
