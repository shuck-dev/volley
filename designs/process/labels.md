# Labels

Every ticket carries one intent label that names its discipline and its tier. Labels drive ticket shape (see [Ticket Writing](ticket-writing.md)), branch naming (see [Contributing](../../CONTRIBUTING.md)), and how `new-branch.sh` sets the branch prefix.

## Taxonomy

|              | Explore       | Produce   | Evolve     |
| ------------ | ------------- | --------- | ---------- |
| **tech**     | `spike`       | `feature` | (`bug` restores) |
| **art**      | `study`       | `asset`   | `revision` |
| **music**    | `concept`     | `cue`     | `rework`   |
| **writing**  | `voice`       | `draft`   | `rewrite`  |
| **design**   | `discovery`   | -         | `tune`     |
| **audio**    | -             | `sfx`     | -          |

Three intents plus `bug` as its own shape. Pick the label whose discipline and tier best match the work.

---

## Labels in detail

### Tech

- **`spike`**: explore a technical unknown to inform an implementation choice. Timeboxed investigation producing a written recommendation.
- **`feature`**: build new capability into the game.
- **`bug`**: restore intended behaviour where the system has drifted.

### Art

- **`study`**: explore a visual direction before committing to production. Output: concept work, options, a decision.
- **`asset`**: produce a finalised visual element for game integration. Done when integrated in-engine.
- **`revision`**: evolve an existing asset as the creative direction develops.

### Music

- **`concept`**: explore a musical direction before committing to a composed cue.
- **`cue`**: produce a finished music piece ready for integration.
- **`rework`**: evolve an existing music piece as the creative direction develops.

### Writing

- **`voice`**: explore the voice and tone before committing to written content. Output: a bible entry a draft can cite.
- **`draft`**: produce new written content ready for integration.
- **`rewrite`**: evolve existing written content as the creative direction develops.

### Design

- **`discovery`**: work through an open design question toward a realised idea.
- **`tune`**: refine the balance or feel of an established system.

### Audio

- **`sfx`**: add or change a sound effect in the game.

---

## Choosing the right label

1. **Which discipline owns the work?** Tech, art, music, writing, design, audio.
2. **Which tier?**
   - **Explore** if the answer is not yet known. Spike, study, concept, voice, discovery.
   - **Produce** if the output is a concrete deliverable. Feature, asset, cue, draft, sfx.
   - **Evolve** if iterating on something that already exists. Revision, rework, rewrite, tune.
   - **Bug** if the system has drifted from intended behaviour.
3. The label is the intersection.

When in doubt between `spike` and `feature`: is there a committed output (feature) or an open question (spike)? Between `asset` and `revision`: does the thing exist yet?

---

## `good first issue`

Applied by contributors themselves to tickets that turned out to be approachable for newcomers. Not a replacement for the intent label; sits alongside it.

---

## Branch prefixes

The intent label is also the branch prefix:

```
<intent>/<gh-issue>-<short-description>
```

Examples:

- `feature/123-timeout-and-equip`
- `bug/124-ball-stuck-on-serve`
- `asset/125-main-character-walk-cycle`
- `spike/126-cross-window-drag-drop`
- `cue/127-menu-loop`

Use `./new-branch.sh SH-N` to create a branch from a Linear ticket; it reads the ticket's label and sets the prefix automatically.

---

## PR workflow labels

Separate from intent labels, a small set of GitHub labels are applied automatically to **pull requests** by the CI and review tooling. They describe the PR's state at a glance in the repo's PR list.

### AI review state

- **`ai-approved`**: specialist reviewers from `.claude/agents/` passed the PR with no judgment items.
- **`action-required`**: at least one specialist reviewer posted a line-anchored judgment comment. Blocks merge.

Applied by the orchestrator after `gh pr create` per the step 4 flow in `ai/PARALLEL.md`. These reflect AI reviewer output only; `ai-approved` is an advisory signal, not a merge decision.

### Human review state

- **`human-approved`**: Josh has reviewed and signed off. Required for merge.

### Merge gate

Two required status checks drive the merge gate:

- **`human-approved`**: succeeds only when the `human-approved` label is present.
- **`no-action-required`**: succeeds only when the `action-required` label is absent.

Both must pass before auto-merge fires. The checks are posted by `.github/workflows/approval-gate.yml` on label events.

### Merge state

- **`has-conflicts`**: applied manually when a branch needs to merge `main` in but conflicts block the merge. Remove once the conflict is resolved. Previously applied by the auto-update sweep workflow; that workflow is gone now that GitHub's native merge queue handles pre-merge rebasing on `main`.

### Dependency updates

- **`dependencies`**: the PR updates a third-party package. Applied by Dependabot.
- **`github-actions`**: the dependency is a GitHub Action.
- **`python`**: the dependency is a Python package from `requirements-dev.txt`.

Pinned in `.github/dependabot.yml` per ecosystem.
