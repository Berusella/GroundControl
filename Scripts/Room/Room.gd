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
	door_north.visible = north
	door_south.visible = south
	door_east.visible = east
	door_west.visible = west

	door_north.monitoring = north
	door_south.monitoring = south
	door_east.monitoring = east
	door_west.monitoring = west

	if north:
		door_north.body_entered.connect(_on_door_north_entered)
	if south:
		door_south.body_entered.connect(_on_door_south_entered)
	if east:
		door_east.body_entered.connect(_on_door_east_entered)
	if west:
		door_west.body_entered.connect(_on_door_west_entered)


func _on_door_north_entered(body: Node2D) -> void:
	if body is Player and is_cleared:
		door_entered.emit("north")


func _on_door_south_entered(body: Node2D) -> void:
	if body is Player and is_cleared:
		door_entered.emit("south")


func _on_door_east_entered(body: Node2D) -> void:
	if body is Player and is_cleared:
		door_entered.emit("east")


func _on_door_west_entered(body: Node2D) -> void:
	if body is Player and is_cleared:
		door_entered.emit("west")


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


func get_spawn_position() -> Vector2:
	return player_spawn.global_position
