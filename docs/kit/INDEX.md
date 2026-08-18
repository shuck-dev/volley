# Kit

The staging area where the player keeps balls they are not currently playing with.

## What the player does

The kit sits at the player's end of the venue with a small number of slots. The player drags a ball into a slot to set it aside, and drags it back out to bring it into play. A slot holds one ball, and dropping onto an occupied slot is refused rather than swapping.

A ball in the kit is out of play but still owned. The kit is the tidy option; a ball can also be left lying in the venue where the player dropped it.

## How it is built

`scripts/items/ball_kit.gd` builds the slots and refreshes them from `BallManager`, redrawing whenever `state_changed` fires. `scripts/items/kit_slot.gd` is the individual slot and owns whether it accepts a given ball.

Placement lives on `BallManager`, not on the kit: `Placement.IN_KIT` alongside `STORED`, `ON_COURT`, and `LOOSE_IN_VENUE`. `add_to_kit` and `remove_from_kit` move a ball in and out, and the slot index is recorded per ball so a kitted ball keeps its place.

While a ball is being dragged the kit hides that ball's icon, so the player sees the one they are holding rather than two of the same thing.
