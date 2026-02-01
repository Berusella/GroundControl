extends IProjectile

class_name ProjectileStandard


func _init() -> void:
	sprite_path = "res://Sprites/Projectiles/projectile_standard.png"


func _ready() -> void:
	super._ready()
	speed = 300.0
