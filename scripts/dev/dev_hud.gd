class_name DevHud
extends CanvasLayer

const PADDLE_DEV_OVERLAY_SCENE := "res://scenes/dev/paddle_dev_overlay.tscn"

@export var clearance_button: Button
@export var dev_panel_container: PanelContainer
@export var dev_bounce_overlay: DevBounceOverlay
@export var player_sprite: PlayerSprite

var _partner_overlay: Node2D


func _ready() -> void:
	clearance_button.visible = not ProgressionManager.is_shop_unlocked()
	clearance_button.pressed.connect(_on_clearance_button_pressed)
	ProgressionManager.shop_unlocked_changed.connect(_on_shop_unlocked_changed)

	var venue: Venue = get_parent()
	venue.court.partner_changed.connect(_on_partner_changed)
	_attach_overlay(venue.court.player_paddle)
	_on_partner_changed()


func _exit_tree() -> void:
	if ProgressionManager.shop_unlocked_changed.is_connected(_on_shop_unlocked_changed):
		ProgressionManager.shop_unlocked_changed.disconnect(_on_shop_unlocked_changed)


func _on_clearance_button_pressed() -> void:
	ProgressionManager.unlock_shop()


func _on_shop_unlocked_changed(is_unlocked: bool) -> void:
	clearance_button.visible = not is_unlocked


func _on_partner_changed() -> void:
	var venue: Venue = get_parent()

	if is_instance_valid(_partner_overlay):
		_partner_overlay.queue_free()
	_partner_overlay = null

	if venue.court.partner_paddle != null:
		_partner_overlay = _attach_overlay(venue.court.partner_paddle)

	_push_paddles()


func _attach_overlay(paddle: Paddle) -> Node2D:
	var overlay: DevOverlay = load(PADDLE_DEV_OVERLAY_SCENE).instantiate()
	var body_collider: BodyColliderOverlay = overlay.get_node("BodyColliderOverlay")
	var racket_collider: RacketColliderOverlay = overlay.get_node("RacketColliderOverlay")
	var ray_overlay: GroundRayOverlay = overlay.get_node("GroundRayOverlay")
	var state_label: AnimationStateLabel = overlay.get_node("AnimationStateLabel")
	body_collider.collision = paddle.collision
	racket_collider.racket_hitbox = paddle.racket_hitbox
	ray_overlay.ground_ray = paddle.ground_ray
	state_label.sprite = paddle.sprite
	paddle.add_child(overlay)
	return overlay


func _push_paddles() -> void:
	var venue: Venue = get_parent()
	var paddles: Array[Paddle] = []
	if venue.court.player_paddle != null:
		paddles.append(venue.court.player_paddle)
	if venue.court.partner_paddle != null:
		paddles.append(venue.court.partner_paddle)

	if dev_bounce_overlay != null:
		dev_bounce_overlay.set_paddles(paddles)
	if player_sprite != null:
		player_sprite.set_paddles(paddles)
