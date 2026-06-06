---
name: pr
description: Everything that lands on a GitHub PR, author side and reviewer side. Writing the PR body (short narrative prose, no changelog, no test plan, no local aliases, flag new secrets). Posting reviewer findings (inline comments only, no verdict body, via scripts/swarm/post-review.sh). Read before writing a PR body, before `gh pr create`/`gh pr edit`, or before any reviewer's output step.
---

# PR

Two surfaces: the body the author writes, and the findings a reviewer posts. The diff says what changed; this is the human-facing text around it.

# Writing the body

Explain the change to a reviewer who was not in the conversation. Justify the work; do not recite the diff.

One short paragraph, or a 3-5 bullet list: what the PR does (one sentence), why (only if non-obvious from the issue title), any manual follow-up or risk (only if present). If the change has real themes, a subsection of prose each. Then stop.

The deeper rationale (rejected alternatives, full reasoning) goes in the committed doc or the code, not the body. Detail flows to the most durable surface: commit subject, then body, then doc/code. When a PR ships a design or spike doc, the body points at it. Test each sentence: explaining the change (keep) or relitigating the decision (cut, it belongs in the doc)?

Cut: session history, rationale duplicating the issue AC, meta-commentary, a `## Test plan` or any verification checklist (the Ride covers it), a verb-bullet Summary (that is the diff talking).

Tone: professional prose, complete sentences, past tense. No casual phrasing or fragments, no em dashes (use colons/commas), no AI-register words ("delve", "leverage", "robust"), no scope understatement ("small game").

References: bare GitHub `#N`, no closing verb, no Linear `SH-N` on any public surface (`feedback_design_docs_subject_first_github_ids`). The Linear link is made by hand after the PR is up.

Aliases: spell out Josh's zsh aliases on every public surface (body, commit, repo docs): `./scripts/ci/run_gut.sh` not `ggut`, `git checkout -b` not `gcb`. A contributor or CI runner does not have them.

Secrets: if the diff adds a `pull_request*` (or post-PR `workflow_run`) workflow referencing `${{ secrets.* }}` beyond `GITHUB_TOKEN`, stop and flag it in the body and to Josh. Contributor PRs run workflows automatically, so a secret on that path is exfiltratable.

# Posting reviewer findings

Reviewers post no verdict label and no verdict body; the verdict (approve / block) is reported to the organiser, who posts the single bot synthesis review. Pick one path.

**Approve:** post nothing on the PR; report "approve" to the organiser. Do not run `gh pr review`, write a body, or apply a label.

**Block:** post each finding as an inline review comment anchored to `path:line`, via `scripts/swarm/post-review.sh <pr> <verdict-json>` (JSON: `{verdict: "block", commenter, items: [{path, line, body}]}`). Report "block" to the organiser. No prose in the conversation tab, no summary block; findings are line-anchored or they do not exist. Do not hand-roll `gh api .../comments` (wrong endpoint, wrong flags); use the script.

**Self-approval trap:** `gh pr review --approve` on a PR sharing your gh identity is rejected, and the naive fallback `gh pr review --comment` posts a verdict block to the conversation tab. Never do it. On approve, submit no Review; report to the organiser, who posts under a separate identity.

Each submitted Review renders as a conversation-tab block, and the author's mobile review degrades past ~5 blocks. Inline comments attach to the diff and carry no such cost; that is why the verdict lives in the organiser's one synthesis review, not in reviewer bodies.
