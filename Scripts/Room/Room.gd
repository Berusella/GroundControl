extends Node2D

class_name Room


signal door_entered(direction: String)

enum RoomType { NORMAL, BOSS, ITEM }

const ENEMY_SCENES = {
	"small_sapling": preload("res://Scenes/Enemies/SmallSapling.tscn"),
	"bruteling": preload("res://Scenes/Enemies/Bruteling.tscn"),
	"soldier": preload("res://Scenes/Enemies/Soldier.tscn"),
	"the_tourist": preload("res://Scenes/Enemies/TheTourist.tscn"),
	"super_sniper": preload("res://Scenes/Enemies/SuperSniper.tscn"),
	"boiling_barrel": preload("res://Scenes/Enemies/BoilingBarrel.tscn"),
	"growing_tree": preload("res://Scenes/Enemies/GrowingTree.tscn"),
	"the_buzzer": preload("res://Scenes/Enemies/TheBuzzer.tscn"),
	"boss_the_tree": preload("res://Scenes/Enemies/BossTheTree.tscn"),
	"boss_military_experiment": preload("res://Scenes/Enemies/BossMilitaryExperiment.tscn"),
	"boss_gorilla": preload("res://Scenes/Enemies/BossGorilla.tscn"),
	"boss_vietnam_horror": preload("res://Scenes/Enemies/BossVietnamHorror.tscn")
}

const ITEM_PEDESTAL_SCENE = preload("res://Scenes/Items/ItemPedestal.tscn")
const NEXT_FLOOR_SCENE = preload("res://Scenes/Room/NextFloor.tscn")
const OBSTACLE_SCENE = preload("res://Scenes/Room/Obstacle.tscn")

# Door texture paths
const DOOR_LOCKED_PATH = "res://Sprites/Tiles/Forest/door_locked.png"
const DOOR_OPEN_PATH = "res://Sprites/Tiles/Forest/door_open.png"
const DOOR_CLOSED_PATH = "res://Sprites/Tiles/Forest/door_closed.png"

# Door textures - loaded via ImageValidator
static var _door_locked_texture: Texture2D = null
static var _door_open_texture: Texture2D = null
static var _door_closed_texture: Texture2D = null

const PICKUP_SCENES = [
	preload("res://Scenes/Pickups/ScrapPickup.tscn"),
	preload("res://Scenes/Pickups/KeyPickup.tscn"),
	preload("res://Scenes/Pickups/SpecialChargePickup.tscn")
]

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
var item_taken: bool = false
var item_pedestal: Node2D = null
var locked_doors: Dictionary = {"north": false, "south": false, "east": false, "west": false}

@onready var door_north: Area2D = $Doors/DoorsNorth
@onready var door_south: Area2D = $Doors/DoorsSouth
@onready var door_east: Area2D = $Doors/DoorsEast
@onready var door_west: Area2D = $Doors/DoorsWest
@onready var player_spawn: Marker2D = $SpawnPoints/PlayerSpawn	


func _ready() -> void:
	add_to_group("room")
	_load_door_textures()
	_setup_doors()
	_setup_navigation()


static func _load_door_textures() -> void:
	if _door_locked_texture == null:
		_door_locked_texture = load(ImageValidator.get_valid_path(DOOR_LOCKED_PATH))
	if _door_open_texture == null:
		_door_open_texture = load(ImageValidator.get_valid_path(DOOR_OPEN_PATH))
	if _door_closed_texture == null:
		_door_closed_texture = load(ImageValidator.get_valid_path(DOOR_CLOSED_PATH))


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
		var sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		sprite.texture = _get_door_texture(direction)
		door.add_child(sprite)

	# Connect signal
	var callback = Callable(self, "_on_door_entered").bind(direction)
	if not door.body_entered.is_connected(callback):
		door.body_entered.connect(callback)


func _get_door_texture(direction: String) -> Texture2D:
	if locked_doors.get(direction, false):
		return _door_locked_texture
	elif is_cleared:
		return _door_open_texture
	else:
		return _door_closed_texture


