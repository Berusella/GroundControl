extends ICharacter

class_name Player


const SPRITE_PATH = "res://Sprites/Characters/Player/player.png"
const DEFAULT_PROJECTILE = preload("res://Scenes/Projectiles/ProjectileStandard.tscn")

var projectile_scene: PackedScene = DEFAULT_PROJECTILE

var keys: int = 0
var sprite: Sprite2D = null

# Shooting
var fire_rate: float = 0.2  # Seconds between shots
var fire_cooldown: float = 0.0
var shot_range: float = 1.5  # Projectile lifetime in seconds

# Invincibility
var invincibility_duration: float = 1.0  # Seconds of i-frames after taking damage
var invincibility_timer: float = 0.0
var is_invincible: bool = false


func _ready() -> void:
	add_to_group("player")
	_setup_stats()
	_setup_sprite()
	_setup_hitbox()


func _setup_hitbox() -> void:
	var hitbox = $Hitbox
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	hitbox.area_entered.connect(_on_hitbox_area_entered)


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body is IEnemy:
		take_damage(body.power)


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area is IProjectile and area.owner_node != self:
		take_damage(area.damage)
		area.queue_free()


func _setup_stats() -> void:
	health = 10
	max_health = 10
	speed = 200
	power = 3
	is_alive = true


func _setup_sprite() -> void:
	sprite = SpriteFactory.create_and_attach(self, SPRITE_PATH)


func _physics_process(delta: float) -> void:
	_handle_movement()
	_handle_shooting(delta)
	_handle_invincibility(delta)


func _handle_invincibility(delta: float) -> void:
	if is_invincible:
		invincibility_timer -= delta
		# Flash effect - toggle visibility
		if sprite:
			sprite.visible = int(invincibility_timer * 10) % 2 == 0
		if invincibility_timer <= 0:
			is_invincible = false
			invincibility_timer = 0.0
			if sprite:
				sprite.visible = true


func _handle_movement() -> void:
	var direction = Vector2.ZERO
	direction.x = Input.get_axis("Move_left", "Move_right")
	direction.y = Input.get_axis("Move_up", "Move_down")
	direction = direction.normalized()

	velocity = direction * speed
	move_and_slide()


func _handle_shooting(delta: float) -> void:
	fire_cooldown -= delta

	var shoot_direction = _get_shoot_direction()
	if shoot_direction != Vector2.ZERO and fire_cooldown <= 0:
		_shoot(shoot_direction)
		fire_cooldown = fire_rate


func _get_shoot_direction() -> Vector2:
	var direction = Vector2.ZERO
	direction.x = Input.get_axis("shoot_left", "shoot_right")
	direction.y = Input.get_axis("shoot_up", "shoot_down")

	if direction != Vector2.ZERO:
		direction = direction.normalized()

	return direction


func _shoot(direction: Vector2) -> void:
	var projectile = projectile_scene.instantiate()
	var spawn_offset = direction * 20.0
	projectile.global_position = global_position + spawn_offset
	projectile.lifetime = shot_range
	projectile.initialize(self, direction)
	get_tree().current_scene.add_child(projectile)


func take_damage(amount: int) -> void:
	if is_invincible:
		return

	health -= amount
	is_invincible = true
	invincibility_timer = invincibility_duration

	if health <= 0:
		health = 0
		die()


func heal(amount: int) -> void:
	health += amount
	if health > max_health:
		health = max_health


func die() -> void:
	is_alive = false
	queue_free()
