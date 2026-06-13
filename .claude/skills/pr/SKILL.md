---
name: pr
description: Writing a GitHub PR body (short narrative prose, no changelog, no test plan, no local aliases, flag new secrets). Read before writing a PR body or running `gh pr create`/`gh pr edit`. Reviewer-output mechanics live in the reviewers skill, not here.
---

# Writing a PR body

Explain the change to a reviewer who was not in the conversation. Justify the work; do not recite the diff.

One short paragraph, or a 3-5 bullet list: what the PR does (one sentence), why (only if non-obvious from the issue title), any manual follow-up or risk (only if present). If the change has real themes, a subsection of prose each. Then stop.

The deeper rationale (rejected alternatives, full reasoning) goes in the committed doc or the code, not the body. Detail flows to the most durable surface: commit subject, then body, then doc/code. When a PR ships a design or spike doc, the body points at it. Test each sentence: explaining the change (keep) or relitigating the decision (cut, it belongs in the doc)?

Cut: session history, rationale duplicating the issue AC, meta-commentary, a `## Test plan` or any verification checklist (the Ride covers it), a verb-bullet Summary (that is the diff talking).

Tone: professional prose, complete sentences, past tense. No casual phrasing or fragments, no em dashes (use colons/commas), no AI-register words ("delve", "leverage", "robust"), no scope understatement ("small game").

References: the branch name carries the GitHub `#N` and drives the issue link; the body describes the change; the Linear link is made by hand after the PR is up. Public surfaces stay GitHub-facing, so Linear `SH-N` stays private (`feedback_design_docs_subject_first_github_ids`). Why the branch is the number's only home: a `closes #N` verb hands GitHub the issue-close on merge, carrying the Linear issue to Closed against the manual-merge intent, and keeping every number in the branch makes that form one nobody reaches for.

Aliases: spell out Josh's zsh aliases on every public surface (body, commit, repo docs): `./scripts/ci/run_gut.sh` not `ggut`, `git checkout -b` not `gcb`. A contributor or CI runner does not have them.

Secrets: if the diff adds a `pull_request*` (or post-PR `workflow_run`) workflow referencing `${{ secrets.* }}` beyond `GITHUB_TOKEN`, stop and flag it in the body and to Josh. Contributor PRs run workflows automatically, so a secret on that path is exfiltratable.

The challenge this skill describes is what a reviewer battle runs against: running that pass lives in [`battle`](../battle/SKILL.md). The memory branch for challenge-description discipline is [[feedback_pr_description_brevity]] under [[trunk_dev_cycle]].
