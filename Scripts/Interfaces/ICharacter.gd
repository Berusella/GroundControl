extends CharacterBody2D

class_name ICharacter


var health: int = 100
var max_health: int = 100
var speed: int = 100
var power: int = 1
var is_alive: bool = true


func take_damage(amount: int) -> void:
	pass


func heal(amount: int) -> void:
	pass


func die() -> void:
	pass
