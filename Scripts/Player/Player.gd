extends ICharacter

class_name Player


signal item_picked_up(item_data: Dictionary)
signal player_died(collected_items: Array[Dictionary])

const SPRITE_PATH = "res://Sprites/Characters/Player/player.png"
const DEFAULT_PROJECTILE = preload("res://Scenes/Projectiles/ProjectileStandard.tscn")
const EXPLOSION_SCENE = preload("res://Scenes/Effects/Explosion.tscn")
const PROJECTILE_SCENES = {
	"homing": preload("res://Scenes/Projectiles/ProjectileHoming.tscn"),
	"bounce": preload("res://Scenes/Projectiles/ProjectileBounce.tscn"),
	"laser": preload("res://Scenes/Projectiles/ProjectileLaser.tscn")
}

var projectile_scene: PackedScene = DEFAULT_PROJECTILE

const SPECIAL_COOLDOWNS = {
	"PEW PEW": 3, "BIG BOOM": 3, "ASCEND": 5, "INVERT": 2,
	"MIND CONTROL": 5, "TIME STOP": 4, "SPEED SHOT": 6, "COPY": 3
}

# Special ability constants
const BIG_BOOM_RADIUS: float = 150.0
const BIG_BOOM_DAMAGE_MULTIPLIER: int = 10
const SPEED_SHOT_FIRE_RATE: float = 10.0
const SPEED_SHOT_DURATION: float = 1.0
const TIME_STOP_DURATION: float = 10.0
const INVERT_DURATION: float = 10.0
const MIND_CONTROL_DURATION: float = 5.0
const PEW_PEW_SCALE: float = 3.0
const PEW_PEW_DAMAGE_MULTIPLIER: float = 1.5

var keys: int = 0
var sprite: Sprite2D = null

# Shooting
var fire_rate: float = 2.0  # Shots per second
var fire_cooldown: float = 0.0
var shot_range: float = 1.0  # Projectile lifetime in seconds

# Invincibility
var invincibility_duration: float = 1.0  # Seconds of i-frames after taking damage
var invincibility_timer: float = 0.0
var is_invincible: bool = false

# Health cap
const MAX_HEALTH_CAP: int = 20  # Maximum health player can have

# Item system
var collected_items: Array[Dictionary] = []
var extra_lives: int = 0
var current_special: String = ""
var special_cooldown: int = 0  # Rooms until usable
var special_max_cooldown: int = 0  # For UI progress display
var projectile_modifiers: Array[String] = []

# Active effects tracking
var active_effects: Dictionary = {}  # {"effect_name": remaining_time}
var is_flying: bool = false
var is_copied: bool = false
var original_fire_rate: float = 0.0
var original_sprite_path: String = SPRITE_PATH
var controlled_enemy: IEnemy = null


func _ready() -> void:
	add_to_group("player")
	_setup_stats()
	_setup_sprite()
	_setup_hitbox()


func _setup_hitbox() -> void:
	var hitbox = $Hitbox
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	hitbox.area_entered.connect(_on_hitbox_area_entered)


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body is IEnemy:
		take_damage(body.power)


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area is IProjectile and area.owner_node != self:
		take_damage(area.damage)
		if not area.persistent:
			area.queue_free()


func _setup_stats() -> void:
	health = 5
	max_health = 5
	speed = 150
	power = 3
	is_alive = true
	keys = 1


func _setup_sprite() -> void:
	sprite = SpriteFactory.create_and_attach(self, SPRITE_PATH)


func _physics_process(delta: float) -> void:
	_handle_movement()
	_handle_shooting(delta)
	_handle_invincibility(delta)
	_handle_special_input()
	_process_active_effects(delta)


func _handle_invincibility(delta: float) -> void:
	if is_invincible:
		invincibility_timer -= delta
		# Flash effect - toggle visibility
		if sprite:
			sprite.visible = int(invincibility_timer * 10) % 2 == 0
		if invincibility_timer <= 0:
			is_invincible = false
			invincibility_timer = 0.0
			if sprite:
				sprite.visible = true


func _handle_special_input() -> void:
	if Input.is_action_just_pressed("Special"):
		use_special()


