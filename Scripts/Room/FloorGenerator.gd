extends RefCounted

class_name FloorGenerator


var _floor_size: Vector2i = Vector2i(7, 7)
var _positions: Array[Vector2i] = []
var _rooms_data: Array = []
var _floor_grid: Dictionary = {}  # Vector2i -> room Dictionary


func _init() -> void:
	_load_rooms_data()


func _load_rooms_data() -> void:
	var file = FileAccess.open("res://data/rooms.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			_rooms_data = json.data
		file.close()


func generate_floor(room_count: int = 10) -> Dictionary:
	_positions.clear()

	var start_pos = Vector2i(_floor_size.x / 2, _floor_size.y / 2)
	_positions.append(start_pos)

	var attempts = 0
	# Reserve 2 spots for boss and treasure rooms
	var main_room_count = room_count - 2
	var max_attempts = room_count * 10

	while _positions.size() < main_room_count and attempts < max_attempts:
		attempts += 1

		var expand_from = _positions.pick_random()
		var direction = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT].pick_random()
		var new_pos = expand_from + direction

		if _is_valid(new_pos) and new_pos not in _positions:
			_positions.append(new_pos)

	# Add boss and treasure rooms as guaranteed dead ends
	_add_special_rooms()

	_build_floor_grid()
	_set_starting_room()
	_print_grid()
	return _floor_grid


func _add_special_rooms() -> void:
	var boss_pos = _find_dead_end_slot()
	if boss_pos != Vector2i(-1, -1):
		_positions.append(boss_pos)

	var treasure_pos = _find_dead_end_slot()
	if treasure_pos != Vector2i(-1, -1):
		_positions.append(treasure_pos)


func _find_dead_end_slot() -> Vector2i:
	# Find a position that connects to exactly one existing room
	var candidates: Array[Vector2i] = []
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

	for pos in _positions:
		for dir in directions:
			var candidate = pos + dir

			if not _is_valid(candidate):
				continue
			if candidate in _positions:
				continue

			# Check how many neighbors this candidate would have
			var neighbor_count = 0
			for check_dir in directions:
				if (candidate + check_dir) in _positions:
					neighbor_count += 1

			# Only one neighbor = dead end
			if neighbor_count == 1:
				candidates.append(candidate)

	if candidates.is_empty():
		return Vector2i(-1, -1)

	return candidates.pick_random()


func _set_starting_room() -> void:
	if _positions.is_empty():
		return

	var start_pos = _positions[0]  # First position is the center
	if start_pos in _floor_grid:
		_floor_grid[start_pos]["is_starting_room"] = true
		_floor_grid[start_pos]["obstacles"] = []
		# Original: no enemies in starting room
		#_floor_grid[start_pos]["enemies"] = {}
		# Testing: spawn saplings in starting room
		_floor_grid[start_pos]["enemies"] = {
			"small_sapling": [[100, 50], [-100, 50]]
		}


func _build_floor_grid() -> void:
	_floor_grid.clear()

	# Last two positions are boss and treasure rooms
	var boss_pos = _positions[-2] if _positions.size() >= 2 else Vector2i(-1, -1)
	var treasure_pos = _positions[-1] if _positions.size() >= 1 else Vector2i(-1, -1)

	var map_index = 1
	for pos in _positions:
		var doors = _get_doors_for_position(pos)
		var room_type = "Normal"

		if pos == boss_pos:
			room_type = "Boss"
		elif pos == treasure_pos:
			room_type = "Treasure"

		var matching_room = _find_matching_room(doors, room_type)

		if matching_room:
			_floor_grid[pos] = matching_room.duplicate()
			_floor_grid[pos]["grid_position"] = pos
			_floor_grid[pos]["map_index"] = map_index
			# Add enemies to all normal rooms (temporary for testing)
			if room_type == "Normal":
				_floor_grid[pos]["enemies"] = {
					"small_sapling": [[100, 50], [-100, 50]]
				}
			map_index += 1
		else:
			push_warning("No matching room found for position %s with doors %s and type %s" % [pos, doors, room_type])


func _find_matching_room(doors: Dictionary, room_type: String = "Normal") -> Dictionary:
	var matching_rooms: Array = []

	for room in _rooms_data:
		if room.room_type != room_type:
			continue

		if room.north == doors.north and \
		   room.south == doors.south and \
		   room.east == doors.east and \
		   room.west == doors.west:
			matching_rooms.append(room)

	if matching_rooms.is_empty():
		return {}

	return matching_rooms.pick_random()


func _is_valid(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < _floor_size.x and pos.y >= 0 and pos.y < _floor_size.y


func _print_grid() -> void:
	print("=== FLOOR GRID ===")
	print("Positions: ", _positions.size())

	for y in range(_floor_size.y):
		var row = ""
		for x in range(_floor_size.x):
			var pos = Vector2i(x, y)
			if pos in _floor_grid:
				var room_type = _floor_grid[pos].get("room_type", "Normal")
				var map_index = _floor_grid[pos].get("map_index", 0)
				match room_type:
					"Boss":
						row += "[BB]"
					"Treasure":
						row += "[TT]"
					_:
						row += "[%02d]" % map_index
			else:
				row += "[  ]"
		print(row)

	print("")

	for pos in _positions:
		var doors = _get_doors_for_position(pos)
		var map_index = _floor_grid[pos].get("map_index", -1) if pos in _floor_grid else -1
		var room_type = _floor_grid[pos].get("room_type", "Normal") if pos in _floor_grid else "?"
		print("Room %d (%s) | Pos %s | N:%s S:%s E:%s W:%s" % [map_index, room_type, pos, doors.north, doors.south, doors.east, doors.west])


func _get_doors_for_position(pos: Vector2i) -> Dictionary:
	return {
		"north": (pos + Vector2i.UP) in _positions,
		"south": (pos + Vector2i.DOWN) in _positions,
		"east": (pos + Vector2i.RIGHT) in _positions,
		"west": (pos + Vector2i.LEFT) in _positions
	}
