extends IEnemy

class_name TheTourist


const SPRITE_PATH = "res://Sprites/Characters/Enemies/the_tourist.png"

var wander_direction: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0
var base_speed: float = 150.0


func _init() -> void:
	sprite_path = SPRITE_PATH


func _ready() -> void:
	super._ready()
	_setup_stats()
	_pick_new_direction()


func _setup_stats() -> void:
	health = 3
	max_health = 3
	speed = 150
	power = 1
	is_alive = true


func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	_move_random(delta)


func _move_random(delta: float) -> void:
	wander_timer -= delta

	if wander_timer <= 0:
		_pick_new_direction()

	var current_speed = base_speed
	if not target or not is_instance_valid(target):
		current_speed = base_speed * 0.5
	else:
		var distance = global_position.distance_to(target.global_position)
		if distance > detection_range:
			current_speed = base_speed * 0.5

	velocity = wander_direction * current_speed
	move_and_slide()


func _pick_new_direction() -> void:
	wander_direction = Vector2.from_angle(randf() * TAU)
	wander_timer = randf_range(0.3, 0.6)
