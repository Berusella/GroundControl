extends Node

class_name FloorManager


var _room_loader: RoomLoader = null
var _floor_generator: FloorGenerator = null
var _player: Player = null
var _floor_grid: Dictionary = {}
var _current_position: Vector2i = Vector2i.ZERO
var _current_room: Room = null
var _can_transition: bool = true
const TRANSITION_COOLDOWN: float = 0.1  # 100ms


func initialize(room_loader: RoomLoader, player: Player) -> void:
	_room_loader = room_loader
	_player = player
	_floor_generator = FloorGenerator.new()


func generate_floor(room_count: int = 10) -> void:
	_floor_grid = _floor_generator.generate_floor(room_count)


func load_starting_room() -> Room:
	generate_floor()

	# Find the starting room
	for pos in _floor_grid:
		var room_data = _floor_grid[pos]
		if room_data.get("is_starting_room", false):
			_current_position = pos
			return _load_room_at_position(pos)

	return null


func _load_room_at_position(pos: Vector2i, from_direction: String = "") -> Room:
	if pos not in _floor_grid:
		return null

	# Clear all projectiles when transitioning
	_clear_all_projectiles()

	# Clean up old room and save its state
	if _current_room:
		_floor_grid[_current_position]["is_cleared"] = _current_room.is_cleared
		_floor_grid[_current_position]["item_taken"] = _current_room.item_taken
		_current_room.door_entered.disconnect(_on_door_entered)
		_current_room.queue_free()

	var room_data = _floor_grid[pos]
	_current_room = _room_loader.create_room(room_data)
	_current_position = pos

	# Print room entry to console
	var map_index = room_data.get("map_index", -1)
	print("Entered Room %d at %s" % [map_index, pos])

	# Connect door signal
	_current_room.door_entered.connect(_on_door_entered)

	# Add room to scene
	add_child(_current_room)

	# Spawn enemies
	_current_room.spawn_enemies()

	# Spawn item pedestal if this is an item room
	_current_room.spawn_item_pedestal()

	# Position player and notify of room entry
	if _player:
		_player.global_position = _current_room.get_spawn_position(from_direction)
		_player.on_room_entered()

	return _current_room


func _on_door_entered(direction: String) -> void:
	if not _can_transition:
		return

	var next_pos = _get_adjacent_position(direction)

	if next_pos in _floor_grid:
		_can_transition = false
		var opposite_direction = _get_opposite_direction(direction)
		# Defer room loading to avoid physics flush error
		call_deferred("_load_room_at_position", next_pos, opposite_direction)
		_start_transition_cooldown()


func _start_transition_cooldown() -> void:
	await get_tree().create_timer(TRANSITION_COOLDOWN).timeout
	if is_instance_valid(self):
		_can_transition = true


func _get_adjacent_position(direction: String) -> Vector2i:
	match direction:
		"north":
			return _current_position + Vector2i.UP
		"south":
			return _current_position + Vector2i.DOWN
		"east":
			return _current_position + Vector2i.RIGHT
		"west":
			return _current_position + Vector2i.LEFT
	return _current_position


func _get_opposite_direction(direction: String) -> String:
	match direction:
		"north":
			return "south"
		"south":
			return "north"
		"east":
			return "west"
		"west":
			return "east"
	return ""


func _clear_all_projectiles() -> void:
	var projectiles = get_tree().get_nodes_in_group("projectile")
	for projectile in projectiles:
		projectile.queue_free()
