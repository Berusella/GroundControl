extends Node2D


const PLAYER_SCENE = preload("res://Scenes/Player.tscn")
const ROOM_SCENE = preload("res://Scenes/Room.tscn")
const HUD_SCENE = preload("res://Scenes/UI/HUD.tscn")
const DEBUG_CONSOLE_SCENE = preload("res://Scenes/UI/DebugConsole.tscn")
const ROOMS_DATA_PATH = "res://data/rooms.json"

var player: Player = null
var floor_manager: FloorManager = null
var room_loader: RoomLoader = null
var hud: HUD = null
var debug_console: DebugConsole = null


func _ready() -> void:
	_setup_room_loader()
	_create_player()
	_setup_floor_manager()
	_create_hud()
	_create_debug_console()


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
