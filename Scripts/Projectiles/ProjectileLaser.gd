extends IProjectile

class_name ProjectileLaser


enum State { CHARGING, FIRING, DONE }

const BEAM_DURATION = 2.0
const DAMAGE_INTERVAL = 0.33
const BASE_BEAM_SPEED = 300.0

var state: State = State.CHARGING
var beam_length: float = 500.0
var charge_progress: float = 0.0
var charge_time_required: float = 2.0
var beam_timer: float = 0.0
var damage_timer: float = 0.0

var _raycast: RayCast2D = null
var _line: Line2D = null
var _charge_indicator: Line2D = null


func _init() -> void:
	sprite_path = ""
	speed = 0.0
	lifetime = 999.0


func _ready() -> void:
	lifetime = 999.0

	super._ready()
	add_to_group("laser_projectile")

	if _has_existing_laser_from_owner():
		queue_free()
		return

	_setup_raycast()
	_setup_charge_indicator()


func _setup_raycast() -> void:
	_raycast = RayCast2D.new()
	_raycast.enabled = true
	_raycast.collide_with_bodies = true
	_raycast.collide_with_areas = false
	_raycast.collision_mask = 1
	_raycast.hit_from_inside = false
	_raycast.target_position = Vector2(beam_length, 0)
	add_child(_raycast)


func _setup_charge_indicator() -> void:
	_charge_indicator = Line2D.new()
	_charge_indicator.width = 2.0
	_charge_indicator.default_color = Color(1.0, 0.5, 0.5, 0.5)
	_charge_indicator.add_point(Vector2.ZERO)
	_charge_indicator.add_point(Vector2.ZERO)
	add_child(_charge_indicator)


func _setup_beam_visual() -> void:
	_line = Line2D.new()
	_line.width = 6.0
	_line.default_color = Color(1.0, 0.2, 0.2, 0.9)
	_line.add_point(Vector2.ZERO)
	_line.add_point(Vector2(beam_length, 0))
	add_child(_line)

	if _charge_indicator:
		_charge_indicator.visible = false


func initialize(shooter: Node2D, dir: Vector2, shooter_velocity: Vector2 = Vector2.ZERO) -> void:
	owner_node = shooter
	direction = dir.normalized()
	inherited_velocity = Vector2.ZERO

	if shooter is ICharacter:
		damage = shooter.power

	if shooter.get("fire_rate"):
		charge_time_required = 10.0 / shooter.fire_rate
	else:
		charge_time_required = 2.0

	if shooter.get("shot_range"):
		beam_length = shooter.shot_range * BASE_BEAM_SPEED
	else:
		beam_length = 500.0

	rotation = direction.angle()


func _has_existing_laser_from_owner() -> bool:
	var lasers = get_tree().get_nodes_in_group("laser_projectile")
	for laser in lasers:
		if laser != self and laser.owner_node == owner_node:
			return true
	return false


func _physics_process(delta: float) -> void:
	match state:
		State.CHARGING:
			_process_charging(delta)
		State.FIRING:
			_process_firing(delta)
		State.DONE:
			queue_free()


func _process_charging(delta: float) -> void:
	if owner_node and is_instance_valid(owner_node):
		global_position = owner_node.global_position + direction * 20.0

	var shoot_dir = _get_shoot_direction()
	if shoot_dir == Vector2.ZERO:
		queue_free()
		return

	direction = shoot_dir.normalized()
	rotation = direction.angle()

	charge_progress += delta
	_update_charge_indicator()

	if charge_progress >= charge_time_required:
		_start_firing()


func _get_shoot_direction() -> Vector2:
	var dir = Vector2(
		Input.get_axis("shoot_left", "shoot_right"),
		Input.get_axis("shoot_up", "shoot_down")
	)
	return dir.normalized() if dir != Vector2.ZERO else Vector2.ZERO


func _update_charge_indicator() -> void:
	if not _charge_indicator:
		return

	var progress = charge_progress / charge_time_required
	var indicator_length = 30.0 + progress * 50.0
	_charge_indicator.set_point_position(1, Vector2(indicator_length, 0))
	_charge_indicator.default_color = Color(1.0, 1.0 - progress, 1.0 - progress, 0.5 + progress * 0.5)


func _start_firing() -> void:
	state = State.FIRING
	beam_timer = BEAM_DURATION
	_setup_beam_visual()


func _process_firing(delta: float) -> void:
	if owner_node and is_instance_valid(owner_node):
		global_position = owner_node.global_position + direction * 20.0

	beam_timer -= delta
	if beam_timer <= 0:
		state = State.DONE
		return

	damage_timer -= delta
	if damage_timer <= 0:
		_deal_beam_damage()
		damage_timer = DAMAGE_INTERVAL

	_update_beam_endpoint()


func _deal_beam_damage() -> void:
	_raycast.force_raycast_update()
	var beam_end = global_position + direction * beam_length
	if _raycast.is_colliding():
		beam_end = _raycast.get_collision_point()

	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy == owner_node or not is_instance_valid(enemy):
			continue
		if _is_point_on_beam(enemy.global_position, beam_end):
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)


func _is_point_on_beam(point: Vector2, beam_end: Vector2) -> bool:
	var beam_start = global_position
	var beam_vec = beam_end - beam_start
	var beam_len = beam_vec.length()
	if beam_len == 0:
		return false

	var to_point = point - beam_start
	var projection = to_point.dot(beam_vec.normalized())

	if projection < 0 or projection > beam_len:
		return false

	var closest_point = beam_start + beam_vec.normalized() * projection
	var distance = point.distance_to(closest_point)

	return distance < 20.0


func _update_beam_endpoint() -> void:
	if not _raycast or not _line:
		return

	_raycast.force_raycast_update()

	var end_point = Vector2(beam_length, 0)
	if _raycast.is_colliding():
		var collision_point = _raycast.get_collision_point()
		end_point = to_local(collision_point)

	_line.set_point_position(1, end_point)


func _on_body_entered(_body: Node2D) -> void:
	pass
