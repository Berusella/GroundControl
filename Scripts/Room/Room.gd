extends Node2D

class_name Room


signal door_entered(direction: String)

enum RoomType { NORMAL, BOSS, TREASURE }

var id: int = 0
var room_type: RoomType = RoomType.NORMAL
var north: bool = false
var south: bool = false
var east: bool = false
var west: bool = false
var obstacles: Array = []
var enemies_data: Dictionary = {}
var enemies: Array[IEnemy] = []
var is_cleared: bool = false

@onready var door_north: Area2D = $Doors/DoorsNorth
@onready var door_south: Area2D = $Doors/DoorsSouth
@onready var door_east: Area2D = $Doors/DoorsEast
@onready var door_west: Area2D = $Doors/DoorsWest
@onready var player_spawn: Marker2D = $SpawnPoints/PlayerSpawn	


func _ready() -> void:
	_setup_doors()


func _setup_doors() -> void:
	_setup_door(door_north, north, "north")
	_setup_door(door_south, south, "south")
	_setup_door(door_east, east, "east")
	_setup_door(door_west, west, "west")


func _setup_door(door: Area2D, is_active: bool, direction: String) -> void:
	door.visible = is_active
	door.monitoring = is_active

	if is_active:
		# Add sprite if not already present
		if not door.has_node("Sprite2D"):
			var sprite = SpriteFactory.create("res://Sprites/Tiles/Forest/door_open.png")
			door.add_child(sprite)

		# Connect signal
		var callback = Callable(self, "_on_door_entered").bind(direction)
		if not door.body_entered.is_connected(callback):
			door.body_entered.connect(callback)


func _on_door_entered(body: Node2D, direction: String) -> void:
	if body is Player and is_cleared:
		door_entered.emit(direction)


func load_from_dict(data: Dictionary) -> void:
	id = data.get("id", 0)
	north = data.get("north", false)
	south = data.get("south", false)
	east = data.get("east", false)
	west = data.get("west", false)
	obstacles = data.get("obstacles", [])
	enemies_data = data.get("enemies", {})

	var type_str = data.get("room_type", "Normal")
	match type_str:
		"Treasure":
			room_type = RoomType.TREASURE
		"Boss":
			room_type = RoomType.BOSS
		_:
			room_type = RoomType.NORMAL


func spawn_enemies() -> void:
	pass


func spawn_obstacles() -> void:
	for obs in obstacles:
		var pos = Vector2(obs[0], obs[1])
		# Add obstacle spawning logic here


func check_cleared() -> void:
	if enemies.is_empty():
		is_cleared = true


func get_spawn_position(from_direction: String = "") -> Vector2:
	if from_direction.is_empty():
		return player_spawn.global_position

	# Spawn player at the door they entered from (offset into the room)
	match from_direction:
		"north":
			return door_north.global_position + Vector2(0, 50)
		"south":
			return door_south.global_position + Vector2(0, -50)
		"east":
			return door_east.global_position + Vector2(-50, 0)
		"west":
			return door_west.global_position + Vector2(50, 0)

	return player_spawn.global_position
