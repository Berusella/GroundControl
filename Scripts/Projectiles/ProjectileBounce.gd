extends IProjectile

class_name ProjectileBounce


var bounce_count: int = 3
var hit_enemies: Array = []  # Track which enemies we've hit this bounce


func _init() -> void:
	sprite_path = "res://Sprites/Projectiles/projectile_bounce.png"


func _ready() -> void:
	super._ready()
	speed = 250.0


func _on_body_entered(body: Node2D) -> void:
	if body == owner_node:
		return

	if body is IEnemy:
		# Skip if we already hit this enemy in this bounce chain
		if body in hit_enemies:
			return

		body.take_damage(damage)
		hit_enemies.append(body)
		bounce_count -= 1

		if bounce_count <= 0:
			queue_free()
		else:
			# Bounce towards nearest other enemy
			_bounce_to_next_enemy(body)
	elif body is Player:
		# Player hitbox handles damage
		return
	else:
		# Hit wall or obstacle - destroy
		queue_free()


func _bounce_to_next_enemy(hit_enemy: Node2D) -> void:
	var nearest_enemy: Node2D = null
	var nearest_dist: float = 300.0  # Max bounce range

	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy == hit_enemy or enemy in hit_enemies:
			continue
		if not is_instance_valid(enemy):
			continue

		var dist = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_enemy = enemy

	if nearest_enemy:
		direction = (nearest_enemy.global_position - global_position).normalized()
	else:
		# No enemy to bounce to - continue in reflected direction
		direction = -direction
