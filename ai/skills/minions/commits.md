---
name: commits
description: Commit shape every code-writing minion follows. DCO sign-off, role tag in the subject, Agent-Role trailer, no Co-Authored-By. Read before your first commit on a worktree.
---

# Agent commit shape

Every code-writing minion commits like a team member, not a tool.

## The shape

```
git commit -s -m "$(cat <<'EOF'
[<Codename>/<role>] <subject in the imperative mood>

<short body if needed; usually one or two sentences>

Agent-Role: <role>
EOF
)"
```

- `-s` for the DCO sign-off (`Signed-off-by: ...`). The DCO check blocks challenges without it.
- Subject prefix `[<Codename>/<role>]` for minions: codename (Feldspar, Hornfels, Trillian, etc.) plus role (general-purpose, code-quality, etc.). Codename rotates per work unit; role is stable to the agent type.
- Subject prefix for Gru: `[Gru]` only. Gru is the singleton organiser; codename and role are the same and the slash is redundant.
- `Agent-Role: <role>` trailer, exactly once. For Gru: `Agent-Role: organiser`.
- No `Co-Authored-By:` lines. Volley's swarm uses Agent-Role for attribution; Co-Authored-By creates double counting.

## What goes in the subject

Imperative mood, present tense. No file paths, no symptom descriptions, no issue numbers (Linear autolinks the branch name). Conventional-commit prefixes are fine but not required: `[Feldspar/general-purpose] feat: fast timeout tests via custom_step`.

For breaking changes (save wipes, API renames, workflow-input shifts), use `feat!:` or `fix!:` on the subject. Autolabel aliases the bang.

## Hooks

Let lefthook fire on commit. Do not run `lefthook run pre-commit` by hand. If a hook fails, fix the underlying issue and create a new commit; do not amend, do not `--no-verify`.

## Push and merge

Push the branch with `-u` on first push. Open the challenge ready-for-review (not draft) unless more commits are coming. After `gh pr create`, queue auto-merge with `gh pr merge <n> --auto`. The `gh` command names stay literal; the noun for the work in flight is "challenge."

Do not merge yourself. Only Josh applies `approved-human` to release auto-merge.

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
