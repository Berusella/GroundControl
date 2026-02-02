extends IEnemy

class_name TheBuzzer


const SPRITE_PATH = "res://Sprites/Characters/Enemies/the_buzzer.png"

enum MovementMode { PLAYER, RANDOM }

var current_mode: MovementMode = MovementMode.RANDOM
var mode_timer: float = 0.0
var wander_direction: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0


func _init() -> void:
	sprite_path = SPRITE_PATH


func _ready() -> void:
	super._ready()
	_setup_stats()
	_pick_new_mode()


func _setup_stats() -> void:
	health = 10
	max_health = 10
	speed = 60
	power = 1
	is_alive = true


func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	_update_mode(delta)

	match current_mode:
		MovementMode.PLAYER:
			_move_like_player()
		MovementMode.RANDOM:
			_move_random(delta)


func _update_mode(delta: float) -> void:
	mode_timer -= delta
	if mode_timer <= 0:
		_pick_new_mode()


func _pick_new_mode() -> void:
	if current_mode == MovementMode.PLAYER:
		current_mode = MovementMode.RANDOM
		_pick_new_wander_direction()
	else:
		current_mode = MovementMode.PLAYER

	mode_timer = randf_range(1.0, 3.0)


func _move_like_player() -> void:
	var dir = Vector2(
		Input.get_axis("Move_left", "Move_right"),
		Input.get_axis("Move_up", "Move_down")
	).normalized()

	velocity = dir * speed
	move_and_slide()


func _move_random(delta: float) -> void:
	wander_timer -= delta

	if wander_timer <= 0:
		_pick_new_wander_direction()

	velocity = wander_direction * speed
	move_and_slide()


func _pick_new_wander_direction() -> void:
	wander_direction = Vector2.from_angle(randf() * TAU)
	wander_timer = randf_range(0.3, 0.6)
