extends ICharacter

class_name IEnemy


var target: Node2D = null
var attack_damage: int = 10
var attack_range: float = 50.0
var detection_range: float = 200.0
var sprite: Sprite2D = null
var sprite_path: String = ""
var sprite_scale: float = 1.5  # Default sprite scale, override in subclass
var pathfinder: EnemyPathfinder = null
var shot_range: float = 2.0  # Projectile lifetime in seconds (2x player default)

# Spawn delay - enemies wait before attacking
var spawn_delay: float = 1.5
var spawn_timer: float = 0.0
var is_spawning: bool = true

# Mind control support
var is_player_controlled: bool = false

# Invert support (for player INVERT special)
var original_path_mode: int = -1  # Stores mode before invert, -1 = not inverted


func _ready() -> void:
	add_to_group("enemy")
	_setup_sprite()
	_find_player()
	_start_spawn_delay()


func _start_spawn_delay() -> void:
	spawn_timer = spawn_delay
	is_spawning = true
	set_physics_process(false)
	set_process(true)  # Enable _process for spawn delay countdown


func _process_spawn_delay(delta: float) -> void:
	if not is_spawning:
		return

	spawn_timer -= delta
	if spawn_timer <= 0:
		is_spawning = false
		if not is_player_controlled:
			set_physics_process(true)
			set_process(false)  # Disable _process when not needed


func _find_player() -> void:
	# Find player in the scene tree
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]


func _setup_sprite() -> void:
	if not sprite_path.is_empty():
		sprite = SpriteFactory.create_and_attach(self, sprite_path)
		if sprite:
			sprite.scale = Vector2(sprite_scale, sprite_scale)


func attack() -> void:
	pass


func detect_player() -> void:
	pass


func chase_target() -> void:
	pass


func on_death() -> void:
	pass


func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		health = 0
		die()


func die() -> void:
	is_alive = false
	queue_free()


## Shared shooting method for ranged enemies
## projectile_scene: The preloaded projectile scene to instantiate
## spawn_offset_distance: How far from the enemy to spawn the projectile (default 20.0)
func _shoot_at_target(projectile_scene: PackedScene, spawn_offset_distance: float = 20.0) -> void:
	if not target or not is_instance_valid(target):
		return

	var direction = (target.global_position - global_position).normalized()
	var projectile = projectile_scene.instantiate()
	var spawn_offset = direction * spawn_offset_distance
	projectile.global_position = global_position + spawn_offset
	projectile.lifetime = shot_range
	projectile.initialize(self, direction)
	get_tree().current_scene.add_child(projectile)


## Setup pathfinder for enemies that need navigation
## mode: EnemyPathfinder.PathMode.BRUTE or EnemyPathfinder.PathMode.ESCAPE
func _setup_pathfinder(mode: int) -> void:
	pathfinder = EnemyPathfinder.new()
	add_child(pathfinder)
	pathfinder.set_mode(mode)
	pathfinder.set_target(target)


## Shared movement method - moves toward target using pathfinder if available
## Falls back to direct movement if pathfinder is not set
func _move_toward_target() -> void:
	if not target or not is_instance_valid(target):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if pathfinder:
		pathfinder.set_target(target)
		velocity = pathfinder.get_movement_direction() * speed
	else:
		# Fallback: direct movement toward target
		velocity = (target.global_position - global_position).normalized() * speed

	move_and_slide()


## Shared movement method - moves away from target using pathfinder if available
## Falls back to direct movement if pathfinder is not set
func _move_away_from_target() -> void:
	if not target or not is_instance_valid(target):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if pathfinder:
		pathfinder.set_target(target)
		velocity = pathfinder.get_movement_direction() * speed
	else:
		# Fallback: direct movement away from target
		velocity = (global_position - target.global_position).normalized() * speed

	move_and_slide()


func set_player_controlled(controlled: bool) -> void:
	is_player_controlled = controlled
	if controlled:
		# Swap to player-controlled movement
		set_physics_process(false)
		set_process(true)
	else:
		# Restore normal AI movement
		set_process(false)
		set_physics_process(true)


## Invert movement mode: BRUTE becomes ESCAPE, ESCAPE becomes BRUTE
## Returns true if mode was swapped, false if enemy has no pathfinder or uses DASH/other
func invert_movement() -> bool:
	if not pathfinder:
		return false

	var current_mode = pathfinder.path_mode

	# Only swap BRUTE and ESCAPE
	if current_mode == EnemyPathfinder.PathMode.BRUTE:
		original_path_mode = current_mode
		pathfinder.set_mode(EnemyPathfinder.PathMode.ESCAPE)
		return true
	elif current_mode == EnemyPathfinder.PathMode.ESCAPE:
		original_path_mode = current_mode
		pathfinder.set_mode(EnemyPathfinder.PathMode.BRUTE)
		return true

	return false


## Restore original movement mode after invert ends
func restore_movement() -> void:
	if not pathfinder or original_path_mode == -1:
		return

	pathfinder.set_mode(original_path_mode)
	original_path_mode = -1


func _process(delta: float) -> void:
	# Handle spawn delay countdown
	_process_spawn_delay(delta)

	# Player-controlled movement
	if not is_player_controlled:
		return
	var dir = Vector2(
		Input.get_axis("Move_left", "Move_right"),
		Input.get_axis("Move_up", "Move_down")
	).normalized()
	velocity = dir * speed
	move_and_slide()
