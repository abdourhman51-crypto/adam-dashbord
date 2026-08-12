# Workflow code, mirrored here

n8n is the only home of these node bodies, and n8n has no diff. When a code node
changes, the reasoning goes in the commit message and the file goes here, so the
next person can read what the live workflow does without opening a browser and
without trusting a memory.

Mirrored, not authoritative: n8n is still where it runs. If the two disagree,
n8n wins and this file is stale — which is itself worth knowing.

| File | Node | Workflow |
|---|---|---|
| `W1-Router.js` | `Router` | `ADAM - Machine 1+2` (`42loY0bgUSwYmHFV`) |
| `W1-M2-Classify-Track.js` | `M2 - Classify Track` | `ADAM - Machine 1+2` |
| `W1-Tap-Get-Moment.body.js` | `Tap - Get Moment` (jsonBody) | `ADAM - Machine 1+2` |
| `W1-Gate-Agent-Reply.body.js` | `Gate - Agent Reply` (jsonBody) | `ADAM - Machine 1+2` |
| `W1-FA-Send-Reply1.body.js` | `FA - Send Reply1` (jsonBody) | `ADAM - Machine 1+2` |

Wiring notes (not a code node, but a change that needed reasoning):
`agent-reply-gate-wire.md` — the language gate on the paid reply, and its one
manual credential step.
