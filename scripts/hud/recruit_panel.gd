extends VBoxContainer

# preload workaround for autoload class_name ordering (godotengine/godot#75582)
@warning_ignore("shadowed_global_identifier")
const PartnerDefinition = preload("res://scripts/partners/partner_definition.gd")

@export var recruit_label: Label
@export var recruit_button: Button
@export var recruit_sound: AudioStreamPlayer

var _pending_partner_key: StringName = &""


func _ready() -> void:
	visible = false
	recruit_button.pressed.connect(_on_recruit_pressed)
	ProgressionManager.partner_recruit_available.connect(_on_partner_recruit_available)
	ProgressionManager.partner_recruited.connect(_on_partner_recruited)


func _on_partner_recruit_available(partner: PartnerDefinition) -> void:
	_pending_partner_key = partner.key
	recruit_label.text = "Recruit %s" % partner.display_name
	recruit_button.text = "%d FP" % partner.unlock_cost
	visible = true


func _on_recruit_pressed() -> void:
	if _pending_partner_key != &"":
		ProgressionManager.recruit_partner(_pending_partner_key)


func _on_partner_recruited(_partner_key: StringName) -> void:
	visible = false
	if recruit_sound != null and recruit_sound.stream != null:
		recruit_sound.play()
	_pending_partner_key = &""
