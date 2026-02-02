extends IEnemy

class_name Soldier


const SPRITE_PATH = "res://Sprites/Characters/Enemies/soldier.png"
const PROJECTILE_SCENE = preload("res://Scenes/Projectiles/ProjectileStandard.tscn")

var fire_rate: float = 2.0  # Shoot every 2 seconds
var fire_cooldown: float = 0.0
var raycast: RayCast2D = null


func _init() -> void:
	sprite_path = SPRITE_PATH


func _ready() -> void:
	super._ready()
	_setup_stats()
	_setup_raycast()
	_setup_pathfinder(EnemyPathfinder.PathMode.ESCAPE)


func _setup_stats() -> void:
	health = 15
	max_health = 15
	speed = 60  # 0.6 * 100 base
	power = 1
	is_alive = true


func _setup_raycast() -> void:
	# Create RayCast2D for line-of-sight checking
	raycast = RayCast2D.new()
	raycast.enabled = true
	raycast.collision_mask = 1  # Check for walls/obstacles on layer 1
	raycast.hit_from_inside = false
	add_child(raycast)


func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	_move_away_from_target()
	_handle_shooting(delta)


func _handle_shooting(delta: float) -> void:
	fire_cooldown -= delta

	if fire_cooldown <= 0 and target and is_instance_valid(target):
		if _has_line_of_sight():
			_shoot_at_target(PROJECTILE_SCENE)
			fire_cooldown = fire_rate


func _has_line_of_sight() -> bool:
	if not target or not is_instance_valid(target) or not raycast:
		return false

	# Point raycast at target
	var direction = target.global_position - global_position
	raycast.target_position = direction
	raycast.force_raycast_update()

	# If nothing is hit, or if hit object is the player, we have line of sight
	if not raycast.is_colliding():
		return true

	var collider = raycast.get_collider()
	if collider and collider.is_in_group("player"):
		return true

	return false
