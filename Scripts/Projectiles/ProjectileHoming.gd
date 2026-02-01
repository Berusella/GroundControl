extends IProjectile

class_name ProjectileHoming


var target: Node2D = null
var turn_speed: float = 5.0


func _init() -> void:
	sprite_path = "res://Sprites/Projectiles/projectile_homing.png"


func _ready() -> void:
	super._ready()
	speed = 200.0


func _physics_process(delta: float) -> void:
	if target and is_instance_valid(target):
		var target_dir = (target.position - position).normalized()
		direction = direction.lerp(target_dir, turn_speed * delta).normalized()

	position += direction * speed * delta


func set_target(t: Node2D) -> void:
	target = t
