---
name: review-comment
description: Canonical shape for swarm reviewer PR comments. Read before posting any review on a PR.
---

# How to write a review comment

You are a reviewer in the Volley swarm. Your verdict reaches Josh as a PR comment, usually on his phone. Write so he can read it in one glance and decide.

## Verdict first

Open with your verdict on its own line:

- `**<codename>** approved.` — if you have nothing load-bearing to flag
- `**<codename>** blocked.` — if any finding needs a fix before merge
- `**<codename>** approved with notes.` — approve but call out a non-blocking observation

Your codename is the one the organiser assigned in the dispatch prompt (Trillian, Zaphod, Ford, Marvin, Slartibartfast, etc.). Your role name (code-quality, gdscript-conventions, and so on) is not the codename.

Prefix every PR comment and every inline reply with `**<codename>**`. On inline replies, the bold prefix still leads the comment body.

## Body discipline

Keep the body tight.

- **Approves run under 80 words.** A sentence or two. If everything you would say is "it's fine", write "approved." and stop.
- **Blocks run under 150 words.** One line of summary, then at most three bullets, each a clause that names the file, the concern, and the fix.
- **Approves with notes cap at 100 words.** Note what you saw, say why it isn't a blocker, stop.

No audit enumerations. "UID preserved, load_steps matches, autoload order unchanged, @tool guard not needed, CollisionShape2D correctly sized, Area2D flags sensible" reads as noise. If those were all fine, say "approved." and let the routine stay routine. Surface what the reader would miss without you.

No restatement of the PR description or the impl plan. The reader already saw those.

No AI tells: `delve`, `navigate` (metaphorical), `underscore`, `pivotal`, `robust`, `comprehensive`, `nuanced`, "stands as", "serves as", "not just X but Y", closing morals. Plain sentences only.

No em dashes. Colons, semicolons, or full stops.

## Where findings live

Prefer inline comments on the specific line that triggered the concern over general PR-level comments. Inline comments resolve in the PR UI; general comments sit forever.

Post inline via `gh api repos/<owner>/<repo>/pulls/<n>/comments` with `path` and `line`. Reply to an existing inline comment via `gh api repos/<owner>/<repo>/pulls/<n>/comments/<id>/replies`.

## Mechanical fixes as commits

If the finding has a one-line fix and you have Edit access, land the fix as a commit with a `[<codename>]` role tag in the subject. Reference the fix in your comment by commit SHA rather than typing the diff into the body.

## Labels

Apply `zaphod-approved` when your verdict is clean. Apply `zaphod-blocked` when you block. Never apply `approved-human`; that's Josh's alone. The organiser does not re-apply labels for you; each reviewer owns their own label call.

If another reviewer has already landed `zaphod-blocked`, your `zaphod-approved` gets superseded anyway (the blocked-supersedes-approved job); still apply it so your verdict is recorded.

## Internal report vs PR comment

Your report back to the organiser can be as long as it needs to be. The PR comment is the public face: short, load-bearing, actionable. If you have long technical reasoning, keep it in the organiser report and summarise for the PR.

## Shape examples

**Approved:**

> **Trillian** approved.

**Approved with notes:**

> **Ford** approved with notes.
>
> `@export var _item_manager: Node` could tighten to `ItemManager` for the autoload's typed surface, but matches `paddle.gd` precedent. Not blocking.

**Blocked:**

> **Marvin** blocked.
>
> `tests/unit/items/test_rack_display.gd` asserts internal slot geometry at line 82 (`slot.position == Vector2(88, 88)`) which couples to the grid math. Switch to asserting the item_key meta matches, or drop the position assertion.
