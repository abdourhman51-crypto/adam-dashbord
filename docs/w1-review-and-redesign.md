# W1 — architecture review and redesign plan

**Workflow:** `42loY0bgUSwYmHFV` — *ADAM · Machine 1+2 · Reception, Gates & AI Agents*. 89 nodes, **active**.
**Reviewed against:** `docs/adam-architecture.md` v4 and the UX / Conversation / Knowledge layers.

---

## 1. Verdict

W1 is the gateway every parent enters through, and it is **the pre-redesign gateway intact**. The single touch point with the new architecture is `CK - Update Step Status → rpc/record_harvest_answer`, fixed in an earlier session. Everything else predates the redesign.

### Confirmed against live production data

```
parents 299 · children 3 · parents with a named child 1 · situations 1 · logs with a result 3
```

**298 of 299 parents have no child name.** W1 never writes to `children` — it stores `main_pain` / `pain_time` as flat text on `followers`. Therefore, for almost every live parent:

| Function | Result | Consequence |
|---|---|---|
| `knowledge_depth()` | **level 0** — level 1 requires a child name | Nothing proactive is possible |
| `can_ground_seed()` | **false** | No Seed may be composed |
| `get_rhythm_due()` | finds no `situations` row | **W3 never fires** |

W3 is live and executing hourly (`5417`, `5420`, both success) and correctly sending nothing. The rhythm cannot start for anyone who came through W1. This is a live structural break, not a difference of definition.

---

## 2. Findings, by severity

### Blocking

| # | Finding | Contradicts |
|---|---|---|
| **A** | **The free tier is capped, the paid tier is not.** `M2 - Track Switch` routes `free` and `waitlist` to `Check daily Cap`; `paid` bypasses it | §6.5 rung 1 — "unlimited conversation… free forever, every country" |
| **B** | Child name never captured; situation never written to `situations` | §2.4, §2.5 — see §1 above |
| **C** | `OB - Log Step` writes to `daily_logs` directly, bypassing `record_seed_sent` — no `source`, no `log_date`, no `seed_grounded_on`. `UNIQUE (follower_id, log_date)` means it **can collide with W3's Seed row for the same day** | §5.3, P11 |
| **D** | `OB - Send Clarity` is a 7-day-trial pitch: a 🔹 feature list plus "ابدأ التجربة الآن". Fails `copy_violations()` on several counts, and promises a "ملخص بعد 7 أيام" nothing implements | P21, P24, §3.7 |
| **E** | `CTA - Build Offer Prompt` hardcodes a `PRICES` map duplicating `supported_countries`; `CTA - Offer Writer` is an LLM that composes an offer **containing the price**; `Notify Abd CTA` messages the founder personally. `CTA - Eligible?` consults neither `commerce_allowed` nor strain — **it can fire at L3** | §3.7, P17, AD-1, P1 |

### Substantive

| # | Finding | Contradicts |
|---|---|---|
| F | Six forced button steps before a word of conversation; country asked first | §9.1 — "no name request, no country question, no age question" |
| G | **Zero of 22 button sets contain «شيء آخر»** | §3.1 — "without exception" |
| H | `OB - Build Aha` is a static content library (~25 entries). Every string is sendable to a different family verbatim — `passes_uniqueness_test` → `generic` | P18, §2.6 |
| I | The agent's system prompt states "هذا المربّي في تجربة 7 أيام" — its self-concept contradicts the value model | §6.5 |
| J | No strain check anywhere in W1 | AD-2 |

### Surfaces

Of the four surfaces the Telegram Experience Engine owns, W1 implements **one**:

| | count |
|---|---|
| `inline_keyboard` | 22 |
| Reply Keyboard (`"keyboard"`, `resize_keyboard`) | **0** |
| `setMyCommands` | **0** |
| `pinChatMessage` | **0** |

### Structural

- Seven separate `GET followers` calls, each a different column subset — "what ADAM knows" assembled in seven places.
- `Is Waitlist ?` routes **both** outputs to `Mark Cap Reached` — dead logic.
- Free text bypasses the funnel entirely, so it is mandatory by design only.

---

## 3. Security — found during review, founder-owned

> **The service-role secret appears 116 times in plaintext inside W1's node parameters, and two bot tokens are inline in URLs. Zero nodes carry a credential.**

The credential connection the founder performed applied to W3/W2, not W1. W3 uses the correct pattern:

```
authentication:      predefinedCredentialType
nodeCredentialType:  supabaseApi
```

This does not close the week-0 exposure — **the key still needs rotating**, and W1 needs converting to the W3 pattern.

---

## 4. What has been done

**Applied to production** (verified present):

| Migration | Contents |
|---|---|
| `telegram_surface_state` | `get_telegram_surface`, `ar_digits`, `ar_nights`, `situation_label_ar` |
| `conversation_copy_and_button_law` | `conversation_moments` (23 rows), `copy_violations`, `validate_outgoing`, `get_conversation_moment` |
| `knowledge_gate_and_uniqueness` | `family_tokens`, `passes_uniqueness_test`, `knowledge_depth`, `can_send` |

**Not applied:** the W1 edits. The first batch failed atomically — nothing was written.

### Why it failed, and the fix

`setNodeCredential` was rejected: *"node type 'n8n-nodes-base.httpRequest' does not accept credential 'supabaseApi'"*. This is a limitation of the n8n **MCP tool**, not of n8n — W3 runs that exact combination in production.

**Resolution:** keep `authentication: predefinedCredentialType` / `nodeCredentialType: supabaseApi` in the node's `parameters` (those operations validated fine) and **omit the `setNodeCredential` operations**. The credential is then attached once in the n8n UI, exactly as was done for W3. This also avoids writing any new plaintext secret.

