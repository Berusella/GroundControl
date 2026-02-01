extends IProjectile

class_name ProjectileHoming


var target: Node2D = null
var turn_speed: float = 5.0
var detection_range: float = 300.0


func _init() -> void:
	sprite_path = "res://Sprites/Projectiles/projectile_homing.png"


func _ready() -> void:
	super._ready()
	speed = 200.0
	_find_nearest_target()


func _physics_process(delta: float) -> void:
	# Re-acquire target if lost
	if not target or not is_instance_valid(target):
		_find_nearest_target()

	if target and is_instance_valid(target):
		var target_dir = (target.global_position - global_position).normalized()
		direction = direction.lerp(target_dir, turn_speed * delta).normalized()

	position += direction * speed * delta


func _find_nearest_target() -> void:
	var nearest_dist = detection_range
	target = null

	# Find enemies if shot by player, find player if shot by enemy
	if owner_node is Player:
		var enemies = get_tree().get_nodes_in_group("enemy")
		for enemy in enemies:
			if not is_instance_valid(enemy):
				continue
			var dist = global_position.distance_to(enemy.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				target = enemy
	else:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target = players[0]


func set_target(t: Node2D) -> void:
	target = t
