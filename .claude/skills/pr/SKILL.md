---
name: pr
description: Everything that lands on a GitHub PR, author side and reviewer side. Writing the PR body (narrative prose, short, no changelog, no test plan, no local aliases, flag new secrets). Posting reviewer findings (inline comments only, no verdict body, via scripts/swarm/post-review.sh). Read before writing a PR body, before `gh pr create`/`gh pr edit`, or before any reviewer's output step.
---

# PR

The two surfaces a PR carries: the body the author writes, and the findings a reviewer posts. Both are this skill. The diff already says what changed; everything here is about the surrounding human-facing text and where it lands.

# Writing the body

A PR body explains the change to a reviewer who was not in the conversation. It justifies the work; it does not recite the diff.

## Shape

One short opening paragraph: what the issue asked for and why the PR is shaped this way. Then, only if the change has real themes, a subsection or two of prose per theme. Call out known concerns, deferred work, and links to related issues. Stop.

Aim for one short paragraph or a 3-5 bullet list. Include only:
- **What the PR does**: one sentence.
- **Why**: only if non-obvious from the issue title.
- **Manual follow-up or risk**: only if present.

The deeper rationale (rejected alternatives, the full reasoning) belongs in the committed doc or the code, not the PR body. Detail flows outward to the most durable surface: commit subject (one line), PR body (a paragraph or two), the doc or code (the full reasoning). When a PR ships a design or spike doc, that doc holds the rationale; the body points at it. The test for any sentence: is it explaining the change, or relitigating the decision? The second belongs in the doc.

## Cut

- Session history ("this came up three times today").
- Rationale that duplicates the issue AC.
- Meta-commentary on why a rule is being added.
- A `## Test plan` section or any checklist of verification steps. Player-facing verification lives in the mission's Ride; AC lives on the Linear issue. Duplicating it into the PR is noise that decays the moment the Ride runs.
- A Summary section that is bullet points starting with verbs ("Moved X", "Added Y"). That is the diff talking, not the author.

## Tone

Professional prose, complete sentences, past tense for completed actions. Avoid casual phrasing ("turned out to be", "came out in the same PR"), sentence fragments, and conversational asides. Read every sentence; if it reads like a chat message instead of a technical writeup, rewrite it. Avoid em dashes (use colons, semicolons, commas), AI-register vocabulary ("delve", "leverage", "robust", "streamline"), and understatements of scope ("small game").

## References

Reference related work by bare GitHub `#N` (no closing verb, no Linear `SH-N` on any public surface, per `feedback_design_docs_subject_first_github_ids`). Bare `#N` references go in the body; the Linear link is made by hand after the PR is up.

## Spell out local aliases

Local shell aliases (`ggut`, `gcf`, `gcb`) live in Josh's zsh and nowhere else; a contributor, CI runner, or clean-environment agent will not have them. In the body, commit messages, and any repo-tracked doc, write the real command: `./scripts/ci/run_gut.sh` (or "the GUT suite"), `git checkout -b`. Local Bash tool calls in conversation may use aliases; public surfaces may not.

## Flag new PR-triggered secrets

If the diff adds or edits a workflow that runs on `pull_request*` (or `workflow_run` after a PR-gated workflow) and references `${{ secrets.* }}` beyond `GITHUB_TOKEN`, stop. "Do not require approval" is on, so any contributor PR runs workflows automatically; a secret on that path is exfiltratable. Flag it in the body and to Josh in the handoff; do not ship it silently. `GITHUB_TOKEN` scoped by the workflow's `permissions:` block is fine.

# Posting reviewer findings

A swarm reviewer producing a verdict on a PR. Reviewers apply no verdict label and post no verdict body; the verdict (approve / block) is reported to the organiser, who posts the single bot synthesis review. Two paths. Pick one. Nothing else lands on GitHub from the dispatch.

## Approve path

1. Post nothing on the PR.
2. Report "approve" to the organiser in the dispatcher report.

Do not run `gh pr review`. Do not write a body, apply a label, or post a thank-you. The organiser posts the round's synthesis review (APPROVE on a clean pass); that is not the reviewer's step.

## Block path

1. For each finding, post an inline review comment anchored to a specific `path:line`. Use `scripts/swarm/post-review.sh <pr> <verdict-json>` (verdict JSON is `{verdict: "block", commenter, items: [{path, line, body}]}`), or the Reviews API directly as documented in `.claude/skills/reviewers/SKILL.md` (multi-comment Review submission with empty `body`). The Review wrapper exists ONLY to group line comments; its `body` stays empty.
2. Report "block" to the organiser so the synthesis review becomes REQUEST_CHANGES.

No prose explainer in the PR's main conversation tab. No "summary" body block. Findings are line-anchored or they do not exist. Do not hand-roll `gh api .../comments`: it is the wrong endpoint and the compound shell gets denied as unreviewable; use the script.

## The trap: self-approval blocked

Running `gh pr review --approve` on a PR sharing your gh identity returns "Can not approve your own pull request." The naive fallback is `gh pr review --comment --body "Verdict: approve..."`. **NEVER DO IT.** `--comment` submits a `COMMENTED` Review whose body lands in the conversation tab as a verdict block; stacked dispatches pile these up (Volley PRs have hit 20+). When self-approval is blocked, submit no Review on approve; report the verdict to the organiser, who posts the synthesis review under a separate identity. The dispatcher report lands in the Agent tool result, not on GitHub.

## Verifying you obeyed

Before exiting the dispatch:
- `gh pr view <N> --json reviews | jq '.reviews | map(select(.author.login == "<your gh login>")) | length'` should match the Block-path passes run (0 for approve, 1 for block).
- `gh pr view <N> --json comments` (top-level conversation comments) should be unchanged by the dispatch.

If either grew unexpectedly, note it in the report and recommend the organiser delete the offending Review.

## Why the reviewer discipline matters

GitHub renders each submitted Review as a block in the conversation tab. The author's mobile review degrades sharply past ~5 blocks; a 20-block PR is unreadable on a phone. Inline comments attach to the diff under the file, not the conversation, and carry none of this cost. The verdict surface is the organiser's single bot synthesis review; a reviewer's verdict body adds nothing and is pure cost.
