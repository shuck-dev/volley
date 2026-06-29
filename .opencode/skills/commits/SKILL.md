---
name: commits
description: Commit shape every code-writing minion follows. Bare conventional commit subject, DCO sign-off, Agent-Role trailer, no Co-Authored-By, no codename in subject. Read before your first commit on a worktree.
---

# Agent commit shape

Every code-writing minion commits like a team member, not a tool. The repo is open source; the subject is a public surface and reads as a normal Conventional Commit.

## The shape

```
git commit -s -m "$(cat <<'EOF'
<type>: <subject in the imperative mood>

<short body if needed; usually one or two sentences>

Agent-Role: <role>
EOF
)"
```

- `-s` for the DCO sign-off (`Signed-off-by: ...`). The DCO check blocks challenges without it. **Let `-s` generate the sign-off.** Git derives `Signed-off-by:` from your user config, so it always matches the author name. Typing it by hand is how the name drifts and DCO fails.
- **Bare Conventional Commit subject.** `<type>: <subject>`. No `[Codename]` prefix or suffix, no `SH-N` prefix, no `(sh-N)` scope. Codename lives in the `Agent-Role` trailer and in the dispatch description, not in the subject.
- `Agent-Role: <role>` trailer, exactly once. The role names the agent type (gdscript-implementer, code-quality, general-purpose, etc.). For Gru, the role is `dispatcher`; the subject still follows the bare Conventional Commit shape (e.g. `chore: bump lint timeout`), no `[Gru]` prefix.
- No `Co-Authored-By:` lines. Volley's swarm uses Agent-Role for attribution; Co-Authored-By creates double counting.

## What goes in the subject

Imperative mood, present tense, lowercase. Conventional Commit type required: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `ci`, `perf`. No file paths, no symptom descriptions, no issue numbers in the subject. Example: `feat: fast timeout tests via custom_step`.

For breaking changes (save wipes, API renames, workflow-input shifts), use `feat!:` or `fix!:` on the subject. Autolabel maps the bang to the `breaking` label and release-drafter groups it under Breaking Changes.

## Issue references

**The GitHub issue number lives in the branch name only.** The repo is open source; readers follow GitHub links, not Linear. The branch is `feature/<gh-number>-<slug>` (the GitHub issue number, no `sh-` prefix, no `gh-` prefix). When a branch covers two issues, chain the numbers: `feature/691-692-slug`. Linear IDs (`SH-N`) are private and appear on no open surface: not the branch, not the title, not the body, not commits, not comments.

**Each surface carries one thing.** The branch name carries the issue number and drives Linear movement. The PR body and commits describe the change. The Linear attachment link is made by hand after the PR opens (see below). With the number living in the branch, the body stays a clean description and the issue link stays deliberate.

Why the branch is the number's only home: a closing verb in a body (`closes`/`fixes`/`resolves #N`) hands GitHub the issue-close on merge, which carries the linked Linear issue to Closed against the manual-merge intent. Keeping every number in the branch makes that form one nobody reaches for. See [`designs/ai/lane-semantics.md`](../../../designs/ai/lane-semantics.md).

**Linear transitions: the Shuck team PR automations move the issue on PR state** (draft open to Dispatched, marked-ready to Challenged, no action on merge so Completed is manual). BUT those automations only fire on a PR that Linear has *linked* to the issue, and Linear forms that link by finding a Linear ID (`SH-N`) in the branch name, PR title, or PR body. A fully GitHub-facing PR with no `SH-N` anywhere is unlinked, so it drives no transition.

The reconciliation, while branches stay GitHub-facing: link the PR yourself. The MCP Linear tools do not expose attachment linking, but the raw GraphQL API does. Script it with `$LINEAR_API_KEY` against `https://api.linear.app/graphql` using `attachmentLinkGitHubPR` with `issueId`, `url`, and a `linkKind` (the `GitLinkKind` enum). `attachmentDelete` drops a link. Do not put `SH-N` on an open surface to get the link. Confirm the link landed with a Linear read; do not assume the PR moved the issue.

**`linkKind` is the relationship, and it is what handles multi-PR.** The enum (matching the UI picker):
- `closes` ("Resolves"), the PR resolves the issue on merge. Use for a single-PR issue.
- `contributes` ("Contributes to"), one of several PRs; moves the issue but does not solo-resolve. **Use this for every PR on a multi-PR issue.**
- `links` ("Related to"), reference only, no status automation.

**Links accumulate; they are the record of related work. Do not prune them.** Every PR that touched an issue stays attached, including closed and superseded ones; that trail is the point. The transition is governed by the `linkKind` (relationship), not by which attachments are present, so a closed PR linked as `contributes` does not need removing. `attachmentDelete` is for a genuinely mistaken link, not for tidying history. The merge automation is an AND across `contributes` PRs (the issue reaches the terminal state when the final one merges), so `contributes` (not `closes`) is what keeps one early merge from completing a multi-PR issue.

