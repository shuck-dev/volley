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

- `-s` for the DCO sign-off (`Signed-off-by: ...`). The DCO check blocks challenges without it.
- **Bare Conventional Commit subject.** `<type>: <subject>`. No `[Codename]` prefix or suffix, no `SH-N` prefix, no `(sh-N)` scope. Codename lives in the `Agent-Role` trailer and in the dispatch description, not in the subject.
- `Agent-Role: <role>` trailer, exactly once. The role names the agent type (gdscript-implementer, code-quality, general-purpose, etc.). For Gru, the role is `dispatcher`; the subject still follows the bare Conventional Commit shape (e.g. `chore: bump lint timeout`), no `[Gru]` prefix.
- No `Co-Authored-By:` lines. Volley's swarm uses Agent-Role for attribution; Co-Authored-By creates double counting.

## What goes in the subject

Imperative mood, present tense, lowercase. Conventional Commit type required: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `ci`, `perf`. No file paths, no symptom descriptions, no issue numbers in the subject. Example: `feat: fast timeout tests via custom_step`.

For breaking changes (save wipes, API renames, workflow-input shifts), use `feat!:` or `fix!:` on the subject. Autolabel maps the bang to the `breaking` label and release-drafter groups it under Breaking Changes.

## Issue references

**GitHub issue IDs (`#N`) are the primary surface.** The repo is open source; readers of commits and PRs follow GitHub links, not Linear. Reference the GitHub issue with a bare `#123` (just the number, no leading verb) in the commit body or PR body: GitHub backlinks them, and the branch name (not the body) is what advances the Linear issue on merge. Linear IDs (`SH-N`) are private and never appear in commit messages or PR bodies. The branch name carries the Linear context for internal tooling; that is enough.

The bare reference is the one to reach for. A leading GitHub action-verb on the issue number fires GitHub's own issue-close on merge, which overshoots the Linear issue two states past where the branch-name integration leaves it. See [`designs/ai/lane-semantics.md`](../../../designs/ai/lane-semantics.md).

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

Push the branch with `-u` on first push. Open the challenge ready-for-review (not draft) unless more commits are coming. After `gh pr create`, leave the PR for the maintainer to merge; do not enable auto-merge. The `gh` command names stay literal; the noun for the work in flight is "challenge."

Do not merge yourself. The maintainer merges by hand (Merge when ready).

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
