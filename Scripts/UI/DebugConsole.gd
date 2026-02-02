extends CanvasLayer

class_name DebugConsole


const ENEMY_SCENES = {
	"small_sapling": preload("res://Scenes/Enemies/SmallSapling.tscn"),
	"bruteling": preload("res://Scenes/Enemies/Bruteling.tscn"),
	"soldier": preload("res://Scenes/Enemies/Soldier.tscn"),
	"the_tourist": preload("res://Scenes/Enemies/TheTourist.tscn"),
	"super_sniper": preload("res://Scenes/Enemies/SuperSniper.tscn"),
	"boiling_barrel": preload("res://Scenes/Enemies/BoilingBarrel.tscn"),
	"growing_tree": preload("res://Scenes/Enemies/GrowingTree.tscn"),
	"the_buzzer": preload("res://Scenes/Enemies/TheBuzzer.tscn"),
	"boss_the_tree": preload("res://Scenes/Enemies/BossTheTree.tscn"),
	"boss_military_experiment": preload("res://Scenes/Enemies/BossMilitaryExperiment.tscn"),
	"boss_gorilla": preload("res://Scenes/Enemies/BossGorilla.tscn"),
	"boss_vietnam_horror": preload("res://Scenes/Enemies/BossVietnamHorror.tscn")
}

const PROJECTILE_SCENES = {
	"standard": preload("res://Scenes/Projectiles/ProjectileStandard.tscn"),
	"homing": preload("res://Scenes/Projectiles/ProjectileHoming.tscn"),
	"bounce": preload("res://Scenes/Projectiles/ProjectileBounce.tscn"),
	"laser": preload("res://Scenes/Projectiles/ProjectileLaser.tscn")
}

const ITEM_PEDESTAL_SCENE = preload("res://Scenes/Items/ItemPedestal.tscn")

# Map console-friendly names to actual special ability names
const SPECIAL_ABILITIES = {
	"pew_pew": "PEW PEW",
	"pewpew": "PEW PEW",
	"big_boom": "BIG BOOM",
	"bigboom": "BIG BOOM",
	"boom": "BIG BOOM",
	"ascend": "ASCEND",
	"invert": "INVERT",
	"mind_control": "MIND CONTROL",
	"mindcontrol": "MIND CONTROL",
	"time_stop": "TIME STOP",
	"timestop": "TIME STOP",
	"speed_shot": "SPEED SHOT",
	"speedshot": "SPEED SHOT",
	"copy": "COPY"
}

var is_visible: bool = false
var command_history: Array[String] = []
var history_index: int = -1

@onready var panel: Panel = $Panel
@onready var output: RichTextLabel = $Panel/VBoxContainer/Output
@onready var input: LineEdit = $Panel/VBoxContainer/Input


