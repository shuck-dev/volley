# Contributing to Volley!

Welcome. Volley! is an idle pong game about a chase for the world volley record, built in the open so anyone who wants to can help shape it. If you are here to fix a bug, ship an animation, sketch a concept, write a piece of dialogue, or dig into a tricky system, thanks for stopping in.

This guide covers the practical parts: picking up a ticket, running the project, submitting a PR, and signing off. For how tickets are shaped and what the labels mean, see [`designs/process/ticket-writing.md`](designs/process/ticket-writing.md) and [`designs/process/labels.md`](designs/process/labels.md).

## Picking up a ticket

Tickets are open. If one catches your eye, start work on it: no claim, no approval, no queue. Opening a draft PR when you have something early to show is the clearest way to let others know you are on it, and it gives maintainers a chance to chime in early.

If you want to flag intent first, a comment saying you are looking at a ticket is always welcome. It does not hold the ticket; anyone else can also start work on it. If two of you end up on the same thing, coordinate in the comments or split the scope. The PR that lands the acceptance criteria is the one that merges, and we will credit anyone whose work fed into it.

Sometimes maintainers will pick up a ticket themselves to hit a deadline. When that happens we will say so in the thread and, where possible, fold any in-progress contributor work into the result.

## Running the project

The project is built in [Godot](https://godotengine.org). Install the editor version listed in `project.godot` (under `config/features`), open the project folder, and you should be playing within a minute.

### Asset setup (Git LFS)

Large binaries under `assets/` and `concepts/` are stored in Git LFS, fetched through a Cloudflare
R2 proxy. One-time setup:

```sh
git lfs install
```

After that, a normal clone fetches `assets/` automatically using the published download key already
baked into `.lfsconfig`:

```
vlfs_dl_448b7e551036da1e613d5a44638fdd2d
```

This key is intentionally public. The proxy enforces a rate limit and per-window byte cap, so
possession of the key cannot exhaust the R2 free tier. Only the upload key (needed to push art)
stays private; ask a maintainer if you need it.

Concept art under `concepts/` is opt-in and not fetched on clone. Pull it when you need it:

```sh
make concepts
```

## Tests and lint

Tests use [GUT (Godot Unit Test)](https://github.com/bitwes/Gut), vendored under `addons/gut/`. Run the suite headlessly:

```sh
godot --headless -s addons/gut/gut_cmdln.gd
```

Lint runs through [lefthook](https://github.com/evilmartians/lefthook) git hooks, which keep `gdformat`, `gdlint`, `codespell`, `gitleaks`, and the GUT suite green on every commit. Install hooks once:

```sh
lefthook install
```

CI runs the same checks on every PR, so whatever passes locally will pass there.

A pre-commit hook also enforces a **500 KB size gate** on staged files. Any binary over that threshold must be tracked via Git LFS rather than committed directly. The hook skips `.import` sidecars (generated config) and files already tracked by LFS. CI runs the same check on every pull request as a backstop for skipped local hooks. If you pull a change that adds or removes hooks, re-run `lefthook install` to pick up the new hook set.

## Submitting a PR

Open the PR against `main`. Branch name format is `<intent>/<gh-issue>-<short-description>`, where `<intent>` matches the ticket's label and `<gh-issue>` is the GitHub issue number. See [`designs/process/labels.md`](designs/process/labels.md) for the full label set and examples.

Reference the issue in the PR body with a bare `#123` (the number on its own). GitHub backlinks the PR and the issue, and the branch name drives the issue's state on merge. Leave any GitHub action-verb off the number: a verb fires GitHub's auto-close, which moves the tracked issue further than the merge should.

**Write the PR description as a short explanation of the change.** Cover what the change does, why it is being made, and any tradeoffs worth flagging. A reader should come away understanding the reasoning behind the change.

**Keep the scope tight.** Stick to the ticket. If you spot something adjacent that needs fixing, open a new issue for it; tight PRs that do one thing land faster and read better in the commit history. When your change does sit on top of a rough shape, reshaping it in the same PR is welcome; see [`designs/process/refactoring.md`](designs/process/refactoring.md) for where that line sits.

**Tone.** Plain descriptive prose, positive framing. Lead with what a thing is and does. Applies to PR descriptions, commit messages, and code comments.

**Code style.** Inline comments explain why; `##` doc-comments describe the public API. The conventions live in [`designs/process/code-style.md`](designs/process/code-style.md).

**What a reviewer looks at:**

- Acceptance criteria from the ticket are met.
- Tests and lint are green.
- The affected scene or system behaves as described.
- Screenshots are attached for visual changes.

Small, friendly PR reviews are the norm. If something needs rework we will say why and suggest a direction.

### How review and merge work

A set of AI reviewers read your PR first. Small fixes land as commits on your branch. Anything else shows up as a short comment on the line it's about. Their overall verdict appears as a single bot review (an approval, or a request-changes if they left comments). It is a heads-up, not the merge decision.

A maintainer then reads the PR and adds `human-approved` to sign off. The PR merges on its own once it has `human-approved` and no open reviewer comments. If you push new commits, `human-approved` comes off so the next push gets a fresh look.

Full list of labels in [`designs/process/labels.md`](designs/process/labels.md).

## Asking questions

The GitHub issue thread is the right place. Decisions live there, future contributors can find them, and maintainers read everything. No question is too small.

## Commit messages

We follow [Conventional Commits](https://www.conventionalcommits.org) so the history reads cleanly and the changelog can write itself. The first line is `<type>: <subject>`, in the present tense and lowercase. The types you will reach for most are `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `ci`, and `perf`.

```
feat: ascend back to the lane via physics after walking on
```

When a change breaks compatibility (a save format wipe, a public API rename, a workflow input shift, anything a downstream reader needs to act on), add `!` after the type. The bang is what our autolabeller picks up, and what surfaces in the squash-merge commit and the changelog so the people who care can find it.

```
feat!: drop floor_y from TimeoutConfig; descent grounds on physics
```

Aim for a subject under about seventy characters. If there is more to say, a short body of one or two sentences explaining the why goes a long way; reviewers love the context.

## Sign your commits (DCO)

We use the [Developer Certificate of Origin](https://developercertificate.org) instead of a Contributor License Agreement. It is a lightweight way of saying "I wrote this, or I have the right to submit it under the project's license." Every commit needs a `Signed-off-by:` line, added automatically with:

```sh
git commit -s -m "your message"
```

Which produces:

```
Signed-off-by: Your Name <your@email.com>
```

Use your real name and a valid email. CI checks this so contributions keep a clean provenance trail.

## Credit and what you get out of contributing

Everyone who lands a PR is credited in the game's contributor list. Beyond that, contributing here is a chance to:

- See your work ship in a real game people play.
- Work against a full-bodied design documentation set, not a blank brief.
- Build out the parts of game development you care about most (systems, art, music, writing, design, audio) with a maintainer who will review carefully and explain reasoning.
- Join a warm, considered project that takes its craft seriously.

If there is something specific you want to get out of contributing (a piece for your portfolio, a credit for a grant application, a reference letter, experience in a particular system), say so in the ticket thread and we will work with you to make it happen.

## Inbound license

By contributing:

- **Code contributions** are licensed under the [MIT License](LICENSE), the same as the rest of the codebase.
- **Asset contributions** (art, music, sound effects, narrative text) grant Josh Hartley a perpetual, worldwide, royalty-free license to use, modify, and distribute the asset as part of the commercial release and any derivative products. See [ASSETS-LICENSE.md](ASSETS-LICENSE.md).
- **Design doc contributions** (in `designs/`) are licensed under CC-BY 4.0; see [`designs/LICENSE`](designs/LICENSE).

Everyone who lands a contribution is added to the game's credits.

Contributors supplying assets under a separate work-for-hire agreement are covered by that agreement, not this policy.

---

Thanks for being here. However large or small your contribution ends up being, it is genuinely appreciated.
