extends IEnemy

class_name BoilingBarrel


const SPRITE_PATH = "res://Sprites/Characters/Enemies/boiling_barrel.png"
const BURNING_PATCH_SCENE = preload("res://Scenes/Projectiles/BurningPatch.tscn")

var burn_timer: float = 0.0
var burn_interval: float = 1.0


func _init() -> void:
	sprite_path = SPRITE_PATH


func _ready() -> void:
	super._ready()
	_setup_stats()
	_setup_pathfinder(EnemyPathfinder.PathMode.BRUTE)


func _setup_stats() -> void:
	health = 20
	max_health = 20
	speed = 60
	power = 1
	is_alive = true


func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	_move_toward_target()
	_handle_burning(delta)


func _handle_burning(delta: float) -> void:
	burn_timer -= delta

	if burn_timer <= 0:
		_spawn_burning_patch()
		burn_timer = burn_interval


func _spawn_burning_patch() -> void:
	var patch = BURNING_PATCH_SCENE.instantiate()
	patch.initialize(self, Vector2.ZERO)
	get_tree().current_scene.add_child(patch)
	patch.global_position = global_position
