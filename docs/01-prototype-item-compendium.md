# Item Compendium

Design for the item compendium UI: a reference screen where players can review the descriptions and effects of items they have fully mastered.

---

## Design principle

The compendium is a reward for mastery, not a strategy guide. An item's entry only appears once the player has reached max level with it. Before that, the item's behaviour is learned through play, consistent with the core design principle that effects are discovered by owning them.

The compendium does not explain items the player has not yet mastered. It is a record of what the player already knows, presented cleanly so they can revisit it.

---

## Unlock condition

**Items:** An item's compendium entry unlocks permanently when the item reaches level 3 (max). The entry persists even if the item is later destroyed at the Tinkerer. Destruction removes the item from the kit/locker; it does not erase the player's knowledge of it.

**Partners:** A partner's compendium entry unlocks permanently when the player reaches a volley threshold with that partner active. The threshold is the same for every partner. Partners do not have levels; mastery comes from time spent together. The threshold is a tuning target; it should feel like a natural milestone, not a grind. The compendium tracks volley total per partner silently in `ProgressionData`.

---

## Entry content

Each compendium entry displays:

### Header
- Item name
- Physical description (the "thing + twist" line from the item card)
- Item art/sprite at max level

### Descriptions
All three description variants, labelled by state:
- Default
- Power revealed
- Narrative revealed (post-break for pre-break items)

Description variants the player has not yet encountered in-game are hidden behind a placeholder (e.g. "???"). Reaching max level does not automatically reveal all variants; each variant unlocks independently through play. This preserves the discovery moment for Post-Break text even if the player maxes the item early.

### Effects
A plain-language summary of the item's max-level effects. Not the raw trigger/condition/outcome notation; a sentence or two that describes what the item does in terms the player already understands from having used it.

Example for The Stray:
> Spawns extra balls when you miss (up to 4). Hitting a personal best or a streak milestone triggers frenzy: doubled ball speed until the next miss clears everything.

### Stats
- Base cost and upgrade costs (the player has already paid these)
- Category (if applicable, e.g. Court)

---

## What the compendium does not show

- Hidden internal values (degradation counters, exact multipliers, roll weights)
- Trigger/condition/outcome notation
- Items the player has never owned
- Items owned but not yet at max level
- Synergy hints or build recommendations

The compendium is a mirror of what the player has experienced, not a wiki.

---

## Layout

The compendium is a separate screen accessible from the main menu or the kit UI. Not a modal overlay; a full-screen view the player navigates to intentionally.

### List view
- Grid or list of unlocked item icons/sprites
- Locked items are not shown at all (no greyed-out silhouettes, no "???/12 items" counter)
- The compendium feels like a personal collection, not a checklist

### Detail view
- Tapping/clicking an item opens the full entry
- Scrollable if content exceeds the viewport
- Back button returns to the list

---

## Empty state

If the player has no max-level items, the compendium is either:
- Not accessible yet (button does not appear until the first entry unlocks), or
- Shows a single line: something brief that acknowledges the space exists without making it feel like a task

The empty state should not create pressure to grind. Preference is to hide the entry point until there is something to show.

---

## Interaction with destruction

Destroying a max-level item at the Tinkerer does not remove its compendium entry. The player invested in mastering it; that knowledge is theirs.

If a destroyed item unlocks a secret item and the secret item is then also maxed, both appear in the compendium independently.

---

## Interaction with secret items

Secret items follow the same rules: compendium entry unlocks at max level. The compendium does not hint at their existence before that. No "hidden entry" slots, no question marks.

---

## Notes

- The compendium is read-only. No equipping, upgrading, or destroying from this screen.
- Description variant unlock state needs to be tracked per-item in save data, separate from ownership.
- The effect summary text is authored content, not generated from the effect definitions. Each item needs a hand-written compendium blurb.
- Court items and kit items appear in the same compendium with no category separation.
