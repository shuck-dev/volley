---
name: pr-output
description: Reviewer output discipline for GitHub PRs. Findings as inline comments only. Reviewers apply no verdict label and post no Review body; the verdict is reported to the organiser. Self-approval-blocked is NOT a license to fall back to `gh pr review --comment`. Read before any reviewer's output step.
---

# PR output

You are a swarm reviewer about to produce your verdict on a PR. This skill specifies the exact output mechanics. Reviewers apply no verdict label and post no verdict body; the verdict (approve / block) is reported to the organiser, who posts the single bot synthesis review. Two paths. Pick one. Nothing else lands on GitHub from your dispatch.

## Approve path

1. Post nothing on the PR.
2. Report "approve" to the organiser in your dispatcher report.

You do not run `gh pr review`. You do not write a body. You do not apply a label. You do not post a thank-you. The organiser posts the round's synthesis review (APPROVE on a clean pass); that is not your step.

## Block path

1. For each finding, post an inline review comment anchored to a specific `path:line`. Use the Reviews API as documented in `.claude/skills/reviewers/SKILL.md` (the multi-comment Review submission with empty `body`), or `scripts/swarm/post-review.sh`. The Review wrapper exists ONLY to group line comments; its `body` field stays empty.
2. Report "block" to the organiser so the synthesis review becomes REQUEST_CHANGES.

No prose explainer in the PR's main conversation tab. No "summary" body block. Findings are line-anchored or they don't exist.

## The trap: self-approval blocked

If you run `gh pr review --approve` on a PR you authored (or that shares your gh identity), GitHub returns "Can not approve your own pull request." The naive fallback is `gh pr review --comment --body "Verdict: approve. <reasoning>"`. **THIS IS THE TRAP. NEVER DO IT.**

`--comment` submits a Review with type `COMMENTED` whose body lands in the PR's main conversation tab as a verdict block. Multiple reviewer dispatches stacking these blocks is exactly the noise the rule prevents. Volley PRs have accumulated 20+ such blocks before; do not add to the pile.

Correct behaviour when self-approval is blocked: do not submit any Review at all on approve. Report the verdict to the organiser, who posts the bot synthesis review under a separate identity. The dispatcher report does not land on GitHub; it lands in your Agent tool's result, which only the organiser sees.

## Verifying you obeyed

Before exiting your dispatch, check:

- `gh pr view <N> --json reviews | jq '.reviews | map(select(.author.login == "<your gh login>")) | length'` should match the number of Block-path passes you ran (typically 0 for approve, 1 for block). If you accidentally submitted a comment-style Review, it shows up here.
- `gh pr view <N> --json comments` (top-level conversation comments) should be unchanged by your dispatch.

If either count grew unexpectedly, you wrote noise to the main thread. Note it in your report and recommend the organiser delete the offending Review.

## Why this matters

GitHub's conversation tab renders submitted Reviews inline. Each Review body is a block in the thread. The PR author's mobile review experience degrades sharply past ~5 blocks. A 20-block PR is unreadable on phone. Inline comments do not have this cost; they attach to the diff and render under the file, not in the conversation.

The verdict surface is the organiser's single bot synthesis review. A reviewer's verdict body adds nothing to the PR; it is pure cost.