---

## 5. Redesign plan

Ordered by severity. Each batch is atomic and independently revertible; n8n version history retains the prior graph, so nothing is deleted — disabled nodes stay on the canvas per the standing archive rule.

### Batch 1 — stop the active harm *(written, not applied)*

1. `removeConnection` `M2 - Track Switch`[1] → `Check daily Cap`; `addConnection` [1] → `M2 - Get Memory Snapshot`. Disable the five cap nodes. **Free conversation becomes uncapped.**
2. Replace the selling branch: `CTA - Get Follower` → **`Get Referral Moment`** (`rpc/get_conversation_moment`, key `referral`) → **`Referral Allowed?`** → **`Send Team Referral`** / **`Get Presence Moment`** → **`Send Presence`**. Disable the twelve CTA nodes.
   - The body comes from `conversation_moments`, so it **cannot contain a price without a constraint violation**.
   - `requires_commerce` makes the strain gate structural: at L2/L3 the parent gets presence, not a cashier.

### Batch 2 — first contact replaces the funnel

`Route Switch[start]` → `Get Follower` → `Follower Exists?` → `Create Follower` → `Get Surface` (`get_telegram_surface`) → `Send First Contact` (`get_conversation_moment('first_contact')`) with the **reply keyboard** → `Send Pinned` → `Pin It` (`disable_notification: true`).
Disable: country nodes, `Send Main Welcome`, `Send Waitlist Message`, and the entire `OB-*` chain including `OB - Send Clarity` and `OB - Log Step`.

### Batch 3 — menu and menu taps

`القائمة ☰` → `get_telegram_surface` → render the five items; taps resolve through `get_conversation_moment('menu_*')`. The `meaning` string is the seam — every value already has a moment, asserted by `conversation_law_test.sql`.
`menu_progress` and `menu_child` are answered **deterministically** from the surface and `family_tokens` — §2.2 forbids using tier 3 for what tiers 1–2 can answer.

### Batch 4 — the outgoing gate

`validate_outgoing(key, body)` between the agent and every send. A failure is a message not sent.

### Batch 5 — child name and situation capture

Belongs to W2 (Knowledge Writer), not W1: extract the name into `children` and the situation into `situations` via `commit_situation`. **This is what unblocks W3.** Until it exists, batches 1–4 improve the gateway but the rhythm still cannot start.

---

## 6. Blocked

The n8n and Supabase connectors lost authorization mid-task. Batches 1–5 need n8n; nothing further can be applied until both are re-authorized from the claude.ai connector settings.

---

## 7. Execution log — 2026-07-31

Applied to `42loY0bgUSwYmHFV` via atomic operation batches. **89 → 111 nodes.**

| Batch | Ops | Result |
|---|---|---|
| 1 — stop the harm | 32 | applied |
| 2 — first contact replaces the funnel | 53 | applied |
| 3 — menu and menu taps | 22 | applied |

### Batch 1
- `M2 - Track Switch`[1] rerouted from `Check daily Cap` straight to `M2 - Get Memory Snapshot`. **Free conversation is no longer capped.** Five cap nodes disabled.
- The selling branch replaced by `Get Referral Moment → Referral Allowed? → Send Team Referral | Get Presence Moment → Send Presence`. Twelve CTA nodes disabled, including the hardcoded `PRICES` map and the LLM that composed offers containing them.

### Batch 2
- `Get Parent Row → Resolve Parent → Get Surface → Get First Contact → Send First Contact → Send Pinned → Pin It`.
- The reply keyboard is now sent on first contact; the pinned message is derived from `get_telegram_surface` and pinned with `disable_notification`.
- Disabled: the country nodes, both welcome variants, all 27 `OB-*` nodes (including `OB - Send Clarity`, the trial pitch, and `OB - Log Step`, the direct `daily_logs` write), and the two `RA-*` nodes.

### Batch 3
- `Router` rewritten: recognises `القائمة ☰`, `/menu`, `كيف نتقدّم`, and `menu_*` callbacks. `how_start` / `not_now` from the new moment buttons are routed to the referral and the no-follow-up path.
- `Route Switch` extended to 19 outputs (`menu`, `menu_tap`).
- Menu renders from the surface; taps resolve through `get_conversation_moment`. Fixed moments send their stored body and buttons; the rest are answered **deterministically from the surface** (§2.2 — what tier 1 can answer must not go to the LLM).

### ⚠ One manual step is required before this can go live

**Fifteen new HTTP nodes have no credential attached.** The n8n MCP refuses to bind `supabaseApi` to an `httpRequest` node — retried on an already-created node and rejected again — although n8n itself supports the combination and W3 runs on it.

Attach **`adam Supabase`** to these nodes in the n8n UI:

```
Get Referral Moment · Get Presence Moment · Get Parent Row · Get Surface
Get First Contact · Menu - Get Parent · Menu - Get Surface
Tap - Get Parent · Tap - Get Surface · Tap - Get Moment
```

Until then those nodes return 401 and `/start` produces no welcome. The edits appear to be saved as a new workflow version that is not the active one — **confirm in the UI before publishing**, and publish only after the credentials are attached.

### Still not done

**Batch 5 — child name and situation capture — belongs to W2 and has not been built. It is the only thing that unblocks W3.** Batches 1–3 fix the gateway; the rhythm still cannot start until a name reaches `children` and a situation reaches `situations` via `commit_situation`.

Also outstanding: `validate_outgoing` is not yet wired between the agent and its send, and the agent's system prompt still frames itself as a 7-day trial.
