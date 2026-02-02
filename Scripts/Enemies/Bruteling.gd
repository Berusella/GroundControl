extends IEnemy

class_name Bruteling


const SPRITE_PATH = "res://Sprites/Characters/Enemies/bruteling.png"


func _init() -> void:
	sprite_path = SPRITE_PATH


func _ready() -> void:
	super._ready()
	_setup_stats()
	_setup_pathfinder(EnemyPathfinder.PathMode.BRUTE)


func _setup_stats() -> void:
	health = 25
	max_health = 25
	speed = 90
	power = 1
	is_alive = true


func _physics_process(_delta: float) -> void:
	if not is_alive:
		return

	_move_toward_target()
