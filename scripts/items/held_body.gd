class_name HeldBody
extends RigidBody2D

## Dragged-gravity body per `designs/01-prototype/21-ball-dynamics.md` (SH-314).
## During the lift and held phases the body is kinematic-frozen so the controller drives position;
## release transitions either despawn the body (rack/court) or unfreeze it for loose-on-venue-floor.

enum Phase { LIFTING, HELD, LOOSE }

@export_range(0.0, 4.0, 0.05) var loose_gravity_scale: float = 1.0

var phase: Phase = Phase.LIFTING
var item_key: String = ""


## Builds a held body for `item_key` using the definition's authored art and at_rest_shape.
static func make_for(definition: ItemDefinition, item_key_override: String) -> HeldBody:
	var body: HeldBody = HeldBody.new()
	body.name = "HeldBody_%s" % item_key_override
	body.item_key = item_key_override
	body.gravity_scale = 0.0
	body.lock_rotation = true
	body.linear_damp = 1.0
	body.contact_monitor = false
	body.freeze = true
	body.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	# Held bodies must not be press-targets; the controller owns the gesture lifecycle.
	body.input_pickable = false
	# Visible scale rides on the body for the SH-297 lift feel; collision must not scale with it,
	# so collision layer/mask stay zeroed until go_loose flips the body into the world.
	body.collision_layer = 0
	body.collision_mask = 0

	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.name = "Collision"
	if definition != null and definition.at_rest_shape != null:
		collision.shape = definition.at_rest_shape
	else:
		# Fallback so test fixtures without an authored shape still spawn a valid body.
		var fallback: CircleShape2D = CircleShape2D.new()
		fallback.radius = 12.0
		collision.shape = fallback
	body.add_child(collision)

	if definition != null and definition.art != null:
		var art_holder: Node2D = Node2D.new()
		art_holder.name = "ArtHolder"
		# ArtHolder stays unscaled while held; the body's `scale` carries the SH-297 lift feel.
		# go_loose transfers the visible scale onto the ArtHolder so the body ends up unscaled
		# (so the collision shape matches the authored at_rest_shape in world space).
		art_holder.add_child(definition.art.instantiate())
		body.add_child(art_holder)

	return body


## Engages gravity for the loose-on-venue-floor state; unfreezes so physics integrates.
func go_loose(release_velocity: Vector2) -> void:
	phase = Phase.LOOSE
	# Migrate the visible scale off the body and onto the ArtHolder so the collision shape
	# matches the authored at_rest_shape (body itself is now unscaled in world space).
	var pre_loose_scale: Vector2 = scale
	scale = Vector2.ONE
	var art_holder: Node2D = get_node_or_null("ArtHolder") as Node2D
	if art_holder != null:
		art_holder.scale = pre_loose_scale
	freeze = false
	gravity_scale = loose_gravity_scale
	# Standard physics layer/mask: the body now collides with the venue floor and walls.
	collision_layer = 1
	collision_mask = 1
	linear_velocity = release_velocity


## Marks the lift tween as settled; the body is still kinematic-frozen on the cursor.
func mark_held() -> void:
	phase = Phase.HELD