func _on_door_entered(body: Node2D, direction: String) -> void:
	if not body is Player:
		return
	if not is_cleared:
		return

	var player = body as Player

	# Check if door is locked and player has key
	if locked_doors.get(direction, false):
		if player.keys <= 0:
			return
		# Use key to unlock
		player.keys -= 1
		locked_doors[direction] = false
		_update_door_texture(direction)

	door_entered.emit(direction)


func _update_door_texture(direction: String) -> void:
	var door = _get_door_by_direction(direction)
	if door and door.has_node("Sprite2D"):
		var sprite = door.get_node("Sprite2D")
		sprite.texture = _get_door_texture(direction)


func _get_door_by_direction(direction: String) -> Area2D:
	match direction:
		"north":
			return door_north
		"south":
			return door_south
		"east":
			return door_east
		"west":
			return door_west
	return null


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
		"Boss":
			room_type = RoomType.BOSS
		"Item":
			room_type = RoomType.ITEM
		_:
			room_type = RoomType.NORMAL

	# Track if item was taken (persisted in floor_grid)
	item_taken = data.get("item_taken", false)

	# Load locked doors info
	locked_doors = data.get("locked_doors", {"north": false, "south": false, "east": false, "west": false})

	# Room is cleared if: already marked cleared, is starting room, or has no enemies
	if data.get("is_cleared", false) or data.get("is_starting_room", false) or enemies_data.is_empty():
		is_cleared = true

	# ITEM rooms are always cleared (no enemies to fight)
	if room_type == RoomType.ITEM:
		is_cleared = true


func spawn_enemies() -> void:
	if is_cleared:
		return

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
		var obstacle = OBSTACLE_SCENE.instantiate()
		obstacle.position = pos
		add_child(obstacle)


func spawn_item_pedestal() -> void:
	if room_type != RoomType.ITEM:
		return

	if item_taken:
		return

	item_pedestal = ITEM_PEDESTAL_SCENE.instantiate()
	item_pedestal.position = player_spawn.position  # Center of room
	item_pedestal.item_picked_up.connect(_on_item_picked_up)
	add_child(item_pedestal)
	item_pedestal.set_random_item()  # Call after adding to tree so @onready vars are set


func _on_item_picked_up(_item_data: Dictionary) -> void:
	item_taken = true


func _on_enemy_died(enemy: IEnemy) -> void:
	# enemy reference may be stale when tree_exited fires
	if enemy in enemies:
		enemies.erase(enemy)
	check_cleared()


func check_cleared() -> void:
	if enemies.is_empty():
		is_cleared = true
		_open_doors()
		_notify_player_room_cleared()
		_try_spawn_pickup()

		# Spawn next floor portal in boss rooms
		if room_type == RoomType.BOSS:
			_spawn_next_floor_portal()


func _notify_player_room_cleared() -> void:
	if not is_inside_tree():
		return
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		if player.has_method("on_room_cleared"):
			player.on_room_cleared()


func _spawn_next_floor_portal() -> void:
	var portal = NEXT_FLOOR_SCENE.instantiate()
	portal.position = _find_clear_spawn_position()
	add_child(portal)


func _find_clear_spawn_position() -> Vector2:
	var default_pos = player_spawn.position
	var obstacle_size = 48.0  # Obstacle (32) + margin (16)

	# Check if default position is clear
	if _is_position_clear(default_pos, obstacle_size):
		return default_pos

	# Try positions in expanding circles around center
	var offsets = [
		Vector2(64, 0), Vector2(-64, 0), Vector2(0, 64), Vector2(0, -64),
		Vector2(64, 64), Vector2(-64, 64), Vector2(64, -64), Vector2(-64, -64),
		Vector2(128, 0), Vector2(-128, 0), Vector2(0, 128), Vector2(0, -128)
	]

	for offset in offsets:
		var test_pos = default_pos + offset
		if _is_position_clear(test_pos, obstacle_size):
			return test_pos

	# Fallback to default if no clear position found
	return default_pos


