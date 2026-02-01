extends CanvasLayer

class_name HUD


const SCRAP_FULL_PATH = "res://Sprites/UI/ui_heart_full.png"
const SCRAP_EMPTY_PATH = "res://Sprites/UI/ui_heart_empty.png"
const SCRAP_SPACING = 20

var scrap_full_texture: Texture2D
var scrap_empty_texture: Texture2D
var player: Player = null
var scrap_icons: Array[TextureRect] = []

@onready var scrap_container: HBoxContainer = $MarginContainer/VBoxContainer/ScrapContainer
@onready var key_label: Label = $MarginContainer/VBoxContainer/KeyContainer/KeyLabel
@onready var special_label: Label = $MarginContainer/VBoxContainer/SpecialContainer/SpecialLabel


func _ready() -> void:
	_load_textures()
	_find_player()


func _load_textures() -> void:
	scrap_full_texture = load(ImageValidator.get_valid_path(SCRAP_FULL_PATH))
	scrap_empty_texture = load(ImageValidator.get_valid_path(SCRAP_EMPTY_PATH))


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
		icon.texture = scrap_full_texture
		icon.stretch_mode = TextureRect.STRETCH_KEEP
		scrap_container.add_child(icon)
		scrap_icons.append(icon)


func _update_health() -> void:
	# Add new icons if max health increased (from items)
	while scrap_icons.size() < player.max_health:
		var icon = TextureRect.new()
		icon.texture = scrap_full_texture
		icon.stretch_mode = TextureRect.STRETCH_KEEP
		scrap_container.add_child(icon)
		scrap_icons.append(icon)

	for i in range(scrap_icons.size()):
		if i < player.health:
			scrap_icons[i].texture = scrap_full_texture
		else:
			scrap_icons[i].texture = scrap_empty_texture


func _update_keys() -> void:
	key_label.text = str(player.keys)


func _update_special() -> void:
	if player.current_special.is_empty():
		special_label.text = "None"
		return

	if player.special_cooldown > 0:
		var progress = player.special_max_cooldown - player.special_cooldown
		special_label.text = "%s (%d/%d)" % [player.current_special, progress, player.special_max_cooldown]
	else:
		special_label.text = "%s [READY]" % player.current_special
