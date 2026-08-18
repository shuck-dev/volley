# Labels

Every ticket carries one intent label that names its discipline. Labels drive ticket shape (see [Ticket Writing](ticket-writing.md)) and branch naming (see [Contributing](../../CONTRIBUTING.md)); the branch prefix follows the label.

## Taxonomy

The label set is trimmed to the intents in real use. Each discipline group still exists in Linear; several now hold a single leaf or none.

| Discipline   | Labels                       |
| ------------ | ---------------------------- |
| **tech**     | `spike`, `feature`, `bug`    |
| **art**      | `concept`, `asset`           |
| **audio**    | `sfx`                        |
| **writing**  | `narrative`                  |
| **design**   | `spec`                       |

Pick the label whose discipline and intent best match the work.

---

## Labels in detail

### Tech

- **`spike`**: explore a technical unknown to inform an implementation choice. Timeboxed investigation producing a written recommendation.
- **`feature`**: build new capability into the game.
- **`bug`**: restore intended behaviour where the system has drifted.

### Art

- **`concept`**: explore a visual direction before committing to production. Output: concept work, options, a decision.
- **`asset`**: produce a finalised visual element for game integration. Done when integrated in-engine.

### Audio

- **`sfx`**: add or change a sound effect in the game.

### Writing

- **`narrative`**: author narrative docs, character profiles, outlines, lore.

### Design

- **`spec`**: spec out how a feature should work, working an open design question toward a realised idea.

---

## Choosing the right label

1. **Which discipline owns the work?** Tech, art, audio, writing, design.
2. **What kind of output?**
   - `spec` if the answer to an open design question is not yet known.
   - `feature`, `asset`, `sfx`, or `narrative` if the output is a concrete deliverable.
   - `bug` if the system has drifted from intended behaviour.
   - `spike` for a timeboxed technical investigation.
3. The label is the intersection.

When in doubt between `spike` and `feature`: is there a committed output (feature) or an open question (spike)? Between `spec` and `feature`: is the work answering how something should behave (spec) or building it (feature)?

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
- `spec/127-serve-window-shape`

Name the branch from the ticket's intent label and GitHub issue number.

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