Note for the Shuck team specifically: merge is set to no-action, so no `linkKind` completes an issue on merge today (Completed is always manual). The `closes` / `contributes` distinction still matters if that mapping is ever turned on, and `links` vs the others still controls whether the open / ready automations fire at all.

## Branch discipline

- **Never rebase; merge `main` in.** Use `git merge main`, never `git rebase`. If a rebase is genuinely needed, stop and ask Josh. Josh merges challenges, not minions.
- **No amending, no force-push.** Add a new commit on top instead of `--amend`. Don't `push --force` or `--force-with-lease`. Intermediate noise is fine; squash-merge collapses it. Only amend or force-push when Josh explicitly asks.
- **Fresh branch after a challenge merges.** Never pile commits onto a branch whose challenge already merged. If `git push` reports `remote: Create a pull request for '<branch>'` on a branch the minion thought was live, origin deleted it; stop and cut a fresh branch off `origin/main`.

## Hooks

Let lefthook fire on commit. Do not run `lefthook run pre-commit` by hand. If a hook fails, fix the underlying issue and create a new commit; do not amend, do not `--no-verify`.

## Tests after every code change

Run `./scripts/ci/run_gut.sh` after every code change. Iterate until green. Lefthook fires GUT on `git commit`; that is the gate, not a manual sweep.

## ggut runtime expectations

The full GUT suite runs under a few seconds. Post-Vector-Squared budget is a hard 2 seconds, with a CI gate enforcing it. Never set multi-minute Bash timeouts on a `ggut` invocation; if the suite isn't done in 5 seconds something is wrong (test hang, init-order deadlock, infinite loop in production). Investigate the hang, don't extend the timeout. If the test count makes you suspicious, recall: 488 tests in under 2s is the post-rework normal.

Don't background `ggut` to a poll-loop watching a file you didn't write. Run it foreground with a hard 5s cap: `timeout 5 godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit 2>&1 | tail -50`. If it hits the timeout, that's a real hang, not a slow suite.

## Push and merge

Push the branch with `-u` on first push. **Open the challenge as a draft** (`gh pr create --draft`); every challenge opens draft and stays draft. Josh flips it ready when he is choosing to merge; the dispatcher never marks it ready, not even on a clean battle. Draft does not block review: the spot-check and a full reviewer battle run on the draft exactly as on any challenge; ready is only the merge gate, not a review gate. After `gh pr create`, do not enable auto-merge. The `gh` command names stay literal; the noun for the work in flight is "challenge."

Do not merge yourself, and do not flip ready yourself. Both the ready-flip and the merge are Josh's by hand.

## PR title and body shape

The PR is a public surface. Linear is private; the open repo is the audience. Apply on every `gh pr create` and `gh pr edit`.

**Title.** Bare conventional commit: `type: subject`. No `(sh-N)` scope, no `[Codename]` prefix, no GitHub-state words like `(draft)` or `[WIP]` (GitHub already tracks PR state). One example: `docs: per-limb equip design`. Not `docs(sh-404): per-limb equip design (draft)`.

**Body.** Narrative prose. One short paragraph is usually the whole body. No `## Summary` header, no `## Test plan`, no checklist of verification steps. Player-facing verification belongs in the mission's Ride, not in every PR body. AC lives on the Linear issue.

**IDs in body.** Reference GitHub issue/PR numbers (`#346`, Challenge `#403`), never Linear IDs (`SH-211`, `SH-403`). A reader of the open repo cannot follow Linear IDs.

**Trailers.** `Agent-Role: <role>` exactly once. No `Co-Authored-By:`.

## Replying to Josh's review comments

When a fix lands that resolves an inline review comment from Josh, reply to that comment via `gh api repos/.../pulls/<n>/comments/<id>/replies`. Lead with your codename in bold (`**Feldspar**`, `**Hornfels**`, `**Gru**`); name the fix SHA in short form (7 chars); under 30 words. Don't silently push and let the thread hang open.

## What this skill replaces

Consolidates:
- `feedback_agents_commit_like_team.md`
- `feedback_agent_role_trailer.md`
- `feedback_sign_commits_dco.md`
- `feedback_no_amend_no_force.md`
- `feedback_dont_run_hooks_manually.md`
- `feedback_breaking_change_bang.md`
- `feedback_enable_auto_merge_on_create.md`
- `feedback_merge_not_done.md`
- `feedback_never_merge_prs.md`
- `feedback_never_rebase.md`
- `feedback_run_tests_after_changes.md`

It also absorbs the commit-side ground rules (never-rebase, no-amend, no-force, fresh branch after merge, ggut after every code change) that previously lived in `ai/PARALLEL.md`.
