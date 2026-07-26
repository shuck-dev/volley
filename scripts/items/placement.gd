class_name Placement
extends RefCounted

## Where an item currently lives; STORED is inert, ON_COURT runs effects.
## LOOSE_IN_VENUE is a transient runtime state for items dropped on the venue floor; not persisted.
enum {
	STORED = 0,
	ON_COURT = 1,
	LOOSE_IN_VENUE = 2,
}
