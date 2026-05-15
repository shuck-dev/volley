# Gear

Gear is what the player attaches to the main character to change how that character plays. Tech spec follows in [`../tech/gear.md`](../tech/gear.md); narrative grounding sits in [`../narrative/gear.md`](../narrative/gear.md).

## Capacity

The character has a friendship capacity. Each piece of gear carries a friendship cost; equipping draws from the capacity. When the next item would exceed the capacity, the character refuses with an animation: the item bounces back to the rack, the character reads as "I can't carry this yet."

Capacity grows through training. The cap on day one is small; it expands as the player invests in the character.

## Equipping

The timeout opens the equip window. The player drags gear from the rack onto the character; the gear's effect registers via the existing effect manager and the gear's visual lands at its art-anchor on the body. Drag the gear back to the rack to unequip. Swap freely within the window.

The kit reads from the character: each visible item is one piece of gear in play. The unkitted character plays the complete baseline; gear sculpts on top, within whatever the character can currently carry.
