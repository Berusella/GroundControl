extends Area2D

class_name Item


const PROJECTILE_SCENES = {
	"homing": preload("res://Scenes/Projectiles/ProjectileHoming.tscn"),
	"bounce": preload("res://Scenes/Projectiles/ProjectileBounce.tscn"),
	"laser": preload("res://Scenes/Projectiles/ProjectileLaser.tscn")
}

var item_data: Dictionary = {}
var item_id: int = -1
var item_name: String = ""
var rarity: int = 1
var special: String = ""
var stats: Dictionary = {}
var projectile_modifier: String = ""
var charges_special: bool = false

var sprite: Sprite2D = null


func _ready() -> void:
	add_to_group("item")
	body_entered.connect(_on_body_entered)


func initialize(data: Dictionary) -> void:
	item_data = data
	item_id = data.get("id", -1)
	item_name = data.get("name", "Unknown Item")
	rarity = data.get("rarity", 1)
	special = data.get("special", "") if data.get("special") != null else ""
	stats = data.get("stats", {}) if data.get("stats") != null else {}
	projectile_modifier = data.get("projectile", "") if data.get("projectile") != null else ""
	charges_special = data.get("charges_special", false)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		pickup(body as Player)


func pickup(player: Player) -> void:
	player.apply_item(item_data)
	queue_free()


func get_projectile_scene() -> PackedScene:
	if projectile_modifier in PROJECTILE_SCENES:
		return PROJECTILE_SCENES[projectile_modifier]
	return null
