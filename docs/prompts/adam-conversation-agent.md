# ADAM — the main conversation agent prompt

**Node:** `paid aget adam` in W1. Serves free and paid alike — the name is legacy.
**Rewritten:** 2026-07-31, after the founder read a live `/start` and named this the deepest problem.

## What was wrong

| Problem | In the old prompt |
|---|---|
| **A false self-concept** | *"هذا المربّي في تجربة 7 أيام"* — there is no trial. Rungs 1–2 are free forever (§6.5). ADAM believed it was renting itself out. |
| **Templated by construction** | Every turn was mandated as cause + step + measure. The founder felt the repetition because the prompt *required* it. |
| **Lecturing** | Nothing capped explanation, and nothing forbade teaching child psychology at length. |
| **Interrogation risk** | The old prompt permitted a question per turn with no rule against stacking fields across turns. |
| **Gendered** | Opened with `{{ $json.gender_line }}` — an injected masculine/feminine instruction. `parent_gender` is now null for every new parent, since the funnel that collected it is disabled. §0.7 makes the gender-free default primary anyway. |

## The three changes that matter

**1. A repertoire instead of a template.** The old prompt gave one shape. The new one gives five legitimate moves and forbids using the same construction twice running:

- a cause, then something small to try tonight
- something small immediately, no preamble — when it is late and they are spent
- one observation about what recurs, then silence
- presence only, no step and no question
- a single question, when it genuinely opens the way

The opening must vary too. **Repetition is what makes it feel like a machine, so the rule is explicit rather than implied.**

**2. The name is earned, not collected.** Asking for the child's name, age, time and state is a form, and the prompt now bans that outright — across turns, not just within one message. The name usually arrives on its own when a parent talks about their child. If it has not after several messages *and ADAM has already been useful*, it may be asked once, casually, and never again.

This is what actually feeds `commit_child_name` — W2 extracts the name from conversation. The agent's job is to make saying it natural, not to demand it.

**3. Length is a cost, not a style.** Two or three lines. Four only if the fourth line changes their night. Stated as: *every line that does not bring them closer to a calmer evening steals energy they do not have.*

## What stayed, and why

- **The full recipe is always given.** If they ask "how exactly?", answer completely. Withholding detail is the fastest way to destroy the reason they came.
- **Collapse means presence only** — no step, no measure, no question.
- **Never a price, never a subscription, however directly asked.** Point at فريق آدم and name no number (§3.7, AD-1).
- **Show, never announce** (§2.7). Using what ADAM knows is allowed; saying that it knows is not.

## What this prompt still cannot do

It does not receive `knowledge_depth`, so it cannot know whether it is at level 0 or level 4 and adjust what it may attempt (§2.4). Right now it infers from `memory_snapshot` and `child_name`. **Injecting depth is the obvious next improvement** — it would let the prompt stop guessing at its own stage.

Its output is also **not** run through `gate_composed_reply` yet. The evening reply is gated; ordinary conversation is not. That is the remaining half of the outgoing gate.
