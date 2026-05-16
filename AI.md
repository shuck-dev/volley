# How AI is used on Volley!

Volley! is built in the open. The repository is public, the design documents are public, the issue tracker is public, the conversations on every pull request are public. The thinking behind that posture, why a new indie studio benefits more from being seen at work than from running a marketing campaign in the dark, lives in the essay [The Case for Open Development](designs/research/the-case-for-open-development.md). Read it for the long view; this page covers one specific question the essay raises and that any reader of the repo deserves a clean answer to: where does AI sit in the project, what does it do, and what does it not do.

The short version. AI is a tool the maintainer uses to write code, generate drafts of internal documentation, and run reviews. It does not author the world, the art, the music, the public voice, or the merge decision. Every change it produces is signed off by a person under the Developer Certificate of Origin, and the history is honest about which agent type produced which commit. The rest of this page is the detail.

## What AI does on the project

The development orchestrator on this project is Claude Code. It dispatches a swarm of small sub-agent specialists (one for GDScript implementation, one for code review, one for documentation tone, one for CI workflows, one for root-cause analysis, and so on) and folds their work back into branches and pull requests. Code, tests, configuration, and most documentation in the repo pass through that pipeline at some point.

Everything those agents produce is treated as a draft from a colleague. The maintainer reads it, edits where needed, sometimes throws it away, and signs off on what lands. Every commit carries a `Signed-off-by:` line under the [Developer Certificate of Origin](https://developercertificate.org); an agent's authored change is committed under the maintainer's name with the legal attestation that the maintainer has the right to submit it. Commits authored by an agent also carry an `Agent-Role:` trailer naming the agent type (`gdscript-implementer`, `code-quality`, etc.) so the history is honest about how the code came to be.

The reasoning for working this way is in the open-development essay. The short version: shipping the practice in public is how a new studio becomes known, and the practice has to include how the work actually gets made.

## What AI does not do

A short list of where AI is deliberately kept out:

- **Narrative and canon.** The world, the protagonist, the language the game uses for itself, all of that is human-authored. Drafts may pass through an agent for sentence-level polish, but the seed and the world-building are the maintainer's. Agent drafts of canon prose have a documented tendency to drift into pretty-sounding nonsense; the rule is that every sentence in canon has to assert something checkable, and that gate is held by a person.
- **Art, music, and sound.** These are commissioned from human artists and composers. The asset license at [ASSETS-LICENSE.md](ASSETS-LICENSE.md) covers the rights side. No generative-AI assets ship in the game.
- **Merge decisions.** Pull requests merge on the maintainer's `approved-human` label. Reviewer agents can apply `zaphod-approved` or `zaphod-blocked` to surface findings, but those are signals, not decisions. The maintainer reads the diff and the playtest before the gate flips.
- **Marketing and community voice.** Devlogs, social posts, replies in issue threads, replies in community spaces, all of that is the maintainer. The "marketing" of this project is the open-development practice itself; an agent ghostwriting the public voice would undo the point.
- **Contributor credit.** Agents are tools, not contributors. The contributor list credits people who land PRs and people whose assets ship. No agent name appears.

## How agent-authored changes show up in the repo

If you read the history, the agent fingerprint is visible:

- Commit subjects follow the Conventional Commits shape (`feat:`, `fix:`, `docs:` and friends) per [CONTRIBUTING.md](CONTRIBUTING.md). Codenames do not appear in subjects.
- Commits carry an `Agent-Role:` trailer naming the agent type that produced the change.
- Pull request bodies are narrative prose written for a human reader, not changelog dumps. If a PR references an issue, it uses the GitHub issue ID (`#123`); Linear IDs (`SH-N`) are private and never appear in commit messages or PR bodies.
- Code style follows [CODE_STYLE.md](CODE_STYLE.md), which captures the project conventions the linters cannot enforce.

A contributor opening a PR is held to the same conventions; the agent pipeline and a human contributor produce work that reads the same way in the history.

## For contributors

You do not need to use AI to contribute. The project welcomes hand-written PRs and treats them the same as agent-authored ones. The conventions in [CONTRIBUTING.md](CONTRIBUTING.md) and [CODE_STYLE.md](CODE_STYLE.md) are what matter; what tool you used to get there is your business.

If you do use AI tools to help draft your contribution, sign your commits with `git commit -s` like anyone else; you are taking responsibility for the work either way.