func _handle_movement() -> void:
	var direction = Vector2.ZERO
	direction.x = Input.get_axis("Move_left", "Move_right")
	direction.y = Input.get_axis("Move_up", "Move_down")
	direction = direction.normalized()

	velocity = direction * speed
	move_and_slide()


func _handle_shooting(delta: float) -> void:
	fire_cooldown -= delta

	var shoot_direction = _get_shoot_direction()
	if shoot_direction != Vector2.ZERO and fire_cooldown <= 0:
		_shoot(shoot_direction)
		fire_cooldown = 1.0 / fire_rate


func _get_shoot_direction() -> Vector2:
	var direction = Vector2.ZERO
	direction.x = Input.get_axis("shoot_left", "shoot_right")
	direction.y = Input.get_axis("shoot_up", "shoot_down")

	if direction != Vector2.ZERO:
		direction = direction.normalized()

	return direction


func _shoot(direction: Vector2) -> void:
	var shot_count = 2 if "double" in projectile_modifiers else 1

	for i in range(shot_count):
		var projectile = projectile_scene.instantiate()
		var spawn_offset = direction * 20.0

		# Offset second shot slightly perpendicular to direction
		if i == 1:
			var perpendicular = Vector2(-direction.y, direction.x) * 10.0
			spawn_offset += perpendicular

		projectile.global_position = global_position + spawn_offset
		projectile.lifetime = shot_range
		projectile.initialize(self, direction, velocity)
		get_tree().current_scene.add_child(projectile)


func take_damage(amount: int) -> void:
	if is_invincible:
		return

	health -= amount
	is_invincible = true
	invincibility_timer = invincibility_duration

	if health <= 0:
		health = 0
		die()


func heal(amount: int) -> void:
	health += amount
	if health > max_health:
		health = max_health
	if health > MAX_HEALTH_CAP:
		health = MAX_HEALTH_CAP


func die() -> void:
	if extra_lives > 0:
		extra_lives -= 1
		health = max_health
		is_invincible = true
		invincibility_timer = invincibility_duration * 2  # Extra i-frames on revive
		print("Player revived! Extra lives remaining: %d" % extra_lives)
		return

	is_alive = false
	var items_copy = collected_items.duplicate()
	player_died.emit(items_copy)
	call_deferred("queue_free")


func apply_item(item_data: Dictionary) -> void:
	collected_items.append(item_data)

	var item_name = item_data.get("name", "Unknown")
	print("Picked up: %s" % item_name)

	item_picked_up.emit(item_data)

	# Apply stat modifiers
	var stats = item_data.get("stats")
	if stats != null and stats is Dictionary:
		_apply_stats(stats)

	# Apply special ability
	var special = item_data.get("special")
	if special != null and special is String and not special.is_empty():
		current_special = special
		special_cooldown = 0  # Ready immediately
		print("Gained special ability: %s" % special)

	# Apply projectile modifier
	var projectile = item_data.get("projectile")
	if projectile != null and projectile is String and not projectile.is_empty():
		_apply_projectile_modifier(projectile)

	# Check if item charges special
	if item_data.get("charges_special", false) and not current_special.is_empty():
		if special_cooldown > 0:
			special_cooldown = max(0, special_cooldown - 1)
			print("Special cooldown reduced to: %d" % special_cooldown)


func _apply_stats(stats: Dictionary) -> void:
	if stats.has("hp"):
		var hp_bonus = int(stats["hp"])
		max_health += hp_bonus
		if max_health > MAX_HEALTH_CAP:
			max_health = MAX_HEALTH_CAP
		health += hp_bonus
		if health > max_health:
			health = max_health
		print("  +%d HP (now %d/%d)" % [hp_bonus, health, max_health])

	if stats.has("power"):
		var power_bonus = stats["power"]
		power += int(power_bonus)
		print("  +%s power (now %d)" % [str(power_bonus), power])

	if stats.has("speed"):
		var speed_bonus = stats["speed"]
		speed += int(speed_bonus)
		print("  +%s speed (now %d)" % [str(speed_bonus), speed])

	if stats.has("fire_rate"):
		var fr_bonus = stats["fire_rate"]
		fire_rate += fr_bonus
		print("  +%s fire rate (now %.1f)" % [str(fr_bonus), fire_rate])

	if stats.has("keys"):
		var key_bonus = int(stats["keys"])
		keys += key_bonus
		print("  +%d keys (now %d)" % [key_bonus, keys])

	if stats.has("extra_lives"):
		var life_bonus = int(stats["extra_lives"])
		extra_lives += life_bonus
		print("  +%d extra lives (now %d)" % [life_bonus, extra_lives])


