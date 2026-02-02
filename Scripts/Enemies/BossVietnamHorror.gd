extends IEnemy

class_name BossVietnamHorror


const SPRITE_PATH = "res://Sprites/Characters/Enemies/boss_vietnam_horror.png"
const BURNING_PATCH_SCENE = preload("res://Scenes/Projectiles/BurningPatch.tscn")

# Burning patch
var burn_timer: float = 0.0
var burn_interval: float = 0.5

# Speed phases
var base_speed: float = 100.0  # speed 1
var enraged_speed: float = 150.0  # speed 1.5
var enrage_threshold: float = 0.4  # 40% hp
var is_enraged: bool = false


func _init() -> void:
	sprite_path = SPRITE_PATH


func _ready() -> void:
	super._ready()
	_setup_stats()
	_setup_pathfinder(EnemyPathfinder.PathMode.DASH)


func _setup_stats() -> void:
	health = 180
	max_health = 180
	speed = base_speed
	power = 2
	is_alive = true


func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	_check_enrage()
	_handle_dash_movement(delta)
	_handle_burning(delta)


func _check_enrage() -> void:
	if is_enraged:
		return

	var health_percent = float(health) / float(max_health)
	if health_percent <= enrage_threshold:
		is_enraged = true
		speed = enraged_speed


func _handle_dash_movement(delta: float) -> void:
	if not pathfinder:
		_move_toward_target()
		return

	pathfinder.update_dash(delta, speed)
	pathfinder.try_start_dash()

	if pathfinder:
		pathfinder.set_target(target)
		var speed_mult = pathfinder.get_speed_multiplier()
		velocity = pathfinder.get_movement_direction() * speed * speed_mult

	move_and_slide()


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
