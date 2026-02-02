extends Node2D


const PLAYER_SCENE = preload("res://Scenes/Player.tscn")
const ROOM_SCENE = preload("res://Scenes/Room.tscn")
const HUD_SCENE = preload("res://Scenes/UI/HUD.tscn")
const DEBUG_CONSOLE_SCENE = preload("res://Scenes/UI/DebugConsole.tscn")
const ITEM_POPUP_SCENE = preload("res://Scenes/UI/ItemPopup.tscn")
const GAME_OVER_SCENE = preload("res://Scenes/UI/GameOver.tscn")
const YOU_WIN_SCENE = preload("res://Scenes/UI/YouWin.tscn")
const MAIN_MENU_SCENE = preload("res://Scenes/UI/MainMenu.tscn")
const ROOMS_DATA_PATH = "res://data/rooms.json"

var player: Player = null
var floor_manager: FloorManager = null
var room_loader: RoomLoader = null
var hud: HUD = null
var debug_console: DebugConsole = null
var item_popup: ItemPopup = null
var game_over: GameOver = null
var you_win: YouWin = null
var main_menu: MainMenu = null


func _ready() -> void:
	_create_main_menu()


func _create_main_menu() -> void:
	main_menu = MAIN_MENU_SCENE.instantiate()
	add_child(main_menu)
	main_menu.new_run_pressed.connect(_on_new_run_pressed)
	main_menu.exit_pressed.connect(_on_menu_exit_pressed)


func _on_new_run_pressed() -> void:
	main_menu.queue_free()
	main_menu = null
	_start_game()


func _on_menu_exit_pressed() -> void:
	get_tree().quit()


func _start_game() -> void:
	_setup_room_loader()
	_create_player()
	_setup_floor_manager()
	_create_hud()
	_create_debug_console()
	_create_item_popup()
	_create_game_over()
	_create_you_win()


func _setup_room_loader() -> void:
	room_loader = RoomLoader.new(ROOM_SCENE)
	room_loader.load_data(ROOMS_DATA_PATH)


func _create_player() -> void:
	player = PLAYER_SCENE.instantiate()
	add_child(player)


func _setup_floor_manager() -> void:
	floor_manager = FloorManager.new()
	add_child(floor_manager)
	floor_manager.initialize(room_loader, player)
	floor_manager.load_starting_room()


func _create_hud() -> void:
	hud = HUD_SCENE.instantiate()
	add_child(hud)


func _create_debug_console() -> void:
	debug_console = DEBUG_CONSOLE_SCENE.instantiate()
	add_child(debug_console)


func _create_item_popup() -> void:
	item_popup = ITEM_POPUP_SCENE.instantiate()
	add_child(item_popup)
	player.item_picked_up.connect(_on_item_picked_up)


func _on_item_picked_up(item_data: Dictionary) -> void:
	item_popup.show_item(item_data)


func _create_game_over() -> void:
	game_over = GAME_OVER_SCENE.instantiate()
	add_child(game_over)
	game_over.restart_pressed.connect(_on_restart_pressed)
	game_over.exit_pressed.connect(_on_exit_pressed)
	player.player_died.connect(_on_player_died)


func _on_player_died(collected_items: Array[Dictionary]) -> void:
	game_over.show_game_over(collected_items)


func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()


func _on_exit_pressed() -> void:
	get_tree().quit()


func _create_you_win() -> void:
	you_win = YOU_WIN_SCENE.instantiate()
	add_child(you_win)
	you_win.restart_pressed.connect(_on_restart_pressed)
	you_win.exit_pressed.connect(_on_exit_pressed)
	floor_manager.player_won.connect(_on_player_won)


func _on_player_won() -> void:
	you_win.show_you_win(player.collected_items)
