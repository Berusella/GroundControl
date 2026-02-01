extends IProjectile

class_name ProjectileBounce


var bounce_count: int = 3


func _init() -> void:
	sprite_path = "res://Sprites/Projectiles/projectile_bounce.png"


func _ready() -> void:
	super._ready()
	speed = 250.0


func _on_body_entered(body: Node2D) -> void:
	if body == owner_node:
		return

	if body is ICharacter:
		body.take_damage(damage)
		queue_free()
	else:
		# Bounce off walls
		bounce_count -= 1
		if bounce_count <= 0:
			queue_free()
		else:
			direction = direction.bounce(Vector2.UP)  # Simplified, should use collision normal
