extends CanvasLayer

class_name HUD


const SCRAP_FULL = preload("res://Sprites/UI/ui_heart_full.png")
const SCRAP_EMPTY = preload("res://Sprites/UI/ui_heart_empty.png")
const SCRAP_SPACING = 20

var player: Player = null
var scrap_icons: Array[TextureRect] = []

@onready var scrap_container: HBoxContainer = $MarginContainer/VBoxContainer/ScrapContainer
@onready var key_label: Label = $MarginContainer/VBoxContainer/KeyContainer/KeyLabel
@onready var special_label: Label = $MarginContainer/VBoxContainer/SpecialContainer/SpecialLabel


func _ready() -> void:
	_find_player()


func _process(_delta: float) -> void:
	if player:
		_update_health()
		_update_keys()
		_update_special()


func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		_create_scrap_icons()


func _create_scrap_icons() -> void:
	# Clear existing icons
	for icon in scrap_icons:
		icon.queue_free()
	scrap_icons.clear()

	if not player:
		return

	# Create icons for max health
	for i in range(player.max_health):
		var icon = TextureRect.new()
		icon.texture = SCRAP_FULL
		icon.stretch_mode = TextureRect.STRETCH_KEEP
		scrap_container.add_child(icon)
		scrap_icons.append(icon)


func _update_health() -> void:
	for i in range(scrap_icons.size()):
		if i < player.health:
			scrap_icons[i].texture = SCRAP_FULL
		else:
			scrap_icons[i].texture = SCRAP_EMPTY


func _update_keys() -> void:
	key_label.text = str(player.keys)


func _update_special() -> void:
	# TODO: Implement special ability cooldown display
	special_label.text = "Ready"
