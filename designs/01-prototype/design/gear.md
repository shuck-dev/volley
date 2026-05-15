# Gear

Gear is what the player attaches to the main character to change how that character plays. Tech spec follows in [`../tech/gear.md`](../tech/gear.md); narrative grounding sits in [`../narrative/gear.md`](../narrative/gear.md).

## Capacity

The character has a kit cap: a number of equipment items they can hold at once. When equipping would push past the cap, the character refuses with an animation; the held item stays on the cursor for the player to place elsewhere.

The cap grows through training. The cap on day one is small; it expands as the player invests in the character.

## Equipping

The timeout opens the equip window. The player drags gear from the rack onto the character; the gear's effect registers via the existing effect manager and the gear's visual lands at its art-anchor on the body. Drag the gear back to the rack to unequip. Swap freely within the window.

The kit reads from the character: each visible item is one piece of gear in play. The unkitted character plays the complete baseline; gear sculpts on top, within whatever the character can currently carry.
