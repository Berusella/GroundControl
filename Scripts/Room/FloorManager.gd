extends Node

class_name FloorManager


signal room_changed(room: Room)

var current_floor: int = 0
var current_room: Room = null

var _room_loader: RoomLoader = null
var _player: Player = null


func initialize(room_loader: RoomLoader, player: Player) -> void:
	_room_loader = room_loader
	_player = player


func load_first_room() -> void:
	if _room_loader == null or not _room_loader.has_rooms():
		push_error("No rooms available")
		return

	var room_data = _room_loader.get_random_room_data()
	_load_room(room_data, "")


func _load_room(room_data: Dictionary, entry_direction: String) -> void:
	if room_data.is_empty():
		return

	_cleanup_current_room()

	current_room = _room_loader.create_room(room_data)
	add_child(current_room)

	current_room.door_entered.connect(_on_door_entered)

	_position_player(entry_direction)

	# Mark room as cleared for testing (remove when enemies work)
	current_room.is_cleared = true

	room_changed.emit(current_room)


func _cleanup_current_room() -> void:
	if current_room == null:
		return

	if current_room.door_entered.is_connected(_on_door_entered):
		current_room.door_entered.disconnect(_on_door_entered)

	current_room.queue_free()


func _position_player(entry_direction: String) -> void:
	if _player != null and current_room != null:
		_player.position = current_room.get_spawn_position(entry_direction)


func _on_door_entered(direction: String) -> void:
	var opposite = DirectionHelper.get_opposite(direction)
	var next_room_data = _room_loader.get_room_data_with_door(opposite)

	if not next_room_data.is_empty():
		_load_room(next_room_data, opposite)
