extends IEnemy

class_name GrowingTree


const SPRITE_PATH = "res://Sprites/Characters/Enemies/growing_tree.png"

var swipe_range: float = 80.0  # Range at which player triggers swipe
var swipe_cone_angle: float = 60.0  # Cone angle in degrees
var swipe_damage: int = 2
var charge_time: float = 2.0
var is_charging: bool = false
var charge_timer: float = 0.0
var swipe_direction: Vector2 = Vector2.ZERO


func _init() -> void:
	sprite_path = SPRITE_PATH


func _ready() -> void:
	super._ready()
	_setup_stats()


func _setup_stats() -> void:
	health = 30
	max_health = 30
	speed = 0  # Stationary
	power = 1
	is_alive = true


func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	if is_charging:
		_process_charge(delta)
	else:
		_check_player_proximity()


func _check_player_proximity() -> void:
	if not target or not is_instance_valid(target):
		return

	var distance = global_position.distance_to(target.global_position)
	if distance <= swipe_range:
		_start_charge()


func _start_charge() -> void:
	if not target or not is_instance_valid(target):
		return

	is_charging = true
	charge_timer = charge_time
	swipe_direction = (target.global_position - global_position).normalized()
	queue_redraw()


func _process_charge(delta: float) -> void:
	charge_timer -= delta

	if charge_timer <= 0:
		_execute_swipe()


func _execute_swipe() -> void:
	is_charging = false
	queue_redraw()

	if not target or not is_instance_valid(target):
		return

	# Check if player is in cone
	var to_player = target.global_position - global_position
	var distance = to_player.length()

	if distance > swipe_range * 1.5:  # Slightly larger range for the actual attack
		return

	var angle_to_player = rad_to_deg(swipe_direction.angle_to(to_player.normalized()))
	if abs(angle_to_player) <= swipe_cone_angle / 2:
		# Player is in cone, deal damage
		if target.has_method("take_damage"):
			target.take_damage(swipe_damage)


func _draw() -> void:
	if is_charging:
		# Draw cone indicator
		var cone_length = swipe_range * 1.5
		var half_angle = deg_to_rad(swipe_cone_angle / 2)
		var points = PackedVector2Array()
		points.append(Vector2.ZERO)

		for i in range(11):
			var angle = -half_angle + (half_angle * 2 * i / 10)
			var point = swipe_direction.rotated(angle) * cone_length
			points.append(point)

		points.append(Vector2.ZERO)
		draw_colored_polygon(points, Color(1.0, 0.0, 0.0, 0.3))
