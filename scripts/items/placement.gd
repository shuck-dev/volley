class_name Placement
extends RefCounted

## Where an item currently lives. Effects run only when the item is physically
## on the player (EQUIPPED) or on the court (ON_COURT). STORED means the item
## is owned but sitting on a rack, and is inert.

enum {
	STORED = 0,
	EQUIPPED = 1,
	ON_COURT = 2,
}