func _apply_projectile_modifier(modifier: String) -> void:
	if modifier not in projectile_modifiers:
		projectile_modifiers.append(modifier)
		print("  Added projectile modifier: %s" % modifier)

	# Update projectile scene to the most recent modifier
	if modifier in PROJECTILE_SCENES:
		projectile_scene = PROJECTILE_SCENES[modifier]
		print("  Projectile type changed to: %s" % modifier)


func use_special() -> void:
	if current_special.is_empty():
		return

	if special_cooldown > 0:
		print("Special not ready! %d rooms remaining" % special_cooldown)
		return

	# End COPY if active (using any special ends COPY)
	if is_copied:
		_end_copy()

	print("Using special: %s" % current_special)
	_perform_special(current_special)
	special_max_cooldown = SPECIAL_COOLDOWNS.get(current_special, 3)
	special_cooldown = special_max_cooldown


func _perform_special(special_name: String) -> void:
	match special_name:
		"BIG BOOM":
			_special_big_boom()
		"PEW PEW":
			_special_pew_pew()
		"ASCEND":
			_special_ascend()
		"TIME STOP":
			_special_time_stop()
		"SPEED SHOT":
			_special_speed_shot()
		"MIND CONTROL":
			_special_mind_control()
		"COPY":
			_special_copy()
		"INVERT":
			_special_invert()
		_:
			print("Unknown special ability: %s" % special_name)


func _special_big_boom() -> void:
	# Deal damage to enemies within radius around player
	var boom_damage: int = power * BIG_BOOM_DAMAGE_MULTIPLIER

	# Spawn explosion visual
	var explosion = EXPLOSION_SCENE.instantiate()
	explosion.radius = BIG_BOOM_RADIUS
	explosion.global_position = global_position
	get_tree().current_scene.add_child(explosion)

	var enemies = get_tree().get_nodes_in_group("enemy")
	var hit_count: int = 0

	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance <= BIG_BOOM_RADIUS:
			if enemy.has_method("take_damage"):
				enemy.take_damage(boom_damage)
				hit_count += 1

	print("BIG BOOM! Hit %d enemies for %d damage each" % [hit_count, boom_damage])


func on_room_entered() -> void:
	# Reset room-based effects
	is_flying = false

	# End all active timed effects
	for effect_name in active_effects.keys():
		_end_effect(effect_name)
	active_effects.clear()

	# End COPY on floor change (handled separately since it persists across rooms)
	if is_copied:
		_end_copy()


func on_room_cleared() -> void:
	# Called when all enemies in a room are defeated
	if special_cooldown > 0:
		special_cooldown -= 1
		print("Special cooldown: %d rooms remaining" % special_cooldown)


func _process_active_effects(delta: float) -> void:
	var effects_to_end: Array[String] = []

	for effect_name in active_effects:
		active_effects[effect_name] -= delta
		if active_effects[effect_name] <= 0:
			effects_to_end.append(effect_name)

	for effect_name in effects_to_end:
		_end_effect(effect_name)
		active_effects.erase(effect_name)


func _end_effect(effect_name: String) -> void:
	match effect_name:
		"SPEED SHOT":
			fire_rate = original_fire_rate
			print("SPEED SHOT ended - fire rate restored to %.1f" % fire_rate)
		"TIME STOP":
			_unfreeze_all()
			print("TIME STOP ended - enemies unfrozen")
		"MIND CONTROL":
			if controlled_enemy and is_instance_valid(controlled_enemy):
				controlled_enemy.set_player_controlled(false)
				controlled_enemy = null
			print("MIND CONTROL ended")
		"INVERT":
			_restore_enemy_movements()
			print("INVERT ended - enemy movements restored")


func _unfreeze_all() -> void:
	# Unfreeze enemies
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		enemy.set_physics_process(true)

	# Unfreeze enemy projectiles
	var projectiles = get_tree().get_nodes_in_group("projectile")
	for proj in projectiles:
		if proj is IProjectile and proj.owner_node != self:
			proj.set_physics_process(true)


