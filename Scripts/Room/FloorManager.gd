extends Node

class_name FloorManager


signal player_won

var _room_loader: RoomLoader = null
var _floor_generator: FloorGenerator = null
var _player: Player = null
var _floor_grid: Dictionary = {}
var _current_position: Vector2i = Vector2i.ZERO
var _current_room: Room = null
var _can_transition: bool = true
var _current_floor: int = 1
const TRANSITION_COOLDOWN: float = 0.1  # 100ms
const MAX_FLOORS: int = 3


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
		_floor_grid[_current_position]["locked_doors"] = _current_room.locked_doors.duplicate()
		_current_room.door_entered.disconnect(_on_door_entered)
		_current_room.queue_free()

	var room_data = _floor_grid[pos].duplicate()

	# Determine which doors lead to item rooms (should be locked)
	room_data["locked_doors"] = _get_locked_doors(pos)

	_current_room = _room_loader.create_room(room_data)
	_current_position = pos

	# Print room entry to console
	var map_index = room_data.get("map_index", -1)
	print("Entered Room %d at %s" % [map_index, pos])

	# Connect door signal
	_current_room.door_entered.connect(_on_door_entered)

	# Add room to scene
	add_child(_current_room)

	# Spawn obstacles first (before enemies)
	_current_room.spawn_obstacles()

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


func _get_locked_doors(pos: Vector2i) -> Dictionary:
	# Check if locked_doors state was already saved (door was unlocked with key)
	if _floor_grid[pos].has("locked_doors"):
		return _floor_grid[pos]["locked_doors"].duplicate()

	# Generate initial locked doors based on adjacent item rooms
	var locked = {"north": false, "south": false, "east": false, "west": false}
	var directions = {
		"north": Vector2i.UP,
		"south": Vector2i.DOWN,
		"east": Vector2i.RIGHT,
		"west": Vector2i.LEFT
	}

	for dir_name in directions:
		var adjacent_pos = pos + directions[dir_name]
		if adjacent_pos in _floor_grid:
			var adjacent_room = _floor_grid[adjacent_pos]
			if adjacent_room.get("room_type", "Normal") == "Item":
				locked[dir_name] = true

	return locked


func go_to_next_floor() -> void:
	# Check if player has completed all floors
	if _current_floor >= MAX_FLOORS:
		player_won.emit()
		return

	# Clear current room
	if _current_room and is_instance_valid(_current_room):
		if _current_room.door_entered.is_connected(_on_door_entered):
			_current_room.door_entered.disconnect(_on_door_entered)
		_current_room.queue_free()
		_current_room = null

	_clear_all_projectiles()

	# Increment floor counter
	_current_floor += 1
	print("Entering Floor %d" % _current_floor)

	# Generate new floor and load starting room
	_floor_grid.clear()
	_current_position = Vector2i.ZERO
	load_starting_room()


func get_current_floor() -> int:
	return _current_floor
