extends IEnemy

class_name SmallSapling


const SPRITE_PATH = "res://Sprites/Characters/Enemies/small_sapling.png"
const PROJECTILE_SCENE = preload("res://Scenes/Projectiles/ProjectileStandard.tscn")

var fire_rate: float = 1.5
var fire_cooldown: float = 0.0


func _init() -> void:
	sprite_path = SPRITE_PATH


func _ready() -> void:
	super._ready()
	_setup_stats()


func _setup_stats() -> void:
	health = 17
	max_health = 17
	speed = 0
	power = 1
	is_alive = true


func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	_handle_shooting(delta)


func _handle_shooting(delta: float) -> void:
	fire_cooldown -= delta

	if fire_cooldown <= 0 and target:
		_shoot_at_target(PROJECTILE_SCENE)
		fire_cooldown = fire_rate
