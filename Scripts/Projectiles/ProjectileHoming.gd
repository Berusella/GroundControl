extends IProjectile

class_name ProjectileHoming


var target: Node2D = null
var turn_speed: float = 5.0
var _targets_in_range: Array[Node2D] = []

@onready var detection_area: Area2D = $DetectionArea


func _init() -> void:
	sprite_path = "res://Sprites/Projectiles/projectile_homing.png"


func _ready() -> void:
	super._ready()
	speed = 200.0
	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)


func _physics_process(delta: float) -> void:
	if target and not is_instance_valid(target):
		target = null

	if not target:
		_find_nearest_target()

	if target and is_instance_valid(target):
		var target_dir = (target.global_position - global_position).normalized()
		direction = direction.lerp(target_dir, turn_speed * delta).normalized()

	var movement = direction * speed + inherited_velocity
	position += movement * delta


func _on_detection_body_entered(body: Node2D) -> void:
	if body == owner_node:
		return

	if owner_node is Player and body is IEnemy:
		_targets_in_range.append(body)
	elif not (owner_node is Player) and body is Player:
		_targets_in_range.append(body)


func _on_detection_body_exited(body: Node2D) -> void:
	_targets_in_range.erase(body)
	if target == body:
		target = null


func _find_nearest_target() -> void:
	var nearest_dist = INF

	for potential_target in _targets_in_range:
		if not is_instance_valid(potential_target):
			continue
		var dist = global_position.distance_to(potential_target.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			target = potential_target


func set_target(t: Node2D) -> void:
	target = t
