extends IProjectile

class_name ProjectileLaser


var pierce_count: int = 3


func _init() -> void:
	sprite_path = "res://Sprites/Projectiles/projectile_laser.png"


func _ready() -> void:
	super._ready()
	speed = 500.0


func _on_body_entered(body: Node2D) -> void:
	if body == owner_node:
		return
	if body is ICharacter:
		body.take_damage(damage)
		pierce_count -= 1
		if pierce_count <= 0:
			queue_free()
