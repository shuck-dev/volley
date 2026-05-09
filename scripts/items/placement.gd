class_name Placement
extends RefCounted

## Where an item currently lives; STORED is inert, EQUIPPED and ON_COURT run effects.
## LOOSE_IN_VENUE is a transient runtime state for items dropped on the venue floor; not persisted.
enum {
	STORED = 0,
	EQUIPPED = 1,
	ON_COURT = 2,
	LOOSE_IN_VENUE = 3,
}
