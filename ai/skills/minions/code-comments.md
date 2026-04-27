---
name: code-comments
description: Code-comment policy every minion follows when writing code. One line max, WHY-only, no narration of what the code does. Read before writing or editing any source file.
---

# Code comments

Default to no comments. Most code shouldn't carry any.

## When to write one

Only when the WHY is non-obvious from the code:

- A hidden constraint or subtle invariant a reader would miss.
- A workaround for a specific bug or engine quirk.
- Behaviour that would surprise a reader of well-named identifiers.

If removing the comment wouldn't confuse a future reader, don't write it.

## What not to comment

- **What the code does.** Well-named identifiers already do that. `// loops over enemies and applies damage` next to a `for enemy in enemies: enemy.take_damage(d)` loop is noise.
- **Current task / fix / callers.** No `// added for SH-247`, no `// used by the rack reconciler`, no `// handles the case from #321`. Those belong in the PR description and rot the moment a caller changes.
- **Section headers in code.** `// === Public API ===` divides a file that should be split if it's that big.

## Length

One line max. If the WHY needs a paragraph, write a doc and link from the PR description, not from the code.

## TODOs

`todo: SH-XX` lowercase with the ticket id. No `TODO: ` shouty form. No bare TODOs without a ticket.

## Why this rule keeps slipping

Reviewers cite CLAUDE.md when blocking on multi-line block comments, and the violation still appears in fresh PRs. The cause is "I'll explain my approach" instinct overriding the policy. Treat any urge to write more than one line of comment as a signal to either rename the identifier, extract a helper, or move the explanation to the PR description.

## What this skill replaces

Memory rule `feedback_comment_style.md` and the comment section of `CLAUDE.md` both describe the same policy; this skill is the canonical version minions read before writing code.
