# Labels

Every ticket carries one intent label that names its discipline and its tier. Labels drive ticket shape (see [Ticket Writing](ticket-writing.md)), branch naming (see [Contributing](../../CONTRIBUTING.md)), and how `new-branch.sh` sets the branch prefix.

## Taxonomy

|              | Explore       | Produce   | Evolve     |
| ------------ | ------------- | --------- | ---------- |
| **tech**     | `spike`       | `feature` | (`bug` restores) |
| **art**      | `study`       | `asset`   | `revision` |
| **music**    | `concept`     | `cue`     | `rework`   |
| **writing**  | -             | `draft`   | `rewrite`  |
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
   - **Explore** if the answer is not yet known. Spike, study, concept, discovery.
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

The reviewer verdict is not a label. Specialist reviewers from `.claude/agents/` post inline findings and report their verdict to the organiser, which posts one bot synthesis review every review round under `shuck-volley-bot[bot]` via `.github/workflows/bot-review.yml`: an approval on a clean pass, request-changes if any reviewer blocked. That review is an advisory signal, not a merge decision. A branch that conflicts with `main` is handled the same way, by a bot request-changes noting the conflict, not by a label.

> **About the name.** "Zaphod" is the pan-galactic president from *The Hitchhiker's Guide to the Galaxy*: a two-headed alien whose extra head was added "to do all the lying, swearing and lounging about." The `zaphod-*` family now collects only the bot-applied dependency-bump labels under one multi-headed figure. The leading `z` is also a sort hack: GitHub's label picker uses the Unicode Collation Algorithm, which treats most punctuation and emoji as primary-ignorable, so the only reliable way to push a label to the bottom of the picker is a text prefix that sorts late alphabetically. `z*` does that; `zaphod-*` happens to do that AND name the labels.

### Merge gate

The required status checks are `Tests` and `Lint`. The maintainer reviews and merges by hand (Merge when ready); that manual merge is the approval. The agent reviewer verdict (the bot synthesis review) is attribution, not a required check. GitHub's native merge queue handles pre-merge rebasing on `main`.

### Dependency updates

- **`zaphod-dep`**: the PR updates a third-party package. Applied by Dependabot.
- **`zaphod-dep-action`**: the dependency is a GitHub Action.
- **`zaphod-dep-pip`**: the dependency is a Python package from `requirements-dev.txt`.

Pinned in `.github/dependabot.yml` per ecosystem. The `zaphod-` prefix groups every bot-applied label together at the bottom of the picker, Dependabot is treated as another head of the same Zaphod that handles AI review.
