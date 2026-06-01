---
name: bubble
description: Promote a matured design doc out of the prototype discipline split into its flat entity home. Read when Josh says "bubble X", or asks to move/promote an emerged doc out of designs/01-prototype/{design,tech,narrative}/. Bubbling is always Josh's call; never self-promote a doc.
---

# Bubble

A prototype doc graduates to a flat entity doc once the thing it describes has emerged. Bubbling is **Josh's call**; never decide a subject has emerged and promote it yourself.

## Two steps. A bubble is not done at the move.

**1. Move (mechanical).**
- `git mv designs/01-prototype/{discipline}/NN-name.md designs/name.md`. Drop the `NN-` ordinal and the `{discipline}/` path.
- Single flat file at first. Promote to an entity folder `designs/<entity>/` only when a second related doc needs to join it.
- Fix every inbound link (`git grep` the old path), and the doc's own relative links so they resolve from the new location.
- Update `designs/INDEX.md` / `_Sidebar.md` if they list it. Cross-refs live in the INDEX, not inline body prose.
- Verify `git diff --cached -M` shows a rename, not add+delete (history preserved).

**2. Rewrite (substantive).**
- Re-author the doc in light of everything now known. It reads as the matured entity's authority, not a phase-1 discipline note.
- This is the point of bubbling. The move alone is half done; the rewrite can land as a deliberate next step but is not optional.

## Group by entity, not discipline

The bubble exists to **stop** the tech/design/narrative split. Do not bubble into another discipline bucket: no `designs/tech/`, no `designs/design/`. Group by what the thing **is**. There is no `concept/` folder; never create or add to one.

## Worked example

`01-prototype/tech/04-effect-system.md` → `designs/effect-system.md` (move committed 2dd4c22c, 2026-05-31). Rewrite-with-current-context deferred as the next step.

Full rule: memory `project_docs_structure_prototype_to_entity`. Pairs with `feedback_extract_to_new_structure`, `feedback_cross_links_in_index_not_body`.
