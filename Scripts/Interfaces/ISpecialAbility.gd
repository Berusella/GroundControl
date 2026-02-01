extends Node

class_name ISpecialAbility


var charge_required: int = 3
var current_charge: int = 0
var is_ready: bool = false
var owner_player: Player = null


func initialize(player: Player) -> void:
	owner_player = player


func add_charge(amount: int = 1) -> void:
	current_charge += amount
	if current_charge >= charge_required:
		current_charge = charge_required
		is_ready = true


func activate() -> void:
	if not is_ready:
		return

	_perform_ability()
	current_charge = 0
	is_ready = false


func _perform_ability() -> void:
	pass


func get_charge_percent() -> float:
	return float(current_charge) / float(charge_required)
