extends IEnemy

class_name BossMilitaryExperiment


const SPRITE_PATH = "res://Sprites/Characters/Enemies/boss_military_experiment.png"
const PROJECTILE_SCENE = preload("res://Scenes/Projectiles/ProjectileStandard.tscn")
const BRUTELING_SCENE = preload("res://Scenes/Enemies/Bruteling.tscn")

# Shooting
var fire_rate: float = 2.0
var fire_cooldown: float = 0.0

# Spawning brutelings
var bruteling_timer: float = 0.0
var bruteling_interval: float = 10.0
var max_spawned: int = 5
var spawned_count: int = 0


func _init() -> void:
	sprite_path = SPRITE_PATH


func _ready() -> void:
	super._ready()
	_setup_stats()
	_setup_pathfinder(EnemyPathfinder.PathMode.BRUTE)


func _setup_stats() -> void:
	health = 200
	max_health = 200
	speed = 50  # 0.7 * 100 base
	power = 2
	is_alive = true


func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	_move_toward_target()
	_handle_shooting(delta)
	_handle_spawning(delta)


func _handle_shooting(delta: float) -> void:
	fire_cooldown -= delta

	if fire_cooldown <= 0 and target and is_instance_valid(target):
		_shoot_at_target(PROJECTILE_SCENE)
		fire_cooldown = fire_rate


func _handle_spawning(delta: float) -> void:
	bruteling_timer -= delta

	if bruteling_timer <= 0:
		_spawn_bruteling()
		bruteling_timer = bruteling_interval


func _spawn_bruteling() -> void:
	if spawned_count >= max_spawned:
		return

	var bruteling = BRUTELING_SCENE.instantiate()
	var spawn_offset = Vector2(50, 0).rotated(randf() * TAU)
	bruteling.global_position = global_position + spawn_offset

	# Add to current room if possible
	var room = _get_current_room()
	if room:
		room.get_node("Enemies").add_child(bruteling)
		room.enemies.append(bruteling)
		# Connect to room's enemy died handler so room clears properly
		bruteling.tree_exited.connect(room._on_enemy_died.bind(bruteling))
		bruteling.tree_exited.connect(_on_spawned_died)
	else:
		get_tree().current_scene.add_child(bruteling)
		bruteling.tree_exited.connect(_on_spawned_died)

	spawned_count += 1


func _on_spawned_died() -> void:
	spawned_count = max(0, spawned_count - 1)


func _get_current_room() -> Room:
	var rooms = get_tree().get_nodes_in_group("room")
	if rooms.size() > 0:
		return rooms[0]
	return null
