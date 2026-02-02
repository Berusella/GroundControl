extends CanvasLayer

class_name Minimap


const MAP_NORMAL_CLEARED = "res://Sprites/UI/map/map_normal_cleared.png"
const MAP_NORMAL_UNCLEARED = "res://Sprites/UI/map/map_normal_uncleared.png"
const MAP_BOSS_CLEARED = "res://Sprites/UI/map/map_boss_cleared.png"
const MAP_BOSS_UNCLEARED = "res://Sprites/UI/map/map_boss_uncleared.png"
const MAP_ITEM_CLEARED = "res://Sprites/UI/map/map_item_cleared.png"
const MAP_ITEM_UNCLEARED = "res://Sprites/UI/map/map_item_uncleared.png"
const MAP_CURRENT = "res://Sprites/UI/map/map_current.png"

const CELL_SIZE = 18
const CELL_SPACING = 2
const MAP_MARGIN = 10

var _textures: Dictionary = {}
var _floor_manager: FloorManager = null
var _visited_rooms: Dictionary = {}
var _revealed_rooms: Dictionary = {}
var _room_icons: Dictionary = {}
var _current_indicator: TextureRect = null

const DIRECTIONS = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

@onready var map_container: Control = $MapContainer


func _ready() -> void:
	_load_textures()
	_create_current_indicator()
	call_deferred("_find_floor_manager")


func _load_textures() -> void:
	_textures["normal_cleared"] = load(ImageValidator.get_valid_path(MAP_NORMAL_CLEARED))
	_textures["normal_uncleared"] = load(ImageValidator.get_valid_path(MAP_NORMAL_UNCLEARED))
	_textures["boss_cleared"] = load(ImageValidator.get_valid_path(MAP_BOSS_CLEARED))
	_textures["boss_uncleared"] = load(ImageValidator.get_valid_path(MAP_BOSS_UNCLEARED))
	_textures["item_cleared"] = load(ImageValidator.get_valid_path(MAP_ITEM_CLEARED))
	_textures["item_uncleared"] = load(ImageValidator.get_valid_path(MAP_ITEM_UNCLEARED))
	_textures["current"] = load(ImageValidator.get_valid_path(MAP_CURRENT))


func _create_current_indicator() -> void:
	_current_indicator = TextureRect.new()
	_current_indicator.texture = _textures["current"]
	_current_indicator.stretch_mode = TextureRect.STRETCH_KEEP
	_current_indicator.visible = false
	_current_indicator.z_index = 1
	map_container.add_child(_current_indicator)


func _find_floor_manager() -> void:
	var parent = get_parent()
	if parent and parent.has_node("FloorManager"):
		_floor_manager = parent.get_node("FloorManager")
	else:
		for child in get_tree().root.get_children():
			if child is Node2D:
				for sub in child.get_children():
					if sub is FloorManager:
						_floor_manager = sub
						break

	if _floor_manager:
		_update_map()


func set_floor_manager(fm: FloorManager) -> void:
	_floor_manager = fm
	_visited_rooms.clear()
	_revealed_rooms.clear()
	_clear_room_icons()
	if _floor_manager:
		_update_map()


func _clear_room_icons() -> void:
	for icon in _room_icons.values():
		icon.queue_free()
	_room_icons.clear()


func _process(_delta: float) -> void:
	if _floor_manager:
		_update_map()


func _update_map() -> void:
	if not _floor_manager:
		return

	var floor_grid = _floor_manager._floor_grid
	var current_pos = _floor_manager._current_position

	_visited_rooms[current_pos] = true

	for dir in DIRECTIONS:
		var adjacent_pos = current_pos + dir
		if adjacent_pos in floor_grid:
			_revealed_rooms[adjacent_pos] = true

	var all_shown_rooms: Dictionary = {}
	for pos in _visited_rooms:
		all_shown_rooms[pos] = true
	for pos in _revealed_rooms:
		all_shown_rooms[pos] = true

	var min_pos = Vector2i(999, 999)
	var max_pos = Vector2i(-999, -999)

	for pos in all_shown_rooms:
		min_pos.x = min(min_pos.x, pos.x)
		min_pos.y = min(min_pos.y, pos.y)
		max_pos.x = max(max_pos.x, pos.x)
		max_pos.y = max(max_pos.y, pos.y)

	var grid_width = max_pos.x - min_pos.x + 1
	var grid_height = max_pos.y - min_pos.y + 1
	var map_width = grid_width * (CELL_SIZE + CELL_SPACING) - CELL_SPACING

	var viewport_size = get_viewport().get_visible_rect().size
	var base_x = viewport_size.x - map_width - MAP_MARGIN
	var base_y = MAP_MARGIN

	for pos in all_shown_rooms:
		if pos not in floor_grid:
			continue

		var room_data = floor_grid[pos]
		var room_type = room_data.get("room_type", "Normal")
		var is_cleared = room_data.get("is_cleared", false)

		if _floor_manager._current_room and pos == current_pos:
			is_cleared = _floor_manager._current_room.is_cleared

		var texture_key = _get_texture_key(room_type, is_cleared)

		var grid_x = pos.x - min_pos.x
		var grid_y = pos.y - min_pos.y
		var icon_x = base_x + grid_x * (CELL_SIZE + CELL_SPACING)
		var icon_y = base_y + grid_y * (CELL_SIZE + CELL_SPACING)

		if pos in _room_icons:
			var icon = _room_icons[pos]
			icon.texture = _textures[texture_key]
			icon.position = Vector2(icon_x, icon_y)
		else:
			var icon = TextureRect.new()
			icon.texture = _textures[texture_key]
			icon.stretch_mode = TextureRect.STRETCH_KEEP
			icon.position = Vector2(icon_x, icon_y)
			map_container.add_child(icon)
			_room_icons[pos] = icon

		if pos == current_pos:
			_current_indicator.position = Vector2(icon_x, icon_y)
			_current_indicator.visible = true


func _get_texture_key(room_type: String, is_cleared: bool) -> String:
	var type_prefix = "normal"
	match room_type:
		"Boss":
			type_prefix = "boss"
		"Item":
			type_prefix = "item"

	var state_suffix = "cleared" if is_cleared else "uncleared"
	return "%s_%s" % [type_prefix, state_suffix]


func on_floor_changed() -> void:
	_visited_rooms.clear()
	_revealed_rooms.clear()
	_clear_room_icons()
	_current_indicator.visible = false
