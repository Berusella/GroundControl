extends Node2D


const PLAYER_SCENE = preload("res://Scenes/Player.tscn")
const ROOM_SCENE = preload("res://Scenes/Room.tscn")
const ROOMS_DATA_PATH = "res://data/rooms.json"

var player: Player = null
var floor_manager: FloorManager = null
var room_loader: RoomLoader = null


func _ready() -> void:
	_setup_room_loader()
	_create_player()
	_setup_floor_manager()


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
	floor_manager.load_first_room()
