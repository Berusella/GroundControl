extends RefCounted

class_name RoomLoader


var _rooms_data: Array = []
var _room_scene: PackedScene = null


func _init(room_scene: PackedScene) -> void:
	_room_scene = room_scene


func load_data(path: String) -> bool:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open rooms file: " + path)
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("Failed to parse rooms JSON: " + json.get_error_message())
		return false

	_rooms_data = json.data
	return true


func create_room(room_data: Dictionary) -> Room:
	if _room_scene == null:
		push_error("Room scene not set")
		return null

	var room = _room_scene.instantiate()
	room.load_from_dict(room_data)
	return room


func get_random_room_data() -> Dictionary:
	if _rooms_data.is_empty():
		return {}
	return _rooms_data.pick_random()


func get_room_data_by_id(id: int) -> Dictionary:
	for data in _rooms_data:
		if data.get("id", -1) == id:
			return data
	return {}


func get_room_data_with_door(direction: String) -> Dictionary:
	var matching = _rooms_data.filter(func(r):
		return r.get(direction, false) == true
	)

	if matching.is_empty():
		return {}

	return matching.pick_random()


func has_rooms() -> bool:
	return not _rooms_data.is_empty()


func get_all_room_data() -> Array:
	return _rooms_data
