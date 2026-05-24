# How AI is used on Volley!

AI is a tool the maintainer uses to write code, generate drafts of internal documentation, and run reviews. It does not author the world, the art, the music, the voice, or the merge decision. Every change it produces is signed off by a person under the Developer Certificate of Origin, and the history names which agent type produced which commit.

## What AI does on the project

The development orchestrator is Claude Code. It dispatches a swarm of small sub-agent specialists (one for GDScript implementation, one for code review, one for documentation tone, one for CI workflows, one for root-cause analysis, and so on) and folds their work back into branches and pull requests. Code, tests, configuration, and most documentation in the repo pass through that pipeline at some point.

Everything those agents produce is treated as a draft from a colleague. The maintainer reads it, edits where needed, sometimes throws it away, and signs off on what lands. Every commit carries a `Signed-off-by:` line under the [Developer Certificate of Origin](https://developercertificate.org); an agent's authored change is committed under the maintainer's name with the legal attestation that the maintainer has the right to submit it. Commits authored by an agent also carry an `Agent-Role:` trailer naming the agent type (`gdscript-implementer`, `code-quality`, etc.) so the history shows how a change came to be.

## What AI does not do

A short list of where AI is deliberately kept out:

- **Narrative and fiction.** The world, the protagonist, the language the game uses for itself: all human-authored. Drafts may pass through an agent for sentence-level polish, but the seed and the world-building are the maintainer's. Agent drafts of narrative prose have a documented tendency to drift into pretty-sounding nonsense; the rule is that every sentence in fiction has to assert something checkable, and that gate is held by a person.
- **Art, music, and sound.** Commissioned from human artists and composers. The asset license at [ASSETS-LICENSE.md](ASSETS-LICENSE.md) covers the rights side. No generative-AI assets ship in the game.
- **Merge decisions.** Pull requests merge on the maintainer's `approved-human` label. Reviewer agents can apply `zaphod-approved` or `zaphod-blocked` to surface findings, but those are signals, not decisions. The maintainer reads the diff and the playtest before the gate flips.
- **Marketing and voice.** Devlogs, social posts, replies in issue threads, replies in community spaces: all the maintainer. The reasoning lives in the open-development essay; an agent ghostwriting the voice would undo the point.
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