func _is_position_clear(pos: Vector2, min_distance: float) -> bool:
	for obs in obstacles:
		var obs_pos = Vector2(obs[0], obs[1])
		if pos.distance_to(obs_pos) < min_distance:
			return false
	return true


func _try_spawn_pickup() -> void:
	# 1/3 chance to spawn something
	if randi() % 3 != 0:
		return

	# Pick random pickup type (1/3 each: scrap, key, special charge)
	var pickup_index = randi() % PICKUP_SCENES.size()
	var pickup = PICKUP_SCENES[pickup_index].instantiate()
	pickup.position = player_spawn.position
	add_child(pickup)


func _open_doors() -> void:
	var door_directions = {"north": door_north, "south": door_south, "east": door_east, "west": door_west}

	for direction in door_directions:
		var door = door_directions[direction]
		# Skip locked doors - they stay locked until key is used
		if locked_doors.get(direction, false):
			continue
		if door.visible and door.has_node("Sprite2D"):
			door.get_node("Sprite2D").texture = _door_open_texture


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


func _setup_navigation() -> void:
	# Create NavigationRegion2D for pathfinding
	var nav_region = NavigationRegion2D.new()
	nav_region.name = "NavigationRegion"

	# Create navigation polygon covering walkable floor area
	var nav_poly = NavigationPolygon.new()

	# Define room bounds (based on Room.tscn boundaries)
	# Inset slightly from walls to prevent pathing into them
	var margin = 20.0
	var min_x = -350.0 + margin
	var max_x = 390.0 - margin
	var min_y = -270.0 + margin
	var max_y = 260.0 - margin

	# Outer boundary (clockwise winding)
	var outer_outline = PackedVector2Array([
		Vector2(min_x, min_y),
		Vector2(max_x, min_y),
		Vector2(max_x, max_y),
		Vector2(min_x, max_y)
	])
	nav_poly.add_outline(outer_outline)

	# Add holes for each obstacle (counter-clockwise winding)
	var obstacle_margin = 20.0  # Extra margin around obstacles for pathfinding
	var obstacle_half_size = 16.0 + obstacle_margin  # 32/2 + margin

	for obs in obstacles:
		var pos = Vector2(obs[0], obs[1])
		# Counter-clockwise winding for holes
		var hole = PackedVector2Array([
			Vector2(pos.x - obstacle_half_size, pos.y - obstacle_half_size),
			Vector2(pos.x - obstacle_half_size, pos.y + obstacle_half_size),
			Vector2(pos.x + obstacle_half_size, pos.y + obstacle_half_size),
			Vector2(pos.x + obstacle_half_size, pos.y - obstacle_half_size)
		])
		nav_poly.add_outline(hole)

	# Bake the navigation mesh using NavigationServer2D
	var source_geometry = NavigationMeshSourceGeometryData2D.new()

	# Add traversable area (outer boundary)
	source_geometry.add_traversable_outline(outer_outline)

	# Add obstruction outlines for each obstacle
	for obs in obstacles:
		var pos = Vector2(obs[0], obs[1])
		var obstruction = PackedVector2Array([
			Vector2(pos.x - obstacle_half_size, pos.y - obstacle_half_size),
			Vector2(pos.x + obstacle_half_size, pos.y - obstacle_half_size),
			Vector2(pos.x + obstacle_half_size, pos.y + obstacle_half_size),
			Vector2(pos.x - obstacle_half_size, pos.y + obstacle_half_size)
		])
		source_geometry.add_obstruction_outline(obstruction)

	NavigationServer2D.bake_from_source_geometry_data(nav_poly, source_geometry)

	nav_region.navigation_polygon = nav_poly
	add_child(nav_region)

	# Move to back so it doesn't interfere with rendering
	move_child(nav_region, 0)
