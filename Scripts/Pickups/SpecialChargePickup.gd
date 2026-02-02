extends IPickup

class_name SpecialChargePickup


func _init() -> void:
	sprite_path = "res://Sprites/Consumables/consumable_special_charge.png"


func pickup(player: Player) -> void:
	if player.special_cooldown > 0:
		player.special_cooldown = max(0, player.special_cooldown - 1)
		print("Special cooldown reduced by 1")
