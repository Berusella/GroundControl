extends Area2D

class_name IPickup


var sprite: Sprite2D = null
var sprite_path: String = ""


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_setup_sprite()


func _setup_sprite() -> void:
	if not sprite_path.is_empty():
		sprite = SpriteFactory.create_and_attach(self, sprite_path)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		pickup(body as Player)
		queue_free()


func pickup(player: Player) -> void:
	pass
