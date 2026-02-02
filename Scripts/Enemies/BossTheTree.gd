extends IEnemy

class_name BossTheTree


const SPRITE_PATH = "res://Sprites/Characters/Enemies/boss_the_tree.png"
const PROJECTILE_SCENE = preload("res://Scenes/Projectiles/ProjectileStandard.tscn")

# Swipe attack
var swipe_timer: float = 0.0
var swipe_interval: float = 10.0
var swipe_charge_time: float = 2.0
var swipe_cone_angle: float = 60.0
var swipe_range: float = 200.0
var swipe_damage: int = 3
var is_charging_swipe: bool = false
var swipe_charge_timer: float = 0.0
var swipe_direction: Vector2 = Vector2.ZERO

# Above projectile attack
var shoot_timer: float = 0.0
var shoot_interval: float = 2.0


func _init() -> void:
	sprite_path = SPRITE_PATH


func _ready() -> void:
	super._ready()
	_setup_stats()


func _setup_stats() -> void:
	health = 200
	max_health = 200
	speed = 0  # Stationary
	power = 2
	is_alive = true


func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	_handle_swipe_attack(delta)
	_handle_shooting(delta)


func _handle_swipe_attack(delta: float) -> void:
	if is_charging_swipe:
		swipe_charge_timer -= delta
		if swipe_charge_timer <= 0:
			_execute_swipe()
	else:
		swipe_timer -= delta
		if swipe_timer <= 0:
			_start_swipe_charge()


func _start_swipe_charge() -> void:
	if not target or not is_instance_valid(target):
		swipe_timer = swipe_interval
		return

	is_charging_swipe = true
	swipe_charge_timer = swipe_charge_time
	swipe_direction = (target.global_position - global_position).normalized()
	queue_redraw()


func _execute_swipe() -> void:
	is_charging_swipe = false
	swipe_timer = swipe_interval
	queue_redraw()

	if not target or not is_instance_valid(target):
		return

	# Check if player is in cone
	var to_player = target.global_position - global_position
	var distance = to_player.length()

	if distance > swipe_range:
		return

	var angle_to_player = rad_to_deg(swipe_direction.angle_to(to_player.normalized()))
	if abs(angle_to_player) <= swipe_cone_angle / 2:
		if target.has_method("take_damage"):
			target.take_damage(swipe_damage)


func _handle_shooting(delta: float) -> void:
	shoot_timer -= delta

	if shoot_timer <= 0 and target and is_instance_valid(target):
		_shoot_from_above()
		shoot_timer = shoot_interval


func _shoot_from_above() -> void:
	# Spawn projectile above target that falls down
	var projectile = PROJECTILE_SCENE.instantiate()
	projectile.global_position = target.global_position + Vector2(0, -200)
	projectile.initialize(self, Vector2.DOWN)
	get_tree().current_scene.add_child(projectile)


func _draw() -> void:
	if is_charging_swipe:
		# Draw cone indicator
		var cone_length = swipe_range
		var half_angle = deg_to_rad(swipe_cone_angle / 2)
		var points = PackedVector2Array()
		points.append(Vector2.ZERO)

		for i in range(11):
			var angle = -half_angle + (half_angle * 2 * i / 10)
			var point = swipe_direction.rotated(angle) * cone_length
			points.append(point)

		points.append(Vector2.ZERO)
		draw_colored_polygon(points, Color(1.0, 0.0, 0.0, 0.3))
