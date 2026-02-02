extends IProjectile

class_name BurningPatch


const SPRITE = "res://Sprites/Projectiles/burning_patch.png"


func _init() -> void:
	sprite_path = SPRITE
	speed = 0.0
	lifetime = 5.0
	persistent = true


func _physics_process(_delta: float) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	if body == owner_node:
		return
	if body is IEnemy:
		body.take_damage(damage)
