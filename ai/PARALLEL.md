# Parallel Processing Coordination: Volley!

Live scratchpad for parallel agent work. One agent per Linear ticket. Log progress in the Activity Log at the bottom.

---

## How to use this doc

1. **Claim a ticket.** Every branch must carry its Linear ticket ID. Chore/infra with no SH-N: file first via `./scripts/dev/new-ticket.sh "<title>"` (Backlog, Feature, Josh-assigned, estimate 0, auto-slotted into the active cycle). Branch name: `sh-<N>-<slug>`. Add a row to the Active table, then commit the claim on the branch (not on main).
2. **Cycle placement.** If the claimed ticket has no cycle, move it into the current active cycle: `mcp__linear__list_cycles(teamId, type: "current")` → `mcp__linear__save_issue(id, cycleId)`. Skip if no active cycle.
3. **Log progress.** One terse line per meaningful step to the Activity Log: `[SH-XX] <agent>: <what happened>`.
4. **Sync before opening and before every later push.** `git fetch origin main && git merge origin/main`, resolve, re-run `./scripts/ci/run_gut.sh`, push. Repeat any time you resume work or before asking Josh to merge. `git rev-list --count HEAD..origin/main` = "behind by N".
5. **Open PR, dispatch reviewers.** After `gh pr create`, dispatch matching specialists from `.claude/agents/` in parallel (background agents), by changed path:
   - `**/*.gd` → `code-quality`, `gdscript-conventions`, `test-coverage`
   - `**/*.tscn` or `**/*.tres` → `godot-scene`
   - diff contains `connect(`, `emit(`, `tree_exit`, or a new autoload → `signals-lifecycle`
   - `.github/**` → `ci-and-workflows`
   - `export_presets.cfg`, `project.godot`, or `**/*.import` → `asset-pipeline`
   - `**/*.md` → `docs-and-writing`

   Each specialist splits findings:
   - **Mechanical fixes** (typos, dead code, obvious bugs, style): commit on the PR branch.
   - **Everything else**: short line-anchored review comments following [Conventional Comments](https://conventionalcomments.org/) (`praise:`, `nitpick:`, `suggestion:`, `issue:`, `question:`, `thought:`, `chore:`, `note:`, with decorators like `(non-blocking)`). **One idea per comment, two sentences max.** If it needs more context, open an issue and link from the comment.

   After all specialists finish: clean → `gh pr edit <N> --add-label 'zaphod-approved'`. Any comments → `--add-label 'zaphod-blocked'` instead. `zaphod-blocked` supersedes `zaphod-approved`: if a later specialist finds blocking issues, add `zaphod-blocked` and the race-resolver workflow strips the earlier `zaphod-approved`. A later clean pass never downgrades a prior blocked verdict; the blocked stands until a new commit triggers a fresh review. No `LGTM` or summary comments.

   **One review per agent's pass, many comments inside.** Each reviewer agent's pass posts a single GitHub Review wrapping that agent's findings, not N standalone comments (SH-326, sharpened SH-327). When the fan-out dispatches N reviewers, each agent posts its own Review; six reviewers in flight produce six Reviews on the PR. The Reviews API (`pulls/<N>/reviews`) groups findings under one review header and one notification. Build the JSON payload and pipe it via `--input -` so reviewer text never interpolates into the shell:

   ```bash
   jq -n --arg sha "<sha>" '{
     event: "COMMENT",
     commit_id: $sha,
     body: "",
     comments: [
       {"path": "<file>", "line": <line>, "side": "RIGHT", "body": "**<commenter>**\n\n<type>: <body>"},
       {"path": "<file>", "line": <line>, "side": "RIGHT", "body": "**<commenter>**\n\n<type>: <body>"}
     ]
   }' | gh api -X POST repos/shuck-dev/volley/pulls/<N>/reviews --input -
   ```

   The review `body` stays empty; top-level summary comments are forbidden per `ai/skills/minions/reviewers.md`. The Review wrapper is just the grouping container; all content lives in the `comments` array. `<commenter>` is a rotating codename for implementation agents (`trillian`, `abe`, `manny`), the role name for review specialists (`ci-and-workflows`, `docs-and-writing`, `code-quality`, etc.), or `josh` for Josh. The `\n\n` in each comment body sits inside JSON, so jq emits it as a real newline and the bold name renders on its own line above the Conventional Comment.

   **Replies to an existing thread** stay on the comments endpoint, since a reply anchors to one prior comment rather than opening a new review:

   ```bash
   gh api -X POST repos/shuck-dev/volley/pulls/<N>/comments/<comment-id>/replies \
     -f body=$'**<commenter>**\n\nresolved: <body>'
   ```
6. **Hand off.** Re-sync against main, then report the PR to Josh. Don't flag comments in chat; the PR is the source of truth.
7. **Block or spin.** Loop on the same issue twice → escalate (see below). Do not try a third variant silently.

**Follow-up review** (Josh asks for another pass on an existing PR): dispatch a fresh reviewer, post all findings as a single Review wrapping line comments using the template above. If nothing to say, post nothing. Do not auto-apply fixes on follow-ups; Josh responds inline or marks threads Resolved.

**Human verdict labels.** Josh's review applies one of two mutually exclusive labels: `approved-human` (sign-off, required for merge) or `action-required-human` (address comments before merge). Both strip on every new commit, so pushing a fix naturally clears the blocker and Josh re-verdicts on the next pass. The `Human Approved` merge-queue check fails with a "Changes requested" message whenever `action-required-human` is present and fails with a "Needs human review" message when neither label is set. Only Josh may apply either label; the approver-check workflow strips unauthorised applications.

---

## Ground rules

- **One ticket, one agent, one branch, one worktree.** Never two agents in the same file. Check the Active table's "Files touched" column before claiming. Sub-agents modifying the repo must use `isolation: "worktree"`.
- **Worktree cleanup on merge.** After a PR merges: `git worktree remove ../volley-sh-N && git branch -D sh-N-...`. Alive agent is responsible; otherwise periodic `git worktree list && git worktree prune`.
- **Never rebase; merge main in.** Use `git merge main`, never `git rebase`. If a rebase is genuinely needed, stop and ask Josh. Josh merges PRs, not agents.
- **No amending, no force-push.** Add a new commit on top instead of `--amend`. Don't `push --force` or `--force-with-lease`. Intermediate noise is fine; squash-merge collapses it. Only amend/force when Josh explicitly asks.
- **Fresh branch after a PR merges.** Never pile commits onto a branch whose PR already merged. If `git push` says `remote: Create a pull request for '<branch>'` on a branch you thought was live, origin deleted it; stop and cut a fresh branch off `origin/main`.
- **`./scripts/ci/run_gut.sh` after every code change.** Iterate until green. Lefthook fires on `git commit`; don't invoke it manually.
- **Merge queue serialises main.** Clicking "Merge when ready" pulls the PR into a `merge_group` ref, re-runs lint+test against `main + PR`, then fast-forwards main. The pre-PR `git merge origin/main` still matters: the queue catches mechanical staleness, not semantic conflicts.
- **Godot tool discipline.** Prefer GodotIQ MCP tools over raw file ops. Never delete-and-rebuild scenes; `node_ops` + `save_scene` for `.tscn`. Godot 4 quirks live in [`godot-quirks.md`](godot-quirks.md).
- **Commit subjects.** `[SH-<N> ]<type>: <subject>` is the convention, not a gate. Common types: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `style`, `perf`, `ci`, `build`, `revert`. The `prepare-commit-msg` hook auto-prepends the SH-XXX prefix from the branch; use `git commit -s` to sign off.
- **Engineer PRs to merge in any order.** Each PR stands alone against current main. Combine related changes sharing a file rather than splitting them. Avoid "depends on #X".
- **Verify, don't assume.** Every change needs evidence: tool output or tests, not "looks correct".

---

## Godot session tiers

Pick the lowest tier that answers the question.

| Tier | Scope | Parallelism | Editor? |
|---|---|---|---|
| **0: Static** | `run_gut.sh`, `validate`, `file_context`, `signal_map`, `impact_check`, `.gd` edits, grep, read | High, headless | No |
| **1: Scene edits** | `node_ops`, `build_scene`, `save_scene`, `placement`, `scene_map`, `spatial_audit` | Serial, or parallel via worktrees | Yes, per worktree |
| **2: Runtime** | `run(play)`, `state_inspect`, `verify_motion`, `screenshot`, `input`, `ui_map`, `perf_snapshot` | Single-agent, exclusive | Yes, exclusive |

**Default Tier 0.** Josh's no-playtest rule.

**Tier 1** is fine when scene work is genuinely required; spawn sub-agents with `isolation: "worktree"` if another Tier 1 agent is on overlapping files. First boot of a fresh worktree re-imports (~1 min).

**Tier 2 is by request.** Agent must ask Josh before running the game. OK: reproducing a runtime-only bug, verifying a Tier 1 scene change loads clean, measuring a perf regression code review can't catch. Not OK: "double-checking". Format in the Activity Log with `RUNTIME REQUEST` prefix:

```
RUNTIME REQUEST [SH-XX] <agent>: <one-line reason>
  What I'll verify: <concrete claim>
  How I'll verify: <state_inspect path or verify_motion call>
  Why static checks are insufficient: <one sentence>
```

Do not `run(play)` until Josh answers.

---

## Escalate early

Escalate the **first** time you hit any of these; don't try a third variant silently:

- **Loop detected**: two genuinely different strategies on the same failure.
- **Scope ambiguity**: AC is met but spirit unclear, or the ticket touches a system not explainable from design docs alone.
- **Cross-ticket collision**: your change forces edits in a file another active stream owns.
- **Design gap**: code and design doc disagree; ticket doesn't pick a side.
- **External shift**: Godot bug, addon regression, mid-task API change.

Format in the Activity Log:

```
ESCALATE [SH-XX] <agent>: <one-line summary>
  Tried: <strategy 1> → <evidence>
  Tried: <strategy 2> → <evidence>
  Question: <what you need Josh to decide>
```

---

## Releases

See [`release-playbook.md`](release-playbook.md). Agents read it only when Josh asks for a release.

---

## Active (in flight)

The Active table on `origin/main` is the source of truth. A fresh worktree reads whatever commit it branched from, so sibling agents' claim rows only appear after their pre-push sync merges their claim into `main` and you pull it in. If the table looks empty in your worktree, fetch `origin/main` before trusting it.

| Agent | Ticket | Branch | Files touched | Started | Notes |
|---|---|---|---|---|---|
| Glottis | SH-80 | sh-80-tech-art-pipeline | designs/art/tech-pipeline.md, designs/art/INDEX.md | 2026-04-21 | Tech art pipeline spike |
| Trillian | SH-120 / SH-123 | sh-120-sh-123-workflow-hardening | .github/workflows/*.yml | 2026-04-21 | paired dispatch: per-job permissions + verify SHA pins |
| Riebeck | SH-88 | sh-88-ball-speed-tiers-and-physics-ceiling | designs/01-prototype/20-ball-speed-tiers.md | 2026-04-21 | spike: tier system + 1800 px/s physics ceiling |
| Solanum | SH-83 | sh-83-ball-dynamics-design-spike | designs/01-prototype/21-ball-dynamics.md | 2026-04-21 | spike: ball physics model answers to seven questions |
| Feldspar | SH-107 | sh-107-court-bounds-and-miss | designs/01-prototype/08-court-bounds.md | 2026-04-21 | spike: bounds, miss, rest, upgrade path |
| Ford | SH-169 | sh-169-prefix-pr-comments-with-commenter-name | ai/PARALLEL.md, ai/swarm/README.md, scripts/swarm/post-review.sh | 2026-04-21 | commenter-name prefix on PR comments |
| Slartibartfast | SH-100 | feature/sh-100-shop-arrivals-inactive | tests/integration/test_shop_arrivals_inactive.gd, ai/PARALLEL.md | 2026-04-23 | shop arrivals land inactive on rack |
| Norbert | SH-326 | feature/sh-326-reviewers-post-one-review-wrapping-many-comments | ai/PARALLEL.md, ai/skills/minions/reviewers.md | 2026-04-28 | reviewers post one Review wrapping many comments |
| Manny | SH-287 | feature/sh-287-drag-drops-validated-by-body-projection | scripts/items/{ball_drag_controller,item_definition,drop_target}.gd, scripts/items/drop_targets/*.gd, scripts/shop/{shop,shop_item}.gd, resources/items/{base_ball,training_ball}.tres, tests/unit/items/test_drop_targets.gd, tests/unit/items/test_ball_drag_controller_sh287.gd, tests/integration/test_shop_drag_drop.gd | 2026-04-28 | DropTarget interface + body-projection refactor; SH-320 closed |
| Kevin | SH-327 | feature/sh-327-sharpen-reviewer-canon-one-review-per-agent | ai/PARALLEL.md, ai/skills/minions/reviewers.md | 2026-04-28 | sharpen "one review per agent's pass" wording |

## Done (recent)

| Agent | Ticket | PR | Merged | Notes |
|---|---|---|---|---|

## Blocked / escalated

| Ticket | Agent | Reason | Raised | Resolution |
|---|---|---|---|---|
| _(none)_ | | | | |

---

## Activity log

Newest at top. One line per event.

```
[SH-327] kevin: claimed; sharpening "one review per pass" so it cannot be misread as one Review across the whole fan-out
[SH-287] manny: claimed; DropTarget interface + CourtDropTarget body projection + RackDropTarget + ShopDropTarget + VenueDropTarget; expansion-ring fallback wired; ItemDefinition.at_rest_shape authored on base_ball/training_ball; SH-320 covered by spawn_purchased_at hand-off
[SH-326] norbert: claimed; replacing per-comment template with one-Review-many-comments canon in PARALLEL.md and reviewers.md
[SH-100] slartibartfast: claimed; SH-96 activate/deactivate and SH-99 rack display already land the behavior, adding integration tests to pin shop->rack and dev-panel purchase flows
[SH-80] glottis: claimed; drafting tech-pipeline.md partner doc to the bible
[SH-88] Riebeck: claim; drafting ball speed tier design doc
[SH-83] Solanum: claimed; spike doc drafted at designs/01-prototype/21-ball-dynamics.md (slot 20 taken by SH-88)
[SH-120/SH-123] Trillian: claimed paired dispatch; per-job permissions landed, SHA pins verified across all workflows
[SH-107] feldspar: claimed spike; validating 08-court-bounds.md against ticket open questions
[SH-169] Ford: claimed; name-prefix rule landed in PARALLEL.md §5, swarm README, post-review.sh
[init] scratchpad reset on cycle #3 open
```
