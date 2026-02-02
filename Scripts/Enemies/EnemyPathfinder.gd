extends Node

class_name EnemyPathfinder


enum PathMode { BRUTE, ESCAPE, DASH }

var nav_agent: NavigationAgent2D = null
var parent_enemy: CharacterBody2D = null
var target: Node2D = null
var path_mode: PathMode = PathMode.BRUTE
var escape_distance: float = 300.0
var _is_ready: bool = false

var dash_charge: float = 0.0
var dash_charge_threshold: float = 10.0
var is_dashing: bool = false
var dash_duration: float = 0.3
var dash_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var dash_speed_multiplier: float = 5.0


func _ready() -> void:
	parent_enemy = get_parent() as CharacterBody2D
	if not parent_enemy:
		push_warning("EnemyPathfinder must be child of CharacterBody2D")
		return

	_setup_navigation_agent()


func _setup_navigation_agent() -> void:
	nav_agent = NavigationAgent2D.new()
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 4.0
	nav_agent.path_max_distance = 50.0
	nav_agent.avoidance_enabled = false
	nav_agent.debug_enabled = false
	parent_enemy.add_child(nav_agent)

	await get_tree().physics_frame
	if is_instance_valid(nav_agent) and is_instance_valid(self):
		nav_agent.velocity_computed.connect(_on_velocity_computed)
		_is_ready = true


func _on_velocity_computed(_safe_velocity: Vector2) -> void:
	pass


func set_target(new_target: Node2D) -> void:
	target = new_target


func set_mode(mode: PathMode) -> void:
	path_mode = mode


func get_movement_direction() -> Vector2:
	if not parent_enemy or not target or not is_instance_valid(target):
		return Vector2.ZERO

	if not _is_ready or not nav_agent or not nav_agent.is_inside_tree():
		return _get_direct_direction()

	match path_mode:
		PathMode.BRUTE:
			return _get_brute_direction()
		PathMode.ESCAPE:
			return _get_escape_direction()
		PathMode.DASH:
			return _get_dash_direction()

	return Vector2.ZERO


func update_dash(delta: float, base_speed: float) -> void:
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			dash_charge = 0.0
	else:
		dash_charge += base_speed * delta * 0.01


func try_start_dash() -> bool:
	if is_dashing:
		return false
	if dash_charge >= dash_charge_threshold:
		is_dashing = true
		dash_timer = dash_duration
		if target and is_instance_valid(target):
			dash_direction = (target.global_position - parent_enemy.global_position).normalized()
		return true
	return false


func get_speed_multiplier() -> float:
	return dash_speed_multiplier if is_dashing else 1.0


func _get_brute_direction() -> Vector2:
	nav_agent.target_position = target.global_position

	if nav_agent.is_navigation_finished():
		return Vector2.ZERO

	var next_pos = nav_agent.get_next_path_position()
	var direction = (next_pos - parent_enemy.global_position).normalized()

	if direction == Vector2.ZERO:
		return _get_direct_direction()

	return direction


func _get_escape_direction() -> Vector2:
	var to_target = target.global_position - parent_enemy.global_position
	var distance_to_target = to_target.length()

	if distance_to_target >= escape_distance:
		return Vector2.ZERO

	var escape_dir = -to_target.normalized()
	var escape_point = parent_enemy.global_position + escape_dir * escape_distance

	escape_point = _clamp_to_room_bounds(escape_point)

	nav_agent.target_position = escape_point

	if nav_agent.is_navigation_finished():
		return escape_dir

	var next_pos = nav_agent.get_next_path_position()
	var direction = (next_pos - parent_enemy.global_position).normalized()

	if direction == Vector2.ZERO:
		return escape_dir

	return direction


func _get_dash_direction() -> Vector2:
	if is_dashing:
		return dash_direction
	else:
		return _get_brute_direction() * 0.3


func _get_direct_direction() -> Vector2:
	var to_target = target.global_position - parent_enemy.global_position

	match path_mode:
		PathMode.BRUTE:
			return to_target.normalized()
		PathMode.ESCAPE:
			return -to_target.normalized()
		PathMode.DASH:
			if is_dashing:
				return dash_direction
			return to_target.normalized() * 0.3

	return Vector2.ZERO


func _clamp_to_room_bounds(point: Vector2) -> Vector2:
	var min_bounds = Vector2(-350, -280)
	var max_bounds = Vector2(390, 260)

	return Vector2(
		clamp(point.x, min_bounds.x, max_bounds.x),
		clamp(point.y, min_bounds.y, max_bounds.y)
	)


func is_navigation_available() -> bool:
	if not nav_agent:
		return false

	var map_rid = nav_agent.get_navigation_map()
	return map_rid.is_valid()
