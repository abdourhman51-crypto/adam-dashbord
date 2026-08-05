# The one wire left: free-text country capture

The «بلد آخر» tree the founder drew is built. Everything below the buttons runs
in the database and is tested (`supabase/tests/country_other_test.sql`, 22
assertions) and deployed. What follows is the **single** thing that still needs a
hand in n8n, and exactly why it could not be done from here.

## What is already wired, end to end

| Step | Where it runs | State |
|---|---|---|
| Tap a supported country | `set_country_XX` → Router → `country_recorded` | ✅ live |
| Tap «بلد آخر» (any unknown code) | Router → `get_moment_after_tap` → `country_other` moment: says *why*, offers سجّلوني / ليس الآن | ✅ live |
| Tap سجّلوني | `get_moment_after_tap('menu_waitlist_join')` → `menu_waitlist_ask_country`, and it **stamps `country_asked_at`** to open the 36-hour window | ✅ live |
| Type a country | `capture_country_text(parent, text)` — matches an alias anywhere in the sentence, records it, joins the waitlist, spends the window | ✅ built, tested, deployed — **not yet called from a message** |

The gap is the last row's final clause. `capture_country_text` exists and works
in production; nothing calls it when a parent **types** their answer, because a
typed message is an ordinary message, not a tap.

## Why this needs a hand, and the tap branches did not

The tap branches ride the existing tap pipeline: a callback arrives,
`get_moment_after_tap` is already called with a credential that is already
attached. Zero new nodes.

A typed country answer arrives on the **message** path, where there is no
existing node that calls a function for us. Calling `capture_country_text`
therefore needs one `httpRequest` node — and an httpRequest node needs a
Supabase credential the MCP API cannot bind. That bind is the 30-second manual
step in the n8n UI, the same one every other credentialed node in W1 needed.

Everything that could be done without that bind is done. `M2 - Get Follower Full`
now fetches `country_asked_at` (deployed, active version `58cae67c`), so the data
the capture needs is already on the message path.

## The wire — three small changes in `ADAM - Machine 1+2`

**1. `M2 - Classify Track`** — one branch, at the top of the classifier, before
the existing track logic. `f` is the follower row, `r` is `$('Router').first().json`:

```js
// A country answer we are waiting for outranks every other track. The window
// was opened by get_moment_after_tap when they tapped سجّلوني.
const awaitingCountry = f.country_asked_at
  && (Date.now() - new Date(f.country_asked_at).getTime()) < 36 * 3600 * 1000;
if (awaitingCountry && r.route === 'normal') {
  track = 'country_answer';
}
```

**2. A new httpRequest node — `Capture Country`** (this is the one that needs the
credential attached by hand):

- method `POST`
- url `https://aajqbmjasnbwwyvgrlzy.supabase.co/rest/v1/rpc/capture_country_text`
- authentication `predefinedCredentialType`, `nodeCredentialType` `supabaseApi`
  — **attach the `adam Supabase` credential in the UI** (MCP cannot)
- body:
  ```
  ={{ JSON.stringify({ p_parent_id: $('M2 - Classify Track').first().json.id,
                       p_text: $('M2 - Classify Track').first().json.message_text }) }}
  ```
- `onError: continueRegularOutput` — a capture failure must never swallow a reply

Then a **Send** node reading the result: if `captured` is true and `joined` is
true, send `menu_waitlist_joined`; if `reason` is `already_supported`, send
`country_recorded`; if `unrecognised`, send `country_not_recognised` (which asks
once more, leaving the window open). All three moment bodies already exist.

**3. `M2 - Track Switch`** — add a rule `country_answer` routing to the new
`Capture Country` node.

## How to know it works

After the credential is attached and the workflow published, from Telegram:
tap any country menu → «بلد آخر» → سجّلوني → type «انا من تونس». The reply should
be the «سجّلناكم» confirmation, and:

```sql
select country, waitlist, waitlist_at
from public.followers where platform_user_id = '<your telegram id>';
-- country = 'TN', waitlist = true, waitlist_at set
select * from public.v_waitlist_demand;   -- TN now shows one waiting
```

If the credential cannot bind (the repeat of the earlier `FA - Country Ask?`
issue), `onError: continueRegularOutput` means the parent still gets a reply —
nothing regresses, and this stays a visible follow-up rather than a silent
outage.
