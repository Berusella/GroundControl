extends Node2D

class_name Room


signal door_entered(direction: String)

enum RoomType { NORMAL, BOSS, TREASURE }

const ENEMY_SCENES = {
	"small_sapling": preload("res://Scenes/Enemies/SmallSapling.tscn")
}

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
	door.monitorable = is_active

	# Disable all collision shapes if door is inactive
	for child in door.get_children():
		if child is CollisionShape2D:
			child.disabled = not is_active

	if not is_active:
		return

	# Add sprite if not already present
	if not door.has_node("Sprite2D"):
		var door_texture = "res://Sprites/Tiles/Forest/door_open.png" if is_cleared else "res://Sprites/Tiles/Forest/door_closed.png"
		var sprite = SpriteFactory.create(door_texture)
		sprite.name = "Sprite2D"
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

	# Starting room or rooms with no enemies are already cleared
	if data.get("is_starting_room", false) or enemies_data.is_empty():
		is_cleared = true


func spawn_enemies() -> void:
	var enemies_container = $Enemies

	for enemy_type in enemies_data:
		if enemy_type not in ENEMY_SCENES:
			continue

		var positions = enemies_data[enemy_type]
		for pos in positions:
			var enemy = ENEMY_SCENES[enemy_type].instantiate()
			enemy.position = Vector2(pos[0], pos[1])
			enemies_container.add_child(enemy)
			enemies.append(enemy)
			enemy.tree_exited.connect(_on_enemy_died.bind(enemy))


func spawn_obstacles() -> void:
	for obs in obstacles:
		var pos = Vector2(obs[0], obs[1])
		# Add obstacle spawning logic here


func _on_enemy_died(enemy: IEnemy) -> void:
	enemies.erase(enemy)
	check_cleared()


func check_cleared() -> void:
	if enemies.is_empty():
		is_cleared = true
		_open_doors()


func _open_doors() -> void:
	var doors = [door_north, door_south, door_east, door_west]
	var open_texture = load("res://Sprites/Tiles/Forest/door_open.png")

	for door in doors:
		if door.visible and door.has_node("Sprite2D"):
			door.get_node("Sprite2D").texture = open_texture


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
