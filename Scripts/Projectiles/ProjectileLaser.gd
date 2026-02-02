extends IProjectile

class_name ProjectileLaser

## Charged laser projectile. Charges while shoot is held, then fires continuous beam.

enum State { CHARGING, FIRING, DONE }

const BEAM_DURATION = 2.0
const DAMAGE_INTERVAL = 0.33  # 3 hits per second
const BASE_BEAM_SPEED = 300.0  # Used to calculate beam length from range

var state: State = State.CHARGING
var beam_length: float = 500.0
var charge_progress: float = 0.0
var charge_time_required: float = 2.0  # Will be set based on owner's fire_rate
var beam_timer: float = 0.0
var damage_timer: float = 0.0

var _raycast: RayCast2D = null
var _line: Line2D = null
var _charge_indicator: Line2D = null


func _init() -> void:
	sprite_path = ""  # No sprite during charge, we use custom visuals
	speed = 0.0  # Doesn't move like normal projectile
	lifetime = 999.0  # Managed manually


func _ready() -> void:
	# Restore lifetime before super._ready() starts the timer
	lifetime = 999.0

	super._ready()
	add_to_group("laser_projectile")

	# Check if another laser from this owner already exists - if so, self-destruct
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
	_raycast.collision_mask = 3  # Walls (1) and enemies (2)
	_raycast.hit_from_inside = false
	_raycast.target_position = Vector2(beam_length, 0)  # Local space (node is rotated)
	add_child(_raycast)


func _setup_charge_indicator() -> void:
	# Small line showing charge direction
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
	_line.add_point(Vector2(beam_length, 0))  # Local space (node is rotated)
	add_child(_line)

	if _charge_indicator:
		_charge_indicator.visible = false


func initialize(shooter: Node2D, dir: Vector2, shooter_velocity: Vector2 = Vector2.ZERO) -> void:
	owner_node = shooter
	direction = dir.normalized()
	inherited_velocity = Vector2.ZERO  # Laser doesn't inherit velocity

	if shooter is ICharacter:
		damage = shooter.power

	# Calculate charge time: 10 / fire_rate
	if shooter.get("fire_rate"):
		charge_time_required = 10.0 / shooter.fire_rate
	else:
		charge_time_required = 2.0

	# Calculate beam length from shot_range (range = lifetime * speed)
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
	# Follow owner
	if owner_node and is_instance_valid(owner_node):
		global_position = owner_node.global_position + direction * 20.0

	# Check if still shooting (any direction counts, allows aiming while charging)
	var shoot_dir = _get_shoot_direction()
	if shoot_dir == Vector2.ZERO:
		# Released shoot - cancel
		queue_free()
		return

	# Update direction to current aim while charging
	direction = shoot_dir.normalized()
	rotation = direction.angle()

	# Update charge
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
	# Follow owner while firing
	if owner_node and is_instance_valid(owner_node):
		global_position = owner_node.global_position + direction * 20.0

	beam_timer -= delta
	if beam_timer <= 0:
		state = State.DONE
		return

	# Deal damage periodically
	damage_timer -= delta
	if damage_timer <= 0:
		_deal_beam_damage()
		damage_timer = DAMAGE_INTERVAL

	_update_beam_endpoint()


func _deal_beam_damage() -> void:
	if not _raycast:
		return

	_raycast.force_raycast_update()

	if _raycast.is_colliding():
		var collider = _raycast.get_collider()
		if collider and collider != owner_node:
			if collider is IEnemy and collider.has_method("take_damage"):
				collider.take_damage(damage)


func _update_beam_endpoint() -> void:
	if not _raycast or not _line:
		return

	_raycast.force_raycast_update()

	var end_point = Vector2(beam_length, 0)  # Local space, rotated by node
	if _raycast.is_colliding():
		var collision_point = _raycast.get_collision_point()
		end_point = to_local(collision_point)

	_line.set_point_position(1, end_point)


# Override parent - don't destroy on body contact during charging/firing
func _on_body_entered(_body: Node2D) -> void:
	pass  # Beam handles its own damage
