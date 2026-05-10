class_name MissZone
extends Area2D

## Area that fires body_entered on overlap; the ball hooks in via register_miss_zone().

## Side bands set this true so the ball falls out of the weightless play volume on cross.
@export var releases_ball: bool = false