func _ready() -> void:
	print("DEBUG: DebugConsole _ready() called")
	panel.visible = false
	input.text_submitted.connect(_on_command_submitted)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_console"):
		print("DEBUG: debug_console action pressed, toggling console")
		_toggle_console()
		get_viewport().set_input_as_handled()
	elif is_visible and event is InputEventKey and event.pressed:
		if event.keycode == KEY_UP:
			_navigate_history(-1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_DOWN:
			_navigate_history(1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			_toggle_console()
			get_viewport().set_input_as_handled()


func _toggle_console() -> void:
	is_visible = not is_visible
	panel.visible = is_visible

	if is_visible:
		input.grab_focus()
		input.clear()
		get_tree().paused = true
	else:
		get_tree().paused = false


func _on_command_submitted(command: String) -> void:
	if command.strip_edges().is_empty():
		return

	command_history.append(command)
	history_index = command_history.size()

	_log("> " + command)
	_execute_command(command.strip_edges().to_lower())
	input.clear()


func _navigate_history(direction: int) -> void:
	if command_history.is_empty():
		return

	history_index = clamp(history_index + direction, 0, command_history.size() - 1)
	input.text = command_history[history_index]
	input.caret_column = input.text.length()


func _log(message: String) -> void:
	output.append_text(message + "\n")


func _execute_command(command: String) -> void:
	var parts = command.split(" ", false, 1)
	if parts.is_empty():
		return

	var cmd = parts[0]
	var args = parts[1] if parts.size() > 1 else ""

	match cmd:
		"spawn":
			_cmd_spawn(args)
		"change":
			_cmd_change(args)
		"help":
			_cmd_help()
		"clear":
			output.clear()
		"heal":
			_cmd_heal(args)
		"kill":
			_cmd_kill(args)
		"god":
			_cmd_god()
		"range":
			_cmd_range(args)
		"firerate":
			_cmd_firerate(args)
		"tp":
			_cmd_teleport(args)
		"teleport":
			_cmd_teleport(args)
		"item":
			_cmd_item(args)
		_:
			_log("Unknown command: " + cmd)
			_log("Type 'help' for available commands")


func _cmd_spawn(args: String) -> void:
	var parts = args.split(":", false)
	if parts.size() < 2:
		_log("Usage: spawn enemy:<type>")
		_log("Types: " + ", ".join(ENEMY_SCENES.keys()))
		return

	var category = parts[0]
	var type_name = parts[1]

	if category == "enemy":
		if type_name not in ENEMY_SCENES:
			_log("Unknown enemy: " + type_name)
			_log("Available: " + ", ".join(ENEMY_SCENES.keys()))
			return

		var player = _get_player()
		if not player:
			_log("Error: Player not found")
			return

		var enemy = ENEMY_SCENES[type_name].instantiate()
		var spawn_offset = Vector2(100, 0).rotated(randf() * TAU)
		enemy.global_position = player.global_position + spawn_offset

		var room = _get_current_room()
		if room:
			room.get_node("Enemies").add_child(enemy)
			room.enemies.append(enemy)
			enemy.tree_exited.connect(room._on_enemy_died.bind(enemy))
			_log("Spawned " + type_name + " near player")
		else:
			get_tree().current_scene.add_child(enemy)
			_log("Spawned " + type_name + " (no room found)")
	else:
		_log("Unknown spawn category: " + category)


func _cmd_change(args: String) -> void:
	var parts = args.split(":", false)
	if parts.size() < 2:
		_log("Usage: change projectile:<type> or change special:<type>")
		return

	var category = parts[0]
	var type_name = parts[1]

	match category:
		"projectile":
			if type_name not in PROJECTILE_SCENES:
				_log("Unknown projectile: " + type_name)
				_log("Available: " + ", ".join(PROJECTILE_SCENES.keys()))
				return

			var player = _get_player()
			if player:
				player.projectile_scene = PROJECTILE_SCENES[type_name]
				_log("Changed projectile to: " + type_name)
			else:
				_log("Error: Player not found")

		"special":
			if type_name not in SPECIAL_ABILITIES:
				_log("Unknown special: " + type_name)
				_log("Available: " + ", ".join(SPECIAL_ABILITIES.keys()))
				return

			var player = _get_player()
			if player:
				var special_name = SPECIAL_ABILITIES[type_name]
				player.current_special = special_name
				player.special_cooldown = 0  # Ready immediately
				player.special_max_cooldown = Player.SPECIAL_COOLDOWNS.get(special_name, 3)
				_log("Set special to: " + special_name + " [READY]")
			else:
				_log("Error: Player not found")

		_:
			_log("Unknown category: " + category)
			_log("Use: projectile, special")


func _cmd_heal(args: String) -> void:
	var amount = int(args) if args.is_valid_int() else 10
	var player = _get_player()
	if player:
		player.heal(amount)
		_log("Healed player for " + str(amount))
	else:
		_log("Error: Player not found")


func _cmd_kill(args: String) -> void:
	if args == "all":
		var enemies = get_tree().get_nodes_in_group("enemy")
		for enemy in enemies:
			enemy.queue_free()
		_log("Killed " + str(enemies.size()) + " enemies")
	else:
		_log("Usage: kill all")


func _cmd_god() -> void:
	var player = _get_player()
	if player:
		player.is_invincible = not player.is_invincible
		if player.is_invincible:
			player.invincibility_timer = 999999.0
			_log("God mode: ON")
		else:
			player.invincibility_timer = 0.0
			_log("God mode: OFF")
	else:
		_log("Error: Player not found")


func _cmd_range(args: String) -> void:
	var player = _get_player()
	if not player:
		_log("Error: Player not found")
		return

	if args.is_empty():
		_log("Current range: " + str(player.shot_range))
		return

	if args.is_valid_float():
		player.shot_range = float(args)
		_log("Set range to: " + str(player.shot_range))
	else:
		_log("Usage: range [value] - Set projectile lifetime in seconds")


func _cmd_firerate(args: String) -> void:
	var player = _get_player()
	if not player:
		_log("Error: Player not found")
		return

	if args.is_empty():
		_log("Current fire rate: " + str(player.fire_rate) + " shots/sec")
		return

	if args.is_valid_float():
		player.fire_rate = float(args)
		_log("Set fire rate to: " + str(player.fire_rate) + " shots/sec")
	else:
		_log("Usage: firerate [value] - Set shots per second")


func _cmd_teleport(args: String) -> void:
	var floor_manager = _get_floor_manager()
	if not floor_manager:
		_log("Error: FloorManager not found")
		return

	if args.is_empty():
		_log("Usage: tp <room_type>")
		_log("Types: item, boss")
		return

	var target_type = args.to_lower()
	var target_pos = Vector2i(-1, -1)

	for pos in floor_manager._floor_grid:
		var room_data = floor_manager._floor_grid[pos]
		var room_type = room_data.get("room_type", "Normal").to_lower()
		if room_type == target_type:
			target_pos = pos
			break

	if target_pos == Vector2i(-1, -1):
		_log("No " + target_type + " room found on this floor")
		return

	# Load the room
	floor_manager._load_room_at_position(target_pos, "")
	_log("Teleported to " + target_type + " room at " + str(target_pos))


func _cmd_item(args: String) -> void:
	var player = _get_player()
	if not player:
		_log("Error: Player not found")
		return

	var pedestal = ITEM_PEDESTAL_SCENE.instantiate()
	var spawn_offset = Vector2(80, 0)
	pedestal.global_position = player.global_position + spawn_offset
	get_tree().current_scene.add_child(pedestal)

	if args.is_empty():
		# Random item
		pedestal.set_random_item()
		_log("Spawned item pedestal with random item")
	elif args.is_valid_int():
		# Specific item by ID
		var item_id = int(args)
		pedestal.set_item_by_id(item_id)
		_log("Spawned item pedestal with item ID: " + str(item_id))
	else:
		# Try to find by name
		pedestal.set_item_by_name(args)
		_log("Spawned item pedestal with item: " + args)


func _cmd_help() -> void:
	_log("=== Debug Console Commands ===")
	_log("spawn enemy:<type> - Spawn enemy near player")
	_log("  Types: " + ", ".join(ENEMY_SCENES.keys()))
	_log("change projectile:<type> - Change player projectile")
	_log("  Types: " + ", ".join(PROJECTILE_SCENES.keys()))
	_log("change special:<type> - Set special ability (ready to use)")
	_log("  Types: pew_pew, big_boom, ascend, invert,")
	_log("         mind_control, time_stop, speed_shot, copy")
	_log("heal [amount] - Heal player (default: 10)")
	_log("kill all - Kill all enemies")
	_log("god - Toggle invincibility")
	_log("range [value] - Set/show projectile range (lifetime)")
	_log("firerate [value] - Set/show fire rate (shots/sec)")
	_log("tp <type> - Teleport to room (item, boss)")
	_log("item [id/name] - Spawn item pedestal (random if no arg)")
	_log("clear - Clear console")
	_log("help - Show this help")


func _get_player() -> Player:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null


func _get_current_room() -> Room:
	var rooms = get_tree().get_nodes_in_group("room")
	if rooms.size() > 0:
		return rooms[0]
	# Try to find via FloorManager
	var floor_manager = _get_floor_manager()
	if floor_manager:
		return floor_manager._current_room
	return null


func _get_floor_manager() -> FloorManager:
	var main = get_tree().current_scene
	if main and main.has_method("get") and main.get("floor_manager"):
		return main.floor_manager
	# Try direct child lookup
	for child in main.get_children():
		if child is FloorManager:
			return child
	return null
