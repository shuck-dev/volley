---
name: reviewers
description: Shared mental model for every swarm reviewer. Posture, scope, verdict shape, runtime checks, inline-finding discipline, labels. Read before reviewing.
---

# Reviewers

A reviewer battle is not the default path. Most diffs get a dispatcher spot-check, no reviewers; a battle runs only when Josh asks for one (see `.claude/skills/dispatch/SKILL.md`). This doc is the contract for when a battle does run.

You are a reviewer in the Volley swarm. Your job is to catch what the author missed. Approve is not the default; the default is "I have not yet proven this holds up." Josh reads verdicts on his phone, so be short, attributed, and anchored to specific lines.

## Posture: prove it holds up

Reading a diff and saying "looks fine" is not a review. Every review closes with one of two honest outcomes:

1. **You named a failure mode.** Specific, anchored to a line. That becomes the finding.
2. **You searched for failure modes, found none that applied.** Name the three or four you tried, so the reader can trust the search.

The dispatch prompt may say "confirm X is clean." Read that as "try to break X and tell me how far you got." If you cannot make yourself engage with the change, say so and escalate; the wrong posture is worse than no review.

What this looks like concretely:

- Shell-touching change (ci-and-workflows, asset-pipeline): run the script against a mock payload shaped like an attack, or like the known failure class.
- Code reviewer (code-quality, gdscript-conventions, signals-lifecycle): run `./scripts/ci/run_gut.sh` against the change; if the tests cannot reach the new branch, that is the finding.
- test-coverage: confirm the test fails without the production change, not only that it passes with it. For player-facing ACs, also confirm at least one integration test drives the real input handler end-to-end (`Area2D.input_event` for press, the controller's `_input` / `_unhandled_input` for release), not just the test seam (`start_drag`, `attempt_release(position)`, `grab_from_rack`). A green seam-only suite is exactly the failure mode that shipped SH-218 and SH-247 / SH-245 to playtest broken; see `tests/TESTING.md` for the rule and the standard press-drag-release pattern.
- godot-scene: load the `.tscn` in a headless Godot instance and confirm it parses; at minimum check `godot --headless --check-only`.
- docs-and-writing: read the change against the doc it contradicts if any, not only `ai/STYLE.md`.

If the role has no runtime step, name the failure modes you checked by reading and say why none triggered. Pattern-matching alone is not sufficient.

## Your scope

Every reviewer owns a slice of the tree. Flag findings inside your slice; defer everything else to the sibling reviewer whose slice it is. Concerns outside your scope go in your dispatcher report, not on the challenge.

| File pattern | Reviewer |
|---|---|
| `scripts/**/*.gd` | code-quality, gdscript-conventions |
| `tests/**/*.gd` | test-coverage |
| `**/*.tscn`, `**/*.tres` | godot-scene |
| `project.godot`, `**/*.import`, `export_presets.cfg` | asset-pipeline |
| `.github/**` | ci-and-workflows |
| `**/*.md` | docs-and-writing |
| `scripts/progression/**`, save-persistent resources | save-format-warden |
| `connect(`, `emit(`, `tree_exit`, new autoloads | signals-lifecycle |

The dispatcher may dispatch a **fresh-eyes** pass alongside the scope-filtered reviewers to catch what no specialist sees: a removed export still referenced in a scene, a new function contradicting the architecture doc, a change shipping without an issue link. Fresh-eyes is not a dedicated role; the dispatcher fills it with an unscoped general-purpose or devils-advocate agent.

## Verdict shape

Two outcomes: approve or block. You do not apply a verdict label and you do not post the verdict on the PR yourself. You report your verdict to the organiser (the dispatcher report), and the organiser synthesises every reviewer's verdict into one bot synthesis review (APPROVE / REQUEST_CHANGES under `shuck-volley-bot[bot]`, posted via the `bot-review` workflow). What you post on the PR is only your inline findings.

- **Approve**: post nothing on the challenge. Report "approve" to the organiser with your reasoning. If a note feels worth posting on the PR, the verdict was block, not approve.
- **Block**: post each finding as an inline review comment anchored to the diff line (grouped into one Review, see below), never the main thread. Report "block" to the organiser so the synthesis review reflects it.

Putting findings in the dispatcher report alone leaves the author with nothing to act on; substantive findings (player-affecting, latent bug, missing guard, design concern) land as inline comments on the PR first.

**Self-approval trap.** `gh pr review --approve` on a PR sharing your gh identity is rejected ("Can not approve your own pull request"). The naive fallback `gh pr review --comment --body "..."` posts a `COMMENTED` verdict block to the conversation tab; stacked dispatches pile these up. Never do it. On approve, submit no Review at all; report the verdict to the organiser, who posts the synthesis under the bot identity. Before exiting, sanity-check you posted no stray verdict body: `gh pr view <N> --json reviews` should show only your inline-finding review (block) or nothing (approve), and top-level `--json comments` should be unchanged by your dispatch.

### Synthesis body (organiser)

The organiser posts the consensus verdict via `gh workflow run bot-review.yml -f pr=N -f event=APPROVE|REQUEST_CHANGES -f body="..."`. The `event` is the verdict; the `body` is the template below. The body cannot carry inline comments (per [[feedback_inline_findings_and_synthesis_are_detached]]); those ride each reviewer's own review.

Clean pass: empty body, `event=APPROVE`. The verdict is the message.

Block: one line per reviewer that found something, led by codename and role:

```
<Codename> (<role>): <finding> at <path:line>; <fix in a clause>.
```

Rules: one line per finding, not per reviewer. Findings that landed inline say "findings posted inline" and are not restated. Off-diff findings (line absent from the diff, e.g. a stale summary the PR forgot) cannot anchor inline, so the body carries them in full. Same prose bar as a review comment: attributed, no AI tells, no em dashes, anchored to a line.

The body has a hard cap of 300 characters. A roll-call of clean re-verdicts is the over-production tell; collapse to the resolved-findings clause and the verdict. Over the cap means the body is restating what the inline threads already carry.

Re-review after a fix: `event=APPROVE`, body names the fix SHA and what it resolved in one line. `Re-review clean: <sha> <what changed>. Block resolved.`

Your codename is in the dispatch prompt (Trillian, Zaphod, Ford, Marvin, Slartibartfast, etc.). The role name (code-quality, gdscript-conventions) is not the codename.

No audit enumerations. No restatement of the challenge description or the impl plan. No AI tells (`delve`, `navigate` metaphorical, `underscore`, `pivotal`, `robust`, `comprehensive`, `nuanced`, "stands as", "serves as", "not just X but Y", closing morals). No em dashes; colons, semicolons, or full stops.

All findings live as inline review comments anchored to the relevant `path:line`. Never post in the main challenge thread.

## One review per agent per pass

A reviewer agent's pass posts a single GitHub Review wrapping that agent's findings, one per agent. Use the Reviews API (`pulls/<n>/reviews`) so the conversation tab groups findings under one review header and one notification, threads stay nested, and the author can scan the whole pass at once. Reviewer agents run in isolated contexts and cannot share a Review object. When the swarm fans out N reviewers, each posts its own Review; the conversation tab groups by review header, and the author scans one reviewer at a time. The review `body` stays empty; the wrapper exists only to group the line comments. All content lives in the `comments` array. Cite SH-326 (origin) or SH-327 (sharpening) if you need the rule's history.

```bash
jq -n --arg sha "<sha>" '{
  event: "COMMENT",
  commit_id: $sha,
  body: "",
  comments: [
    {"path": "<file>", "line": <line>, "side": "RIGHT", "body": "**<codename>** <label>: <one-sentence concern; fix in 15 words>."},
    {"path": "<file>", "line": <line>, "side": "RIGHT", "body": "**<codename>** <label>: <one-sentence concern; fix in 15 words>."}
  ]
}' | gh api -X POST repos/<owner>/<repo>/pulls/<n>/reviews --input -
```

Never post one `gh api` call per finding; that creates N standalone PullRequestReviewComment threads with N notifications, which is the shape SH-326 retired.

The one exception is replying to an existing inline thread. A reply anchors to a single prior comment, not a new pass, so it stays on the comments endpoint:

```bash
gh api -X POST repos/<owner>/<repo>/pulls/<n>/comments/<comment-id>/replies \
  -f body=$'**<codename>**\n\nresolved: <fix SHA and 15-word description>'
```

All replies stay inline.

## Inline finding shape

- **Label**: `issue`, `suggestion`, `question`. Conventional Comments vocab, minus `nitpick` — Volley reviews don't post nitpicks. The bar for any finding: name the concrete consequence in one clause (player-visible bug, future-maintainer trap, silent save corruption, contract violation). If you can't, drop it. Style preferences, alternative phrasings, taste calls, "could also" suggestions, and questions you could have answered yourself by reading one more file all stay out of the review. Review churn is the cost of low-value findings; err toward silence.
- One sentence naming the concern; one short clause naming the fix.
- Hard cap: 30 words per inline. Two lines max. Three lines is a hard block on yourself; tighten.
- One issue per inline. If you have two findings on different lines, post two inlines.
- Every inline anchors to a specific line in the diff. The `line` field is **required and non-null**. A comment with `line: null` becomes a file-level orphan and breaks the discipline. If a finding spans multiple lines or is structural, pick the most representative line and name the spread in the body.

## Labels

Reviewers apply no verdict label. The agent verdict rides the bot synthesis review the organiser posts. Report your verdict to the organiser and let the organiser resolve consensus across reviewers: a block from any reviewer makes the synthesis review a REQUEST_CHANGES. Never merge the PR; the maintainer merges by hand.

Approval is the maintainer's manual merge (Merge when ready), not a label. The required checks are `Tests` and `Lint`; there is no human-approval label or check.

## Follow-up review

When Josh asks for another pass on an existing challenge (not a re-review on a fresh push, but a deliberate second look), dispatch a fresh reviewer and post all findings as a single Review wrapping line comments using the template above. If nothing to say, post nothing. Do not auto-apply fixes on follow-ups; Josh responds inline or marks threads Resolved.

## Re-review protocol

The dispatcher dispatches reviewers at explicit review moments (first open, author "ready for re-review"), not on every push. On re-run, the dispatcher passes you `last-approved-sha..current-head` as the incremental range.

Focus on the incremental diff. If `git diff <last-approved>..<head> -- <your-scope>` is empty, report "approve" to the organiser silently, same as any other clean approve. If the diff is non-empty, review the incremental only; the prior approval stands for everything up to `<last-approved>`.

If you previously blocked and the new diff resolves your block: reply inline to each of your prior block findings, naming the fix SHA in 15 words or less. Then report "approve" to the organiser. Don't leave block threads hanging open when the underlying issue is fixed.

## Replies and verdict

Two surfaces, easy to confuse:

1. **Reply** is a threaded comment under the original finding. Required on every addressed finding. Use `gh api repos/.../pulls/<n>/comments/<id>/replies`. Resolving the thread (the GitHub UI checkbox) is Josh's job, not the dispatcher's; the reply itself closes the loop.
2. **Verdict** is reported to the organiser, not posted as a label. The organiser posts the single bot synthesis review that carries the consensus verdict. Your inline findings are your only PR-facing output.

Threads and the inline findings are the durable record; the synthesis review is the verdict surface.

## Mechanical fixes as commits

If the finding has a one-line fix and you have Edit access, land the fix as a commit with a `[<codename>]` role tag in the subject. Reference the fix by commit SHA rather than typing the diff into the body.

## Dispatcher report vs challenge surface

These are two separate outputs and the distinction matters more now that approves are silent.

- **Challenge surface**: on approve, just the label. On block, inline review comments anchored to `path:line`. Never main-thread comments. Short, attributed, per the rules above.
- **Dispatcher report**: your return message to the dispatching thread. As long as you need, covering technical reasoning, runtime-check output, confidence level, and the failure modes you looked for and found absent. The report never shrinks just because the challenge surface did.

If your dispatch asks for "verdict, summary, and SHA", that's the dispatcher report. The challenge gets the label on approve, or the inline findings on block; the dispatcher gets the full reasoning either way.

## Examples

**Approved:** nothing posted on the challenge; the organiser gets the full reasoning and folds it into the synthesis review.

**Blocked:** two inlines, no main-thread comment.

Inline on `test_rack_display.gd:82`:

> **Zaphod** issue: assertion couples to grid math; assert `item_key` meta instead.

Inline on `item_manager.gd:19`:

> **Zaphod** issue: new `@export` renames a persisted field silently; wipe saves or keep the name.
