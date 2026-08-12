# The language gate on the paid reply — wired

`gate_agent_reply(p_parent_id, p_body)` was built and tested in
`supabase/migrations/20260801250000_the_agent_speaks_under_law.sql`
(`supabase/tests/agent_gate_test.sql`) but for a long time nothing called it:
every reply `paid aget adam` produced went straight to Telegram unchecked. This
is the wire that closes that gap.

## What runs now

The paid reply path is:

```
paid aget adam  →  Gate - Agent Reply  →  FA - Send Reply1  →  Telegram
```

| Node | Role | State |
|---|---|---|
| `Gate - Agent Reply` | POSTs the reply to `gate_agent_reply`; returns `{ ok, blocked, violations, ... }` | ✅ live (published, active version `6b851201`) |
| `FA - Send Reply1` | sends the **gated** reply — withholds and substitutes `reply_withheld` copy when `blocked === true`, else sends the reply unchanged | ✅ live |

Both node bodies are mirrored beside this file: `W1-Gate-Agent-Reply.body.js`,
`W1-FA-Send-Reply1.body.js`.

The gate **fails open.** `Gate - Agent Reply` has `onError: continueRegularOutput`,
and `FA - Send Reply1` treats `blocked` as blocking only when it is strictly
`true`. If the gate call errors — including the case below, where the credential
is not yet attached — the raw reply still reaches the parent. A gate outage never
swallows a reply someone is waiting on.

## The one manual step: attach the credential

`Gate - Agent Reply` is an `httpRequest` node authenticating with
`nodeCredentialType: "supabaseApi"`. The MCP API **cannot** bind a `supabaseApi`
credential to an httpRequest node — confirmed again this session with the same
error every other credentialed node in W1 hit:

```
node type 'n8n-nodes-base.httpRequest' does not accept credential 'supabaseApi'
```

So the credential must be attached by hand, exactly as `HR - Context`, `HR - Gate`
and `Tap - Get Moment` were:

1. Open `ADAM - Machine 1+2` in the n8n UI.
2. Open the `Gate - Agent Reply` node.
3. Under **Credential for Supabase API**, choose **`adam Supabase`**
   (`EI2e62pg3bxhCSMJ`).
4. Save, and activate the workflow.

Until that is done the gate is present but **not enforcing** — it errors on each
paid reply and fails open, so nothing regresses, but no reply is actually
checked. The moment the credential is attached, the gate begins withholding
replies that break the vocabulary law.

## How to verify, once the credential is attached

- Send a real paid message and confirm the reply still arrives normally
  (`blocked === false`, raw reply passes through).
- `Gate - Agent Reply` returns `{ ok: true, blocked: ... }` in the execution,
  not a 401 / "Credentials not found".
- A row appears in `reply_gate_log` (Supabase) for the send.
- The withheld path: any reply the law rejects is replaced with
  «هذه تستحق جواباً أدقّ ممّا كنت سأقول. / احكوا لي أكثر عمّا حدث، وأنا معكم.»
  — the `reply_withheld` copy, kept in sync with `conversation_moments`.
