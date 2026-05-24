# Memory System Improvements

Options for improving Claude Code's per-project memory at `~/.claude/projects/<project>/memory/`. Captured 2026-05-24. Background reading for the ticket on memory triggers and auto-consolidation.

## TL;DR

Three highest-leverage moves, in order:

1. **Install `dream-skill`** (or fork its 4-phase consolidation skill). Direct fix for the MEMORY.md-past-200-lines pain (currently 372 lines) and for duplication / conflict drift. ~30 min setup; runs automatically on a 24h schedule via Stop hook. ([grandamenium/dream-skill](https://github.com/grandamenium/dream-skill))
2. **Convert the highest-value memory rules into Claude Code Skills** with sharp YAML `description:` triggers. Skills are description-loaded at session start and full-content loaded on intent match; native fix for "triggers don't fire" because Anthropic's matcher reads `description` against every prompt automatically. ([Anthropic skills docs](https://code.claude.com/docs/en/skills); [practical guide](https://dev.to/muhammad_moeed/claude-code-skills-a-practical-guide-for-2026-3f6p))
3. **Extend the existing `UserPromptSubmit` hook into a topic-router** that greps the prompt for keywords (ticket / linear / commit / battle / narrative / negotiation / addepar) and injects only the relevant subset of MEMORY.md lines as `additionalContext`. ~2 hours of shell. Solves the trigger-miss problem for rules that don't justify their own Skill. ([hooks reference](https://code.claude.com/docs/en/hooks))

Cumulative cost: an afternoon. Cumulative benefit: addresses all five observed pain points (silent trigger miss, over-200-line truncation, duplication, manual restructuring, edge conflicts).

## Ranked options

| # | Option | What it does | Cost | Pain points addressed | Risk | Citation |
|---|---|---|---|---|---|---|
| 1 | `dream-skill` (or self-rolled 4-phase consolidator) | Stop hook flags `/dream` every 24h; agent reads sessions, merges duplicates, rebuilds MEMORY.md under 200 lines | ~30 min | duplication, >200 lines, manual restructure, edge conflicts | Low. Modifies memory only; gitted dir means roll-back is `git reset` | [GitHub](https://github.com/grandamenium/dream-skill) |
| 2 | Promote ~10 highest-value rules to Skills | Each rule becomes `~/.claude/skills/<name>/SKILL.md`; description triggers Claude to load body on relevant prompts | 2-4 hr | trigger miss for high-value rules | Low. Skills are additive, don't break memory | [Anthropic docs](https://code.claude.com/docs/en/skills); [Nimbalyst guide](https://nimbalyst.com/blog/claude-code-skills-guide/) |
| 3 | Topic-router `UserPromptSubmit` hook | Shell script greps prompt, `additionalContext` injects matched MEMORY.md subset (10K char cap) | 2 hr | trigger miss for tail rules | Medium. False positives inject noise; false negatives still miss. Pairs well with Skills, doesn't replace | [hooks](https://code.claude.com/docs/en/hooks) |
| 4 | Split MEMORY.md into per-domain index files (linear.md, narrative.md, swarm.md, etc.) loaded via path-scoped CLAUDE.md or scoped rules | One ~50-line top index loaded always; domain indices loaded by `SessionStart` hook based on cwd or branch | 3-5 hr | >200 lines, partially trigger miss | Medium. Adds files to keep in sync; double-source-of-truth risk | [Parreo Garcia on rules](https://joseparreogarcia.substack.com/p/how-claude-code-rules-actually-work) |
| 5 | `claude-mem` MCP server | SQLite-backed auto-capture of sessions, compresses + retrieves on next session | 15 min install | Cross-session continuity, not the listed pains | High. Known token-burn issue #618; "uses all my tokens in <10 messages" | [Termdock review](https://www.termdock.com/blog/claude-mem-persistent-memory-claude-code); [Augment Code](https://www.augmentcode.com/learn/claude-mem-persistent-memory-claude-code) |
| 6 | Basic Memory MCP server | Markdown-backed memory with hybrid full-text + vector search | 1-2 hr | trigger miss via semantic retrieval | Medium. New tool surface, embedding step on every read, replaces a system already running in git | [ChatForest](https://chatforest.com/guides/best-memory-mcp-servers/) |
| 7 | Engram MCP server | Single Go binary, SQLite, full-text only, coding-agent focused | 15 min | trigger miss for technical rules | Medium. Opaque SQLite; loses the human-editable markdown advantage | [ChatForest](https://chatforest.com/guides/best-memory-mcp-servers/) |
| 8 | mem0 / Zep / Memento knowledge-graph servers | Vector or graph-DB-backed semantic memory | 2-8 hr | trigger miss | High. Cloud-hosted (mem0), or Neo4j infra (Memento); private info leaks become a surface | [mem0 blog](https://mem0.ai/blog/mcp-knowledge-graph-memory-enterprise-ai) |
| 9 | Per-rule tagged retrieval via slash command (`/recall <topic>`) | Manual on-demand load | 1 hr | None not already covered via Read | Low | n/a |
| 10 | Periodic Linear-driven "memory retro" issue, owned by Gru | Recurring issue runs the consolidation skill on a schedule visible in Linear | 30 min after option 1 lands | Visibility of memory hygiene as work | Low | feedback_scheduled_template_planning_fills.md |

## Per-option detail

### 1. dream-skill (recommended)

**For:** Designed for the exact symptoms here. Four-phase prompt: Orient (read memory dir), Gather Signal (grep recent session JSONLs for corrections / patterns), Consolidate (merge duplicates, resolve contradictions, convert relative dates to absolute), Prune & Index (rebuild MEMORY.md under 200 lines, demote verbose entries to topic files, remove dead pointers). ([MindStudio walkthrough](https://www.mindstudio.ai/blog/what-is-claude-code-autodream-memory-consolidation))

Auto-triggers via Stop hook: every session exit checks if 24h have passed; next session runs `/dream` in background with minimal overhead. Modifies memory files only, never project code.

**Against:** Community skill, not Anthropic-shipped, despite the "AutoDream" framing in MindStudio's marketing. Two competing forks (`grandamenium/dream-skill`, `jl-cmd/claude-dream`), neither dominant. Will sweep up things to keep (the "Reinforced YYYY-MM-DD" appendage rule sits awkwardly with auto-pruning).

**Integration:** Memory dir is git-versioned, so a runaway dream pass is reversible. Configure to leave `project_*_PRIVATE.md` files untouched. Install: `git clone https://github.com/grandamenium/dream-skill.git ~/.claude/skills/dream` then `bash /tmp/dream-skill/install.sh --auto`. Prereq: Claude Code v2.1.59+.

### 2. Promote rules to Skills

**For:** Skills solve the "trigger doesn't fire" problem natively. From the Anthropic docs surface: "Claude reads the description field of every available SKILL.md and matches it against your request. If your message contains keywords or intent that align with a Skill's description, that Skill gets loaded." Full content loads only on match; 50+ skills cost nothing on unrelated prompts.

Candidates (highest pain-to-fix ratio):
- `feedback_ticket_writing` and `feedback_ticket_shape` (huge load-bearing, fire constantly, currently miss before drafting)
- `feedback_dandori_structure` (mission start)
- `feedback_battle_is_a_confidence_pass` and the reviewers cluster
- `feedback_narrative_*` cluster (narrative writing kicks)
- `feedback_no_em_dashes` and the voice cluster (Skill `disable-model-invocation: true` + cited on every doc write)

**Against:** Description-writing is the hard part. Vague description = no fire; over-specific = misses adjacencies. Skill content duplicates memory body, creating a sync problem unless the SKILL.md is just `Read ~/.claude/.../feedback_X.md`.

**Integration:** Skill body can be a pointer (one line + `Read` of the canonical memory file), so memory stays canonical and Skill is just a load-trigger. Aligns with `feedback_skill_consolidates_not_restates.md`.

### 3. UserPromptSubmit topic-router

**For:** UserPromptSubmit hook is already wired (correction-signal). Extending to a topic-router is one shell file. Pattern from Anthropic docs: grep prompt for keyword, return `hookSpecificOutput.additionalContext`, capped at 10K chars. Catches the long tail of rules that don't deserve a full Skill.

**Against:** Static keyword lists rot. False positives waste context (10K is non-trivial). The correction-signal hook already proved hooks can be noisy.

**Integration:** Reuse `~/.claude/hooks/memory-correction-signal.sh` as the template. Build a `tags.json` mapping rule → keywords, generated by a one-off pass over `feedback_*.md` frontmatter. Cap injected context at one rule + index lines for related rules.

### 4. Split MEMORY.md by domain

**For:** Directly addresses the 200-line truncation; each shard stays under the load window. Path-scoped rules (per parreogarcia) load by glob on cwd. Volley's repo cwd makes this clean.

**Against:** Two indices to maintain. Modular `.claude/rules/` is for repo conventions; memory is per-project user state, so the file lives outside the repo and the path-scoping doesn't help unless symlinked. Likely needs a SessionStart hook to load the right shard.

**Integration:** Could pair with option 1: dream-skill rebuilds shards, top-level MEMORY.md becomes a 50-line directory of shards. Natural endpoint if option 1 alone doesn't shrink enough.

### 5. claude-mem MCP server (NOT recommended)

**Against:** Open issue #618 ("Uses too much tokens") reports users burning a 5-hour session in 10 messages on a medium codebase. Memory here is already markdown-canonical and git-versioned; claude-mem's value prop (auto-capture sessions) duplicates Linear status updates and the handoff scratchpad without solving the rule-fire problem.

### 6. Basic Memory MCP

**For:** Preserves the markdown + git story. Hybrid search (full-text + FastEmbed vectors) could solve trigger-miss via semantic recall. ([ChatForest](https://chatforest.com/guides/best-memory-mcp-servers/))

**Against:** New tool surface to learn and brief sub-agents about. Adds an embedding step on every read. Skills + topic-router probably get 80% of the recall benefit with no new dependency.

### 7-8. Engram, mem0, Zep, Memento

Skipped detail. Engram and mem0 are coding-agent-oriented but opaque-SQLite or cloud-backed; the "memory dir is a git repo" rule is incompatible. Memento needs Neo4j. None improve trigger-fire over native Skills.

## What to discard

- **claude-mem**: known token-burn problem; solves a different problem (session continuity, not rule-fire).
- **mem0 / Zep / Memento**: cloud or graph-DB infra, private-info leak surface, marginal benefit over native Skills.
- **A second correction-detection hook**: already in `reference_correction_signal_hook.md` as a "don't do this".
- **Per-rule slash commands** (`/recall foo`): manual recall is what's failing today; adding more manual surface doesn't help.
- **Tag-based loading via YAML frontmatter on memory files**: docs are clear that Claude Code has no built-in tag-retrieval; would need to be reimplemented in a hook, which is option 3 in different clothing.
- **Embedding-based semantic search over feedback_*.md without a hook**: nothing reads embeddings at trigger time without an MCP, so this is just option 6 with extra steps.

## Loose ends

- Confirm `dream-skill` respects the `_PRIVATE.md` suffix convention or wrap it in a guard.
- Decide whether to merge the correction-signal hook's logic into a unified topic-router or keep them as two single-purpose hooks.
- Audit which 10-20 rules would benefit most from Skill-promotion; start by grepping session transcripts for "you forgot" / "you didn't" against rule titles.
- Open question: does Claude Code v2.1.59+ ship its own AutoDream now? The MindStudio piece frames it as Anthropic's, the GitHub project frames itself as replicating an unreleased feature; check release notes.

## Sources

- [Hooks reference, Claude Code docs](https://code.claude.com/docs/en/hooks)
- [Extend Claude with skills, Claude Code docs](https://code.claude.com/docs/en/skills)
- [How Claude remembers your project, Claude Code docs](https://code.claude.com/docs/en/memory)
- [dream-skill GitHub](https://github.com/grandamenium/dream-skill)
- [claude-dream GitHub (alt fork)](https://github.com/jl-cmd/claude-dream)
- [MindStudio: What Is Claude Code AutoDream](https://www.mindstudio.ai/blog/what-is-claude-code-autodream-memory-consolidation)
- [MindStudio: How to Build a Learnings Loop](https://www.mindstudio.ai/blog/how-to-build-learnings-loop-claude-code-skills)
- [ChatForest: Best Memory MCP Servers](https://chatforest.com/guides/best-memory-mcp-servers/)
- [Termdock: claude-mem review](https://www.termdock.com/blog/claude-mem-persistent-memory-claude-code)
- [Augment Code: claude-mem persistent memory](https://www.augmentcode.com/learn/claude-mem-persistent-memory-claude-code)
- [Nimbalyst: Claude Code Skills practical guide](https://nimbalyst.com/blog/claude-code-skills-guide/)
- [Parreo Garcia: How Claude Code rules actually work](https://joseparreogarcia.substack.com/p/how-claude-code-rules-actually-work)
- [Parreo Garcia: You probably don't understand Claude Code memory](https://joseparreogarcia.substack.com/p/claude-code-memory-explained)
- [DEV Community: Claude Code Skills Practical Guide 2026](https://dev.to/muhammad_moeed/claude-code-skills-a-practical-guide-for-2026-3f6p)
- [mem0 blog: MCP knowledge graph memory](https://mem0.ai/blog/mcp-knowledge-graph-memory-enterprise-ai)
