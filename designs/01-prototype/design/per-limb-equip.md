# Per-Limb Equipment

Settles the equipment model so SH-211 (drag-equip from rack onto the character) can ship against a fixed shape. The home-and-loose regime in [22-equip-loop-regime.md](../22-equip-loop-regime.md) already names equipment as a class of item with the character as its active home. This doc says what that means.

Scope: the concept, not the data model. Tech doc follows.

---

## What equipment is

Equipment is the class of items the player attaches to the main character to change how that character plays. It sits beside ball-role items in the existing two-role split: balls live on the court, equipment lives on the player. Both classes share the same drag, the same rack home, the same loose-in-venue fallback. The character is to equipment what the court is to balls: the active home, the place the item does its job.

The character carries kit; the court carries play. Items already authored as `role: equipment` (Ankle Weights, Grip Tape, Wrist Brace, Cadence) become this class without redefinition. The item card stays the same. What changes is the destination: the natural target for an equipment item is no longer "the player" as an undifferentiated owner but a specific position on the body.

Equipment is diegetic. A grip tape goes on a hand. An ankle weight goes on an ankle. A wrist brace goes on a wrist. The drag gesture lands the item where the item visibly belongs. If a player drags grip tape toward a foot, the foot does not accept it; the character does not absorb the item into a hidden pool. The world honours the shape of the thing being placed.

## What a slot is

A slot is an anatomical position on the character that can hold an equipment item. Slots are body parts the player can recognise on sight: hands, wrists, ankles, head. A slot is not an abstract category ("offence", "defence"), not a generic index ("equipment 1, equipment 2"), not a role ("striker", "tank"). It is a place on a body.

This is the call: anatomy, not abstraction. The reasons are short.

The item set already implies anatomy. Grip tape is for hands. Ankle weights are for ankles. Wrist braces are for wrists. The art and the name carry the slot. Forcing these into an abstract slot system would discard signal the items already broadcast for free.

Anatomy carries the rule the player needs to learn. "Two hands, two ankles, one head" is a fact about bodies. The player does not need a tutorial to know they cannot wear three wrist braces. The constraint is legible because the body is legible.

Anatomy composes with the diegetic drag. The drop target is a part of the character the player can see and aim at. A slot is not a glowing rectangle that lights up on hover; it is a wrist, and the gesture lands there because the player put it there. Hover feedback signals acceptance, but the player's intent reads from the cursor's position on the body, not from a UI element overlaid on the character.

Symmetric pairs (left and right) count as distinct slots that accept the same items. A character with two hands has two grip-tape positions; the player can fill both, or one, or neither. Pairs are not a separate concept; they are two slots that happen to take the same kind of item. The doubling is not a bonus mechanic, it is just what having two hands means.

## What equipping does

A kitted character plays differently. The difference is the sum of the items' effects, applied while the items are on the body, removed when they come off. Effect ownership stays where it already lives, in the effect manager; equipping is the act that registers a source, unequipping is the act that unregisters it. The slot model does not change what an effect does; it changes when and where the effect is live.

Equipping is a state of the character, not a state of the item alone. A grip tape sitting in the rack is owned, inert, and visible as a token. The same grip tape on the character's hand is owned, live, and visible as tape on a hand. Same item, two states, distinguished by where it lives. The character carries its kit visibly; the kit reads from the character's silhouette.

The character with a full kit is not a stronger version of the empty character. It is a character shaped by what the player chose to put on it. Ankle weights make the steps heavy. Grip tape widens the contact. A wrist brace stiffens the swing. The combination is the build, and the build is visible on the body. The player reads the loadout by looking at the character.

Equipping is reversible at no cost. The cost of a kit choice is the choice itself, not a penalty for changing it. A player who wants to swap grip tape for a wrist brace drags one off, drags the other on, and the effects update in place. The slot model exists to make these swaps legible; it does not exist to gate them.

The unkitted character is not a deficient character. It plays the base game with no modifiers. Equipment is additive sculpting on top of a complete baseline, never a hole the player must fill to feel whole.

---

## What this leaves to the tech doc

The data shape (how a slot is named, where the assignment is stored, how pair-slots are addressed), the drop-target authoring (which nodes on the character scene accept which items, what hover feedback shows), the save migration from the existing `EQUIPPED` enum to per-slot assignments, the failure mode when a saved item's slot no longer exists. None of these change the shape above; they implement it.
