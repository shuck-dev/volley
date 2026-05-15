# Per-Limb Gear

Gear lives on the main character at named positions on the body. Extends the home-and-loose regime ([22-equip-loop-regime.md](../22-equip-loop-regime.md)); tech spec follows in [`../tech/per-limb-gear.md`](../tech/per-limb-gear.md).

## Gear

The class of items attached to the character to change how that character plays. Beside ball-role items in the existing two-role split: balls live on the court, gear lives on the player. The character is to gear what the court is to balls: the active home.

## Slots

Anatomical positions: hands, wrists, ankles, head. The item set already implies anatomy (grip tape on hands, ankle weights on ankles); the body's symmetry carries the constraint by itself. Symmetric pairs are two slots that take the same kind of item.

## Equipping

Timeout opens the equip window: the character walks off the court to the equip pose, and the rack-to-body drag becomes available. Equipping registers the item's effects via the existing effect manager while the item lives on the body; unequipping unregisters. Swap freely within the window: drag on, drag off, effects update in place. The kit reads from the silhouette; the build is visible on the character. The unkitted character plays the complete baseline; gear sculpts on top.
