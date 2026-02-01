extends Area2D

class_name IProjectile


var direction: Vector2 = Vector2.ZERO
var speed: float = 300.0
var damage: int = 0
var owner_node: Node2D = null
var sprite: Sprite2D = null
var sprite_path: String = ""
var lifetime: float = 5.0
var inherited_velocity: Vector2 = Vector2.ZERO
var momentum_retention: float = 0.5  # How much of shooter's velocity to keep
var _lifetime_timer: SceneTreeTimer = null


func _ready() -> void:
	add_to_group("projectile")
	body_entered.connect(_on_body_entered)
	_setup_sprite()
	_start_lifetime_timer()


func _exit_tree() -> void:
	if _lifetime_timer and _lifetime_timer.timeout.is_connected(_on_lifetime_expired):
		_lifetime_timer.timeout.disconnect(_on_lifetime_expired)


func _setup_sprite() -> void:
	if not sprite_path.is_empty():
		sprite = SpriteFactory.create_and_attach(self, sprite_path)


func _start_lifetime_timer() -> void:
	_lifetime_timer = get_tree().create_timer(lifetime)
	_lifetime_timer.timeout.connect(_on_lifetime_expired)


func _on_lifetime_expired() -> void:
	if is_instance_valid(self) and is_inside_tree():
		queue_free()


func _physics_process(delta: float) -> void:
	var movement = direction * speed + inherited_velocity
	position += movement * delta


func initialize(shooter: Node2D, dir: Vector2, shooter_velocity: Vector2 = Vector2.ZERO) -> void:
	owner_node = shooter
	direction = dir.normalized()
	inherited_velocity = shooter_velocity * momentum_retention
	if shooter is ICharacter:
		damage = shooter.power


func _on_body_entered(body: Node2D) -> void:
	if body == owner_node:
		return
	# Only deal damage to enemies, player hitbox handles player damage
	if body is IEnemy:
		body.take_damage(damage)
	elif body is Player:
		# Player hitbox handles damage, don't destroy here (hitbox will)
		return
	# Destroy on any non-player hit (enemies, walls, obstacles)
	queue_free()
