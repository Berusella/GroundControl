extends Node

class_name GameManager


static var instance: GameManager = null

var is_paused: bool = false
var current_floor: int = 0
var current_room: Room = null


func _ready() -> void:
	if instance == null:
		instance = self
	else:
		queue_free()


static func get_instance() -> GameManager:
	return instance


func change_pause_state() -> void:
	is_paused = not is_paused
	get_tree().paused = is_paused


func change_room(room: Room) -> void:
	current_room = room


func next_floor() -> void:
	current_floor += 1