func _end_copy() -> void:
	is_copied = false
	if sprite:
		sprite.texture = load(ImageValidator.get_valid_path(original_sprite_path))
	print("COPY ended - sprite restored")


func _special_pew_pew() -> void:
	# Shoot a scaled projectile with bonus damage
	var shoot_direction = _get_shoot_direction()
	if shoot_direction == Vector2.ZERO:
		shoot_direction = Vector2.RIGHT

	var projectile = projectile_scene.instantiate()
	var spawn_offset = shoot_direction * 20.0
	projectile.global_position = global_position + spawn_offset
	projectile.lifetime = shot_range
	projectile.scale = Vector2(PEW_PEW_SCALE, PEW_PEW_SCALE)
	projectile.initialize(self, shoot_direction, velocity)
	projectile.damage = int(power * PEW_PEW_DAMAGE_MULTIPLIER)
	get_tree().current_scene.add_child(projectile)
	print("PEW PEW! Fired projectile with %d damage" % projectile.damage)


func _special_ascend() -> void:
	# Grant permanent +1 HP, +2 power and enable flight for the room
	heal(1)
	power += 2
	is_flying = true
	print("ASCEND! Healed 1 HP (now %d/%d), +2 power (now %d), flight enabled" % [health, max_health, power])


func _special_speed_shot() -> void:
	# Temporarily boost fire rate
	original_fire_rate = fire_rate
	fire_rate = SPEED_SHOT_FIRE_RATE
	active_effects["SPEED SHOT"] = SPEED_SHOT_DURATION
	print("SPEED SHOT! Fire rate boosted to %.0f for %.1f second" % [SPEED_SHOT_FIRE_RATE, SPEED_SHOT_DURATION])


func _special_time_stop() -> void:
	# Freeze enemies and their projectiles
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		enemy.set_physics_process(false)

	var projectiles = get_tree().get_nodes_in_group("projectile")
	for proj in projectiles:
		if proj is IProjectile and proj.owner_node != self:
			proj.set_physics_process(false)

	active_effects["TIME STOP"] = TIME_STOP_DURATION
	print("TIME STOP! Enemies and projectiles frozen for %.0f seconds" % TIME_STOP_DURATION)


func _special_mind_control() -> void:
	# Control one enemy - mirrors player input
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.is_empty():
		print("MIND CONTROL failed - no enemies to control")
		return

	# Pick the nearest enemy that's not spawning
	var nearest_enemy: IEnemy = null
	var nearest_dist: float = INF

	for enemy in enemies:
		if enemy is IEnemy:
			# Skip enemies still in spawn delay
			if enemy.is_spawning:
				continue
			var dist = global_position.distance_to(enemy.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest_enemy = enemy

	if nearest_enemy:
		controlled_enemy = nearest_enemy
		nearest_enemy.set_player_controlled(true)
		active_effects["MIND CONTROL"] = MIND_CONTROL_DURATION
		print("MIND CONTROL! Controlling enemy at distance %.1f" % nearest_dist)
	else:
		print("MIND CONTROL failed - no valid enemy found")


func _special_copy() -> void:
	# Transform into a random enemy until next special or floor change
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.is_empty():
		print("COPY failed - no enemies to copy")
		return

	# Pick a random enemy
	var random_enemy = enemies[randi() % enemies.size()]

	if random_enemy is IEnemy and random_enemy.sprite:
		is_copied = true
		if sprite and random_enemy.sprite.texture:
			sprite.texture = random_enemy.sprite.texture
			print("COPY! Transformed into enemy sprite")
	else:
		print("COPY failed - enemy has no sprite to copy")


func _special_invert() -> void:
	# Swap BRUTE↔ESCAPE enemy movement types
	var enemies = get_tree().get_nodes_in_group("enemy")
	var inverted_count: int = 0

	for enemy in enemies:
		if enemy is IEnemy and enemy.has_method("invert_movement"):
			if enemy.invert_movement():
				inverted_count += 1

	active_effects["INVERT"] = INVERT_DURATION
	print("INVERT! Swapped movement for %d enemies (%.0f seconds)" % [inverted_count, INVERT_DURATION])


func _restore_enemy_movements() -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy is IEnemy and enemy.has_method("restore_movement"):
			enemy.restore_movement()
