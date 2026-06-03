---
name: code-comments
description: Code-comment policy every minion follows when writing code. The code, its names, and its tests carry the meaning; a comment is the rare exception for a WHY the code cannot hold. Read before writing or editing any source file.
---

# Code comments

Before you write any line of code, read this and `data-driven.md`.

Good code documents itself. The identifiers name what things are, the structure shows what happens, and the tests show what it should do. Reach for those first: a clearer name, a smaller function, an extracted helper, a test that demonstrates the case. When the code carries the meaning there is nothing left for a comment to add, and that is the normal state. Most files carry no comments; that is them working as intended.

A comment earns its place only for a **WHY the code genuinely cannot hold**: a hidden constraint, a workaround for a specific engine quirk, a choice that would look wrong to a careful reader who doesn't know the reason. If a reader of the well-named code could deduce it, or if it belongs in a design or tech doc, let one of those carry it instead.

## A comment lives on the line it explains

A comment sits on the thing it explains and shares its spacing: a `##` directly above a declaration, or a `#` on or directly above the line it is about, with no blank line between them and none padding it off from the code above. It is part of that line, so it keeps the code's rhythm.

When a comment has nowhere to sit, that is the signal to read: it wants to explain a whole block from above a blank line, which means the block wants a name. Make it a named function and the name carries what the comment was reaching for.

## The two comment kinds

`##` is Godot's documentation comment; it attaches to the declaration directly below and surfaces in the editor. Same bar: one line naming a non-obvious WHY for that declaration, kept adjacent (a blank line breaks the attachment). One line per declaration; a WHY that needs a paragraph is a doc, not a docstring.

`#` is an inline comment, same bar again: a single line, only for the WHY the code can't hold, on or directly above the line it explains.

## Test files document themselves

A test needs no comments. The file name, the `test_*` function name, and the assertion messages already say what is under test and what should hold, so a test file and its support stubs carry no header docstring, no per-test explanation, and no `# --- group ---` dividers. If a test seems to need a comment to be understood, the test name or the test itself is what to fix.

## Let the code carry it instead of commenting

- **What the code does** is the identifiers' job; a `#` restating the line below is the line restated.
- **Why it exists, who calls it, what task it is for** lives in the PR and the issue, not the code; it rots the moment a caller changes.
- **Grouping a file into sections** (`# === Public API ===`, `# --- group ---`) means the file wants splitting, or the names want to do the grouping.

## Length and TODOs

One line, always. A WHY that needs more is a doc, linked from the PR, not from the code. TODOs are `todo: SH-XX <what>`, lowercase, with the issue id; never bare, never shouty.

## The pull to resist

The urge to add a comment is usually the urge to show the thinking, to explain the approach or prove the work was careful, the same over-production reflex behind long commit messages and sectioned PR bodies. The next reader wants the clear code, not the narration. So spend the urge on a better name, a smaller function, or a test, and write nothing.

## What this skill replaces

Memory rule `feedback_comment_style.md` and the comment section of `CLAUDE.md` describe the same policy; this skill is the standard version minions read before writing code.
