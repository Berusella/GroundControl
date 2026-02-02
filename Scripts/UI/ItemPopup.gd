extends CanvasLayer

class_name ItemPopup


const DISPLAY_DURATION: float = 2.5
const FADE_DURATION: float = 0.5

var _timer: float = 0.0
var _is_showing: bool = false

@onready var panel: PanelContainer = $CenterContainer/PanelContainer
@onready var name_label: Label = $CenterContainer/PanelContainer/VBoxContainer/MarginContainer/VBoxContainer/NameLabel
@onready var desc_label: Label = $CenterContainer/PanelContainer/VBoxContainer/MarginContainer/VBoxContainer/DescLabel


func _ready() -> void:
	panel.modulate.a = 0.0
	panel.visible = false


func _process(delta: float) -> void:
	if not _is_showing:
		return

	_timer -= delta

	if _timer <= 0:
		_is_showing = false
		panel.visible = false
	elif _timer <= FADE_DURATION:
		panel.modulate.a = _timer / FADE_DURATION


func show_item(item_data: Dictionary) -> void:
	var item_name = item_data.get("name", "Unknown Item")
	var description = _generate_description(item_data)

	name_label.text = item_name
	desc_label.text = description

	panel.visible = true
	panel.modulate.a = 1.0
	_timer = DISPLAY_DURATION
	_is_showing = true


func _generate_description(item_data: Dictionary) -> String:
	var parts: Array[String] = []

	var stats = item_data.get("stats")
	if stats != null and stats is Dictionary:
		if stats.has("hp"):
			parts.append("+%d HP" % int(stats["hp"]))
		if stats.has("power"):
			parts.append("+%s Power" % str(stats["power"]))
		if stats.has("speed"):
			parts.append("+%s Speed" % str(stats["speed"]))
		if stats.has("fire_rate"):
			parts.append("+%s Fire Rate" % str(stats["fire_rate"]))
		if stats.has("keys"):
			parts.append("+%d Keys" % int(stats["keys"]))
		if stats.has("extra_life"):
			parts.append("+%d Extra Life" % int(stats["extra_life"]))

	var special = item_data.get("special")
	if special != null and special is String and not special.is_empty():
		parts.append("Special: %s" % special)

	var projectile = item_data.get("projectile")
	if projectile != null and projectile is String and not projectile.is_empty():
		parts.append("Projectile: %s" % projectile.capitalize())

	if parts.is_empty():
		return "A mysterious item"

	return ", ".join(parts)
