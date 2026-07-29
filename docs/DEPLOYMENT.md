# ADAM — Deployment Checklist

Everything below is built and tested. Nothing is live. These are the steps that
put it in front of real parents, in order.

**Nothing here is destructive except step 4, which is a deactivation and is reversible.**

---

## Before anything else — two items only you can do

### 1. Rotate the exposed credentials
The Supabase `service_role` key and at least two Telegram bot tokens are in
plaintext inside workflow JSON. I proved during Week-0 what service-role reaches:
4,174 parent conversations.

- Supabase dashboard → Settings → API → roll `service_role`
- BotFather → `/revoke` for the ADAM bot and the survey bot
- Update the n8n credentials (`adam Supabase`, `Telegram account`)
- The new workflows use **credentials, not hardcoded tokens**, so they pick this up automatically

### 2. Point the dashboard at the service key
Week-0 revoked anonymous read of all parent data. Any dashboard read using the
anon key now correctly fails.

`.env.local` already provisions `SUPABASE_SERVICE_ROLE_KEY` and labels it
server-only. The dashboard is server-rendered — all its traffic logs as `| node` —
so it can use it safely. This is a one-line change in the Supabase client setup.

---

## Shipping the check-in and the Mirror

### 3. Attach the Supabase credential to five HTTP nodes

The MCP tool refuses to attach `supabaseApi` to an HTTP Request node, though n8n
supports it — the existing production workflows use exactly this pattern. Each
node is already configured with `authentication: predefinedCredentialType` and
`nodeCredentialType: supabaseApi`; it just needs the credential selected.

**`ADAM · Check-in Sender v2`** — [open](https://adam-voices-n8n.hawiyat.cloud/workflow/xcebVnU05w5Sx4JO)
- `Who Is Due Now` → credential: **adam Supabase**
- `Mark Sent` → credential: **adam Supabase**

**`ADAM · First Mirror Sender`** — [open](https://adam-voices-n8n.hawiyat.cloud/workflow/pj19WNHEqU4xDDjy)
- `Who Is Owed A Mirror` → **adam Supabase**
- `Generate Mirror` → **adam Supabase**
- `Mark Delivered` → **adam Supabase**

### 4. Verify the Telegram credential, then deactivate the old check-in

Both new workflows were auto-assigned **`Telegram account`**. There are two
Telegram credentials and I cannot tell which is the ADAM bot and which is the
survey bot (`mid3zo_bot`). **Confirm before activating** — sending a nightly
check-in from the survey bot would be confusing and hard to undo.

Then deactivate the legacy sender, or parents receive two check-ins a night:

- `Adam - Nightly Checkin` (`A2XHImAuFiPA6Yoh`) → **deactivate**

This is the workflow carrying the Egypt bug (below).

### 5. Activate, one at a time

Activate **Check-in Sender v2** first. Watch one evening. Then activate
**First Mirror Sender**.

The Mirror cannot fire until parents have logged three nights, so there is
naturally a few days between the two taking effect.

---

## What changes for parents the moment step 5 lands

**Egyptian parents stop being messaged an hour early.** The legacy workflow
hardcodes `{ DZ: 1, EG: 2, MA: 1 }` as fixed UTC offsets. Verified against
`tzdata`: Egypt's real offset is **+3** — DST was reintroduced in 2023, after that
map was written. Egypt is the largest market and the source of the only real
payment, and it has been getting the 21:00 check-in at 20:00 every night.

**Check-ins reach more than three countries.** Free support is universal, so
timezones are seeded for 30 countries rather than the payment markets alone.

**56 parents are deliberately still not messaged** — their country maps to no
timezone, so their local evening is unknown. They are listed in
`v_checkin_unschedulable`. Guessing an hour is how ADAM becomes the thing a
parent mutes.

**The Mirror fires for the first time ever.** It has never once run in
production.

---

## Deliberately not shipped yet

| Item | Why it waits |
|---|---|
| Prep messages (anticipation) | Paid feature. Zero paid parents exist to receive one |
| Flashpoint detection | `hard_moment` is already captured by six buttons; a detection layer adds nothing until there is volume |
| Sleep Journey config | No stage can start until parents are logging |
| Rewiring the 89-node router | Its existing handlers already write `daily_logs`, which is what the Mirror needs. Editing a live workflow serving parents tonight buys correctness we do not yet need |

Each of these was deferred against one test: *does it increase learning from real
parents, unblock shipping, or materially improve safety?* None did.

---

## Still open and genuinely blocking scale

**Where a crisis disclosure routes (architecture review D1).** Three code paths
now raise a flag — crisis detection, low-confidence voice transcripts, and
persistent stage failure — and all three route to a human queue that has no
owner, no SLA, and no defined action.

A pilot where you are personally reachable is a legitimate answer. It stops being
one once volume exceeds what one person can hold.
