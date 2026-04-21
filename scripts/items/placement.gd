class_name Placement
extends RefCounted

## Where an item currently lives; STORED is inert, EQUIPPED and ON_COURT run effects.
enum {
	STORED = 0,
	EQUIPPED = 1,
	ON_COURT = 2,
}
