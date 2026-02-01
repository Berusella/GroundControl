extends ICharacter

class_name IEnemy


var target: Node2D = null
var attack_damage: int = 10
var attack_range: float = 50.0
var detection_range: float = 200.0
var sprite: Sprite2D = null
var sprite_path: String = ""

# Mind control support
var is_player_controlled: bool = false


func _ready() -> void:
	add_to_group("enemy")
	_setup_sprite()
	_find_player()


func _find_player() -> void:
	# Find player in the scene tree
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]


func _setup_sprite() -> void:
	if not sprite_path.is_empty():
		sprite = SpriteFactory.create_and_attach(self, sprite_path)


func attack() -> void:
	pass


func detect_player() -> void:
	pass


func chase_target() -> void:
	pass


func on_death() -> void:
	pass


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


func _process(delta: float) -> void:
	# Only runs when player-controlled
	if not is_player_controlled:
		return
	var dir = Vector2(
		Input.get_axis("Move_left", "Move_right"),
		Input.get_axis("Move_up", "Move_down")
	).normalized()
	velocity = dir * speed
	move_and_slide()
