extends Node2D

class_name Door


enum DoorState { OPEN, CLOSED, LOCKED }

var state: DoorState = DoorState.CLOSED
var leads_to: Room = null
var requires_key: bool = false


func _ready() -> void:
	pass


func open() -> void:
	if state != DoorState.LOCKED:
		state = DoorState.OPEN


func close() -> void:
	if state == DoorState.OPEN:
		state = DoorState.CLOSED


func lock() -> void:
	state = DoorState.LOCKED


func unlock() -> void:
	if state == DoorState.LOCKED:
		state = DoorState.CLOSED


func interact(player: Player) -> void:
	if state == DoorState.LOCKED and requires_key:
		if player.stats.keys > 0:
			player.stats.keys -= 1
			unlock()
			open()
	elif state == DoorState.CLOSED:
		open()
