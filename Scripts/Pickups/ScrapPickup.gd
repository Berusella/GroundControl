extends IPickup

class_name ScrapPickup


var heal_amount: int = 10


func _init() -> void:
	sprite_path = "res://Sprites/Consumables/consumable_scrap.png"


func pickup(player: Player) -> void:
	player.heal(heal_amount)
