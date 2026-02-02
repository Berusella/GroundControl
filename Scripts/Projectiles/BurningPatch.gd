extends IProjectile

class_name BurningPatch


const SPRITE = "res://Sprites/Projectiles/burning_patch.png"


func _init() -> void:
	sprite_path = SPRITE
	speed = 0.0  # Stationary
	lifetime = 5.0
	persistent = true  # Don't destroy on hit


func _physics_process(_delta: float) -> void:
	# Override parent - stay in place, don't move
	pass


func _on_body_entered(body: Node2D) -> void:
	if body == owner_node:
		return
	# Deal damage to enemies
	if body is IEnemy:
		body.take_damage(damage)
	# Don't destroy on hit - it's a persistent hazard
