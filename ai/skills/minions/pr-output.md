---
name: pr-output
description: Reviewer output discipline for GitHub PRs. Findings as inline comments only. Approve verdicts are label flips, never Review bodies. Self-approval-blocked is NOT a license to fall back to `gh pr review --comment`. Read before any reviewer's output step.
---

# PR output

You are a swarm reviewer about to post your verdict on a PR. This skill specifies the exact output mechanics. Two paths. Pick one. Nothing else lands on GitHub from your dispatch.

## Approve path

1. `gh pr edit <N> --add-label zaphod-approved`. That is the verdict.
2. Stop.

You do not run `gh pr review`. You do not write a body. You do not post a thank-you. The label IS the verdict.

## Block path

1. For each finding, post an inline review comment anchored to a specific `path:line`. Use the Reviews API as documented in `ai/skills/minions/reviewers.md` (the multi-comment Review submission with empty `body`). The Review wrapper exists ONLY to group line comments; its `body` field stays empty.
2. `gh pr edit <N> --add-label zaphod-blocked`.
3. Stop.

No prose explainer in the PR's main conversation tab. No "summary" body block. Findings are line-anchored or they don't exist.

## The trap: self-approval blocked

If you run `gh pr review --approve` on a PR you authored (or that shares your gh identity), GitHub returns "Can not approve your own pull request." The naive fallback is `gh pr review --comment --body "Verdict: approve. <reasoning>"`. **THIS IS THE TRAP. NEVER DO IT.**

`--comment` submits a Review with type `COMMENTED` whose body lands in the PR's main conversation tab as a verdict block. Multiple reviewer dispatches stacking these blocks is exactly the noise the rule prevents. Volley PRs have accumulated 20+ such blocks before; do not add to the pile.

Correct behaviour when self-approval is blocked:

- Do NOT submit any Review.
- Apply the `zaphod-approved` label via `gh pr edit`.
- Optionally note in your dispatcher report that you handled this case via label-only because `--approve` was blocked. The dispatcher report does not land on GitHub; it lands in your Agent tool's result, which only the dispatcher sees.

## Verifying you obeyed

Before exiting your dispatch, check:

- `gh pr view <N> --json reviews | jq '.reviews | map(select(.author.login == "<your gh login>")) | length'` should match the number of Block-path passes you ran (typically 0 for approve, 1 for block). If you accidentally submitted a comment-style Review, it shows up here.
- `gh pr view <N> --json comments` (top-level conversation comments) should be unchanged by your dispatch.

If either count grew unexpectedly, you wrote noise to the main thread. Note it in your report and recommend the dispatcher delete the offending Review.

## Why this matters

GitHub's conversation tab renders submitted Reviews inline. Each Review body is a block in the thread. The PR author's mobile review experience degrades sharply past ~5 blocks. A 20-block PR is unreadable on phone. Inline comments do not have this cost; they attach to the diff and render under the file, not in the conversation.

The label carries the merge gate signal. The body adds nothing. The body is pure cost.
