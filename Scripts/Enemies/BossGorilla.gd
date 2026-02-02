extends IEnemy

class_name BossGorilla


const SPRITE_PATH = "res://Sprites/Characters/Enemies/boss_gorilla.png"
const PROJECTILE_SCENE = preload("res://Scenes/Projectiles/ProjectileStandard.tscn")

enum BehaviorMode { BRUTE, ESCAPE }

var current_mode: BehaviorMode = BehaviorMode.BRUTE
var mode_timer: float = 0.0
var mode_switch_interval: float = 5.0

# Base speed that gets modified
var base_speed: float = 80.0
var speed_modifier: float = 50.0  # 0.5 * 100

# BRUTE mode - swipe attack
var swipe_charge_time: float = 1.0
var swipe_cone_angle: float = 45.0
var swipe_range: float = 60.0
var swipe_damage: int = 2
var is_charging_swipe: bool = false
var swipe_charge_timer: float = 0.0
var swipe_direction: Vector2 = Vector2.ZERO
var can_swipe: bool = true

# ESCAPE mode - shooting
var fire_rate: float = 2.0
var fire_cooldown: float = 0.0


func _init() -> void:
	sprite_path = SPRITE_PATH


func _ready() -> void:
	super._ready()
	_setup_stats()
	_setup_pathfinder(EnemyPathfinder.PathMode.BRUTE)
	_set_mode(BehaviorMode.BRUTE)


func _setup_stats() -> void:
	health = 250
	max_health = 250
	speed = base_speed + speed_modifier  # Start in BRUTE mode with bonus speed
	power = 2
	is_alive = true


func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	_handle_mode_switch(delta)

	match current_mode:
		BehaviorMode.BRUTE:
			_handle_brute_mode(delta)
		BehaviorMode.ESCAPE:
			_handle_escape_mode(delta)


func _handle_mode_switch(delta: float) -> void:
	mode_timer -= delta

	if mode_timer <= 0:
		if current_mode == BehaviorMode.BRUTE:
			_set_mode(BehaviorMode.ESCAPE)
		else:
			_set_mode(BehaviorMode.BRUTE)
		mode_timer = mode_switch_interval


func _set_mode(mode: BehaviorMode) -> void:
	current_mode = mode
	is_charging_swipe = false
	can_swipe = true
	queue_redraw()

	match mode:
		BehaviorMode.BRUTE:
			speed = base_speed + speed_modifier
			if pathfinder:
				pathfinder.set_mode(EnemyPathfinder.PathMode.BRUTE)
		BehaviorMode.ESCAPE:
			speed = base_speed - speed_modifier
			if pathfinder:
				pathfinder.set_mode(EnemyPathfinder.PathMode.ESCAPE)


func _handle_brute_mode(delta: float) -> void:
	_move_toward_target()

	if is_charging_swipe:
		swipe_charge_timer -= delta
		if swipe_charge_timer <= 0:
			_execute_swipe()
	elif can_swipe and _is_player_in_range():
		_start_swipe_charge()


func _is_player_in_range() -> bool:
	if not target or not is_instance_valid(target):
		return false
	return global_position.distance_to(target.global_position) <= swipe_range * 1.5


func _start_swipe_charge() -> void:
	if not target or not is_instance_valid(target):
		return

	is_charging_swipe = true
	swipe_charge_timer = swipe_charge_time
	swipe_direction = (target.global_position - global_position).normalized()
	queue_redraw()


func _execute_swipe() -> void:
	is_charging_swipe = false
	can_swipe = false  # Can only swipe once per BRUTE phase
	queue_redraw()

	if not target or not is_instance_valid(target):
		return

	var to_player = target.global_position - global_position
	var distance = to_player.length()

	if distance > swipe_range * 1.5:
		return

	var angle_to_player = rad_to_deg(swipe_direction.angle_to(to_player.normalized()))
	if abs(angle_to_player) <= swipe_cone_angle / 2:
		if target.has_method("take_damage"):
			target.take_damage(swipe_damage)


func _handle_escape_mode(delta: float) -> void:
	_move_away_from_target()

	fire_cooldown -= delta
	if fire_cooldown <= 0 and target and is_instance_valid(target):
		_shoot_at_target(PROJECTILE_SCENE)
		fire_cooldown = fire_rate


func _draw() -> void:
	if is_charging_swipe:
		var cone_length = swipe_range * 1.5
		var half_angle = deg_to_rad(swipe_cone_angle / 2)
		var points = PackedVector2Array()
		points.append(Vector2.ZERO)

		for i in range(11):
			var angle = -half_angle + (half_angle * 2 * i / 10)
			var point = swipe_direction.rotated(angle) * cone_length
			points.append(point)

		points.append(Vector2.ZERO)
		draw_colored_polygon(points, Color(1.0, 0.5, 0.0, 0.3))
