extends IProjectile

class_name ProjectileBounce


var bounce_count: int = 3
var wall_bounce_count: int = 3
var hit_enemies: Array = []

var _raycast: RayCast2D


func _init() -> void:
	sprite_path = "res://Sprites/Projectiles/projectile_bounce.png"


func _ready() -> void:
	super._ready()
	speed = 250.0
	_setup_raycast()


func _setup_raycast() -> void:
	_raycast = RayCast2D.new()
	_raycast.enabled = true
	_raycast.collide_with_bodies = true
	_raycast.collision_mask = 1
	add_child(_raycast)


func _physics_process(delta: float) -> void:
	_raycast.target_position = direction * speed * delta * 2

	var movement = direction * speed + inherited_velocity
	position += movement * delta


func _on_body_entered(body: Node2D) -> void:
	if body == owner_node:
		return

	if body is IEnemy:
		if body in hit_enemies:
			return

		body.take_damage(damage)
		hit_enemies.append(body)
		bounce_count -= 1

		if bounce_count <= 0:
			queue_free()
		else:
			_bounce_to_next_enemy(body)
	elif body is Player:
		return
	else:
		_bounce_off_wall()


func _bounce_off_wall() -> void:
	wall_bounce_count -= 1
	if wall_bounce_count <= 0:
		queue_free()
		return

	if _raycast.is_colliding():
		var normal = _raycast.get_collision_normal()
		direction = direction.bounce(normal)
	else:
		direction = -direction

	hit_enemies.clear()


func _bounce_to_next_enemy(hit_enemy: Node2D) -> void:
	var nearest_enemy: Node2D = null
	var nearest_dist: float = 300.0

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
		direction = -direction
