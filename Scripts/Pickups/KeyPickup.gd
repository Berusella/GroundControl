extends IPickup

class_name KeyPickup


func _init() -> void:
	sprite_path = "res://Sprites/Consumables/consumable_key.png"


func pickup(player: Player) -> void:
	player.keys += 1
